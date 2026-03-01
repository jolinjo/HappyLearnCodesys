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

# Robotics_PickAndPlace — 整體架構與功能說明

---

## 一、這個專案在做什麼？（一句話＋情境）

這個範例示範一套以 <span class="cfg-name">Tripod</span> 三角機器人為主角的 **Pick & Place 工作站**：  
機器人從旋轉工作台上取下圓環，追蹤輸送帶上的圓錐，最後把圓環準確地套在移動中的圓錐上，並持續循環執行。

從學習角度來看，這個專案同時練習：

- 如何在 CODESYS <span class="cfg-name">SoftMotion Robotics</span> 中設定多軸 <span class="cfg-name">Tripod</span> 機構。
- 如何運用 <span class="cfg-func">MC_Power()</span>、<span class="cfg-func">MC_MoveLinearAbsolute()</span> 等運動控制 FB 形成「啟動 → 取件 → 放件 → 回原位」的狀態機。
- 如何利用 <span class="cfg-func">MC_TrackConveyorBelt()</span> 與 <span class="cfg-func">MC_TrackRotaryTable()</span> 追蹤輸送帶與轉盤上的工件位置，並透過 <span class="cfg-name">PCS_1</span>、<span class="cfg-name">PCS_2</span> 與 <span class="cfg-name">WCS</span> 等座標系來完成座標轉換。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務與程式對應（對照 `TaskConfiguration.md`）

| 任務名稱 | 類型 | 週期 | 優先權 | 執行的 POU |
|----------|------|------|--------|------------|
| MainTask | Cyclic | t#4ms | 1 | `Robot`, `Environment`, `DepictorCalculations` |
| Tripod_PlanningTask | Freewheeling | t#8ms | 2 | `Tripod_PlanningPrg` |
| VISU_TASK | Cyclic | 50 ms | 31 | `VisuElems.Visu_Prg`（視覺化程式，未列在本目錄中） |

- <span class="cfg-name">MainTask</span> 是整個工作站的核心控制迴圈：啟動三個軸形成 <span class="cfg-name">Tripod</span> 機構、控制輸送帶與轉盤、並更新可視化資料。
- <span class="cfg-name">Tripod_PlanningTask</span> 作為規劃用任務，掛載 `Tripod_PlanningPrg`，原始內容極少，示範「可將重運算分到另一個任務」的架構。
- <span class="cfg-name">VISU_TASK</span> 只負責視覺化程式，從本目錄的資料看不到詳細程式，但可以想像會讀取 `DepictorCalculations`、`Robot` 等輸出來畫圖。

### 2.2 軸與裝置結構（對照 `DeviceTree_Axes.md`）

本範例使用的軸列表如下：

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| Tripod1 | SM_Drive_Virtual | - |
| Tripod2 | SM_Drive_Virtual | - |
| Tripod3 | SM_Drive_Virtual | - |
| DriveRotaryTable | SM_Drive_Virtual | - |
| DriveConveyorBelt | SM_Drive_Virtual | - |

- 三個虛擬軸 <span class="cfg-name">Tripod1</span>、<span class="cfg-name">Tripod2</span>、<span class="cfg-name">Tripod3</span> 共同組成 <span class="cfg-name">Tripod</span> 機器人軸組，供 `Robot` 程式控制。
- <span class="cfg-name">DriveRotaryTable</span> 負責帶動放置圓環的旋轉工作台，由 `Environment` 內的 <span class="cfg-func">MC_MoveVelocity()</span> 持續驅動。
- <span class="cfg-name">DriveConveyorBelt</span> 為輸送帶軸，同樣由 `Environment` 持續以固定速度運轉，讓圓錐在帶面上移動。

雖然 `DeviceTree_Axes.md` 中沒有明確列出軸組資訊，但從程式可以看出：

- `Robot` 透過 <span class="cfg-local">enable</span>（型態 <span class="cfg-type">MC_GroupEnable</span>）操作軸組 `<span class="cfg-name">Tripod</span>`。
- `Cone` 與 `Ring` 使用 <span class="cfg-func">MC_TrackConveyorBelt()</span> 與 <span class="cfg-func">MC_TrackRotaryTable()</span>，將工件位置綁定在輸送帶與轉盤對應的座標系上。

