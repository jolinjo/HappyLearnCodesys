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

# Robotics_Interrupt_Continue — 整體架構與功能說明

---

## 一、這個專案在做什麼？（一句話＋情境）

這個範例示範如何在機器人軸組執行一連串插補運動時，**中斷目前運動、插入中間動作、再從中斷點繼續原路徑**。  
你可以把它想成：機器人在移動途中收到「暫停去做一件事」的指令，完成後再回到原路徑，平順地把剩下的動作做完。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務與程式對應（對照 `TaskConfiguration.md`）

| 任務名稱 | 類型 | 週期 | 優先權 | 執行的 POU |
|----------|------|------|--------|------------|
| MainTask | Cyclic | t#4ms | 1 | `PLC_PRG` |
| SoftMotion_PlanningTask | Freewheeling | t#2ms | 15 | - |

所有中斷與續行邏輯皆在 `PLC_PRG` 裡，由 MainTask 週期性執行。  
本範例沒有額外的規劃程式，重點放在 MC_GroupInterrupt / MC_GroupContinue 的使用方式。

### 2.2 軸與裝置結構（對照 `DeviceTree_Axes.md`）

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| Drive_A1 | SM_Drive_Virtual | - |
| Drive_A2 | SM_Drive_Virtual | - |
| Drive_A3 | SM_Drive_Virtual | - |

三個虛擬軸組成一個簡化的軸組（可想像為三自由度的機構），用來示範中斷與續行，不涉及完整機器人運動學。

### 2.3 Trace 與觀察點（對照 `TraceConfig.md`）

| 變數名 | 說明 |
|--------|------|
| `PLC_PRG.state` | 主狀態機目前狀態 |
| `PLC_PRG.moveLinearA.Active`、`moveLinearB.Active` | 兩段線性運動是否正在執行 |
| `PLC_PRG.interrupt.Busy`、`PLC_PRG.cont.Busy` | 中斷與續行 FB 忙碌狀態 |
| `PLC_PRG.moveToContinuePos.Active` | 移動回中斷點過程是否啟動 |
| `PLC_PRG.Position.c.X/Y/Z` | 目前位置，用來觀察路徑和中斷點位置 |

透過這些 Trace，可以清楚看到「原始運動 → 中斷 → 中間動作 → 回到中斷點 → 繼續原運動」的完整軌跡。

---

## 三、控制流程：由淺入深（對照 `PLC_PRG.st`）

### 3.1 整體狀態機

`PLC_PRG` 使用 <span class="cfg-local">state</span> 與一組常數（<span class="cfg-const">STATE_POWER_ON</span> 等）表示流程：

- **STATE_POWER_ON (0)**  
  - 呼叫 <span class="cfg-func">SMC_GroupPower()</span>（<span class="cfg-local">power</span>）與 <span class="cfg-func">MC_GroupEnable()</span>（<span class="cfg-local">enable</span>）啟動軸組。  
  - 啟動成功後，啟用 `readPos`（<span class="cfg-func">SMC_GroupReadSetPosition()</span>），並啟動第一段線性運動 `moveLinearA`。

- **STATE_START_MOVING (10)**  
  - 一旦 `moveLinearA.CommandAccepted = TRUE`，代表第一段運動已被接受，便啟動第二段運動 `moveLinearB`。  
  - 當 `moveLinearB.Active = TRUE` 時，呼叫 <span class="cfg-func">MC_GroupInterrupt()</span>（<span class="cfg-local">interrupt</span>），進入中斷流程。

- **STATE_INTERRUPT (20)**  
  - 等待中斷完成（`interrupt.Done = TRUE`），此時原本的運動會暫停並將續行所需資料寫入 <span class="cfg-local">data</span>（型態 <span class="cfg-type">SMC_AXIS_GROUP_CONTINUE_DATA</span>）。  
  - 隨後啟動 `movePTP`，讓軸組執行一段相對運動（例如往上抬一段距離）。

- **STATE_INTERMEDIATE_MOVEMENT (30)**  
  - 等待 `movePTP.Done = TRUE`，表示中間動作完成。  
  - 接著啟動 `getContinuePos`（<span class="cfg-func">SMC_GroupGetContinuePosition()</span>），要求系統計算「若從中斷點繼續，應該往哪個位置移動」。

