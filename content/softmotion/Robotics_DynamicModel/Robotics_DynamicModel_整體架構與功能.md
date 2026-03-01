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

# Robotics_DynamicModel — 整體架構與功能說明

---

## 一、這個專案在做什麼？（一句話＋情境）

這個範例示範如何為一台 3 軸 Scara+Z 機器人建立**自訂動力學模型**，並透過三種測試情境比較「無扭矩限制」、「有限扭矩」、「加掛負載」時，軸的速度、加速度與扭矩表現有什麼差異。  
可以把它看成「給機器人加上一個真實物理世界的大腦」，讓控制器在規劃運動時能考慮慣性與負載，而不只是幾何位置。

---

## 二、使用情境與硬體／軸架構

### 2.1 任務與程式對應（對照 `TaskConfiguration.md`）

| 任務名稱 | 類型 | 週期 | 優先權 | 執行的 POU |
|----------|------|------|--------|------------|
| MainTask | Cyclic | t#20ms | 1 | `PLC_PRG`, `DynModel_Tests` |
| SoftMotion_PlanningTask | Freewheeling | t#2ms | 15 | - |

- <span class="cfg-name">MainTask</span> 是核心：同時執行動力學測試狀態機 `PLC_PRG` 與單元測試程式 `DynModel_Tests`。  
- <span class="cfg-name">SoftMotion_PlanningTask</span> 在本範例中僅作為規劃用途的基礎設定，主要邏輯都在 MainTask。

### 2.2 軸與裝置結構（對照 `DeviceTree_Axes.md`）

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| A1 | SM_Drive_Virtual | - |
| A2 | SM_Drive_Virtual | - |
| Z  | SM_Drive_Virtual | - |

- <span class="cfg-name">A1</span>、<span class="cfg-name">A2</span>：Scara 機器人的兩個旋轉關節軸。  
- <span class="cfg-name">Z</span>：垂直線性軸。  
三軸組成一個簡化的 Scara+Z 結構，提供給動力學模型 `DynModel_Scara2_Z` 使用。

### 2.3 Trace 與觀察點（對照 `TraceConfig.md`）

Trace 主要監看三軸的速度、加速度與扭矩：

- `A1.fSetVelocity`、`A2.fSetVelocity`、`Z.fSetVelocity`  
- `A1.fSetAcceleration`、`A2.fSetAcceleration`、`Z.fSetAcceleration`  
- `A1.fSetTorque`、`A2.fSetTorque`、`Z.fSetTorque`  

建議在觀察時，先看「無扭矩限制」的運動，再比對「有限扭矩」與「加掛負載」時這些量的變化。

---

## 三、控制流程：由淺入深（對照 `PLC_PRG.st`）

### 3.1 測試情境概觀

`PLC_PRG` 透過列舉型別 <span class="cfg-type">TorqueLimitationDemoStates</span> 形成狀態機，依序執行三種測試：

1. **Unlimited Torque**：  
   - 軸的扭矩上限設為無窮大，只受速度／加速度／Jerk 限制。  
   - 觀察在理想情況下，軸可達到的動態表現。
2. **Limited Torque**：  
   - 對 A2 軸設置明確的扭矩上限（例如 2 Nm）。  
   - 觀察在相同運動目標下，速度與加速度如何被限制，扭矩曲線如何被「切頂」。
3. **Movement With Load**：  
   - 對 Z 軸掛上負載（質量與慣性），模擬末端工具或工件。  
   - 觀察負載對扭矩需求與速度曲線的影響。

### 3.2 `PLC_PRG` 狀態機重點

- **PowerAxisGroup**：  
  - 使用 <span class="cfg-func">SMC_GroupPower()</span> 啟動軸組，並確認 `groupPower.Status` 為 TRUE。  
  - 之後切換到 `InitializeDynamicModel`。

- **InitializeDynamicModel**：  
  - 呼叫 `dynModel.Init()` 初始化 `DynModel_Scara2_Z`。  
  - 將 `dynModel` 指定給 <span class="cfg-func">SMC_GroupSetDynamics()</span> 的 `Dynamics`，並設定重力加速度向量。  

- **InitializeTestMovement**：  
  - 根據 `currentTestMovement`（0 或 1）從 `TEST_MOVEMENT_*` 常數中選出起點 `start` 與目標 `destination`。  
  - 初始時先將負載設為 `ZERO_LOAD`，並呼叫 <span class="cfg-func">SMC_GroupSetLoad()</span> 套用。  

