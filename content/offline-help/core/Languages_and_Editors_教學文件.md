<style>
html, body, #preview, .markdown-preview, .markdown-body, .markdown-preview-section,
[id^="preview"], [class*="markdown-preview"] {
  background-color: #FDF5E6 !important;
  font-size: 14px;
}

/* 程式／術語：只用同一套等寬字體；用顏色區分型別 */
.cfg-func,
.cfg-global,
.cfg-local,
.cfg-custom,
.cfg-const,
.cfg-keyword,
.cfg-type,
.cfg-arg,
.cfg-name,
code {
  font-family: ui-monospace, "Cascadia Code", "Source Code Pro", Consolas, Monaco, "Courier New", monospace;
}

/* 移除反引號 inline code 的灰底樣式（只靠顏色規則） */
.markdown-preview-section :not(pre) > code,
.markdown-preview :not(pre) > code,
.markdown-body :not(pre) > code {
  background: transparent !important;
  padding: 0 !important;
  border: none !important;
  border-radius: 0 !important;
  box-shadow: none !important;
}

.cfg-func   { color: #6f42c1 !important; background: none !important; }
.cfg-global { color: #953800 !important; background: none !important; }
.cfg-local  { color: #0a6c0a !important; background: none !important; }
.cfg-custom { color: #8250df !important; background: none !important; }
.cfg-const  { color: #0d9488 !important; background: none !important; }
.cfg-keyword{ color: #0550ae !important; background: none !important; }
.cfg-type   { color: #cf222e !important; background: none !important; }
.cfg-arg    { color: #c2410c !important; background: none !important; }
.cfg-name   { color: #b45309 !important; background: none !important; }
</style>

**顏色對應**：<span class="cfg-func">內建函數</span> <span class="cfg-global">全域變數</span> <span class="cfg-local">區域變數</span> <span class="cfg-custom">自訂函數</span> <span class="cfg-const">常數</span> <span class="cfg-keyword">保留字</span> <span class="cfg-type">型態</span> <span class="cfg-arg">引數</span> <span class="cfg-name">專有名詞</span>

# Languages and Editors 程式語言與編輯器 教學整理

> 本文件基於 CODESYS Offline Help 中下列主題整理而成：
> - `Programming Languages and Editors`（`_cds_struct_reference_programming_languages_and_editors.html`）
> - `Declaration Editor`（`_cds_edt_declaration_editor.html`）
> - `Common Functions in Graphical Editors`（`_cds_common_functionalities_in_grafic_editors.html`）
> - `Structured Text and Extended Structured Text (ExST)`、`ST Editor`、`Statements`
> 目標是從「語言與編輯器」角度說明各實作語言的適用場景、ST 基本結構與常見敘述，以及宣告／圖形編輯器的共通概念；詳細語法請參閱 ST 章節或變數／運算子教學文件。

---

## 1. 程式語言與編輯器總覽

在 CODESYS 中，每個 POU 依**建立時選擇的實作語言**使用對應編輯器撰寫程式：

- **ST（Structured Text）**：文字編輯器，適合算式、流程控制、複雜邏輯；本文件以 ST 為重點。
- **ExST（Extended Structured Text）**：ST 的擴充版，同一套 ST 編輯器可編輯。
- **SFC（Sequential Function Chart）**：圖形編輯器，適合步驟與狀態流程。
- **FBD（Function Block Diagram）／LD（Ladder Diagram）／IL（Instruction List）**：圖形／梯狀／指令列表編輯器，常與 CFC 歸類為「圖形編輯器」。

編輯器開啟方式：在 Device Tree 或 **POUs** 視圖中**雙擊**該 POU。

不論哪一種實作語言，編輯器都由**兩個子視窗**組成：

1. **上方**：**Declaration Editor 宣告編輯器**，以文字或表格形式定義變數與宣告。
2. **下方**：以該語言撰寫的**實作區**（ST 程式碼、SFC 圖、FBD/LD 圖等）。

各編輯器的外觀與行為可在 **CODESYS Options** 對應分頁中設定。

---

## 2. Declaration Editor 宣告編輯器

### 2.1 角色與顯示模式

- 在宣告編輯器中撰寫 **variable lists** 與 **POUs** 的變數宣告。
- 與實作語言編輯器搭配時，宣告編輯器出現在**上方**視窗。
- 支援兩種檢視：
  - **文字檢視**：以 ST 語法撰寫宣告（例如 `VAR x : INT; END_VAR`）。
  - **表格檢視**：以欄位方式編輯名稱、型別、初值等。
- 在 **Options → Declaration Editor** 可設定僅顯示其中一種，或允許在編輯器右側按鈕切換。

### 2.2 線上模式（Online mode）

- 連線至 PLC 時，宣告編輯器以**表格檢視**顯示，標題列會顯示目前物件路徑：`<device>.<application>.<object>`。
- 表格會多出 **Value**（PLC 上目前值，具監看功能）與 **Prepared Value**（準備用來 Force／Write 的值）。
- 陣列若超過 1,000 個元素，可在 **Data Type** 欄雙擊開啟 **Monitoring Area** 設定要監看的索引範圍（單一陣列最多監看 20,000 個元素）。
- 浮點數顯示格式可在 **Project Settings → Monitoring** 中設定。

---

## 3. Structured Text（ST）與 ST 編輯器

### 3.1 ST／ExST 與編輯器

- **ST** 為 IEC 61131-3 標準的文字化程式語言；**ExST** 為 CODESYS 擴充版，語法與編輯方式與 ST 一致。
- **ST Editor** 為文字編輯器：左側有行號、支援 **F2** 開啟 Input Assistant、游標停在變數上可顯示宣告資訊；若啟用 **SmartCoding**，可列出元件。
- 長行時可 **Shift + 滑鼠滾輪** 水平捲動、**Ctrl + 滑鼠滾輪** 縮放；**Ctrl+Shift+i** 可開啟遞增搜尋。
- 括號、滑鼠行為、Tab 等可在 **Options → Text editor** 設定；語法錯誤會在輸入時即標示（Message 視窗 Precompile、或紅色波浪底線）。

### 3.2 ST 程式結構（宣告區／實作區）

- **宣告區**：在 Declaration Editor 中撰寫（VAR … END_VAR、VAR_INPUT 等），定義變數、常數、暫存變數等。
- **實作區**：在 ST 編輯器中撰寫，由**敘述（Statements）**與**運算式（Expressions）**組成；敘述之間以分號 `;` 結束。

### 3.3 常見敘述簡短示例

以下僅列出語法要點與短範例；完整語義與參數請參閱 Offline Help 之 ST Statements 章節。

**IF … ELSIF … ELSE … END_IF**

```iecst
IF condition1 THEN
    (* 區塊 A *)
ELSIF condition2 THEN
    (* 區塊 B *)
ELSE
    (* 區塊 C *)
END_IF;
```

**CASE … OF … ELSE … END_CASE**

```iecst
CASE selector OF
    1: (* 選項 1 *)
    2, 3: (* 選項 2 或 3 *)
ELSE
    (* 預設 *)
END_CASE;
```

**FOR … TO … BY … DO … END_FOR**

```iecst
FOR i := 1 TO 10 BY 2 DO
    (* 迴圈本體，i = 1, 3, 5, 7, 9 *)
END_FOR;
```

**WHILE … DO … END_WHILE**

```iecst
WHILE condition DO
    (* 迴圈本體 *)
END_WHILE;
```

**REPEAT … UNTIL … END_REPEAT**

```iecst
REPEAT
    (* 迴圈本體，至少執行一次 *)
UNTIL condition
END_REPEAT;
```

**RETURN**：結束目前 POU 執行並回傳（若為 FUNCTION）。  
**EXIT**：跳出目前迴圈。  
**CONTINUE**（ExST）：跳過本次迭代，進入下一輪迴圈。

詳細敘述與運算式（Assignments、Expressions）請參閱 Offline Help 之 ST 章節或本系列之 Variables、Operators 教學文件。

---

## 4. 圖形編輯器（SFC、FBD、LD、IL、CFC）與共通功能

- **SFC**：以步驟（Step）與轉換（Transition）描述順序流程，適合狀態機與製程步驟。
- **FBD／LD／IL**：以方塊、接點、梯階或指令列表描述邏輯，適合接點邏輯與訊號組合。
- **CFC**：連續功能圖，以方塊與連線組成，適合迴路與資料流。

圖形編輯器與 ST 共用**同一個 Declaration Editor**（上方）；下方則為各語言專屬的圖形編輯區。圖形編輯器之間有**共通功能**（例如複製貼上、縮放、對齊、工具箱等），詳見 Offline Help「Common Functions in Graphical Editors」。

---

## 5. 語言與場景對照

| 語言 | 編輯器類型 | 常見適用場景 |
|------|------------|--------------|
| **ST / ExST** | 文字 | 算式、流程控制、複雜條件、演算法、可讀性與版本控制友善 |
| **SFC** | 圖形 | 順序流程、狀態機、步驟式製程 |
| **FBD / LD** | 圖形 | 接點邏輯、聯鎖、訊號組合、習慣梯狀圖的維護 |
| **IL** | 圖形/列表 | 指令列表、低階或緊湊程式 |
| **CFC** | 圖形 | 控制迴路、資料流、方塊圖式設計 |

同一專案內可依 POU 需求選擇不同語言；宣告區語法一致，僅實作區表現方式不同。若需深入單一語言的語法與進階敘述，請參閱 CODESYS Offline Help 對應章節或本系列 Variables、Operators 教學文件。