### 2.3 全域幾何與作業模式設定（對照 `GVL.st`）

`GVL.st` 裡的 <span class="cfg-global">VAR_GLOBAL CONSTANT</span> 與 <span class="cfg-global">VAR_GLOBAL</span> 區段，定義了本工作站的幾何位置與作業模式：

- <span class="cfg-const">gcTripodTransX</span>、<span class="cfg-const">gcTripodTransY</span>、<span class="cfg-const">gcTripodTransZ</span>：<span class="cfg-name">Tripod</span> 機構在世界座標中的三維平移量。
- <span class="cfg-const">gcBeltTransX</span>、<span class="cfg-const">gcBeltTransY</span>、<span class="cfg-const">gcBeltTransZ</span>：輸送帶座標系（<span class="cfg-name">PCS_2</span>）的位置。
- <span class="cfg-const">gcTableTransX</span>、<span class="cfg-const">gcTableTransY</span>、<span class="cfg-const">gcTableTransZ</span>：旋轉工作台座標系（<span class="cfg-name">PCS_1</span>）的位置。
- <span class="cfg-const">gcTCP_Ring</span>：機器人 <span class="cfg-name">TCP</span> 到圓環下緣的距離，影響取放高度。
- <span class="cfg-const">gcTripod1PosOrig</span> ~ <span class="cfg-const">gcTripod3PosOrig</span>：三個軸的啟動基準位置。
- <span class="cfg-global">gbSetRing</span>：手動要求在轉盤上放一個新圓環。
- <span class="cfg-global">gbAutomatic</span>：是否自動、連續地產生圓環。

這些參數決定了實體（或虛擬）場景中各設備的相對位置，修改前要先理解 `Robot`、`Cone`、`Ring` 中如何使用它們。

---

## 三、控制流程：由淺入深

### 3.1 整體流程概觀

用白話來看，一次完整的循環大致分為：

1. 啟動三個 Tripod 軸、設定座標系與軸組。
2. 檢查轉盤上是否有可用的圓環，若有就移動到圓環上方並取下。
3. 上升到安全高度、退回中立位置。
4. 前往目前在輸送帶上的目標圓錐上方。
5. 下降、將圓環放在圓錐上，再上升並退回中立位置。
6. 回到等待狀態，準備下一個圓環與圓錐。

在此過程中，`Environment` 會持續讓輸送帶與轉盤以固定速度運轉；`Cone` 與 `Ring` 的狀態機則依據 <span class="cfg-name">Tripod</span> 的週期時間與當前狀態更新各自的位置與旗標。

### 3.2 `Robot` 程式的狀態機（對照 `Robot.st`）

`Robot` 以整數變數 <span class="cfg-local">state</span> 建立狀態機，主要狀態如下：

- **0**：等待三個軸的 <span class="cfg-func">MC_Power()</span> 全部上電完成。
- **10**：呼叫 <span class="cfg-func">MC_SetPosition()</span>，將三個 Tripod 軸移動到預設初始位置（使用 `gcTripod1PosOrig` 等常數）。
- **20**：透過 <span class="cfg-func">MC_SetCoordinateTransform()</span> 告訴系統 Tripod 在世界座標中的實際位置（使用 `gcTripodTransX/Y/Z`）。
- **30**：以 <span class="cfg-func">MC_GroupEnable()</span> 啟用整個軸組 `<span class="cfg-name">Tripod</span>`。
- **40**：判斷 `Environment.bRingOnTable`，如果轉盤上有可用圓環，就開始接近圓環上方的位置 `POS_ABOVE_RING_PCS_1`。
- **50** ~ **70**：  
  - 等待到位後啟動 <span class="cfg-func">TON()</span> 計時，模擬在環上方跟隨一小段時間。  
  - 然後呼叫 <span class="cfg-func">MC_MoveLinearRelative()</span> 以 <span class="cfg-name">PCS_1</span> 座標系向上抬起。
  - 回到世界座標 <span class="cfg-name">WCS</span> 的中立位置 `POS_REST_WCS`。