- **InitializeUnlimitedTorqueMovement → ExecuteUnlimitedTorqueMovement**：  
  - 將三軸的軸限制設為 `DEFAULT_*_AXIS_LIMITS`（扭矩上限為正無窮大）。  
  - 使用 `ResetRobotPosition()` 將機器人拉回起點。  
  - 之後呼叫 `moveDirectAbs` 讓軸以 Direct 方式移動到 `destination`。  

- **InitializeLimitedTorqueMovement → ExecuteLimitedTorqueMovement**：  
  - 在原本限制基礎上，將第二軸（A2）的 `maxTorque` 設為 2 Nm。  
  - 再次回到起點，執行相同的目標運動，觀察扭矩受限時的動態差異。

- **InitializeMovementWithLoad → ExecuteMovementWithLoad**：  
  - 以 `LOAD` 結構設定 Z 軸負載（質量與慣性矩）。  
  - 再次從起點移動到 `destination`，觀察負載對扭矩與速度的影響。  

- **FinalizeTestMovement → DemoFinished**：  
  - 切換 `currentTestMovement`，若尚有第二組測試，重複上述流程；  
  - 全部測試完成後進入 `DemoFinished`。

---

## 四、各支程式負責哪些功能？（由淺入深）

### 4.1 `DynModel_Scara2_Z.st` — Scara+Z 動力學模型

- **類型**：<span class="cfg-keyword">FUNCTION_BLOCK</span>，實作 <span class="cfg-type">SMDYN.ISMDynamics</span>。  
- **職責**：
  - 定義 Scara+Z 機器人的幾何與質量分佈（m_aM, m_aG）。  
  - 定義關節螺旋軸（m_aS），讓動力學計算器知道每個關節的旋轉／平移方向。  
  - 提供給 <span class="cfg-func">SMC_GroupSetDynamics()</span> 使用，作為整個軸組的動力學基礎。

### 4.2 `DynModel_Tests.st` 與 `Test_DynModel_Scara2_Z.st`

- **`DynModel_Tests.st`（PROGRAM）**：  
  - 以簡單狀態機呼叫 `tester.CheckScrewAxis()` 與 `tester.CheckStandstillTorque()`。  
  - 根據測試結果輸出 `successful` 與 `error`，方便在視覺化或監控畫面上一眼看出模型是否通過測試。

- **`Test_DynModel_Scara2_Z.st`（FUNCTION_BLOCK）**：  
  - 實際實作測試邏輯，例如：  
    - 比對螺旋軸是否與幾何設定一致；  
    - 檢查機器人在靜止時、給定特定姿態下的理論扭矩是否合理。

### 4.3 其他數學與工具類 FUNCTION_BLOCK

如 `TwistVec_Add`、`TwistVec_Scale`、`Twist_Bracket_Twist`、`Twist_Bracket_Wrench`、`WrenchVec_Add`、`WrenchVec_Sub`、`Wrench_Dot_Twist` 等，  
主要提供「扭轉向量（Twist）」與「力矩向量（Wrench）」運算的基本積木，供動力學計算過程使用。  
在閱讀時，可把它們當成「矩陣／向量運算函式庫」，不必一開始就深入每一行實作。

---

## 五、函式庫與函式／功能塊一覽（用途、引數、回傳）

### 5.1 函式庫（對照 `Libraries.md`）

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | SoftMotion 基本運動控制與群組控制功能塊 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 提供軌跡／凸輪等高階路徑工具（本範例主角是動力學模型） |

### 5.2 範例中常用的關鍵功能塊

- <span class="cfg-func">SMC_GroupPower()</span> / <span class="cfg-func">MC_GroupEnable()</span>：啟動軸組。  
- <span class="cfg-func">SMC_GroupSetDynamics()</span>：將 `DynModel_Scara2_Z` 套用到軸組。  
- <span class="cfg-func">SMC_GroupSetLoad()</span>：設定末端或軸上的負載質量與慣性。  
- <span class="cfg-func">MC_MoveDirectAbsolute()</span>：在 ACS 中執行直接移動，用於三種測試情境的主要運動。  
- <span class="cfg-func">SetAxisLimits()</span>（自訂 FB）：集中設定各軸的速度、加速度、Jerk 與扭矩上限。

