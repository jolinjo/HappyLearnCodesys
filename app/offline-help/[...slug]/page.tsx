import Link from "next/link";
import { notFound } from "next/navigation";
import { readMarkdown } from "@/lib/contentLoader";
import { offlineHelpToc } from "@/lib/offlineHelpToc";
import { offlineHelpBatches } from "@/lib/offlineHelpBatches";
import { MarkdownWithToc } from "@/components/MarkdownWithToc";

export function generateStaticParams(): { slug: string[] }[] {
  return offlineHelpToc.sections.flatMap((section) =>
    section.articles.map((article) => ({
      slug: [section.id, article.id],
    })),
  );
}

interface OfflineHelpArticlePageProps {
  params: Promise<{ slug: string[] }>;
}

export default async function OfflineHelpArticlePage({
  params,
}: OfflineHelpArticlePageProps) {
  const { slug } = await params;

  if (!Array.isArray(slug) || slug.length < 2) {
    notFound();
  }

  const [sectionId, articleId] = slug;

  const section = offlineHelpToc.sections.find((s) => s.id === sectionId);
  if (!section) {
    notFound();
  }

  const article = section.articles.find((a) => a.id === articleId);
  if (!article) {
    notFound();
  }

  let markdown: string;
  try {
    markdown = await readMarkdown(article.mdPath);
  } catch {
    markdown = `## 說明檔尚未同步\n\n此 Offline Help 教學的 Markdown 檔尚未同步到教學網站的 \`content\` 目錄。\n\n請先將 \`${article.mdPath}\` 準備好並放入 \`tutorial-site/content\`，或之後再回到此頁。`;
  }

  // 找出有哪些批次推薦了這篇文章（若有設定）
  const relatedBatches = offlineHelpBatches.batches.filter((batch) =>
    batch.recommendedTopics.includes(article.id),
  );

  return (
    <div className="space-y-5">
      <nav
        className="text-xs"
        style={{ color: "var(--t-text-muted)" }}
      >
        <Link
          href="/offline-help"
          style={{ color: "var(--t-accent)" }}
        >
          Offline Help 首頁
        </Link>
        <span className="mx-1">/</span>
        <span>{section.title}</span>
      </nav>

      <header className="space-y-2">
        <h1
          className="text-xl font-semibold"
          style={{ color: "var(--t-text)" }}
        >
          {article.title}
        </h1>
        <p
          className="text-sm"
          style={{ color: "var(--t-text-muted)" }}
        >
          {article.description}
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

      {relatedBatches.length > 0 && (
        <section className="space-y-2">
          <h2
            className="text-sm font-semibold"
            style={{ color: "var(--t-text)" }}
          >
            相關批次學習路線
          </h2>
          <ul className="space-y-1.5 text-xs">
            {relatedBatches.map((batch) => (
              <li key={batch.id}>
                <Link
                  href={`/offline-help/batch/${batch.id}`}
                  className="hover:underline"
                  style={{ color: "var(--t-accent)" }}
                >
                  {batch.title}
                </Link>
              </li>
            ))}
          </ul>
        </section>
      )}
    </div>
  );
}

