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

# Robotics_Triggers_Advanced — 整體架構與功能說明

---

## 一、這個專案在做什麼？（一句話＋情境）

這個進階範例建立在基本 Triggers 範例之上，模擬一個二軸點膠工作站：  
軸組沿著多段路徑移動，搭配多個觸發點與時間位移，精準地控制「膠閥開關、UV 燈開關與膠料補充」的時機。

從學習角度來看，這個專案示範：

- 如何在 **多段運動路徑** 上放置多個觸發點。
- 如何使用 <span class="cfg-custom">TriggerWithTimeShift()</span> 在同一條路徑上同時處理「提前開啟」與「延遲關閉」等行為。
- 如何根據實體設備的延遲時間（膠閥、UV 燈）來設計觸發的 TimeShift 與規劃器的預測時間。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務與程式對應（對照 `TaskConfiguration.md`）

| 任務名稱 | 類型 | 週期 | 優先權 | 執行的 POU |
|----------|------|------|--------|------------|
| MainTask | Cyclic | t#GVL.BUS_CYCLE_TIME_IN_US | 1 | `GlueApplication` |
| SoftMotion_PlanningTask | Freewheeling | t#2ms | 15 | `Planning_PRG` |

- `GVL.BUS_CYCLE_TIME_IN_US` 設為 4000 µs，對應 MainTask 4 ms 週期。  
- `Planning_PRG` 依照 `GVL.MAX_TRIGGER_FORECAST_DURATION` 來設定預測時間。

### 2.2 軸與裝置結構（對照 `DeviceTree_Axes.md`）

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| X | SM_Drive_Virtual | - |
| Y | SM_Drive_Virtual | - |

這兩個虛擬軸構成二維平面工作區，所有點膠路徑都在這個平面內執行。  
在程式中，它們被包裝成一個軸組 `AxisGroup`，由 `GlueApplication` 透過多個 <span class="cfg-func">MC_MoveLinearAbsolute()</span> 實例來控制。

### 2.3 Trace 與觀察點（對照 `TraceConfig.md`）

| 變數名 | 說明 |
|--------|------|
| `X.fSetPosition`, `Y.fSetPosition` | 指令位置，方便觀察路徑形狀 |
| `X.fSetVelocity`, `Y.fSetVelocity` | 指令速度 |
| `X.fSetAcceleration`, `Y.fSetAcceleration` | 指令加速度 |
| `GlueApplication.EnableGlue` | 膠閥啟用訊號 |
| `GlueApplication.EnableUVLamp` | UV 燈啟用訊號 |
| `GlueApplication.RefillGlueStorage` | 補充膠料訊號 |

透過這些 Trace，可以清楚看到「路徑位置」、「觸發時機」與「工具開關」之間的關係。

---

## 三、控制流程：由淺入深

### 3.1 整體流程概觀

1. `Planning_PRG` 在規劃任務中呼叫 <span class="cfg-func">SMC_TuneCPKernel()</span>，將預測時間設為 `GVL.MAX_TRIGGER_FORECAST_DURATION`。  
2. `GlueApplication` 在 `STATE_INIT` 等待 `Planning_PRG.initDone` 後，初始化所有運動 FB 並進入上電階段。  
3. 上電並啟用軸組後，依序執行五段線性運動，每一段搭配不同觸發配置：  
   - 第一段：在相對位置 0.5 處開啟膠閥與 UV 燈。  
   - 第二段：純運動，無觸發。  
   - 第三段：在移動距離 5 的位置觸發補充膠料。  
   - 第四段：純運動，無觸發。  
   - 第五段：當軸組通過某平面位置時關閉膠閥與 UV 燈（含 TimeShift）。  
4. 在 `STATE_MONITOR_MOVEMENTS_AND_TRIGGERS` 中，持續呼叫 `CallTriggers()` 與 `EvaluateTriggers()`，直到最後一段運動完成且所有輸出訊號皆為 FALSE，流程結束。

### 3.2 `GlueApplication` 狀態機（對照 `GlueApplication.st`）

`GlueApplication` 使用 <span class="cfg-local">m_state</span> 將流程分成多個階段：