---

## 六、變數與常數一覽（重點節錄）

### 6.1 測試相關常數（`PLC_PRG.st`）

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| <span class="cfg-const">TEST_MOVEMENT_COUNT</span> | <span class="cfg-type">UINT</span> | 2 | 測試路徑組數量 |
| <span class="cfg-const">LOAD_MASS</span> | <span class="cfg-type">LREAL</span> | 3 | 掛載在 Z 軸的負載質量（kg） |
| <span class="cfg-const">LOAD_LENGTH</span> | <span class="cfg-type">LREAL</span> | 0.2 | 負載長度（m），用於計算慣性矩 |
| <span class="cfg-const">LOAD</span> | <span class="cfg-type">SMC_DynLoad</span> | 見程式 | 模擬細桿負載的動力學參數 |
| <span class="cfg-const">ZERO_LOAD</span> | <span class="cfg-type">SMC_DynLoad</span> | 全零 | 無負載情境 |

### 6.2 軸限制常數

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| <span class="cfg-const">DEFAULT_REVOLUTE_AXIS_LIMITS</span> | <span class="cfg-type">AxisLimits</span> | 見程式 | 旋轉軸預設速度／加速度／Jerk／扭矩上限 |
| <span class="cfg-const">DEFAULT_PRISMATIC_AXIS_LIMITS</span> | <span class="cfg-type">AxisLimits</span> | 見程式 | 線性軸預設限制 |

---

## 七、特別的演算法與觀念

### 7.1 動力學模型與控制器的分工

在這個範例中，`DynModel_Scara2_Z` 負責提供「機械本體」的物理特性，控制器本身（例如 `MC_MoveDirectAbsolute`）則負責產生軌跡。  
透過 <span class="cfg-func">SMC_GroupSetDynamics()</span> 與 <span class="cfg-func">SMC_GroupSetLoad()</span>，控制器在規劃加速度與扭矩時會考慮這些特性，  
讓模擬結果更接近真實機台。

### 7.2 扭矩限制與負載的影響

比較三種情境時，可以從 Trace 中觀察：

- 無扭矩限制：速度與加速度曲線較「尖銳」，扭矩可達較大峰值。  
- 扭矩受限：為了不超過 `maxTorque`，控制器會自動降低加速度，使扭矩曲線被「壓平」。  
- 有負載：在同樣限制下，為了帶動更重的負載，扭矩更接近上限，速度與加速度可能進一步被削弱。

---

## 八、重要參數與設定位置（實作時對照）

- 任務週期：見 `TaskConfiguration.md`（MainTask t#20ms，會影響模擬時間解析度）。  
- 軸限制：`SetAxisLimits.st` 與 `PLC_PRG.st` 中的 `DEFAULT_*_AXIS_LIMITS`。  
- 負載參數：`LOAD_*` 常數與 `LOAD` 結構，可依實際機構修改質量與幾何尺寸。

---

## 九、建議閱讀與修改順序

1. 先閱讀本說明，掌握三種測試情境與範例目的。  
2. 打開 `TaskConfiguration.md`、`DeviceTree_Axes.md`，確認任務週期與軸名稱。  
3. 閱讀 `DynModel_Scara2_Z.st`，理解幾何與質量定義的大致結構。  
4. 閱讀 `DynModel_Tests.st` 與 `Test_DynModel_Scara2_Z.st`，確認模型測試內容。  
5. 最後閱讀 `PLC_PRG.st`，專注在狀態機如何組合「無限制」、「有限扭矩」、「加掛負載」三種流程。  
6. 使用 Trace 比較三種情境下的速度／加速度／扭矩曲線，體會動力學模型對運動的影響。

---

## 十、名詞對照

| 英文／符號 | 說明 |
|-----------|------|
| <span class="cfg-name">Scara</span> | 一種兩旋轉一線性的平面關節機器人結構 |
| <span class="cfg-name">Twist</span> | 描述剛體瞬時運動（角速度＋線速度）的 6 維向量 |
| <span class="cfg-name">Wrench</span> | 描述力與力矩的 6 維向量 |
| <span class="cfg-name">Dynamics</span> | 動力學，關係「力／扭矩」與「加速度」的模型 |

---
