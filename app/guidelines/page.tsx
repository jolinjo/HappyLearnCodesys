import { readMarkdown } from "@/lib/contentLoader";
import { MarkdownWithToc } from "@/components/MarkdownWithToc";

const GUIDELINES_PATH = "guidelines/CODESYS_開發規範_CFC_SFC_ST.md";

export default async function GuidelinesPage() {
  let markdown: string;
  try {
    markdown = await readMarkdown(GUIDELINES_PATH);
  } catch {
    markdown =
      "## 內容尚未同步\n\n請從專案根目錄執行：\n`node tutorial-site/scripts/sync-content.js`";
  }

  return (
    <div className="space-y-5">
      <header className="space-y-1">
        <h2
          className="text-lg font-semibold"
          style={{ color: "var(--t-accent)" }}
        >
          開發規範與語言搭配
        </h2>
        <p
          className="text-sm"
          style={{ color: "var(--t-text-muted)" }}
        >
          ST / CFC / SFC / FBD / LD 在專案裡各自適合放哪邊，用實際場景來說明。
        </p>
      </header>

      <section
        className="rounded-lg border p-4 text-sm"
        style={{
          borderColor: "var(--t-border)",
          backgroundColor: "var(--t-bg-card)",
          color: "var(--t-text-muted)",
        }}
      >
        <h3
          className="font-semibold mb-2"
          style={{ color: "var(--t-accent)" }}
        >
          如何使用這份規範
        </h3>
        <ul className="list-disc list-inside space-y-1">
          <li>
            <strong style={{ color: "var(--t-text)" }}>先看第 1 節</strong>：了解各語言的定位（ST 當核心、CFC 拼裝、SFC 管流程）。
          </li>
          <li>
            <strong style={{ color: "var(--t-text)" }}>再看第 2 節</strong>：上層 SFC、中層 CFC、底層 ST 的分層架構。
          </li>
          <li>
            <strong style={{ color: "var(--t-text)" }}>實作時對照第 5 節</strong>：單軸站、多工位、三軸機床、轉盤、SCARA 飛抓等實際範例的語言搭配建議。
          </li>
        </ul>
      </section>

      <section
        className="rounded-lg border p-4"
        style={{
          borderColor: "var(--t-border)",
          backgroundColor: "var(--t-bg-card)",
        }}
      >
        <MarkdownWithToc content={markdown} />
      </section>
    </div>
  );
}