- **STATE_INIT**：  
  等待 `Planning_PRG.initDone = TRUE`，並呼叫 <span class="cfg-custom">InitializeMovementPOUs()</span> 設定 `m_moveLinearAbsolutes` 的目標位置（使用 `GLUE_POSITIONS` 陣列）。

- **STATE_POWER_AND_ENABLE**：  
  - 透過 <span class="cfg-func">SMC_GroupPower()</span>（<span class="cfg-local">m_groupPower</span>）上電軸組。  
  - 透過 <span class="cfg-func">MC_GroupEnable()</span>（<span class="cfg-local">m_groupEnable</span>）啟用軸組。  
  - 完成後切換到第一段運動。

- **STATE_COMMAND_FIRST_MOVEMENT_WITH_TRIGGERS**：  
  - 設定 `m_enableGlueTrigger` 為相對位置 0.5，TimeShift 為 <span class="cfg-const">GLUE_ON_OFF_DELAY</span>（0.05s），表示在真正到達點位前 0.05 秒就開膠。  
  - 設定 `m_enableUVLampTrigger` 為相對位置 0.5，TimeShift 為 0（直接使用觸發點）。  
  - 當兩個觸發都準備完成後，啟動第一段運動 `m_moveLinearAbsolutes[0]`。

- **STATE_COMMAND_SECOND_MOVEMENT**：  
  - 直接啟動第二段運動 `m_moveLinearAbsolutes[1]`，不掛觸發。

- **STATE_COMMAND_THIRD_MOVEMENT_WITH_TRIGGERS**：  
  - 設定 `m_refillGlueStorageTrigger` PositionType 為 <span class="cfg-name">MvtDistance</span>，距離為 5。  
  - 當觸發準備完成後啟動第三段運動 `m_moveLinearAbsolutes[2]`。  
  - 後續在 `EvaluateTriggers()` 中會把 `RefillGlueStorage` 設為 TRUE。

- **STATE_COMMAND_FOURTH_MOVEMENT**：  
  - 直接執行第四段運動，讓路徑形成一個完整圖形。

- **STATE_COMMAND_FIFTH_MOVEMENT_WITH_TRIGGERS**：  
  - 設定 `m_disableGlueTrigger`、`m_disableUVLampTrigger` 的 PositionType 為 <span class="cfg-name">PlaneIntersection</span>，在某一平面位置觸發。  
  - `m_disableGlueTrigger.TimeShift := GLUE_ON_OFF_DELAY`，`m_disableUVLampTrigger.TimeShift := UV_LAMP_OFF_DELAY`（-1.5 秒，代表在通過後某段時間才關掉 UV 燈）。  
  - 當兩個觸發都準備好後啟動第五段運動。

- **STATE_MONITOR_MOVEMENTS_AND_TRIGGERS**：  
  - 反覆呼叫 `CallTriggers()` 與 `EvaluateTriggers()`，讓觸發邏輯更新 `EnableGlue`、`EnableUVLamp`、`RefillGlueStorage`。  
  - 當最後一段運動 Done，且三個輸出皆為 FALSE，切換到 **STATE_DONE**。

### 3.3 `TriggerWithTimeShift` 的內部邏輯（對照 `TriggerWithTimeShift.st`）

`TriggerWithTimeShift` 將觸發流程分為幾個主要狀態：

- **STATE_PREPARE_TRIGGER**：呼叫 <span class="cfg-func">SMC_GroupPrepareTrigger()</span> 準備觸發並取得 TriggerId。  
- **STATE_MONITOR_TRIGGER**：呼叫 <span class="cfg-func">SMC_GroupReadTrigger()</span>，讀取 `TriggerInfo.triggerTime`；  
  - 若加上 TimeShift 後的 `TriggerTime <= GVL.BUS_CYCLE_TIME_IN_S`，代表本週期內會達到觸發點，進入 `STATE_TRIGGER_FIRED`。  
  - 若未達到，且「原始 triggerTime」小於一個週期，則進入 `STATE_DECREMENT_REMAINING_TRIGGER_TIME`，開始以週期遞減 TimeShift 後的剩餘時間。
