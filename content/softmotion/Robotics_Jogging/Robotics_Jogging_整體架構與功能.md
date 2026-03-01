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

# Robotics_Jogging — 整體架構與功能說明

---

## 一、這個專案在做什麼？（一句話＋情境）

這個範例示範如何為六軸機器人加上兩個附加軸，並透過一組 Jog 功能塊讓操作者以按鍵方式手動點動整個軸組。  
你可以把它想成「機器人教導器」的底層實作：按住某個方向鍵，機器人就沿著指定座標系與速度平滑地移動。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務與程式對應（對照 `TaskConfiguration.md`）

| 任務名稱 | 類型 | 週期 | 優先權 | 執行的 POU |
|----------|------|------|--------|------------|
| MainTask | Cyclic | t#4ms | 1 | `PLC_PRG` |
| SoftMotion_PlanningTask | Freewheeling | t#2ms | 15 | - |

- 本範例的主要控制邏輯完全在 `PLC_PRG` 中，由 MainTask 週期性執行。  
- `SoftMotion_PlanningTask` 雖然存在，但目前沒有掛程式，只保留對未來擴充規劃功能的彈性。

### 2.2 軸與裝置結構（對照 `DeviceTree_Axes.md`）

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| Drive_A1 | SM_Drive_Virtual | - |
| Drive_A2 | SM_Drive_Virtual | - |
| Drive_A3 | SM_Drive_Virtual | - |
| Drive_A4 | SM_Drive_Virtual | - |
| Drive_A5 | SM_Drive_Virtual | - |
| Drive_A6 | SM_Drive_Virtual | - |
| AddAxis_Linear_A7 | SM_Drive_Virtual | - |
| AddAxis_Rotary_A8 | SM_Drive_Virtual | - |

- <span class="cfg-name">Drive_A1 ~ Drive_A6</span>：對應機器人本體六個關節軸。  
- <span class="cfg-name">AddAxis_Linear_A7</span>：額外的線性軸（例如外部滑台）。  
- <span class="cfg-name">AddAxis_Rotary_A8</span>：額外的旋轉軸（例如旋轉平台）。

在程式中，這些軸被彙整成軸組 `<span class="cfg-name">Robi</span>`，由 `PLC_PRG` 與 `GroupJog2` 共同操作。

### 2.3 Trace 與觀察點（對照 `TraceConfig.md`）

Trace 主要關注 Z 軸相關物理量與 Jog 狀態：

| 變數名 | 說明 |
|--------|------|
| `VirtZ.fSetPosition`、`VirtZ.fSetVelocity`、`VirtZ.fSetAcceleration`、`VirtZ.fSetJerk` | 虛擬 Z 軸的指令位置、速度、加速度、Jerk |
| `VirtZ.fSavePosition` | 用來儲存特定位置的輔助變數 |
| `GroupJog.state` | Jog 狀態機目前狀態 |
| `GroupJog.readP_PCS.Position.c.Z` | 在工件座標系（PCS）下 Z 位置 |
| `GroupJog.readV_PCS.Velocity.c.Z`、`readA_PCS.Acceleration.c.Z`、`readJ_PCS.Jerk.c.Z` | Jog 過程中的速度、加速度與 Jerk |

這些變數有助於在示波器中分析 Jog 行為是否平順、是否符合期望加減速曲線。

---

## 三、控制流程：由淺入深

### 3.1 整體流程概觀（`PLC_PRG`）

1. 根據 `iCoordSystem` 選擇 Jog 使用的座標系（ACS/MCS/WCS/TCS）。  
2. 在狀態 0～6 啟動軸組並設定工具座標（Tool Offset）與機器人座標系（MCS）。  
3. 進入狀態 10 之後，啟用 `GroupJog2`，開始接受 Forward/Backward 按鍵命令。  
4. 在狀態 20 監控 Jog 狀態與錯誤，必要時可透過 `MoveTo` 命令暫停 Jog，改用點對點運動（mda）移動到指定姿態。  
5. 狀態 900/1000 對應錯誤處理與重置機制，確保在 GroupErrorStop 與一般錯誤情境下都能安全回到可 Jog 的狀態。

### 3.2 Jog 功能流程（`GroupJog2`）

