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

# CNC11_CustomFunctions — 整體架構與功能說明

---

## 一、這個專案在做什麼？

本範例示範 **如何在 SoftMotion CNC 中，將自訂 PLC 函數／功能塊，掛接到 G-code 解析流程裡，作為「自訂 G 功能（Custom G Function）」**。  
核心觀念是透過 <span class="cfg-type">SMC_NC_GFunctionTable</span> 與 <span class="cfg-type">SMC_SingleVar</span> / <span class="cfg-type">SMC_VARLIST</span>，把：

- G-code 裡的自訂指令（例如 `GSEL ...` / `SEL ...` 類型）對應到 PLC 端的 <span class="cfg-type">CNC_Sel</span> 功能塊。  
- G-code 中的變數名稱（例如 `LONGLINE`）綁定到 PLC 全域變數 <span class="cfg-global">GVL.g_longline</span>。  

整體流程仍是 **G-code → SMC_ReadNCFile2 → SMC_NCInterpreter → SMC_CheckVelocities → SMC_Interpolator → 軸控制**，只是中間插入自訂功能與變數。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務與程式

依 XML 匯出資訊與程式命名，可整理為：

- **MotionTask（約 4 ms）**：執行 `CNC`，負責三軸上電與插補（呼叫 `Interpolation()`）。  
- **PathTask（約 20 ms）**：執行 `CNC_PreparePath`，負責讀取 G-code、呼叫解譯與速度檢查。  
- **VISU_TASK（約 100 ms）**：執行 `VisuElems.Visu_Prg`，顯示 3D 路徑與 G-code 視覺化。  

### 2.2 軸與裝置

`DeviceTree_Axes.md` 類型（由其他 CNC 範例推測結構相同）：

- 三軸虛擬軸：`AxisX`、`AxisY`、`AxisZ`，類型為 <span class="cfg-type">SM_Drive_Virtual</span>，掛在 **SoftMotion General Axis Pool**。  
- 用於模擬三軸 CNC 工作機（例如 X/Y 平面 + Z 軸進給）。  

### 2.3 函式庫概觀

`Libraries.md`：

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | 基礎運動控制與軸功能塊。 |
| <span class="cfg-name">#SM3_Basic_Visu</span> | 基礎運動的視覺化輔助元件。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 凸輪等高級運動功能。 |
| <span class="cfg-name">#SM3_CNC</span> | CNC / G-code 相關功能、解譯器與 G-code Viewer。 |
| <span class="cfg-name">#System_VisuElem3DPath</span> | 3D Path 視覺化。 |
| <span class="cfg-name">#System_VisuElemCamDisplayer</span> | 凸輪視覺化。 |

---

## 三、控制流程：由 G-code 到三軸運動

### 3.1 大致資料流

1. 操作者透過 Visu 或參數指定 G-code 檔案 `Application/CNC.cnc`。  
2. `CNC_PreparePath` 在 PathTask 內運行：  
   - 呼叫 <span class="cfg-func">SMC_ReadNCFile2</span> 讀取 G-code，並傳入 **自訂函數表** 與 **變數列表**。  
   - 將 `rncf2.sentences` 交給 <span class="cfg-func">SMC_NCInterpreter</span> 產生幾何段與 OutQueue。  
   - 交給 <span class="cfg-func">SMC_CheckVelocities</span> 做速度檢查與平滑處理，輸出 `cv.poqDataOut`。  
   - 啟動插補旗標 `xStartIpo := TRUE`，表示路徑準備完成。  
3. `CNC` 在 MotionTask 內運行：  
   - 使用 <span class="cfg-func">MC_Power</span> 對 `AxisX`、`AxisY`、`AxisZ` 上電。  
   - 當三軸都 Ready 時，進入狀態 `100` 呼叫 `Interpolation()`，內部會使用 <span class="cfg-func">SMC_Interpolator</span> / <span class="cfg-type">SMC_TRAFO_Gantry3</span> / <span class="cfg-type">SMC_ControlAxisByPos</span> 完成插補與軸控制。  
4. 視覺化部分由 <span class="cfg-func">SMC_GCodeViewer</span> (`gcv`) 把 G-code 文本與插補結果顯示在 3D Path 介面上。  

### 3.2 `CNC_PreparePath` 狀態機細節

程式關鍵變數（擷取部分）：

