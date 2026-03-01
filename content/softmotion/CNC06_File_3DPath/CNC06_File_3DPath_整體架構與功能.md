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

# CNC06_File_3DPath — 整體架構與功能說明

---

## 一、這個專案在做什麼？

本範例在 CNC05\_File「從檔案讀取 G-code 並執行」的基礎上，加入 **3D 路徑視覺化**：使用 <span class="cfg-func">SMC_PathCopierFile</span> 將 G-code 路徑轉成 3D Path 點陣列，並搭配 <span class="cfg-func">SMC_PositionTracker</span>（`SMC_PositionTracker`）在 CNC 執行時追蹤實際運動軌跡，讓視覺化畫面可以同時顯示「理論刀路」與「實際行走路徑」。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務與程式

`TaskConfiguration.md`：

| 任務名稱 | 類型 | 週期 | 優先權 | POU 清單 |
|----------|------|------|--------|----------|
| MotionTask | Cyclic | t#gc_dwCycle | 1 | `CNC` |
| PathTask | Cyclic | t#20ms | 5 | `CNC_PreparePath` |
| VISU_TASK | Cyclic | t#100ms | 10 | `VisuElems.Visu_Prg` |

- **MotionTask（CNC）**：插補、三軸控制與實際路徑追蹤（PositionTracker）。  
- **PathTask（CNC_PreparePath）**：從 G-code 檔案讀取並產生路徑佇列，同時使用 PathCopierFile 預先生成 3D Path 資料。  
- **VISU_TASK**：使用 3D Path 與 PositionTracker 輸出的資料做視覺化。

### 2.2 軸與裝置

`DeviceTree_Axes.md`：

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| AxisX | SM_Drive_Virtual | - |
| AxisY | SM_Drive_Virtual | - |
| AxisZ | SM_Drive_Virtual | - |

與 CNC05 相同，為三軸虛擬 CNC。

### 2.3 函式庫

`Libraries.md`：

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | SoftMotion 基礎運動控制。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 凸輪相關。 |
| <span class="cfg-name">#System_VisuElem3DPath</span> | Path3D、VisuStruct3DPathPoint 等 3D 路徑視覺化元件。 |
| <span class="cfg-name">#System_VisuElemCamDisplayer</span> | 凸輪視覺化。 |

---

## 三、控制流程：由淺入深

### 3.1 PathTask：從檔案讀取 G-code + 預先產生 3D Path

`CNC_PreparePath.st`：

```pascal
PROGRAM CNC_PreparePath
VAR_INPUT
	xStart: BOOL;
	sFileName: STRING := '_cnc/CNC1.cnc';
END_VAR
VAR_OUTPUT
	xStartIpo: BOOL;
	poqPath: Pointer to SMC_Outqueue;
END_VAR
VAR
	iState: INT;
	rncf2 : SMC_ReadNCFile2;
	nci: SMC_NCInterpreter;
	cv: SMC_CheckVelocities;
	agiBufInterpreter: ARRAY[0..99] OF SMC_GeoInfo;

	pcf: SMC_PathCopierFile;
	pointbuffer: ARRAY [0..1000] OF VisuStruct3DPathPoint;

	vc: VisuStruct3DControl;
END_VAR
```

重要流程：

1. `poqPath := cv.poqDataOut`：與 CNC05 一樣，輸出為速度檢查後的路徑佇列。  
2. 狀態 `0`（idle）時，當 `xStart` 為 TRUE：  
   - 清除 `rncf2` / `nci` / `cv` 的執行狀態。  
   - 呼叫 <span class="cfg-func">SMC_PathCopierFile</span> `pcf` 預先產生 3D Path：  
     - `udiNumberOfPointsInArray := SIZEOF(pointbuffer)/SIZEOF(pointbuffer[0])`。  
     - `pBuffer := ADR(pointbuffer)`。  
     - `sFileName := sFileName`。  
   - 以 `WHILE NOT (pcf.bDone OR pcf.bError)` 迴圈呼叫 `pcf(bExecute := TRUE)`，直到完成或錯誤。  
   - 完成後 `xStart := FALSE`，進入下一狀態。  
3. 狀態 `10`：與 CNC05 幾乎相同：  
   - `rncf2(bExecute := TRUE, sFileName := sFileName)`：讀 G-code 檔。  
   - `nci(bExecute := TRUE, sentences := rncf2.sentences, ...)`：解譯成幾何段。  
   - `cv(bExecute := TRUE, poqDataIn := nci.poqDataOut)`：速度檢查。  
   - `xStartIpo := TRUE`，完成後回到 `iState := 0`。  

**差異點**：CNC05 只有讀檔與解譯；CNC06 先用 `SMC_PathCopierFile` 把整條刀路轉成 3D 點陣列 `pointbuffer`，供 3D Path 元件使用。

