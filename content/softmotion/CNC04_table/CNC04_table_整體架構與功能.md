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

# CNC04_table — 整體架構與功能說明

---

## 一、這個專案在做什麼？

本範例示範如何使用 **CNC Table 編輯器** 管理 CNC 路徑：使用者可以在表格視圖中輸入每一段路徑的目標座標、進給與 G/M 指令，並在圖形與表格視圖之間切換。執行時，Table 內容仍會被編譯成 CNC 程式，經 <span class="cfg-func">SMC_NCDecoder</span> 線上解碼、<span class="cfg-func">SMC_SmoothPath</span> 平滑與 <span class="cfg-func">SMC_CheckVelocities</span> 檢查，最後由插補器與二軸龍門轉換驅動 `X_Drive` / `Y_Drive`。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務與程式

`TaskConfiguration.md` 未解析出任務資訊；官方 CNC04\_table 範例通常配置為：

- **PathTask**：執行 `Path`（Decoder + SmoothPath + CheckVel）。  
- **IpoTask**：執行 `Ipo`（Interpolator + 軸控制）。  

本範例目錄中程式分工：

- `Path.st`：對由 Table 編輯器建立的 CNC 程式做線上解碼與前處理。  
- `Ipo.st`：插補與二軸驅動。  

### 2.2 軸與裝置

`DeviceTree_Axes.md`：

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| X_Drive | SM_Drive_Virtual | - |
| Y_Drive | SM_Drive_Virtual | - |

與 CNC01～03 相同，為兩軸虛擬 CNC。

### 2.3 函式庫

`Libraries.md`：

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | SoftMotion 基礎運動控制。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 凸輪相關。 |
| <span class="cfg-name">#System_VisuElem3DPath</span> | 3D Path 視覺化。 |
| <span class="cfg-name">#System_VisuElemCamDisplayer</span> | 凸輪視覺化。 |

---

## 三、控制流程：由淺入深

### 3.1 Path：Decoder + SmoothPath + CheckVel（來源為 Table）

`Path.st`：

```pascal
PROGRAM Path
VAR
	dec: SMC_NCDecoder;
	SmoothPath: SMC_SmoothPath;
	CheckVel: SMC_CheckVelocities;
	buf1: ARRAY[0..15] OF SMC_GEOINFO;
	buf2: ARRAY[0..99] OF SMC_GEOINFO;
END_VAR
```

流程與 `CNC03_prepro` 類似，但 CNC 程式是由 Table 編輯器維護的：

1. **Decoder `dec`**  
   - <span class="cfg-func">SMC_NCDecoder</span> 線上解碼 CNC 程式（該程式由 Table 編輯器編輯出來），輸出幾何段到 `buf1` 對應的 OutQueue。  
2. **SmoothPath `SmoothPath`**  
   - <span class="cfg-func">SMC_SmoothPath</span> 對 `dec.poqDataOut` 進行樣條平滑，消除 Table 行與行之間的幾何尖角。  
   - 輸出到 `buf2` 對應的 OutQueue。  
3. **CheckVel `CheckVel`**  
   - <span class="cfg-func">SMC_CheckVelocities</span> 對平滑後路徑做速度檢查，產生供插補器使用的最終 OutQueue。  

從 PLC 程式角度看，與純文字 G-code 並無太大差異；差別主要在於 IDE 中 CNC 程式是透過 Table 視圖編輯，而不是文字檔。

### 3.2 Ipo：插補與二軸控制

`Ipo.st`：

```pascal
PROGRAM Ipo
VAR
	trafo: SMC_TRAFO_Gantry2;
	p1,p2: SMC_ControlAxisByPos;
	trafof: SMC_TRAFOF_Gantry2;
	smci: SMC_Interpolator;
	mcp1, mcp2: MC_Power;
END_VAR
```

與 CNC01～03 相同，典型流程為：

1. `mcp1` / `mcp2` 對 `X_Drive` / `Y_Drive` 上電。  
2. `smci` 從 `Path.CheckVel.poqDataOut` 取得路徑佇列，進行插補。  
3. `trafo` / `trafof` 將插補位置轉成兩軸驅動 SetPosition。  
4. `p1` / `p2` 將 SetPosition 寫入兩軸。  

---

## 四、各支程式負責哪些功能？

### 4.1 `Ipo.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 兩軸上電。  
  - 從前處理後的路徑佇列插補位置。  
  - 透過二軸龍門座標轉換與位置控制驅動 `X_Drive` / `Y_Drive`。  

