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

# CNC14_PathPreprocessing — 整體架構與功能說明

---

## 一、這個專案在做什麼？

本範例示範在 CNC 路徑上套用 **多段前處理**：先用 <span class="cfg-func">SMC_SmoothPath</span> 對路徑做五次樣條平滑（Min Curvature），再透過自訂功能塊 <span class="cfg-custom">LimitTangentVelocity</span> 依曲率限制切線速度，最後再交給 <span class="cfg-func">SMC_CheckVelocities</span> 檢查整體速度。藉由這個流程可以在不更改 G-code 的前提下，同時達到路徑平滑化與速度上限控制。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務配置

對照 `TaskConfiguration.md`：

| 任務名稱 | 類型 | 週期 | 優先權 | POU 清單 |
|----------|------|------|--------|----------|
| MainTask | Cyclic | t#4ms | 1 | `PLC_PRG` |
| Path | Cyclic | t#8ms | 2 | `Path` |

- **Path 任務**：以 8 ms 的週期負責 G-code 解碼與前處理。  
- **MainTask**：以 4 ms 的週期執行插補與三軸控制。

### 2.2 軸與裝置

對照 `DeviceTree_Axes.md`：

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| DriveX | SM_Drive_Virtual | - |
| DriveY | SM_Drive_Virtual | - |
| DriveC | SM_Drive_Virtual | - |

三支虛擬軸可想成 X / Y 線性軸與 C 旋轉軸，`PLC_PRG` 透過 <span class="cfg-func">SMC_TRAFO_GantryCutter2</span> 將插補結果轉換為三軸指令並寫入。

### 2.3 函式庫

`Libraries.md` 顯示本範例使用：

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | 基礎運動控制功能塊。 |
| <span class="cfg-name">#SM3_Basic_Visu</span> | 視覺化輔助。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 凸輪相關。 |
| <span class="cfg-name">#SM3_CNC</span> | CNC 解碼、前處理與插補相關功能塊。 |

---

## 三、控制流程：由淺入深

### 3.1 Path 任務：解碼、平滑與速度限制

`Path` 程式（`Path.st`）流程：

1. **NC 解碼**：  
   - 使用 <span class="cfg-func">SMC_NCDecoder</span> `dec` 讀取 CNC 物件 `ncprog := CNC`，並在緩衝區 `aBufDec` 中產生幾何段佇列。  
2. **路徑平滑（SmoothPath）**：  
   - <span class="cfg-func">SMC_SmoothPath</span> `sp` 接收 `dec.poqDataOut`，設定：  
     - `eMode := SMC_SMOOTHPATHMODE.SP_SPLINE5_MIN_CURVATURE`：使用五次樣條最小曲率模式。  
     - `bSymmetricalDistances := TRUE`、`bImprovedSymmetricCuts := TRUE`：改善前後對稱與切割品質。  
   - 输出佇列使用 `aBufSp` 緩衝。  
3. **切線速度限制（LimitTangentVelocity）**：  
   - 自訂 FB <span class="cfg-custom">LimitTangentVelocity</span> 接上 `sp.poqDataOut`，指定：  
     - `maxAngularVelocity_deg`：切線最大角速度（°/s）。  
     - `featureFlag`：由 G38/G39 控制是否對該段路徑啟用本功能。  
   - 內部會根據曲率計算對應的最大路徑速度並修改 GEOINFO 中的 `dVel`。  
4. **速度檢查（CheckVelocities）**：  
   - <span class="cfg-func">SMC_CheckVelocities</span> `cv` 最終對 `limitTangentVel.poqDataOut` 做速度檢查，輸出插補器可使用的佇列。

Path 任務的輸出即為 `cv.poqDataOut`，供 `PLC_PRG` 內插補器使用。

### 3.2 MainTask：插補與三軸驅動

`PLC_PRG` 程式（`PLC_PRG.st`）流程：

1. 三軸上電：三個 <span class="cfg-func">MC_Power</span> `pwX` / `pwY` / `pwC` 將 `DriveX`、`DriveY`、`DriveC` 啟動。  
2. 插補器：<span class="cfg-func">SMC_Interpolator</span> `ipo`  
   - `bExecute := bStart`（輸入）。  
   - `poqDataIn := Path.cv.poqDataOut`，接收經全部前處理後的路徑佇列。  
   - `iVelMode := SMC_INT_VELMODE.QUADRATIC`、`dwIpoTime := 4000`、`dJerkMax := 10000` 等插補參數。  
3. 機構轉換：  
   - <span class="cfg-func">SMC_TRAFO_GantryCutter2</span> `trafo` 使用 `ipo.piSetPosition` 與 `ipo.vecActTangent`，計算出對 `DriveX` / `DriveY` / `DriveC` 的對應位移 `dx` / `dy` / `dr`。  
