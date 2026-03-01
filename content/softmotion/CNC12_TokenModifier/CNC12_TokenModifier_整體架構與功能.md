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

# CNC12_TokenModifier — 整體架構與功能說明

---

## 一、這個專案在做什麼？

本範例示範 **如何在 G-code 讀取階段，使用 Token Modifier（<span class="cfg-type">SMC_ITokenModifier</span>）動態修改 G-code Token 內容**。  
具體例子是：將 G-code 中以 **mm/min** 表示的進給速度（F-word），在讀取時自動換算為 **mm/s**，讓 CNC 控制邏輯仍然用 mm/s 的統一單位運算。  

關鍵角色是功能塊 <span class="cfg-type">TokenModifySpeed</span>，它實作了 <span class="cfg-type">SMC_ITokenModifier</span>，並成批配置到 <span class="cfg-func">SMC_ReadNCFile2</span> 的 `aTokenModifier` 陣列中，對 G-code Token 進行前置處理。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務與程式

根據專案結構與其他 CNC 範例，可整理程式與任務關係如下：

- **MotionTask（約 4 ms）**：執行 `CNC`，完成三軸上電與插補（呼叫 `Interpolation()`）。  
- **PathTask（約 20 ms）**：執行 `CNC_PreparePath`，讀取 `Application/CNC_PathSpeed.cnc`，呼叫 Token Modifier 修改 Token，並完成解譯與速度檢查。  
- **VISU_TASK（約 100 ms）**：執行 `VisuElems.Visu_Prg`，使用 <span class="cfg-func">SMC_GCodeViewer</span> 來顯示 G-code 與 3D Path。  

### 2.2 軸與裝置

- 三軸 `AxisX`、`AxisY`、`AxisZ`，型態皆為 <span class="cfg-type">SM_Drive_Virtual</span>，掛載於 **SoftMotion General Axis Pool**。  
- 適合作為三軸 CNC 模擬，實機可改綁定實際驅動器。  

### 2.3 函式庫概觀

`Libraries.md` 中列出：

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | 基礎運動控制與軸功能塊。 |
| <span class="cfg-name">#SM3_Basic_Visu</span> | 基礎運動視覺化。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 凸輪與高階運動功能。 |
| <span class="cfg-name">#SM3_CNC</span> | CNC / G-code 解析、插補與 Viewer。 |
| <span class="cfg-name">#System_VisuElem3DPath</span> | 3D 路徑視覺化。 |
| <span class="cfg-name">#System_VisuElemCamDisplayer</span> | 凸輪視覺化。 |

---

## 三、控制流程：從 G-code 到三軸運動

### 3.1 整體資料流

1. 操作者在 HMI 啟動 PathTask：`xStart := TRUE` 送入 `CNC_PreparePath`。  
2. `CNC_PreparePath` 進入狀態 10：  
   - 將多個 <span class="cfg-type">TokenModifySpeed</span> 實例填入 `rncf.aTokenModifier` 陣列。  
   - 呼叫 <span class="cfg-func">SMC_ReadNCFile2</span> 讀取 `Application/CNC_PathSpeed.cnc`。  
   - 在讀取過程中，每遇到 Token（包含 F-word）都會依序經過所有 Token Modifier 處理。  
   - 將處理後的 Token 傳給 <span class="cfg-func">SMC_NCInterpreter</span> 解譯為幾何段與 OutQueue。  
   - 將 OutQueue 傳給 <span class="cfg-func">SMC_CheckVelocities</span> 進行速度檢查。  
   - 完成後設定 `xStartIpo := TRUE`，通知插補端「路徑已準備好」。  
