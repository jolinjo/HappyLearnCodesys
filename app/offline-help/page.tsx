import Link from "next/link";
import { offlineHelpToc } from "@/lib/offlineHelpToc";

export default function OfflineHelpHomePage() {
  return (
    <div className="space-y-6">
      <header className="space-y-2">
        <h1
          className="text-xl font-semibold"
          style={{ color: "var(--t-text)" }}
        >
          CODESYS Offline Help 教學入口
        </h1>
        <p
          className="text-sm leading-relaxed"
          style={{ color: "var(--t-text-muted)" }}
        >
          這裡把 CODESYS 官方 Offline Help 中與開發系統操作、專案管理、I/O 組態、語言基礎、
          下載與除錯、函式庫與安全性相關的重點整理成教學文件，依主題重新分區，方便由淺入深閱讀。
        </p>
      </header>

      {/* 主題目錄：依 Offline-Help/zh-TW 教學檔分區展示 */}
      <section className="space-y-3">
        <h2
          className="text-base font-semibold"
          style={{ color: "var(--t-text)" }}
        >
          主題目錄（依 Offline Help 教學檔分區）
        </h2>
        <p
          className="text-xs"
          style={{ color: "var(--t-text-muted)" }}
        >
          下方依主題將 `Offline-Help/zh-TW` 中的教學文件重新分組。建議從「CODESYS 概觀與入門」開始，依序往右閱讀。
        </p>
        <div className="grid gap-4 md:grid-cols-2">
          {offlineHelpToc.sections.map((section) => (
            <div
              key={section.id}
              className="space-y-2 rounded-lg border p-3"
              style={{
                borderColor: "var(--t-border)",
                backgroundColor: "var(--t-bg-card)",
              }}
            >
              <div>
                <h3
                  className="text-sm font-semibold"
                  style={{ color: "var(--t-text)" }}
                >
                  {section.title}
                </h3>
                <p
                  className="mt-1 text-xs leading-relaxed"
                  style={{ color: "var(--t-text-muted)" }}
                >
                  {section.description}
                </p>
              </div>
              <ul className="space-y-1.5 text-xs">
                {section.articles.map((article) => (
                  <li key={article.id}>
                    <Link
                      href={`/offline-help/${section.id}/${article.id}`}
                      className="block rounded px-1 py-0.5 hover:underline"
                      style={{ color: "var(--t-accent)" }}
                    >
                      {article.title}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}