4. 三軸位置控制：  
   - 三個 <span class="cfg-func">SMC_ControlAxisByPos</span> `cabpX` / `cabpY` / `cabpC` 將 `trafo.dx/dy/dr` 寫入對應軸。  

Trace 設定中監看 `DriveX/Y/C.fSetPosition`、`fSetVelocity` 與 `PLC_PRG.ipo.dVel` 等變數，有助於觀察前處理對速度與曲線的影響。

---

## 四、各支程式負責哪些功能？

### 4.1 `PLC_PRG.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 三軸上電。  
  - 以 <span class="cfg-func">SMC_Interpolator</span> 消費前處理後的路徑佇列。  
  - 以 <span class="cfg-func">SMC_TRAFO_GantryCutter2</span> 轉換為 X/Y/C 三軸位置。  
  - 以 <span class="cfg-func">SMC_ControlAxisByPos</span> 驅動三軸。  

### 4.2 `Path.st`

- **類型**：PROGRAM。  
- **職責**：  
  - G-code 解碼（<span class="cfg-func">SMC_NCDecoder</span>）。  
  - 路徑平滑（<span class="cfg-func">SMC_SmoothPath</span>）。  
  - 切線速度限制（<span class="cfg-custom">LimitTangentVelocity</span>）。  
  - 速度檢查（<span class="cfg-func">SMC_CheckVelocities</span>）。  
- **輸出**：  
  - `cv.poqDataOut` 為最終路徑佇列，供插補器使用。

### 4.3 `LimitTangentVelocity.st`

- **類型**：FUNCTION_BLOCK（自訂 FB）。  
- **介面**：  
  - 輸入：`Execute`、`poqDataIn`、`nSizeOutQueue`、`pbyBufferOutQueue`、`maxAngularVelocity_deg`、`featureFlag`。  
  - 輸出：`Done`、`Busy`、`Error`、`ErrorID`、`poqDataOut`、`velMin`。  
- **職責**：  
  - 逐一從輸入佇列讀取幾何段（<span class="cfg-type">SMC_GeoInfo</span>），對啟用指定 featureFlag 的段落，計算最大曲率並換算允許的最大路徑速度，修改 `dVel` 後寫入輸出佇列。  
  - 同時維護 `velMin` 以記錄目前最嚴格的速度限制。  
  - 處理 G75 相關 queue synchronization 標記，確保與前後 FB 串接正確。  

### 4.4 `ComputeMaxCurvature.st`

- **類型**：FUNCTION。  
- **介面**：  
  - IN\_OUT：`geo: SMC_GeoInfo`。  
  - 輸出：`kappa: LREAL`。  
- **職責**：  
  - 依 `geo.iMoveType` 決定如何計算最大曲率 `kappa`：  
    - 線段（LIN 系列）→ 曲率 0。  
    - SPLINE 系列 → 使用 <span class="cfg-func">SMC_CalcSplineMinCurvatureRadius</span> 反算曲率。  
    - 圓弧 / 橢圓 → 由半徑或橢圓長短軸推得最大曲率。  
  - 回傳 <span class="cfg-keyword">TRUE</span> / <span class="cfg-keyword">FALSE</span> 表示是否成功計算。

---

## 五、函式庫與函式／功能塊一覽

只列出與理解本範例前處理鏈結有關的主要元件。

| 名稱 | 類別 | 用途 |
|------|------|------|
| <span class="cfg-func">SMC_NCDecoder</span> | FB | 將 CNC 程式 `CNC` 解碼成幾何段佇列。 |
| <span class="cfg-func">SMC_SmoothPath</span> | FB | 對路徑做樣條平滑，降低轉角尖銳度。 |
| <span class="cfg-custom">LimitTangentVelocity</span> | FB | 自訂前處理，依曲率限制切線速度。 |
| <span class="cfg-custom">ComputeMaxCurvature</span> | 函式 | 計算單一幾何段的最大曲率。 |
| <span class="cfg-func">SMC_CheckVelocities</span> | FB | 速度檢查與限制。 |
| <span class="cfg-func">SMC_Interpolator</span> | FB | 從前處理後路徑插補位置與速度。 |
| <span class="cfg-func">SMC_TRAFO_GantryCutter2</span> | FB | 將插補路徑轉換成三軸（X/Y/C）位移。 |
| <span class="cfg-func">SMC_ControlAxisByPos</span> | FB | 依目標位置控制單軸。 |

---

## 六、變數與常數一覽

本範例未使用 RETAIN／PERSISTENT；路徑與前處理狀態皆在執行期由程式維護。