- **STATE_DECREMENT_REMAINING_TRIGGER_TIME**：每個週期將 `TriggerTime` 減去 `GVL.BUS_CYCLE_TIME_IN_S`，直到小於等於一個週期時觸發。  
- **STATE_TRIGGER_FIRED**：將 `TriggerTime := 0` 並切換到 `STATE_DONE`。  
- **STATE_ABORTED / STATE_ERROR**：處理運動被中止或觸發錯誤的情況。

輸出旗標 `Busy`、`TriggerPrepared`、`TriggerTimeValid`、`TriggerReachedThisCycle`、`Aborted`、`Done`、`Error` 等，可以幫助使用者在上層程式中做出對應反應。

---

## 四、各支程式負責哪些功能？（由淺入深）

### 4.1 `GVL.st` — 時序與預測參數

- **類型**：<span class="cfg-keyword">VAR_GLOBAL CONSTANT</span>。  
- **職責**：集中定義匯流排週期時間 `BUS_CYCLE_TIME_IN_US`、以秒為單位的 `BUS_CYCLE_TIME_IN_S`，以及 `MAX_TRIGGER_FORECAST_DURATION`。  
- **與整體關係**：  
  - `TriggerWithTimeShift` 依賴 `BUS_CYCLE_TIME_IN_S` 來遞減 TriggerTime。  
  - `Planning_PRG` 依賴 `MAX_TRIGGER_FORECAST_DURATION` 來設定規劃器的預測窗口。

### 4.2 `GlueApplication.st` — 點膠與 UV 燈流程主程式

- **類型**：<span class="cfg-keyword">PROGRAM</span>。  
- **職責**：實作一個完整的點膠路徑與工具控制流程，將軸運動與觸發邏輯組合起來。  
- **輸出**：  
  - <span class="cfg-local">EnableGlue</span>：膠閥啟用信號。  
  - <span class="cfg-local">EnableUVLamp</span>：UV 燈啟用信號。  
  - <span class="cfg-local">RefillGlueStorage</span>：提示補充膠料的信號。

### 4.3 `Planning_PRG.st` — 規劃器設定

- **類型**：<span class="cfg-keyword">PROGRAM</span>。  
- **職責**：根據 `GVL.MAX_TRIGGER_FORECAST_DURATION` 呼叫 <span class="cfg-func">SMC_TuneCPKernel()</span>，並輸出 `initDone`。  
- **與整體關係**：  
  - 控制整個專案的「預測時間」設定，必須在主程式開始點膠前完成。

### 4.4 `TriggerWithTimeShift.st` — 觸發封裝 FB

- **類型**：<span class="cfg-keyword">FUNCTION_BLOCK</span>。  
- **職責**：封裝觸發準備與時間位移的邏輯，支援多種 PositionType（相對位置、距離、平面交會）。  
- **輸出**：可被 `GlueApplication` 重複使用於膠閥啟用、膠閥關閉、UV 燈關閉、膠料補充等多種情境。

---

## 五、函式庫與函式／功能塊一覽（用途、引數、回傳）

### 5.1 函式庫（對照 `Libraries.md`）

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | SoftMotion 基礎運動控制與觸發功能塊 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 支援路徑／凸輪建構與可視化，間接用於路徑呈現 |

### 5.2 主要功能塊與函數（補充）

- <span class="cfg-custom">TriggerWithTimeShift()</span>  
  - 封裝 <span class="cfg-func">SMC_GroupPrepareTrigger()</span> 與 <span class="cfg-func">SMC_GroupReadTrigger()</span> 的使用方式，並加入 TimeShift 與多種 PositionType 支援。  
  - 典型用法：在 `GlueApplication` 中重複建立多個實例（開膠、關膠、補充膠、關 UV 燈等）。

- 其他 SoftMotion FB（與基本 Triggers 範例類似）：  
  - <span class="cfg-func">SMC_GroupPower()</span>、<span class="cfg-func">MC_GroupEnable()</span>、<span class="cfg-func">MC_MoveLinearAbsolute()</span> 等，此處不再重複。

---

## 六、變數與常數一覽

本範例未使用 RETAIN／PERSISTENT。

