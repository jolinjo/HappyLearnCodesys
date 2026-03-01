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

**顏色對應**：<span class="cfg-func">內建函數 / 功能塊</span> <span class="cfg-global">全域變數</span> <span class="cfg-local">區域變數</span> <span class="cfg-custom">自訂函數 / 方法</span> <span class="cfg-const">常數</span> <span class="cfg-keyword">保留字</span> <span class="cfg-type">型態</span> <span class="cfg-arg">引數</span> <span class="cfg-name">專有名詞</span>

# PLCopenMulti — 整體架構與功能說明

---

## 一、這個專案在做什麼？（一句話＋情境）

這個範例示範在一個主虛擬軸與一個從軸的架構下，如何準備多軸凸輪同步控制所需的功能塊：包含兩個軸的上電、凸輪表選取、凸輪同步與虛擬主軸的速度控制，作為進入「多軸凸輪應用」前的中階練習。

可以把它想像成「一個主軸帶著一個從軸，沿著設定好的凸輪曲線運動」，例如包裝機裡由主軸帶著切刀軸依特定輪廓動作。

---

## 二、使用情境與硬體／通訊架構

### 2.1 硬體與軸配置

根據 `DeviceTree_Axes.md`，本範例包含兩根虛擬軸：

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| <span class="cfg-name">Drive</span> | <span class="cfg-name">SM_Drive_Virtual</span> | - |
| <span class="cfg-name">Virtual</span> | <span class="cfg-name">SM_Drive_Virtual</span> | - |

- <span class="cfg-name">Virtual</span>：可以視為「主軸」，由速度指令帶動。  
- <span class="cfg-name">Drive</span>：可以視為「從軸」，其運動輪廓由凸輪（Cam）定義，相對主軸運動。

### 2.2 任務與週期

`TaskConfiguration.md` 顯示有兩個任務：

| 任務名稱 | 類型 | 週期 | 優先權 | POU 清單 |
|----------|------|------|--------|----------|
| Task | Cyclic | t#4ms | 1 | MOTION_PRG |
| VISU_TASK | Cyclic | t#100ms | 10 | VisuElems.Visu_Prg |

- `Task` 每 4ms 執行一次 `MOTION_PRG`，負責主軸／從軸與凸輪同步邏輯。  
- `VISU_TASK` 每 100ms 執行 `VisuElems.Visu_Prg`，用於可視化顯示與操作。

### 2.3 資料流與角色分工

- `MOTION_PRG` 應該負責：  
  - 兩根軸的上電（透過 <span class="cfg-func">MC_Power</span>）。  
  - 選取並應用凸輪表（<span class="cfg-func">MC_CamTableSelect</span>、<span class="cfg-func">MC_CamIn</span>）。  
  - 控制虛擬主軸的速度（<span class="cfg-func">MC_MoveVelocity</span>）。  
  - 輔助位置判斷（<span class="cfg-func">SMC_GetTappetValue</span>）。  

在目前轉出的程式中主要保留了變數宣告與功能塊準備，實際的狀態機與呼叫邏輯可以根據教學需要再補充。

---

## 三、控制流程：由淺入深

### 3.1 整體概念

雖然 `MOTION_PRG.st` 目前只看到變數宣告，但從功能塊型態可以推測出典型的多凸輪控制流程：

1. 對主軸 <span class="cfg-name">Virtual</span> 與從軸 <span class="cfg-name">Drive</span> 進行上電與啟動。  
2. 使用 <span class="cfg-func">MC_CamTableSelect</span> 選取合適的凸輪表（Cam Table）。  
3. 使用 <span class="cfg-func">MC_CamIn</span> 讓從軸依照凸輪表與主軸保持同步。  
4. 使用 <span class="cfg-func">MC_MoveVelocity</span> 讓主軸以固定速度運轉，帶動從軸執行周期性運動。  
5. 視需求使用 <span class="cfg-func">SMC_GetTappetValue</span> 判斷當前是否位在特定凸輪區段，以觸發其他邏輯。

### 3.2 初學者可以這樣理解

如果你已經看過 PLCopenSingle 的單軸範例，可以把這個案例想成：

