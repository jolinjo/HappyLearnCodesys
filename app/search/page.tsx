import { Suspense } from "react";
import { SearchUI } from "./SearchUI";

export default function SearchPage() {
  return (
    <div className="space-y-5">
      <header>
        <h2
          className="text-lg font-semibold"
          style={{ color: "var(--t-text)" }}
        >
          站內搜尋
        </h2>
        <p
          className="mt-1 text-sm"
          style={{ color: "var(--t-text-muted)" }}
        >
          可搜尋函數／功能塊名稱（如 MC_Power、SMC_ReadNCFile2）或關鍵字，結果來自範例說明、授權與開發規範文件。
        </p>
      </header>
      <Suspense
        fallback={
          <p className="text-sm" style={{ color: "var(--t-text-muted)" }}>
            載入中…
          </p>
        }
      >
        <SearchUI initialQuery="" />
      </Suspense>
    </div>
  );
}