### 3.2 MotionTask：三軸插補 + 實際位置追蹤

`CNC.st`：

```pascal
PROGRAM CNC
VAR
	iState: INT;
	pX, pY, pZ: MC_Power;

	ipo: SMC_Interpolator;
	trafo: SMC_TRAFO_Gantry3;
	trafof: SMC_TRAFOF_Gantry3D;
	cabpX, 	cabpY, 	cabpZ: SMC_ControlAxisByPos;

	pt: SMC_PositionTracker;
	pointbuffer_pt: ARRAY [0..1000] OF VisuStruct3DPathPoint;
END_VAR
```

1. 三軸上電：與 CNC05 相同，三個 <span class="cfg-func">MC_Power</span>。  
2. 狀態機 `iState`：  
   - `0`：等待三軸 `Status` 就緒。  
   - `100`：呼叫 `Interpolation()`。  
3. 在 `Interpolation()` 中（定義未展開，但可從變數推測）：  
   - `ipo` 從 `CNC_PreparePath.poqPath` 取得路徑並插補。  
   - `trafo` / `trafof` 轉換成三軸 SetPosition。  
   - `cabpX/Y/Z` 寫入三軸位置。  
   - `pt`（<span class="cfg-func">SMC_PositionTracker</span>）使用 `ipo` 或實際軸位置，產生實際運動軌跡點並寫入 `pointbuffer_pt`，供視覺化比較「理論刀路（PathCopierFile）」與「實際軌跡（PositionTracker）」。

視覺化程式 `VisuElems.Visu_Prg` 會讀取 `pointbuffer`（理論路徑）與 `pointbuffer_pt`（實走路徑）以及控制變數 `vc : VisuStruct3DControl`，在 Path3D 等元件中顯示。

---

## 四、各支程式負責哪些功能？

### 4.1 `CNC.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 三軸上電與插補（與 CNC05 類似）。  
  - 使用 <span class="cfg-func">SMC_PositionTracker</span> `pt` 追蹤實際運動位置，並將結果寫入 `pointbuffer_pt`，供 3D 視覺化使用。  

### 4.2 `CNC_PreparePath.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 使用 <span class="cfg-func">SMC_PathCopierFile</span> `pcf` 從 G-code 檔案產生理論 3D 路徑點陣列 `pointbuffer`。  
  - 使用 <span class="cfg-func">SMC_ReadNCFile2</span> 讀檔、<span class="cfg-func">SMC_NCInterpreter</span> 解譯與 <span class="cfg-func">SMC_CheckVelocities</span> 速度檢查，輸出 `poqPath`。  
  - 與 MotionTask 透過 `xStart` / `xStartIpo` 簡單同步啟動。  

### 4.3 `GVL.st`

```pascal
VAR_GLOBAL CONSTANT
	gc_dwCycle : DWORD := 4000;
END_VAR
```

- **職責**：提供 MotionTask 週期常數。

---

## 五、函式庫與函式／功能塊一覽

| 名稱 | 類別 | 用途 |
|------|------|------|
| <span class="cfg-func">SMC_ReadNCFile2</span> | FB | 從檔案系統讀取 ASCII G-code。 |
| <span class="cfg-func">SMC_NCInterpreter</span> | FB | 將 G-code 句子解譯成幾何段。 |
| <span class="cfg-func">SMC_CheckVelocities</span> | FB | 對路徑做速度檢查。 |
| <span class="cfg-func">SMC_PathCopierFile</span> | FB | 讀取 G-code 檔並生成理論 3D 路徑點陣列。 |
| <span class="cfg-func">SMC_PositionTracker</span> | FB | 追蹤插補或軸的實際路徑，輸出 3D 路徑點陣列。 |
| <span class="cfg-func">SMC_Interpolator</span> | FB | 插補路徑。 |
| <span class="cfg-func">SMC_TRAFO_Gantry3</span> / <span class="cfg-func">SMC_TRAFOF_Gantry3D</span> | FB | 三軸龍門座標轉換。 |
| <span class="cfg-func">SMC_ControlAxisByPos</span> | FB | 軸位置控制。 |
| <span class="cfg-func">MC_Power</span> | FB | 軸上電。 |

---

## 六、變數與常數一覽

本範例未使用 RETAIN／PERSISTENT。

### 6.1 全域常數（`GVL.st`）

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| <span class="cfg-const">gc_dwCycle</span> | <span class="cfg-type">DWORD</span> | 4000 | MotionTask 週期（μs）。 |

