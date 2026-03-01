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

**顏色對應**：<span class="cfg-func">內建函數 / 功能塊</span> <span class="cfg-global">全域變數</span> <span class="cfg-local">區域變數</span> <span class="cfg-custom">自訂函數 / 方法</span> <span class="cfg-const">常數</span> <span class="cfg-keyword">保留字</span> <span class="cfg-type">型態</span> <span class="cfg-arg">引數</span> <span class="cfg-name">專有名詞</span>

# PLCopenMultiCAM — 整體架構與功能說明

---

## 一、這個專案在做什麼？（一句話＋情境）

這個範例示範如何在同一組主軸／從軸架構上，輪流使用兩張不同的凸輪表（Cam Table），並在不中斷運動的情況下，在兩條凸輪曲線之間平順切換，是一個「雙凸輪交替控制」的教學案例。

你可以把它想成：由一根主軸帶動從軸，從軸有兩種不同的運動型態（例如「長行程」與「短行程」），系統會在適當時機在兩種型態間來回切換，而且切換瞬間不會產生明顯的速度突變。

---

## 二、使用情境與硬體／通訊架構

### 2.1 硬體與軸配置

`DeviceTree_Axes.md` 顯示本範例與 PLCopenMulti 類似，同樣包含兩根虛擬軸：

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| <span class="cfg-name">Drive</span> | <span class="cfg-name">SM_Drive_Virtual</span> | - |
| <span class="cfg-name">Virtual</span> | <span class="cfg-name">SM_Drive_Virtual</span> | - |

- <span class="cfg-name">Virtual</span>：主軸，由速度命令驅動。  
- <span class="cfg-name">Drive</span>：從軸，依凸輪表 Example1 / Example2 與主軸保持同步。

### 2.2 任務與週期

`TaskConfiguration.md` 中的任務結構：

| 任務名稱 | 類型 | 週期 | 優先權 | POU 清單 |
|----------|------|------|--------|----------|
| Task | Cyclic | t#4ms | 1 | MOTION_PRG |
| VISU_TASK | Cyclic | t#100ms | 10 | VisuElems.Visu_Prg |

- `Task` 以 4ms 週期執行 `MOTION_PRG`，負責全部的上電、凸輪選取、CamIn 控制與狀態機切換。  
- `VISU_TASK` 以 100ms 週期執行可視化 POU，顯示軸狀態與凸輪切換情形。

### 2.3 Trace 設定與觀測重點

`TraceConfig.md` 中的 8 個變數，大致可以分成兩類：

| 變數名 | 任務 | 緩衝筆數 | 說明（概念） |
|--------|------|----------|--------------|
| <span class="cfg-name">Virtual.fSetPosition</span> | Task | 501 | 主軸的目標位置，用來觀察主軸運動。 |
| <span class="cfg-name">Drive.fSetPosition</span> | Task | 501 | 從軸的目標位置，用來觀察凸輪曲線效果。 |
| <span class="cfg-name">Drive.fSetVelocity</span> | Task | 501 | 從軸目標速度，觀察速度變化是否平順。 |
| <span class="cfg-name">Drive.fSetAcceleration</span> | Task | 501 | 從軸加速度，觀察加減速區段。 |
| <span class="cfg-name">MOTION_PRG.CamIn1.Active</span> | Task | 501 | 判斷目前是否由 CamIn1 控制。 |
| <span class="cfg-name">MOTION_PRG.CamIn2.Active</span> | Task | 501 | 判斷目前是否由 CamIn2 控制。 |
| <span class="cfg-name">MOTION_PRG.CamIn1.InSync</span> | Task | 501 | 測試 CamIn1 是否與主軸同步。 |
| <span class="cfg-name">MOTION_PRG.CamIn2.InSync</span> | Task | 501 | 測試 CamIn2 是否與主軸同步。 |

透過這些 Trace 設定，可以在 CODESYS 中畫出曲線，清楚看到「主軸位置」、「從軸位置」以及「哪一個 CamIn 正在控制」三者之間的關係。

---

## 三、控制流程：由淺入深

### 3.1 狀態機總覽

`MOTION_PRG.st` 裡的核心是一個由 <span class="cfg-local">state</span> 控制的狀態機，常數定義如下：

- <span class="cfg-const">STATE_POWER_ON</span> = 0  
- <span class="cfg-const">STATE_START_SYNC</span> = 10  
- <span class="cfg-const">STATE_RESTART_CAM_IN_1</span> = 20  
- <span class="cfg-const">STATE_RESTART_CAM_IN_2</span> = 30  

可以依下列順序理解整個流程：

