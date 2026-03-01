export interface OfflineHelpArticle {
  /** 文章在 Offline Help 區內的唯一 id（也作為 URL slug 的最後一段） */
  id: string;
  /** 顯示給使用者看的標題（中英文並陳） */
  title: string;
  /** 簡短描述，用在列表或卡片上 */
  description: string;
  /**
   * Markdown 相對路徑，基準為 `tutorial-site/content`。
   * 之後會交給 `readMarkdown()` 讀取。
   */
  mdPath: string;
  /** 可選的標籤，方便之後做篩選或搜尋加權 */
  tags?: string[];
}

export interface OfflineHelpSection {
  /** 區塊 id，同時用在 URL 第一層（例如 `/offline-help/overview/...`） */
  id: string;
  /** 顯示標題 */
  title: string;
  /** 區塊說明文字，顯示在 Offline Help 首頁與側邊目錄上方 */
  description: string;
  /** 本區塊底下的 Offline Help 文章 */
  articles: OfflineHelpArticle[];
}

export interface OfflineHelpToc {
  sections: OfflineHelpSection[];
}

/**
 * Offline Help 教學文件的樹狀結構。
 *
 * 注意：
 * - `mdPath` 一律以 `tutorial-site/content` 為根目錄的相對路徑。
 * - 若對應的 Markdown 尚未同步到 `content/offline-help/...`，前端會顯示「說明檔尚未同步」的提示。
 * - 目前僅先收錄「概觀與入門」相關文章，之後可以依照需要再擴充。
 */
