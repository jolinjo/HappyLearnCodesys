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

# CustomKinematics_Implementation — 整體架構與功能說明

---

## 一、這個專案在做什麼？（一句話＋情境）

這個範例示範如何在 CODESYS SoftMotion 中實作 **自訂運動學（Gantry3C）**，並將它與 Jog 功能及 2D/3D 視覺化整合在一起。  
從使用者的角度來看，就是透過畫面上的 Jog 按鍵，在「關節空間」和「笛卡兒空間」之間自由切換，控制一台 Gantry3C 機台，並在畫面上即時看到 TCP 的位置。

---

## 二、使用情境與硬體／軸架構

### 2.1 任務與程式對應（對照 `TaskConfiguration.md`）

| 任務名稱 | 類型 | 週期 | 優先權 | 執行的 POU |
|----------|------|------|--------|------------|
| MainTask | Cyclic | t#20ms | 1 | `Prg_Visu` |
| SoftMotion_PlanningTask | Cyclic | t#2ms | 15 | - |

`Prg_Visu` 是整個範例的核心：MainTask 每個週期會執行軸組啟動、Jog 邏輯與視覺化計算。

### 2.2 軸與裝置結構（對照 `DeviceTree_Axes.md`）

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| DriveX | SM_Drive_Virtual | - |
| DriveZ | SM_Drive_Virtual | - |
| DriveY | SM_Drive_Virtual | - |
| DriveC | SM_Drive_Virtual | - |

這四個軸對應到 Gantry3C 的平面三軸加上旋轉（C 軸），範例中假設它們隸屬於同一個 AxisGroup，由自訂運動學負責將這些關節位置轉成 TCP 位置。

---

## 三、控制流程：由淺入深

### 3.1 `Prg_Visu` 的整體流程

在 `Prg_Visu` 中：

1. 使用 <span class="cfg-func">SMC_GroupPower()</span>（變數 <span class="cfg-local">gpow</span>）上電軸組，並在其 `Status` 為 TRUE 時，啟動 <span class="cfg-func">MC_GroupEnable()</span>（<span class="cfg-local">gen</span>）。  
2. 一旦 AxisGroup 啟用完成，程式進入穩定狀態，持續呼叫：
   - `jog(AxisGroup := AxisGroup)`：處理來自視覺的 Jog 輸入。  
   - `mla(AxisGroup := AxisGroup)`、`mda(AxisGroup := AxisGroup)`：提供線性與 Direct 的移動指令介面。  
   - `Gantry3C_Visu_Calc(...)`：根據四個 Drive 軸的實際位置計算 TCP 位置，並正規化後送給視覺模板。

整體來說，`Prg_Visu` 就是一個「測試與視覺展示殼程式」，把軸組啟動、Jog 與視覺化串在一起。

### 3.2 `Jog` 的雙 Jog 通道

`Jog` 功能塊同時包含兩個 <span class="cfg-func">SMC_GroupJog2()</span> 實例：

- <span class="cfg-local">jog_mcs</span>：  
  - `CoordSystem := SMC_COORD_SYSTEM.MCS`，用來在笛卡兒空間（TCP）中 Jog。  
  - `Forward[0..5]` 與 `Backward[0..5]` 對應到 `Jog_TCP_Xp/Xn`、`Jog_TCP_Yp/Yn`、`Jog_TCP_Zp/Zn`、`Jog_TCP_Ap/An`、`Jog_TCP_Bp/Bn`、`Jog_TCP_Cp/Cn`。  
- <span class="cfg-local">jog_axes</span>：  
  - `CoordSystem := SMC_COORD_SYSTEM.ACS`，用來在關節座標中 Jog。  
  - `Forward/Backward[0..3]` 對應到 `Jog_Drive_X*`、`Jog_Drive_Y*`、`Jog_Drive_Z*`、`Jog_Drive_C*`。  

視覺介面的按鍵只要設好對應變數，就能透過這個 FB 同時得到 TCP Jog 與關節 Jog 的能力。

### 3.3 `SMC_TRAFOF_Gantry3C` 的計算流程

`SMC_TRAFOF_Gantry3C` 負責：

1. 讀取 DriveX/Y/Z/C 的實際位置並扣除 offset，得到 TCP 在 X/Y/Z/C 上的絕對位置（dx, dy, dz, dAzimuth）。  
2. 以 minX/maxX 等設定，計算出一個最大絕對值 `dm` 作為正規化基準。  
3. 將實際位置除以 `dm`，得到介於 -1..1 的正規化值，便於視覺模板繪製。  

這個 FB 不直接控制運動，而是為視覺化與後續運算提供「從關節到 TCP」的座標映射。

---

## 四、各程式與功能塊負責哪些功能？

### 4.1 `Jog.st` — Jog 介面封裝

- **類型**：<span class="cfg-keyword">FUNCTION_BLOCK</span>。  
- **職責**：
  - 收集來自視覺的 Jog 輸入，分別寫入 `jog_mcs` 的 Forward/Backward（TCP Jog）與 `jog_axes` 的 Forward/Backward（關節 Jog）。  
  - 持續呼叫兩個 SMC_GroupJog2 實例，讓軸組依照最新的按鍵狀態更新運動。  

### 4.2 `Prg_Visu.st` — 測試與視覺整合程式