### 6.2 `CNC_PreparePath` 主要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">xStart</span> / <span class="cfg-local">xStartIpo</span> | <span class="cfg-type">BOOL</span> | 啟動一次路徑與 3D Path 準備 / 向插補器發出「路徑就緒」訊號。 |
| <span class="cfg-local">sFileName</span> | <span class="cfg-type">STRING</span> | G-code 檔路徑，預設 `_cnc/CNC1.cnc`。 |
| <span class="cfg-local">rncf2</span> | <span class="cfg-type">SMC_ReadNCFile2</span> | 讀檔 FB。 |
| <span class="cfg-local">nci</span> | <span class="cfg-type">SMC_NCInterpreter</span> | 解譯 FB。 |
| <span class="cfg-local">cv</span> | <span class="cfg-type">SMC_CheckVelocities</span> | 速度檢查 FB。 |
| <span class="cfg-local">pcf</span> | <span class="cfg-type">SMC_PathCopierFile</span> | 生成理論 3D 路徑資料。 |
| <span class="cfg-local">pointbuffer</span> | <span class="cfg-type">ARRAY [0..1000] OF VisuStruct3DPathPoint</span> | 理論 3D 路徑點。 |
| <span class="cfg-local">vc</span> | <span class="cfg-type">VisuStruct3DControl</span> | 視覺化控制結構。 |

### 6.3 `CNC` 主要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">pX/pY/pZ</span> | <span class="cfg-type">MC_Power</span> | 三軸上電。 |
| <span class="cfg-local">ipo</span> | <span class="cfg-type">SMC_Interpolator</span> | 插補器。 |
| <span class="cfg-local">trafo/trafof</span> | <span class="cfg-type">SMC_TRAFO_Gantry3</span> / <span class="cfg-type">SMC_TRAFOF_Gantry3D</span> | 三軸座標轉換。 |
| <span class="cfg-local">cabpX/cabpY/cabpZ</span> | <span class="cfg-type">SMC_ControlAxisByPos</span> | 三軸位置控制。 |
| <span class="cfg-local">pt</span> | <span class="cfg-type">SMC_PositionTracker</span> | 實際路徑追蹤 FB。 |
| <span class="cfg-local">pointbuffer_pt</span> | <span class="cfg-type">ARRAY [0..1000] OF VisuStruct3DPathPoint</span> | 實際 3D 路徑點。 |

---

## 七、特別的演算法與觀念

### 7.1 理論刀路 vs. 實際軌跡

透過 <span class="cfg-func">SMC_PathCopierFile</span> 與 <span class="cfg-func">SMC_PositionTracker</span>，CNC06 能夠同時取得：

- **理論刀路**（PathCopierFile）：直接從 G-code 檔案計算得來的理想路徑，未受速度限制與加減速等動態因素影響。  
- **實際軌跡**（PositionTracker）：考慮了插補、加減速與可能的速度限制後，實際軸位置的走向。  

在視覺化介面中可把兩者畫在同一個 3D 視圖中，對比差異，有助於調整動態參數與路徑品質。

### 7.2 PathTask 內部的阻塞 PathCopier 呼叫

在 `xStart` 被觸發時，使用 `WHILE NOT (pcf.bDone OR pcf.bError)` 迴圈同步跑完 PathCopierFile：

- 這樣可以在「第一次啟動前」就生成完整的 3D Path，確保 VISU 端一開始就有完整路徑可顯示。  
- 在實際專案中，若 G-code 很大，可改以類似 CNC15\_LargeGCode 的分批處理方式，以避免一次性阻塞 PathTask 過久。

---

## 八、重要參數與設定位置

| 參數 | 檔案 / 位置 | 說明 |
|------|-------------|------|
| <span class="cfg-const">gc_dwCycle</span> | `GVL.st` | MotionTask 插補週期。 |
| `sFileName` | `CNC_PreparePath.st` | G-code 檔案路徑。 |
| `udiNumberOfPointsInArray` | `CNC_PreparePath.st` 內 `pcf` 呼叫 | 3D Path 點陣列大小，需與實際路徑複雜度匹配。 |

---

## 九、建議閱讀與修改順序

1. 先閱讀 `GVL.st`、`TaskConfiguration.md` 與 `DeviceTree_Axes.md`，了解任務週期與三軸結構。  
2. 再看 `CNC_PreparePath.st`，弄清楚 ReadNCFile2 + NCInterpreter + CheckVel + PathCopierFile 的結構。  
3. 接著看 `CNC.st`，特別注意 `pt` 與 `pointbuffer_pt` 如何與插補與軸位置搭配。  
4. 在 CODESYS 中開啟視覺化畫面，觀察理論刀路與實際軌跡的差異，嘗試調整 3D Path 點數與運動參數。  

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-func">SMC_PathCopierFile</span> | 從 G-code 檔案生成 3D Path 點陣列的 SoftMotion FB。 |
| <span class="cfg-func">SMC_PositionTracker</span> | 根據插補或軸位置追蹤實際路徑點的 SoftMotion FB。 |
| <span class="cfg-type">VisuStruct3DPathPoint</span> | System\_VisuElem3DPath 提供的 3D 路徑點結構，供 Path3D 等元件使用。 |

