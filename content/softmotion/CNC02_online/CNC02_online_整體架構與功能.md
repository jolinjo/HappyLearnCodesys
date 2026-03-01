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

# CNC02_online — 整體架構與功能說明

---

## 一、這個專案在做什麼？

本範例在 CNC01\_direct 的基礎上，示範如何讓 **G-code 在執行期間依變數動態改變**。CNC 程式編譯成 <span class="cfg-name">SMC_CNC_REF</span> 模式，執行時由 <span class="cfg-func">SMC_NCDecoder</span> 線上解碼，並使用全域變數 <span class="cfg-global">g_x</span>、<span class="cfg-global">g_y</span> 控制路徑中的目標位置；PathTask 負責解碼與速度檢查，Ipo 任務則用插補器與軸控制執行路徑。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務與程式

`TaskConfiguration.md` 沒有成功解析任務（XML 結構略異），不過依官方 CNC02\_online 範例，典型配置為：

- **PathTask**：週期 10～20 ms，執行 `Path` 程式，進行 Decoder + CheckVel。  
- **IpoTask**：週期 4 ms，執行 `Ipo` 程式，進行插補與軸控制。

在本目錄中：

- `Path.st`：解碼、速度檢查，輸出路徑佇列。  
- `Ipo.st`：插補、座標轉換與兩軸控制。  
- `GVL_Globale_Variablen.st`：定義全域變數 `g_x`、`g_y`，給 G-code 使用。

### 2.2 軸與裝置

`DeviceTree_Axes.md`：

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| X_Drive | SM_Drive_Virtual | - |
| Y_Drive | SM_Drive_Virtual | - |

與 CNC01 相同，為兩軸虛擬 CNC。

### 2.3 函式庫

`Libraries.md`：

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | SoftMotion 基礎運動控制。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 凸輪相關（本範例未直接使用）。 |
| <span class="cfg-name">#System_VisuElem3DPath</span> | 3D Path 視覺化。 |
| <span class="cfg-name">#System_VisuElemCamDisplayer</span> | 凸輪視覺化。 |

---

## 三、控制流程：由淺入深

### 3.1 Path：線上解碼與速度檢查

`Path.st`：

```pascal
PROGRAM Path
VAR
	dec: SMC_NCDecoder;
	checkVel: SMC_CheckVelocities;
	buf: ARRAY[0..99] OF SMC_GEOINFO;
END_VAR
```

雖然程式體在匯出檔中未顯示，但對照官方 CNC02\_online，可理解為：

1. `dec` 以 <span class="cfg-name">SMC_CNC_REF</span> 模式對 CNC 程式進行線上解碼，將包含變數（例如 G\_X、G\_Y）與運算的 G-code 轉成幾何段。  
2. 解碼結果存入 `buf` 所指向的 OutQueue。  
3. `checkVel` 以 <span class="cfg-func">SMC_CheckVelocities</span> 對 `dec.poqDataOut` 做速度檢查，輸出供插補器使用的路徑佇列。  

關鍵是：**G-code 中的變數會在解碼時讀取 PLC 內的 <span class="cfg-global">g_x</span>、<span class="cfg-global">g_y</span>，因此可以在程式執行前（甚至執行中）透過 HMI 或 PLC 邏輯改變路徑目標點**。

### 3.2 Ipo：插補與兩軸控制

`Ipo.st` 與 CNC01 基本相同：

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

概念與 CNC01 一致：

1. 透過兩個 <span class="cfg-func">MC_Power</span> `mcp1` / `mcp2` 對 `X_Drive` / `Y_Drive` 上電。  
2. <span class="cfg-func">SMC_Interpolator</span> `smci` 從 `Path.checkVel.poqDataOut` 取得路徑佇列，產生 SetPosition。  
3. <span class="cfg-func">SMC_TRAFO_Gantry2</span> / <span class="cfg-func">SMC_TRAFOF_Gantry2</span> 將 SetPosition 轉為兩軸驅動位置。  
4. 兩個 <span class="cfg-func">SMC_ControlAxisByPos</span> `p1` / `p2` 將結果寫入 `X_Drive` / `Y_Drive`。

---

## 四、各支程式負責哪些功能？

### 4.1 `Ipo.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 對 `X_Drive` / `Y_Drive` 上電。  
  - 從 PathTask 輸出的路徑佇列插補 SetPosition。  
  - 經二軸龍門座標轉換後，驅動兩軸位置控制。  

### 4.2 `Path.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 使用 <span class="cfg-func">SMC_NCDecoder</span> 以 <span class="cfg-name">SMC_CNC_REF</span> 模式線上解碼 CNC 程式，支援變數。  
  - 使用 <span class="cfg-func">SMC_CheckVelocities</span> 做速度檢查。  
  - 輸出插補器可直接使用的 OutQueue。  

### 4.3 `GVL_Globale_Variablen.st`

