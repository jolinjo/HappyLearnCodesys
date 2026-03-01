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

# BasicMotion_GearInPos — 整體架構與功能說明

---

## 一、這個專案在做什麼？

這個範例示範如何在 CODESYS SoftMotion 中使用 <span class="cfg-func">MC_GearInPos()</span> 功能塊，讓鋸片滑台軸在輸送帶上的工件到達指定位置時與輸送帶同步，並搭配一支刀具軸完成一次安全且可重複的切割動作。  
整個專案僅使用虛擬軸與模擬工件，不需要實體硬體，就可以觀察「工件經過光遮斷器 → 計算同步點 → 鋸片跟隨 → 刀具切入、退回」的完整流程。

---

## 二、使用情境與硬體／通訊架構

在實務上，這類應用常見於「鋸片切割輸送帶上的木料／鋁型材」等場景：工件由輸送帶帶動前進，當通過光遮斷器時，控制器必須預估工件到達切割點的時間與位置，讓鋸片滑台在該位置與輸送帶速度同步，刀具再於適當時機切入完成加工。

在本範例中，三個軸皆為 SoftMotion 虛擬軸（<span class="cfg-name">SM_Drive_Virtual</span>），可想像成實際應用中將會對應到 EtherCAT 伺服驅動器：

| 軸名稱 | 類型 | 角色 | 綁定任務 | 主要使用位置 |
|--------|------|------|----------|--------------|
| <span class="cfg-name">Master</span> | <span class="cfg-name">SM_Drive_Virtual</span> | 輸送帶軸，帶動工件前進 | （由 SoftMotion 內部任務更新） | `PLC_PRG` 中的 <span class="cfg-func">MC_MoveVelocity()</span>、`SimulateWorkpiece` 中的 `Master.fSetPosition` |
| <span class="cfg-name">Slave</span> | <span class="cfg-name">SM_Drive_Virtual</span> | 鋸片滑台軸，沿輸送帶方向移動 | 同上 | `PLC_PRG` 中的 <span class="cfg-func">MC_GearInPos()</span>、<span class="cfg-func">MC_MoveAbsolute()</span> |
| <span class="cfg-name">Tool</span> | <span class="cfg-name">SM_Drive_Virtual</span> | 刀具上下軸，模擬刀具抬升與切入 | 同上 | `PLC_PRG` 中的 <span class="cfg-func">MC_MoveAbsolute()</span> |

任務與程式配置（對照 `TaskConfiguration.md`）如下：

| 任務名稱 | 類型 | 週期 | 優先權 | POU 清單 |
|----------|------|------|--------|----------|
| MainTask | Cyclic | t#4ms | 1 | `SimulateWorkpiece`, `PLC_PRG`, `DepictorCalculation` |

- MainTask 每 4 ms 依序呼叫三個程式，更新工件位置模擬、主控制邏輯與視覺化描繪。  
- 軸與 SoftMotion 內部執行緒透過 SoftMotion 機制與控制任務協同運作，本範例只需要專注在控制流程本身。

全域幾何與同步相關的常數集中在 `GVL_Const.st` 中，例如：
- <span class="cfg-const">SYNCPOS</span>：鋸片應與工件同步的目標 X 位置。  
- <span class="cfg-const">LIGHTBARRIERPOS</span>：光遮斷器的 X 位置。  
- <span class="cfg-const">BELTLENGTH</span>、<span class="cfg-const">WORKPIECELENGTH</span> 等：輸送帶與工件的幾何尺寸。

---

## 三、控制流程：由淺入深

### 3.1 整體流程概觀

用一句話來看，控制流程可以概括為：

> 啟動三軸 → 輸送帶持續運轉 → 模擬工件移動並偵測光遮斷器 → 根據偵測位置計算同步點 → 鋸片滑台與輸送帶同步 → 刀具切入、退回 → 鋸片滑台回待命位置 → 等待下一塊工件。

搭配主程式 `PLC_PRG` 的狀態機 <span class="cfg-local">state</span>，流程依序如下：

