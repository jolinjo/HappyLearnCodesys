/**
 * 建置時產生靜態搜尋索引，供 GitHub Pages 等純靜態環境使用。
 * 執行：從 tutorial-site 目錄 run `npx tsx scripts/generate-search-index.ts`
 */
import { mkdirSync, writeFileSync } from "fs";
import { join } from "path";
import { getSearchableDocs } from "../lib/searchIndex";
import { readMarkdown } from "../lib/contentLoader";

function stripMarkdown(text: string): string {
  return text
    .replace(/#{1,6}\s/g, "")
    .replace(/\*\*([^*]+)\*\*/g, "$1")
    .replace(/\*([^*]+)\*/g, "$1")
    .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")
    .replace(/`([^`]+)`/g, "$1")
    .replace(/\|/g, " ")
    .replace(/\n+/g, " ")
    .trim();
}

interface IndexEntry {
  url: string;
  title: string;
  content: string;
}

async function main() {
  const docs = getSearchableDocs();
  const entries: IndexEntry[] = [];

  for (const doc of docs) {
    try {
      const raw = await readMarkdown(doc.contentPath);
      entries.push({
        url: doc.url,
        title: doc.title,
        content: stripMarkdown(raw),
      });
    } catch {
      // 略過讀取失敗的檔案
    }
  }

  const publicDir = join(process.cwd(), "public");
  mkdirSync(publicDir, { recursive: true });
  const outPath = join(publicDir, "search-index.json");
  writeFileSync(outPath, JSON.stringify(entries), "utf-8");
  console.log(`Wrote ${entries.length} entries to ${outPath}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
