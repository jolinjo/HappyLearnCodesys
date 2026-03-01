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

# BasicMotion_CamExportAndImport — 整體架構與功能說明

---

## 一、這個專案在做什麼？

這個範例示範如何在 CODESYS SoftMotion 中，使用 <span class="cfg-name">CamBuilder</span> 以程式方式建立一條凸輪曲線，並透過 <span class="cfg-func">SMC_WriteCAM()</span> 匯出成檔案，再使用 <span class="cfg-func">SMC_ReadCAM()</span> 從檔案匯入回系統。  
換句話說，它教你「如何把記憶體中的 Cam 轉成檔案」以及「如何把檔案中的 Cam 再讀回來」，方便在實機專案中管理、備份或交換凸輪表。

---

## 二、使用情境與硬體／通訊架構

在實務應用中，越複雜的機械越需要根據產線需求調整凸輪曲線（例如改變加速度、動作角度、同步範圍等）。將凸輪存成檔案可以帶來幾個好處：

- 方便在不同機台之間交換同一組 Cam 設定。  
- 可以在現場調整後匯出備份，未來需要時再匯入。  
- 可由上位系統或離線工具產生 Cam 檔，再由 PLC 匯入使用。  

本範例不直接操作軸，只專注在「Cam 資料結構 ↔ 檔案」的轉換，因此 `DeviceTree_Axes.md` 中沒有實際解析到軸；你可以把它視為「純資料處理、與軸脫鉤」的示範。

任務設定（來自 `TaskConfiguration.md`）如下：

| 任務名稱 | 類型 | 週期 | 優先權 | POU 清單 |
|----------|------|------|--------|----------|
| MainTask | Cyclic | t#20ms | 1 | <span class="cfg-name">PLC_PRG</span> |

所有建立與匯出／匯入的流程都在 <span class="cfg-name">PLC_PRG</span> 裡完成，每 20 ms 執行一次狀態機。

函式庫（來自 `Libraries.md`）：

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | SoftMotion 基本運動功能庫。 |
| <span class="cfg-name">#SM3_Basic_Visu</span> | SoftMotion 視覺化輔助庫。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 提供 <span class="cfg-name">CamBuilder</span> 等凸輪建構工具。 |
| <span class="cfg-name">#SM3_CNC</span> | CNC 相關功能庫（本範例主要使用 Cam 相關結構）。 |

---

## 三、控制流程：由淺入深

### 3.1 一句話版流程

> 進入程式後，自動建立一條簡單的凸輪 → 檢查是否有錯誤 → 若成功則匯出成 CAM 檔 → 再從該檔案把凸輪讀回來，確認檔案可正確使用。

### 3.2 狀態機步驟說明

<span class="cfg-name">PLC_PRG</span> 使用 <span class="cfg-local">state</span> 作為狀態機，重要狀態如下（對照原始程式）：

1. **<span class="cfg-const">STATE_CREATE_CAM</span>（建立凸輪）**  
   - 呼叫 <span class="cfg-local">camBuilder</span>.Init() 清空建構器。  
   - 依序 <span class="cfg-keyword">Append</span> 三個 <span class="cfg-name">Segments</span>：  
     - 第 1 段：<span class="cfg-func">Poly5()</span>，起／終點皆採用 <span class="cfg-func">BoundImplicit()</span>，表示與前一段／預設條件平順銜接。  
     - 第 2 段：<span class="cfg-func">Line()</span>，從 (160,140) 線性移動到 (200,220)，並指定加速度邊界。  
     - 第 3 段：<span class="cfg-func">Poly5()</span>，最後收斂到 (360,360) 並讓末端速度為 0。  
   - 檢查 <span class="cfg-local">camBuilder.IsErrorPending()</span> 是否有錯誤；若無，呼叫 <span class="cfg-func">SMCB.InitCamRef()</span> 初始化 <span class="cfg-local">camRefExport</span>，再呼叫 <span class="cfg-local">camBuilder.Write(camRefExport)</span> 將凸輪資料寫入緩衝區。  
   - 若寫入成功（<span class="cfg-local">error</span> = <span class="cfg-const">SMC_NO_ERROR</span>），狀態轉為 **<span class="cfg-const">STATE_EXPORT_CAM</span>**，否則進入錯誤路徑。  

