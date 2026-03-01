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

# CNC13_ReadInterpolatorState — 整體架構與功能說明

---

## 一、這個專案在做什麼？

本範例示範如何在 CNC 流程中讀取插補器 <span class="cfg-func">SMC_Interpolator</span> 的「額外狀態」，包含 DCS（機台座標系）位置與方向資訊，並將其轉換、套用到 MCS（機械座標系）位置上，讓程式可以在 PLC 端取得插補器當下的詳細狀態，做為顯示、監控或後續功能（例如 Block Search / Resume）的基礎。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務與 POU 分工

對照 `TaskConfiguration.md`：

| 任務名稱 | 類型 | 週期 | 優先權 | POU 清單 |
|----------|------|------|--------|----------|
| Control | Cyclic | t#4ms | 1 | `Control` |
| PathTask | Cyclic | t#10ms | 2 | `Path` |

- **PathTask（Path）**：負責從 G-code 檔讀取路徑、解譯與速度檢查，輸出路徑佇列。  
- **Control（Control）**：負責插補、軸控制與讀取插補器狀態，把位置資訊轉換成 MCS / DCS，並驅動兩支軸。

### 2.2 軸與裝置

對照 `DeviceTree_Axes.md`：

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| Drive0 | SM_Drive_Virtual | - |
| Drive1 | SM_Drive_Virtual | - |

兩支虛擬軸可想像為 CNC 的 X / Y 軸，由 `Control` 程式透過 <span class="cfg-func">MC_Power</span> 上電，並由 <span class="cfg-func">SMC_ControlAxisByPos</span> 依插補結果給定位置。

### 2.3 函式庫

對照 `Libraries.md`，本範例使用的主要函式庫：

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | SoftMotion 基礎運動控制（MC\_* 功能塊）。 |
| <span class="cfg-name">#SM3_Basic_Visu</span> | SoftMotion 視覺化輔助。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 凸輪相關（本範例間接依賴）。 |
| <span class="cfg-name">#SM3_CNC</span> | CNC / G-code 相關（Interpolator、ReadNCFile、Interpreter、CheckVelocities 等）。 |
| <span class="cfg-name">#System_VisuElem3DPath</span> | 3D Path 視覺化。 |
| <span class="cfg-name">#System_VisuElemCamDisplayer</span> | 凸輪視覺化。 |

---

## 三、控制流程：由淺入深

整體資料流可用一句話描述：

> PathTask 從 G-code 檔讀出路徑 → Interpeter 產生幾何 → CheckVel 檢查後輸出佇列 → Control 任務用 Interpolator 消費佇列並驅動兩軸，同時利用 ReadAdditionalIpoState 讀取插補器狀態並轉成 MCS / DCS 位置。

### 3.1 PathTask：讀檔、解譯與速度檢查

`Path` 程式流程（對照 `Path.st`）：

1. 以 <span class="cfg-func">SMC_ReadNCFile2</span>（變數 `rncf`）讀取 `sFile` 指定的 G-code 檔與子目錄 `sSub`。  
2. 將 `rncf.sentences` 丟給 <span class="cfg-func">SMC_NCInterpreter</span>（變數 `ipr`），設定輸出緩衝 `aBufIpr` 與姿態慣例 `eOriConv:= SMC_ORI_CONVENTION.ZYZ`。  
3. 以 <span class="cfg-func">SMC_CheckVelocities</span>（變數 `cv`）檢查路徑速度，輸出佇列 `cv.poqDataOut`。  
4. 將 `poqDataOut` 指標回傳給控制端使用。

初始化旗標 `bInit` 確保檔名與子目錄僅在第一次執行時設定一次，之後每週期只需持續呼叫 FB。

### 3.2 Control：插補、軸控制與狀態讀取

`Control` 程式流程（對照 `Control.st`）：

1. 兩軸上電：<span class="cfg-func">MC_Power</span> `pw0` / `pw1` 使能 `Drive0` / `Drive1`。  
2. 簡單狀態機 `state`：  
   - `0`：等待兩軸 `Status` 為 TRUE。  
   - `10`：將 Interpolator 的 `bExecute` 接到輸入 `start`。  
