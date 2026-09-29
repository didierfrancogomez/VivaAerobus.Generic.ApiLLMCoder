import newman from 'newman';
import { chromium } from 'playwright-core';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { TOOL_DIR, fail, list, parseArgs } from './lib.mjs';

const USAGE = `Usage:
  node newman-evidence.mjs --collection <file> --folder "<TC folder>" --ticket API-XXXX --tc TC01 --out <png dir>
                           [--environment <file>] [--env-var key=value]... [--hide-body "<request name>"]...
                           [--cards <cards.json>] [--shots all|none] [--max-lines 40] [--code-repo <path>]
  node newman-evidence.mjs --from-run <run dir> --ticket API-XXXX --tc TC01 --out <png dir> [--cards <cards.json>]

Runs ONE test-case folder of a Postman collection with newman (reporters cli + htmlextra + json) and writes:
  <out>/<TICKET>_<TC>_00_newman-summary.png           the run summary (requests, assertions, failures)
  <out>/<TICKET>_<TC>_<NN>_<request>_newman.png       one per request: request, response, pm.test results
  <out>/<TICKET>_<TC>_<NN>_<slug>_card.png            one per entry of --cards (readable evidence card)
Raw report.html / run.json stay in tools/evidence/.runs/ — they carry tokens and full bodies; never share them.
Requests whose name matches /login|token/i get their request AND response bodies hidden automatically.

cards.json = [{ "request": "<request name>", "title": "...", "subtitle": "...", "expected": "...",
                "got": "...", "excerpt": ["data.checkIn.status", "data.journeys[0].passengers[?type=EXST]"] }]`;

const SENSITIVE_REQUEST = /login|token/i;
const SENSITIVE_KEY = /^pass$|password|passwd|token|secret|cvv|cvc|cardnumber|^pan$/i;
const CDN = /^https:\/\/(cdnjs\.cloudflare\.com|stackpath\.bootstrapcdn\.com|cdn\.datatables\.net)\//;

const args = parseArgs(process.argv.slice(2));
if (args.help)
  fail(USAGE, 0);
if (!args.ticket || !args.tc || !args.out || (!args['from-run'] && (!args.collection || !args.folder)))
  fail(USAGE);

const prefix = `${args.ticket}_${args.tc}`;
const outDir = resolve(args.out);
mkdirSync(outDir, { recursive: true });

const slug = text => text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 60);
const pad = number => String(number).padStart(2, '0');
const escapeHtml = text => String(text).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);

function collectNames(items, folders, inside = false) {
  return items.flatMap(item => {
    const within = inside || folders.includes(item.name);
    if (item.item)
      return collectNames(item.item, folders, within);
    return within ? [item.name] : [];
  });
}

function runNewman(runDir) {
  const collection = JSON.parse(readFileSync(resolve(args.collection), 'utf8'));
  const folders = list(args.folder);
  const hidden = [...new Set([...collectNames(collection.item, folders).filter(name => SENSITIVE_REQUEST.test(name)), ...list(args['hide-body'])])];
  const envVar = list(args['env-var']).map(pair => ({ key: pair.split('=')[0], value: pair.slice(pair.indexOf('=') + 1) }));
  const title = `${args.ticket} ${args.tc} — ${folders.join(', ')}`;
  return new Promise((done, reject) => newman.run({
    collection,
    environment: args.environment ? resolve(args.environment) : undefined,
    folder: folders.length === 1 ? folders[0] : folders,
    envVar,
    insecure: true,
    timeoutRequest: 90000,
    delayRequest: 250,
    reporters: ['cli', 'htmlextra', 'json'],
    reporter: {
      htmlextra: { export: join(runDir, 'report.html'), title, browserTitle: title, skipHeaders: 'Authorization', hideRequestBody: hidden, hideResponseBody: hidden },
      json: { export: join(runDir, 'run.json') }
    }
  }, (error, summary) => (error ? reject(error) : done({ summary, hidden }))));
}

function codeUnderTest() {
  const repo = args['code-repo'] || process.env.VIVA_CODE_REPO || join(TOOL_DIR, '..', '..', '..', 'VivaAerobus.Generic.Api');
  const git = (...params) => spawnSync('git', ['-C', repo, ...params], { encoding: 'utf8' }).stdout?.trim();
  const branch = git('rev-parse', '--abbrev-ref', 'HEAD');
  const sha = git('rev-parse', '--short', 'HEAD');
  const dirty = git('status', '--porcelain', '--untracked-files=no');
  return branch && sha ? `${branch} @ ${sha}${dirty ? ' + uncommitted changes' : ''}` : 'unknown';
}

