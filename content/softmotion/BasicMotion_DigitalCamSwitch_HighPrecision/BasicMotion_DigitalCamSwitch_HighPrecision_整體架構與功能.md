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

# BasicMotion_DigitalCamSwitch_HighPrecision — 教材式範例說明

本文件以**講師整理教材**的角度撰寫，引導初學者**系統性理解**本專案：從使用情境與硬體通訊出發，再進入控制流程與各程式職責，最後說明函式庫、變數與關鍵演算法。建議按章節順序閱讀。

---

## 一、這個專案在做什麼？（一句話＋情境）

- **一句話**：本範例示範如何用 **Soft Motion 的數位凸輪（Digital Cam Switch）**，在**虛擬軸運動過程中**，於**精確時間點**觸發 **Beckhoff 具時間戳的數位輸出卡**（EL2252 / EL2258），實現「位置／時間 → 數位輸出」的高精度同步。
- **使用情境**：  
  - 需要**依軸位置或運動時間**在固定時間點打開／關閉數位輸出（例如：到某角度亮燈、某段距離後觸發閥門、包裝機切刀與輸送帶同步等）。  
  - 輸出時機要求**高於一般 PLC 掃描週期**，故使用**硬體時間戳**（EL2252 / EL2258）由 EtherCAT 在指定時間點驅動輸出，而非僅在程式掃描到時才給 ON/OFF。

---

## 二、使用情境與硬體／通訊架構

### 2.1 為什麼需要「高精度」數位輸出？

一般 PLC 程式是**週期掃描**：每 1～10 ms 執行一次，輸出在掃描到邏輯時才改變。若要在「軸走到某個位置」或「某個精確時間點」觸發輸出，誤差常達數個掃描週期。  
本範例的做法是：  
- 用 **SMC 凸輪** 算出「下一個要觸發的事件」的**時間點**（Duration：再過多久觸發）。  
- 把這個時間轉成 **EtherCAT 的 DC 時間戳**，寫入 **EL2252 / EL2258**。  
- 由**硬體**在該時間點驅動輸出，與 PLC 掃描解耦，達成高精度。

### 2.2 硬體與通訊架構（初學者對應到裝置樹）

| 項目 | 說明 | 在本專案中的對應 |
|------|------|-------------------|
| **PLC / 執行環境** | CODESYS Control（如 Control Win V3） | 執行 Main 與凸輪、輸出 FB |
| **通訊** | **EtherCAT** | EtherCAT_Master_SoftMotion |
| **軸** | 本範例為**虛擬軸**，只提供「位置＋週期」給凸輪計算 | **Drive**（SM_Drive_Virtual），在 SoftMotion General Axis Pool 下 |
| **數位輸出卡** | 具 **DC Time Stamp / Multi-Time-Stamp** 的模組 | **EL2252**（2Ch）、**EL2258**（8Ch），掛在 EtherCAT 下 |
| **任務** | 凸輪與輸出 FB 需在固定週期執行 | **EtherCAT_Task**，週期 **t#4ms**，執行 **Main** |

