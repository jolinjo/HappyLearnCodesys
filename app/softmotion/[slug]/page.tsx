import path from "path";
import Link from "next/link";
import { notFound } from "next/navigation";
import { learningMap } from "@/lib/learningMap";
import { offlineHelpToc } from "@/lib/offlineHelpToc";
import { readMarkdown, readTextFile, listStFiles } from "@/lib/contentLoader";
import { highlightSt } from "@/lib/syntaxHighlighter";
import { MarkdownWithToc } from "@/components/MarkdownWithToc";
import { StCodeBlock } from "@/components/StCodeBlock";

interface SoftMotionExamplePageProps {
  params: Promise<{ slug: string }>;
}

const softmotionLibrary = learningMap.libraries.find(
  (lib) => lib.id === "softmotion",
);

export function generateStaticParams() {
  if (!softmotionLibrary) {
    return [];
  }

  return softmotionLibrary.sections.flatMap((section) =>
    section.examples.map((example) => ({
      slug: example.id,
    })),
  );
}

export default async function SoftMotionExamplePage({
  params,
}: SoftMotionExamplePageProps) {
  const { slug } = await params;

  if (!softmotionLibrary) {
    notFound();
  }

  const example = softmotionLibrary.sections
    .flatMap((section) => section.examples)
    .find((ex) => ex.id === slug);

  if (!example) {
    notFound();
  }

  let markdown: string;
  try {
    markdown = await readMarkdown(example.mdPath);
  } catch {
    markdown = `## 說明檔尚未同步\n\n此範例的說明 Markdown 尚未複製到教學網站，請先從專案根目錄執行：\n\`node tutorial-site/scripts/sync-content.js\`\n\n下方仍會顯示本範例的 ST 程式碼。`;
  }

  const contentDir = path.dirname(example.mdPath);
  const stFiles = await listStFiles(contentDir);
  const stBlocks: { title: string; html: string }[] = [];
  for (const entry of stFiles) {
    const code = await readTextFile(entry.path);
    const html = await highlightSt(code);
    stBlocks.push({ title: entry.name, html });
  }

  // 依範例設定的 relatedHelpIds 找出對應的 Offline Help 文章
  const relatedHelp =
    example.relatedHelpIds?.flatMap((id) => {
      const items: {
        sectionId: string;
        sectionTitle: string;
        articleId: string;
        articleTitle: string;
        description: string;
      }[] = [];
      for (const section of offlineHelpToc.sections) {
        const article = section.articles.find((a) => a.id === id);
        if (article) {
          items.push({
            sectionId: section.id,
            sectionTitle: section.title,
            articleId: article.id,
            articleTitle: article.title,
            description: article.description,
          });
        }
      }
      return items;
    }) ?? [];

  return (
    <div className="space-y-5">
      <nav className="text-xs" style={{ color: "var(--t-text-muted)" }}>
        <Link href="/softmotion" style={{ color: "var(--t-accent)" }}>
          SoftMotion 學習地圖
        </Link>
        <span className="mx-1">/</span>
        <span style={{ color: "var(--t-text)" }}>{example.title}</span>
      </nav>

      <header className="space-y-1">
        <div
          className="inline-flex items-center gap-2 rounded-full border px-2 py-1 text-[11px] font-medium"
          style={{
            borderColor: "var(--t-border)",
            backgroundColor: "var(--t-bg-card)",
            color: "var(--t-text-muted)",
          }}
        >
          <span className="uppercase tracking-wide">{example.category}</span>
          <span
            className="h-1 w-1 rounded-full"
            style={{ backgroundColor: "var(--t-accent)" }}
          />
          <span style={{ color: "var(--t-accent)" }}>步驟 {example.order}</span>
        </div>
        <h1
          className="text-xl font-semibold"
          style={{ color: "var(--t-text)" }}
        >
          {example.title}
        </h1>
        <p
          className="text-sm"
          style={{ color: "var(--t-text-muted)" }}
        >
          {example.summary}
        </p>
        <p
          className="text-xs"
          style={{ color: "var(--t-text-muted)" }}
        >
          官方專案：{" "}
          <code
            className="rounded px-1 py-0.5"
            style={{
              backgroundColor: "var(--t-border)",
              color: "var(--t-text)",
            }}
          >
            {example.projectName}
          </code>
        </p>
      </header>

      <section
        className="rounded-lg border p-4"
        style={{
          borderColor: "var(--t-border)",
          backgroundColor: "var(--t-bg-card)",
        }}
      >
        <MarkdownWithToc content={markdown} />
      </section>

      {relatedHelp.length > 0 && (
        <section className="space-y-2">
          <h2
            className="text-base font-semibold"
            style={{ color: "var(--t-text)" }}
          >
            延伸閱讀：Offline Help
          </h2>
          <p
            className="text-xs"
            style={{ color: "var(--t-text-muted)" }}
          >
            建議搭配以下 Offline Help 教學，一起理解 CODESYS 開發系統與基礎操作。
          </p>
          <ul className="space-y-1.5 text-xs">
            {relatedHelp.map((item) => (
              <li key={`${item.sectionId}-${item.articleId}`}>
                <Link
                  href={`/offline-help/${item.sectionId}/${item.articleId}`}
                  className="hover:underline"
                  style={{ color: "var(--t-accent)" }}
                >
                  {item.articleTitle}
                </Link>
              </li>
            ))}
          </ul>
        </section>
      )}

      {stBlocks.length > 0 && (
        <section className="space-y-3">
          <h2
            className="text-base font-semibold"
            style={{ color: "var(--t-text)" }}
          >
            ST 程式碼
          </h2>
          <p
            className="text-xs"
            style={{ color: "var(--t-text-muted)" }}
          >
            以下為本範例的 ST 檔，預設收合；可展開後使用「放大」或字體大小按鈕閱讀。
          </p>
          <div className="space-y-2">
            {stBlocks.map((block) => (
              <StCodeBlock
                key={block.title}
                title={block.title}
                html={block.html}
              />
            ))}
          </div>
        </section>
      )}
    </div>
  );
}

