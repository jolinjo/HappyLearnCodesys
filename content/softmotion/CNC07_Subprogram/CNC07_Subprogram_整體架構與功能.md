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

# CNC07_Subprogram — 整體架構與功能說明

---

## 一、這個專案在做什麼？

本範例示範 CNC 程式中的 **Subprogram（子程式）機制**：如何將重複使用的加工段寫成獨立 `.cnc` 檔，並從主程式呼叫；以及 SoftMotion 如何在讀檔與解譯時自動搜尋子程式目錄、處理呼叫堆疊（Callstack），並搭配全域變數 `g_x` / `g_y` 作為 G-code 變數。路徑仍由 <span class="cfg-func">SMC_ReadNCFile2</span> + <span class="cfg-func">SMC_NCInterpreter</span> + <span class="cfg-func">SMC_CheckVelocities</span> 準備，再由插補器與三軸控制執行。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務與程式

`TaskConfiguration.md`：

| 任務名稱 | 類型 | 週期 | 優先權 | POU 清單 |
|----------|------|------|--------|----------|
| MotionTask | Cyclic | t#gc_dwCycle | 1 | `CNC` |
| PathTask | Cyclic | t#20ms | 5 | `CNC_PreparePath` |
| VISU_TASK | Cyclic | t#100ms | 31 | `VisuElems.Visu_Prg` |

- **MotionTask（CNC）**：以 4 ms 週期執行三軸插補與軸控制。  
- **PathTask（CNC_PreparePath）**：以 20 ms 週期讀取主程式與子程式 G-code，並產生路徑佇列。  
- **VISU_TASK**：僅負責視覺化。

### 2.2 軸與裝置

`DeviceTree_Axes.md`：

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| AxisX | SM_Drive_Virtual | - |
| AxisY | SM_Drive_Virtual | - |
| AxisZ | SM_Drive_Virtual | - |

三軸皆為虛擬軸，對應三軸 CNC 的 X/Y/Z。

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

### 3.1 PathTask：讀取主程式與子程式、設變數與顯示 Callstack

`CNC_PreparePath.st`：

```pascal
PROGRAM CNC_PreparePath
VAR_INPUT
	xStart: BOOL;
	sFileName: STRING := 'Application/CNC2Main.cnc';
END_VAR
VAR_OUTPUT
	xStartIpo: BOOL;
	poqPath: Pointer to SMC_Outqueue;
END_VAR
VAR
	iState: INT;
	rncf2 : SMC_ReadNCFile2 := (aSubProgramDirs := ['Application/']);
	nci : SMC_NCInterpreter;
	cv : SMC_CheckVelocities;
	aBufInterpreter : ARRAY[0..99] OF SMC_GeoInfo ;
    dnccs : SMC_DisplayNCCallstack;

	sentenc: SMC_GSentenceQueue;
	asv : ARRAY[0..1] OF SMC_SingleVar := [
  	(strVarName := 'G_X', eVarType := SMC_TYPE_REAL, pAdr := ADR(g_x)),
  	(strVarName := 'G_Y', eVarType := SMC_TYPE_REAL, pAdr := ADR(g_y))];
	vl : SMC_VarList := (wNumberVars := 2, psvVarList := ADR(asv[0]));
END_VAR
```

1. `poqPath := cv.poqDataOut`：輸出為速度檢查後的路徑佇列。  
2. `rncf2` 的初始化：  
   - `aSubProgramDirs := ['Application/']`：指定子程式搜尋目錄為 `Application/`，主程式可在 G-code 中呼叫位於該目錄的其他 `.cnc` 檔。  
3. 變數列表 `vl`：  
   - 使用兩個 <span class="cfg-type">SMC_SingleVar</span>：  
     - `G_X` 對應 <span class="cfg-global">g_x</span>。  
     - `G_Y` 對應 <span class="cfg-global">g_y</span>。  
   - 透過 <span class="cfg-type">SMC_VarList</span> `vl` 傳給 ReadNCFile2，使 G-code 中的變數可以讀寫 PLC 全域變數。  
4. Callstack 顯示：  
   - <span class="cfg-func">SMC_DisplayNCCallstack</span> `dnccs`：  
     - `csi := nci.CallstackInfo`：接收解譯器的呼叫堆疊資訊（主程式 / 子程式）。  
     - `ipo := CNC.ipo`：接上插補器，用於顯示當前正在執行哪個程式段。  
     - `Enable := TRUE`：啟用顯示。  
5. 狀態機 `iState`：  
   - `0`（idle）：等待 `xStart`，並清除 `rncf2`, `nci`, `cv` 狀態。  
   - `10`（start reading and processing）：  
     - `rncf2(bExecute := TRUE, sFileName := sFileName, pvl := ADR(vl))`：從檔案讀取主程式 `CNC2Main.cnc`，並在解譯過程中支援 G-code 變數與子程式目錄。  
     - `nci(bExecute := TRUE, sentences := rncf2.sentences, ...)`：解譯主程式與子程式，輸出幾何段。  
     - `cv(bExecute := TRUE, poqDataIn := nci.poqDataOut)`：速度檢查。  
     - `xStartIpo := TRUE`，完成後回到 `iState := 0`。  