1. 在狀態 10 設定 <span class="cfg-local">jog2</span> 的各種參數：  
   - <span class="cfg-arg">CoordSystem</span>、<span class="cfg-arg">ABC_as_ACS</span>、<span class="cfg-arg">MaxLinearDistance</span>、<span class="cfg-arg">MaxAngularDistance</span>。  
   - <span class="cfg-arg">Velocity</span>、<span class="cfg-arg">Acceleration</span>、<span class="cfg-arg">Deceleration</span>、<span class="cfg-arg">Jerk</span>，以及各自的 Factor。  
2. 透過 <span class="cfg-func">MC_GroupReadActualPosition()</span> 取得目前的運動學設定，並用 <span class="cfg-func">SMC_SetKinConfiguration()</span> 設定給 jog2，確保 Jog 與當前姿態一致。  
3. 在狀態 30 監控參數變化與錯誤，若 Jog 期間變更了重要參數（例如 Velocity、MaxLinearDistance 等），會自動 Disable 再重啟 jog2。  
4. 在狀態 50～60 使用 <span class="cfg-func">MC_GroupHalt()</span> 完成平滑停止，讓 Done 訊號反映「已安全停止 Jog」。

---

## 四、各支程式負責哪些功能？（由淺入深）

### 4.1 `GroupJog2.st` — Jog 功能封裝

- **類型**：<span class="cfg-keyword">PROGRAM</span>。  
- **職責**：
  - 負責呼叫底層 <span class="cfg-func">SMC_GroupJog2()</span>，並以額外狀態機管理 Enable／Halt／Reset 行為。  
  - 將 Forward / Backward 按鍵陣列與附加軸 Jog 命令轉換為對 `AxisGroup` 的連續運動。  
- **對外介面**：  
  - 輸出 `Active`、`Done`、`Error`、`ErrorID` 反映 Jog 狀態。  
  - 輸出 `CurrentPosition` 與 `CurrentAdditionalAxesPositions`，供上層程式與視覺化使用。

### 4.2 `PLC_PRG.st` — 系統整合及視覺化資料提供

- **類型**：<span class="cfg-keyword">PROGRAM</span>。  
- **職責**：
  - 完成軸組上電、工具座標設定與 MCS 座標系設定。  
  - 呼叫 `GroupJog2`，並將操作者輸入的 Forward/Backward／AdditionalAxesForward/Backward 陣列轉交給 Jog 功能塊。  
  - 產生 Depictor 所需的 `DepictorFrame` 資料，用於畫面呈現機器人與附加軸的位置與姿態。  
- **Error 處理**：  
  - 透過 `MC_GroupReadStatus`、`MC_GroupReadError` 與 `MC_GroupReset` 管理 AxisGroup 的錯誤與復歸流程。  
  - 在錯誤發生時更新 `statusText`，顯示錯誤代碼與文字說明。

---

## 五、函式庫與函式／功能塊一覽（用途、引數、回傳）

### 5.1 函式庫（對照 `Libraries.md`）

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | 基本運動控制與群組控制功能塊 |
| <span class="cfg-name">#SM3_Basic_Visu</span> | 對應 Depictor 與視覺元件的輔助功能 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 用於路徑與凸輪建構（本範例主要聚焦 Jog） |
| <span class="cfg-name">#SM3_CNC</span> | CNC 與路徑控制相關功能（本範例中僅作為相依庫） |

### 5.2 Jog 相關功能塊

- <span class="cfg-func">SMC_GroupJog2()</span>（隱含在 `jog2` 實例中）  
  - **用途**：提供群組 Jog 控制，支援多軸同時 Jog。  
  - 由 `GroupJog2` 進一步包裝，避免在主程式中直接操作所有 Jog 細節。

- <span class="cfg-func">MC_GroupHalt()</span>（<span class="cfg-local">halt</span>）  
  - **用途**：在停用 Jog 時，以設定的 Deceleration 與 Jerk 執行平滑停止。  

- <span class="cfg-func">MC_GroupReadActualPosition()</span>（<span class="cfg-local">grap</span>）  
  - **用途**：讀取當前實際位置，用於初始化 `setConfig.ConfigData`。

- <span class="cfg-func">SMC_SetKinConfiguration()</span>（<span class="cfg-local">setConfig</span>）  
  - **用途**：將目前運動學設定灌入 Jog 功能塊，確保 Jog 以正確的配置運作。

---

## 六、變數與常數一覽