- **80** ~ **100**：  
  - 讀取 `Environment.pActiveCone`，決定下一個要放環的圓錐。  
  - 切換到 <span class="cfg-name">PCS_2</span> 座標系，到達圓錐上方 `POS_ABOVE_CONE_PCS_2` 後再下降到 `POS_ON_CONE_PCS_2` 放環。
  - 放完後再向上抬起，回到安全高度。
- **110** ~ **120**：移動回中立位置 `POS_REST_WCS`，最後把 `state` 設回 40，進入下一輪循環。

輸出腳位：

- <span class="cfg-local">bReadyForMotion</span>：只要軸組沒有停用也沒有錯誤，就是 TRUE，供 `Ring` 判斷是否可以啟動。
- <span class="cfg-local">bRingAttached</span>：當狀態在 70～100 之間時為 TRUE，代表圓環被機器人夾持。
- <span class="cfg-local">bDontChangePCS_2</span>：當機器人正在圓錐附近操作（90～110）時為 TRUE，用來避免 `Cone` 在這段期間更換 <span class="cfg-name">PCS_2</span> 綁定的圓錐。

### 3.3 `Environment`、`Cone`、`Ring` 的互動（對照對應 .st）

- `Environment`：
  - 先用兩顆 <span class="cfg-func">MC_Power()</span> 與兩顆 <span class="cfg-func">MC_MoveVelocity()</span>，讓 <span class="cfg-name">DriveRotaryTable</span> 與 <span class="cfg-name">DriveConveyorBelt</span> 持續運轉。
  - 再建立三顆 `Cone` 與兩顆 `Ring` 的實例，並在第一次循環時做初始化（例如給定 `ring1StartPos`）。
  - 最後輸出 `bRingOnTable`，表示目前是否有至少一個圓環在轉盤可用範圍內。

- `Cone`：
  - 使用 <span class="cfg-func">MC_TrackConveyorBelt()</span> 追蹤某一顆圓錐在輸送帶上的位置，並將 <span class="cfg-name">PCS_2</span> 綁定到這顆圓錐。
  - 以 `state = 0 / 10 / 20` 區分「尚未出現」、「連結 PCS_2」、「在輸送帶上移動」三種狀態。
  - `pActiveCone` 指向目前與機器人座標系綁定的圓錐，供 `Robot` 取用。

- `Ring`：
  - 使用 <span class="cfg-func">MC_TrackRotaryTable()</span> 追蹤轉盤上的圓環位置，並將 <span class="cfg-name">PCS_1</span> 綁定到該圓環。
  - 狀態 0 表示待命在初始位置；狀態 20/30 表示在轉盤上等待機器人可用；狀態 40 則是圓環已被機器人夾持並跟隨 <span class="cfg-name">TCP</span>；狀態 50 表示圓環已放到圓錐上，等待圓錐離開。
  - 兩顆 `Ring` 會互相參照，確保同一時間只有一顆圓環會被送到機器人前方。

### 3.4 `DepictorCalculations` 與規劃程式

- `DepictorCalculations` 使用 <span class="cfg-func">Tripod_Lin_Depictor()</span> 與三角函數 <span class="cfg-func">SIN()</span>、<span class="cfg-func">COS()</span>，在陣列 `aafPos` 中準備一組可視化用軌跡點。
- `Tripod_PlanningPrg` 在原始 XML 中幾乎為空，僅作為規劃任務佔位；在實務專案裡，這裡可以擴充為離線路徑產生與插補規劃程式。

---

## 四、各支程式負責哪些功能？（由淺入深）

### 4.1 `GVL.st` — 全域幾何與模式設定

- **類型**：<span class="cfg-type">VAR_GLOBAL</span>、<span class="cfg-type">VAR_GLOBAL CONSTANT</span>。
- **職責**：集中定義 Tripod 機構、輸送帶、轉盤的位置與大小，以及是否自動連續產生圓環。
- **與硬體／通訊關係**：數值會直接影響 <span class="cfg-name">Tripod</span> 軸組與輸送帶、轉盤在空間中的相對位置，是調整「機械佈局」時的主要入口。

### 4.2 `Environment.st` — 環境與工件管理