3. <span class="cfg-func">SMC_Interpolator</span> `ipo`：  
   - `poqDataIn := Path.poqDataOut` 接上 PathTask 的輸出佇列。  
   - `dwIpoTime := 4000`（4 ms）、`dJerkMax := 10000`。  
   - Emergency stop 條件來自兩個 `SMC_ControlAxisByPos` 的錯誤或停止旗標。  
4. 使用 <span class="cfg-func">SMC_V3_Set</span> 由 `ipo.piSetPosition.dX/Y/Z` 組出 `pos_MCS`，代表 MCS 下的目標位置。  
5. 使用 <span class="cfg-func">SMC_ReadAdditionalIpoState</span> `readState` 讀取插補器額外狀態，包含 `State.DCS`（DCS 位置）與 `State.OriConv`。  
6. 當 `readState.Valid` 為 TRUE 時：  
   - 先用 <span class="cfg-func">SMC_PosInfo_Trf_Inverse</span> 從 `State.DCS` 推回一個「DCS→MCS 轉換」矩陣 `piMCS_to_DCS`。  
   - 再用 <span class="cfg-func">SMC_PosInfo_Trf_Apply</span> 將 MCS 位置 `pos_MCS` 套到這個轉換上，得到 `pos_DCS`，便於顯示或後處理。  
7. 最後由兩個 <span class="cfg-func">SMC_ControlAxisByPos</span> `cap0` / `cap1` 將 `ipo.piSetPosition.dX/Y` 寫入 `Drive0` / `Drive1`。

### 3.3 Trace 與監看

`TraceConfig.md` 設定了三個變數：

| 變數名 | 任務 | 緩衝筆數 |
|--------|------|----------|
| Control.ipo.piSetPosition.dX | Control | 251 |
| Control.ipo.piSetPosition.dY | Control | 251 |
| Control.ipo.dVel | Control | 251 |

可搭配 `pos_MCS` / `pos_DCS` 的監看來比較不同座標系下的位置與速度。

---

## 四、各支程式負責哪些功能？

### 4.1 `Control.st`

- **類型**：PROGRAM。  
- **角色**：主控制程式，負責：
  - 兩軸 `Drive0` / `Drive1` 的上電與位置控制。  
  - 插補器 <span class="cfg-func">SMC_Interpolator</span> 的執行（消費 PathTask 的路徑佇列）。  
  - 透過 <span class="cfg-func">SMC_ReadAdditionalIpoState</span> 讀取插補器的 DCS 狀態，並轉換到 MCS / DCS 位置輸出。  
- **對外介面**：
  - `start`：啟動插補的輸入。  
  - `pos_MCS` / `pos_DCS`：分別代表機械座標系與機台座標系下的插補位置。

### 4.2 `Path.st`

- **類型**：PROGRAM。  
- **角色**：路徑準備程式，負責：
  - 以 <span class="cfg-func">SMC_ReadNCFile2</span> 讀取 G-code 檔（含子程式目錄）。  
  - 以 <span class="cfg-func">SMC_NCInterpreter</span> 將句子解譯為幾何段佇列。  
  - 以 <span class="cfg-func">SMC_CheckVelocities</span> 進行速度檢查，輸出供插補器使用的路徑佇列。  
- **對外介面**：
  - `sFile` / `sSub`：檔案名稱與子程式路徑。  
  - `poqDataOut`：指向經速度檢查後的路徑佇列。

### 4.3 `GVL_PARAMETERS.st`

- **類型**：全域常數表。  
- **內容**：  
  - <span class="cfg-const">dAngleTol</span>：角度公差，供 <span class="cfg-func">SMC_CheckVelocities</span> 等功能塊使用。

---

## 五、函式庫與函式／功能塊一覽

以下僅列出在本範例程式中實際使用到、且理解範例重點所需的功能塊／函式。

