import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { TOOL_DIR, fail, highlight, list, openBrowser, outline, parseArgs, screenshot } from './lib.mjs';

const USAGE = `Usage:
  node admin-portal.mjs --login
  node admin-portal.mjs --check
  node admin-portal.mjs --section Services --out <file.png> [--channel web|mobile|kiosk|whatsapp|callcenter|express]
                        [--node train] [--field train.enabled]... [--color red|green]
                        [--highlight text]... [--full] [--mask css]...
                        [--base http://localhost:9507] [--state <session.json>] [--headed] [--wait ms]

--section  route of the left menu (/Services, /Features, /Basket, /BookingRules, /Payments, ...).
--node     JSON path of the block to capture (header + that block only). Without it: the viewport around
           the first --field, or the whole page with --full (a section can be 35,000+ px tall).
--field    JSON path of a property to outline (the editor's data-schemapath without "root.").
           Array items are indexed: services.0.code. An unknown path lists the top-level nodes.
--caption  banner on top of the captured block: a text, or "auto" = section > node [channel]: field=value … — time.`;

const schemaPath = path => `[data-schemapath="root.${path.replace(/^root\.?/, '')}"]`;

async function fieldValue(field) {
  return field.evaluate(element => {
    const input = element.querySelector('input, select, textarea');
    if (!input)
      return '(block)';
    return input.type === 'checkbox' ? String(input.checked) : input.value;
  });
}

async function addCaption(anchor, text) {
  await anchor.evaluate((element, caption) => {
    const banner = document.createElement('div');
    banner.textContent = caption;
    banner.style.cssText = 'background:#0f172a;color:#fff;font:600 14px "Segoe UI",sans-serif;padding:8px 12px;border-radius:6px;margin:0 0 10px;';
    element.prepend(banner);
  }, text);
}

async function topLevelNodes(page) {
  return page.evaluate(() => [...document.querySelectorAll('[data-schemapath]')]
    .map(element => element.getAttribute('data-schemapath'))
    .filter(path => path.split('.').length === 2)
    .map(path => path.slice('root.'.length))
    .join(', '));
}

async function locate(page, path) {
  const target = page.locator(schemaPath(path)).first();
  if (!(await target.count()))
    throw new Error(`no node '${path}' in this section — top-level nodes: ${await topLevelNodes(page)}`);
  return target;
}

async function captureNode(page, node, out, masks) {
  const header = await page.locator('nav.v-toolbar').first().boundingBox();
  const bar = page.locator('.save-button-container').first();
  const saveBar = (await bar.count()) ? await bar.boundingBox() : null;
  const offset = Math.ceil(header?.height ?? 0) + 8;
  const footer = Math.ceil(saveBar?.height ?? 0);
  const { height } = await node.boundingBox();
  const { width } = page.viewportSize();
  await page.setViewportSize({ width, height: Math.min(Math.ceil(height) + offset + footer + 16, 16000) });
  await node.evaluate((element, top) => window.scrollTo(0, element.getBoundingClientRect().top + window.scrollY - top), offset);
  await screenshot(page, out, { masks });
}

const CHANNELS = ['web', 'mobile', 'kiosk', 'whatsapp', 'callcenter', 'express'];
const SESSION_EXPIRED = 2;

const args = parseArgs(process.argv.slice(2));
const base = (args.base || 'http://localhost:9507').replace(/\/$/, '');
const state = args.state && args.state !== true ? args.state : join(TOOL_DIR, '.auth', 'admin-portal.json');

if (args.help)
  fail(USAGE, 0);

if (args.login) {
  const result = spawnSync(process.execPath, [join(TOOL_DIR, 'save-session.mjs'), `${base}/login`, state], { stdio: 'inherit' });
  process.exit(result.status ?? 1);
}