- **類型**：<span class="cfg-keyword">PROGRAM</span>。
- **職責**：
  - 啟動並維持 <span class="cfg-name">DriveRotaryTable</span> 與 <span class="cfg-name">DriveConveyorBelt</span> 的運轉。
  - 建立並驅動三顆 `Cone` 與兩顆 `Ring` 的狀態機。
  - 對外提供 `bRingOnTable` 與 `pActiveCone`，讓 `Robot` 能判斷是否有環可取、要把環放在哪顆圓錐上。
- **與硬體／通訊關係**：對應到 Device Tree 中軸的啟動與速度設定，並以狀態機的方式模擬輸送帶與轉盤上工件的流動。

### 4.3 `Robot.st` — Tripod 機器人主控制程式

- **類型**：<span class="cfg-keyword">PROGRAM</span>。
- **職責**：完成一整輪 Pick & Place 流程，包含軸啟動、座標系設定、靠近圓環、夾持、移動到圓錐上方、放環與回到中立位置。
- **與硬體／通訊關係**：直接操作 <span class="cfg-name">Tripod</span> 軸組，並根據 `Environment.bRingOnTable` 與 `Environment.pActiveCone` 來決定何時開始移動與要放到哪個圓錐上。

### 4.4 `Cone.st` — 輸送帶上的圓錐狀態機

- **類型**：<span class="cfg-keyword">FUNCTION_BLOCK</span>。
- **職責**：描述單一圓錐在輸送帶上的運動與壽命週期，並決定何時把 <span class="cfg-name">PCS_2</span> 綁定到自己身上。
- **與硬體／通訊關係**：透過 <span class="cfg-func">MC_TrackConveyorBelt()</span> 與 <span class="cfg-name">DriveConveyorBelt</span> 的運動，計算出圓錐在 <span class="cfg-name">PCS_2</span> 下的位置，並提供給 `Robot` 參考。

### 4.5 `Ring.st` — 轉盤上的圓環狀態機

- **類型**：<span class="cfg-keyword">FUNCTION_BLOCK</span>。
- **職責**：描述單一圓環從轉盤待命、準備被機器人夾取、被夾持並跟隨 <span class="cfg-name">TCP</span> 移動，到最後放到圓錐上、再回到初始狀態的流程。
- **與硬體／通訊關係**：透過 <span class="cfg-func">MC_TrackRotaryTable()</span> 與 <span class="cfg-name">DriveRotaryTable</span> 的運動獲得環的位置，並透過 `Robot.bReadyForMotion`、`Robot.bRingAttached`、`Robot.pTargetCone` 等旗標與 Robot 溝通。

### 4.6 `DepictorCalculations.st` — 可視化軌跡計算

- **類型**：<span class="cfg-keyword">PROGRAM</span>。
- **職責**：計算 `aafPos` 陣列中的一組座標點，供 3D 視覺元件顯示輸送帶路徑與參考軌跡。
- **與硬體／通訊關係**：從 <span class="cfg-name">DriveConveyorBelt</span> 的當前位置與週期長度推回帶面上的標記點，並結合 <span class="cfg-func">Tripod_Lin_Depictor()</span> 反映 Tripod 的運動。

### 4.7 `Tripod_PlanningPrg.st` — 規劃任務佔位程式

- **類型**：<span class="cfg-keyword">PROGRAM</span>。
- **職責**：目前僅作為 <span class="cfg-name">Tripod_PlanningTask</span> 的佔位主程式，原始 XML 幾乎沒有實作。
- **與硬體／通訊關係**：在實際專案中，可在此加入較重的運算（例如離線路徑產生），藉由獨立任務避免影響主控制迴圈的即時性。

---

## 五、函式庫與函式／功能塊一覽（用途、引數、回傳）

### 5.1 函式庫（對照 `Libraries.md`）

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | SoftMotion 基礎運動控制功能塊與型態 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 與凸輪軌跡相關的功能（本範例主要使用線性移動） |
| <span class="cfg-name">#System_VisuElem3DPath</span> | 3D 路徑視覺元件，顯示由 `DepictorCalculations` 計算的點 |
| <span class="cfg-name">#System_VisuElemCamDisplayer</span> | 顯示凸輪或路徑的視覺元件 |

### 5.2 主要運動控制功能塊