- 把「速度模式」從單軸提升到「主軸」，由主軸決定整體節奏。  
- 把「絕對定位」換成「依照凸輪曲線運動的從軸」，從軸不再直接給位置，而是依照主軸角度與凸輪表運動。

這樣一來，整個系統的時間基準與運動節奏都由主軸控制，從軸只負責「依規則追隨」。

---

## 四、各支程式負責哪些功能？（由淺入深）

目前範例目錄中只有 `MOTION_PRG.st`，其餘 POU 與可視化程式在專案中管理。

### 4.1 `MOTION_PRG.st`

- **類型**：<span class="cfg-keyword">PROGRAM</span>  
- **職責（依變數宣告推估）**：  
  - 透過 <span class="cfg-local">power1</span>、<span class="cfg-local">power2</span> 對兩根軸上電與啟動。  
  - 用 <span class="cfg-local">TableSelect</span> 選取要使用的凸輪表。  
  - 用 <span class="cfg-local">CamIn</span> 啟動從軸與主軸之間的凸輪同步。  
  - 用 <span class="cfg-local">MoveVirtual</span> 控制主軸 <span class="cfg-name">Virtual</span> 的速度。  
  - 用 <span class="cfg-local">Tappet</span> 做區段判斷（例如：現在是否處於「切刀動作區」、「等待區」等）。

---

## 五、函式庫與函式／功能塊一覽（用途、引數、回傳）

### 5.1 函式庫清單（對照 `Libraries.md`）

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | 提供基本運動控制功能塊（<span class="cfg-func">MC_Power</span>、<span class="cfg-func">MC_MoveVelocity</span> 等）。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 提供凸輪表的建立與管理功能。 |
| <span class="cfg-name">#System_VisuElem3DPath</span> | 視覺化 3D 運動路徑用的系統庫。 |
| <span class="cfg-name">#System_VisuElemCamDisplayer</span> | 用來在視覺化畫面中顯示凸輪曲線。 |

### 5.2 功能塊簡介

#### 5.2.1 <span class="cfg-func">MC_Power()</span>

- 用途與引數說明同先前範例，這裡透過 <span class="cfg-local">power1</span>、<span class="cfg-local">power2</span> 對主軸與從軸分別上電。

#### 5.2.2 <span class="cfg-func">MC_CamTableSelect()</span>

- **用途**：選取一張凸輪表並建立相對應的 CamTableID，供 <span class="cfg-func">MC_CamIn</span> 使用。  
- **主要引數（概念性）**：  
  - <span class="cfg-arg">Master</span> / <span class="cfg-arg">Slave</span>：指定主軸與從軸。  
  - <span class="cfg-arg">CamTable</span>：要選取的凸輪表名稱。  
  - <span class="cfg-arg">Execute</span>：TRUE 時啟動選取動作。  
- **重要輸出**：  
  - <span class="cfg-arg">CamTableID</span>：供 <span class="cfg-func">MC_CamIn</span> 使用的識別碼。  

#### 5.2.3 <span class="cfg-func">MC_CamIn()</span>

- **用途**：依指定的凸輪表，讓從軸追隨主軸的位移。  
- **常見引數**：  
  - <span class="cfg-arg">Master</span> / <span class="cfg-arg">Slave</span>：主軸／從軸。  
  - <span class="cfg-arg">CamTableID</span>：來自 <span class="cfg-func">MC_CamTableSelect</span> 的 ID。  
  - 其他參數（例如 StartMode、BufferMode）則決定如何啟動與切換。

#### 5.2.4 <span class="cfg-func">SMC_GetTappetValue()</span>

- **用途**：依主軸位置判斷目前是否落在某段凸輪區間，常用於分段觸發邏輯（例如「進刀段」、「退刀段」）。  

#### 5.2.5 <span class="cfg-func">MC_MoveVelocity()</span>

- 控制主軸 <span class="cfg-name">Virtual</span> 的速度，使整個多軸系統的節奏可控。

---

## 六、變數與常數一覽

本範例沒有獨立 GVL 檔案，所有變數都在 `MOTION_PRG.st` 中宣告。

### 6.1 `MOTION_PRG.st` 內的變數