1. **STATE\_POWER**：透過三個 <span class="cfg-func">MC_Power()</span> 將 Tool／Master／Slave 軸上電並啟動。  
2. **啟動輸送帶**：當電源狀態皆 OK，呼叫 <span class="cfg-func">MC_MoveVelocity()</span> 讓 <span class="cfg-name">Master</span> 軸以固定速度前進。  
3. **STATE\_WAIT\_FOR\_WORKPIECE**：持續等待 `SimulateWorkpiece.WorkpieceDetected` 變為 TRUE，代表工件通過光遮斷器。  
4. **計算同步點並啟動 GearInPos**：偵測到工件後，計算 <span class="cfg-func">MC_GearInPos()</span> 的 <span class="cfg-arg">MasterSyncPosition</span>、<span class="cfg-arg">SlaveSyncPosition</span>、<span class="cfg-arg">MasterStartDistance</span>，啟動齒輪同步命令。  
5. **STATE\_WAIT\_FOR\_SYNC**：等待 <span class="cfg-func">MC_GearInPos()</span> 回報 InSync，表示鋸片滑台與輸送帶速度已對齊。  
6. **STATE\_MOVE\_TOOL\_0 / STATE\_MOVE\_TOOL\_1**：透過兩段 <span class="cfg-func">MC_MoveAbsolute()</span> 控制 <span class="cfg-name">Tool</span> 軸先下刀（移到帶寬＋刀尖偏移），再抬刀回到原點。  
7. **STATE\_MOVE\_TO\_REST**：驅動 <span class="cfg-name">Slave</span> 軸回到較安全的待命位置，準備下一次切割。  
8. **回到 STATE\_WAIT\_FOR\_WORKPIECE**：等待下一塊工件進入光遮斷器區域。

整體來說，真正影響「何時切、切在哪裡」的，是工件被偵測到的時間點、輸送帶的速度，以及 `GVL_Const` 中的幾個幾何參數與位移距離。

### 3.2 與模擬程式、視覺化的關係

- `SimulateWorkpiece`：模擬工件在輸送帶上移動，並依據光遮斷器位置決定何時輸出 `WorkpieceDetected`。  
- `DepictorCalculation`：使用 <span class="cfg-func">BeltDepictor()</span> 依據 <span class="cfg-name">Master</span> 軸位置更新輸送帶的視覺化資訊。  
- `PLC_PRG`：將上述資訊整合成一個實際可用的伺服控制流程。

若有連接 3D/2D 視覺化畫面，可以同時看到：輸送帶前進、工件位置變化、鋸片滑台隨輸送帶同步，以及刀具上下移動的結果。

---

## 四、各支程式負責哪些功能？

### 4.1 `PLC_PRG` — 主控制程式

- **類型**：PROGRAM。  
- **職責**：  
  - 管理三個軸的上電與驅動（<span class="cfg-func">MC_Power()</span>）。  
  - 以固定速度驅動輸送帶（<span class="cfg-func">MC_MoveVelocity()</span>）。  
  - 在收到 `SimulateWorkpiece.WorkpieceDetected` 後，設定並啟動 <span class="cfg-func">MC_GearInPos()</span>。  
  - 控制刀具軸與鋸片滑台軸的絕對移動（<span class="cfg-func">MC_MoveAbsolute()</span>），完成切割並回復待命位置。  
- **與硬體／通訊的關係**：  
  - 透過四個 SoftMotion 功能塊與三個軸互動，可對應到實際伺服驅動器的啟停與位置命令。  

### 4.2 `SimulateWorkpiece` — 工件與光遮斷器模擬

- **類型**：PROGRAM。  
- **職責**：  
  - 基於 <span class="cfg-name">Master</span> 軸位置模擬一塊工件在輸送帶上移動。  
  - 使用 `LightBarrierPos` 與 `WorkpieceLength` 判斷工件是否覆蓋光遮斷器，輸出 `WorkpieceDetected`。  
  - 提供工件中心位置 `WorkPiecePos`，可用於 Trace 或視覺化。  
