## CODESYS SoftMotion 教學網站規格書（初版）

> 目標：為初學者提供一個「看得懂、願意看下去」的 SoftMotion 教學網站，同時保留未來擴充到其他函式庫 / 硬體的彈性。

---

## 1. 專案定位與目標

- **專案名稱**：`tutorial-site`
- **主要對象**：剛接觸 CODESYS / SoftMotion 的工程師與學生。
- **核心目標**：
  - 以「學習地圖」引導初學者，知道 **先學什麼、再學什麼、為什麼要這樣排順序**。
  - 每個範例都有「教練式」、「人性化」的中文解說，重點放在 **概念與理解**，而不只是貼程式碼。
  - 使用者可以直接在瀏覽器裡閱讀對應的 **ST 程式碼**，預設折疊，需要時再展開，並可放大與調整字體。
  - 提供 **搜尋功能**，方便查詢函數名稱、功能塊名稱與關鍵觀念。
  - 保持架構可擴充，未來能加上其他函式庫（例如 Robotics / CNC）與硬體教學。

---

## 2. 技術堆疊與基本約定

- **前端框架**
  - Next.js 14+（App Router）
  - TypeScript
  - React（優先使用 Server Components，必要時才使用 Client Components）
- **樣式與 UI**
  - Tailwind CSS
  - shadcn/ui + Radix UI 作為元件庫
  - Lucide React 作為圖示
- **內容格式**
  - 教學內容與範例說明以 **Markdown** 儲存（`.md`）。
  - ST 程式碼以 `.st` 檔案保存，或內嵌於 Markdown 的程式碼區塊中。
- **語言**
  - 網站內容：**繁體中文**。
  - 系統與程式碼註解：偏技術但盡量白話、易懂。
- **語法高亮**
  - 使用 **Shiki** 在伺服端（SSR）對 ST 程式碼做語法高亮，產生帶 `<span>` 的 HTML，再由前端包裝排版。

---

## 3. 目錄與檔案結構（草案）

根目錄 `tutorial-site/` 預期主要結構：

- `app/`
  - `page.tsx`：網站首頁（整體說明與 SoftMotion 學習入口）。
  - `softmotion/`
    - `page.tsx`：SoftMotion 學習地圖總覽頁。
    - `[slug]/page.tsx`：單一範例說明頁（對應各個範例說明與 ST 程式展示）。
  - `licensing/`
    - `page.tsx`：授權相關總覽與各子主題切換（RTE、授權模組、函式庫分類）。
  - `guidelines/`
    - `page.tsx`：開發規範頁，含自動 TOC 與導讀。
  - `search/`
    - `page.tsx`：搜尋結果頁（函數 / 關鍵字）。
- `content/`
  - `softmotion/`
    - `CODESYS_SoftMotion_官網教學與範例總覽.md`
    - 其他 SoftMotion 範例說明（複製自 `ExampleFile` 子目錄的 `範例英文名稱_整體架構與功能.md`）。
  - `licensing/`
    - `01_RTE環境與支援硬體.md`
    - `02_授權版本模組與費用.md`
    - `03_函式庫總覽與分類.md`
  - `guidelines/`
    - `CODESYS_開發規範_CFC_SFC_ST.md`
- `lib/`
  - `learningMap.ts`：各 library（目前以 SoftMotion 為主）的學習地圖結構與型別。
  - `contentLoader.ts`：讀取 Markdown / ST 檔案的工具。
  - `searchIndex.ts`：搜尋索引建立與查詢邏輯。
  - `syntaxHighlighter.ts`：包裝 Shiki 語法高亮（ST 為主，必要時可擴充其他語言）。
- `scripts/`
  - `sync-content.*`：內容同步腳本，從既有專案中的 Markdown 複製到 `tutorial-site/content/`。
- 其他
  - `SPEC.md`：本文件。
  - 未來將新增 `EXTEND.md`：說明如何擴充與維護（在實作網站後撰寫）。

> 註：實際檔案與路徑名稱可在實作階段依 Next.js 結構微調，但整體分層概念應保持一致。

---

## 4. 內容來源與同步機制

### 4.1 來源目錄

- SoftMotion 總覽與學習地圖：
  - `ExampleFile/CODESYS_SoftMotion_官網教學與範例總覽.md`
- SoftMotion 範例說明（目前已知）：
  - `ExampleFile/BasicMotion_GearInPos/BasicMotion_GearInPos_整體架構與功能.md`
  - `ExampleFile/BasicMotion_CamIn_StartModes/BasicMotion_CamIn_StartModes_整體架構與功能.md`
  - `ExampleFile/Robotics_PickAndPlace/Robotics_PickAndPlace_整體架構與功能.md`
  - 日後可能還會加入其他範例（BasicMotion、Robotics、CNC 等）；檔名規則為 `範例目錄名_整體架構與功能.md`。