```pascal
VAR_GLOBAL
	g_x: REAL:=100;
	g_y:REAL:=50;
END_VAR
```

- **類型**：全域變數表。  
- **職責**：提供 CNC 程式中的 G-code 變數對應（例如 G\_X、G\_Y），用於設定路徑中的 X / Y 目標位置或偏移量。調整這兩個值就能不改 G-code 內容而改變實際路徑。

---

## 五、函式庫與函式／功能塊一覽

| 名稱 | 類別 | 用途 |
|------|------|------|
| <span class="cfg-func">SMC_NCDecoder</span> | FB | 線上解碼 CNC 程式（SMC\_CNC\_REF 編譯）。 |
| <span class="cfg-func">SMC_CheckVelocities</span> | FB | 對解碼後路徑做速度檢查。 |
| <span class="cfg-func">SMC_Interpolator</span> | FB | 從路徑佇列插補出 SetPosition。 |
| <span class="cfg-func">SMC_TRAFO_Gantry2</span> / <span class="cfg-func">SMC_TRAFOF_Gantry2</span> | FB | 二軸龍門座標轉換。 |
| <span class="cfg-func">SMC_ControlAxisByPos</span> | FB | 根據 SetPosition 控制單軸位置。 |
| <span class="cfg-func">MC_Power</span> | FB | 軸上電與驅動啟動。 |

---

## 六、變數與常數一覽

本範例未使用 RETAIN／PERSISTENT。

### 6.1 全域變數（`GVL_Globale_Variablen.st`）

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| <span class="cfg-global">g_x</span> | <span class="cfg-type">REAL</span> | 100 | G-code 中對應的 X 目標位置或偏移量。 |
| <span class="cfg-global">g_y</span> | <span class="cfg-type">REAL</span> | 50 | G-code 中對應的 Y 目標位置或偏移量。 |

### 6.2 `Path` 主要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">dec</span> | <span class="cfg-type">SMC_NCDecoder</span> | 線上解碼 CNC 程式。 |
| <span class="cfg-local">checkVel</span> | <span class="cfg-type">SMC_CheckVelocities</span> | 對解碼出的路徑做速度檢查。 |
| <span class="cfg-local">buf</span> | <span class="cfg-type">ARRAY[0..99] OF SMC_GEOINFO</span> | 路徑 OutQueue 緩衝。 |

---

## 七、特別的演算法與觀念

### 7.1 SMC_CNC_REF 與線上解碼

與 CNC01 的 OutQueue 編譯模式不同，CNC02 使用 <span class="cfg-name">SMC_CNC_REF</span>：

- CNC 程式不直接編譯成固定的 GEOINFO 陣列，而是保留為可解碼的參考。  
- 執行時由 <span class="cfg-func">SMC_NCDecoder</span> 讀取這個參考並根據當下的 PLC 變數值（如 <span class="cfg-global">g_x</span>、<span class="cfg-global">g_y</span>）產生實際路徑。  

因此，只要修改 PLC 變數，就能在下一次解碼時改變路徑，而無需重編譯 CNC 程式。

### 7.2 變數驅動路徑

實務上，可以將 `g_x` / `g_y` 接到 HMI 或外部通訊：

- 使用者可輸入不同的工件尺寸或偏移量。  
- CNC 程式利用這些變數計算目標座標；Decoder 在解碼時讀取變數，路徑自然隨之更新。  

這是實現「同一套 G-code，對應許多產品規格」的關鍵。

---

## 八、重要參數與設定位置

| 參數 | 檔案 / 位置 | 說明 |
|------|-------------|------|
| <span class="cfg-global">g_x</span> / <span class="cfg-global">g_y</span> | `GVL_Globale_Variablen.st` | 控制 G-code 中的目標位置或偏移量，常由 HMI 或 PLC 寫入。 |
| 軸名稱 `X_Drive` / `Y_Drive` | `DeviceTree_Axes.md` | CNC 兩軸對應的實體或虛擬軸。 |

---

## 九、建議閱讀與修改順序

1. 先看 `GVL_Globale_Variablen.st`，理解 `g_x` / `g_y` 的角色。  
2. 再看 `Path.st`，理解 Decoder + CheckVel 的基本做法。  
3. 接著閱讀 `Ipo.st`，對照 CNC01 的說明，加深對 OutQueue → Interpolator → Axis 控制流程的理解。  
4. 若要實作自己的參數化 CNC，從定義 GVL 變數與在 CNC 程式中使用變數開始，然後以 Decoder 進行線上解碼。  

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">SMC_CNC_REF</span> | 一種 CNC 編譯模式，執行時透過 Decoder 線上解碼。 |
| <span class="cfg-name">Online decoding</span> | 指在運轉中依照 PLC 變數解碼 G-code，而非預先產生固定路徑。 |
| <span class="cfg-global">g_x</span> / <span class="cfg-global">g_y</span> | 本範例用來控制路徑終點或偏移的 PLC 全域變數。 |