function select(value, path) {
  let matches = [value];
  for (const token of path.match(/\[[^\]]*\]|[^.[\]]+/g) || []) {
    if (!token.startsWith('['))
      matches = matches.map(item => item?.[token]);
    else if (token === '[*]')
      matches = matches.flatMap(item => (Array.isArray(item) ? item : []));
    else if (token.startsWith('[?')) {
      const [key, expected] = token.slice(2, -1).split('=');
      matches = matches.flatMap(item => (Array.isArray(item) ? item : []).filter(entry => String(entry?.[key]) === expected));
    } else
      matches = matches.map(item => item?.[Number(token.slice(1, -1))]);
    matches = matches.filter(item => item !== undefined);
  }
  return matches.length === 1 ? matches[0] : matches;
}

function mask(value) {
  if (Array.isArray(value))
    return value.map(mask);
  if (value && typeof value === 'object')
    return Object.fromEntries(Object.entries(value).map(([key, inner]) => [key, SENSITIVE_KEY.test(key) && inner !== null ? '•••' : mask(inner)]));
  return value;
}

function parseJson(text) {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

function describe(execution) {
  const url = execution.request.url;
  const query = (url.query || []).filter(q => !q.disabled).map(q => `${q.key}=${q.value ?? ''}`).join('&');
  const address = `${url.protocol}://${url.host.join('.')}${url.port ? `:${url.port}` : ''}/${url.path.join('/')}${query ? `?${query}` : ''}`;
  const headers = execution.request.header.filter(header => !header.system && !header.disabled && !/^(authorization|cookie)$/i.test(header.key));
  const raw = execution.request.body?.raw || '';
  const body = Buffer.from(execution.response?.stream?.data || []).toString('utf8');
  return { address, headers, raw, body, json: parseJson(body) };
}

function cardHtml(card, execution, meta) {
  const { address, headers, raw } = describe(execution);
  const response = describe(execution).json;
  const hidden = meta.hidden.includes(execution.item.name);
  const assertions = execution.assertions || [];
  const passed = assertions.length > 0 && assertions.every(item => !item.error && !item.skipped);
  const requestBody = hidden ? '(hidden — credentials)' : raw ? JSON.stringify(mask(parseJson(raw) ?? raw), null, 2) : '';
  const excerpts = list(card.excerpt).map(path => `
      <div class="path">${escapeHtml(path)}</div>
      <pre class="excerpt">${escapeHtml(hidden ? '(hidden — credentials)' : JSON.stringify(mask(select(response, path)), null, 2) ?? 'undefined')}</pre>`).join('');
  const headerRows = headers.map(header => `<span><b>${escapeHtml(header.key)}</b>: ${escapeHtml(header.value)}</span>`).join(' · ');
  return `<!doctype html><html><head><meta charset="utf-8"><style>
    body { margin: 0; padding: 24px; background: #eef1f5; font: 14px/1.45 "Segoe UI", system-ui, sans-serif; color: #1c2430; }
    .card { background: #fff; border-radius: 10px; padding: 22px 26px; box-shadow: 0 1px 3px rgba(0,0,0,.12); width: 1180px; }
    .top { display: flex; justify-content: space-between; align-items: flex-start; gap: 16px; }
    .kicker { color: #5b6675; font-size: 12px; letter-spacing: .04em; text-transform: uppercase; }
    h1 { margin: 4px 0 2px; font-size: 21px; } .subtitle { color: #5b6675; }
    .badge { padding: 5px 14px; border-radius: 16px; font-weight: 700; font-size: 15px; }
    .pass { background: #dff5e5; color: #17693a; } .fail { background: #fbe1e1; color: #a12020; }
    .expect { margin: 14px 0; padding: 10px 14px; background: #f5f7fa; border-radius: 6px; }
    .cols { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
    h2 { font-size: 12px; letter-spacing: .06em; color: #5b6675; margin: 6px 0; text-transform: uppercase; }
    .line { word-break: break-all; margin-bottom: 6px; } .headers { font-size: 12px; color: #394455; margin-bottom: 8px; }
    pre { margin: 0 0 10px; padding: 12px; border-radius: 6px; background: #111a2b; color: #e8edf5; font: 12.5px/1.4 Consolas, monospace; white-space: pre-wrap; word-break: break-all; }
    .excerpt { background: #1f1a08; color: #fdf3c4; border: 2px solid #f0b400; }
    .path { font: 12px Consolas, monospace; color: #7a5a00; margin: 8px 0 4px; }
    ul { margin: 4px 0 0; padding-left: 18px; } li.ok::marker { content: "✔ "; color: #17693a; } li.ko::marker { content: "✖ "; color: #a12020; }
    .foot { margin-top: 16px; padding-top: 10px; border-top: 1px solid #e3e7ee; display: flex; justify-content: space-between; gap: 16px; color: #5b6675; font-size: 12px; }
  </style></head><body><div class="card">
    <div class="top"><div>
      <div class="kicker">${escapeHtml(meta.ticket)} · ${escapeHtml(meta.tc)} · step ${escapeHtml(meta.step)} · ${escapeHtml(execution.item.name)}</div>
      <h1>${escapeHtml(card.title || execution.item.name)}</h1>
      ${card.subtitle ? `<div class="subtitle">${escapeHtml(card.subtitle)}</div>` : ''}
    </div><div class="badge ${passed ? 'pass' : 'fail'}">${passed ? 'PASS' : 'FAIL'}</div></div>
    ${card.expected || card.got ? `<div class="expect">${card.expected ? `<b>Expected:</b> ${escapeHtml(card.expected)}` : ''}${card.expected && card.got ? ' &nbsp;·&nbsp; ' : ''}${card.got ? `<b>Got:</b> ${escapeHtml(card.got)}` : ''}</div>` : ''}
    <div class="cols"><div>
      <h2>Request</h2>
      <div class="line"><b>${escapeHtml(execution.request.method)}</b> ${escapeHtml(address)}</div>
      <div class="headers">${headerRows}${headerRows ? ' · ' : ''}<b>Authorization</b>: (omitted)</div>
      ${requestBody ? `<pre>${escapeHtml(requestBody)}</pre>` : ''}
      <h2>Assertions (pm.test)</h2>
      <ul>${assertions.map(item => `<li class="${item.error ? 'ko' : 'ok'}">${escapeHtml(item.assertion)}${item.error ? ` — ${escapeHtml(item.error.message)}` : ''}</li>`).join('') || '<li>none</li>'}</ul>
    </div><div>
      <h2>Response · HTTP ${escapeHtml(execution.response?.code ?? '—')} · ${escapeHtml(execution.response?.responseTime ?? '—')} ms</h2>
      ${excerpts || '<div class="subtitle">No excerpt requested.</div>'}
      <div class="subtitle">Full request and response: the classic evidence file of this test case.</div>
    </div></div>
    <div class="foot"><span>Code under test: ${escapeHtml(meta.code)}</span><span>Captured ${escapeHtml(meta.captured)} · newman run of “${escapeHtml(meta.collection)}”</span></div>
  </div></body></html>`;
}

async function captureReport(context, runDir, executions) {
  const page = await context.newPage();
  page.setDefaultTimeout(90000);
  await page.addInitScript(maxLines => document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('pre code').forEach(code => {
      const lines = code.textContent.split('\n');
      if (lines.length <= maxLines)
        return;
      code.textContent = lines.slice(0, maxLines).join('\n');
      code.dataset.truncatedFrom = String(lines.length);
    });
  }), +(args['max-lines'] || 40));
  await page.goto(pathToFileURL(join(runDir, 'report.html')).href, { waitUntil: 'load' });
  await page.addStyleTag({ content: `.copyButton, #myBtn, .dataTables_filter, .dataTables_length, .dataTables_info, .dataTables_paginate { display: none !important; }
    #pills-requests .dyn-height, #pills-requests pre, #pills-requests pre code { max-height: none !important; overflow: visible !important; }` });
  await page.evaluate(() => document.querySelectorAll('code[data-truncated-from]').forEach(code => {
    const note = document.createElement('div');
    note.textContent = `⋯ body truncated in this capture (${code.dataset.truncatedFrom} lines) — full response in the classic evidence file of this test case`;
    note.style.cssText = 'font: italic 13px sans-serif; color: #f0c040; margin: 6px 0 10px;';
    code.closest('pre').after(note);
  }));

  const shots = [];
  const summary = page.locator('#pills-summary').first();
  shots.push(join(outDir, `${prefix}_00_newman-summary.png`));
  await summary.screenshot({ path: shots.at(-1) });

  await page.evaluate(() => {
    document.querySelectorAll('.tab-pane').forEach(pane => pane.classList.remove('show', 'active'));
    document.querySelector('#pills-requests').classList.add('show', 'active');
  });
  for (const [index, execution] of executions.entries()) {
    const target = page.locator(`#collapse-${execution.cursor.ref}`);
    if (!(await target.count()))
      continue;
    await target.evaluate(element => {
      for (let current = element; current; current = current.parentElement)
        if (current.classList?.contains('collapse'))
          current.classList.add('show');
    });
    shots.push(join(outDir, `${prefix}_${pad(index + 1)}_${slug(execution.item.name)}_newman.png`));
    await target.locator('xpath=..').screenshot({ path: shots.at(-1) });
  }
  await page.close();
  return shots;
}

