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

# CNC01_direct — 整體架構與功能說明

---

## 一、這個專案在做什麼？

本範例是 SoftMotion CNC 的「最基礎範例」：示範如何讓 **兩軸 CNC（X/Y）** 依照 CNC 物件中的路徑運動，透過 **OutQueue + Interpolator + ControlAxisByPos** 這條資料流完成最簡單的 CNC 架構。它不包含 G-code 檔案讀取或前處理，而是直接使用 CODESYS 內建的 CNC Editor 所產生的路徑佇列。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務與程式

`TaskConfiguration.md` 中未解析出任務（此範例的 XML 結構與其他 CNC 範例略有不同），但一般官方專案配置會類似：

- 一個運動任務（典型週期 4 ms）執行 `Ipo` 程式。  
- CNC Editor 中的路徑編譯成 OutQueue，由插補器在同一任務內消費。

在本專案目錄中，我們只看到一支 `Ipo` 程式（`Ipo.st`），負責整個 CNC 流程。

### 2.2 軸與裝置

`DeviceTree_Axes.md`：

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| X_Drive | SM_Drive_Virtual | - |
| Y_Drive | SM_Drive_Virtual | - |

兩支虛擬軸位於 SoftMotion General Axis Pool 下，可視為 CNC X/Y 軸。

### 2.3 函式庫

`Libraries.md` 顯示：

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | SoftMotion 基礎運動控制功能塊。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 凸輪相關（本範例未直接使用）。 |
| <span class="cfg-name">#System_VisuElem3DPath</span> | 3D Path 視覺化。 |
| <span class="cfg-name">#System_VisuElemCamDisplayer</span> | 凸輪視覺化。 |

---

## 三、控制流程：由淺入深

雖然 `Ipo.st` 只有變數宣告，未見完整程式體，但對照官方說明與其他 CNC 範例，可把整體流程理解為：

1. **軸上電（MC_Power）**  
   - 兩個 <span class="cfg-func">MC_Power</span> `mcp1` / `mcp2` 作用於 `X_Drive` / `Y_Drive`。  
2. **路徑插補（SMC_Interpolator）**  
   - <span class="cfg-func">SMC_Interpolator</span> `smci` 從 CNC Editor 編譯出的 OutQueue 取樣，產生機械座標下的 SetPosition（通常為 X/Y 或中間軌跡表示）。  
3. **座標轉換（SMC_TRAFO_Gantry2 / SMC_TRAFOF_Gantry2）**  
   - <span class="cfg-func">SMC_TRAFO_Gantry2</span> `trafo` 將插補器位置轉成兩支驅動軸的位置。  
   - <span class="cfg-func">SMC_TRAFOF_Gantry2</span> `trafof` 則提供浮點版結果，常用於視覺化。  
4. **軸位置控制（SMC_ControlAxisByPos）**  
   - 兩個 <span class="cfg-func">SMC_ControlAxisByPos</span> `p1` / `p2` 將轉換後的位置寫入 `X_Drive` / `Y_Drive`。  

整體架構可概略畫成：

> CNC Editor（OutQueue） → <span class="cfg-func">SMC_Interpolator</span>（`smci`） → <span class="cfg-func">SMC_TRAFO_Gantry2</span>（`trafo`） → <span class="cfg-func">SMC_ControlAxisByPos</span>（`p1` / `p2`） → `X_Drive` / `Y_Drive`

這個架構是後續所有進階 CNC 範例（CNC02～CNC17）的基礎。

---

## 四、各支程式負責哪些功能？

本目錄中只有一支程式：

### 4.1 `Ipo.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 定義 CNC 運動鏈中所需的所有功能塊實例：  
    - `trafo`：<span class="cfg-func">SMC_TRAFO_Gantry2</span>。  
    - `trafof`：<span class="cfg-func">SMC_TRAFOF_Gantry2</span>。  
    - `smci`：<span class="cfg-func">SMC_Interpolator</span>。  
    - `p1` / `p2`：<span class="cfg-func">SMC_ControlAxisByPos</span>。  
    - `mcp1` / `mcp2`：<span class="cfg-func">MC_Power</span>。  
  - 在完整專案中，`Ipo` 程式體會：  
    - 先呼叫 `mcp1` / `mcp2` 讓軸上電。  
    - 呼叫 `smci` 從 OutQueue 取得 SetPosition。  
    - 呼叫 `trafo` / `trafof` 轉換座標。  
    - 呼叫 `p1` / `p2` 驅動 `X_Drive` / `Y_Drive`。  