- <span class="cfg-func">MC_Power()</span>  
  - **用途**：啟用單一軸的驅動器與調節器。  
  - **主要引數**：  
    - <span class="cfg-arg">Axis</span>（<span class="cfg-type">AXIS_REF</span>，IN）：目標軸（例如 `Tripod1`）。  
    - <span class="cfg-arg">Enable</span>（<span class="cfg-type">BOOL</span>，IN）：是否上電。  
  - **重要輸出**：<span class="cfg-arg">Status</span>（<span class="cfg-type">BOOL</span>），表示軸是否已經就緒。

- <span class="cfg-func">MC_SetPosition()</span>  
  - **用途**：強制設定軸的實際位置，常用於啟動後的「基準位置」建立。  
  - **主要引數**：<span class="cfg-arg">Axis</span>、<span class="cfg-arg">Execute</span>、<span class="cfg-arg">Position</span>。  
  - **在本範例的用法**：把三個 Tripod 軸拉到 `gcTripod1PosOrig` 等預設位置。

- <span class="cfg-func">MC_MoveLinearAbsolute()</span>、<span class="cfg-func">MC_MoveLinearRelative()</span>  
  - **用途**：在指定座標系下進行直線絕對／相對移動。  
  - **主要引數**：  
    - <span class="cfg-arg">AxisGroup</span>（<span class="cfg-type">AXIS_GROUP_REF</span>）：例如 `Tripod`。  
    - <span class="cfg-arg">Position</span> 或 <span class="cfg-arg">Distance</span>（<span class="cfg-type">SMC_POS_REF</span> 或對應型態）。  
    - <span class="cfg-arg">Velocity</span>、<span class="cfg-arg">Acceleration</span>、<span class="cfg-arg">Deceleration</span>、<span class="cfg-arg">Jerk</span>。  
  - **在本範例的用法**：構成「到環上方 → 抬起 → 回中立 → 到圓錐上方 → 放環 → 回中立」的直線路徑。

- <span class="cfg-func">MC_GroupEnable()</span>  
  - **用途**：啟用整個軸組，以便後續使用軸組層級的移動 FB。  
  - **本範例重點**：啟用後才可以使用上述線性移動 FB 控制 <span class="cfg-name">Tripod</span>。

- <span class="cfg-func">MC_TrackConveyorBelt()</span> / <span class="cfg-func">MC_TrackRotaryTable()</span>  
  - **用途**：將工件位置繫結到輸送帶或轉盤的運動，同時提供座標系（`cs`）給使用者。  
  - **在本範例的用法**：`Cone` 與 `Ring` 透過這兩個 FB 取得目前工件姿態，再搭配 <span class="cfg-func">SMC_Frame_To_CoordRef()</span> 轉成 <span class="cfg-type">MC_COORD_REF</span> 或 <span class="cfg-type">SMC_POS_REF</span> 方便使用。

### 5.3 其他常見函數

- <span class="cfg-func">SIN()</span>、<span class="cfg-func">COS()</span>：在 `DepictorCalculations` 中用來產生圓弧路徑。  
- <span class="cfg-const">SMC_PI</span>：常數 π，搭配弧長計算路徑。

---

## 六、變數與常數一覽

本範例 **未使用 RETAIN／PERSISTENT**，所有變數在 PLC 斷電後皆不保留。

### 6.1 全域常數與變數（對照 `GVL.st`）

