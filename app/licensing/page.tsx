import { readMarkdown } from "@/lib/contentLoader";
import { MarkdownRenderer } from "@/components/MarkdownRenderer";
import { LicensingTabs } from "./LicensingTabs";

const LICENSING_DOCS = [
  {
    id: "rte",
    title: "RTE 環境與支援硬體",
    path: "licensing/01_RTE環境與支援硬體.md",
  },
  {
    id: "modules",
    title: "授權版本、模組與費用",
    path: "licensing/02_授權版本模組與費用.md",
  },
  {
    id: "libraries",
    title: "函式庫總覽與分類",
    path: "licensing/03_函式庫總覽與分類.md",
  },
] as const;

export default async function LicensingPage() {
  const contents = await Promise.all(
    LICENSING_DOCS.map(async (doc) => {
      let markdown: string;
      try {
        markdown = await readMarkdown(doc.path);
      } catch {
        markdown = `## 內容尚未同步\n\n請從專案根目錄執行：\n\`node tutorial-site/scripts/sync-content.js\``;
      }
      return { id: doc.id, title: doc.title, markdown };
    }),
  );

  return (
    <div className="space-y-5">
      <header className="space-y-1">
        <h2
          className="text-lg font-semibold"
          style={{ color: "var(--t-accent)" }}
        >
          CODESYS 授權與環境
        </h2>
        <p
          className="text-sm"
          style={{ color: "var(--t-text-muted)" }}
        >
          用白話整理 RTE、Control、授權模組與函式庫分類，方便你選型與查閱。
        </p>
      </header>

      <LicensingTabs items={contents} />
    </div>
  );
}
