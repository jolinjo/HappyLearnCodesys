import { readMarkdown } from "@/lib/contentLoader";
import { learningMap } from "@/lib/learningMap";

export interface SearchableDoc {
  url: string;
  title: string;
  contentPath: string;
}

export interface SearchResult {
  url: string;
  title: string;
  snippet: string;
}

/** 可搜尋的文件清單：SoftMotion 範例、授權、開發規範 */
export function getSearchableDocs(): SearchableDoc[] {
  const docs: SearchableDoc[] = [];

  docs.push({
    url: "/softmotion",
    title: "SoftMotion 學習地圖總覽",
    contentPath: "softmotion/CODESYS_SoftMotion_官網教學與範例總覽.md",
  });

  const softmotion = learningMap.libraries.find((l) => l.id === "softmotion");
  if (softmotion) {
    for (const section of softmotion.sections) {
      for (const ex of section.examples) {
        docs.push({
          url: `/softmotion/${ex.id}`,
          title: ex.title,
          contentPath: ex.mdPath,
        });
      }
    }
  }

  docs.push(
    { url: "/licensing", title: "RTE 環境與支援硬體", contentPath: "licensing/01_RTE環境與支援硬體.md" },
    { url: "/licensing", title: "授權版本、模組與費用", contentPath: "licensing/02_授權版本模組與費用.md" },
    { url: "/licensing", title: "函式庫總覽與分類", contentPath: "licensing/03_函式庫總覽與分類.md" },
  );
  docs.push({
    url: "/guidelines",
    title: "CODESYS 開發規範（CFC / SFC / ST）",
    contentPath: "guidelines/CODESYS_開發規範_CFC_SFC_ST.md",
  });

  return docs;
}

/** 從 Markdown 純文字中擷取不含 Markdown 語法的片段，方便做 snippet */
function stripMarkdownForSearch(text: string): string {
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

/** 在 text 中找 query 出現位置，截取前後文作為 snippet，長度約 200 字元 */
function snippetAround(text: string, query: string, maxLen = 200): string {
  const lower = text.toLowerCase();
  const q = query.trim().toLowerCase();
  if (!q) return text.slice(0, maxLen);
  const idx = lower.indexOf(q);
  if (idx === -1) return text.slice(0, maxLen);
  const start = Math.max(0, idx - 60);
  const end = Math.min(text.length, idx + q.length + 140);
  let s = text.slice(start, end);
  if (start > 0) s = "…" + s;
  if (end < text.length) s = s + "…";
  return s;
}

const contentCache = new Map<string, string>();

/** 依關鍵字搜尋所有已註冊文件，回傳標題與 snippet */
export async function searchDocs(query: string): Promise<SearchResult[]> {
  const q = query.trim();
  if (!q) return [];

  const docs = getSearchableDocs();
  const results: SearchResult[] = [];

  for (const doc of docs) {
    let text: string;
    if (contentCache.has(doc.contentPath)) {
      text = contentCache.get(doc.contentPath)!;
    } else {
      try {
        text = await readMarkdown(doc.contentPath);
      } catch {
        continue;
      }
      contentCache.set(doc.contentPath, text);
    }

    const plain = stripMarkdownForSearch(text);
    if (!plain.toLowerCase().includes(q.toLowerCase())) continue;

    results.push({
      url: doc.url,
      title: doc.title,
      snippet: snippetAround(plain, q),
    });
  }

  return results;
}
