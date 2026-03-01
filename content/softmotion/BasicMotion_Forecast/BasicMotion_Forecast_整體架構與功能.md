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

# BasicMotion_Forecast — 整體架構與功能說明

---

## 一、這個專案在做什麼？

這個範例示範 SoftMotion 的「預測（Forecast）」功能：  
在軸已經有運動命令的前提下，控制器可以預先計算「若未來某一段時間後，軸會在什麼位置、速度、加速度」，並且計算「到達某個位置大約需要多久時間」。  
這在做安全檢查（例如碰撞預測）、提前切換模式、或與其他軸／外部設備協調時非常有用。

---

## 二、使用情境與硬體／軸架構

### 2.1 任務與程式

根據 `TaskConfiguration.md`，本範例的任務配置如下：

| 任務名稱 | 類型 | 週期 | 優先權 | POU 清單 |
|----------|------|------|--------|----------|
| MainTask | Cyclic | t#4ms | 1 | `PLC_PRG` |

也就是說，每 4 ms 會呼叫一次 `PLC_PRG`，更新軸的電源、運動命令以及 Forecast 相關功能塊。

### 2.2 軸與裝置

根據 `DeviceTree_Axes.md`：

| 軸名稱 | 類型 | 角色 |
|--------|------|------|
| <span class="cfg-name">Drive</span> | <span class="cfg-name">SM_Drive_Virtual</span> | 單一虛擬軸，用來示範預測功能。 |

實際上你可以把 <span class="cfg-name">Drive</span> 想像成任何單軸伺服：只要能接受位置命令，就可以套用這個 Forecast 示例。

### 2.3 Trace 觀察點

`TraceConfig.md` 中記錄了：

- `Drive.fSetPosition`、`Drive.fSetVelocity`、`Drive.fSetAcceleration`  
- `PLC_PRG.timeToPosition.Duration`  
- `PLC_PRG.readSetValues.Position`／`Velocity`／`Acceleration`  

這些變數可以幫助你觀察：

- 軸當前的 Set 值（實際命令曲線）。  
- 預估從現在到達某個位置所需的時間。  
- 在該預估時間點，軸的預期 SetPosition／SetVelocity／SetAcceleration。

---

## 三、控制流程：由淺入深

### 3.1 整體流程概觀

用一句話來看：  

> 上電 → 開啟 Forecast 視窗 → 發出絕對位置移動命令 → 持續計算「到達中間目標位置需要多久」並讀取預估的 Set 值。

對照 `PLC_PRG` 狀態機 <span class="cfg-local">state</span>：

1. **STATE\_POWER\_DRIVE**：  
   - 透過 <span class="cfg-func">MC_Power()</span> 上電 <span class="cfg-name">Drive</span> 軸，等 `Status` 變為 TRUE。  
2. **STATE\_SET\_FORECAST**：  
   - 呼叫 <span class="cfg-func">SMC_SetForecast()</span> 對 Drive 軸啟用 Forecast 功能，並設定 `ForecastDuration := 0.3`，代表未來 0.3 秒內的軌跡會被預先計算。  
   - 同時啟用 <span class="cfg-func">SMC_GetForecast()</span>，之後可搭配 `ReadSetValues` 取用預測結果。  
3. **STATE\_MOVE\_TO\_POSITION**：  
   - 使用 <span class="cfg-func">MC_MoveAbsolute()</span> 對 Drive 軸下達移動命令（位置=10, 速度=20, 加速度/減速度=200, Jerk=1000）。  
   - 啟用 <span class="cfg-func">SMC_GetTravelTime()</span> 計算「到達位置 8 需要多久」 (`timeToPosition.Position := 8`)。  
   - 利用 `timeToPosition.Duration` 搭配 <span class="cfg-func">SMC_ReadSetValues()</span> 讀出「在該時間點的預估 SetPosition／SetVelocity／SetAcceleration」。  

整體來說，這支程式不在意「實際是否到達目標」，而是示範「如何在運動途中查詢未來某一時刻的預估狀態」。

---

## 四、各支程式負責哪些功能？

本範例只有一個主要程式 `PLC_PRG`，所有邏輯都集中於此。

### 4.1 `PLC_PRG` — 單軸預測示範程式

- **類型**：PROGRAM。  
- **主要職責**：  
  - 上電並啟動 <span class="cfg-name">Drive</span> 軸。  
  - 對 Drive 軸啟用 Forecast 視窗並指定長度。  
  - 發出絕對位置移動命令。  
  - 使用 <span class="cfg-func">SMC_GetTravelTime()</span> 與 <span class="cfg-func">SMC_ReadSetValues()</span> 計算「到達中間位置需要多久」與「該時間點軸的預期狀態」。  