- 授權相關：
  - `授權相關/01_RTE環境與支援硬體.md`
  - `授權相關/02_授權版本模組與費用.md`
  - `授權相關/03_函式庫總覽與分類.md`
- 開發規範：
  - `ExampleFile/CODESYS_開發規範_CFC_SFC_ST.md`

### 4.2 同步策略（重要）

- **原始資料**（教學 Markdown）維持在既有目錄（`ExampleFile/`、`授權相關/`），視為「真實來源」。
- `tutorial-site/content/` 內放置的是**完整複製本**，用於網站渲染與部署。
- 實作一個 **同步腳本 `scripts/sync-content`**：
  - 讀取一份「來源 → 目標」的對應表（可以是 JSON 或 TS 常數）。
  - 將原始 Markdown 全檔複製到對應的 `tutorial-site/content/...`。
  - 不改寫內容，只做單純覆寫（確保「格式保持不變」）。
- 使用者未來若更新原始 Markdown，只需要：
  1. 修改 `ExampleFile/` 或 `授權相關/` 內的檔案。
  2. 在專案根目錄執行同步腳本。
  3. 重新部署或啟動 `tutorial-site` 即可。

---

## 5. 網站資訊架構與頁面需求

### 5.1 首頁（`/`）

- 簡短說明本教學網站的目的與範圍（目前以 SoftMotion 為主）。
- 提供明顯的入口：
  - 「從 SoftMotion 入門開始學」按鈕 → `/softmotion`
  - 「了解授權怎麼選」按鈕 → `/licensing`
  - 「開發規範與語言搭配」按鈕 → `/guidelines`
- 可選：顯示學習路徑的簡化示意圖（例如 Basic Motion → Robotics → CNC）。

### 5.2 SoftMotion 學習地圖頁（`/softmotion`）

- 角色定位：像一位 **教練 / 導師**，用人性化語氣幫使用者安排學習順序，重點是「為什麼這樣排」。
- 內容來源：
  - 主體結構依照 `content/softmotion/CODESYS_SoftMotion_官網教學與範例總覽.md` 中的「學習地圖」段落。
  - 不要求畫面與原始 Markdown 完全一致，但概念與順序要對得上。
- UI 需求：
  - 清楚區分三條主線：
    - Basic Motion
    - Robotics
    - CNC
  - 每條主線內，以卡片 / 時間線形式顯示：
    - 範例名稱（例如 `BasicMotion_GearInPos`）。
    - 主要學習重點（MC/SMC FB 名稱、觀念）。
    - 建議前置技能（先學哪幾個範例）。
  - 點擊某個範例卡片 → 導向該範例詳細頁（`/softmotion/[slug]`）。

### 5.3 SoftMotion 範例詳細頁（`/softmotion/[slug]`）

以 `BasicMotion_GearInPos`、`BasicMotion_CamIn_StartModes`、`Robotics_PickAndPlace` 等為例。

- 內容構成：
  - 上方：從 Markdown 複製來的「範例英文名稱_整體架構與功能」文件，以美觀排版呈現。
  - 中間 / 下方：該範例相關 ST 程式碼清單（預設折疊，可展開查看）。
  - 可能的「教練小語」區塊：
    - 用幾句話提醒讀者這個範例最重要的 1～3 個觀念。
- 導覽：
  - 顯示此範例在整體學習路徑中的位置（例如「Basic Motion 線上的第 10 個範例」）。
  - 提供「上一個範例」、「下一個範例」按鈕，依學習地圖順序連結。

### 5.4 授權相關頁（`/licensing`）

- 結構：
  - 上方簡介：用白話說明「為什麼要關心授權」、「不同等級大概差在哪裡」。
  - 下方採用 Tab 或側邊目錄方式切換三個主題：
    - RTE 環境與支援硬體（對應 `01_RTE環境與支援硬體.md`）
    - 授權版本、模組與費用（對應 `02_授權版本模組與費用.md`）
    - 函式庫總覽與分類（對應 `03_函式庫總覽與分類.md`）
- 每個子主題的主體內容直接從對應 Markdown 渲染，格式保持不變，前端只負責樣式美化與 TOC。

### 5.5 開發規範頁（`/guidelines`）

- 單一頁呈現 `CODESYS_開發規範_CFC_SFC_ST.md` 的內容。
- 功能需求：
  - 自動產生右側或上方的 **TOC（Table of Contents）**，可點選捲動到對應段落。
  - 頁面最上方加入「如何使用這份規範」導讀：
    - 給初學者建議先看哪幾節。
    - 說明 SFC/CFC/ST 在專案中的分工建議。

---

## 6. ST 程式碼呈現與互動需求

### 6.1 語法高亮（Shiki）