- **與硬體／通訊的關係**：  
  - 實務上對應到「光遮斷器輸入訊號」與「工件位置估測」，在此以程式模擬，不需要真實 I/O。

### 4.3 `DepictorCalculation` — 輸送帶視覺化

- **類型**：PROGRAM。  
- **職責**：  
  - 利用功能塊 <span class="cfg-func">BeltDepictor()</span>，根據 `Const.BELTLENGTH`、`Const.BELTWIDTH` 等參數與 <span class="cfg-name">Master</span> 軸位置，產生輸送帶的幾何與位置資訊。  
  - 讓視覺化畫面可以正確描繪輸送帶，幫助使用者理解整體運動關係。  

### 4.4 `GVL_Const` — 全域常數表

- **類型**：全域變數表（<span class="cfg-global">VAR_GLOBAL CONSTANT</span>）。  
- **職責**：  
  - 集中定義與幾何、位置有關的常數，例如 <span class="cfg-const">SYNCPOS</span>、<span class="cfg-const">LIGHTBARRIERPOS</span>、<span class="cfg-const">BELTLENGTH</span> 等。  
  - 讓多個程式在計算同步點、工件位置與視覺化時，共用一致的座標與尺寸設定。

---

## 五、函式庫與函式／功能塊一覽

### 5.1 函式庫

對照 `Libraries.md`，本範例主要使用下列函式庫：

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | 系統庫，提供 SoftMotion 基本運動控制功能（MC\_* 功能塊）。 |

### 5.2 主要功能塊

下表整理 `PLC_PRG` 與 `DepictorCalculation` 中實際使用到的功能塊與用途：

| 名稱 | 類型 | 用途 | 主要引數（IN / IN\_OUT） | 回傳／狀態 |
|------|------|------|--------------------------|------------|
| <span class="cfg-func">MC_Power()</span> | FUNCTION\_BLOCK | 控制軸上電與驅動啟動。 | <span class="cfg-arg">Axis</span>：軸物件；<span class="cfg-arg">Enable</span>：啟動命令；<span class="cfg-arg">bRegulatorOn</span>：啟動位置／速度迴路；<span class="cfg-arg">bDriveStart</span>：啟動驅動器。 | `Status`：TRUE 表示軸已準備就緒。 |
| <span class="cfg-func">MC_MoveVelocity()</span> | FUNCTION\_BLOCK | 以固定速度驅動輸送帶（Master 軸）。 | <span class="cfg-arg">Axis</span>；<span class="cfg-arg">Execute</span>；<span class="cfg-arg">Velocity</span>；<span class="cfg-arg">Acceleration</span>；<span class="cfg-arg">Deceleration</span>；<span class="cfg-arg">Jerk</span>。 | `Done`、`Busy`、`Error` 等狀態。 |
| <span class="cfg-func">MC_MoveAbsolute()</span> | FUNCTION\_BLOCK | 以絕對位置控制刀具軸與鋸片滑台軸。 | <span class="cfg-arg">Axis</span>；<span class="cfg-arg">Execute</span>；<span class="cfg-arg">Position</span>；<span class="cfg-arg">Velocity</span> 等。 | `Done`：到達目標位置；`Error`：命令失敗。 |
| <span class="cfg-func">MC_GearInPos()</span> | FUNCTION\_BLOCK | 在指定位置啟動 Master／Slave 齒輪同步。 | <span class="cfg-arg">Master</span>；<span class="cfg-arg">Slave</span>；<span class="cfg-arg">Execute</span>；<span class="cfg-arg">MasterSyncPosition</span>；<span class="cfg-arg">SlaveSyncPosition</span>；<span class="cfg-arg">MasterStartDistance</span>；<span class="cfg-arg">RatioNumerator</span>/<span class="cfg-arg">RatioDenominator</span>。 | `InSync`：同步完成；`Done`：動作結束；`Error`：同步失敗。 |
| <span class="cfg-func">BeltDepictor()</span> | FUNCTION\_BLOCK | 計算輸送帶幾何形狀與位置，用於視覺化。 | <span class="cfg-arg">posOrigin</span>：原點座標；<span class="cfg-arg">length</span>、<span class="cfg-arg">width</span>、<span class="cfg-arg">height</span>；<span class="cfg-arg">beltPos</span>：沿帶方向位置。 | 視覺化元件使用的輸送帶資訊。 |