| 名稱 | 型態 | 預設值 | 斷電記憶 | 說明 |
|------|------|--------|----------|------|
| <span class="cfg-const">gcTripodTransX</span> | <span class="cfg-type">LREAL</span> | 0 | 否 | Tripod 基座在世界座標 X 方向的平移量 |
| <span class="cfg-const">gcTripodTransY</span> | <span class="cfg-type">LREAL</span> | 0 | 否 | Tripod 基座在世界座標 Y 方向的平移量 |
| <span class="cfg-const">gcTripodTransZ</span> | <span class="cfg-type">LREAL</span> | 1700 | 否 | Tripod 基座在世界座標 Z 方向的高度 |
| <span class="cfg-const">gcTripodSize</span> | <span class="cfg-type">LREAL</span> | 180 | 否 | Tripod 幾何尺寸基準，影響工作空間 |
| <span class="cfg-const">gcBeltTransX</span> | <span class="cfg-type">LREAL</span> | 0 | 否 | 輸送帶座標系 X 位置 |
| <span class="cfg-const">gcBeltTransY</span> | <span class="cfg-type">LREAL</span> | 500 | 否 | 輸送帶座標系 Y 位置 |
| <span class="cfg-const">gcBeltTransZ</span> | <span class="cfg-type">LREAL</span> | 0 | 否 | 輸送帶座標系 Z 位置 |
| <span class="cfg-const">gcTableTransX</span> | <span class="cfg-type">LREAL</span> | 0 | 否 | 轉盤座標系 X 位置 |
| <span class="cfg-const">gcTableTransY</span> | <span class="cfg-type">LREAL</span> | -500 | 否 | 轉盤座標系 Y 位置 |
| <span class="cfg-const">gcTableTransZ</span> | <span class="cfg-type">LREAL</span> | 0 | 否 | 轉盤座標系 Z 位置 |
| <span class="cfg-const">gcTCP_Ring</span> | <span class="cfg-type">LREAL</span> | 0.02×gcTripodSize+15 | 否 | TCP 到圓環下緣的距離 |
| <span class="cfg-const">gcTripod1PosOrig</span> | <span class="cfg-type">LREAL</span> | 50 | 否 | Tripod1 啟動基準位置 |
| <span class="cfg-const">gcTripod2PosOrig</span> | <span class="cfg-type">LREAL</span> | 75 | 否 | Tripod2 啟動基準位置 |
| <span class="cfg-const">gcTripod3PosOrig</span> | <span class="cfg-type">LREAL</span> | 25 | 否 | Tripod3 啟動基準位置 |
| <span class="cfg-global">gbSetRing</span> | <span class="cfg-type">BOOL</span> | FALSE | 否 | 手動要求新增一顆圓環的旗標 |
| <span class="cfg-global">gbAutomatic</span> | <span class="cfg-type">BOOL</span> | TRUE | 否 | TRUE 時自動連續產生圓環 |

### 6.2 關鍵區域變數（節錄）

| 所在 POU | 名稱 | 型態 | 說明 |
|----------|------|------|------|
| `Robot` | <span class="cfg-local">state</span> | <span class="cfg-type">INT</span> | 機器人狀態機目前的步驟編號 |
| `Robot` | <span class="cfg-local">mcs</span> | <span class="cfg-type">MC_COORD_REF</span> | Tripod 在世界座標中的原點與姿態 |
| `Robot` | <span class="cfg-local">mvToRing</span> 等 | <span class="cfg-type">MC_MoveLinearAbsolute</span> / <span class="cfg-type">MC_MoveLinearRelative</span> | 封裝不同路徑段的直線移動 FB |
| `Environment` | <span class="cfg-local">bInit</span> | <span class="cfg-type">BOOL</span> | 第一次循環的初始化旗標 |
| `Environment` | <span class="cfg-local">cone1</span>..`cone3` | <span class="cfg-type">Cone</span> | 三顆圓錐的狀態機實例 |
| `Environment` | <span class="cfg-local">ring1</span>, `ring2` | <span class="cfg-type">Ring</span> | 兩顆圓環的狀態機實例 |
| `Cone` | <span class="cfg-local">state</span> | <span class="cfg-type">DINT</span> | 圓錐狀態（0：未出現、10：連結 PCS_2、20：在輸送帶上） |
| `Ring` | <span class="cfg-local">state</span> | <span class="cfg-type">DINT</span> | 圓環狀態（0/10/20/30/40/50 對應不同階段） |

---

## 七、特別的演算法與觀念

### 7.1 使用座標系連結（PCS_1／PCS_2／WCS）

本範例最大的觀念重點之一，是運用不同座標系來簡化運動規劃：

- 旋轉工作台上的圓環以 <span class="cfg-name">PCS_1</span> 為基礎，由 <span class="cfg-func">MC_TrackRotaryTable()</span> 提供即時姿態。
- 輸送帶上的圓錐以 <span class="cfg-name">PCS_2</span> 為基礎，由 <span class="cfg-func">MC_TrackConveyorBelt()</span> 提供即時姿態。
- 休息位置與較大範圍的運動以世界座標 <span class="cfg-name">WCS</span> 表示。