2. **<span class="cfg-const">STATE_EXPORT_CAM</span>（匯出 CAM 檔案）**  
   - 呼叫 <span class="cfg-func">SMC_WriteCAM()</span>（變數名 <span class="cfg-local">writeCam</span>），指定 <span class="cfg-arg">cam</span>=<span class="cfg-local">camRefExport</span>、<span class="cfg-arg">bExecute</span>=<span class="cfg-keyword">TRUE</span>、<span class="cfg-arg">sFileName</span>=<span class="cfg-name">'exportedCam.cam'</span>。  
   - 若 <span class="cfg-local">writeCam.bDone</span> 為 <span class="cfg-keyword">TRUE</span>，表示匯出完成，狀態轉為 **<span class="cfg-const">STATE_START_IMPORT_CAM</span>**。  
   - 若 <span class="cfg-local">writeCam.bError</span> 為 <span class="cfg-keyword">TRUE</span>，表示匯出失敗，狀態轉為錯誤路徑。  

3. **<span class="cfg-const">STATE_START_IMPORT_CAM</span>（從檔案匯入凸輪）**  
   - 呼叫 <span class="cfg-func">SMC_ReadCAM()</span>（變數名 <span class="cfg-local">readCam</span>），指定 <span class="cfg-arg">bExecute</span>=<span class="cfg-keyword">TRUE</span>、<span class="cfg-arg">sFileName</span>=<span class="cfg-name">'exportedCam.cam'</span>。  
   - 若 <span class="cfg-local">readCam.bDone</span> 為 <span class="cfg-keyword">TRUE</span>，狀態轉為 **<span class="cfg-const">STATE_DONE</span>**，代表完成整個建立＋匯出＋匯入流程。  
   - 若 <span class="cfg-local">readCam.bError</span> 為 <span class="cfg-keyword">TRUE</span>，則進入錯誤狀態。  

4. **<span class="cfg-const">STATE_DONE</span> / <span class="cfg-const">STATE_ERROR</span>**  
   - **<span class="cfg-const">STATE_DONE</span>**：流程結束，通常保持在此狀態，讓使用者在監看視窗中確認結果。  
   - **<span class="cfg-const">STATE_ERROR</span>**：說明在建立、匯出或匯入任一階段發生錯誤，可進一步顯示 `error` 或 `writeCam`／`readCam` 的錯誤碼來除錯。  

整體來說，這個狀態機是「單趟流程」：程式啟動一次後跑完建立與讀寫檔案，之後就停在 <span class="cfg-const">STATE_DONE</span> 或 <span class="cfg-const">STATE_ERROR</span>，方便你在監看畫面確認結果。

---

## 四、各支程式負責哪些功能？

本範例只有一個程式 <span class="cfg-name">PLC_PRG</span>，但裡面整合了幾個核心元件。

### 4.1 <span class="cfg-name">PLC_PRG</span> — 凸輪建立與匯出／匯入示範

- **類型**：PROGRAM。  
- **主要職責**：  
  - 使用 <span class="cfg-name">CamBuilder</span> 建立一條簡單但具有代表性的凸輪曲線。  
  - 將凸輪內容寫入 `MC_CAM_REF` 所指向的緩衝區。  
  - 呼叫 <span class="cfg-func">SMC_WriteCAM()</span> 匯出為 CAM 檔案。  
  - 呼叫 <span class="cfg-func">SMC_ReadCAM()</span> 從檔案匯入，驗證檔案可以被完整讀回。  
- **適合學習的觀點**：  
  - 從這個程式你可以學到「如何組裝 Cam 資料結構」以及「如何控制寫檔與讀檔流程」，而不被軸或機構細節干擾。  

---

## 五、函式庫與函式／功能塊一覽