```pascal
PROGRAM CNC_PreparePath
VAR_INPUT
	xStart : BOOL;
	sFileName : STRING := 'Application/CNC.cnc';
END_VAR
VAR_OUTPUT
	xStartIpo : BOOL;
	poqPath : POINTER TO SMC_Outqueue;
END_VAR
VAR
	iState : INT;
	rncf2 : SMC_ReadNCFile2 := (bParenthesesAsComments:= FALSE);
	nci : SMC_NCInterpreter;
	cv : SMC_CheckVelocities;
	aBufInterpreter : ARRAY[0..99] OF SMC_GeoInfo;
	gcv : SMC_GCodeViewer;

	bufGCV : ARRAY[0..99] OF SMC_GCODEVIEWER_DATA;
```

與自訂函數／變數相關部分：

```pascal
    aCNCFunctions : ARRAY[0..0] OF SMC_NC_GFunction :=
        [(stName:= 'SEL', iFunc:= GVL.g_Sel)];

    funTable : SMC_NC_GFunctionTable :=
        (numFunctions:= 1,
         pFunction:= ADR(aCNCFunctions)) ;

    vars : ARRAY[0..0] OF SMC_SingleVar :=
		[
			(strVarName:= 'LONGLINE',
			 eVarType:= SMC_VARTYPE.SMC_TYPE_BOOL,
			 pAdr:= ADR(GVL.g_longline))
		];

	varList : SMC_VARLIST := (wNumberVars:= 1, psvVarList:= ADR(vars));
```

狀態流程：

- **狀態 0（Idle）**  
  - 等待 `xStart = TRUE`。  
  - 清除 `xStartIpo`，將 `rncf2` / `nci` / `cv` 的 `bExecute` 先設為 `FALSE`。  
  - 將 `xStart := FALSE`，避免重複觸發，進入狀態 `10`。  

- **狀態 10（開始讀檔與解譯）**  
  - 呼叫 `rncf2`：  
    - `bExecute := TRUE`  
    - `sFileName := sFileName`（預設 `Application/CNC.cnc`）  
    - `pCustomFunTable := ADR(funTable)`（把自訂函數表傳給 Reader）  
    - `pvl := ADR(varList)`（把變數列表傳給 Reader）  
  - 呼叫 `nci`：  
    - `sentences := rncf2.sentences`  
    - 指定 outqueue 緩衝區 `aBufInterpreter`。  
  - 呼叫 `cv`：  
    - `poqDataIn := nci.poqDataOut`，完成速度檢查。  
  - 將 `xStartIpo := TRUE` 告知插補器可以啟動。  
  - 當 `cv.bBusy = FALSE`，表示前處理完成，狀態回到 `0`。  

---

## 四、各支程式／全域變數負責哪些功能？

### 4.1 `CNC.st`

- **類型**：PROGRAM（MotionTask）。  
- **主要職責**：  
  - 呼叫三個 <span class="cfg-func">MC_Power</span>（`pX`、`pY`、`pZ`）對三軸上電：  
    - `Axis := AxisX / AxisY / AxisZ`。  
  - 以 `iState` 狀態機控管流程：  
    - `iState = 0`：等待三軸 `Status = TRUE`。  
    - `iState = 100`：呼叫 `Interpolation()`，實際執行插補與座標轉換。  

### 4.2 `CNC_PreparePath.st`

- **類型**：PROGRAM（PathTask）。  
- **主要職責**：  
  - 讀取 G-code 檔案 `Application/CNC.cnc`。  
  - 組裝自訂函數表（`aCNCFunctions` / `funTable`），將 G-code 中的 `SEL` 對應到 PLC 物件 `GVL.g_Sel`。  
  - 組裝變數列表（`vars` / `varList`），將 G-code 變數 `LONGLINE` 綁定到 <span class="cfg-global">GVL.g_longline</span>。  
  - 呼叫 <span class="cfg-func">SMC_ReadNCFile2</span> + <span class="cfg-func">SMC_NCInterpreter</span> + <span class="cfg-func">SMC_CheckVelocities</span> 產生可供插補器使用的 OutQueue。  
  - 對視覺化元件 <span class="cfg-func">SMC_GCodeViewer</span> 提供資料（`GCodeText := nci.GCodeText` 等）。  

### 4.3 `CNC_Sel.st`