### 6.1 全域常數（對照 `GVL.st`）

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| <span class="cfg-const">BUS_CYCLE_TIME_IN_US</span> | <span class="cfg-type">DWORD</span> | 4000 | 匯流排週期，提供轉換為秒與 Trigger 計算基準 |
| <span class="cfg-const">BUS_CYCLE_TIME_IN_S</span> | <span class="cfg-type">LREAL</span> | 0.004 | 上述週期換算成秒 |
| <span class="cfg-const">MAX_TRIGGER_FORECAST_DURATION</span> | <span class="cfg-type">LREAL</span> | 取 GLUE_ON_OFF_DELAY / UV_LAMP_OFF_DELAY 較大值 | 規劃器預測時間上限 |

### 6.2 `GlueApplication` 中的常數（節錄）

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| <span class="cfg-const">MOVEMENT_COUNT</span> | <span class="cfg-type">UINT</span> | 5 | 運動段數 |
| <span class="cfg-const">GLUE_ON_OFF_DELAY</span> | <span class="cfg-type">LREAL</span> | 0.05 | 膠閥開關相對於觸發點的提前／延後時間 |
| <span class="cfg-const">UV_LAMP_OFF_DELAY</span> | <span class="cfg-type">LREAL</span> | -1.5 | UV 燈關閉時間，為負代表通過觸發點後延遲關閉 |
| <span class="cfg-const">GLUE_POSITIONS</span> | <span class="cfg-type">ARRAY[..] OF SMC_POS_REF</span> | 如程式所列 | 構成點膠路徑的五個節點座標 |

---

## 七、特別的演算法與觀念

### 7.1 TimeShift 正負值的意義

- 正的 TimeShift（例如 `GLUE_ON_OFF_DELAY = 0.05`）：  
  - 代表要在真正經過觸發點之前就啟動設備（提早 0.05 秒開膠或提前關膠）。  
  - 若運動太快，可能出現「來不及提前」的情況，`TriggerTime` 會變成負值或非常接近零。

- 負的 TimeShift（例如 `UV_LAMP_OFF_DELAY = -1.5`）：  
  - 代表要在通過觸發點之後一段時間才關閉設備。  
  - 常見於需要「照射餘量」的應用，如 UV 固化燈。

### 7.2 多觸發、多段運動的設計方式

本範例示範了一種實務常見模式：

- 對一條複雜路徑拆成多段 `MC_MoveLinearAbsolute()` 調用。  
- 針對每一段需求，建立一個或多個 <span class="cfg-custom">TriggerWithTimeShift()</span> 實例。  
- 在狀態機中明確區分「指令運動」與「監控觸發」，讓邏輯清晰、易於擴充。

---

## 八、建議閱讀與修改順序

1. **閱讀本說明**：先對整體架構與應用情境有概念。  
2. **打開 `GVL.st`**：理解匯流排週期與 `MAX_TRIGGER_FORECAST_DURATION` 如何設定。  
3. **閱讀 `Planning_PRG.st`**：確認規劃器如何套用這些時間參數。  
4. **深入 `TriggerWithTimeShift.st`**：看懂 TimeShift 與 TriggerTime 的演算法流程。  
5. **閱讀 `GlueApplication.st`**：  
   - 先看狀態機 m_state 的大致流程；  
   - 再回頭對照各 TriggerWithTimeShift 實例與 `GLUE_POSITIONS` 之間的關係。  
6. **最後觀察 Trace**：在示波器中同時看位置、速度與三個輸出訊號，體會觸發設計是否符合預期。

修改時，建議先從 `GLUE_POSITIONS` 或 `GLUE_ON_OFF_DELAY`／`UV_LAMP_OFF_DELAY` 這類參數著手，再調整狀態機邏輯與觸發條件。

---

## 九、名詞對照

| 英文／符號 | 說明 |
|-----------|------|
| <span class="cfg-name">Trigger</span> | 觸發點，軌跡上某個特定位置，用來驅動邏輯事件 |
| <span class="cfg-name">TimeShift</span> | 觸發時間位移，正值代表提早、負值代表延後 |
| <span class="cfg-name">PlaneIntersection</span> | 平面交會型觸發位置，適合用於「通過某條線」時觸發 |
| <span class="cfg-name">MvtRelative</span> | 以 0.0～1.0 表示整段運動中相對位置的觸發型態 |
| <span class="cfg-name">MvtDistance</span> | 以實際距離（例如 5 單位）表示觸發點 |

---
