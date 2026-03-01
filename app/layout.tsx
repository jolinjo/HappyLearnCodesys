import type { ReactNode } from "react";
import Link from "next/link";
import "./globals.css";

export const metadata = {
  title: "CODESYS 教學網站",
  description: "針對初學者設計的 CODESYS / SoftMotion 與相關授權、開發規範教學網站。",
};

interface RootLayoutProps {
  children: ReactNode;
}

export default function RootLayout({ children }: RootLayoutProps) {
  return (
    <html lang="zh-Hant">
      <body className="min-h-screen">
        <div className="mx-auto flex min-h-screen max-w-5xl flex-col px-4 py-6">
          <header
            className="mb-6 border-b pb-4"
            style={{ borderColor: "var(--t-border)" }}
          >
            <div className="flex items-start justify-between gap-4">
              <div>
                <h1 className="text-xl font-semibold tracking-tight">
                  <Link href="/" style={{ color: "var(--t-accent)" }} className="hover:underline">
                    CODESYS 教學網站
                  </Link>
                </h1>
                <p
                  className="mt-1 text-sm"
                  style={{ color: "var(--t-text-muted)" }}
                >
                  用比較人性、好理解的方式，陪你把 CODESYS、SoftMotion 與周邊觀念一步一步補齊。
                </p>
              </div>
              <nav className="flex shrink-0 items-center gap-2">
                <Link
                  href="/"
                  className="rounded border px-3 py-1.5 text-sm hover:underline"
                  style={{
                    borderColor: "var(--t-border)",
                    color: "var(--t-text-muted)",
                  }}
                >
                  回首頁
                </Link>
                <Link
                  href="/offline-help"
                  className="rounded border px-3 py-1.5 text-sm hover:underline"
                  style={{
                    borderColor: "var(--t-border)",
                    color: "var(--t-text-muted)",
                  }}
                >
                  Offline Help
                </Link>
                <Link
                  href="/search"
                  className="rounded border px-3 py-1.5 text-sm hover:underline"
                  style={{
                    borderColor: "var(--t-border)",
                    color: "var(--t-text-muted)",
                  }}
                >
                  搜尋
                </Link>
              </nav>
            </div>
          </header>
          <main className="flex-1 pb-8">{children}</main>
          <footer
            className="border-t pt-4 text-xs"
            style={{
              borderColor: "var(--t-border)",
              color: "var(--t-text-muted)",
            }}
          >
            內容來源整理自 CODESYS 官方文件與你的教學筆記，僅供學習使用。
          </footer>
        </div>
      </body>
    </html>
  );
}

