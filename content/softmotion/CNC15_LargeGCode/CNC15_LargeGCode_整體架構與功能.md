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

# CNC15_LargeGCode — 整體架構與功能說明

---

## 一、這個專案在做什麼？

本範例示範如何在 CODESYS SoftMotion 中處理 **大型 G-code 程式**：在 Path 任務中以「分批循環處理」方式讀取檔案、解譯、前處理與速度檢查，每個週期只處理一小段資料，累積到路徑佇列中；Control 任務則從這個佇列持續插補與驅動兩軸。這種做法適用於刀路很長、無法一次性讀入記憶體的情境。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務配置

`TaskConfiguration.md`：

| 任務名稱 | 類型 | 週期 | 優先權 | POU 清單 |
|----------|------|------|--------|----------|
| MainTask | Cyclic | t#4ms | 1 | `Control` |
| PathTask | Cyclic | t#4ms | 2 | `Path` |

兩個任務週期同為 4 ms，但職責不同：

- **PathTask（Path）**：讀檔、解譯、平滑與速度檢查，逐步填滿路徑佇列。  
- **MainTask（Control）**：插補與兩軸控制，消費路徑佇列。

### 2.2 軸與裝置

`DeviceTree_Axes.md`：

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| Drive1 | SM_Drive_Virtual | - |
| Drive2 | SM_Drive_Virtual | - |

兩支虛擬軸可想成 X / Y 軸，由 `Control` 程式透過 <span class="cfg-func">MC_Power</span> 上電，並由 <span class="cfg-func">SMC_ControlAxisByPos</span> 依插補結果給定位置。

### 2.3 函式庫

`Libraries.md` 顯示：

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | 基礎運動控制。 |
| <span class="cfg-name">#SM3_Basic_Visu</span> | 視覺化輔助。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 凸輪相關。 |
| <span class="cfg-name">#SM3_CNC</span> | CNC 解碼、前處理與插補。 |

---

## 三、控制流程：由淺入深

### 3.1 PathTask：大型 G-code 分批讀取與前處理

`Path` 程式（`Path.st`）的核心是一個 `WHILE` 迴圈，搭配 `counter` 控制「每個週期最多處理幾次」：

1. 在每個週期開始時，`counter := 25`（可視 CPU 與任務負載調整）。  
2. 迴圈條件：  
   - `counter > 0`，且  
   - 輸出佇列尚未被填滿或尚未到路徑結束：  
     ```text
     poqDataOut = 0 OR_ELSE (NOT poqDataOut^.bFull AND NOT poqDataOut^.bEndOfList)
     ```  
3. 迴圈體內依序呼叫：  
   - <span class="cfg-func">SMC_ReadNCFile2</span> `rncf`：  
     - `bExecute := TRUE`；  
     - `sFileName := '_cnc/CNC.cnc'`。  
   - <span class="cfg-func">SMC_NCInterpreter</span> `ip`：  
     - `sentences := rncf.sentences`；  
     - `bExecute := rncf.bExecute`；  
     - 使用 `aBufIp` 作為輸出緩衝。  
   - <span class="cfg-func">SMC_SmoothMerge</span> `smm`：  
     - 接上 `ip.poqDataOut`，將段與段之間以樣條方式平滑銜接，並限制最大形狀差異 `piMaxDifference`、最小曲率半徑 `dMinCurvatureRadius` 等。  
   - <span class="cfg-func">SMC_SmoothPath</span> `smp`：  
     - 對 `smm.poqDataOut` 再做一次樣條平滑（五次樣條、最小曲率）。  
   - <span class="cfg-func">SMC_CheckVelocities</span> `cv`：  
     - 對 `smp.poqDataOut` 做速度檢查，考慮角度公差 `dAngleTol`。  
4. 每迴圈最後 `counter := counter - 1`，避免 PathTask 在單一週期處理過多工作。  
5. 迴圈結束後，`poqDataOut := cv.poqDataOut` 作為整份路徑的輸出佇列。

**重點觀念**：  
- `RNFC + Interpreter + SmoothMerge + SmoothPath + CheckVel` 整串前處理被切成許多「小步驟」，每個週期最多執行 25 個步驟，避免長時間堵在 PathTask。  
- 只要輸出佇列還沒滿（`bFull = FALSE`）且未到 `bEndOfList = TRUE`，PathTask 就會持續填充，直到整份大型 G-code 都被前處理完為止。

### 3.2 MainTask：插補與兩軸驅動

`Control` 程式（`Control.st`）流程：

1. 兩軸上電：  
   - 兩個 <span class="cfg-func">MC_Power</span> `pow1` / `pow2`，`Enable := TRUE`、`bRegulatorOn := TRUE`、`bDriveStart := TRUE`，分別作用於 `Drive1` 與 `Drive2`。  