### 6.1 `Path` 重要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">dec</span> | <span class="cfg-type">SMC_NCDecoder</span> | G-code 解碼器。 |
| <span class="cfg-local">sp</span> | <span class="cfg-type">SMC_SmoothPath</span> | 路徑平滑處理。 |
| <span class="cfg-local">limitTangentVel</span> | <span class="cfg-type">LimitTangentVelocity</span> | 自訂速度限制 FB。 |
| <span class="cfg-local">cv</span> | <span class="cfg-type">SMC_CheckVelocities</span> | 最終速度檢查。 |
| <span class="cfg-local">aBufDec</span> / <span class="cfg-local">aBufSp</span> / <span class="cfg-local">aBufLimit</span> | <span class="cfg-type">ARRAY OF SMC_GeoInfo</span> | 各階段輸出緩衝。 |

### 6.2 `LimitTangentVelocity` 重要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">maxAngularVelocity_deg</span> | <span class="cfg-type">LREAL</span> | 允許的最大切線角速度（°/s）。 |
| <span class="cfg-local">featureFlag</span> | <span class="cfg-type">USINT</span> | 對應 G38/G39 的 feature bit，決定哪些段要套用限制。 |
| <span class="cfg-local">m_maxAngularVelocity_rad</span> | <span class="cfg-type">LREAL</span> | 將角速度轉成 rad/s 後的內部使用值。 |
| <span class="cfg-local">m_geo</span> | <span class="cfg-type">SMC_GeoInfo</span> | 正在處理的幾何段副本。 |
| <span class="cfg-local">velMin</span> | <span class="cfg-type">LREAL</span> | 目前看到的最小允許速度，用於統計。 |

---

## 七、特別的演算法與觀念

### 7.1 曲率與速度上限的關係

在 `LimitTangentVelocity` 中，對啟用該 feature 的每一段路徑執行：

1. 透過 <span class="cfg-custom">ComputeMaxCurvature()</span> 計算該段最大曲率 `kappa_max`。  
2. 將 `maxAngularVelocity_deg` 轉為 `m_maxAngularVelocity_rad`。  
3. 若 `kappa_max > 0`，則以  
   \[
   v_\text{max} = \frac{\text{m\_maxAngularVelocity\_rad}}{\kappa_\text{max}}
   \]  
   計算最大路徑速度；若 `kappa_max = 0` 則不限制。  
4. 將 `m_geo.dVel` 改為 `MIN(m_geo.dVel, v_max)`，並寫回輸出佇列。  

這樣可以在曲率大的地方自動降低速度，避免慣量過大或機構超出能力。

### 7.2 前處理鏈結與 G75 支援

`LimitTangentVelocity` 內部還處理與前後 FB 串接相關的控制碼（例如 `MCOMMAND` 與 `iHelpID` 特定值），用來表示 queue synchronization（G75 相關），確保在 Look-Ahead 與 queue 清空時，不會因為前處理而破壞插補器的假設。

---

## 八、重要參數與設定位置

| 參數 | 檔案 / 位置 | 說明 |
|------|-------------|------|
| 任務週期 t#4ms | `TaskConfiguration.md`（MainTask） | 插補與軸控制更新頻率。 |
| 任務週期 t#8ms | `TaskConfiguration.md`（Path） | 解碼與前處理頻率。 |
| `maxAngularVelocity_deg` | `Path.st` 內 `limitTangentVel` 初始值 | 最大切線角速度，直接影響彎曲處的速度上限。 |
| `featureFlag` | 同上 | 指定對哪些路徑段套用速度限制（對應 G-code 內的 feature bit）。 |

---

## 九、建議閱讀與修改順序

1. 先看 `TaskConfiguration.md` 與 `DeviceTree_Axes.md`，理解任務與三軸結構。  
2. 再看 `Path.st`，弄清楚 Decoder → SmoothPath → LimitTangentVelocity → CheckVelocities 的串接方式。  
3. 接著看 `LimitTangentVelocity.st` 與 `ComputeMaxCurvature.st`，了解速度限制的數學邏輯。  
4. 最後看 `PLC_PRG.st`，理解插補與三軸控制如何接上整條前處理鏈。  
5. 實驗時可先調小 `maxAngularVelocity_deg` 觀察速度被壓低的程度，再配合 Trace 檢查軸速度與位置。

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">Path Preprocessing</span> | 路徑前處理，指在插補前對路徑做平滑、補償、速度限制等。 |
| <span class="cfg-name">Tangent Velocity</span> | 沿路徑切線方向的速度。 |
| <span class="cfg-name">Curvature</span> / κ | 曲率，描述路徑彎曲程度，半徑愈小曲率愈大。 |
| <span class="cfg-func">SMC_SmoothPath</span> | SoftMotion 路徑平滑功能塊。 |
| <span class="cfg-custom">LimitTangentVelocity</span> | 本範例自訂前處理 FB，以曲率限制切線速度。 |