### 5.1 函式庫（再次整理）

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | 基本運動控制與資料結構。 |
| <span class="cfg-name">#SM3_Basic_Visu</span> | 與視覺化相關的輔助功能。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 提供 <span class="cfg-name">CamBuilder</span> 類別與相關工具。 |
| <span class="cfg-name">#SM3_CNC</span> | CNC／凸輪相關結構與工具。 |

### 5.2 主要函式與功能塊

| 名稱 | 類型 | 用途 | 主要引數（IN / IN\_OUT） | 回傳／狀態 |
|------|------|------|--------------------------|------------|
| <span class="cfg-custom">SMCB.CamBuilder</span> | 類別／物件 | 以程式方式建立一條凸輪，內部維護 Segments 清單。 | <span class="cfg-func">Init()</span>：重設內容；<span class="cfg-func">Append()</span>：加入一段 Segment；<span class="cfg-func">Write()</span>：將內容寫入 CamRef。 | <span class="cfg-func">IsErrorPending()</span>：檢查是否有錯誤；`Write()` 回傳 `SMC_ERROR`。 |
| <span class="cfg-func">SMCB.Poly5()</span> | 函數 | 建立五次多項式型態的 Segment，適合做平順的起動／停止。 | <span class="cfg-arg">BoundStart</span>、<span class="cfg-arg">BoundEnd</span>：起終點邊界條件。 | 傳回一個 `SMC_CAM_SEGMENT`。 |
| <span class="cfg-func">SMCB.Line()</span> | 函數 | 建立線性 Segment，在主軸座標與從軸座標間做直線插補。 | <span class="cfg-arg">BoundStart</span>、<span class="cfg-arg">BoundEnd</span>。 | 傳回一個 `SMC_CAM_SEGMENT`。 |
| <span class="cfg-func">SMCB.Bound()</span> | 函數 | 建立具體的邊界條件，如 (MasterPos, SlavePos, AccLimit, JerkLimit)。 | 位置與限制條件。 | 傳回一個邊界結構。 |
| <span class="cfg-func">SMCB.BoundImplicit()</span> | 函數 | 使用隱含邊界條件（例如「延續前一段的速度」），常用於段與段之間平順銜接。 | 無顯式位置輸入。 | 傳回一個邊界結構。 |
| <span class="cfg-func">SMCB.InitCamRef()</span> | 函數 | 將 `MC_CAM_REF` 指向一個 Segments 陣列與其大小。 | <span class="cfg-arg">CamRef</span>、<span class="cfg-arg">pSegments</span>、<span class="cfg-arg">sizeBytes</span>。 | 將 CamRef 結構填妥，無明確回傳值。 |
| <span class="cfg-func">SMC_WriteCAM()</span> | FUNCTION\_BLOCK | 將 `MC_CAM_REF` 內容寫成 CAM 檔案。 | <span class="cfg-arg">cam</span>：來源凸輪；<span class="cfg-arg">bExecute</span>：觸發寫檔；<span class="cfg-arg">sFileName</span>：檔名。 | `bDone`：寫檔完成；`bError`：寫檔錯誤。 |
| <span class="cfg-func">SMC_ReadCAM()</span> | FUNCTION\_BLOCK | 從 CAM 檔讀回凸輪並載入系統。 | <span class="cfg-arg">bExecute</span>；<span class="cfg-arg">sFileName</span>。 | `bDone`：讀檔完成；`bError`：讀檔錯誤。 |

---

## 六、變數與常數一覽

本範例未使用 RETAIN／PERSISTENT 變數。

### 6.1 <span class="cfg-name">PLC_PRG</span> 中的主要變數