| 名稱 | 類別 | 用途 |
|------|------|------|
| <span class="cfg-func">MC_Power</span> | FB | 軸上電與驅動啟動，`Enable` / `bRegulatorOn` / `bDriveStart` 控制狀態，`Status` 表示軸就緒。 |
| <span class="cfg-func">SMC_Interpolator</span> | FB | 從路徑佇列插補產生 `piSetPosition` 與 `vecActTangent` 等資訊。 |
| <span class="cfg-func">SMC_ControlAxisByPos</span> | FB | 根據插補結果驅動單軸位置，`fSetPosition` 為位置命令。 |
| <span class="cfg-func">SMC_ReadNCFile2</span> | FB | 從檔案讀取 G-code 並產生句子隊列 `sentences`。 |
| <span class="cfg-func">SMC_NCInterpreter</span> | FB | 將 `sentences` 解譯成幾何段路徑佇列 `poqDataOut`。 |
| <span class="cfg-func">SMC_CheckVelocities</span> | FB | 速度檢查與平滑處理，輸出插補器可直接使用的佇列。 |
| <span class="cfg-func">SMC_ReadAdditionalIpoState</span> | FB | 讀取插補器的額外狀態（例如 DCS 中的位置與姿態、物件資訊）。 |
| <span class="cfg-func">SMC_PosInfo_Trf_Inverse</span> | 函式 | 由一個位置資訊 `piIn` 建立「相反轉換」的 <span class="cfg-type">SMC_PosInfo</span> 結構。 |
| <span class="cfg-func">SMC_PosInfo_Trf_Apply</span> | 函式 | 將轉換 `piTrf` 套用到向量 `vSrc` 上，輸出 `vDst`。 |
| <span class="cfg-func">SMC_V3_Set</span> | 函式 | 便利函式，將 X/Y/Z 轉成 <span class="cfg-type">SMC_Vector3D</span>。 |

---

## 六、變數與常數一覽

本範例僅使用一個全域常數，其他變數皆為區域或暫存，未使用 RETAIN／PERSISTENT。

### 6.1 全域常數（`GVL_PARAMETERS.st`）

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| <span class="cfg-const">dAngleTol</span> | <span class="cfg-type">LREAL</span> | 0.001 | 路徑角度公差，供 <span class="cfg-func">SMC_CheckVelocities</span> 使用，用來判斷轉角是否需要特殊處理。 |

### 6.2 `Control` 重要變數（節選）

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">ipo</span> | <span class="cfg-type">SMC_Interpolator</span> | 插補器，輸入路徑佇列、輸出 `piSetPosition` 與速度資訊。 |
| <span class="cfg-local">pw0</span>, <span class="cfg-local">pw1</span> | <span class="cfg-type">MC_Power</span> | 兩軸上電與驅動啟動。 |
| <span class="cfg-local">cap0</span>, <span class="cfg-local">cap1</span> | <span class="cfg-type">SMC_ControlAxisByPos</span> | 兩軸位置控制，將 `ipo.piSetPosition.dX/dY` 寫入 `Drive0/Drive1`。 |
| <span class="cfg-local">readState</span> | <span class="cfg-type">SMC_ReadAdditionalIpoState</span> | 插補器額外狀態讀取 FB。 |
| <span class="cfg-local">pos_MCS</span>, <span class="cfg-local">pos_DCS</span> | <span class="cfg-type">SMC_Vector3D</span> | 分別代表機械座標系與機台座標系下的位置向量。 |
| <span class="cfg-local">piMCS_to_DCS</span> | <span class="cfg-type">SMC_PosInfo</span> | 用於 MCS → DCS 轉換的暫存結構。 |

