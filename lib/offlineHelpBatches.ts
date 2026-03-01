export interface OfflineHelpBatch {
  /** 批次 id，同時用在 URL （例如 `/offline-help/batch/batch-01-codesys-overview`） */
  id: string;
  /** 顯示用標題（含批次編號與主題） */
  title: string;
  /** 簡短描述，說明本批次在教什麼、適合什麼階段閱讀 */
  description: string;
  /**
   * Markdown 相對路徑，基準為 `tutorial-site/content`。
   *
   * 目前 Offline Help 的批次說明仍放在 `Offline-Help/batches` 底下，
   * 若未同步到 `content/offline-help/batches`，前端會顯示「尚未同步」提示。
   */
  mdPath: string;
  /** 建議先閱讀或搭配閱讀的 Offline Help 文章 id（對應 `offlineHelpToc` 中的 `OfflineHelpArticle.id`） */
  recommendedTopics: string[];
}

export interface OfflineHelpBatches {
  batches: OfflineHelpBatch[];
}

/**
 * Offline Help 批次學習規劃（Batch 01～06）。
 *
 * - `mdPath` 預留給未來同步到 `tutorial-site/content/offline-help/batches` 的 Markdown。
 * - `recommendedTopics` 目前僅先關聯概觀類文章，之後可以逐步補齊。
 */
export const offlineHelpBatches: OfflineHelpBatches = {
  batches: [
    {
      id: "batch-01-codesys-overview",
      title: "Batch 01：CODESYS 概觀與入門教學",
      description:
        "從 CODESYS Development System 的整體環境、相容性與第一個專案開始，建立對 IDE 與平台的基本認識。",
      mdPath: "offline-help/batches/Batch_01_Codesys_Overview.md",
      recommendedTopics: ["codesys-overview", "codesys-getting-started"],
    },
    {
      id: "batch-02-project-lifecycle",
      title: "Batch 02：專案生命週期（建立、匯出、保護）",
      description:
        "涵蓋專案建立、設定、匯出與比較，以及保護與封存的完整生命週期，適合負責專案管理與交接的人員。",
      mdPath: "offline-help/batches/Batch_02_Project_Lifecycle.md",
      recommendedTopics: [],
    },
    {
      id: "batch-03-io-and-application",
      title: "Batch 03：I/O 組態與應用程式程式設計總覽",
      description:
        "說明 Device Tree、I/O Mapping 與 Application 架構，幫助讀者理解程式與硬體如何銜接。",
      mdPath: "offline-help/batches/Batch_03_IO_and_Application_Programming.md",
      recommendedTopics: [],
    },
    {
      id: "batch-04-programming-reference-core",
      title: "Batch 04：程式設計核心參考（語言、變數、運算子）",
      description:
        "整理 CODESYS 語言與編輯器、變數型別與生命週期、運算子分類與範例，是之後閱讀所有程式碼的基礎參考。",
      mdPath: "offline-help/batches/Batch_04_Programming_Reference_Core.md",
      recommendedTopics: [],
    },
    {
      id: "batch-05-download-debug-runtime",
      title: "Batch 05：下載、測試、除錯與執行階段",
      description:
        "聚焦程式從編譯、下載到 PLC、Online Change、Simulation、Trace、Task 監看與 Runtime 監控的完整流程。",
      mdPath: "offline-help/batches/Batch_05_Runtime_and_Debug.md",
      recommendedTopics: [],
    },
    {
      id: "batch-06-libraries-devices-security",
      title: "Batch 06：函式庫、裝置、套件與安全性",
      description:
        "整理 Library/Device Repository、Package 與 License 管理，以及 CODESYS 安全性最佳實務，適合平台維運與系統架構角色。",
      mdPath: "offline-help/batches/Batch_06_Libraries_Devices_Security.md",
      recommendedTopics: [],
    },
  ],
};