---

## 六、變數與常數一覽

本範例未使用 RETAIN／PERSISTENT 變數，所有資料在重新下載或控制器重啟後皆會回到初始值。

### 6.1 全域常數（`GVL_Const`）

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| <span class="cfg-const">SYNCPOS</span> | <span class="cfg-type">LREAL</span> | 0 | 鋸片與工件應該同步的 X 位置。 |
| <span class="cfg-const">LIGHTBARRIERPOS</span> | <span class="cfg-type">LREAL</span> | -300 | 光遮斷器在輸送帶座標系下的 X 位置。 |
| <span class="cfg-const">WORKPIECELENGTH</span> | <span class="cfg-type">LREAL</span> | 200 | 單一工件的長度。 |
| <span class="cfg-const">WORKPIECEWIDTH</span> | <span class="cfg-type">LREAL</span> | 120 | 工件寬度（與輸送帶寬度對齊）。 |
| <span class="cfg-const">WORKPIECEHEIGHT</span> | <span class="cfg-type">LREAL</span> | 10 | 工件高度。 |
| <span class="cfg-const">BELTLENGTH</span> | <span class="cfg-type">LREAL</span> | 1000 | 輸送帶模型的長度。 |
| <span class="cfg-const">BELTWIDTH</span> | <span class="cfg-type">LREAL</span> | 150 | 輸送帶寬度。 |
| <span class="cfg-const">BELTHEIGHT</span> | <span class="cfg-type">LREAL</span> | 50 | 輸送帶高度。 |
| <span class="cfg-const">TIPOFFSET</span> | <span class="cfg-type">LREAL</span> | 8 | 刀尖相對於連桿末端的偏移距離，用來決定下刀深度。 |

### 6.2 主程式 `PLC_PRG` 中的重要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">pwTool</span> / <span class="cfg-local">pwMaster</span> / <span class="cfg-local">pwSlave</span> | <span class="cfg-type">MC_Power</span> | 對應 Tool／Master／Slave 三個軸的電源控制。 |
| <span class="cfg-local">moveBelt</span> | <span class="cfg-type">MC_MoveVelocity</span> | 控制輸送帶速度與加減速度的命令。 |
| <span class="cfg-local">moveTool</span> | <span class="cfg-type">MC_MoveAbsolute</span> | 控制刀具由原點到切削位置，再回到原點。 |
| <span class="cfg-local">moveSlave</span> | <span class="cfg-type">MC_MoveAbsolute</span> | 控制鋸片滑台移動到待命位置。 |
| <span class="cfg-local">gearInPos</span> | <span class="cfg-type">MC_GearInPos</span> | 定義 Master／Slave 齒輪同步關係與觸發條件。 |
| <span class="cfg-local">state</span> | <span class="cfg-type">UDINT</span> | 主狀態機，決定目前控制流程步驟。 |

相關常數狀態值（`STATE_*`）則界定了每個流程階段，方便在 Trace 中觀察狀態機的變化。

### 6.3 `SimulateWorkpiece` 中的重要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">LightBarrierPos</span> | <span class="cfg-type">LREAL</span> | 光遮斷器位置，預設取自 <span class="cfg-const">LIGHTBARRIERPOS</span>。 |
| <span class="cfg-local">WorkpieceLength</span> | <span class="cfg-type">LREAL</span> | 工件長度，預設取自 <span class="cfg-const">WORKPIECELENGTH</span>。 |
| <span class="cfg-local">WorkpieceDetected</span> | <span class="cfg-type">BOOL</span> | TRUE 代表工件覆蓋光遮斷器。 |
| <span class="cfg-local">WorkPiecePos</span> | <span class="cfg-type">LREAL</span> | 工件中心在輸送帶座標系下的位置。 |
| <span class="cfg-local">state</span> | <span class="cfg-type">UDINT</span> | 工件模擬狀態（初始化／運行中）。 |
| <span class="cfg-local">masterOffset</span> | <span class="cfg-type">LREAL</span> | 紀錄產生工件當下的 Master 軸位置，用於處理位置回捲。 |