1. **STATE_POWER_ON**：確保兩根軸都上電且可控制。  
2. **STATE_START_SYNC**：同時選取兩張凸輪表 Example1 / Example2，並啟動第一個 CamIn1，同時啟動主軸速度。  
3. **STATE_RESTART_CAM_IN_1 與 STATE_RESTART_CAM_IN_2**：  
   - 當目前由 CamIn2 控制時，準備重新啟動 CamIn1，讓它在適當時機接手。  
   - 當目前由 CamIn1 控制時，準備重新啟動 CamIn2。  
   - 藉由兩個狀態互相切換，在 Example1 與 Example2 兩張凸輪表之間來回輪流控制。

### 3.2 各狀態細節

**狀態：STATE_POWER_ON**  

- 週期性呼叫兩個 <span class="cfg-func">MC_Power</span> 功能塊：一個對 <span class="cfg-name">Drive</span>，一個對 <span class="cfg-name">Virtual</span>。  
- 當 `Power.Status` 與 `PowerVirtual.Status` 同時為 TRUE 時，代表兩根軸都已準備就緒，狀態切換到 <span class="cfg-const">STATE_START_SYNC</span>。

**狀態：STATE_START_SYNC**  

- 使用兩個 <span class="cfg-func">MC_CamTableSelect</span>：  
  - <span class="cfg-local">TableSelect1</span> 選取凸輪表 Example1，建立 `CamTableID`。  
  - <span class="cfg-local">TableSelect2</span> 選取凸輪表 Example2，建立另一個 `CamTableID`。  
- 把這兩個 `CamTableID` 分別指定給 <span class="cfg-local">CamIn1</span> 與 <span class="cfg-local">CamIn2</span>。  
- 等 <span class="cfg-local">TableSelect1.Done</span> 與 <span class="cfg-local">TableSelect2.Done</span> 都為 TRUE 後，才開始：  
  - 以 <span class="cfg-local">CamIn1</span> 作為第一個啟動的凸輪同步：  
    - `StartMode := ramp_in_dist`、`MasterSyncPosition := 2`、`MasterStartDistance := 1`，用距離模式平順進入同步。  
  - 啟動 <span class="cfg-local">MoveVirtual</span>，讓主軸開始以設定速度運轉。  
- 狀態切換到 <span class="cfg-const">STATE_RESTART_CAM_IN_2</span>，準備日後改由 CamIn2 接手。

**狀態：STATE_RESTART_CAM_IN_1**  

- 當 <span class="cfg-local">CamIn2.Active</span> 為 TRUE 時，代表目前由 CamIn2 控制從軸。  
- 這時先呼叫 `CamIn1(Execute := FALSE)` 結束前一次命令，接著：  
  - 設定 `StartMode := relative`、`BufferMode := MC_BUFFER_MODE.Buffered`。  
  - 再把 `Execute := TRUE`，讓 CamIn1 以「緩衝模式」排隊等待合適時機接管控制。  
- 狀態切換到 <span class="cfg-const">STATE_RESTART_CAM_IN_2</span>。

**狀態：STATE_RESTART_CAM_IN_2**  

- 當 <span class="cfg-local">CamIn1.Active</span> 為 TRUE 時，代表目前由 CamIn1 控制從軸。  
- 流程與上一個狀態相反：  
  - 先把 CamIn2 的舊命令結束，再用 `StartMode := relative`、`BufferMode := MC_BUFFER_MODE.Buffered` 啟動新的命令。  
  - 讓 CamIn2 在 CamIn1 結束輪廓時平順接手控制。  
- 狀態切回 <span class="cfg-const">STATE_RESTART_CAM_IN_1</span>，形成「1 ↔ 2」來回切換的循環。

### 3.3 週期性呼叫與 EndOfProfile 處理

在 CASE 區塊之外，程式還做了兩件事：

- 週期性呼叫 <span class="cfg-local">MoveVirtual</span>，讓主軸 <span class="cfg-name">Virtual</span> 持續以設定速度運動。  
- 週期性呼叫 <span class="cfg-local">CamIn1</span> 與 <span class="cfg-local">CamIn2</span>，讓兩個功能塊根據狀態與參數實際控制從軸。  

此外，還有一段：

- 當 `CamIn2.EndOfProfile` 為 TRUE 時，再呼叫一次 <span class="cfg-local">CamIn1</span>，確保在 CamIn2 結束輪廓的瞬間，CamIn1 會接手控制權，避免從軸暫時失去控制。

---

## 四、各支程式負責哪些功能？（由淺入深）

本範例程式集中在 `MOTION_PRG.st`：

### 4.1 `MOTION_PRG.st`

- **類型**：<span class="cfg-keyword">PROGRAM</span>  
- **職責**：  
  - 管理兩根軸與兩張凸輪表，並以狀態機 <span class="cfg-local">state</span> 控制何時由哪一個 CamIn 負責同步。  
  - 保持主軸 <span class="cfg-name">Virtual</span> 以連續速度運轉，讓整個系統有穩定的時間基準。  
  - 與 Trace 所設定的變數配合，提供觀察凸輪切換行為的最佳訊號。