```pascal
FUNCTION_BLOCK CNC_Sel IMPLEMENTS SMC_NC_IFunction
VAR
    argTypes : ARRAY[0..2] OF SMC_GVar_Type :=
		[SMC_GVar_Type.T_BOOL,
		 SMC_GVar_Type.T_OTHER,
		 SMC_GVar_Type.T_OTHER];
END_VAR
```

- **類型**：FUNCTION_BLOCK，實作 <span class="cfg-type">SMC_NC_IFunction</span> 介面。  
- **主要職責**：  
  - 定義自訂 G Function `SEL` 的參數型態。  
  - 當 G-code 解譯到 `SEL ...`（或對應語法）時，解譯器會呼叫此 FB 實例，依 G-code 傳入參數做動作（本範例僅示意參數型態設定，實際邏輯可擴充）。  

### 4.4 `GVL.st`

```pascal
{attribute 'qualified_only'}
VAR_GLOBAL
    g_Sel : CNC_Sel;
	g_longline : BOOL;
END_VAR
```

- <span class="cfg-global">g_Sel</span>：全域 FB 實例，用於自訂函數表中，提供給 G-code Reader / Interpreter 使用。  
- <span class="cfg-global">g_longline</span>：全域布林變數，透過 `LONGLINE` 這個 G-code 變數名稱映射；G-code 改變 `LONGLINE`，PLC 端就能讀到對應的布林值。  

---

## 五、使用到的函式庫與重要功能塊

| 名稱 | 類別 | 用途 |
|------|------|------|
| <span class="cfg-func">SMC_ReadNCFile2</span> | FB | 讀取 G-code 檔案，支援自訂函數表與變數綁定。 |
| <span class="cfg-func">SMC_NCInterpreter</span> | FB | 將 G-code 句子轉成幾何段與 OutQueue。 |
| <span class="cfg-func">SMC_CheckVelocities</span> | FB | 路徑的速度檢查與平滑限制。 |
| <span class="cfg-func">SMC_GCodeViewer</span> | FB | 提供 3D Path 與 G-code 視覺化資訊。 |
| <span class="cfg-type">SMC_NC_GFunction</span> / <span class="cfg-type">SMC_NC_GFunctionTable</span> | 型態 | 自訂 G Function 描述與函數表。 |
| <span class="cfg-type">SMC_SingleVar</span> / <span class="cfg-type">SMC_VARLIST</span> | 型態 | G-code 變數與 PLC 位址映射。 |
| <span class="cfg-func">MC_Power</span> | FB | 軸上電與驅動啟動。 |

---

## 六、變數與常數一覽（重點）

### 6.1 `CNC_PreparePath` 相關

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">sFileName</span> | <span class="cfg-type">STRING</span> | G-code 檔案路徑（預設 `Application/CNC.cnc`）。 |
| <span class="cfg-local">rncf2</span> | <span class="cfg-type">SMC_ReadNCFile2</span> | G-code 檔案讀取 FB。 |
| <span class="cfg-local">nci</span> | <span class="cfg-type">SMC_NCInterpreter</span> | G-code 解譯 FB。 |
| <span class="cfg-local">cv</span> | <span class="cfg-type">SMC_CheckVelocities</span> | 速度檢查 FB。 |
| <span class="cfg-local">aCNCFunctions</span> | <span class="cfg-type">ARRAY OF SMC_NC_GFunction</span> | 自訂 G Function 陣列，目前只含 `SEL`。 |
| <span class="cfg-local">funTable</span> | <span class="cfg-type">SMC_NC_GFunctionTable</span> | 提供給 `SMC_ReadNCFile2` 的函數表。 |
| <span class="cfg-local">vars</span> | <span class="cfg-type">ARRAY OF SMC_SingleVar</span> | G-code 變數描述陣列。 |
| <span class="cfg-local">varList</span> | <span class="cfg-type">SMC_VARLIST</span> | 提供給 `SMC_ReadNCFile2` 的變數列表。 |
| <span class="cfg-local">xStartIpo</span> | <span class="cfg-type">BOOL</span> (輸出) | 通知插補端「路徑已準備好」。 |

### 6.2 `GVL` 相關

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-global">g_Sel</span> | <span class="cfg-type">CNC_Sel</span> | 自訂 G Function `SEL` 的 FB 實例。 |
| <span class="cfg-global">g_longline</span> | <span class="cfg-type">BOOL</span> | 對應 G-code 變數 `LONGLINE`，可由 G-code 直接控制。 |

