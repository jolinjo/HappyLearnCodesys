import { createHighlighter } from "shiki";

let highlighterPromise: ReturnType<typeof createHighlighter> | null = null;

async function getHighlighter() {
  if (!highlighterPromise) {
    highlighterPromise = createHighlighter({
      themes: ["github-light"],
      langs: ["pascal"],
    });
  }
  return highlighterPromise;
}

/**
 * 將 ST 程式碼轉成 Shiki 高亮後的 HTML（使用 Pascal 語法近似，淺色背景）。
 */
export async function highlightSt(code: string): Promise<string> {
  const highlighter = await getHighlighter();
  return highlighter.codeToHtml(code, {
    lang: "pascal",
    theme: "github-light",
  });
}
