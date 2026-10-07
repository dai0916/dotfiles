#!/usr/bin/env node
/**
 * UI Review Screenshot Tool
 *
 * Usage:
 *   node screenshot.mjs <base-url> <output-dir> [--pages "/,/about,/settings"]
 *
 * Captures desktop/mobile x light/dark x full/fold screenshots.
 * Requires: playwright (installed in project or globally)
 */

import { mkdirSync } from "fs";
import { execSync } from "child_process";
import { createRequire } from "module";

// Resolve playwright from the current working directory's node_modules
let chromium;
try {
  const require = createRequire(process.cwd() + "/package.json");
  ({ chromium } = require("playwright"));
} catch {
  console.log("📦 Installing playwright...");
  execSync("npm install -D playwright && npx playwright install chromium", {
    stdio: "inherit",
    cwd: process.cwd(),
  });
  const require = createRequire(process.cwd() + "/package.json");
  ({ chromium } = require("playwright"));
}

const args = process.argv.slice(2);
const baseUrl = args[0] || "http://localhost:3000";
const outDir = args[1] || "/tmp/ui-review-screenshots";

// Parse --pages flag
let pages = ["/"];
const pagesIdx = args.indexOf("--pages");
if (pagesIdx !== -1 && args[pagesIdx + 1]) {
  pages = args[pagesIdx + 1].split(",").map((p) => p.trim());
}

mkdirSync(outDir, { recursive: true });

const viewports = [
  { name: "desktop", width: 1280, height: 900 },
  { name: "mobile", width: 375, height: 812 },
];

const themes = ["light", "dark"];

async function captureAll() {
  for (const theme of themes) {
    const browser = await chromium.launch();

    for (const vp of viewports) {
      const context = await browser.newContext({
        viewport: { width: vp.width, height: vp.height },
        colorScheme: theme,
      });
      const page = await context.newPage();

      for (const pagePath of pages) {
        const url = `${baseUrl}${pagePath}`;
        const pageName =
          pages.length === 1
            ? ""
            : (pagePath === "/"
                ? "home"
                : pagePath.replace(/\//g, "-").replace(/^-/, "")) + "-";

        try {
          await page.goto(url, { waitUntil: "networkidle", timeout: 15000 });
          await page.waitForTimeout(500);
        } catch (e) {
          console.error(`⚠ Failed to load ${url}: ${e.message}`);
          continue;
        }

        // Full page
        await page.screenshot({
          path: `${outDir}/${pageName}${vp.name}-${theme}-full.png`,
          fullPage: true,
        });

        // Above the fold
        await page.screenshot({
          path: `${outDir}/${pageName}${vp.name}-${theme}-fold.png`,
        });

        console.log(`✓ ${pageName || "/  "}${vp.name}-${theme}`);
      }

      await context.close();
    }

    await browser.close();
  }

  console.log(`\n📸 Screenshots saved to ${outDir}/`);
}

captureAll().catch((err) => {
  console.error("❌ Screenshot failed:", err.message);
  process.exit(1);
});
