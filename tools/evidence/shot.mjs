import { readFileSync } from 'node:fs';
import { fail, fill, highlight, list, openBrowser, parseArgs, screenshot } from './lib.mjs';

const USAGE = `Usage:
  node shot.mjs <url> <out.png> [--full] [--selector css] [--wait-for css] [--wait ms]
                [--click selector]... [--highlight text]... [--color red|green]
                [--mask css]... [--state session.json] [--width 1440] [--height 900]
                [--headed] [--insecure] [--browser chrome|msedge] [--timeout ms]
  node shot.mjs --steps flow.json [same browser options]

flow.json = array of steps, run in order:
  { "goto": "https://..." }            { "click": "text=MOBILE" }
  { "fill": "#search", "value": "x" }  { "press": "Enter" }
  { "waitFor": "css or text=..." }     { "wait": 1000 }
  { "highlight": "label text", "color": "green" }
  { "screenshot": "out.png", "fullPage": true, "selector": "css", "mask": ["css"] }`;

const args = parseArgs(process.argv.slice(2));
if (args.help || (!args.steps && args._.length < 2))
  fail(USAGE, args.help ? 0 : 1);

const steps = args.steps
  ? JSON.parse(readFileSync(args.steps, 'utf8'))
  : [
      { goto: args._[0] },
      ...(args['wait-for'] ? [{ waitFor: args['wait-for'] }] : []),
      ...list(args.click).map(click => ({ click })),
      ...(args.wait ? [{ wait: +args.wait }] : []),
      ...list(args.highlight).map(text => ({ highlight: text, color: args.color })),
      { screenshot: args._[1], fullPage: !!args.full, selector: args.selector, mask: list(args.mask) }
    ];

const { browser, page } = await openBrowser(args);
let exitCode = 0;
try {
  for (const step of steps) {
    if (step.goto) await page.goto(step.goto, { waitUntil: 'networkidle' });
    else if (step.click) { await page.locator(step.click).first().click(); await page.waitForLoadState('networkidle'); }
    else if (step.fill) await fill(page, step.fill, step.value);
    else if (step.press) await page.keyboard.press(step.press);
    else if (step.waitFor) await page.locator(step.waitFor).first().waitFor();
    else if (step.wait) await page.waitForTimeout(step.wait);
    else if (step.highlight) await highlight(page, [step.highlight], step.color);
    else if (step.screenshot) await screenshot(page, step.screenshot, { fullPage: step.fullPage, selector: step.selector, masks: step.mask || [] });
    else throw new Error(`unknown step: ${JSON.stringify(step)}`);
  }
} catch (error) {
  console.error(`✖ ${error.message.split('\n')[0]} (page: ${page.url()})`);
  exitCode = 1;
} finally {
  await browser.close();
}
process.exit(exitCode);
