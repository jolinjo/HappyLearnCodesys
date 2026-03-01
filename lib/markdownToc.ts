/**
 * 從標題文字產生 HTML id 用 slug（與 rehype 標題 id 一致）。
 */
export function slugify(text: string): string {
  const t = text
    .replace(/\s+/g, "-")
    .replace(/[、。，．]/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
  return t || "heading";
}

/** 將 Markdown 原始標題文字轉成純文字（移除反引號與簡單 HTML 標籤），以便與實際渲染後的 heading 對齊。 */
function normalizeHeadingSource(text: string): string {
  return text
    // `code` → code
    .replace(/`([^`]+)`/g, "$1")
    // <span class="...">X</span> → X 等簡單 HTML 標籤
    .replace(/<\/?[^>]+>/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

export interface TocItem {
  level: 1 | 2 | 3;
  text: string;
  id: string;
}

/**
 * 從 Markdown 原始字串解析一～三級標題，產出 TOC 清單（id 與之後 rehype 寫入的 id 一致）。
 */
export function parseHeadings(content: string): TocItem[] {
  const re = /^(#{1,3})\s+(.+)$/gm;
  const items: { level: 1 | 2 | 3; text: string }[] = [];
  let m: RegExpExecArray | null;
  while ((m = re.exec(content)) !== null) {
    const level = (m[1].length === 1 ? 1 : m[1].length === 2 ? 2 : 3) as 1 | 2 | 3;
    const rawText = m[2].trim();
    const text = normalizeHeadingSource(rawText);
    if (text) items.push({ level, text });
  }
  const seen = new Map<string, number>();
  return items.map(({ level, text }) => {
    let id = slugify(text);
    if (seen.has(id)) {
      const n = seen.get(id)! + 1;
      seen.set(id, n);
      id = `${id}-${n}`;
    } else {
      seen.set(id, 1);
    }
    return { level, text, id };
  });
}
