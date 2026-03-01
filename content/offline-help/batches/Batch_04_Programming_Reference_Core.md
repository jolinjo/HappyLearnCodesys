# Batch 04：程式設計核心參考（語言、變數、運算子）

## 1. 批次目的

- 系統性整理 Offline Help 中關於「程式語言與編輯器」、「變數型別」、「運算子」的核心參考內容。
- 產生可被多處教學引用的「基礎語言手冊」，方便前端網站統一連結。

## 2. 來源主題（對應 Offline Help）

皆位於 TOC 的：

- `Engineering` → `Development System` → `CODESYS Essentials` → `Reference: Programming`

本批要處理的節點（核心）：

- `Programming Languages and Editors`（`_cds_struct_reference_programming_languages_and_editors.html` 及其子頁）
  - `Declaration Editor`（`_cds_edt_declaration_editor.html`）
  - `Common Functions in Graphical Editors`（`_cds_common_functionalities_in_grafic_editors.html`）
  - `Structured Text and Extended Structured Text (ExST)` 系列（含 ST Editor、ST Expressions、Statements 等）
- `Variables`（`_cds_struct_reference_variable_types.html` 及其子頁）
  - 各種 `VAR_*` 與 `PERSISTENT` / `RETAIN` / 指標相關關鍵字。
- `Operators`（`_cds_struct_reference_operators.html` 及其子頁）
  - 各種運算子（Arithmetic / Bitstring / Comparison / Address / Type conversion / Numeric 等）。
  - 其中 `Operators_教學文件.md` 已存在，可視為本批的一部分。

## 3. 輸出教學檔案規劃（zh-TW）

本批次建議產生以下 Markdown 檔案（放到 `Offline-Help/zh-TW/`）：

1. `Languages_and_Editors_教學文件.md`
   - 說明 ST / FBD / Ladder / SFC 等語言與其編輯器特性，重點放在 ST 與常見圖形語言。
2. `Variables_and_Types_教學文件.md`
   - 系統整理各種 `VAR_*`、`PERSISTENT`、`RETAIN` 等的語意與使用情境。
3. `Operators_教學文件.md`（已存在）
   - 如有需要，可在未來批次擴充其內容，覆蓋更多運算子。

## 4. 轉換指引（給轉換腳本／模型）

- 遵守 `HelpConversion_規則說明.md` 中的通用規則。
- `Languages_and_Editors_教學文件.md`：
  - 先高層比較各語言的適用場景（流程控制 vs 數學運算 vs 狀態機等）。
  - 對 ST 需要較詳細說明，包括：
    - 基本程式結構（宣告區／實作區）。
    - 常見敘述（IF、CASE、FOR、WHILE…）只做簡短示例，詳細語法可連結回 ST 章節或其他專檔。
- `Variables_and_Types_教學文件.md`：
  - 著重在「變數生命週期與儲存區」概念：
    - 區分 `VAR`, `VAR_INPUT`, `VAR_OUTPUT`, `VAR_IN_OUT`, `VAR_GLOBAL`, `VAR_TEMP`, `VAR_STAT` 等。
    - 解釋 `PERSISTENT` 與 `RETAIN` 的差異以及何時使用。
  - 以表格形式整理各關鍵字的作用與適用情境。
- `Operators_教學文件.md`：
  - 延續目前結構：
    - 各類運算子的概念說明。
    - 常用運算子（ADD / GT / AND / ADR 等）的 ST 範例與實務說明。
  - 未來若擴充時，仍應依此批次規則，維持一致風格。 