- **STATE_GET_CONTINUE_POS (40)**  
  - 等待 `getContinuePos.Done = TRUE`，此時得到 `getContinuePos.Position` 與 `getContinuePos.CoordSystem`。  
  - 將這些位置資訊指定給 `moveToContinuePos.Position` 與 `moveToContinuePos.CoordSystem`，然後啟動 `moveToContinuePos`。

- **STATE_MOVE_TO_CONTINUE_POS (50)**  
  - 等待 `moveToContinuePos.Done = TRUE`，表示軸組已移動回續行點。  
  - 此時呼叫 <span class="cfg-func">MC_GroupContinue()</span>（<span class="cfg-local">cont</span>），讓系統從中斷位置繼續原本的運動。

- **STATE_CONTINUE (60)**  
  - 等待 `cont.Done = TRUE`，代表續行指令已處理。  
  - 接著進入 `STATE_FINISH_MOVE`，監控第二段運動何時真正完成。

- **STATE_FINISH_MOVE (70)**  
  - 等待 `moveLinearB.Done = TRUE`，表示原始整段運動（含中斷與續行）已走完。  
  - 切換到 `STATE_DONE` 並將 `Done := TRUE`。

- **STATE_ERROR (1000)**  
  - 若任何運動或中斷相關 FB 出現 Error，狀態機會進到錯誤狀態，`Error := TRUE`。

### 3.2 續行資料的傳遞（`data : SMC_AXIS_GROUP_CONTINUE_DATA`）

- `interrupt` 呼叫時將 `continueData := data`，中斷完成後 `data` 中會帶有「原本運動未完成部分」的資訊。  
- `getContinuePos` 與 `cont` 在呼叫時同樣使用 `continueData := data`，代表它們都在處理同一筆續行資料。  
- 透過這個結構，系統可以：  
  - 算出「若要從中斷點繼續，應該回到哪個姿態」，也就是 `getContinuePos` 的 Position。  
  - 在 `cont` 被呼叫時，知道原本運動還剩哪些路徑需要完成。

---

## 四、各支程式負責哪些功能？（本專案僅 `PLC_PRG.st`）

### 4.1 `PLC_PRG.st` — 中斷與續行的範例主程式

- **類型**：<span class="cfg-keyword">PROGRAM</span>。  
- **職責**：
  - 啟動軸組並下達兩段線性運動。  
  - 在第二段運動途中執行中斷，並插入一段「中間運動」`movePTP`。  
  - 利用 `SMC_GroupGetContinuePosition` 計算續行位置，先平滑移回該位置，再呼叫 `MC_GroupContinue` 續行原運動。  
  - 監控每個功能塊的 Error 狀態，決定是否進入 `STATE_ERROR`。

---

## 五、函式庫與函式／功能塊一覽（用途、引數、回傳）

### 5.1 函式庫（對照 `Libraries.md`）

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | 提供 MC_* 及部分 SMC_* 群組運動功能塊 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 路徑／凸輪相關功能（本範例聚焦在中斷與續行） |

### 5.2 主要功能塊

- <span class="cfg-func">SMC_GroupPower()</span>（<span class="cfg-local">power</span>）與 <span class="cfg-func">MC_GroupEnable()</span>（<span class="cfg-local">enable</span>）  
  - 啟動軸組，是所有運動前的前置條件。

- <span class="cfg-func">MC_MoveLinearAbsolute()</span>（<span class="cfg-local">moveLinearA</span>、<span class="cfg-local">moveLinearB</span>）  
  - 兩段主要線性運動，其中 B 使用 `BufferMode := MC_BUFFER_MODE.BlendingHigh` 形成連續路徑。

- <span class="cfg-func">MC_GroupInterrupt()</span>（<span class="cfg-local">interrupt</span>）  
  - 中斷當前由群組功能塊控制的運動，並將續行所需資料寫入 `data`。  

- <span class="cfg-func">SMC_GroupGetContinuePosition()</span>（<span class="cfg-local">getContinuePos</span>）  
  - 根據 `data` 計算「應該從哪個位置繼續」，並輸出位置與座標系。  

- <span class="cfg-func">MC_MoveDirectRelative()</span>（<span class="cfg-local">movePTP</span>）  
  - 中斷後插入的相對運動，用來模擬去做一件「中間動作」。  

- <span class="cfg-func">MC_MoveLinearAbsolute()</span>（<span class="cfg-local">moveToContinuePos</span>）  
  - 用 `getContinuePos` 輸出的 Position 與 CoordSystem 把軸組移回續行點。  