- **與硬體／視覺化的關係**：  
  - 在真實機台上，你可以在這個基礎上加入更多判斷，例如如果預估到達時間過長就提早減速，或若預估會超過安全位置則提早停機。  

---

## 五、函式庫與函式／功能塊一覽

### 5.1 函式庫

根據 `Libraries.md`：

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | 提供基本 MC\_* 運動控制功能塊。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 雖有引用，但本範例主要用到的是 SMC\_* 預測相關功能。 |

### 5.2 主要功能塊

| 名稱 | 類型 | 用途 | 主要引數（IN / IN\_OUT） | 回傳／狀態 |
|------|------|------|--------------------------|------------|
| <span class="cfg-func">MC_Power()</span> | FUNCTION\_BLOCK | 對 Drive 軸上電與啟動驅動。 | <span class="cfg-arg">Axis</span>；<span class="cfg-arg">Enable</span>；<span class="cfg-arg">bDriveStart</span>；<span class="cfg-arg">bRegulatorOn</span>。 | `Status`、`Error`、`ErrorID`。 |
| <span class="cfg-func">MC_MoveAbsolute()</span> | FUNCTION\_BLOCK | 命令 Drive 軸移動到絕對位置。 | <span class="cfg-arg">Axis</span>；<span class="cfg-arg">Execute</span>；<span class="cfg-arg">Position</span>；<span class="cfg-arg">Velocity</span>；<span class="cfg-arg">Acceleration</span> 等。 | `Done`、`Error`、`ErrorID`。 |
| <span class="cfg-func">SMC_SetForecast()</span> | FUNCTION\_BLOCK | 啟用並設定 Forecast 功能。 | <span class="cfg-arg">Axis</span>；<span class="cfg-arg">Execute</span>；<span class="cfg-arg">ForecastDuration</span>（預測時間長度）。 | `Done`、`Error`、`ErrorID`。 |
| <span class="cfg-func">SMC_GetForecast()</span> | FUNCTION\_BLOCK | 啟用後，讓系統持續維護預測資訊。 | <span class="cfg-arg">Axis</span>；<span class="cfg-arg">Enable</span>。 | 預測資訊搭配其他功能塊取得。 |
| <span class="cfg-func">SMC_GetTravelTime()</span> | FUNCTION\_BLOCK | 計算從當前狀態到達目標位置所需時間。 | <span class="cfg-arg">Axis</span>；<span class="cfg-arg">Enable</span>；<span class="cfg-arg">Position</span>。 | `Valid`；`Duration`（預估所需時間）。 |
| <span class="cfg-func">SMC_ReadSetValues()</span> | FUNCTION\_BLOCK | 讀取在某個「時間偏移」之後的預估 SetPosition／SetVelocity／SetAcceleration。 | <span class="cfg-arg">Axis</span>；<span class="cfg-arg">Enable</span>；<span class="cfg-arg">TimeOffset</span>。 | `Position`、`Velocity`、`Acceleration` 等預估 Set 值。 |

---

## 六、變數與常數一覽

本範例未使用 RETAIN／PERSISTENT 變數。

### 6.1 `PLC_PRG` 中的重要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">state</span> | <span class="cfg-type">UDINT</span> | 主狀態機。 |
| <span class="cfg-local">error</span> | <span class="cfg-type">SMC_ERROR</span> | 儲存錯誤碼。 |
| <span class="cfg-local">setForecast</span> | <span class="cfg-type">SMC_SetForecast</span> | 設定 Forecast 視窗長度。 |
| <span class="cfg-local">getForecast</span> | <span class="cfg-type">SMC_GetForecast</span> | 啟用 Forecast 資訊維護。 |
| <span class="cfg-local">mcp</span> | <span class="cfg-type">MC_Power</span> | Drive 軸的電源功能塊。 |
| <span class="cfg-local">ma</span> | <span class="cfg-type">MC_MoveAbsolute</span> | 對 Drive 軸發出絕對位置命令。 |
| <span class="cfg-local">timeToPosition</span> | <span class="cfg-type">SMC_GetTravelTime</span> | 預估從目前到達位置 8 所需時間。 |
| <span class="cfg-local">readSetValues</span> | <span class="cfg-type">SMC_ReadSetValues</span> | 以預估時間偏移讀取預期 SetPosition／SetVelocity／SetAcceleration。 |

常數 `STATE_*` 則標示各個流程階段，方便在監控畫面或 Trace 中觀察邏輯推進。

Trace 中記錄的變數（例如 `timeToPosition.Duration`、`readSetValues.Position` 等）可以輕鬆對照「預估時間」與「預估狀態」是否符合你的直覺。

---