2. 插補器：  
   - <span class="cfg-func">SMC_Interpolator</span> `ipo`：  
     - `dwIpoTime := dwTaskCycleMicros`（全域常數，預設 4000 μs）。  
     - `dJerkMax := dJerkMax`（全域常數）。  
     - `bExecute := bInitialized`：僅在兩軸都就緒後才開始執行。  
     - `poqDataIn := Path.poqDataOut`：消費 PathTask 輸出佇列。  
3. 軸控制：  
   - 兩個 <span class="cfg-func">SMC_ControlAxisByPos</span> `cap1` / `cap2` 將 `ipo.piSetPosition.dX` / `dY` 寫入 `Drive1` / `Drive2`。  
4. 初始化邏輯：  
   - `bInitialized` 只有在 `pow1.Status AND pow2.Status` 成立時才會變 TRUE，保證插補器啟動前兩軸已就緒。

---

## 四、各支程式負責哪些功能？

### 4.1 `Control.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 兩軸上電（`Drive1` / `Drive2`）。  
  - 使用 <span class="cfg-func">SMC_Interpolator</span> 以固定插補週期從 `Path.poqDataOut` 中取樣路径。  
  - 透過兩個 <span class="cfg-func">SMC_ControlAxisByPos</span> 依插補器的 `piSetPosition.dX/dY` 驅動軸位置。  
- **初始化保護**：  
  - 透過 `bInitialized` 確保插補只在兩軸就緒後啟動。

### 4.2 `Path.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 在 `WHILE` 迴圈中以「小步驟」方式進行：讀檔 → 解譯 → SmoothMerge → SmoothPath → CheckVel。  
  - 使用 `counter` 控制單一週期處理量，避免 PathTask 佔用過多時間。  
  - 持續填入 `cv.poqDataOut` 直到 G-code 讀完並設 `bEndOfList = TRUE`。  

### 4.3 `GVL_PARAMETERS.st`

- **類型**：全域變數表。  
- **職責**：集中定義前處理與插補的重要參數：

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| <span class="cfg-global">piMaxDifference</span> | <span class="cfg-type">SMC_PosInfo</span> | dX/Y/Z/A/B/C 設為小值 | 給 <span class="cfg-func">SMC_SmoothMerge</span> 的最大幾何差異限制。 |
| <span class="cfg-global">dAngleTol</span> | <span class="cfg-type">LREAL</span> | 0.01 | 角度公差，給 <span class="cfg-func">SMC_SmoothPath</span> / <span class="cfg-func">SMC_CheckVelocities</span> 用。 |
| <span class="cfg-global">dMinCurvatureRadius</span> | <span class="cfg-type">LREAL</span> | 0.015 | 最小曲率半徑，用於平滑與 Merge。 |
| <span class="cfg-global">dwTaskCycleMicros</span> | <span class="cfg-type">DWORD</span> | 4000 | 插補器週期（μs）。 |
| <span class="cfg-global">dJerkMax</span> | <span class="cfg-type">LREAL</span> | 10000 | 插補器最大躍度。 |

---

## 五、函式庫與函式／功能塊一覽

| 名稱 | 類別 | 用途 |
|------|------|------|
| <span class="cfg-func">SMC_ReadNCFile2</span> | FB | 從檔案讀取 G-code。 |
| <span class="cfg-func">SMC_NCInterpreter</span> | FB | 將 G-code 句子解譯為幾何段佇列。 |
| <span class="cfg-func">SMC_SmoothMerge</span> | FB | 在段與段之間作幾何銜接與平滑。 |
| <span class="cfg-func">SMC_SmoothPath</span> | FB | 以 Spline 平滑整條路徑。 |
| <span class="cfg-func">SMC_CheckVelocities</span> | FB | 最終速度檢查與限制。 |
| <span class="cfg-func">SMC_Interpolator</span> | FB | 插補路徑產生軸 SetPosition。 |
| <span class="cfg-func">SMC_ControlAxisByPos</span> | FB | 按 SetPosition 驅動單軸。 |
| <span class="cfg-func">MC_Power</span> | FB | 軸上電與驅動啟動。 |

---

## 六、變數與常數一覽

本範例未使用 RETAIN／PERSISTENT。

### 6.1 全域變數（`GVL_PARAMETERS.st`）

已於四、5 小節表格列出，這裡不重複。