Trace 設定中也包含 `SimulateWorkpiece.WorkPiecePos` 與 `PLC_PRG.state` 等變數，方便從波形觀察整體時間關係。

---

## 七、特別的演算法與觀念

### 7.1 Gear-In-Position 的同步點計算

關鍵演算法在 `STATE_WAIT_FOR_WORKPIECE` 中設定 <span class="cfg-func">MC_GearInPos()</span> 的三個重要參數：

- `gearInPos.MasterSyncPosition := Master.fSetPosition + (Const.SYNCPOS - Const.LIGHTBARRIERPOS) + Const.WORKPIECELENGTH * 0.1;`  
- `gearInPos.SlaveSyncPosition := Const.SYNCPOS;`  
- `gearInPos.MasterStartDistance := 0.75 * (Const.SYNCPOS - Const.LIGHTBARRIERPOS);`

直觀來看：

- 當 `SimulateWorkpiece.WorkpieceDetected` 變為 TRUE 時，可以認為工件的前緣剛好通過光遮斷器位置 <span class="cfg-const">LIGHTBARRIERPOS</span>。  
- 從光遮斷器到同步點 <span class="cfg-const">SYNCPOS</span> 的距離，決定了控制器還有多少時間可以讓 <span class="cfg-name">Slave</span> 軸加速並與 <span class="cfg-name">Master</span> 同步。  
- `Const.WORKPIECELENGTH * 0.1` 代表再向前略為提前 10% 工件長度，使切割在工件進入同步點前就啟動，預留機械與控制延遲。  
- `MasterStartDistance` 則決定在同步點前多少距離開始進行齒輪同步，避免命令一下達就立即同步，導致動作過急。

換句話說，這段演算法把「偵測位置」與「期望切割位置」之間的幾何關係，轉換成 <span class="cfg-func">MC_GearInPos()</span> 所需的三個引數，讓鋸片滑台能在適當時間點、以正確速度加入輸送帶的運動。

### 7.2 工件位置模擬與位置回捲處理

在 `SimulateWorkpiece` 中，工件位置的計算方式為：

- 初始化時：`WorkPiecePos := -Const.BELTLENGTH / 2;`，代表工件一開始在輸送帶左側外。  
- 之後透過 `Master.fSetPosition - masterOffset` 累積位移，再加回起始位置，得到 `WorkPiecePos`。  
- 若偵測到 `Master.fSetPosition < masterOffset`，表示 Master 軸位置因為週期性而回捲（例如位置超過一圈又從 0 開始），此時將 `masterOffset` 減去 `Master.fPositionPeriod`，保持 `(Master.fSetPosition - masterOffset)` 的連續性。

最後，利用以下條件判斷光遮斷器是否被工件遮住：

```text
WorkpieceDetected :=
    WorkPiecePos - WorkpieceLength/2 <= LightBarrierPos AND
    WorkPiecePos + WorkpieceLength/2 >= LightBarrierPos;
```

這表示只要光遮斷器位置 `LightBarrierPos` 落在「工件前緣」與「工件後緣」之間，就視為被遮斷。  
這樣的寫法與實體光遮斷器的行為相符，也方便之後在 Trace 中對照位置與偵測訊號。

---

## 八、重要參數與設定位置

下表整理幾個最常需要調整的參數與其所在檔案，方便實作時快速定位：