export const offlineHelpToc: OfflineHelpToc = {
  sections: [
    {
      id: "overview",
      title: "CODESYS 概觀與入門",
      description:
        "從 CODESYS Development System 的整體架構與相容性開始，幫助讀者建立對整個平台的高層理解，作為後續所有教學的入口。",
      articles: [
        {
          id: "codesys-overview",
          title: "CODESYS Development System 概觀 Overview 教學整理",
          description:
            "說明 CODESYS Development System 在整體平台中的角色、模組化架構、相容性觀念與 Offline/Online Help 使用方式。",
          mdPath: "offline-help/core/CODESYS_Overview_教學文件.md",
          tags: ["overview", "essentials", "installer", "compatibility"],
        },
        {
          id: "codesys-getting-started",
          title: "CODESYS Getting Started 入門教學",
          description:
            "一步步帶你從安裝 CODESYS、建立第一個 Standard Project，到下載、Simulation 與建立 Boot Application 的完整流程。",
          mdPath: "offline-help/core/CODESYS_GettingStarted_教學文件.md",
          tags: ["getting-started", "tutorial", "simulation"],
        },
      ],
    },
    {
      id: "project-lifecycle",
      title: "專案生命週期與結構",
      description:
        "從專案建立、加入物件與設定，到匯出、比較與保護，建立一套完整的 CODESYS 專案生命週期觀念。",
      articles: [
        {
          id: "project-creation-config",
          title: "Project Creation and Configuration 專案建立與設定 教學整理",
          description:
            "說明如何建立 Standard Project、加入 POUs 與物件、調整編譯器版本與開啟舊版專案，建立穩定的專案結構。",
          mdPath: "offline-help/core/Project_Creation_and_Config_教學文件.md",
          tags: ["project", "creation", "configuration"],
        },
        {
          id: "project-export-compare-protect",
          title:
            "Project Export, Transfer, Compare and Protection 專案匯出、移轉、比較與保護 教學整理",
          description:
            "整理專案匯出／匯入、封存、移轉、比較與保護的實務流程，適合專案交接與版本管理情境。",
          mdPath: "offline-help/core/Project_Export_Compare_Protect_教學文件.md",
          tags: ["project", "export", "compare", "protection"],
        },
      ],
    },
    {
      id: "programming-basics",
      title: "程式設計基礎與語言核心",
      description:
        "從 Application 架構、I/O 組態，到語言、變數與運算子，打好撰寫 CODESYS 程式碼的底層功。",
      articles: [
        {
          id: "application-programming-overview",
          title: "Application Programming 應用程式程式設計總覽 教學整理",
          description:
            "站在應用程式架構角度，說明 PROGRAM / FUNCTION_BLOCK / FUNCTION、Task 與變數層級如何搭配。",
          mdPath:
            "offline-help/core/Application_Programming_Overview_教學文件.md",
          tags: ["application", "architecture"],
        },
        {
          id: "io-configuration",
          title: "IO Configuration I/O 組態與 Device Tree 教學整理",
          description:
            "介紹 Device Tree、Device Editor 與 I/O Mapping 的概念與實務流程，說明程式如何與真實 I/O 銜接。",
          mdPath: "offline-help/core/IO_Configuration_教學文件.md",
          tags: ["io", "device-tree", "mapping"],
        },
        {
          id: "languages-and-editors",
          title: "Languages and Editors 程式語言與編輯器 教學整理",
          description:
            "整理 ST / FBD / Ladder / SFC 等語言與編輯器特性，特別說明 ST 編輯器與宣告區用法。",
          mdPath: "offline-help/core/Languages_and_Editors_教學文件.md",
          tags: ["languages", "st", "editors"],
        },
        {
          id: "variables-and-types",
          title: "Variables and Types 變數與型別 教學整理",
          description:
            "從變數生命週期與儲存區角度整理各種 VAR_*、PERSISTENT 與 RETAIN 的語意與適用情境。",
          mdPath: "offline-help/core/Variables_and_Types_教學文件.md",
          tags: ["variables", "types", "lifecycle"],
        },
        {
          id: "operators",
          title: "Operators 運算子 教學整理",
          description:
            "整理算術、比較、位元、位址與型別轉換等運算子的分類與 ST 範例，作為撰寫 ST 程式的快速參考。",
          mdPath: "offline-help/core/Operators_教學文件.md",
          tags: ["operators", "st"],
        },
      ],
    },
    {
      id: "download-debug-runtime",
      title: "下載、測試、除錯與執行階段",
      description:
        "從下載程式到 PLC、Simulation 與 Online Change，到除錯工具與 Runtime 監控，掌握程式在現場的完整生命週期。",
      articles: [
        {
          id: "download-and-online-change",
          title:
            "Download and Online Change 程式下載與線上修改 教學整理",
          description:
            "說明建立通訊、編譯與下載、Boot application 與 Online Change 的差異與實務流程。",
          mdPath: "offline-help/core/Download_and_Online_Change_教學文件.md",
          tags: ["download", "online-change"],
        },
        {
          id: "debug-and-monitoring",
          title: "Testing and Debugging 測試與除錯 教學整理",
          description:
            "整理 Simulation、Breakpoints、Stepping、Forcing、Watch List、Trace 與 Task 監看的用法與實務例子。",
          mdPath: "offline-help/core/Debug_and_Monitoring_教學文件.md",
          tags: ["debug", "simulation", "trace"],
        },
        {
          id: "runtime-operation-and-backup",
          title: "Application at Runtime and Backup 執行階段操作與備份 教學整理",
          description:
            "說明運行中應用程式的監控方式、系統變數操作、PLC Log、備份與還原與檔案複製策略。",
          mdPath: "offline-help/core/Runtime_Operation_and_Backup_教學文件.md",
          tags: ["runtime", "backup", "plc-log"],
        },
      ],
    },
    {
      id: "libraries-devices-security",
      title: "函式庫、裝置、套件與安全性",
      description:
        "整理 Library / Device Repository、Package / License 管理與安全性最佳實務，適合作為平台維運的參考。",
      articles: [
        {
          id: "libraries-and-devices",
          title: "Libraries and Devices 函式庫與裝置管理 教學整理",
          description:
            "說明 Library / Device Repository 的角色、安裝與更新流程，以及 Placeholder 與相容性注意事項。",
          mdPath: "offline-help/core/Libraries_and_Devices_教學文件.md",
          tags: ["libraries", "devices", "repository"],
        },
        {
          id: "packages-licenses-and-scripts",
          title: "Packages, Licenses and Scripts 套件、授權與腳本 教學整理",
          description:
            "介紹 CODESYS Package / License 概念與管理方式，並簡介 Script 與 Command-line 的典型應用情境。",
          mdPath: "offline-help/core/Packages_Licenses_and_Scripts_教學文件.md",
          tags: ["packages", "licenses", "scripts"],
        },
        {
          id: "security-best-practices",
          title: "Security Best Practices 安全性實務建議 教學整理",
          description:
            "從專案保護、加密通訊到裝置使用者管理，整理 CODESYS 開發與 Runtime 端的安全性實務建議與 FAQ。",
          mdPath: "offline-help/core/Security_BestPractices_教學文件.md",
          tags: ["security", "encryption", "users"],
        },
      ],
    },
  ],
};