### 6.3 `Path` 重要變數（節選）

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">rncf</span> | <span class="cfg-type">SMC_ReadNCFile2</span> | 從檔案讀取 G-code，輸出 `sentences`。 |
| <span class="cfg-local">ipr</span> | <span class="cfg-type">SMC_NCInterpreter</span> | 將 `sentences` 轉為幾何段路徑。 |
| <span class="cfg-local">cv</span> | <span class="cfg-type">SMC_CheckVelocities</span> | 對幾何段做速度檢查與限制。 |
| <span class="cfg-local">aBufIpr</span> | <span class="cfg-type">ARRAY[0..15] OF SMC_GeoInfo</span> | Interpreter 的輸出緩衝。 |
| <span class="cfg-local">bInit</span> | <span class="cfg-type">BOOL</span> | 用來確保檔案名稱與子目錄只在第一次執行時設定。 |

---

## 七、特別的演算法與觀念

### 7.1 MCS 與 DCS 位置的轉換

插補器 `ipo` 主要在 MCS 中工作，但 CNC 與視覺化常使用 DCS 或其他座標系。透過：

1. `pos_MCS`：由 `ipo.piSetPosition.dX/Y/Z` 組成的 MCS 位置。  
2. `readState.State.DCS`：由 <span class="cfg-func">SMC_ReadAdditionalIpoState</span> 讀出的 DCS 位置。  
3. `SMC_PosInfo_Trf_Inverse` / `SMC_PosInfo_Trf_Apply`：  
   - 先由 DCS 建立轉換（DCS→MCS 或 MCS→DCS）。  
   - 再把 `pos_MCS` 套上轉換，得到 DCS 下的 `pos_DCS`。  

這樣程式不需要自己處理複雜的旋轉與偏移，只要透過庫提供的 <span class="cfg-type">SMC_PosInfo</span> 函式即可在多座標系之間來回。

### 7.2 插補器狀態做 Block Search / Resume 的基礎

雖然本範例沒有直接實作 Block Search / Resume，但 <span class="cfg-func">SMC_ReadAdditionalIpoState</span> 取得的 `State` 中通常會包含：

- 目前物件編號、路徑位置、是否在末端等資訊；  
- DCS/MCS 下的位置與姿態。  

在實務上可以藉由這些資訊紀錄「當下加工點」，在中斷或停機後選擇最接近的程式段落繼續，這也是後續 CNC13 / CNC15 等進階範例的基礎。

---

## 八、重要參數與設定位置

| 參數 | 檔案 / 位置 | 說明 |
|------|-------------|------|
| <span class="cfg-const">dAngleTol</span> | `GVL_PARAMETERS.st` | 路徑角度公差。 |
| 任務週期 t#4ms | `TaskConfiguration.md`（Control） | 插補與軸控制的更新頻率。 |
| 任務週期 t#10ms | `TaskConfiguration.md`（PathTask） | G-code 解譯與速度檢查的週期。 |
| G-code 檔名 `sFile` | `Path.st` | 讀取的 CNC 檔路徑，可依實際檔案修改。 |

---

## 九、建議閱讀與修改順序

1. **先看 `GVL_PARAMETERS.st`**：了解角度公差等全域設定。  
2. **再看 `TaskConfiguration.md` 與 `DeviceTree_Axes.md`**：搞清楚任務與兩軸結構。  
3. **接著讀 `Path.st`**：看 G-code 如何經 ReadNCFile2 → Interpreter → CheckVel 變成路徑佇列。  
4. **最後讀 `Control.st`**：理解插補器、軸控制與 MCS/DCS 轉換的關係，可搭配 Trace 觀看。  
5. 若要延伸，可在 `Control` 中增加更多輸出（例如目前物件編號、DCS Z 位置），或在 HMI 顯示 MCS / DCS 下的位置差異。

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">MCS</span> | Mechanical Coordinate System，機械／機構座標系。 |
| <span class="cfg-name">DCS</span> | Device Coordinate System 或 Display Coordinate System，顯示／機台座標系。 |
| <span class="cfg-func">SMC_ReadAdditionalIpoState</span> | 讀取插補器額外狀態的 SoftMotion 功能塊。 |
| <span class="cfg-type">SMC_PosInfo</span> | SoftMotion 的位置與轉換資訊結構。 |
| <span class="cfg-name">Block Search / Resume</span> | CNC 先搜尋路徑上某一區段，再從該處續跑的高階功能。 |