- **輸出／介面**：無明確 VAR\_INPUT/OUTPUT，主要透過功能塊與軸物件互動。

---

## 五、函式庫與函式／功能塊一覽

| 名稱 | 類別 | 用途 |
|------|------|------|
| <span class="cfg-func">MC_Power</span> | FB | 軸上電與驅動啟動。 |
| <span class="cfg-func">SMC_Interpolator</span> | FB | 從 CNC OutQueue 插補 SetPosition。 |
| <span class="cfg-func">SMC_TRAFO_Gantry2</span> | FB | 將機械座標轉換為兩軸龍門驅動位置。 |
| <span class="cfg-func">SMC_TRAFOF_Gantry2</span> | FB | 同上，浮點版，常用於視覺化。 |
| <span class="cfg-func">SMC_ControlAxisByPos</span> | FB | 根據 SetPosition 控制單軸位置。 |

---

## 六、變數與常數一覽

本範例未轉出任何 GVL 檔；`Ipo` 中也僅有功能塊實例與軸相關變數，未見全域常數。可視為最簡化的 CNC 範例。

### 6.1 `Ipo` 主要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">trafo</span> | <span class="cfg-type">SMC_TRAFO_Gantry2</span> | 座標轉換，將插補位置拆成 X/Y 軸位置。 |
| <span class="cfg-local">trafof</span> | <span class="cfg-type">SMC_TRAFOF_Gantry2</span> | 浮點版座標轉換，用於視覺化。 |
| <span class="cfg-local">smci</span> | <span class="cfg-type">SMC_Interpolator</span> | 插補器，從 CNC OutQueue 取樣。 |
| <span class="cfg-local">p1</span>, <span class="cfg-local">p2</span> | <span class="cfg-type">SMC_ControlAxisByPos</span> | 兩軸位置控制。 |
| <span class="cfg-local">mcp1</span>, <span class="cfg-local">mcp2</span> | <span class="cfg-type">MC_Power</span> | 兩軸上電。 |

---

## 七、特別的演算法與觀念

### 7.1 CNC 最小骨架：OutQueue + Interpolator + ControlAxis

與後面大量 CNC 範例相比，CNC01\_direct 不做：  
- G-code 檔案讀取（ReadNCFile2）。  
- 線上解碼（NCDecoder）。  
- 路徑前處理（SmoothPath 等）。  

而是直接使用 CNC 編輯器產生的 OutQueue，讓初學者聚焦在「插補器 → 軸控制」這一段。這也是開發自訂 CNC 流程時必須先理解的最小架構。

---

## 八、重要參數與設定位置

由於 XML 未解析出任務，這裡只列出與裝置樹及函式庫相關的資訊：

| 參數 | 檔案 / 位置 | 說明 |
|------|-------------|------|
| 軸名稱 `X_Drive` / `Y_Drive` | `DeviceTree_Axes.md` | CNC 的兩支虛擬軸，必須在實機專案中綁定到實際驅動器。 |
| 函式庫清單 | `Libraries.md` | 確認已載入 SoftMotion 基礎與 3D Path 視覺化等庫。 |

---

## 九、建議閱讀與修改順序

1. 先讀 `DeviceTree_Axes.md`，確認兩支軸的命名與類型。  
2. 再看 `Ipo.st`，理解插補器、轉換與軸控制功能塊的分工。  
3. 之後開啟 CODESYS 原始專案中的 CNC Editor，看 OutQueue 與 `Ipo` 程式是如何配合的。  
4. 若要延伸，可在 `Ipo` 中實作完整程式體（上電、插補、座標轉換、軸控制），或在此基礎上加入 G-code 檔案讀取與前處理功能。

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">OutQueue</span> | CNC Editor 編譯出的幾何段佇列，供插補器使用。 |
| <span class="cfg-name">Interpolator</span> | <span class="cfg-func">SMC_Interpolator</span>，從 OutQueue 產生 SetPosition。 |
| <span class="cfg-name">Gantry2</span> | 二軸龍門座標轉換（機械座標 → 兩支驅動軸）。 |