- **類型**：<span class="cfg-keyword">PROGRAM</span>。  
- **職責**：
  - 啟動並 Enable AxisGroup。  
  - 呼叫 Jog 與 Gantry3C_Visu_Calc FB。  
  - 提供基本 MoveLinear / MoveDirect 介面（`mla`、`mda`）供使用者在視覺中發命令。  

### 4.3 `SMC_TRAFOF_Gantry3C.st` — TCP 位置與正規化計算

- **類型**：<span class="cfg-keyword">FUNCTION_BLOCK</span>。  
- **職責**：
  - 將四個關節軸的實際位置轉成 TCP 位置（dx/dy/dz/dAzimuth）。  
  - 根據顯示範圍設定把 TCP 位置正規化，提供給視覺模板作為輸入。

---

## 五、函式庫與函式／功能塊一覽

### 5.1 函式庫（對照 `Libraries.md`）

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | SoftMotion 基本功能塊（GroupPower、GroupEnable、Jog、Move* 等） |
| <span class="cfg-name">#SM3_CamBuilder</span> | 提供路徑建構與可視化輔助（本範例主要聚焦自訂運動學與 Jog） |

### 5.2 重要功能塊

- <span class="cfg-func">SMC_GroupPower()</span> / <span class="cfg-func">MC_GroupEnable()</span>：啟動與啟用 AxisGroup。  
- <span class="cfg-func">SMC_GroupJog2()</span>：由 `jog_mcs` 與 `jog_axes` 內部使用，實際執行 Jog。  
- <span class="cfg-func">MC_MoveLinearAbsolute()</span>（mla）與 <span class="cfg-func">MC_MoveDirectAbsolute()</span>（mda）：提供對 TCP 或關節的移動命令。  

---

## 六、變數與常數一覽（重點）

由於範例未使用 GVL 定義大量全域常數，這裡僅列出部分關鍵變數：

| 所在 POU | 名稱 | 型態 | 說明 |
|----------|------|------|------|
| `Jog` | <span class="cfg-local">jog_mcs</span> | <span class="cfg-type">SMC_GroupJog2</span> | 在 MCS 下 Jog TCP |
| `Jog` | <span class="cfg-local">jog_axes</span> | <span class="cfg-type">SMC_GroupJog2</span> | 在 ACS 下 Jog 軸 |
| `Prg_Visu` | <span class="cfg-local">gpow</span> | <span class="cfg-type">SMC_GroupPower</span> | 軸組電源控制 |
| `Prg_Visu` | <span class="cfg-local">gen</span> | <span class="cfg-type">MC_GroupEnable</span> | 軸組啟用控制 |
| `Prg_Visu` | <span class="cfg-local">Gantry3C_Visu_Calc</span> | <span class="cfg-type">SMC_TRAFOF_Gantry3C</span> | TCP 座標與正規化計算 |

本專案未設定 Trace；如需觀察實際位置，可自行加入 GroupReadActualPosition / Velocity 等 FB。

---

## 七、特別的觀念與設計重點

### 7.1 自訂運動學與 Jog 的協作

在這個範例中，自訂運動學的重點不在「求逆解程式碼」，而在於「如何把它和使用者介面連在一起」：  
Jog FB 負責解讀使用者按鍵，SMC_TRAFOF_Gantry3C 負責將機構位置轉成視覺化需要的 TCP 座標，  
Prg_Visu 則是把所有東西串接起來、並負責啟動與維持 AxisGroup 的運作。

### 7.2 介面設計：Forward / Backward 陣列

`Jog` 使用 Forward / Backward 陣列承接所有 Jog 按鍵，這種設計能讓你在未來：

- 很容易擴充新的 Jog 方向或模式（只要再增加索引與對應按鍵）。  
- 將視覺層與運動學層清楚分離（視覺只寫變數，實際運動由 Jog FB 處理）。

---

## 八、重要參數與設定位置

- 任務週期：見 `TaskConfiguration.md`（MainTask 20 ms），影響 Jog 與視覺更新頻率。  
- 軸設定：見 `DeviceTree_Axes.md` 中各 Drive 軸的定義。  
- Jog 速度／加速度／Jerk 等參數：在 `Jog` 中初始化 `jog_mcs`／`jog_axes` 時給定，可視為自訂 kinematics 的「預設 Jog 手感」。

---

## 九、建議閱讀與修改順序

1. 先閱讀本說明，了解整體用途與架構。  
2. 查看 `DeviceTree_Axes.md`，確認四個 Drive 軸的實際對應。  
3. 閱讀 `Prg_Visu.st`，看懂 AxisGroup 啟動、Jog 與 Gantry3C_Visu_Calc 如何串起來。  
4. 閱讀 `Jog.st`，重點放在兩個 SMC_GroupJog2 與 Forward/Backward 陣列的設計。  
5. 最後閱讀 `SMC_TRAFOF_Gantry3C.st`，理解如何從關節座標算出 TCP 位置與視覺化座標。

---

## 十、名詞對照

| 英文／符號 | 說明 |
|-----------|------|
| <span class="cfg-name">Gantry3C</span> | 一種三線性加旋轉的龍門式機構 |
| <span class="cfg-name">TCP</span> | Tool Center Point，工具中心點位置 |
| <span class="cfg-name">ACS</span> | Axis Coordinate System，關節座標系 |
| <span class="cfg-name">MCS</span> | Machine Coordinate System，機械座標系 |

---