| 名稱 | 類別 | 型態 | 預設值 | 說明 |
|------|------|------|--------|------|
| <span class="cfg-local">power1</span>, <span class="cfg-local">power2</span> | 區域變數 | <span class="cfg-type">MC_Power</span> | 功能塊預設 | 分別用來對主軸與從軸上電。 |
| <span class="cfg-local">TableSelect</span> | 區域變數 | <span class="cfg-type">MC_CamTableSelect</span> | 功能塊預設 | 選取要使用的凸輪表。 |
| <span class="cfg-local">CamIn</span> | 區域變數 | <span class="cfg-type">MC_CamIn</span> | 功能塊預設 | 依凸輪表控制從軸與主軸同步。 |
| <span class="cfg-local">Tappet</span> | 區域變數 | <span class="cfg-type">SMC_GetTappetValue</span> | 功能塊預設 | 判斷是否處於特定凸輪段。 |
| <span class="cfg-local">MoveVirtual</span> | 區域變數 | <span class="cfg-type">MC_MoveVelocity</span> | 功能塊預設 | 控制虛擬主軸 <span class="cfg-name">Virtual</span> 的速度。 |

---

## 七、特別的演算法與觀念

### 7.1 主從軸與凸輪同步的概念

在多軸應用中，一個常見的設計是：

- 以一根主軸（例如輸送帶或主馬達）作為系統節奏來源。  
- 讓其他軸（切刀、壓輪…）透過凸輪曲線相對主軸運動。  

這個範例的結構正好對應到這個觀念：  
<span class="cfg-name">Virtual</span> 當主軸，<span class="cfg-name">Drive</span> 當從軸，而 <span class="cfg-func">MC_CamIn</span> 則負責把「主軸位置 → 從軸位置」的對應關係落實到運動控制上。

---

## 八、重要參數與設定位置（實作時對照）

### 8.1 軸與任務

| 項目 | 名稱 | 說明 |
|------|------|------|
| 主軸 | <span class="cfg-name">Virtual</span> | <span class="cfg-name">SM_Drive_Virtual</span>，由 <span class="cfg-func">MC_MoveVelocity</span> 控制。 |
| 從軸 | <span class="cfg-name">Drive</span> | <span class="cfg-name">SM_Drive_Virtual</span>，透過凸輪表與主軸同步。 |
| 任務 | <span class="cfg-name">Task</span> | 週期 4ms，執行 `MOTION_PRG`。 |
| 任務 | <span class="cfg-name">VISU_TASK</span> | 週期 100ms，執行 `VisuElems.Visu_Prg`。 |

### 8.2 凸輪與運動參數

實際的凸輪表內容定義於專案與 <span class="cfg-name">SM3_CamBuilder</span> 相關設定，這裡只需記得：

- 要先選取凸輪表（<span class="cfg-func">MC_CamTableSelect</span>）。  
- 再由 <span class="cfg-func">MC_CamIn</span> 使用選到的 <span class="cfg-arg">CamTableID</span> 進行同步。  
- 主軸的速度設定在 <span class="cfg-func">MC_MoveVelocity</span> 裡，會直接影響從軸的整體節奏。

---

## 九、建議閱讀與修改順序（給初學者）

1. **先看 `DeviceTree_Axes.md`**  
   - 了解哪一根軸扮演主軸、哪一根軸扮演從軸。  
2. **再閱讀 `MOTION_PRG.st` 的變數宣告**  
   - 將各個功能塊名稱與角色對起來（上電、主軸速度、凸輪選取、凸輪同步、區段判斷）。  
3. **最後對照第五章的功能塊說明與原始專案中的 VISU 畫面**  
   - 觀察凸輪曲線如何影響從軸運動，以及主軸速度變化如何改變整體節奏。

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">Virtual</span> | 本範例中的虛擬主軸名稱。 |
| <span class="cfg-name">Drive</span> | 本範例中的虛擬從軸名稱。 |
| <span class="cfg-func">MC_CamTableSelect</span> | 選取凸輪表並產生 CamTableID 的功能塊。 |
| <span class="cfg-func">MC_CamIn</span> | 依照凸輪表讓從軸追隨主軸的功能塊。 |
| <span class="cfg-func">SMC_GetTappetValue</span> | 用來判斷主軸位置是否在特定區段的函數。 |