### 3.2 MotionTask：三軸插補與驅動

`CNC.st` 與 CNC05 類似：

```pascal
PROGRAM CNC
VAR
	iState: INT;
	pX, pY, pZ: MC_Power;

	ipo: SMC_Interpolator;
	trafo: SMC_TRAFO_Gantry3;
	trafof: SMC_TRAFOF_Gantry3D;
	cabpX, 	cabpY, 	cabpZ: SMC_ControlAxisByPos;
END_VAR
```

1. 三軸上電：三個 <span class="cfg-func">MC_Power</span> 對 `AxisX` / `AxisY` / `AxisZ` 上電。  
2. 狀態機 `iState`：  
   - `0`：等待三軸 `Status` 為 TRUE。  
   - `100`：呼叫 `Interpolation()` 執行插補與軸控制。  
3. 在 `Interpolation()` 中，典型執行：  
   - <span class="cfg-func">SMC_Interpolator</span> `ipo` 從 `CNC_PreparePath.poqPath` 消費路徑佇列。  
   - `trafo` / `trafof` 進行三軸龍門座標轉換。  
   - `cabpX/Y/Z` 根據 SetPosition 驅動三軸。

---

## 四、各支程式負責哪些功能？

### 4.1 `CNC.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 三軸上電與插補執行。  
  - 實際驅動 `AxisX/Y/Z` 根據從子程式與主程式解譯而來的路徑。  

### 4.2 `CNC_PreparePath.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 使用 <span class="cfg-func">SMC_ReadNCFile2</span> `rncf2` 讀取主程式檔案 `Application/CNC2Main.cnc`，並搜尋 `Application/` 目錄下的子程式檔案。  
  - 透過變數列表 `vl`，讓 G-code 變數 `G_X` / `G_Y` 綁定到 PLC 全域變數 <span class="cfg-global">g_x</span> / <span class="cfg-global">g_y</span>。  
  - 使用 <span class="cfg-func">SMC_NCInterpreter</span> `nci` 解譯主程式 + 子程式，產生完整路徑。  
  - 使用 <span class="cfg-func">SMC_CheckVelocities</span> `cv` 檢查速度，輸出 `poqPath`。  
  - 使用 <span class="cfg-func">SMC_DisplayNCCallstack</span> `dnccs` 顯示當前呼叫堆疊，方便在視覺化畫面中看到目前執行的是哪個 Subprogram。  

### 4.3 `GVL.st`

```pascal
VAR_GLOBAL
	g_x: REAL:=400;
	g_y: REAL:=200;
END_VAR

VAR_GLOBAL CONSTANT
	gc_dwCycle : DWORD := 4000;
END_VAR
```

- **職責**：  
  - `g_x` / `g_y`：G-code 變數 `G_X` / `G_Y` 的 PLC 端對應，可用於調整路徑位置。  
  - `gc_dwCycle`：MotionTask 週期常數。

---

## 五、函式庫與函式／功能塊一覽

| 名稱 | 類別 | 用途 |
|------|------|------|
| <span class="cfg-func">SMC_ReadNCFile2</span> | FB | 從檔案系統讀取主程式與子程式 G-code，支援 Subprogram 目錄。 |
| <span class="cfg-func">SMC_NCInterpreter</span> | FB | 解譯主程式與子程式，產生完整路徑。 |
| <span class="cfg-func">SMC_CheckVelocities</span> | FB | 速度檢查。 |
| <span class="cfg-func">SMC_DisplayNCCallstack</span> | FB | 將解譯器呼叫堆疊與插補器狀態轉成視覺化用資料。 |
| <span class="cfg-func">SMC_Interpolator</span> | FB | 插補路徑。 |
| <span class="cfg-func">SMC_TRAFO_Gantry3</span> / <span class="cfg-func">SMC_TRAFOF_Gantry3D</span> | FB | 三軸龍門座標轉換。 |
| <span class="cfg-func">SMC_ControlAxisByPos</span> | FB | 軸位置控制。 |
| <span class="cfg-func">MC_Power</span> | FB | 軸上電與驅動啟動。 |

---

## 六、變數與常數一覽

本範例未使用 RETAIN／PERSISTENT。

### 6.1 全域變數（`GVL.st`）

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| <span class="cfg-global">g_x</span> | <span class="cfg-type">REAL</span> | 400 | G-code 變數 `G_X` 對應的 PLC 全域變數。 |
| <span class="cfg-global">g_y</span> | <span class="cfg-type">REAL</span> | 200 | G-code 變數 `G_Y` 對應的 PLC 全域變數。 |
| <span class="cfg-const">gc_dwCycle</span> | <span class="cfg-type">DWORD</span> | 4000 | MotionTask 週期。 |

