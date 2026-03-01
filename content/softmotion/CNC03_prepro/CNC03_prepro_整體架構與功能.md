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

# CNC03_prepro — 整體架構與功能說明

---

## 一、這個專案在做什麼？

本範例在 CNC02\_online 的「線上解碼」基礎上，加上 **路徑前處理（Preprocessing）**：使用 <span class="cfg-func">SMC_SmoothPath</span> 對解碼後的 G-code 路徑做平滑化，使轉角不再急停、軌跡更光順，然後再交給 <span class="cfg-func">SMC_CheckVelocities</span> 與插補器執行。路徑仍由 <span class="cfg-func">SMC_NCDecoder</span> 線上解碼並支援變數 `g_x` / `g_y`。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務與程式

`TaskConfiguration.md` 沒有成功解析任務資訊，不過結構與 CNC02 類似，一般設計會是：

- **PathTask**：執行 `Path` 程式（Decoder + SmoothPath + CheckVel）。  
- **IpoTask**：執行 `Ipo` 程式（Interpolator + 軸控制）。

程式分工：

- `Path.st`：負責 G-code 線上解碼與平滑前處理。  
- `Ipo.st`：負責插補與兩軸位置控制。  
- `GVL_Globale_Variablen.st`：提供 `g_x` / `g_y` 等全域變數，讓 G-code 可參數化。

### 2.2 軸與裝置

`DeviceTree_Axes.md`：

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| X_Drive | SM_Drive_Virtual | - |
| Y_Drive | SM_Drive_Virtual | - |

與 CNC01/02 相同，兩軸虛擬 CNC 系統。

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

### 3.1 Path：線上解碼 + SmoothPath + CheckVel

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

概念流程：

1. **線上解碼 `dec`**  
   - <span class="cfg-func">SMC_NCDecoder</span> 讀取編譯為 <span class="cfg-name">SMC_CNC_REF</span> 的 CNC 程式，將 G-code 解譯為幾何段並輸出到 `buf1` 對應的 OutQueue。  
   - 解碼時會讀取全域變數（例如 `g_x`, `g_y`）作為程式中的 G-code 變數。  
2. **路徑平滑 `SmoothPath`**  
   - <span class="cfg-func">SMC_SmoothPath</span> `SmoothPath` 接上 `dec.poqDataOut`，使用樣條演算法（預設為 Spline 模式）平滑路徑，讓轉角變成圓滑過渡，而不是停下再起動。  
   - 輸出使用 `buf2` 對應的 OutQueue。  
3. **速度檢查 `CheckVel`**  
   - <span class="cfg-func">SMC_CheckVelocities</span> `CheckVel` 對 `SmoothPath.poqDataOut` 做速度檢查與限制，產生供插補器使用的最終 OutQueue。  

實際專案中還會加上角度公差、最小曲率半徑等設定；這些多半來自 GVL 或 CNC 物件設定，本匯出檔未顯示細節。

### 3.2 Ipo：插補與兩軸控制

`Ipo.st` 與 CNC01/02 類似：

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

概念上：

1. `mcp1` / `mcp2` 使能 `X_Drive` / `Y_Drive`。  
2. `smci` 從 `Path.CheckVel.poqDataOut` 取得經平滑與速度檢查後的路徑。  
3. `trafo` / `trafof` 做二軸龍門座標轉換。  
4. `p1` / `p2` 根據 SetPosition 控制軸位置。

---

## 四、各支程式負責哪些功能？

### 4.1 `Ipo.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 上電兩軸。  
  - 從前處理後路徑輸出插補位置。  
  - 經二軸龍門轉換後驅動 `X_Drive` / `Y_Drive`。  

### 4.2 `Path.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 使用 <span class="cfg-func">SMC_NCDecoder</span> 線上解碼 CNC 程式，支援變數。  
  - 使用 <span class="cfg-func">SMC_SmoothPath</span> 對路徑做樣條平滑，減少尖角。  
  - 使用 <span class="cfg-func">SMC_CheckVelocities</span> 做速度檢查，產生最終 OutQueue。  

### 4.3 `GVL_Globale_Variablen.st`

```pascal
VAR_GLOBAL
	g_x: REAL:=100;
	g_y:REAL:=50;
END_VAR
```

- **類型**：全域變數表。  
- **職責**：提供 G-code 內的變數（如 G\_X、G\_Y）對應的 PLC 變數來源，和 CNC02 相同，用於控制目標點或偏移。

---

## 五、函式庫與函式／功能塊一覽