| 參數名稱 | 所在檔案／位置 | 作用說明 |
|----------|----------------|----------|
| <span class="cfg-const">SYNCPOS</span> | `GVL_Const.st` | 決定鋸片與工件同步時在輸送帶座標系下的目標位置。 |
| <span class="cfg-const">LIGHTBARRIERPOS</span> | `GVL_Const.st` | 光遮斷器的安裝位置，會影響工件被偵測到的時間點。 |
| <span class="cfg-const">WORKPIECELENGTH</span> | `GVL_Const.st` / `SimulateWorkpiece` 預設 | 工件長度；改變後會影響同步點提前量與模擬路徑。 |
| <span class="cfg-const">BELTLENGTH</span> | `GVL_Const.st` | 輸送帶長度；影響工件初始化與重新產生的位置。 |
| <span class="cfg-const">BELTWIDTH</span> / <span class="cfg-const">TIPOFFSET</span> | `GVL_Const.st` 與 `PLC_PRG`（`moveTool.Position` 設定） | 決定刀具下刀位置的幾何關係。 |
| <span class="cfg-name">MainTask</span> 週期 t#4ms | `TaskConfiguration.md` | 控制更新頻率；過慢會使軌跡較不平滑，過快則增加 CPU 負載。 |
| <span class="cfg-arg">Velocity</span> 等運動參數 | `PLC_PRG` 中 <span class="cfg-local">moveBelt</span>、<span class="cfg-local">moveTool</span>、<span class="cfg-local">moveSlave</span> 的初始值 | 決定輸送帶前進速度、刀具與滑台移動速度與加減速性能。 |

在實際專案中，通常會先依照機械設計與工藝需求，決定幾何常數與安全位置，再微調運動參數與任務週期，以兼顧精度與效能。

---

## 九、建議閱讀與修改順序

若是第一次接觸此範例，建議依照以下順序閱讀與實驗：

1. **先看 `GVL_Const.st`**  
   - 了解輸送帶長度、工件尺寸、光遮斷器與同步點的位置等幾何設定。  
   - 試著修改 <span class="cfg-const">LIGHTBARRIERPOS</span> 或 <span class="cfg-const">WORKPIECELENGTH</span>，觀察工件在視覺化與 Trace 中的變化。  
2. **再看 `SimulateWorkpiece`**  
   - 搭配 Trace，理解 `WorkPiecePos` 如何隨 <span class="cfg-name">Master</span> 軸位置移動，以及位置回捲處理的意義。  
3. **接著看 `PLC_PRG`**  
   - 先從狀態機 <span class="cfg-local">state</span> 的變化開始理解流程，再對照各個功能塊的引數設定。  
   - 尤其注意 <span class="cfg-func">MC_GearInPos()</span> 的三個關鍵引數與常數之間的關係。  
4. **最後看 `DepictorCalculation` 與視覺化畫面**  
   - 了解如何透過一個簡單的功能塊（<span class="cfg-func">BeltDepictor()</span>）把幾何與軸位置轉成圖像，幫助除錯與教學。  

在修改時，建議先只動幾何與速度等「參數」，確認理解效果後，再考慮調整狀態機流程或加入額外保護邏輯。

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">Master</span> | 輸送帶軸，作為齒輪同步中的主軸。 |
| <span class="cfg-name">Slave</span> | 鋸片滑台軸，在指定位置與 Master 軸同步。 |
| <span class="cfg-name">Tool</span> | 刀具上下軸，負責切入與退回。 |
| <span class="cfg-name">Gear-In-Position</span> / <span class="cfg-func">MC_GearInPos()</span> | 在指定位置啟動主從齒輪同步的運動控制功能塊。 |
| <span class="cfg-name">Light barrier</span> / 光遮斷器 | 感測工件是否通過某一位置的感測元件。 |
| <span class="cfg-name">SoftMotion</span> | CODESYS 的運動控制套件，提供 MC\_* 功能塊與虛擬軸。 |
| <span class="cfg-name">Trace</span> | CODESYS 中用來記錄變數隨時間變化的工具，可用來觀察軸位置與狀態機變化。 |

