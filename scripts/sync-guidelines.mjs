#!/usr/bin/env node
/**
 * 將 ExampleFile/CODESYS_開發規範_CFC_SFC_ST.md 同步到 content/guidelines/
 * 使用方式（在專案根目錄）：node tutorial-site/scripts/sync-guidelines.mjs
 */

import { copyFileSync, mkdirSync, existsSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(__dirname, "../..");
const src = join(projectRoot, "ExampleFile", "CODESYS_開發規範_CFC_SFC_ST.md");
const destDir = join(projectRoot, "tutorial-site", "content", "guidelines");
const dest = join(destDir, "CODESYS_開發規範_CFC_SFC_ST.md");

if (!existsSync(src)) {
  console.error("來源檔案不存在:", src);
  process.exit(1);
}
mkdirSync(destDir, { recursive: true });
copyFileSync(src, dest);
console.log("已同步：ExampleFile/CODESYS_開發規範_CFC_SFC_ST.md → tutorial-site/content/guidelines/");
console.log("請在 tutorial-site 目錄執行 npm run build 後再部署。");