async function captureCards(context, executions, meta) {
  const cards = JSON.parse(readFileSync(resolve(args.cards), 'utf8'));
  const shots = [];
  for (const card of cards) {
    const index = executions.findIndex(execution => execution.item.name === card.request);
    if (index < 0)
      throw new Error(`card '${card.title}': no request named '${card.request}' in this run — requests: ${executions.map(e => e.item.name).join(' | ')}`);
    const page = await context.newPage();
    await page.setContent(cardHtml(card, executions[index], { ...meta, step: pad(index + 1) }), { waitUntil: 'load' });
    shots.push(join(outDir, `${prefix}_${pad(index + 1)}_${slug(card.title || card.request)}_card.png`));
    await page.locator('.card').screenshot({ path: shots.at(-1) });
    await page.close();
  }
  return shots;
}

const stamp = new Date().toISOString().replace(/[-:]/g, '').replace(/\..+/, '').replace('T', '-');
const runDir = args['from-run'] ? resolve(args['from-run']) : join(TOOL_DIR, '.runs', args.ticket, `${stamp}-${args.tc}`);
mkdirSync(runDir, { recursive: true });

let hidden = [];
if (!args['from-run']) {
  const result = await runNewman(runDir);
  hidden = result.hidden;
  writeFileSync(join(runDir, 'hidden.json'), JSON.stringify(hidden));
} else if (existsSync(join(runDir, 'hidden.json')))
  hidden = JSON.parse(readFileSync(join(runDir, 'hidden.json'), 'utf8'));