3. `CNC` 在 MotionTask 中：  
   - 使用三個 <span class="cfg-func">MC_Power</span> 對 X/Y/Z 軸上電。  
   - 當所有軸 `Status = TRUE`，切入 `iState = 100`，呼叫 `Interpolation()`：  
     - 內部利用 <span class="cfg-func">SMC_Interpolator</span> 從已檢查的 OutQueue 產生 SetPosition。  
     - 經 <span class="cfg-type">SMC_TRAFO_Gantry3</span> / <span class="cfg-type">SMC_TRAFOF_Gantry3D</span> 座標轉換後，由 <span class="cfg-func">SMC_ControlAxisByPos</span> 寫入 X/Y/Z 軸。  
4. 同時，`SMC_GCodeViewer` 使用 `nci.GCodeText` 等資訊在視覺化介面顯示對應的 G-code 與路徑。  

### 3.2 `CNC_PreparePath` 關鍵程式碼剖析

部分程式碼（節錄）：

```pascal
PROGRAM CNC_PreparePath
VAR_INPUT
	xStart : BOOL;
	sFileName : STRING := 'Application/CNC_PathSpeed.cnc';
END_VAR
VAR_OUTPUT
	xStartIpo : BOOL;
	poqPath : POINTER TO SMC_Outqueue;
END_VAR
VAR
	iState: INT;
    aModifySpeed : ARRAY[0..NUM_MODIFIERS-1] OF TokenModifySpeed ;
	rncf : SMC_ReadNCFile2 := (aSubProgramDirs := ['Application/']);
	nci : SMC_NCInterpreter;
	cv : SMC_CheckVelocities;
	aBufInterpreter : ARRAY[0..99] OF SMC_GeoInfo ;
	gcv : SMC_GCodeViewer;
	bufGCV : ARRAY[0..99] OF SMC_GCODEVIEWER_DATA;
END_VAR
VAR_TEMP
    i : UDINT;
END_VAR
VAR CONSTANT
	NUM_MODIFIERS : UDINT := SMC_CNC_LibParams.MAX_SUBPROGRAM_NESTING_DEPTH+1;
END_VAR
```

狀態 0 會在啟動時設定 Token Modifier：

```pascal
IF xStart THEN
    iState := 10;
    xStartIpo := FALSE;

    i := 0 ;
    WHILE i < NUM_MODIFIERS DO
        rncf.aTokenModifier[i] := aModifySpeed[i] ;
        i := i + 1 ;
    END_WHILE

    rncf(bExecute:= FALSE);
    nci(bExecute:= FALSE, sentences:= rncf.sentences);
    cv(bExecute:= FALSE);
    xStart := FALSE;
END_IF
```

之後在狀態 10 執行實際讀取與解譯：

```pascal
rncf(
    bExecute:= TRUE,
    sFileName:= sFileName);

nci(
    bExecute:= TRUE ,
    sentences:= rncf.sentences,
    nSizeOutQueue:= SIZEOF(aBufInterpreter),
    pbyBufferOutQueue:= ADR(aBufInterpreter),
    bEnableSyntaxChecks:= TRUE);

cv(
    bExecute:= TRUE,
    poqDataIn:= nci.poqDataOut);

xStartIpo := TRUE;
IF NOT cv.bBusy THEN
    iState := 0;
END_IF
```

---

## 四、各程式負責哪些功能？

### 4.1 `CNC.st`

- **類型**：PROGRAM（MotionTask）。  
- **職責**：  
  - 呼叫三個 <span class="cfg-func">MC_Power</span>（`pX`、`pY`、`pZ`）對 `AxisX` / `AxisY` / `AxisZ` 上電。  
  - 使用 `iState` 狀態機：  
    - `0`：等待三軸 `Status = TRUE`。  
    - `100`：呼叫 `Interpolation()`，執行插補與三軸控制。  

### 4.2 `CNC_PreparePath.st`

- **類型**：PROGRAM（PathTask）。  
- **職責**：  
  - 將多個 <span class="cfg-type">TokenModifySpeed</span> 實例綁定到 `rncf.aTokenModifier`。  
  - 呼叫 <span class="cfg-func">SMC_ReadNCFile2</span> 讀取 `Application/CNC_PathSpeed.cnc`，並在 Token 階段進行修改。  
  - 呼叫 <span class="cfg-func">SMC_NCInterpreter</span> 把（已修改速度單位的）Token 轉成幾何段。  
  - 呼叫 <span class="cfg-func">SMC_CheckVelocities</span> 做速度檢查，輸出給插補器。  
  - 用 <span class="cfg-func">SMC_GCodeViewer</span> 將 G-code 與路徑資訊提供給視覺化。  

