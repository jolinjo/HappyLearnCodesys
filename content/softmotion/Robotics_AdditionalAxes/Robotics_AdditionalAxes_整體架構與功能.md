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

# Robotics_AdditionalAxes — 整體架構與功能說明

---

## 一、這個專案在做什麼？（一句話＋情境）

這個範例示範如何在同一個軸組中，同時控制「主軸（例如 X/Y/Z）」與「附加軸」（例如外部滑台或旋轉工作台），  
並在一條路徑內讓主軸與附加軸以對應的距離變化協同運動。  
你可以把它想成：主機器人在平面上畫一條路徑的同時，兩個夾具軸跟著伸縮或旋轉，配合完成工件處理。

---

## 二、使用情境與硬體／軸架構

### 2.1 任務與程式對應（對照 `TaskConfiguration.md`）

| 任務名稱 | 類型 | 週期 | 優先權 | 執行的 POU |
|----------|------|------|--------|------------|
| MainTask | Cyclic | t#4ms | 1 | `PLC_PRG` |
| SoftMotion_PlanningTask | Cyclic | t#2ms | 15 | - |

- 所有運動指令與量測都在 `PLC_PRG` 中完成。  
- 第二個任務目前僅保留作為規劃用途的基礎設定，主要邏輯集中在 MainTask。

### 2.2 軸與裝置結構（對照 `DeviceTree_Axes.md`）

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| Drive1 | SM_Drive_Virtual | - |
| Drive2 | SM_Drive_Virtual | - |
| DriveZ | SM_Drive_Virtual | - |
| DriveAdd1 | SM_Drive_Virtual | - |
| DriveAdd2 | SM_Drive_Virtual | - |

- 可以把 <span class="cfg-name">Drive1 / Drive2 / DriveZ</span> 想成主機器人的三個自由度。  
- <span class="cfg-name">DriveAdd1 / DriveAdd2</span> 則是附加的直線或旋轉軸，用來帶動夾具、工作台或其他外部機構。  
所有這些軸都隸屬於同一個 AxisGroup，由 `PLC_PRG` 一起下達運動指令。

### 2.3 Trace 與觀察點（對照 `TraceConfig.md`）

Trace 關注的是主軸與附加軸的位置與速度：

- `PLC_PRG.readPos.Position.c.X/Y`：主軸在 MCS 下的位置。  
- `PLC_PRG.readPos.AdditionalAxesPositions[0/1]`：兩個附加軸的位置。  
- `PLC_PRG.readVel.Velocity.c.X/Y`：主軸速度。  
- `PLC_PRG.readVel.AdditionalAxesVelocities[0/1]`：附加軸速度。

這些變數有助於在示波器中觀察「主軸路徑」與「附加軸動作」之間的配合情形。

---

## 三、控制流程：由淺入深（對照 `PLC_PRG.st`）

雖然本範例 `PLC_PRG` 中的狀態機結構相對簡單，但可以從變數宣告看出基本運動策略：

- <span class="cfg-local">movePTP</span>（<span class="cfg-type">MC_MoveDirectAbsolute</span>）：  
  - 採用 <span class="cfg-name">MCS</span> 座標系與 `Buffered` 模式，可用於點對點移動或回到某個基準位置。  
- <span class="cfg-local">moveLin</span>（<span class="cfg-type">MC_MoveLinearAbsolute</span>）：  
  - Velocity / Acceleration / Deceleration / Jerk 已預先設定，使用 `BlendingHigh` 緩衝模式，適合接續多段路徑。  
- <span class="cfg-local">POS1</span>、<span class="cfg-local">POS2</span>：  
  - 主軸的目標位置（例：\(X=50, Y=50\) 及 \(X=50, Y=-50\)）。  
- <span class="cfg-local">DIST1</span>、<span class="cfg-local">DIST2</span>：  
  - 對應附加軸的相對位移（第一段 \(+10/+20\)，第二段 \(-10/-20\)），用來示範附加軸與主軸在同一路徑上的配合。

在實際執行時，可想像以下流程：

1. 透過 <span class="cfg-func">SMC_GroupPower()</span>（<span class="cfg-local">pw</span>）與 <span class="cfg-func">MC_GroupEnable()</span>（<span class="cfg-local">en</span>）啟動軸組。  
2. 使用 `movePTP` 或 `moveLin` 先把系統移到起始位置。  
3. 依序對 `moveLin` 指定 `POS1`＋`DIST1`、`POS2`＋`DIST2`，讓軸組沿著主軸路徑移動，同時讓附加軸伸縮。  
4. 透過 `readPos`、`readVel` 與 Trace 監看主軸與附加軸的實際位置與速度。

---

## 四、各支程式負責哪些功能？

本範例僅包含一個主要程式：

### 4.1 `PLC_PRG.st` — 主軸＋附加軸運動示範