## 七、特別的演算法與觀念

### 7.1 ForecastDuration 與 GetTravelTime 的關係

在 **STATE\_SET\_FORECAST** 中設定：

```text
setForecast.ForecastDuration := 0.3;
```

代表控制器會嘗試在未來 0.3 秒的時間範圍內維護預測資料。  
接著在 **STATE\_MOVE\_TO\_POSITION** 中：

```text
timeToPosition.Enable := TRUE;
timeToPosition.Position := 8;
```

此時 <span class="cfg-func">SMC_GetTravelTime()</span> 會計算「在目前軌跡設定下，到達位置 8 需要多少時間」並輸出到 `timeToPosition.Duration`。  
只要這個時間沒有超出 `ForecastDuration`，就可以拿來當作 <span class="cfg-func">SMC_ReadSetValues()</span> 的 `TimeOffset`：

```text
readSetValues(
    Axis:= Drive,
    Enable:= timeToPosition.Valid,
    TimeOffset:= timeToPosition.Duration);
```

這樣就能讀出「當 Drive 軸行進到位置 8 時，預期的 SetPosition／SetVelocity／SetAcceleration」。

### 7.2 可應用的實務情境

雖然範例只做簡單的單軸直線移動，但同樣的概念可以擴展到：

- 在多軸協調時，預先計算各軸到達交會點的時間，避免碰撞。  
- 在高速輸送帶應用中，預先知道工件何時會到達某個感測器或工作站。  
- 在安全區域邊界前，若預估時間過短則提早減速或停機。  

換句話說，Forecast 功能提供了一個「往前看一小段未來」的能力，讓你不必等到實際到達才反應。

---

## 八、重要參數與設定位置

| 參數／設定 | 所在檔案／位置 | 說明 |
|------------|----------------|------|
| <span class="cfg-arg">ForecastDuration</span> | `PLC_PRG` 中 `setForecast.ForecastDuration` | 決定系統維護的預測時間範圍，太短可能無法覆蓋到你關心的位置，太長則計算量較大。 |
| 絕對移動命令參數 | `PLC_PRG` 中 `ma.Position/Velocity/Acceleration/Deceleration/Jerk` | 定義 Drive 軸實際運動軌跡，會影響預估時間與預估狀態。 |
| <span class="cfg-arg">timeToPosition.Position</span> | `PLC_PRG` 中 `timeToPosition.Position := 8;` | 想要查詢的目標位置，實務上可根據限位或工件位置設定。 |
| MainTask 週期 t#4ms | `TaskConfiguration.md` | 影響控制迴圈解析度與 Forecast 更新頻率。 |

在實務專案中，你可以把這些參數改成「真正的工件位置」與「實際速度曲線」，再觀察 Forecast 是否符合期望。

---

## 九、建議閱讀與修改順序

1. **先看 `DeviceTree_Axes.md` 與 `TaskConfiguration.md`**  
   - 確認只有一條 <span class="cfg-name">Drive</span> 軸，以及任務週期為 4 ms。  
2. **再看 `PLC_PRG` 的變數宣告區**  
   - 理解 <span class="cfg-local">setForecast</span>、<span class="cfg-local">getForecast</span>、<span class="cfg-local">timeToPosition</span>、<span class="cfg-local">readSetValues</span> 各自扮演的角色。  
3. **接著看狀態機**  
   - 尤其是 STATE\_SET\_FORECAST 與 STATE\_MOVE\_TO\_POSITION 兩段，對照本章第七節的解說。  
4. **最後打開 Trace 觀察**  
   - 專注在 `timeToPosition.Duration` 與 `readSetValues.Position/Velocity/Acceleration`，試著直覺地預測結果，再確認是否與波形一致。  

修改時，建議先只改 `ForecastDuration`、`timeToPosition.Position` 與目標位置／速度，反覆觀察 Forecast 行為是否符合想像。

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">Forecast</span> | 預測軸在未來某段時間內的預期狀態（位置、速度、加速度等）的功能。 |
| <span class="cfg-func">SMC_SetForecast()</span> | 啟用並設定 Forecast 視窗長度的功能塊。 |
| <span class="cfg-func">SMC_GetForecast()</span> | 啟用 Forecast 資訊維護的功能塊，搭配其他功能塊讀取。 |
| <span class="cfg-func">SMC_GetTravelTime()</span> | 計算從目前狀態到達指定位置所需時間的功能塊。 |
| <span class="cfg-func">SMC_ReadSetValues()</span> | 根據時間偏移讀出預估的 SetPosition／SetVelocity／SetAcceleration。 |
| <span class="cfg-name">Set values</span> | 控制器計畫中的「目標值」，與實際測量值（Actual values）相對。 |

