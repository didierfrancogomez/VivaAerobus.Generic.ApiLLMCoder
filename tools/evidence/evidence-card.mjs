// Render ONE readable evidence card per test case, straight from the classic capture files
// (the "### NN-step / **curl (Request)** / **Response**" markdown this repo already writes).
// The card is what gets attached to Jira; the classic file stays as the full log.
//   node evidence-card.mjs --spec cards.json --out <png dir> [--code-repo <path>]
//
// spec = { "ticket": "API-1901", "raw": "<dir the `from` paths are relative to>", "cards": [
//   { "tc": "TC01", "endpoint": "GET /payment/methodsavailable", "from": "TC1/08-....md",
//     "title": "...", "subtitle": "...", "config": [["label", "value"], ...],
//     "expected": "...", "got": "...", "verdict": "PASS",
//     "excerpt": ["data.paymentOptions[?type=CardPayment].bankOptions[0].installments"],
//     "note": "..." } ] }
import { chromium } from 'playwright-core';
import { spawnSync } from 'node:child_process';
import { mkdirSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { TOOL_DIR, fail, parseArgs } from './lib.mjs';

const args = parseArgs(process.argv.slice(2));
if (!args.spec || !args.out)
  fail('Usage: node evidence-card.mjs --spec <spec.json> --out <png dir> [--code-repo <path>]');

const spec = JSON.parse(readFileSync(resolve(args.spec), 'utf8'));
const outDir = resolve(args.out);
const rawDir = resolve(spec.raw || dirname(resolve(args.spec)));
mkdirSync(outDir, { recursive: true });

const SENSITIVE_KEY = /^pass$|password|passwd|token|secret|cvv|cvc|cardnumber|^pan$/i;
const slug = text => text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 58);
const escapeHtml = text => String(text).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);

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
    return Object.fromEntries(Object.entries(value).map(([key, inner]) => [key, SENSITIVE_KEY.test(key) && inner !== null ? '\u2022\u2022\u2022' : mask(inner)]));
  return value;
}

