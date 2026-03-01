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

# Robotics_PickAndPlace_without_Depictor — 整體架構與功能說明

---

## 一、這個專案在做什麼？（一句話＋情境）

這個範例與 `Robotics_PickAndPlace` 類似，都是使用 Tripod 機器人完成「從轉盤取下圓環、放到輸送帶上的圓錐」的 Pick & Place 工作，  
差別在於 **本專案不依賴 3D Depictor 元件**，只保留控制與基本可視化計算邏輯，適合在沒有 3D 視覺套件的環境中使用或移植。  
你可以把它看成「純控制版」的 Pick & Place 範例。

---

## 二、使用情境與硬體／軸架構

### 2.1 任務與程式對應（對照 `TaskConfiguration.md`）

| 任務名稱 | 類型 | 週期 | 優先權 | 執行的 POU |
|----------|------|------|--------|------------|
| MainTask | Cyclic | t#4ms | 1 | `Robot`, `Environment`, `DepictorCalculations` |
| Tripod_PlanningTask | Freewheeling | t#8ms | 2 | `Tripod_PlanningPrg` |
| VISU_TASK | Cyclic | t#50ms | 31 | `VisuElems.Visu_Prg` |

- MainTask：負責 Tripod 軸組、輸送帶、轉盤與 Pick & Place 流程。  
- Tripod_PlanningTask：目前僅作為規劃任務佔位，未實作複雜規劃邏輯。  
- VISU_TASK：視覺程式在此任務中執行，但本範例不使用 Depictor 函式庫，僅可做較簡單的顯示。

### 2.2 軸與裝置結構（對照 `DeviceTree_Axes.md`）

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| Tripod1 | SM_Drive_Virtual | - |
| Tripod2 | SM_Drive_Virtual | - |
| Tripod3 | SM_Drive_Virtual | - |
| DriveRotaryTable | SM_Drive_Virtual | - |
| DriveConveyorBelt | SM_Drive_Virtual | - |

- <span class="cfg-name">Tripod1~3</span>：組成 Tripod 機器人軸組。  
- <span class="cfg-name">DriveRotaryTable</span>：帶動放圓環的旋轉工作台。  
- <span class="cfg-name">DriveConveyorBelt</span>：帶動放圓錐的輸送帶。

### 2.3 全域幾何與模式設定（對照 `GVL.st`）

`GVL.st` 中的常數與變數與完整版 PickAndPlace 相同：

- `gcTripodTransX/Y/Z`：Tripod 機構在世界座標中的平移。  
- `gcBeltTrans*`、`gcTableTrans*`：輸送帶與轉盤座標系位置。  
- `gcTCP_Ring`：TCP 到圓環下緣的距離。  
- `gcTripod1/2/3PosOrig`：三軸啟動基準位置。  
- `gbSetRing`、`gbAutomatic`：是否手動／自動產生圓環的旗標。

---

## 三、控制流程：由淺入深

整體流程與 `Robotics_PickAndPlace` 一致，僅在視覺部分較為精簡。

### 3.1 `Robot` 狀態機（摘要）

- 啟動三個 Tripod 軸，執行 <span class="cfg-func">MC_SetPosition()</span> 將軸拉到 `gcTripod*PosOrig`。  
- 使用 <span class="cfg-func">MC_SetCoordinateTransform()</span> 告知機器人自身在世界座標中的位置。  
- 啟用軸組後，循環執行：
  1. 檢查 `Environment.bRingOnTable`，若有可用圓環，移動到圓環上方（PCS_1）。  
  2. 等待一段時間（使用 <span class="cfg-func">TON()</span>），模擬跟隨環移動。  
  3. 抬起、回到中立位置（WCS）。  
  4. 依 `Environment.pActiveCone` 移動到目標圓錐上方（PCS_2），下降並放環，再抬起。  
  5. 回到中立位置（WCS），等待下一顆環與圓錐。

輸出 `bReadyForMotion`、`bRingAttached`、`bDontChangePCS_2` 則提供給 `Ring` 與 `Cone` 的狀態機使用。

### 3.2 `Environment`、`Cone`、`Ring` 的合作

- `Environment`：
  - 啟動 `DriveRotaryTable` 與 `DriveConveyorBelt`（<span class="cfg-func">MC_Power</span> + <span class="cfg-func">MC_MoveVelocity</span>）。  
  - 建立三顆 `Cone` 與兩顆 `Ring`，並管理其初始化與更新順序。  
  - 對外輸出 `bRingOnTable` 與 `pActiveCone`。  

- `Cone`：
  - 使用 <span class="cfg-func">MC_TrackConveyorBelt()</span> 追蹤輸送帶上的圓錐位置，並在適當時機把 PCS_2 綁到該圓錐上。  
  - 狀態 0/10/20 對應「尚未出現／連結 PCS_2／在輸送帶上移動」。  

- `Ring`：
  - 使用 <span class="cfg-func">MC_TrackRotaryTable()</span> 追蹤轉盤上的圓環，並綁定 PCS_1。  
  - 與 `Robot` 的 `bReadyForMotion`、`bRingAttached`、`pTargetCone` 合作，決定何時把環交給機器人、何時放到圓錐上。

### 3.3 `DepictorCalculations` 的角色（無 Depictor 版本）