const run = JSON.parse(readFileSync(join(runDir, 'run.json'), 'utf8'));
const executions = run.run.executions;
const failures = run.run.failures.length;
const meta = {
  ticket: args.ticket,
  tc: args.tc,
  hidden,
  code: args['from-run'] && existsSync(join(runDir, 'code.txt')) ? readFileSync(join(runDir, 'code.txt'), 'utf8') : codeUnderTest(),
  captured: new Date(run.run.timings.started || Date.now()).toISOString(),
  collection: run.collection.info.name
};
writeFileSync(join(runDir, 'code.txt'), meta.code);

const browser = await chromium.launch({ channel: args.browser || 'chrome', headless: true });
const context = await browser.newContext({ viewport: { width: 1280, height: 900 }, deviceScaleFactor: 1 });
await context.route(CDN, route => {
  const local = join(TOOL_DIR, 'vendor', route.request().url().replace(/^https:\/\//, '').split('?')[0]);
  return existsSync(local) ? route.fulfill({ path: local }) : route.abort();
});
let exitCode = failures ? 3 : 0;
try {
  const shots = [
    ...(args.shots === 'none' ? [] : await captureReport(context, runDir, executions)),
    ...(args.cards ? await captureCards(context, executions, meta) : [])
  ];
  shots.forEach(path => console.log(`🖼  ${path}`));
  console.log(`📁 raw run (private): ${runDir}`);
  console.log(`${failures ? '✖' : '✔'} ${executions.length} requests · ${failures} failed assertion(s) · code under test: ${meta.code}`);
} catch (error) {
  console.error(`✖ ${error.message.split('\n')[0]}`);
  exitCode = 1;
} finally {
  await browser.close();
}
process.exit(exitCode);