### 6.1 `GroupJog2` 的重要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">jog2</span> | <span class="cfg-type">SMC_GroupJog2</span> | 實際執行 Jog 的 SoftMotion 功能塊 |
| <span class="cfg-local">state</span> | <span class="cfg-type">UDINT</span> | `GroupJog2` 外層狀態機目前狀態 |
| <span class="cfg-local">EnableOld</span> | <span class="cfg-type">BOOL</span> | 偵測 Enable 上升／下降緣 |

### 6.2 `PLC_PRG` 的重要變數（節錄）

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">Forward</span>, <span class="cfg-local">Backward</span> | <span class="cfg-type">ARRAY[..] OF BOOL</span> | 六軸正／反向 Jog 按鍵狀態 |
| <span class="cfg-local">AdditionalAxesForward</span>, <span class="cfg-local">AdditionalAxesBackward</span> | <span class="cfg-type">ARRAY[..] OF BOOL</span> | 兩個附加軸的 Jog 按鍵陣列 |
| <span class="cfg-local">Velocity</span>, <span class="cfg-local">Acceleration</span>, <span class="cfg-local">Deceleration</span>, <span class="cfg-local">Jerk</span> | <span class="cfg-type">LREAL</span> | Jog 的基本運動參數 |
| <span class="cfg-local">VelFactor</span>, <span class="cfg-local">AccFactor</span>, <span class="cfg-local">JerkFactor</span> | <span class="cfg-type">LREAL</span> | 用於比例調整的因子 |
| <span class="cfg-local">MaxLinearDistance</span>, <span class="cfg-local">MaxAngularDistance</span> | <span class="cfg-type">LREAL</span> | 單次 Jog 的最大位移與角度 |
| <span class="cfg-local">state</span> | <span class="cfg-type">UDINT</span> | `PLC_PRG` 主狀態機，用於啟動、錯誤處理等 |

本範例未標記 RETAIN／PERSISTENT，所有變數於斷電後不保留。

---

## 七、特別的演算法與觀念

### 7.1 Jog 與座標系的關係

透過參數 <span class="cfg-local">cs</span>，Jog 可以在不同座標系下運作：

- <span class="cfg-name">ACS</span>：在各軸自身的關節座標中 Jog。  
- <span class="cfg-name">MCS</span>：在機械座標（通常以機器人基座為原點）中 Jog。  
- <span class="cfg-name">WCS</span> / <span class="cfg-name">TCS</span>：在世界／工具座標中 Jog。

這對初學者來說很重要：同一個「向前」按鍵，在不同座標系下的實際運動方向可能完全不同。

### 7.2 外層狀態機包裝 Jog 功能

`GroupJog2` 不只是單純呼叫 <span class="cfg-func">SMC_GroupJog2()</span>，而是加上：

- 參數一致性檢查（若 Jog 過程中改變 Velocity 等，就重新初始化）。  
- 安全停止流程（先停用 Jog，再用 Halt 完成減速）。  
- 錯誤狀態輸出（Error 與 ErrorID）。

這種設計讓 `PLC_PRG` 可以只關注「何時啟用 Jog」「何時停止」，而不需要處理過多細節。

---

## 八、建議閱讀與修改順序

1. 先閱讀本說明，掌握整體 Jog 架構與軸配置。  
2. 查看 `TaskConfiguration.md`、`DeviceTree_Axes.md`，確認 MainTask、軸與軸組的設定。  
3. 打開 `GroupJog2.st`，專注理解 Jog 外層狀態機與 <span class="cfg-func">SMC_GroupJog2()</span> 的關係。  
4. 再閱讀 `PLC_PRG.st`，看它如何：  
   - 啟動軸組與設定工具座標；  
   - 呼叫 `GroupJog2` 並處理錯誤與 Depictor。  
5. 最後使用 Trace 觀察 Z 軸位置／速度與 `GroupJog.state` 的變化，驗證你對 Jog 流程的理解。

若要進一步修改，可從調整 Jog 速度／最大距離等參數開始，再延伸到改變座標系或新增更多 Jog 模式。

---

## 九、名詞對照

| 英文／符號 | 說明 |
|-----------|------|
| <span class="cfg-name">Jog</span> | 手動點動，多用於教導或試動機器人 |
| <span class="cfg-name">AxisGroup</span> | 軸組，由多個軸組成，作為 Jog 與群組運動的操作單位 |
| <span class="cfg-name">PCS/MCS/WCS/TCS</span> | 工件／機械／世界／工具座標系 |
| <span class="cfg-name">Depictor</span> | SoftMotion 提供的可視化框架，用於在視圖中顯示機器人姿態 |

---