初學者可以把這三個座標系想成三張不同的「地圖」：  
在 <span class="cfg-name">PCS_1</span> 地圖上，轉盤總是固定在原點，只是圓環角度在變；  
在 <span class="cfg-name">PCS_2</span> 地圖上，輸送帶是一條直線；  
在 <span class="cfg-name">WCS</span> 地圖上，整個工作站都看得到。

### 7.2 狀態機設計模式

`Robot`、`Cone`、`Ring` 都採用整數狀態 `state` 加上 `stateOld` 或區間判斷的寫法，優點是：

- 流程一眼就能以「0 → 10 → 20 → …」的方式畫成流程圖。
- 如果想插入新步驟，只要在中間插入新的數值區間，例如從 40 加一個 45 狀態即可。

---

## 八、重要參數與設定位置（實作時對照）

### 8.1 任務週期與優先權

- 在 `TaskConfiguration.md` 中，<span class="cfg-name">MainTask</span> 以 t#4ms 的週期運行，是控制迴圈的核心。  
  若硬體負載較高，可以適度放大週期，但要注意運動軌跡會變得較不平滑。
- <span class="cfg-name">Tripod_PlanningTask</span> 以 t#8ms 的 Freewheeling 模式執行，適合放較重的規劃演算法。

### 8.2 速度與加速度設定（對照 `Robot.st`）

- <span class="cfg-const">VEL</span>、<span class="cfg-const">ACC</span>、<span class="cfg-const">JRK</span> 定義了所有線性移動的速度、加速度與 Jerk。  
  調整這三個常數可以同時改變整個 Pick & Place 流程的快慢與平順程度。

### 8.3 幾何佈局參數（對照 `GVL.st`）

- 調整 <span class="cfg-const">gcBeltTrans*</span> 與 <span class="cfg-const">gcTableTrans*</span> 可以改變輸送帶與轉盤相對於機器人的位置。
- 調整 <span class="cfg-const">gcTripodSize</span> 與 <span class="cfg-const">gcTCP_Ring</span> 會影響機器人可及範圍與取放高度。

在實務上，建議先在模擬環境中調整這些常數，使路徑安全且不碰撞，再套用到實際機台。

---

## 九、建議閱讀與修改順序

1. **先看本說明文件**：建立對場景與整體流程的概念。  
2. **閱讀 `TaskConfiguration.md` 與 `DeviceTree_Axes.md`**：搞清楚任務與軸的配置。  
3. **打開 `GVL.st`**：理解幾何與模式相關常數，知道哪些數值可以調整。  
4. **閱讀 `Environment.st`**：看懂輸送帶、轉盤以及圓錐／圓環的狀態機如何串在一起。  
5. **依序閱讀 `Cone.st` 與 `Ring.st`**：練習追蹤單一工件的狀態變化與座標系切換。  
6. **最後閱讀 `Robot.st`**：專注在 Pick & Place 狀態機，對照前面各程式輸出的旗標。  
7. **如需可視化，可再看 `DepictorCalculations.st` 與視覺程式**：了解如何把運動資訊轉成畫面上的軌跡。

修改程式時，建議先從 `GVL.st` 中較安全的幾何參數入手，再調整 `Robot.st` 中的路徑點與速度，最後才變動狀態機流程。

---

## 十、名詞對照

| 英文／符號 | 說明 |
|-----------|------|
| <span class="cfg-name">Tripod</span> | 三角機器人軸組，由三個線性軸構成，可在三維空間移動 TCP |
| <span class="cfg-name">PCS_1</span> | 「工件座標系 1」，本範例綁定到轉盤上的圓環位置 |
| <span class="cfg-name">PCS_2</span> | 「工件座標系 2」，本範例綁定到輸送帶上的圓錐位置 |
| <span class="cfg-name">WCS</span> | 世界座標系，通常以機台基座為原點 |
| <span class="cfg-name">TCP</span> | Tool Center Point，機器人端點工具中心位置 |
| <span class="cfg-name">MC_*</span> | Motion Control 函式庫內的標準運動控制功能塊前綴 |
| <span class="cfg-name">SoftMotion</span> | CODESYS 提供的軟體運動控制與機器人控制套件 |

---