| 名稱 | 型態 | 預設值／來源 | 說明 |
|------|------|--------------|------|
| <span class="cfg-local">state</span> | <span class="cfg-type">UDINT</span> | 0 | 控制流程的狀態機。 |
| <span class="cfg-local">error</span> | <span class="cfg-type">SMC_ERROR</span> | 0 | 儲存 CamBuilder 或相關操作回傳的錯誤碼。 |
| <span class="cfg-local">camBuilder</span> | <span class="cfg-type">SMCB.CamBuilder</span> | - | 建立凸輪的建構器物件。 |
| <span class="cfg-local">camSegmentsExport</span> | <span class="cfg-type">ARRAY[...] OF SMC_CAM_SEGMENT</span> | - | 存放凸輪 Segments 的緩衝陣列。 |
| <span class="cfg-local">camRefExport</span> | <span class="cfg-type">MC_CAM_REF</span> | 由 <span class="cfg-func">InitCamRef()</span> 設定 | 指向 <span class="cfg-local">camSegmentsExport</span> 的參考，用於匯出／匯入。 |
| <span class="cfg-local">writeCam</span> | <span class="cfg-type">SMC_WriteCAM</span> | - | 呼叫以將凸輪寫成檔案。 |
| <span class="cfg-local">readCam</span> | <span class="cfg-type">SMC_ReadCAM</span> | - | 呼叫以從檔案讀回凸輪。 |
| <span class="cfg-local">camId</span> | <span class="cfg-type">UDINT</span> | - | 暫存凸輪 ID 或其他識別用途（目前程式中未進一步使用）。 |

### 6.2 狀態與常數

| 名稱 | 型態 | 值 | 說明 |
|------|------|----|------|
| <span class="cfg-const">STATE_CREATE_CAM</span> | <span class="cfg-type">UDINT</span> | 0 | 建立凸輪的階段。 |
| <span class="cfg-const">STATE_EXPORT_CAM</span> | <span class="cfg-type">UDINT</span> | 10 | 將凸輪寫成 CAM 檔案。 |
| <span class="cfg-const">STATE_START_IMPORT_CAM</span> | <span class="cfg-type">UDINT</span> | 20 | 從 CAM 檔開始讀回凸輪。 |
| <span class="cfg-const">STATE_DONE</span> | <span class="cfg-type">UDINT</span> | 500 | 整個流程完成。 |
| <span class="cfg-const">STATE_ERROR</span> | <span class="cfg-type">UDINT</span> | 1000 | 任一階段出錯。 |
| <span class="cfg-const">MAX_NUM_OF_CAM_SEGMENTS</span> | <span class="cfg-type">INT</span> | 3 | 本範例使用三段 Segments 組成凸輪。 |
| <span class="cfg-const">EXPORT_CAM_FILE_NAME</span> | <span class="cfg-type">STRING</span> | <span class="cfg-name">'exportedCam.cam'</span> | 匯出與匯入共用的檔名。 |

TraceConfig 顯示本專案未特別設定 Trace 變數，但在實機應用中，你可以加入 `state`、`error` 或檔案操作狀態來協助除錯。

---

## 七、特別的演算法與觀念

### 7.1 使用 CamBuilder 組裝凸輪

這個範例的精華在於：「不用手動編輯 CAM 檔，而是在程式裡組裝出一條凸輪曲線」。  
關鍵步驟如下：

1. 呼叫 <span class="cfg-local">camBuilder</span>.Init() 清空建構器。  
2. 使用多個 <span class="cfg-func">Append()</span>，把 <span class="cfg-func">Poly5()</span> 與 <span class="cfg-func">Line()</span> 建立的 Segments 依序加入。  
3. 確認 <span class="cfg-func">IsErrorPending()</span> 沒有錯誤。  
4. 呼叫 <span class="cfg-func">SMCB.InitCamRef()</span> 設定好 <span class="cfg-local">camRefExport</span> 指向 <span class="cfg-local">camSegmentsExport</span>。  
5. 呼叫 <span class="cfg-func">Write()</span> 把內容填到 <span class="cfg-local">camRefExport</span>，準備給 <span class="cfg-func">SMC_WriteCAM()</span> 使用。  

初學者可以這樣理解：  
「CamBuilder 就像是『凸輪編輯器』的後端 API，你在程式中一段段描述主從軸的關係，它幫你整理成可以匯出或被軸使用的資料格式。」

### 7.2 記憶體結構與檔案之間的關係

`MC_CAM_REF` 扮演的角色，是把「程式記憶體中的 Segments 陣列」包裝成一個標準介面，供讀寫函式塊（例如 <span class="cfg-func">SMC_WriteCAM()</span>）使用。  
透過這個設計，你可以：