### 4.3 `TokenModifySpeed.st`

```pascal
// Modifier function block to convert the path velocity (F-Word)
// from mm/min to mm/s.
FUNCTION_BLOCK TokenModifySpeed IMPLEMENTS SMC_ITokenModifier
VAR
    m_state : UDINT := STATE_INIT;

	m_tmpQueue : SMC_TokenQueue;
	m_aBufferTempQueue: ARRAY[0..3] OF SMC_Token;
	m_errorPos : SMC_NC_SourcePosition;
END_VAR
VAR CONSTANT
	STATE_INIT : UDINT := 0;
	STATE_RUNNING : UDINT := 10;
	STATE_DONE : UDINT := 100;
	STATE_ERROR : UDINT := 1000;
END_VAR
```

- **類型**：FUNCTION_BLOCK，實作 <span class="cfg-type">SMC_ITokenModifier</span>。  
- **職責**：  
  - 以狀態機 `STATE_INIT` → `STATE_RUNNING` → `STATE_DONE` 來驅動 Token 處理流程。  
  - 透過暫存佇列 <span class="cfg-type">SMC_TokenQueue</span> 與緩衝陣列 `m_aBufferTempQueue` 讀寫 Token。  
  - 當遇到速度 Token（F-word）時，將其數值從 mm/min 轉成 mm/s，寫回給後續解譯器使用。  
  - 在錯誤時可紀錄於 `m_errorPos : SMC_NC_SourcePosition`。  

---

## 五、使用到的函式庫與關鍵型別

| 名稱 | 類別 | 用途 |
|------|------|------|
| <span class="cfg-func">SMC_ReadNCFile2</span> | FB | 讀取 G-code 檔案，支援 Token Modifier、子程式目錄等。 |
| <span class="cfg-func">SMC_NCInterpreter</span> | FB | 將 Token 轉成幾何段與 OutQueue。 |
| <span class="cfg-func">SMC_CheckVelocities</span> | FB | 檢查並限制路徑速度。 |
| <span class="cfg-func">SMC_GCodeViewer</span> | FB | 提供 G-code / 路徑給視覺化。 |
| <span class="cfg-type">SMC_ITokenModifier</span> | 介面 | Token Modifier 介面，供 `TokenModifySpeed` 實作。 |
| <span class="cfg-type">SMC_TokenQueue</span> / <span class="cfg-type">SMC_Token</span> | 型態 | G-code Token 佇列與單一 Token。 |
| <span class="cfg-func">MC_Power</span> | FB | 軸上電。 |

---

## 六、變數與常數一覽（重點）

### 6.1 `CNC_PreparePath` 重要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">sFileName</span> | <span class="cfg-type">STRING</span> | G-code 檔案名稱（預設 `Application/CNC_PathSpeed.cnc`）。 |
| <span class="cfg-local">aModifySpeed</span> | <span class="cfg-type">ARRAY[0..NUM_MODIFIERS-1] OF TokenModifySpeed</span> | 多個 Token Modifier 實例，對應不同巢狀層級。 |
| <span class="cfg-local">rncf</span> | <span class="cfg-type">SMC_ReadNCFile2</span> | 讀取 G-code 並呼叫 Token Modifier。 |
| <span class="cfg-local">nci</span> | <span class="cfg-type">SMC_NCInterpreter</span> | 將 Token 轉成 CNC 幾何路徑。 |
| <span class="cfg-local">cv</span> | <span class="cfg-type">SMC_CheckVelocities</span> | 路徑速度檢查。 |
| <span class="cfg-local">aBufInterpreter</span> | <span class="cfg-type">ARRAY[0..99] OF SMC_GeoInfo</span> | 解譯輸出佇列緩衝區。 |
| <span class="cfg-local">NUM_MODIFIERS</span> | <span class="cfg-type">UDINT</span> (常數) | `SMC_CNC_LibParams.MAX_SUBPROGRAM_NESTING_DEPTH + 1`，對應最大子程式巢狀深度。 |

