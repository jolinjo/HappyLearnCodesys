import Link from "next/link";

export default function HomePage() {
  return (
    <div className="space-y-6">
      <section
        className="rounded-lg border p-4"
        style={{
          borderColor: "var(--t-border)",
          backgroundColor: "var(--t-bg-card)",
        }}
        >
          <h2 className="text-lg font-semibold" style={{ color: "var(--t-text)" }}>
            歡迎來到 CODESYS 教學網站
          </h2>
          <p
            className="mt-2 text-sm leading-relaxed"
            style={{ color: "var(--t-text-muted)" }}
          >
            這裡的目標不是塞一堆指令給你，而是用比較人話的方式，幫你把 CODESYS、SoftMotion、
            授權選型、還有開發規範串成一條清楚的學習路線。
          </p>
      </section>

      <section className="space-y-2">
        <div
          className="text-xs font-semibold tracking-wide"
          style={{ color: "var(--t-text-muted)" }}
        >
          建議學習路線（由淺入深）
        </div>
        <div className="grid gap-4 md:grid-cols-4">
          <Link
            href="/offline-help"
            className="rounded-lg border p-4 transition hover:opacity-90"
            style={{
              borderColor: "var(--t-border)",
              backgroundColor: "var(--t-bg-card)",
            }}
          >
            <h3
              className="text-sm font-semibold"
              style={{ color: "var(--t-accent)" }}
            >
              Step 1：CODESYS 基礎／Offline Help
            </h3>
            <p
              className="mt-1 text-xs"
              style={{ color: "var(--t-text-muted)" }}
            >
              先從 CODESYS Development System 概觀、專案生命週期與 Offline Help 入門教學開始，把整體地圖看清楚。
            </p>
          </Link>

          <Link
            href="/guidelines"
            className="rounded-lg border p-4 transition hover:opacity-90"
            style={{
              borderColor: "var(--t-border)",
              backgroundColor: "var(--t-bg-card)",
            }}
          >
            <h3
              className="text-sm font-semibold"
              style={{ color: "var(--t-accent)" }}
            >
              Step 2：開發規範與語言搭配
            </h3>
            <p
              className="mt-1 text-xs"
              style={{ color: "var(--t-text-muted)" }}
            >
              整理 ST / CFC / SFC / FBD / LD
              在專案裡各自適合放哪邊，搭配團隊開發規範，先把「怎麼寫程式」的規則定好。
            </p>
          </Link>

          <Link
            href="/licensing"
            className="rounded-lg border p-4 transition hover:opacity-90"
            style={{
              borderColor: "var(--t-border)",
              backgroundColor: "var(--t-bg-card)",
            }}
          >
            <h3
              className="text-sm font-semibold"
              style={{ color: "var(--t-accent)" }}
            >
              Step 3：看懂 CODESYS 授權怎麼選
            </h3>
            <p
              className="mt-1 text-xs"
              style={{ color: "var(--t-text-muted)" }}
            >
              RTE、Control、SoftMotion 軸數、安全控制，各自適合什麼場合，
              讓你在實際專案規劃時能正確評估授權與成本。
            </p>
          </Link>

          <Link
            href="/softmotion"
            className="rounded-lg border p-4 transition hover:opacity-90"
            style={{
              borderColor: "var(--t-border)",
              backgroundColor: "var(--t-bg-card)",
            }}
          >
            <h3
              className="text-sm font-semibold"
              style={{ color: "var(--t-accent)" }}
            >
              Step 4：從 SoftMotion 入門開始
            </h3>
            <p
              className="mt-1 text-xs"
              style={{ color: "var(--t-text-muted)" }}
            >
              在前面基礎都打好之後，再透過學習地圖，從單軸、Basic Motion，
              一路走到 Robotics 與 CNC，實作完整的運動控制應用。
            </p>
          </Link>
        </div>
      </section>
    </div>
  );
}

