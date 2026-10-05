import { chromium } from 'playwright-core';
import { mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fail, parseArgs } from './lib.mjs';

const USAGE = `Usage: node save-session.mjs <url> <session.json> [--browser chrome|msedge] [--minutes 10]

Opens a visible Chrome at <url>. YOU log in (the script never types credentials).
When you close the window, the session (cookies + localStorage) is saved to <session.json>.
The file holds live tokens: keep it under tools/evidence/.auth/ (git-ignored), never commit it or copy it into an evidence folder.`;

const args = parseArgs(process.argv.slice(2));
if (args.help || args._.length < 2)
  fail(USAGE, args.help ? 0 : 1);

const [url, out] = args._;
const path = resolve(out);
mkdirSync(dirname(path), { recursive: true });

const browser = await chromium.launch({ channel: args.browser || 'chrome', headless: false });
const context = await browser.newContext({ viewport: null });
const page = await context.newPage();
await page.goto(url);
console.log(`🔐 Log in in the Chrome window, then CLOSE it. Waiting up to ${args.minutes || 10} min…`);

let saved = false;
const snapshot = async () => {
  try {
    await context.storageState({ path });
    saved = true;
  } catch {
  }
};
const timer = setInterval(snapshot, 1000);
const deadline = setTimeout(() => page.close().catch(() => {}), (+args.minutes || 10) * 60000);

await page.waitForEvent('close', { timeout: 0 });
clearInterval(timer);
await snapshot();
clearTimeout(deadline);
await browser.close().catch(() => {});

if (!saved)
  fail('no session was captured');
console.log(`✔ session saved: ${path}`);