### 6.2 `CNC_PreparePath` 主要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">xStart</span> / <span class="cfg-local">xStartIpo</span> | <span class="cfg-type">BOOL</span> | 啟動讀檔與路徑準備 / 路徑就緒通知插補器。 |
| <span class="cfg-local">rncf2</span> | <span class="cfg-type">SMC_ReadNCFile2</span> | 讀取主程式與子程式 G-code。 |
| <span class="cfg-local">nci</span> | <span class="cfg-type">SMC_NCInterpreter</span> | 解譯 G-code 句子。 |
| <span class="cfg-local">cv</span> | <span class="cfg-type">SMC_CheckVelocities</span> | 速度檢查 FB。 |
| <span class="cfg-local">asv</span> / <span class="cfg-local">vl</span> | <span class="cfg-type">SMC_SingleVar</span> 陣列 / <span class="cfg-type">SMC_VarList</span> | 將 G\_X / G\_Y 綁定到 `g_x` / `g_y`。 |
| <span class="cfg-local">dnccs</span> | <span class="cfg-type">SMC_DisplayNCCallstack</span> | 顯示當前主程式 / 子程式呼叫堆疊。 |

---

## 七、特別的演算法與觀念

### 7.1 Subprogram 搜尋與呼叫堆疊

透過 `aSubProgramDirs := ['Application/']` 與 G-code 語法，ReadNCFile2 能夠：

- 遇到子程式呼叫時，到指定目錄尋找對應 `.cnc` 檔。  
- 支援巢狀子程式呼叫。  
- 將當前呼叫堆疊（主程式 → 子程式 → 巢狀子程式）提供給解譯器與 `SMC_DisplayNCCallstack` 使用。  

`SMC_DisplayNCCallstack` 則把這些資訊與 `CNC.ipo` 狀態結合，方便在 HMI 上顯示「目前執行到哪一個 Subprogram、第幾行」等資訊。

### 7.2 G-code 變數與 PLC 變數的互動

與 CNC02/03 類似，本範例使用 VarList 將 G-code 變數連到 PLC 變數：

- G-code 中使用 `G_X` / `G_Y` 作為座標或偏移。  
- 解譯時 ReadNCFile2 / NCInterpreter 會讀寫 PLC 中的 <span class="cfg-global">g_x</span> / <span class="cfg-global">g_y</span>。  
- 在 PLC 端改變 `g_x` / `g_y` 即可影響子程式中的運動行為，而不需要改 G-code 檔案本身。  

這讓 Subprogram 可以寫得更通用，只靠參數或變數控制不同工件尺寸或位置。

---

## 八、重要參數與設定位置

| 參數 | 檔案 / 位置 | 說明 |
|------|-------------|------|
| <span class="cfg-const">gc_dwCycle</span> | `GVL.st` | MotionTask 插補週期。 |
| `sFileName` | `CNC_PreparePath.st`（VAR\_INPUT） | 主程式 G-code 檔案（預設 `Application/CNC2Main.cnc`）。 |
| `aSubProgramDirs` | `CNC_PreparePath.st` 中 `rncf2` 初始值 | 子程式搜尋目錄清單（此處為 `Application/`）。 |
| `G_X` / `G_Y` ↔ `g_x` / `g_y` | `CNC_PreparePath.st` 中 `asv` / `vl` | G-code 變數與 PLC 變數綁定。 |

---

## 九、建議閱讀與修改順序

1. 先看 `GVL.st`，了解 `g_x` / `g_y` 以及 `gc_dwCycle`。  
2. 再看 `TaskConfiguration.md` 與 `DeviceTree_Axes.md`，掌握任務與三軸結構。  
3. 閱讀 `CNC_PreparePath.st`，特別注意 ReadNCFile2 的 `aSubProgramDirs`、VarList `vl` 與 Callstack 顯示 `dnccs` 的使用。  
4. 最後看 `CNC.st` 與其他 CNC 範例如 CNC05 比較，確認插補與軸控制結構一致。  
5. 若要擴充，可在 Application 目錄新增自己的 Subprogram `.cnc` 檔，並修改主程式 G-code 以呼叫這些子程式。  

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">Subprogram</span> | G-code 子程式，獨立 `.cnc` 檔，被主程式呼叫。 |
| <span class="cfg-func">SMC_ReadNCFile2</span> | 支援 Subprogram 目錄與 VarList 的 G-code 讀取 FB。 |
| <span class="cfg-func">SMC_DisplayNCCallstack</span> | 用於視覺化目前主程式 / 子程式呼叫堆疊的 FB。 |
| <span class="cfg-global">g_x</span> / <span class="cfg-global">g_y</span> | 本範例中對應 G-code 變數 G\_X / G\_Y 的 PLC 全域變數。 |

