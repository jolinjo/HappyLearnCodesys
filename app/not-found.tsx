import Link from "next/link";

export default function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center gap-4 py-12 text-center">
      <p
        className="text-4xl font-semibold"
        style={{ color: "var(--t-text-muted)" }}
      >
        404
      </p>
      <p style={{ color: "var(--t-text-muted)" }}>找不到這個頁面。</p>
      <nav className="mt-4 flex flex-wrap justify-center gap-3">
        <Link
          href="/"
          className="rounded border px-4 py-2 text-sm hover:opacity-90"
          style={{
            borderColor: "var(--t-border)",
            backgroundColor: "var(--t-bg-card)",
            color: "var(--t-accent)",
          }}
        >
          回首頁
        </Link>
        <Link
          href="/softmotion"
          className="rounded border px-4 py-2 text-sm hover:opacity-90"
          style={{
            borderColor: "var(--t-border)",
            color: "var(--t-text-muted)",
          }}
        >
          SoftMotion 學習地圖
        </Link>
        <Link
          href="/licensing"
          className="rounded border px-4 py-2 text-sm hover:opacity-90"
          style={{
            borderColor: "var(--t-border)",
            color: "var(--t-text-muted)",
          }}
        >
          授權說明
        </Link>
        <Link
          href="/guidelines"
          className="rounded border px-4 py-2 text-sm hover:opacity-90"
          style={{
            borderColor: "var(--t-border)",
            color: "var(--t-text-muted)",
          }}
        >
          開發規範
        </Link>
      </nav>
    </div>
  );
}