---

## 五、函式庫與函式／功能塊一覽（用途、引數、回傳）

### 5.1 函式庫清單（對照 `Libraries.md`）

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | 提供 <span class="cfg-func">MC_Power</span>、<span class="cfg-func">MC_MoveVelocity</span>、<span class="cfg-func">MC_CamIn</span> 等功能塊。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 提供凸輪表建立與管理功能，供 Example1 / Example2 等曲線使用。 |
| <span class="cfg-name">#System_VisuElem3DPath</span> | 用於可視化 3D 路徑的系統庫。 |
| <span class="cfg-name">#System_VisuElemCamDisplayer</span> | 用於顯示與操作凸輪曲線的可視化元件庫。 |

### 5.2 主要功能塊整理

#### 5.2.1 <span class="cfg-func">MC_Power()</span>

- 如前幾個範例所述，這裡用兩個執例：<span class="cfg-local">Power</span>、<span class="cfg-local">PowerVirtual</span>，分別對 <span class="cfg-name">Drive</span> 與 <span class="cfg-name">Virtual</span> 上電。

#### 5.2.2 <span class="cfg-func">MC_MoveVelocity()</span>

- 執例：<span class="cfg-local">MoveVirtual</span>。  
- 用途：以指定速度、加減速度與 Jerk 讓主軸 <span class="cfg-name">Virtual</span> 持續運轉。  

#### 5.2.3 <span class="cfg-func">MC_CamTableSelect()</span>

- 執例：<span class="cfg-local">TableSelect1</span>、<span class="cfg-local">TableSelect2</span>。  
- 用途：分別選取凸輪表 Example1 與 Example2，產生對應的 <span class="cfg-arg">CamTableID</span>。  

#### 5.2.4 <span class="cfg-func">MC_CamIn()</span>

- 執例：<span class="cfg-local">CamIn1</span>、<span class="cfg-local">CamIn2</span>。  
- 用途：依各自的 <span class="cfg-arg">CamTableID</span> 控制從軸 <span class="cfg-name">Drive</span> 相對主軸 <span class="cfg-name">Virtual</span> 的運動輪廓。  
- 重要欄位：  
  - <span class="cfg-arg">StartMode</span>：決定如何進入凸輪同步（本例使用 `ramp_in_dist` 或 `relative`）。  
  - <span class="cfg-arg">BufferMode</span>：決定多個命令如何排隊（本例使用 <span class="cfg-name">MC_BUFFER_MODE.Buffered</span>）。  
  - 狀態輸出 `Active`、`InSync`、`EndOfProfile` 供狀態機與 Trace 使用。

---

## 六、變數與常數一覽

本範例未另建 GVL，所有變數與常數都在 `MOTION_PRG.st` 中宣告。

### 6.1 `MOTION_PRG.st` 內的變數與常數

| 名稱 | 類別 | 型態 | 預設值 | 說明 |
|------|------|------|--------|------|
| <span class="cfg-local">Power</span> | 區域變數 | <span class="cfg-type">MC_Power</span> | `Enable := TRUE` 等 | 控制從軸 <span class="cfg-name">Drive</span> 上電。 |
| <span class="cfg-local">PowerVirtual</span> | 區域變數 | <span class="cfg-type">MC_Power</span> | 同上 | 控制主軸 <span class="cfg-name">Virtual</span> 上電。 |
| <span class="cfg-local">MoveVirtual</span> | 區域變數 | <span class="cfg-type">MC_MoveVelocity</span> | `Velocity := 1`、`Acceleration/Deceleration := 100`、`Jerk := 1000` | 主軸速度命令。 |
| <span class="cfg-local">TableSelect1</span> | 區域變數 | <span class="cfg-type">MC_CamTableSelect</span> | 功能塊預設 | 選取 Example1 凸輪表。 |
| <span class="cfg-local">TableSelect2</span> | 區域變數 | <span class="cfg-type">MC_CamTableSelect</span> | 功能塊預設 | 選取 Example2 凸輪表。 |
| <span class="cfg-local">CamIn1</span> | 區域變數 | <span class="cfg-type">MC_CamIn</span> | 功能塊預設 | 套用 Example1 的凸輪同步。 |
| <span class="cfg-local">CamIn2</span> | 區域變數 | <span class="cfg-type">MC_CamIn</span> | 功能塊預設 | 套用 Example2 的凸輪同步。 |
| <span class="cfg-local">state</span> | 區域變數 | <span class="cfg-type">INT</span> | 0 | 控制整體流程的狀態機。 |
| <span class="cfg-const">STATE_POWER_ON</span> | 常數 | <span class="cfg-type">INT</span> | 0 | 上電狀態編號。 |
| <span class="cfg-const">STATE_START_SYNC</span> | 常數 | <span class="cfg-type">INT</span> | 10 | 初次建立凸輪同步的狀態。 |
| <span class="cfg-const">STATE_RESTART_CAM_IN_1</span> | 常數 | <span class="cfg-type">INT</span> | 20 | 在 CamIn2 控制時，準備重新啟動 CamIn1。 |
| <span class="cfg-const">STATE_RESTART_CAM_IN_2</span> | 常數 | <span class="cfg-type">INT</span> | 30 | 在 CamIn1 控制時，準備重新啟動 CamIn2。 |