| 名稱 | 類別 | 用途 |
|------|------|------|
| <span class="cfg-func">SMC_NCDecoder</span> | FB | 線上解碼 CNC 程式。 |
| <span class="cfg-func">SMC_SmoothPath</span> | FB | 對解碼後路徑做樣條平滑處理。 |
| <span class="cfg-func">SMC_CheckVelocities</span> | FB | 對平滑後路徑做速度檢查。 |
| <span class="cfg-func">SMC_Interpolator</span> | FB | 插補器。 |
| <span class="cfg-func">SMC_TRAFO_Gantry2</span> / <span class="cfg-func">SMC_TRAFOF_Gantry2</span> | FB | 二軸龍門座標轉換。 |
| <span class="cfg-func">SMC_ControlAxisByPos</span> | FB | 軸位置控制。 |
| <span class="cfg-func">MC_Power</span> | FB | 軸上電。 |

---

## 六、變數與常數一覽

本範例未使用 RETAIN／PERSISTENT。

### 6.1 全域變數（`GVL_Globale_Variablen.st`）

與 CNC02 相同：

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| <span class="cfg-global">g_x</span> | <span class="cfg-type">REAL</span> | 100 | G-code 中對應的 X 位置變數。 |
| <span class="cfg-global">g_y</span> | <span class="cfg-type">REAL</span> | 50 | G-code 中對應的 Y 位置變數。 |

### 6.2 `Path` 主要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">dec</span> | <span class="cfg-type">SMC_NCDecoder</span> | 線上解碼。 |
| <span class="cfg-local">SmoothPath</span> | <span class="cfg-type">SMC_SmoothPath</span> | 路徑平滑前處理。 |
| <span class="cfg-local">CheckVel</span> | <span class="cfg-type">SMC_CheckVelocities</span> | 速度檢查。 |
| <span class="cfg-local">buf1</span> | <span class="cfg-type">ARRAY[0..15] OF SMC_GEOINFO</span> | Decoder 輸出緩衝。 |
| <span class="cfg-local">buf2</span> | <span class="cfg-type">ARRAY[0..99] OF SMC_GEOINFO</span> | SmoothPath 輸出緩衝。 |

---

## 七、特別的演算法與觀念

### 7.1 路徑前處理的順序

本範例展示了典型的 CNC 前處理順序：

1. **Decoder**：把 G-code 轉成幾何段。  
2. **SmoothPath**：對幾何段做樣條平滑，消除尖角與急停。  
3. **CheckVelocities**：在平滑後的軌跡上做速度限制與檢查。  

這個順序確保速度檢查是針對「最終實際執行的路徑」來做，而不是原始有尖角的路徑。

### 7.2 與 CNC02 的差異

- CNC02：只有 Decoder + CheckVel，轉角仍是原始 G-code 定義的幾何。  
- CNC03：在中間加上 SmoothPath，因此插補器看到的是更光順的路徑，能在不違反速度限制的前提下保持較高平均速度與較好加工品質。

---

## 八、重要參數與設定位置

| 參數 | 檔案 / 位置 | 說明 |
|------|-------------|------|
| <span class="cfg-global">g_x</span> / <span class="cfg-global">g_y</span> | `GVL_Globale_Variablen.st` | 控制 G-code 中使用的位移變數。 |
| 軸名稱 `X_Drive` / `Y_Drive` | `DeviceTree_Axes.md` | 兩軸 CNC 對應的驅動軸。 |
| SmoothPath / CheckVel 相關公差 | 通常在 GVL 或 CNC 物件屬性 | 決定平滑程度與速度限制，匯出檔未列出，可在 CODESYS 專案中檢視。 |

---

## 九、建議閱讀與修改順序

1. 先讀 `GVL_Globale_Variablen.st`，了解路徑中哪些點由 PLC 變數控制。  
2. 再看 `Path.st`，理解 Decoder → SmoothPath → CheckVel 的前處理鏈。  
3. 接著看 `Ipo.st`，與 CNC01/02 比對插補與軸控制部分，建立完整心智模型。  
4. 想體驗前處理效果，可在 CODESYS 中切換 SmoothPath 開/關，對照軸速度與軌跡變化。  

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">Path Preprocessing</span> | 在插補前對路徑做平滑、補償的處理。 |
| <span class="cfg-func">SMC_SmoothPath</span> | 用於將折線路徑變為樣條平滑曲線的前處理 FB。 |
| <span class="cfg-global">g_x</span> / <span class="cfg-global">g_y</span> | 本範例中由 PLC 變數驅動的 G-code 參數。 |

