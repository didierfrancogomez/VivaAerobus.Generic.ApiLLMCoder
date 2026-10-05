import { chromium } from 'playwright-core';
import { existsSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const TOOL_DIR = dirname(fileURLToPath(import.meta.url));

export function parseArgs(argv) {
  const args = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const token = argv[i];
    if (!token.startsWith('--')) {
      args._.push(token);
      continue;
    }
    const key = token.slice(2);
    const next = argv[i + 1];
    const value = next === undefined || next.startsWith('--') ? true : (i++, next);
    args[key] = key in args ? [].concat(args[key], value) : value;
  }
  return args;
}

export const list = value => (value === undefined || value === true ? [] : [].concat(value));

export function fail(message, code = 1) {
  if (code === 0)
    console.log(message);
  else
    console.error(`✖ ${message}`);
  process.exit(code);
}

export async function openBrowser(args) {
  const state = args.state && args.state !== true ? resolve(args.state) : undefined;
  if (state && !existsSync(state))
    fail(`session file not found: ${state} — create it first with save-session.mjs (you log in, the script never types credentials)`);
  const browser = await chromium.launch({ channel: args.browser || 'chrome', headless: !args.headed });
  const context = await browser.newContext({
    viewport: { width: +(args.width || 1440), height: +(args.height || 900) },
    ignoreHTTPSErrors: !!args.insecure,
    storageState: state
  });
  const page = await context.newPage();
  page.setDefaultTimeout(+(args.timeout || 30000));
  return { browser, context, page };
}

export async function outline(target, color = 'red') {
  await target.waitFor();
  await target.scrollIntoViewIfNeeded();
  await target.evaluate((element, border) => {
    element.style.outline = `3px solid ${border}`;
    element.style.outlineOffset = '2px';
  }, color);
}

export async function highlight(page, texts, color = 'red') {
  for (const text of texts)
    await outline(page.getByText(text).first(), color);
}

export async function fill(page, selector, value) {
  const target = page.locator(selector).first();
  if ((await target.getAttribute('type')) === 'password')
    throw new Error(`refusing to fill a password field (${selector}) — credentials are typed by the user in save-session.mjs`);
  await target.fill(value);
}

export async function screenshot(page, out, { fullPage = false, selector, masks = [] } = {}) {
  const path = resolve(out);
  mkdirSync(dirname(path), { recursive: true });
  const mask = masks.map(css => page.locator(css));
  if (selector)
    await page.locator(selector).first().screenshot({ path, mask });
  else
    await page.screenshot({ path, fullPage, mask });
  console.log(`🖼  ${path}`);
  return path;
}