- **類型**：<span class="cfg-keyword">PROGRAM</span>。  
- **職責**：
  - 啟動並啟用多軸軸組。  
  - 定義兩個主軸路徑點（`POS1`、`POS2`）以及對應的附加軸距離（`DIST1`、`DIST2`）。  
  - 準備 `movePTP` 與 `moveLin`，供外部邏輯或視覺介面呼叫，完成主軸與附加軸的同步移動。  
  - 提供 `readPos`、`readVel` 給 Trace 與視覺化使用。

---

## 五、函式庫與函式／功能塊一覽（用途、引數、回傳）

### 5.1 函式庫（對照 `Libraries.md`）

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | 基本運動控制與群組控制功能塊 |
| <span class="cfg-name">#SM3_Basic_Visu</span> | 視覺輔助相關功能，用於顯示軸狀態 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 路徑／凸輪建構（本範例主要做直線與直接移動） |
| <span class="cfg-name">#SM3_CNC</span> | CNC 相關功能 |

### 5.2 常用功能塊

- <span class="cfg-func">MC_MoveDirectAbsolute()</span>（<span class="cfg-local">movePTP</span>）  
  - **用途**：在 MCS 中做點對點移動，可用於回到基準點或做簡單測試。  

- <span class="cfg-func">MC_MoveLinearAbsolute()</span>（<span class="cfg-local">moveLin</span>）  
  - **用途**：在 MCS 中以指定速度／加速度／Jerk 執行線性運動，可結合附加軸距離實現同步運動。  

- <span class="cfg-func">MC_GroupReadActualPosition()</span>（<span class="cfg-local">readPos</span>）  
  - **用途**：同時讀取主軸與附加軸的位置。  

- <span class="cfg-func">MC_GroupReadActualVelocity()</span>（<span class="cfg-local">readVel</span>）  
  - **用途**：讀取主軸與附加軸速度，供示波器與調試使用。

---

## 六、變數與常數一覽（重點）

### 6.1 位置與距離設定

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| <span class="cfg-local">POS1</span> | <span class="cfg-type">SMC_POS_REF</span> | X=50, Y=50 | 第一個主軸目標點 |
| <span class="cfg-local">POS2</span> | <span class="cfg-type">SMC_POS_REF</span> | X=50, Y=-50 | 第二個主軸目標點 |
| <span class="cfg-local">DIST1</span> | <span class="cfg-type">SMC_ADDITIONAL_AXES_VALUES_ARRAY</span> | [10,20] | 第一段運動時附加軸位移 |
| <span class="cfg-local">DIST2</span> | <span class="cfg-type">SMC_ADDITIONAL_AXES_VALUES_ARRAY</span> | [-10,-20] | 第二段運動時附加軸位移 |

### 6.2 狀態監看變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">Ready</span> | <span class="cfg-type">BOOL</span> | 軸組是否已上電且可接受指令（依實作而定） |
| <span class="cfg-local">readPos</span> | <span class="cfg-type">MC_GroupReadActualPosition</span> | 提供位置給 Trace 與視覺化 |
| <span class="cfg-local">readVel</span> | <span class="cfg-type">MC_GroupReadActualVelocity</span> | 提供速度給 Trace 與視覺化 |

本範例未使用 RETAIN／PERSISTENT。

---

## 七、特別的觀念：附加軸與主軸如何協同

在實務專案中，附加軸常見用途包括：外部滑台、旋轉台、升降平台等。  
這個範例提醒你，設計路徑時要同時考慮：

- 主軸路徑（例如 X/Y 平面的直線或折線）。  
- 附加軸相對於主軸位置的變化（例如在主軸到達某區段時抬高或放低夾具）。  

用 `POS1/POS2`＋`DIST1/DIST2` 這種寫法，可以把兩者的關係寫得很清楚，初學者不容易搞混。

---

## 八、重要參數與設定位置

- 任務週期：見 `TaskConfiguration.md`（MainTask t#4ms），影響控制迴圈頻率。  
- 軸配置：見 `DeviceTree_Axes.md`（哪些軸代表主軸、哪些代表附加軸）。  
- 速度／加速度／Jerk：由 `moveLin` 的初始參數決定，可視為這個範例的「全域運動風格」。

---

## 九、建議閱讀與修改順序

1. 先閱讀本說明，理解主軸與附加軸的角色。  
2. 打開 `DeviceTree_Axes.md`，確認軸名稱與實際裝置對應。  
3. 閱讀 `PLC_PRG.st`：  
   - 注意 `POS1/POS2` 與 `DIST1/DIST2` 的設計；  
   - 看懂 `movePTP` 與 `moveLin` 的初始參數。  
4. 最後搭配 Trace 觀察主軸位置／速度與附加軸位置／速度，思考如何依實際機台需求調整這些參數。

---

## 十、名詞對照

| 英文／符號 | 說明 |
|-----------|------|
| <span class="cfg-name">Additional Axis</span> | 附加軸，通常為外部滑台或旋轉軸 |
| <span class="cfg-name">MCS</span> | 機械座標系，常以機台基座為原點 |
| <span class="cfg-name">Buffered</span> / <span class="cfg-name">BlendingHigh</span> | 緩衝模式，決定多段運動如何銜接 |

---