// The classic capture is machine-readable on purpose: a fenced curl, then the response section.
// Two shapes are in use \u2014 "**Response** \u2014 HTTP `400` in `1329 ms`" and the bulleted
// "- HTTP `200 OK`" / "- Duration: `3242 ms`" \u2014 so both are accepted here.
function parseCapture(file) {
  const text = readFileSync(file, 'utf8').replace(/^\uFEFF/, '').replace(/\r\n/g, '\n');
  const curl = text.match(/\*\*curl \(Request\)\*\*\s*```bash\n([\s\S]*?)\n```/);
  if (!curl)
    throw new Error(`${file}: no curl block`);
  const tail = text.slice(text.indexOf('**Response**'));
  const status = tail.match(/HTTP `(\d+)/);
  const time = tail.match(/in `([^`]+)`/) || tail.match(/Duration: `([^`]+)`/);
  const body = tail.match(/Body:\s*```json\n([\s\S]*?)\n```/);
  let json = null;
  try {
    json = JSON.parse(body?.[1] ?? '');
  } catch { /* a non-JSON body is shown verbatim */ }
  return {
    curl: curl[1]
      .replace(/(-H '[Aa]uthorization: Bearer )[^']+'/g, '$1<token redacted>\'')
      .replace(/(\\?"(?:number|cvv|storedPaymentKey)\\?":\s*\\?")[^"\\]+/g, '$1\u2022\u2022\u2022'),
    status: status?.[1] ?? '\u2014',
    time: time?.[1] ?? '\u2014',
    body: body?.[1] ?? '',
    json
  };
}

function codeUnderTest() {
  const repo = args['code-repo'] || process.env.VIVA_CODE_REPO || join(TOOL_DIR, '..', '..', '..', 'VivaAerobus.Generic.Api');
  const git = (...params) => spawnSync('git', ['-C', repo, ...params], { encoding: 'utf8' }).stdout?.trim();
  const branch = git('rev-parse', '--abbrev-ref', 'HEAD');
  const sha = git('rev-parse', '--short', 'HEAD');
  return branch && sha ? `${branch} @ ${sha}` : 'unknown';
}

function cardHtml(card, capture, meta) {
  const pass = (card.verdict || 'PASS').toUpperCase() === 'PASS';
  const excerpts = (card.excerpt || []).map(path => `
      <div class="path">${escapeHtml(path)}</div>
      <pre class="excerpt">${escapeHtml(JSON.stringify(mask(select(capture.json, path)), null, 2) ?? 'undefined')}</pre>`).join('');
  const config = (card.config || []).map(([label, value]) =>
    `<tr><td>${escapeHtml(label)}</td><td><code>${escapeHtml(value)}</code></td></tr>`).join('');
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
    table { border-collapse: collapse; width: 100%; margin-bottom: 10px; font-size: 13px; }
    td { padding: 4px 8px; border-bottom: 1px solid #e9edf3; } td:first-child { color: #5b6675; width: 46%; }
    code { font: 12.5px Consolas, monospace; background: #f0f3f8; padding: 1px 5px; border-radius: 3px; }
    pre { margin: 0 0 10px; padding: 12px; border-radius: 6px; background: #111a2b; color: #e8edf5; font: 12.5px/1.4 Consolas, monospace; white-space: pre-wrap; word-break: break-all; }
    .excerpt { background: #1f1a08; color: #fdf3c4; border: 2px solid #f0b400; }
    .path { font: 12px Consolas, monospace; color: #7a5a00; margin: 8px 0 4px; }
    .note { margin-top: 12px; padding: 9px 13px; background: #eef4ff; border-left: 3px solid #4571c4; border-radius: 0 5px 5px 0; font-size: 13px; }
    .foot { margin-top: 16px; padding-top: 10px; border-top: 1px solid #e3e7ee; display: flex; justify-content: space-between; gap: 16px; color: #5b6675; font-size: 12px; }
  </style></head><body><div class="card">
    <div class="top"><div>
      <div class="kicker">${escapeHtml(meta.ticket)} \u00b7 ${escapeHtml(card.tc)} \u00b7 ${escapeHtml(card.endpoint || '')}</div>
      <h1>${escapeHtml(card.title)}</h1>
      ${card.subtitle ? `<div class="subtitle">${escapeHtml(card.subtitle)}</div>` : ''}
    </div><div class="badge ${pass ? 'pass' : 'fail'}">${pass ? 'PASS' : 'FAIL'}</div></div>
    ${card.expected || card.got ? `<div class="expect">${card.expected ? `<b>Expected:</b> ${escapeHtml(card.expected)}` : ''}${card.expected && card.got ? '<br>' : ''}${card.got ? `<b>Got:</b> ${escapeHtml(card.got)}` : ''}</div>` : ''}
    <div class="cols"><div>
      ${config ? `<h2>Admin Portal configuration under test</h2><table>${config}</table>` : ''}
      <h2>Request</h2>
      <pre>${escapeHtml(capture.curl)}</pre>
    </div><div>
      <h2>Response \u00b7 HTTP ${escapeHtml(capture.status)} \u00b7 ${escapeHtml(capture.time)}</h2>
      ${excerpts || `<pre>${escapeHtml(capture.body.slice(0, 1600))}</pre>`}
    </div></div>
    ${card.note ? `<div class="note">${card.note}</div>` : ''}
    <div class="foot"><span>Code under test: ${escapeHtml(meta.code)}</span><span>Full log: ${escapeHtml(card.from)} \u00b7 captured ${escapeHtml(meta.captured)}</span></div>
  </div></body></html>`;
}

const meta = { ticket: spec.ticket, code: codeUnderTest(), captured: new Date().toISOString().slice(0, 16).replace('T', ' ') };
const browser = await chromium.launch({ channel: args.browser || 'chrome', headless: !args.headed });
const context = await browser.newContext({ viewport: { width: 1280, height: 900 }, deviceScaleFactor: 2 });

for (const card of spec.cards) {
  const capture = parseCapture(join(rawDir, card.from));
  const page = await context.newPage();
  await page.setContent(cardHtml(card, capture, meta), { waitUntil: 'load' });
  const path = join(outDir, `${spec.ticket}_${card.tc}_${slug(card.title)}.png`);
  await page.locator('.card').screenshot({ path });
  await page.close();
  console.log(`\ud83d\uddbc  ${card.tc}  HTTP ${capture.status}  ->  ${path}`);
}

await browser.close();