- **方案**：使用 Shiki 在伺服端預先將 ST 程式轉為高亮 HTML。
- **需求**：
  - 支援 ST 關鍵字（例如 `IF`, `THEN`, `END_IF`, `VAR`, `FUNCTION_BLOCK`, `PROGRAM` 等）。
  - 對常見 CODESYS / SoftMotion 名稱（如 `MC_MoveAbsolute`, `SM_Drive_PosControl`）可以視情況定義顏色類別，或沿用一般函數顏色即可。
  - 色彩風格偏向「現代編輯器風格」（類似 VS Code / Cursor），但需確保可讀性與對比度。

### 6.2 可折疊程式碼區塊

每個範例詳細頁中，ST 程式碼顯示方式需符合下列條件：

- 預設顯示為「程式清單」，每一支 POU 一個折疊區塊，例如：
  - `Robot (PROGRAM)` — 「Tripod 主控制程式」
  - `Environment (PROGRAM)` — 「環境與工件管理」
  - `Cone (FUNCTION_BLOCK)` — 「圓錐狀態機」
- 折疊區塊需求：
  - **預設為收合狀態**，避免頁面過長。
  - 點擊標題列（或右側展開 icon）時，展開該 POU 的完整 ST 程式碼。
  - 可以選擇一次只展開一個區塊，或允許多個同時展開（實作時再定）。

### 6.3 放大與字體調整

- 每個程式碼區塊右上方提供工具列，至少包含：
  - 「放大檢視」按鈕：
    - 打開全螢幕或大對話框顯示該程式碼，適合專心閱讀。
    - 對話框內仍保留語法高亮與捲動。
  - 「字體放大 / 縮小」：
    - 僅影響該程式碼區塊（或全站的程式碼區塊），不影響一般文字。
    - 未來可視需要將使用者偏好存在 localStorage。

---

## 7. 搜尋功能需求

### 7.1 搜尋目標

- 搜尋範圍：
  - `tutorial-site/content/` 底下所有 Markdown 內容。
  - 未來可選擇是否將 ST 程式碼也納入索引（至少要能搜尋函數 / 功能塊名）。
- 主要用途：
  - 查找 **函數 / 功能塊名稱**（例如 `MC_GearInPos`, `SMC_ReadNCFile2`）。
  - 查找重要關鍵字或概念（例如「CNC 前處理」、「Tripod 軸組」、「Safe Control」）。

### 7.2 基本行為

- 頁面頂部或獨立 `/search` 頁提供搜尋框。
- 使用者輸入關鍵字後：
  - 顯示結果列表，每筆結果包含：
    - 標題（例如「GearInPos 齒輪同步 — BasicMotion_GearInPos」）。
    - 所在頁面類型與位置（SoftMotion 範例 / 授權頁 / 規範等）。
    - 一小段內容 snippet，將關鍵字標亮。
  - 點擊結果 → 導向對應頁面，必要時自動捲動到關鍵段落。

### 7.3 技術實作（草案）

- 建立索引：
  - 在 build 時或 server 啟動時讀取所有 Markdown 檔，解析標題與段落，建立輕量索引（可先從簡單的 in-memory 結構開始）。
  - 後續視需求可替換為更完整的全文搜尋方案（例如 mini-lunr 等）。
- 查詢：
  - 提供一個簡單 API（或 server action），根據關鍵字在索引中比對並返回結果。

---

## 8. 可擴充性與未來規劃

### 8.1 支援更多函式庫與範例

- `lib/learningMap.ts` 應支援多個「學習路線」：
  - 例如 `softmotion`, `plcopen`, `cnc`, `robotics` 等 library key。
  - 每個 library 定義：
    - 顯示名稱與描述。
    - 多個 section（階段 / 主題）。
    - 各 section 底下的 example 列表，含 slug、標題、難度、前置範例等。
- `content/` 目錄下可比照 SoftMotion 的方式，為其他 library 建立對應子目錄與 Markdown 說明。

### 8.2 EXTEND 說明文件（之後實作時撰寫）

- 在網站基本實作完成後，新增 `tutorial-site/EXTEND.md`，內容包括：
  - 如何新增新的範例說明 Markdown。
  - 如何在 `learningMap.ts` 中定義新的學習路線與範例。
  - 如何設定同步腳本的來源與目標路徑。
  - 如何調整 Shiki 語法高亮主題與顏色。

---

## 9. 實作優先順序（供之後開工參考）

1. **完成內容同步腳本與 `content/` 複製**。
2. 建立 Next.js 專案骨架與基本 UI（首頁 + SoftMotion 學習地圖頁空殼）。
3. 實作 `/softmotion` 學習地圖與 1～2 個代表性範例詳細頁（含 ST 程式碼展示元件）。
4. 實作 `/licensing` 與 `/guidelines` 頁面，將既有 Markdown 套入。
5. 加入搜尋功能（先支援標題與內文，後續視需要擴充 ST 程式碼搜尋）。
6. 撰寫 `EXTEND.md`，整理擴充與維護步驟。

> 本規格書作為第一版規劃文件，後續若在實作過程中有調整，應在此文件中同步更新，保持「設計意圖」與實際實作一致。