### 6.2 `TokenModifySpeed` 重要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">m_state</span> | <span class="cfg-type">UDINT</span> | Token Modifier 狀態機。 |
| <span class="cfg-local">m_tmpQueue</span> | <span class="cfg-type">SMC_TokenQueue</span> | 內部暫存 Token 的佇列。 |
| <span class="cfg-local">m_aBufferTempQueue</span> | <span class="cfg-type">ARRAY[0..3] OF SMC_Token</span> | Token 緩衝。 |
| <span class="cfg-local">m_errorPos</span> | <span class="cfg-type">SMC_NC_SourcePosition</span> | 錯誤位置記錄，用於診斷。 |

---

## 七、特別的演算法與觀念

### 7.1 Token Modifier 的設計模式

這個範例展示了 **「在語法解譯前修改 Token」** 的設計方式，適用於：

- 統一或轉換量測單位（如本例 mm/min → mm/s）。  
- 濾除或改寫特定 G-code 指令。  
- 基於專案需求，將外部 NC 程式轉換成 SoftMotion 可接受的格式。  

相較於在解譯後修改 OutQueue，Token Modifier 更接近「語言層」，適合作為 G-code 匯入的前處理層。

### 7.2 NUM_MODIFIERS 與子程式巢狀

`NUM_MODIFIERS` 設定為 `SMC_CNC_LibParams.MAX_SUBPROGRAM_NESTING_DEPTH + 1`，目的在於：

- 每個子程式巢狀層級都對應到一個 Token Modifier。  
- 確保在呼叫子程式（`CALL` / `M98` 等）時，各層級的 Token 都能被一致處理。  

---

## 八、重要參數與設定位置

| 參數 | 檔案 / 位置 | 說明 |
|------|-------------|------|
| `sFileName` | `CNC_PreparePath.st` | 指定要讀取的 G-code 檔案。 |
| `NUM_MODIFIERS` | `CNC_PreparePath.st` | Token Modifier 實例數量，與子程式巢狀深度相關。 |
| 子程式目錄 `aSubProgramDirs` | `CNC_PreparePath.st` 中 `rncf` 初始值 | 指定子程式搜尋路徑（此例為 `Application/`）。 |

---

## 九、建議閱讀與實驗順序

1. 先讀 `CNC.st`，確認三軸上電與 `Interpolation()` 的大致結構（可對照其它 CNC 範例）。  
2. 再讀 `CNC_PreparePath.st`，理解 `aModifySpeed` 與 `rncf.aTokenModifier` 的配置方式，以及狀態 0 / 10 的呼叫流程。  
3. 接著深入 `TokenModifySpeed.st`，對照 Help 說明中的 <span class="cfg-type">SMC_ITokenModifier</span> 介面，理解如何讀寫 Token。  
4. 在 CODESYS 中修改 G-code 中的進給值，或改成其他單位，觀察實際軸速是否依照 Token Modifier 的邏輯被正確轉換。  

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-type">SMC_ITokenModifier</span> | 可掛在 G-code Reader 前端，用來修改 Token 的介面。 |
| <span class="cfg-type">TokenModifySpeed</span> | 本範例用來將 F-word 速度由 mm/min 轉成 mm/s 的 Token Modifier。 |
| <span class="cfg-type">SMC_TokenQueue</span> / <span class="cfg-type">SMC_Token</span> | 用來暫存與處理 G-code Token 的結構。 |
| <span class="cfg-name">CNC_PathSpeed.cnc</span> | 範例使用的 G-code 檔案名稱，內含進給速度設定。 |

