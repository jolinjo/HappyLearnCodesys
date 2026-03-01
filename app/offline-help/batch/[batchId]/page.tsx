import Link from "next/link";
import { notFound } from "next/navigation";
import { offlineHelpBatches } from "@/lib/offlineHelpBatches";
import { offlineHelpToc } from "@/lib/offlineHelpToc";
import { MarkdownWithToc } from "@/components/MarkdownWithToc";

export function generateStaticParams(): { batchId: string }[] {
  return offlineHelpBatches.batches.map((batch) => ({
    batchId: batch.id,
  }));
}

interface OfflineHelpBatchPageProps {
  params: Promise<{ batchId: string }>;
}

export default async function OfflineHelpBatchPage({
  params,
}: OfflineHelpBatchPageProps) {
  const { batchId } = await params;

  const batch = offlineHelpBatches.batches.find((b) => b.id === batchId);
  if (!batch) {
    notFound();
  }

  // 根據 recommendedTopics 找出對應 Offline Help 文章（若有設定）
  const recommendedArticles = batch.recommendedTopics
    .map((id) => {
      for (const section of offlineHelpToc.sections) {
        const article = section.articles.find((a) => a.id === id);
        if (article) {
          return { section, article };
        }
      }
      return null;
    })
    .filter(
      (
        x,
      ): x is {
        section: (typeof offlineHelpToc.sections)[number];
        article: (typeof offlineHelpToc.sections)[number]["articles"][number];
      } => x !== null,
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
        <span>{batch.title}</span>
      </nav>

      <header className="space-y-2">
        <h1
          className="text-xl font-semibold"
          style={{ color: "var(--t-text)" }}
        >
          {batch.title}
        </h1>
        <p
          className="text-sm"
          style={{ color: "var(--t-text-muted)" }}
        >
          {batch.description}
        </p>
      </header>

      <section
        className="rounded-lg border p-4"
        style={{
          borderColor: "var(--t-border)",
          backgroundColor: "var(--t-bg-card)",
        }}
      >
        <MarkdownWithToc
          content={`## 這個批次在學什麼\n\n${batch.description}\n\n> 接下來建議依照下方列出的 Offline Help 教學文章順序閱讀，實際內容都來自 \`Offline-Help/zh-TW\` 中的中文教學文件。`}
        />
      </section>

      {recommendedArticles.length > 0 && (
        <section className="space-y-2">
          <h2
            className="text-sm font-semibold"
            style={{ color: "var(--t-text)" }}
          >
            建議搭配閱讀的 Offline Help 文章
          </h2>
          <ul className="space-y-1.5 text-xs">
            {recommendedArticles.map(({ section, article }) => (
              <li key={article.id}>
                <Link
                  href={`/offline-help/${section.id}/${article.id}`}
                  className="hover:underline"
                  style={{ color: "var(--t-accent)" }}
                >
                  {article.title}
                </Link>
              </li>
            ))}
          </ul>
        </section>
      )}
    </div>
  );
}