---

## 七、特別的演算法與觀念

### 7.1 自訂 G Function 的設計步驟

1. **在全域宣告自訂 FB 實例**（如 `GVL.g_Sel : CNC_Sel;`）。  
2. **建立實作 `SMC_NC_IFunction` 的 FB**（`CNC_Sel`）：  
   - 定義 `argTypes` 陣列描述該 G Function 支援的參數型態。  
   - 內部實作 `Execute` / `Reset` 等介面方法（本範例僅示範型態宣告，實際邏輯可自行擴充）。  
3. **建立 `SMC_NC_GFunction` 陣列 `aCNCFunctions`**：  
   - `stName := 'SEL'`，表示 G-code 中遇到 `SEL` 時使用此函數。  
   - `iFunc := GVL.g_Sel` 連到實際 FB 實例。  
4. **組成 `SMC_NC_GFunctionTable`**（`funTable`），並在呼叫 `SMC_ReadNCFile2` 時以 `pCustomFunTable` 傳入。  

### 7.2 G-code 變數與 PLC 變數的綁定

1. 在 PLC 端宣告對應變數（例如 `GVL.g_longline : BOOL;`）。  
2. 在 `vars` 陣列中配置 <span class="cfg-type">SMC_SingleVar</span>：  
   - `strVarName := 'LONGLINE'`（G-code 中使用的變數名稱）。  
   - `eVarType := SMC_VARTYPE.SMC_TYPE_BOOL`。  
   - `pAdr := ADR(GVL.g_longline)` 指向 PLC 變數位址。  
3. 將 `vars` 包裝成 `varList : SMC_VARLIST`，於 `SMC_ReadNCFile2` 呼叫時以 `pvl` 傳入。  
4. 之後 G-code 內部設定 `LONGLINE = TRUE/FALSE` 時，PLC 端就能在程式中直接讀取 <span class="cfg-global">g_longline</span> 的值。  

---

## 八、重要參數與設定位置

| 參數 | 檔案 / 位置 | 說明 |
|------|-------------|------|
| 檔名 `sFileName` | `CNC_PreparePath.st` | 指定 G-code 檔案路徑。 |
| 自訂函數名 `SEL` | `CNC_PreparePath.st` / `aCNCFunctions` | G-code 中呼叫的自訂指令名稱。 |
| G-code 變數 `LONGLINE` | `CNC_PreparePath.st` / `vars` | 綁定到全域變數 `GVL.g_longline`。 |
| Motion / Path 任務周期 | `TaskConfiguration`（專案中） | 影響插補與路徑前處理的更新頻率。 |

---

## 九、建議閱讀與實驗順序

1. **先看 `GVL.st`**：理解有哪些全域變數與自訂 FB 實例（`g_Sel`、`g_longline`）。  
2. **再讀 `CNC_Sel.st`**：理解如何實作 `SMC_NC_IFunction` 與設定 `argTypes`。  
3. **仔細研讀 `CNC_PreparePath.st`**：  
   - 看清楚 `aCNCFunctions` / `funTable` / `vars` / `varList` 的關係。  
   - 觀察 `rncf2`、`nci`、`cv` 的串接方式。  
4. **最後對照 `CNC.st` 與其他 CNC 範例的 `CNC`／`Ipo`**：  
   - 確認插補與軸控制流程與本範例共通之處。  
5. 在理解後，可嘗試：  
   - 新增第二個自訂函數（例如 `MYFUNC`），並在 G-code 內呼叫。  
   - 新增一個 REAL 型別變數（`FEEDFACT`）映射到 PLC，動態調整進給倍率。  

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">Custom G Function</span> | 由使用者在 PLC 端實作，並由 G-code 呼叫的自訂 G 功能。 |
| <span class="cfg-type">SMC_NC_IFunction</span> | 自訂 G Function 需實作的介面。 |
| <span class="cfg-type">SMC_NC_GFunctionTable</span> | 將多個 G Function 組成表格，傳給 G-code Reader 使用。 |
| <span class="cfg-type">SMC_SingleVar</span> / <span class="cfg-type">SMC_VARLIST</span> | 將 G-code 變數名稱映射到 PLC 變數位址的結構。 |
| <span class="cfg-name">LONGLINE</span> | 範例中的 G-code 變數名稱，對應到 PLC 的 `GVL.g_longline`。 |