雖然名稱中仍有「Depictor」，本專案實際上可在沒有 3D 視覺庫的情況下運作：  
`DepictorCalculations` 只是計算輸送帶上的一組參考點（`aafPos`），日後若要接 2D 或簡單 3D 視覺元件時可以直接沿用；  
在目前專案中，它不影響控制邏輯。

---

## 四、各支程式負責哪些功能？（由淺入深）

### 4.1 `GVL.st`

- 定義整個工作站的幾何位置與 Tripod 初始位置，以及自動／手動放環模式旗標。  

### 4.2 `Environment.st`

- 啟動轉盤與輸送帶，並管理圓錐／圓環的狀態機，輸出 `bRingOnTable` 與 `pActiveCone`。  

### 4.3 `Cone.st`

- 描述單一圓錐在輸送帶上的出現、運動與離開流程，並決定何時更新 PCS_2 綁定。  

### 4.4 `Ring.st`

- 描述單一圓環在轉盤上的運動、被機器人夾取與放到圓錐上的流程，並決定何時回到初始狀態。  

### 4.5 `Robot.st`

- 控制 Tripod 的整體 Pick & Place 流程，是主狀態機所在。  

### 4.6 `Tripod_PlanningPrg.st`

- 作為規劃任務佔位程式，未實作實際規劃演算法，未來可擴充為離線路徑產生等功能。  

### 4.7 `DepictorCalculations.st`

- 計算輸送帶路徑上的一組參考點，供簡化視覺化或日後擴充使用。

---

## 五、函式庫與函式／功能塊一覽

本專案的 `Libraries.md` 目前無內容，代表範例在 XML 中的 LibraryManager 未被解析出來，  
但從程式碼可推定至少使用了以下 SoftMotion 功能：

- <span class="cfg-func">MC_Power</span>、<span class="cfg-func">MC_MoveVelocity</span>、<span class="cfg-func">MC_MoveLinearAbsolute</span>、<span class="cfg-func">MC_MoveLinearRelative</span>、<span class="cfg-func">MC_SetCoordinateTransform</span>、<span class="cfg-func">MC_GroupEnable</span>。  
- <span class="cfg-func">MC_TrackConveyorBelt</span>、<span class="cfg-func">MC_TrackRotaryTable</span>。  
- <span class="cfg-func">TON</span>、三角函數等標準函數。

---

## 六、變數與常數一覽（重點）

### 6.1 全域常數與旗標

請參考 `Robotics_PickAndPlace` 範例中的整理（兩者 GVL 相同），這裡僅列出概念：

- `gcTripodTrans*`、`gcBeltTrans*`、`gcTableTrans*`：三大座標系位置。  
- `gcTCP_Ring`、`gcTripod*PosOrig`：取放高度與 Tripod 起始位置。  
- `gbSetRing`、`gbAutomatic`：圓環產生模式旗標。

### 6.2 狀態與輸出（簡要）

- `Robot.state`：整體 Pick & Place 狀態機。  
- `Environment.bRingOnTable`、`Environment.pActiveCone`：環／錐狀態。  
- `Ring.state`、`Cone.state`：各自小狀態機。  
- `Robot.bReadyForMotion`、`Robot.bRingAttached`：供 Ring 與上層判斷。

---

## 七、特別的觀念與設計重點

### 7.1 有／無 Depictor 的差異

在有 Depictor 的完整範例中，`DepictorCalculations` 資料會直接送進 3D 視覺元件；  
在本範例中，即使不使用 3D 視覺，你仍然可以：

- 在 2D 圖上畫出輸送帶路徑，或  
- 將 `aafPos` 資料導出到外部工具進行可視化。  

這讓控制邏輯與視覺呈現自然解耦合，適合在較輕量的環境中使用。

### 7.2 多狀態機協作

`Robot`、`Environment`、`Cone`、`Ring` 透過旗標與指標互相溝通，避免一支程式同時管理所有細節：  
這種拆分方式有助於維護與教學，也方便日後改寫單一部分（例如只換圓錐邏輯）。

---

## 八、重要參數與設定位置

- 任務週期：`TaskConfiguration.md`。  
- 軸與座標系：`DeviceTree_Axes.md`。  
- 幾何與模式：`GVL.st`。  
- Pick & Place 流程與動作細節：`Robot.st`、`Environment.st`、`Cone.st`、`Ring.st`。

---

## 九、建議閱讀與修改順序

1. 先閱讀本說明，掌握場景與整體流程。  
2. 查看 `TaskConfiguration.md`、`DeviceTree_Axes.md`、`GVL.st`。  
3. 依序閱讀 `Environment.st`、`Cone.st`、`Ring.st`，理解工件流動與 PCS_1 / PCS_2 的用法。  
4. 再閱讀 `Robot.st`，專注在 Pick & Place 狀態機如何呼應前述旗標。  
5. 如需視覺化，可參考 `DepictorCalculations.st` 的座標計算方式。

---

## 十、名詞對照

| 英文／符號 | 說明 |
|-----------|------|
| <span class="cfg-name">Tripod</span> | 三角機器人軸組，由三個線性軸構成 |
| <span class="cfg-name">PCS_1 / PCS_2</span> | 工件座標系 1 / 2，分別綁定到轉盤與輸送帶上的工件位置 |
| <span class="cfg-name">WCS</span> | 世界座標系，通常以機台基座為原點 |
| <span class="cfg-name">TCP</span> | Tool Center Point，工具中心點 |

---