- <span class="cfg-func">MC_GroupContinue()</span>（<span class="cfg-local">cont</span>）  
  - 使用同一份 `data`，令軸組從中斷點繼續執行尚未完成的原運動。

---

## 六、變數與常數一覽

### 6.1 重要常數

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| <span class="cfg-const">STATE_POWER_ON</span>..`STATE_DONE` | <span class="cfg-type">UDINT</span> | 如程式設定 | 狀態機各階段定義 |
| <span class="cfg-const">VEL</span> | <span class="cfg-type">LREAL</span> | 50 | 線性運動速度 |
| <span class="cfg-const">ACC</span> | <span class="cfg-type">LREAL</span> | 500 | 加速度 |
| <span class="cfg-const">JERK</span> | <span class="cfg-type">LREAL</span> | 10000 | Jerk |

### 6.2 重要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">moveLinearA</span>, <span class="cfg-local">moveLinearB</span> | <span class="cfg-type">MC_MoveLinearAbsolute</span> | 兩段主要運動 |
| <span class="cfg-local">interrupt</span> | <span class="cfg-type">MC_GroupInterrupt</span> | 負責中斷運動並填入 `data` |
| <span class="cfg-local">cont</span> | <span class="cfg-type">MC_GroupContinue</span> | 根據 `data` 續行原運動 |
| <span class="cfg-local">getContinuePos</span> | <span class="cfg-type">SMC_GroupGetContinuePosition</span> | 計算續行位置與座標系 |
| <span class="cfg-local">movePTP</span> | <span class="cfg-type">MC_MoveDirectRelative</span> | 中間插入的相對運動 |
| <span class="cfg-local">moveToContinuePos</span> | <span class="cfg-type">MC_MoveLinearAbsolute</span> | 將軸組移回續行點 |
| <span class="cfg-local">data</span> | <span class="cfg-type">SMC_AXIS_GROUP_CONTINUE_DATA</span> | 承載續行資訊的結構 |
| <span class="cfg-local">state</span> | <span class="cfg-type">UDINT</span> | 主狀態機 |

本範例未使用 RETAIN／PERSISTENT。

---

## 七、特別的演算法與觀念

### 7.1 中斷與續行的安全流程

這個範例強調的觀念是：  
不要直接「停止運動再重啟」，而是透過中斷與續行保持軌跡連續性：

1. 用 <span class="cfg-func">MC_GroupInterrupt()</span> 暫停運動並取得續行資料。  
2. 插入必要的中間運動（例如離開工件、避開障礙）。  
3. 透過 <span class="cfg-func">SMC_GroupGetContinuePosition()</span> 計算續行起點。  
4. 精準移回該點後，再呼叫 <span class="cfg-func">MC_GroupContinue()</span> 繼續原運動。

這樣做可以確保「剩餘路徑」與原本設計的軌跡一致，不會因為單純重新下達路徑而產生偏差。

### 7.2 續行資料結構的使用方式

`SMC_AXIS_GROUP_CONTINUE_DATA` 在中斷、取得續行位置與續行動作之間被重複使用：  
只要確保整個流程都用同一份 `data`，SoftMotion 就能正確追蹤「哪一條原始運動被中斷、目前進度在哪裡」。

---

## 八、建議閱讀與修改順序

1. 先閱讀本說明，建立整體中斷／續行流程的概念。  
2. 再看 `TaskConfiguration.md` 與 `DeviceTree_Axes.md`，確認任務週期與軸組成員。  
3. 打開 `PLC_PRG.st`：  
   - 先沿著狀態機常數（STATE_*）畫一張流程圖；  
   - 再對照每一段程式碼，弄清楚各 FB 何時被啟動、何時 Done。  
4. 搭配 Trace，觀察：  
   - `Position.c.*` 如何隨中斷／中間運動／續行而變化；  
   - `moveLinearA.Active`、`moveLinearB.Active`、`interrupt.Busy`、`cont.Busy` 在流程中的變化。

若要延伸應用，可以將中間運動 `movePTP` 換成更複雜的安全動作，例如避開人員進入區域、繞開障礙物等。

---

## 九、名詞對照

| 英文／符號 | 說明 |
|-----------|------|
| <span class="cfg-name">Interrupt</span> | 中斷目前插補運動並暫停在安全狀態 |
| <span class="cfg-name">Continue</span> | 根據先前中斷紀錄，繼續尚未走完的軌跡 |
| <span class="cfg-name">ContinueData</span> | 續行資料，記錄中斷時的運動狀態與剩餘路徑 |

---