if (args.check) {
  if (!existsSync(state))
    fail(`no session at ${state} — run: node admin-portal.mjs --login`, SESSION_EXPIRED);
  const origin = JSON.parse(readFileSync(state, 'utf8')).origins?.find(o => o.origin === base);
  const vuex = origin?.localStorage?.find(item => item.name === 'vuex')?.value;
  const token = vuex ? JSON.parse(vuex).auth?.token : null;
  if (!token)
    fail(`session file exists but holds no Admin Portal token for ${base} — run: node admin-portal.mjs --login`, SESSION_EXPIRED);
  const claims = token.split('.').length === 3 ? JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString()) : {};
  const minutesLeft = claims.exp ? Math.floor((claims.exp * 1000 - Date.now()) / 60000) : null;
  if (minutesLeft !== null && minutesLeft <= 0)
    fail(`the Admin Portal token expired at ${new Date(claims.exp * 1000).toISOString()} (it lasts 60 min) — run: node admin-portal.mjs --login`, SESSION_EXPIRED);
  console.log(`✔ Admin Portal session present for ${base} (token not printed)${minutesLeft !== null ? ` — expires in ${minutesLeft} min` : ''}`);
  process.exit(0);
}

if (!args.section || !args.out)
  fail(USAGE);

const channel = (args.channel || 'web').toLowerCase();
if (!CHANNELS.includes(channel))
  fail(`unknown channel '${channel}' — one of: ${CHANNELS.join(', ')}`);

const { browser, page } = await openBrowser({ ...args, state });
let exitCode = 0;
try {
  await page.goto(`${base}/${args.section.replace(/^\//, '')}`, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => location.pathname.startsWith('/login') || document.querySelector('#editor-holder > *'));
  if (new URL(page.url()).pathname.startsWith('/login'))
    throw Object.assign(new Error('redirected to /login: the session expired or is missing — run: node admin-portal.mjs --login'), { exitCode: SESSION_EXPIRED });

  if (channel !== 'web') {
    const button = page.locator('nav.v-toolbar button').filter({ hasText: new RegExp(`^\\s*${channel}\\s*$`, 'i') });
    const reloaded = page.waitForResponse(response => response.url().includes('/configpartgetvalues'));
    await button.click();
    await reloaded;
    await page.locator('nav.v-toolbar button.active-channel').filter({ hasText: new RegExp(`^\\s*${channel}\\s*$`, 'i') }).waitFor();
  }

  await page.locator('#editor-holder > *').first().waitFor();
  if (args.wait)
    await page.waitForTimeout(+args.wait);

  const inherit = page.locator('#checkbox');
  const inheriting = channel !== 'web' && (await inherit.count()) ? await inherit.isChecked() : null;
  if (inheriting !== null)
    console.log(`ℹ ${channel}: "Inherit From Web Channel" = ${inheriting}`);

  const paths = list(args.field);
  const fields = [];
  for (const path of paths)
    fields.push(await locate(page, path));
  for (const field of fields)
    await outline(field, args.color);
  await highlight(page, list(args.highlight), args.color);

  if (args.caption) {
    const values = [];
    for (const [index, field] of fields.entries())
      values.push(`${paths[index]}=${await fieldValue(field)}`);
    const text = args.caption !== 'auto' ? args.caption : [
      `${args.section.replace(/^\//, '')} > ${args.node || paths[0] || 'section'} [${channel}]`,
      values.length ? `: ${values.join(', ')}` : '',
      inheriting !== null ? ` · inherit from web=${inheriting}` : '',
      ` — ${new Date().toISOString()} · local Admin Portal`
    ].join('');
    await addCaption(args.node ? await locate(page, args.node) : fields[0] ?? page.locator('#editor-holder'), text);
  }

  if (args.node)
    await captureNode(page, await locate(page, args.node), args.out, list(args.mask));
  else {
    if (fields.length)
      await fields[0].evaluate(element => element.scrollIntoView({ block: 'center' }));
    await screenshot(page, args.out, { fullPage: !!args.full, masks: list(args.mask) });
  }
} catch (error) {
  console.error(`✖ ${error.message.split('\n')[0]} (page: ${page.url()})`);
  exitCode = error.exitCode || 1;
} finally {
  await browser.close();
}
process.exit(exitCode);
