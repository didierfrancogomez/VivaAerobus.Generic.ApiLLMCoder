// One-off: dump the editor's data-schemapath values that match a prefix.
//   node dump-paths.mjs --section Payments --channel web --prefix cardPayment.banks
import { join } from 'node:path';
import { TOOL_DIR, openBrowser, parseArgs } from './lib.mjs';

const args = parseArgs(process.argv.slice(2));
const section = args.section || 'Payments';
const prefix = args.prefix || '';

const state = join(TOOL_DIR, '.auth', 'admin-portal.json');
const { browser, page } = await openBrowser({ ...args, state });
await page.goto(`http://localhost:9507/${section}`, { waitUntil: 'domcontentloaded' });
await page.waitForFunction(() => location.pathname.startsWith('/login') || document.querySelector('#editor-holder > *'));
if (new URL(page.url()).pathname.startsWith('/login')) { console.log('SESSION EXPIRED'); await browser.close(); process.exit(2); }
await page.locator('#editor-holder > *').first().waitFor();

const paths = await page.evaluate(() => [...document.querySelectorAll('[data-schemapath]')]
  .map(e => e.getAttribute('data-schemapath').replace(/^root\./, '')));

const matched = paths.filter(p => p.startsWith(prefix));
console.log(`total paths: ${paths.length} · matching "${prefix}": ${matched.length}`);
console.log(matched.slice(0, 60).join('\n'));

await browser.close();