### 6.2 `Path` 主要區域變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">rncf</span> | <span class="cfg-type">SMC_ReadNCFile2</span> | 檔案讀取。 |
| <span class="cfg-local">ip</span> | <span class="cfg-type">SMC_NCInterpreter</span> | 解譯 G-code 句子。 |
| <span class="cfg-local">smm</span> | <span class="cfg-type">SMC_SmoothMerge</span> | 段與段的幾何銜接。 |
| <span class="cfg-local">smp</span> | <span class="cfg-type">SMC_SmoothPath</span> | 整體 Spline 平滑。 |
| <span class="cfg-local">cv</span> | <span class="cfg-type">SMC_CheckVelocities</span> | 速度檢查。 |
| <span class="cfg-local">aBufIp</span> / <span class="cfg-local">aBufSmm</span> / <span class="cfg-local">aBufSmp</span> | <span class="cfg-type">ARRAY OF SMC_GeoInfo</span> | 各階段輸出緩衝。 |
| <span class="cfg-local">counter</span> | <span class="cfg-type">DINT</span> | 每週期最多處理次數的計數器。 |

### 6.3 `Control` 主要區域變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">pow1</span>, <span class="cfg-local">pow2</span> | <span class="cfg-type">MC_Power</span> | 兩軸上電。 |
| <span class="cfg-local">cap1</span>, <span class="cfg-local">cap2</span> | <span class="cfg-type">SMC_ControlAxisByPos</span> | 兩軸位置控制。 |
| <span class="cfg-local">ipo</span> | <span class="cfg-type">SMC_Interpolator</span> | 插補器。 |
| <span class="cfg-local">bInitialized</span> | <span class="cfg-type">BOOL</span> | 軸就緒後允許啟動插補。 |

---

## 七、特別的演算法與觀念

### 7.1 大型 G-code 的「分批處理」策略

關鍵在於 `Path` 中的 `WHILE` 迴圈：

- 每個 PathTask 週期只跑固定次數（由 `counter` 控制），避免長時間阻塞。  
- 每次迴圈都讓 ReadNCFile2 / Interpreter / SmoothMerge / SmoothPath / CheckVel 向前推進一小步。  
- 只要輸出佇列尚未滿且未到結尾，就會持續累積資料。  

這樣可以在不一次性載入整個 G-code 的情況下，逐步將大型 G-code 轉成平滑、可插補的路徑，同時保持可接受的反應時間與 CPU 負載。

### 7.2 PathTask 與 MainTask 的協同

- **PathTask** 保持「往前填路徑」，避免插補器斷料。  
- **MainTask** 僅負責依插補週期消費路徑並推動軸位置。  

只要 PathTask 能在插補器消耗前補足足夠的 look-ahead 佇列，整體運動就能平滑進行，即使背後的 G-code 檔案很大。

---

## 八、重要參數與設定位置

| 參數 | 檔案 / 位置 | 說明 |
|------|-------------|------|
| `counter` 初始值 | `Path.st` | 控制每個 PathTask 週期最多處理幾個「小步驟」，影響 CPU 負載與建路速度。 |
| `sFileName` | `Path.st` 內 `rncf` 呼叫 | 指定要讀取的大型 G-code 檔案路徑。 |
| <span class="cfg-global">piMaxDifference</span> / <span class="cfg-global">dMinCurvatureRadius</span> / <span class="cfg-global">dAngleTol</span> | `GVL_PARAMETERS.st` | 決定 SmoothMerge / SmoothPath / CheckVel 的平滑與公差設定。 |
| <span class="cfg-global">dwTaskCycleMicros</span> / <span class="cfg-global">dJerkMax</span> | `GVL_PARAMETERS.st` | 插補週期與最大躍度，需搭配 MainTask 週期評估。 |

---

## 九、建議閱讀與修改順序

1. 先看 `GVL_PARAMETERS.st`：理解與前處理與插補有關的全域參數。  
2. 再看 `TaskConfiguration.md` 與 `DeviceTree_Axes.md`：掌握任務與兩軸架構。  
3. 接著讀 `Path.st`，特別是 `WHILE` 迴圈與 `counter` 的用法，理解「分批處理」概念。  
4. 最後讀 `Control.st`，確認插補器與兩軸是如何銜接 `Path.poqDataOut`。  
5. 實務上可調整 `counter` 與 GVL 內的公差參數，以在「CPU 負載」「記憶體用量」「路徑品質」之間取得平衡。

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">Large G-code</span> | 指行數多、路徑長、無法一口氣完整載入的 G-code 程式。 |
| <span class="cfg-func">SMC_SmoothMerge</span> | 用於段與段幾何接續的平滑前處理。 |
| <span class="cfg-name">Streaming</span> | 此處指以「分批處理、邊讀邊前處理」方式逐步建構路徑的策略。 |