### 4.2 `Path.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 以 <span class="cfg-func">SMC_NCDecoder</span> 將由 Table 編輯器產生的 CNC 程式線上解碼成幾何段。  
  - 以 <span class="cfg-func">SMC_SmoothPath</span> 平滑路徑。  
  - 以 <span class="cfg-func">SMC_CheckVelocities</span> 檢查速度，最終輸出供插補器使用的 OutQueue。  

---

## 五、函式庫與函式／功能塊一覽

| 名稱 | 類別 | 用途 |
|------|------|------|
| <span class="cfg-func">SMC_NCDecoder</span> | FB | 線上解碼 CNC 程式（來源為 Table 編輯器）。 |
| <span class="cfg-func">SMC_SmoothPath</span> | FB | 將折線路徑平滑成樣條曲線。 |
| <span class="cfg-func">SMC_CheckVelocities</span> | FB | 對平滑後路徑進行速度檢查與限制。 |
| <span class="cfg-func">SMC_Interpolator</span> | FB | 插補路徑點，產生 SetPosition。 |
| <span class="cfg-func">SMC_TRAFO_Gantry2</span> / <span class="cfg-func">SMC_TRAFOF_Gantry2</span> | FB | 二軸龍門座標轉換。 |
| <span class="cfg-func">SMC_ControlAxisByPos</span> | FB | 控制單軸位置。 |
| <span class="cfg-func">MC_Power</span> | FB | 軸上電。 |

---

## 六、變數與常數一覽

本範例未轉出任何 GVL；主要變數皆為 `Path` 與 `Ipo` 的區域變數。

### 6.1 `Path` 主要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">dec</span> | <span class="cfg-type">SMC_NCDecoder</span> | 線上解碼編譯自 CNC Table 的程式。 |
| <span class="cfg-local">SmoothPath</span> | <span class="cfg-type">SMC_SmoothPath</span> | 路徑平滑前處理。 |
| <span class="cfg-local">CheckVel</span> | <span class="cfg-type">SMC_CheckVelocities</span> | 速度檢查。 |
| <span class="cfg-local">buf1</span> | <span class="cfg-type">ARRAY[0..15] OF SMC_GEOINFO</span> | 解碼輸出緩衝。 |
| <span class="cfg-local">buf2</span> | <span class="cfg-type">ARRAY[0..99] OF SMC_GEOINFO</span> | SmoothPath 輸出緩衝。 |

---

## 七、特別的演算法與觀念

### 7.1 Table 編輯與執行流程的分離

- **編輯階段**：  
  - 使用者在 CNC Table 視圖中以表格編輯每一行路徑資訊。  
  - 可隨時切換到圖形視圖檢查實際路徑形狀。  
- **執行階段**：  
  - 無論是 Table 還是文字 G-code，最後都編譯成 CNC 程式，由 Decoder + SmoothPath + CheckVel + Interpolator + Axis 控制這條鏈接手。  

本範例強調的是：**更換前端編輯工具（文字 vs Table）不會改變 PLC 執行階段的結構**。

### 7.2 與 CNC03_prepro 的比較

- CNC03：展示文字 G-code 加上 SmoothPath 前處理。  
- CNC04：展示 Table 來源的路徑也可以使用同樣的前處理鏈，方便在「維護視角」上用表格、但在「執行視角」上享受平滑與速度控制的好處。  

---

## 八、重要參數與設定位置

| 參數 | 檔案 / 位置 | 說明 |
|------|-------------|------|
| Table 欄位與內容 | CODESYS 專案內的 CNC Table 物件 | 路徑的實際資料來源，由 IDE 中編輯。 |
| 軸名稱 `X_Drive` / `Y_Drive` | `DeviceTree_Axes.md` | CNC 兩軸對應的驅動軸。 |

---

## 九、建議閱讀與修改順序

1. 在 CODESYS 原始專案中開啟 CNC Table 物件，熟悉表格欄位與圖形顯示。  
2. 回到本目錄閱讀 `Path.st`，理解 Decoder → SmoothPath → CheckVel 的標準前處理流程。  
3. 最後閱讀 `Ipo.st`，與 CNC01～03 的 `Ipo` 對照，加深對整體 CNC 架構的理解。  

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">CNC Table</span> | CODESYS 內以表格方式編輯的 CNC 程式物件。 |
| <span class="cfg-name">Table View</span> | CNC 編輯器的表格視圖。 |
| <span class="cfg-name">Graphic View</span> | CNC 編輯器的圖形路徑視圖。 |

