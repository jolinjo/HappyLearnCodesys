import { learningMap } from "@/lib/learningMap";
import Link from "next/link";

const softmotionLibrary = learningMap.libraries.find(
  (lib) => lib.id === "softmotion",
);

export default function SoftMotionPage() {
  if (!softmotionLibrary) {
    return (
      <p className="text-sm text-red-300">
        找不到 SoftMotion 學習地圖定義，請先確認 lib/learningMap.ts 設定。
      </p>
    );
  }

  return (
    <div className="space-y-6">
      <section>
        <h2
          className="text-lg font-semibold"
          style={{ color: "var(--t-accent)" }}
        >
          SoftMotion 學習地圖
        </h2>
        <p
          className="mt-2 text-sm leading-relaxed"
          style={{ color: "var(--t-text-muted)" }}
        >
          建議你先把單軸與 Basic Motion 走順，再往 Robotics / CNC
          走，這樣後面比較不會一頭霧水。下面每一條主線都幫你排好建議順序，之後會連到更完整的範例說明頁。
        </p>
      </section>

      <section className="space-y-5">
        {softmotionLibrary.sections.map((section) => (
          <div
            key={section.id}
            className="rounded-lg border p-4"
            style={{
              borderColor: "var(--t-border)",
              backgroundColor: "var(--t-bg-card)",
            }}
          >
            <div className="mb-3">
              <h3
                className="text-sm font-semibold"
                style={{ color: "var(--t-text)" }}
              >
                {section.title}
              </h3>
              <p
                className="mt-1 text-xs"
                style={{ color: "var(--t-text-muted)" }}
              >
                {section.description}
              </p>
            </div>

            <ol className="space-y-2">
              {section.examples
                .slice()
                .sort((a, b) => a.order - b.order)
                .map((example) => (
                  <li
                    key={example.id}
                    className="flex items-start gap-3 rounded-md border p-3"
                    style={{
                      borderColor: "var(--t-border)",
                      backgroundColor: "var(--t-bg-code)",
                    }}
                  >
                    <span
                      className="mt-0.5 inline-flex h-5 w-5 flex-none items-center justify-center rounded-full text-xs font-semibold"
                      style={{
                        backgroundColor: "var(--t-accent)",
                        color: "var(--t-bg)",
                      }}
                    >
                      {example.order}
                    </span>
                    <div className="flex-1 space-y-1">
                      <div className="flex flex-wrap items-center gap-x-2 gap-y-1">
                        <span
                          className="text-xs font-semibold uppercase tracking-wide"
                          style={{ color: "var(--t-accent)" }}
                        >
                          {example.category}
                        </span>
                        <span
                          className="text-sm font-medium"
                          style={{ color: "var(--t-text)" }}
                        >
                          {example.title}
                        </span>
                      </div>
                      <p
                        className="text-xs leading-relaxed"
                        style={{ color: "var(--t-text-muted)" }}
                      >
                        {example.summary}
                      </p>
                    </div>
                    <div className="ml-2 flex flex-col gap-1">
                      <Link
                        href={`/softmotion/${example.id}`}
                        className="rounded border px-2 py-1 text-[11px] font-medium hover:opacity-90"
                        style={{
                          borderColor: "var(--t-border)",
                          backgroundColor: "var(--t-bg-card)",
                          color: "var(--t-accent)",
                        }}
                      >
                        查看範例說明
                      </Link>
                    </div>
                  </li>
                ))}
            </ol>
          </div>
        ))}
      </section>
    </div>
  );
}