---

## 七、特別的演算法與觀念

### 7.1 以「緩衝模式」實現平順切換

核心觀念是：使用 <span class="cfg-name">MC_BUFFER_MODE.Buffered</span> 搭配 `Active`、`EndOfProfile` 等狀態，讓兩個 CamIn 功能塊不會同時搶控制權，而是在一個完成輪廓後，另一個才平順接手。

初學者可以這樣理解：

- `Buffered` 模式就像在「佇列」中排隊：  
  - 目前正在執行的命令跑完後，隊列中的下一個命令才會接著執行。  
- 狀態機 <span class="cfg-local">state</span> 的工作，就是決定「下一個排隊的是哪一個 CamIn」，從而達到 Example1 / Example2 輪流執行的效果。

### 7.2 Trace 與除錯思維

透過 Trace 設定中列出的 8 個變數，可以回答以下幾個關鍵問題：

- 主軸位置是否連續且單調增加？  
- 從軸的位置曲線在不同凸輪表下有何差異？  
- 何時由 CamIn1 控制？何時由 CamIn2 控制？是否存在同時 Active 或同時不 Active 的危險狀態？  

這些都是實作多凸輪切換時非常重要的驗證重點。

---

## 八、重要參數與設定位置（實作時對照）

### 8.1 軸與任務

| 項目 | 名稱 | 說明 |
|------|------|------|
| 主軸 | <span class="cfg-name">Virtual</span> | 虛擬主軸，由 <span class="cfg-func">MC_MoveVelocity</span> 控制。 |
| 從軸 | <span class="cfg-name">Drive</span> | 虛擬從軸，透過 <span class="cfg-func">MC_CamIn</span> 依凸輪表運動。 |
| 任務 | <span class="cfg-name">Task</span> | 週期 4ms，執行 `MOTION_PRG`。 |
| 任務 | <span class="cfg-name">VISU_TASK</span> | 週期 100ms，執行 `VisuElems.Visu_Prg`。 |

### 8.2 凸輪與運動參數

- 主軸速度（<span class="cfg-local">MoveVirtual</span>）：`Velocity := 1`、`Acceleration/Deceleration := 100`、`Jerk := 1000`。  
- 凸輪表：Example1 / Example2 的具體內容定義在專案中，可透過 <span class="cfg-name">Cam Builder</span> 或 VISU 介面檢視。  
- CamIn 相關參數（程式中設定）：  
  - 初次啟動 CamIn1：`StartMode := ramp_in_dist`、`MasterSyncPosition := 2`、`MasterStartDistance := 1`。  
  - 後續切換：`StartMode := relative`、`BufferMode := MC_BUFFER_MODE.Buffered`。

---

## 九、建議閱讀與修改順序（給初學者）

1. **先閱讀 `TaskConfiguration.md` 與 `DeviceTree_Axes.md`**  
   - 了解有哪些任務、哪些軸，以及誰是主軸、誰是從軸。  
2. **再看 `TraceConfig.md`**  
   - 把 8 個追蹤變數對應到你想觀察的行為（位置、速度、哪一個 CamIn 控制）。  
3. **接著詳細閱讀 `MOTION_PRG.st`**  
   - 仔細追蹤 <span class="cfg-local">state</span> 如何從 0 → 10 → 20 ↔ 30 變化，並對照每個狀態裡對 CamIn 的設定。  
4. **最後在 CODESYS 中實際跑 Trace**  
   - 檢查當系統切換凸輪表時，位置與速度曲線是否平順、是否符合預期。

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">Cam Table</span> | 凸輪表，定義主軸位置與從軸位置之間的對應關係。 |
| <span class="cfg-func">MC_CamIn</span> | 套用凸輪表並讓從軸追隨主軸的功能塊。 |
| <span class="cfg-name">Buffered</span> | 緩衝模式，新的命令會排隊等前一個命令完成後再執行。 |
| <span class="cfg-name">EndOfProfile</span> | 凸輪輪廓結束的狀態旗標，常用來觸發下一個命令。 |
| <span class="cfg-name">Trace</span> | CODESYS 內建的波形記錄工具，用來觀察變數隨時間的變化。 |