初學者可以對照 **DeviceTree_Axes.md** 與 **TaskConfiguration.md**：  
- 只有一個軸 **Drive**（虛擬軸）。  
- 只有一個週期任務 **EtherCAT_Task (t#4ms)**，呼叫 **Main**。

### 2.3 資料流（誰給誰、誰控制誰）

```
虛擬軸 Drive（速度運動）
    ↓ 位置、週期
SMC_SetForecast → 預測軸週期（fTaskCycle）→ taskInterval_s
SMC_DigitalCamSwitch_HighPrecision（dcs）→ 依 Switches / Tracks 算出 Events（何時、哪一軌、ON/OFF）
    ↓ dcs.Events、taskInterval_s、Axis、ETCMaster
DigitalCamSwitch_EL2252 / DigitalCamSwitch_EL2258 → 把事件寫入 EL2252 / EL2258 的 PDO
    ↓ EtherCAT PDO 映射
EL2252 / EL2258 硬體 → 在指定時間戳驅動數位輸出
```

---

## 三、控制流程：由淺入深

### 3.1 整體流程（高層）

1. **上電與匯流排**：軸上電（MC_Power）→ 等 EtherCAT 匯流排 RUNNING。  
2. **啟動運動與凸輪**：虛擬軸以固定速度運動（MC_MoveVelocity），同時啟用 **SMC_DigitalCamSwitch_HighPrecision**（dcs）與兩張輸出卡的 FB（dcs_el2252、dcs_el2258）。  
3. **每週期**：  
   - 呼叫 **setForecast**、**pw**、**mv**、**dcs**，更新軸與凸輪狀態並產生 **Events**。  
   - 呼叫 **dcs_el2252**、**dcs_el2258**，把 **dcs.Events** 與 **taskInterval_s** 轉成硬體時間戳並寫入 PDO，由硬體在正確時間點輸出。

### 3.2 Main 的狀態機（入門必看）

Main 的狀態機在 **Main.st** 中，用 `state` 控制「何時才開始跑凸輪與輸出」：

| 狀態 | 意義 | 做了什麼 |
|------|------|----------|
| **0** | 取得軸週期預測 | `setForecast.Execute := TRUE`，等 `setForecast.Done` 後到 10 |
| **10** | 軸上電 | `pw.Enable`、`pw.bRegulatorOn`、`pw.bDriveStart`，等 `pw.Status` 後到 20 |
| **20** | 等 EtherCAT 就緒 | `EtherCAT_Master_SoftMotion.GetBusState() = RUNNING` 後到 30 |
| **30** | 正式運行 | `mv.Execute`、`dcs.Enable`、`dcs_el2258.Enable`、`dcs_el2252.Enable`；之後每週期都呼叫 pw、mv、setForecast、dcs、dcs_el2252、dcs_el2258 |

**重點**：狀態 30 之後，**每週期**都會執行底下的 `pw(...)`、`mv(...)`、`setForecast(...)`、`dcs(...)`、`dcs_el2258(...)`、`dcs_el2252(...)`，不再依狀態分支；狀態機只負責「何時開放」這些功能。

### 3.3 凸輪與輸出的關係（進階）

- **dcs**（SMC_DigitalCamSwitch_HighPrecision）：  
  輸入為軸 **Drive**、**Switches**（哪些軌道、在哪些位置 ON/OFF）、**TrackOptions**（補償等）。  
  輸出為 **dcs.Events**：每個軌道（Track）有一串「切換事件」，每個事件包含**還有多久觸發**（Duration）、**新值**（NewValue）、**ToggleEventId** 等。
- **dcs_el2252 / dcs_el2258**：  
  輸入為 **dcs.Events**、**Axis**、**ETCMaster**、**taskInterval_s**。  
  負責：  
  - 從 Events 裡挑出「下一個要觸發」的事件；  
  - 把 **Duration** 轉成 EtherCAT 時間戳；  
  - 寫入 EL2252 / EL2258 的 PDO（**Out**、**ChannelsOut** 等），由硬體在該時間點驅動輸出。

---

## 四、各支程式負責哪些功能？（由淺入深）

### 4.1 Main.st（主程式）

- **類型**：PROGRAM。  
- **職責**：  
  - 狀態機 0→10→20→30：依序完成「軸預測 → 軸上電 → EtherCAT 就緒 → 啟用凸輪與兩張輸出卡」。  
  - 定義**區域變數**：`pw`（MC_Power）、`mv`（MC_MoveVelocity）、`aSwitches` / `switches`（凸輪開關定義）、`tracks`（軌道選項）、`setForecast`、`dcs`、`dcs_el2252`、`dcs_el2258`、`state`。  
  - 從狀態 30 起，每週期呼叫上述 FB，並把 **Drive**、**dcs.Events**、**Drive.fTaskCycle**（給 taskInterval_s）傳給輸出 FB。  
- **與硬體／通訊**：透過 **EtherCAT_Master_SoftMotion** 檢查匯流排狀態；透過 **dcs_el2252**、**dcs_el2258** 間接寫入 EL2252 / EL2258 的 PDO。

### 4.2 DigitalCamSwitch_EL2252.st（2Ch 輸出卡對應 FB）

- **類型**：FUNCTION_BLOCK。  
- **職責**：  
  - 接收 **dcs.Events**（每軌一組事件）、**Axis**、**ETCMaster**、**taskInterval_s**。  
  - **STATE_INIT**：清除 missed 計數、對每軌呼叫 **EventId_Init**，避免重複處理同一事件。  
  - **STATE_CHECK_FOR_EVENT**：  
    - 對每個 channel（軌道）找出「下一個尚未處理且時間足夠」的事件（用 **EventId_GreaterThan**、**IsValidDuration**）；  
    - 在多軌中取 **Duration 最小**的那一個（即「最先觸發」）；  
    - 把該事件的 **Duration** 轉成 64 位元 EtherCAT 時間戳（**DurationTo64bitEtcTimestamp**），寫入 **Out**（activate、startTime、channels[channel].output）；  
    - 更新 **aLastEventIds[channel]**（**EventId_Set**），避免下次再處理同一事件。  
  - **STATE_ACTIVATE_EVENT_IN_EL2252**：把 **Out.activate** 設為 EL2252_ACTIVATE_EVENT，觸發硬體執行。  
  - **STATE_WAIT_UNTIL_THE_INPUTS_MATCH_THE_OUTPUTS**：等硬體回饋 **In** 與 **Out** 一致後，回到 STATE_CHECK_FOR_EVENT，處理下一個事件。  
- **輸出**：**Out**（映射到 EL2252 PDO）、**missedCounter**（因時間太短而無法寫入的事件數）。

### 4.3 DigitalCamSwitch_EL2258.st（8Ch 輸出卡對應 FB）

- **類型**：FUNCTION_BLOCK。  
- **職責**：  
  - 與 EL2252 版概念相同，但 EL2258 支援**一次寫入多筆事件**（Multi-Time-Stamp）。  
  - **STATE_INIT_0**：清除 missed、對每 channel 做 **OutputBufferReset**、**EventId_Init**。  
  - **STATE_INIT_1**：關閉 OutputBufferReset。  
  - **STATE_ACTIVE**：  
    - 當 **ChannelsIn[channel].OutputOrderFeedback = ChannelsOut[channel].OutputOrderCounter** 表示上一批已由硬體處理完；  
    - 對該 channel 最多取 **5 筆**「尚未處理且 Id 較大」的事件，用 **DurationTo32bitEtcTimestamp** 轉成時間戳，寫入 **ChannelsOut[channel].OutputEventTime / OutputEventState**；  
    - 若 **Duration < MIN_CYCLES * taskInterval_s** 則視為來不及寫入，**missedCounter** 加一；  
    - **OutputOrderCounter** 加一，觸發硬體排程。  
- **與 EL2252 的差異**：EL2258 用 32 位元時間戳與批次寫入多事件；EL2252 用 64 位元時間戳、一次一筆並用 In/Out 回饋比對。

### 4.4 GVL_EL2252.st（全域常數）

- **類型**：VAR_GLOBAL CONSTANT。  
- **內容**：**NUM_CHANNELS := 2**（EL2252 為 2 軌／2Ch）。  
- **用途**：給 **DigitalCamSwitch_EL2252** 的迴圈與陣列範圍使用，方便日後若換成同型多通道卡時只改一處。

---

## 五、函式庫與函式／功能塊一覽（用途、引數、回傳）

以下依**函式／功能塊**列出，每項只寫一次；多處使用時可對照名稱查閱。格式：**用途** → 引數（名稱、方向、型態）→ 回傳型態。

### 5.1 本專案自訂函式（FUNCTION）

| 函式名稱 | 用途 | 引數 | 回傳 |
|----------|------|------|------|
| **EventId_Init** | 將 EventId 結構清為「未設定」，避免重複處理舊事件。 | IN_OUT `lte` : **EventId** | （無） |
| **EventId_Set** | 記錄該軌道已處理到的 ToggleEventId（寫入 `lte.id` 並設 `lte.valid := TRUE`）。 | IN_OUT `lte` : **EventId**；INPUT `id` : **UDINT** | （無） |
| **EventId_GreaterThan** | 判斷 `id1` 是否「新於」`id2`（含 32 位元溢位處理）。若 `id2.valid = FALSE` 視為 id1 較新。 | INPUT `id1` : **UDINT**；IN_OUT CONSTANT `id2` : **EventId** | **BOOL** |
| **DurationTo64bitEtcTimestamp** | 將「再過多久觸發」（秒）轉成 EtherCAT 64 位元時間戳（奈秒），供 EL2252 使用。 | IN_OUT `Axis` : **AXIS_REF_SM3**、`ETCMaster` : **IODrvEtherCAT**；INPUT `duration` : **LREAL** | **ULINT** |
| **DurationTo32bitEtcTimestamp** | 將「再過多久觸發」（秒）轉成 EtherCAT 32 位元時間戳（取 64bit 低 32 位），供 EL2258 使用。 | IN_OUT `Axis` : **AXIS_REF_SM3**、`ETCMaster` : **IODrvEtherCAT**；INPUT `duration` : **LREAL** | **UDINT** |
| **LogEvent** | 將事件資訊（軌道、開關號、Id、新值、時間戳、是否漏事件）寫入日誌（除錯／診斷）。 | INPUT `prefix` : **STRING**，`track` : **UDINT**，`event` : **SMC_CAMSWITCH_TOGGLE_EVENT**，`etcTimestamp` : **ULINT**，`missed` : **BOOL** | （無） |

### 5.2 DigitalCamSwitch_EL2252 內建方法（METHOD）

| 方法名稱 | 用途 | 引數 | 回傳 |
|----------|------|------|------|
| **IsValidDuration** | 判斷「剩餘時間（秒）」是否 ≥ MIN_CYCLES × taskInterval_s，足以讓硬體排程該事件。 | 依呼叫：傳入 **Duration**（LREAL，來自事件） | **BOOL** |
| **OnMissedEvent** | 漏事件回呼：當事件因時間太短無法寫入時呼叫（可紀錄或告警）。 | 依呼叫：`Axis`、`ETCMaster`、`channel`（UDINT）、`event`（SMC_CAMSWITCH_TOGGLE_EVENT） | （無） |
| **OnExit** | 每次 FB 執行結束時呼叫（可做收尾或診斷）。 | （無） | （無） |
| **IsBusy** | 回傳 FB 是否正在處理中（例如在 STATE_ACTIVATE_EVENT_IN_EL2252 或 STATE_WAIT_UNTIL_THE_INPUTS_MATCH_THE_OUTPUTS）。 | （無） | **BOOL** |

### 5.3 庫提供之功能塊（本範例使用到的介面摘要）

| 功能塊／介面 | 用途 | 本範例使用之主要輸入／輸出 |
|--------------|------|-----------------------------|
| **MC_Power** | 軸上電。 | Axis；Enable、bRegulatorOn、bDriveStart → Status |
| **MC_MoveVelocity** | 軸速度運動。 | Axis；Velocity、Acceleration、Deceleration、Jerk；Execute → Done / Busy |
| **SMC_SetForecast** | 預測軸週期等，提供 fTaskCycle 給凸輪與輸出 FB。 | Axis；ForecastDuration；Execute → Done |
| **SMC_DigitalCamSwitch_HighPrecision** | 依凸輪開關與軌道設定算出 Events（何時、哪一軌、ON/OFF）。 | Axis、Switches、TrackOptions；Enable → Events |
| **DigitalCamSwitch_EL2252** | 將 dcs.Events 轉成 EL2252 PDO 並寫入硬體。 | Events、Axis、ETCMaster、Enable、taskInterval_s、In → Out、missedCounter |
| **DigitalCamSwitch_EL2258** | 將 dcs.Events 轉成 EL2258 PDO 並寫入硬體（支援多筆事件）。 | Events、Axis、ETCMaster、Enable、taskInterval_s → ChannelsOut、ChannelsIn、missedCounter |
| **EtherCAT_Master_SoftMotion.GetBusState()** | 取得 EtherCAT 匯流排狀態（如 RUNNING）。 | （無） → 回傳列舉（如 DED.BUS_STATE.RUNNING） |

### 5.4 函式庫來源與庫參數（對照 Libraries.md）

- **#SM3_Basic**：SMC_SetForecast、SMC_DigitalCamSwitch_HighPrecision、凸輪相關型別；庫參數如 **GC_SMC_DIGITAL_CAM_SWITCH_MAX_SWITCHES**、**GC_SMC_DIGITAL_CAM_SWITCH_NUM_TRACKS**、**GC_SMC_FILE_MAXCAMEL** 等。
- **#SM3_Basic_Visu**：MAX_CAM_POINTS 等視覺化參數。
- **#SM3_CamBuilder**：MAX_CAM_SEGMENT_COUNT。
- 標準運動庫：MC_Power、MC_MoveVelocity。

---

## 六、變數與常數一覽

本範例未使用 RETAIN 或 PERSISTENT，所有變數斷電後皆不保留。

### 6.1 全域常數（GVL_EL2252）

| 名稱 | 型態 | 預設值 | 斷電記憶 | 說明 |
|------|------|--------|----------|------|
| `NUM_CHANNELS` | UDINT | 2 | 不適用（常數） | EL2252 通道數，供迴圈與陣列範圍使用。 |

### 6.2 Main 區域變數（VAR）

| 名稱 | 型態 | 預設值 | 斷電記憶 | 說明 |
|------|------|--------|----------|------|
| `pw` | MC_Power | （FB 預設） | 否 | 軸上電功能塊實例。 |
| `mv` | MC_MoveVelocity | Velocity:=180, Acceleration:=3600, Deceleration:=3600, Jerk:=36000 | 否 | 軸速度運動功能塊實例。 |
| `aSwitches` | ARRAY[0..7] OF MC_CAMSWITCH_TR | 見程式（4 組開關） | 否 | 凸輪開關定義（軌號、FirstOnPosition、LastOnPosition、AxisDirection、CamSwitchMode）。 |
| `switches` | MC_CAMSWITCH_REF | NoOfSwitches:=4, CamSwitchPtr:=ADR(aSwitches) | 否 | 凸輪開關參考，指向 aSwitches。 |
| `tracks` | MC_TRACK_REF | 兩軌 OnCompensation / OffCompensation | 否 | 軌道選項。 |
| `setForecast` | SMC_SetForecast | ForecastDuration:=0.15 | 否 | 軸週期預測功能塊實例。 |
| `dcs` | SMC_DigitalCamSwitch_HighPrecision | （FB 預設） | 否 | 數位凸輪核心 FB 實例。 |
| `dcs_el2252` | DigitalCamSwitch_EL2252 | （FB 預設） | 否 | EL2252 輸出 FB 實例。 |
| `dcs_el2258` | DigitalCamSwitch_EL2258 | （FB 預設） | 否 | EL2258 輸出 FB 實例。 |
| `state` | UDINT | 0（未寫則為 0） | 否 | Main 狀態機（0/10/20/30）。 |

### 6.3 DigitalCamSwitch_EL2252 內部變數與常數

**VAR（實例變數）**

| 名稱 | 型態 | 預設值 | 斷電記憶 | 說明 |
|------|------|--------|----------|------|
| `state` | UDINT | 0 | 否 | FB 狀態機。 |
| `EnableOld` | BOOL | FALSE | 否 | 上一週期 Enable，用於邊緣偵測。 |
| `aLastEventIds` | ARRAY[1..GVL_EL2252.NUM_CHANNELS] OF EventId | （依 EventId） | 否 | 每軌已處理到的 ToggleEventId。 |

**VAR_TEMP（暫存變數，每週期重算）**

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| `channel` | UDINT | — | 迴圈用軌道索引。 |
| `nextEvents` | ARRAY[1..GVL_EL2252.NUM_CHANNELS] OF EL2252_Event | — | 每軌下一個候選事件。 |
| `eventIdx` | UDINT | — | 事件索引。 |
| `id` | UDINT | — | 當前事件 ToggleEventId。 |
| `lowestDuration` | LREAL | FPU.GetLRealSpecialVal(PosInf) | 多軌中「最先觸發」的 Duration。 |
| `doInputsMatchOutputs` | BOOL | — | In 與 Out 是否一致。 |

**VAR CONSTANT（常數）**

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| `EL2252_ACTIVATE_PREPARE` | USINT | 0 | 硬體「準備」階段。 |
| `EL2252_ACTIVATE_EVENT` | USINT | 3 | 硬體「執行事件」階段。 |
| `MIN_CYCLES` | UDINT | 4 | 至少需幾週期才允許寫入事件。 |
| `STATE_IDLE` | UDINT | 0 | 狀態：閒置。 |
| `STATE_INIT` | UDINT | 10 | 狀態：初始化。 |
| `STATE_CHECK_FOR_EVENT` | UDINT | 20 | 狀態：檢查下一個事件。 |
| `STATE_ACTIVATE_EVENT_IN_EL2252` | UDINT | 30 | 狀態：觸發硬體寫入。 |
| `STATE_WAIT_UNTIL_THE_INPUTS_MATCH_THE_OUTPUTS` | UDINT | 40 | 狀態：等 In/Out 一致。 |
| `STATE_ERROR` | UDINT | 1000 | 狀態：錯誤。 |

### 6.4 DigitalCamSwitch_EL2258 內部變數與常數

**VAR**

| 名稱 | 型態 | 預設值 | 斷電記憶 | 說明 |
|------|------|--------|----------|------|
| `state` | UDINT | 0 | 否 | FB 狀態機。 |
| `EnableOld` | BOOL | FALSE | 否 | 上一週期 Enable。 |
| `aLastEventIds` | ARRAY[1..NUM_CHANNELS] OF EventId | （依 EventId） | 否 | 每軌已處理到的 ToggleEventId。 |

**VAR_TEMP**

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| `channel` | UDINT | — | 軌道索引。 |
| `id` | UDINT | — | 事件 ToggleEventId。 |
| `i` | UDINT | — | 事件迴圈索引。 |
| `event` | POINTER TO SMC_CAMSWITCH_TOGGLE_EVENT | — | 當前事件指標。 |
| `etcTimestamp` | UDINT | — | 32 位元 EtherCAT 時間戳。 |
| `nEvents` | UDINT | — | 本批寫入的事件數。 |
| `missed` | BOOL | — | 本筆是否因時間不足而漏掉。 |

**VAR CONSTANT**

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| `NUM_CHANNELS` | UDINT | 2 | 本 FB 使用之通道數。 |
| `MIN_CYCLES` | UDINT | 6 | 至少需幾週期才允許寫入。 |
| `STATE_IDLE` | UDINT | 0 | 閒置。 |
| `STATE_INIT_0` | UDINT | 10 | 初始化階段 0。 |
| `STATE_INIT_1` | UDINT | 20 | 初始化階段 1。 |
| `STATE_ACTIVE` | UDINT | 30 | 運行中。 |
| `STATE_ERROR` | UDINT | 1000 | 錯誤。 |

---

## 七、特別的演算法與觀念

### 7.1 EventId 與「避免重複處理」

凸輪每週期會產出一串 **Events**，硬體可能尚未執行完上一筆，程式又掃描到同一筆。  
做法：  
- 用變數 `aLastEventIds[channel]` 記錄「該軌道已處理到哪一個 ToggleEventId」。  
- 只處理「**EventId_GreaterThan**(`id`, `aLastEventIds[channel]`) 為 TRUE」的事件；處理完後呼叫 **EventId_Set**(`aLastEventIds[channel]`, `id`)。  
- **EventId_GreaterThan()** 內要處理 32 位元溢位（Id 遞增可能 wrap around），以 `(id1 - id2.id < 16#7FFF_FFFF)` 等條件判斷「新於舊」。

### 7.2 「下一個要觸發」的挑選（EL2252）

多軌道可能同時有多個候選事件，硬體一次只執行一筆，所以要選**最先發生**的：  
- 對每軌找出「尚未處理且 **IsValidDuration**(事件.Duration) 為 TRUE」的**第一個**事件，放入變數 `nextEvents[channel]`。  
- 在這些候選中取變數 `lowestDuration`（各 channel 的 event.Duration 的 MIN）。  
- 只對「Duration = `lowestDuration`」的那一軌（或數軌）設 `activate := TRUE`，寫入 **Out** 並進入 STATE_ACTIVATE_EVENT_IN_EL2252。  
如此可保證「每次只送出一筆最近要觸發的事件」，與硬體單筆觸發模型一致。

### 7.3 「時間夠不夠寫入」：MIN_CYCLES 與 IsValidDuration()

從「現在」到「事件觸發時間」若太短，寫入 PDO 後硬體來不及排程就會漏事件。  
- 常數 `MIN_CYCLES`：至少需要「幾個週期」的時間才允許寫入（EL2252 為 4，EL2258 為 6）。  
- **IsValidDuration()**（EL2252）／條件「Duration >= `MIN_CYCLES` * `taskInterval_s`」（EL2258）：只有滿足才寫入；否則 `missedCounter` 加一並呼叫 **OnMissedEvent()**。  
變數 `taskInterval_s` 來自 **Drive.fTaskCycle**（**setForecast** 提供），代表任務週期（秒），因此「`MIN_CYCLES` 週期」可換算成最短允許的剩餘時間。

### 7.4 EL2258 的批次寫入與 OutputOrderCounter

EL2258 可一次寫入多筆事件（本範例最多 5 筆）。  
- 變數 **OutputOrderCounter** 與 **OutputOrderFeedback**（在 ChannelsOut / ChannelsIn 內）：  
  - 程式寫完一筆批次後 **OutputOrderCounter** 加一；  
  - 硬體處理完該批次後會更新 **OutputOrderFeedback**。  
  - 當兩者相等時，表示該 channel 的上一批已執行完，可以再寫下一批，避免覆寫未執行的資料。

---

## 八、重要參數與設定位置（實作時對照）

| 項目 | 位置 | 說明 |
|------|------|------|
| 任務週期 | TaskConfiguration.md | EtherCAT_Task **t#4ms**，與軸週期一致，影響 taskInterval_s |
| 軸 Drive | DeviceTree_Axes.md、Main.st | 虛擬軸 SM_Drive_Virtual，提供位置與 fTaskCycle |
| 凸輪 Switches | Main.st **aSwitches** / **switches** | TrackNumber、FirstOnPosition、LastOnPosition、CamSwitchMode 等 |
| 凸輪 Tracks | Main.st **tracks** | OnCompensation、OffCompensation  per 軌道 |
| 運動速度／加減速 | Main.st **mv** | Velocity:= 180，Acceleration / Deceleration / Jerk |
| setForecast 預測長度 | Main.st **setForecast** | ForecastDuration:= 0.15（秒） |
| EL2252 通道數 | GVL_EL2252.st | NUM_CHANNELS := 2 |
| EL2252 最少週期數 | DigitalCamSwitch_EL2252.st **MIN_CYCLES** | 4 |
| EL2258 最少週期數 | DigitalCamSwitch_EL2258.st **MIN_CYCLES** | 6 |
| 庫參數 | Libraries.md、#SM3_Basic | GC_SMC_DIGITAL_CAM_SWITCH_* 等 |

---

## 九、建議閱讀與修改順序（給初學者）

1. **本文件「一、二」**：先搞懂專案目標、情境與硬體／通訊架構。  
2. **TaskConfiguration.md、DeviceTree_Axes.md**：對應「誰在跑、哪根軸、週期多少」。  
3. **Main.st**：只看狀態機 0→10→20→30 與最後的 pw、mv、setForecast、dcs、dcs_el2252、dcs_el2258 呼叫順序。  
4. **GVL_EL2252.st**：了解唯一的全域常數。  
5. **DigitalCamSwitch_EL2252.st**：從 STATE_INIT → STATE_CHECK_FOR_EVENT 的流程，以及 EventId、lowestDuration、MIN_CYCLES 的用法。  
6. **DigitalCamSwitch_EL2258.st**：比較與 EL2252 的差異（批次、32bit 時間戳、OutputOrderCounter）。  
7. **Libraries.md** 與 **七、演算法**：需要改參數或除錯時再細看。

---

## 十、名詞對照

| 英文／符號 | 說明 |
|------------|------|
| dcs | SMC_DigitalCamSwitch_HighPrecision 實例，產出 Events |
| setForecast | SMC_SetForecast，提供軸週期（fTaskCycle）→ taskInterval_s |
| pw | MC_Power，軸上電 |
| mv | MC_MoveVelocity，本範例驅動虛擬軸恆速運動 |
| Drive | 虛擬軸 SM_Drive_Virtual，凸輪的參考軸 |
| taskInterval_s | 任務週期（秒），用於 MIN_CYCLES 與時間戳計算 |
| Events | dcs 產出的凸輪事件列（每軌：Duration、NewValue、ToggleEventId 等） |
| ToggleEventId | 事件唯一識別，配合 EventId_Init/Set/GreaterThan 避免重複處理 |
| EL2252 / EL2258 | Beckhoff 具時間戳的數位輸出卡（2Ch / 8Ch） |
| PDO | EtherCAT Process Data Object，程式寫入 Out/ChannelsOut 後經 PDO 送到硬體 |

---

以上為以講師教材角度整理的範例說明：由**專案目標與情境**→**硬體與通訊**→**控制流程**→**各程式職責**→**函式庫與變數**→**演算法與參數**，方便初學者系統性理解與後續修改、除錯。