- 將 CamBuilder 建好的凸輪直接餵給軸的 Cam 運動功能塊。  
- 或是先匯出成檔案、再在另一台機器上匯入。  

這個範例專注在第二種情境：確認「從記憶體 → 檔案 → 記憶體」的往返流程是可行的。

---

## 八、重要參數與設定位置

雖然本範例不驅動實際軸，但還是有幾個關鍵參數會影響凸輪形狀與檔案管理：

| 參數／設定 | 所在位置 | 作用說明 |
|------------|----------|----------|
| <span class="cfg-const">MAX_NUM_OF_CAM_SEGMENTS</span> | <span class="cfg-name">PLC_PRG</span> 常數區 | 陣列大小，決定最多可以容納幾段 Segments。 |
| <span class="cfg-const">EXPORT_CAM_FILE_NAME</span> | <span class="cfg-name">PLC_PRG</span> 常數區 | 匯出與匯入使用的檔名，實務上可改成有意義的名字（例如依機種或工單命名）。 |
| <span class="cfg-func">SMCB.Line()</span> 與 <span class="cfg-func">SMCB.Poly5()</span> 的邊界條件 | <span class="cfg-name">PLC_PRG</span> 中的 <span class="cfg-const">STATE_CREATE_CAM</span> | 決定凸輪曲線在主軸座標與從軸座標上的關係，以及平順程度。 |
| MainTask 週期 t#20ms | `TaskConfiguration.md` | 影響建構與匯出／匯入的觸發頻率（本例中主要是流程邏輯，對數值精度影響不大）。 |

在實際專案中，你可以把這個範例中的常數與邊界條件改成「真實機械的凸輪參數」，再匯出給現場工程師或上位系統使用。

---

## 九、建議閱讀與修改順序

1. **先讀 <span class="cfg-name">PLC_PRG</span> 中的變數與常數宣告**
   - 搞清楚 <span class="cfg-local">camBuilder</span>、<span class="cfg-local">camSegmentsExport</span>、<span class="cfg-local">camRefExport</span>、<span class="cfg-local">writeCam</span>、<span class="cfg-local">readCam</span> 各自扮演的角色。  
2. **再看 <span class="cfg-const">STATE_CREATE_CAM</span> 區塊**  
   - 對照本說明第七章，理解 <span class="cfg-func">Poly5()</span> 與 <span class="cfg-func">Line()</span> 這三段 Segments 的差異，並試著修改邊界參數觀察效果。  
3. **接著看 <span class="cfg-const">STATE_EXPORT_CAM</span> 與 <span class="cfg-const">STATE_START_IMPORT_CAM</span>**  
   - 理解 <span class="cfg-func">SMC_WriteCAM()</span> 與 <span class="cfg-func">SMC_ReadCAM()</span> 的呼叫方式與錯誤處理。  
4. **最後試著修改檔名與錯誤處理行為**  
   - 例如改成在錯誤狀態中重試、或是把錯誤碼輸出到某個監看變數中。  

這樣的順序可以讓你先掌握資料流與物件關係，再動手改動重要參數而不會迷路。

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">Cam</span> | 描述主從軸位置關係的凸輪曲線。 |
| <span class="cfg-name">CamBuilder</span> / <span class="cfg-custom">SMCB.CamBuilder</span> | 以程式方式建立凸輪的工具物件。 |
| <span class="cfg-name">Segment</span> / <span class="cfg-type">SMC_CAM_SEGMENT</span> | 凸輪中的一小段軌跡，可為線性或多項式。 |
| <span class="cfg-type">MC_CAM_REF</span> | 指向凸輪資料的參考結構，供讀寫函式塊使用。 |
| <span class="cfg-func">SMC_WriteCAM()</span> | 將凸輪資料寫入 CAM 檔案的功能塊。 |
| <span class="cfg-func">SMC_ReadCAM()</span> | 從 CAM 檔案讀回凸輪資料的功能塊。 |
| <span class="cfg-name">CAM file</span> | 儲存凸輪定義的檔案格式，可在不同專案或機台之間交換。 |

