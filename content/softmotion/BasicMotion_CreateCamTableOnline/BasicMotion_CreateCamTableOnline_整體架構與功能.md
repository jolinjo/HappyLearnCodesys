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

# BasicMotion_CreateCamTableOnline — 整體架構與功能說明

---

## 一、這個專案在做什麼？

這個範例示範如何在 CODESYS SoftMotion 中「線上動態建立凸輪表（CamTable）」，並同時比較三種來源的凸輪：  
1. 事先離線建立的 <span class="cfg-name">CamOffline</span>。  
2. 在 MainTask 使用 <span class="cfg-custom">CamBuilder</span> 線上建立的 <span class="cfg-name">CamOnline</span>。  
3. 在獨立 BuilderTask 中建立、透過 <span class="cfg-global">GVL.safeCam</span> 分享的 <span class="cfg-name">CamOnlineMultitask</span>。  
最後讓三個從軸同時跟隨這三個凸輪，方便你在視覺化與 Trace 中比較「離線 vs 線上 vs 多工線上」的差異與使用方式。

---

## 二、使用情境與硬體／軸架構

### 2.1 任務與程式

根據 `TaskConfiguration.md`，本範例的任務配置如下：

| 任務名稱 | 類型 | 週期 | 優先權 | POU 清單 |
|----------|------|------|--------|----------|
| BuilderTask | Freewheeling | t#20ms | 10 | `MultitaskCamBuilder` |
| MainTask | Cyclic | t#20ms | 1 | `PLC_PRG` |
| VISU_TASK | Cyclic | t#100ms | 31 | `VisuElems.Visu_Prg` |

- **BuilderTask**：在背景執行，用來建立多工安全的凸輪並寫入 <span class="cfg-global">GVL.safeCam</span>。  
- **MainTask**：主控制邏輯，建立線上凸輪、觸發多工建立、讀回凸輪並驅動三個從軸。  
- **VISU\_TASK**：驅動視覺化程式，顯示 Master 與三個從軸的運動與凸輪曲線。  

### 2.2 軸配置

根據 `DeviceTree_Axes.md`，範例使用四條虛擬軸：

| 軸名稱 | 類型 | 角色 |
|--------|------|------|
| <span class="cfg-name">Master</span> | <span class="cfg-name">SM_Drive_Virtual</span> | 主軸，提供凸輪主軸座標與速度基準。 |
| <span class="cfg-name">SlaveOffline</span> | <span class="cfg-name">SM_Drive_Virtual</span> | 使用預先離線建立的 CamOffline。 |
| <span class="cfg-name">SlaveOnline</span> | <span class="cfg-name">SM_Drive_Virtual</span> | 使用 MainTask 線上建立的 CamOnline。 |
| <span class="cfg-name">SlaveOnlineMultitask</span> | <span class="cfg-name">SM_Drive_Virtual</span> | 使用 BuilderTask 線上建立並經 safeCam 分享的 CamOnlineMultitask。 |

`TraceConfig.md` 追蹤了 Master 與三個從軸的 SetPosition／SetVelocity／SetAcceleration，可用來比較三種凸輪來源在運動上的差異。

### 2.3 全域參數

`GVL.st` 中定義：

```text
{attribute 'qualified_only'}
VAR_GLOBAL
    safeCam : SMCB.CAM_REF_MULTICORE_SAFE;
END_VAR
```

<span class="cfg-global">safeCam</span> 是一個多工安全的凸輪參考物件，用來在 BuilderTask 與 MainTask 之間交換凸輪資料。  
在 BuilderTask 中由 <span class="cfg-custom">WriteMulticoreSafe()</span> 寫入，在 MainTask 中透過 `GetCopy()` 讀出。

---

## 三、控制流程：由淺入深

### 3.1 整體流程文字版

從整體角度來看，流程可以概括為：

> MainTask 線上建立一個凸輪 → 記錄 safeCam 狀態 → 叫 BuilderTask 去再建立一個凸輪寫入 safeCam → MainTask 等待 safeCam 更新並讀出第二個凸輪 → 四軸上電 → 三個從軸各自綁定 Offline／Online／OnlineMultitask 三種凸輪 → 啟動主軸運動，一次比較三種凸輪效果。

### 3.2 `PLC_PRG` 狀態機

`PLC_PRG` 中的 <span class="cfg-local">state</span> 依序經過以下幾個主要狀態（對照程式碼）：

1. **STATE\_CREATE\_ONLINE\_TABLE**  
   - 使用 <span class="cfg-custom">camBuilder</span> 在 MainTask 中組裝一條凸輪（三段 Poly5／Line／Poly5）。  
   - 呼叫 <span class="cfg-func">SMCB.InitCamRef()</span> 讓 `CamOnline` 參考 `camSegments` 陣列，接著 `camBuilder.Write(CamOnline)` 寫入凸輪資料。  
2. **STATE\_INIT\_ONLINE\_TABLE\_MULTITASK**  
   - 將 <span class="cfg-global">GVL.safeCam.CamId</span> 存入 `camIdBeforeCreate`，做為之後偵測「新凸輪是否寫入」的基準值。  
3. **STATE\_START\_CREATE\_ONLINE\_TABLE\_MULTITASK**  
   - 將 `MultitaskCamBuilder.BuildCam := TRUE`，通知 BuilderTask 建立第二份凸輪。  
4. **STATE\_READ\_ONLINE\_TABLE\_MULTITASK**  
   - 若 `MultitaskCamBuilder.Error` 為 TRUE，表示建立失敗，記錄 `ErrorId`。  
   - 若偵測到 <span class="cfg-global">GVL.safeCam.CamId</span> 與 `camIdBeforeCreate` 不同，表示 BuilderTask 已寫入新凸輪，此時呼叫 `safeCam.GetCopy()` 取得 `CamOnlineMultitask` 與 `camSegmentsMultitask`。  
5. **STATE\_POWER\_DRIVES**  
   - 依序啟動 Master 與三個從軸，並等待 `Status` 皆為 TRUE。  
6. **STATE\_SELECT\_TABLE**  
   - 使用三個 <span class="cfg-func">MC_CamTableSelect()</span>：  
     - `ctsSlaveOffline` → 使用 <span class="cfg-name">CamOffline</span>。  
     - `ctsSlaveOnline` → 使用 `CamOnline`。  
     - `ctsSlaveOnlineMultitask` → 使用 `CamOnlineMultitask`。  
   - 三者都 Done 後進入 STATE\_MOVEMENT。  
7. **STATE\_MOVEMENT**  
   - 以 <span class="cfg-func">MC_MoveVelocity()</span>（`mvMaster`）啟動 Master 軸固定速度運轉。  
   - 三個從軸對應的 <span class="cfg-func">MC_CamIn()</span> 同時 Execute，分別依照自己選擇的凸輪表運動。  

透過 Trace 與視覺化，你可以同時觀察三個從軸在相同主軸運動下的差異，驗證「線上建表」與「多工建表」是否與離線結果一致。

---

## 四、各支程式負責哪些功能？

### 4.1 `GVL.st` — 安全凸輪參考

- **類型**：全域變數表。  
- **內容重點**：  
  - <span class="cfg-global">safeCam</span>：<span class="cfg-type">SMCB.CAM_REF_MULTICORE_SAFE</span>，提供多工安全的凸輪參考交換機制。  
  - `qualified_only` 屬性讓程式必須以 `GVL.safeCam` 方式存取，避免名稱衝突。  

### 4.2 `MultitaskCamBuilder` — 多工線上建表程式

- **類型**：PROGRAM，掛載在 BuilderTask。  
- **職責**：  
  - 當 `BuildCam` 為 TRUE 時，於 BuilderTask 中使用 <span class="cfg-custom">camBuilder</span> 建立一條凸輪。  
  - 呼叫 `<span class="cfg-func">WriteMulticoreSafe()</span>` 將結果寫入 <span class="cfg-global">GVL.safeCam</span>，讓其他任務可以透過 `GetCopy()` 取得實際凸輪資料。  
  - 若建表或寫入過程發生錯誤，透過 `Error`／`ErrorId` 對外回報。  

### 4.3 `PLC_PRG` — 主控制與比較邏輯

- **類型**：PROGRAM，掛載在 MainTask。  
- **職責**：  
  - 在 MainTask 中建立一條線上凸輪（CamOnline）。  
  - 觸發 BuilderTask 建立另一條凸輪並寫入 safeCam，然後透過 `GetCopy()` 取得 CamOnlineMultitask。  
  - 將 CamOffline、CamOnline、CamOnlineMultitask 分別指定給三個從軸。  
  - 啟動主軸與三個從軸的 CamIn，提供比較三種來源凸輪的完整示範。  

---

## 五、函式庫與函式／功能塊一覽

### 5.1 函式庫

對照 `Libraries.md`，本範例使用：

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | 提供基本運動控制與 MC\_* 功能塊。 |
| <span class="cfg-name">#SM3_Basic_Visu</span> | SoftMotion 視覺化輔助。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 提供 <span class="cfg-name">CamBuilder</span> 與安全凸輪相關工具。 |
| <span class="cfg-name">#SM3_CNC</span> | 凸輪與 CNC 相關結構。 |
| <span class="cfg-name">#System_VisuElem3DPath</span> | 3D Path 視覺化元件。 |
| <span class="cfg-name">#System_VisuElemCamDisplayer</span> | 顯示凸輪曲線的視覺化元件。 |

### 5.2 主要函式與功能塊

| 名稱 | 類型 | 用途 | 主要引數 | 回傳／狀態 |
|------|------|------|----------|------------|
| <span class="cfg-custom">SMCB.CamBuilder</span> | 類別 | 以程式方式建立凸輪曲線。 | `<span class="cfg-func">Init()</span>`、`<span class="cfg-func">Append()</span>`、`<span class="cfg-func">Write()</span>`、`<span class="cfg-func">WriteMulticoreSafe()</span>`。 | `IsErrorPending()` 回報錯誤；`Write()` 與 `WriteMulticoreSafe()` 回傳 `SMC_ERROR`。 |
| <span class="cfg-func">SMCB.Poly5()</span> | 函數 | 建立五次多項式段落，提供平順加減速。 | 邊界條件 BoundImplicit／Bound。 | 回傳 `SMC_CAM_SEGMENT`。 |
| <span class="cfg-func">SMCB.Line()</span> | 函數 | 建立主從軸線性關係段。 | 起／終點邊界條件。 | 回傳 `SMC_CAM_SEGMENT`。 |
| <span class="cfg-func">SMCB.InitCamRef()</span> | 函數 | 將 `MC_CAM_REF` 指向陣列緩衝。 | <span class="cfg-arg">camRef</span>、<span class="cfg-arg">pSegments</span>、<span class="cfg-arg">arraySize</span>。 | 無明確回傳；修改 camRef。 |
| <span class="cfg-func">MC_Power()</span> | FUNCTION\_BLOCK | 四條軸上電與驅動啟動。 | <span class="cfg-arg">Axis</span>、<span class="cfg-arg">Enable</span>、<span class="cfg-arg">bDriveStart</span>、<span class="cfg-arg">bRegulatorOn</span>。 | `Status`、`Error`、`ErrorID`。 |
| <span class="cfg-func">MC_MoveVelocity()</span> | FUNCTION\_BLOCK | 主軸以速度模式運動。 | <span class="cfg-arg">Axis</span>、<span class="cfg-arg">Execute</span>、<span class="cfg-arg">Velocity</span> 等。 | `Error`、`ErrorID`。 |
| <span class="cfg-func">MC_CamTableSelect()</span> | FUNCTION\_BLOCK | 選擇從軸所使用的凸輪表。 | <span class="cfg-arg">Master</span>、<span class="cfg-arg">Slave</span>、<span class="cfg-arg">CamTable</span>、<span class="cfg-arg">Execute</span> 等。 | `Done`、`Error`、`CamTableID`。 |
| <span class="cfg-func">MC_CamIn()</span> | FUNCTION\_BLOCK | 啟動從軸的凸輪運動。 | <span class="cfg-arg">Master</span>、<span class="cfg-arg">Slave</span>、<span class="cfg-arg">CamTableID</span>、<span class="cfg-arg">Execute</span>。 | `InSync`、`Error`、`ErrorID`。 |
| <span class="cfg-func">safeCam.GetCopy()</span> | 函數 | 從 <span class="cfg-global">GVL.safeCam</span> 複製一份實際可用的 `MC_CAM_REF` 與 Segments。 | <span class="cfg-arg">camRef</span>、<span class="cfg-arg">pCamSegments</span>、<span class="cfg-arg">arraySize</span>。 | `SMC_ERROR`。 |

---

## 六、變數與常數一覽

本範例未使用 RETAIN／PERSISTENT 變數。

### 6.1 全域變數（`GVL.st`）

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-global">safeCam</span> | <span class="cfg-type">SMCB.CAM_REF_MULTICORE_SAFE</span> | 多工安全的凸輪參考，用來在 BuilderTask 與 MainTask 間交換凸輪。 |

### 6.2 `MultitaskCamBuilder` 變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-arg">BuildCam</span> | <span class="cfg-type">BOOL</span> | 輸入觸發旗標，TRUE 時執行一次建表流程。 |
| <span class="cfg-arg">Error</span> | <span class="cfg-type">BOOL</span> | 若建表或寫入 safeCam 失敗則為 TRUE。 |
| <span class="cfg-arg">ErrorId</span> | <span class="cfg-type">SMC_ERROR</span> | 具體錯誤碼。 |
| <span class="cfg-local">camBuilder</span> | <span class="cfg-type">SMCB.CamBuilder</span> | 建立凸輪曲線的建構器。 |

### 6.3 `PLC_PRG` 重要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">state</span> | <span class="cfg-type">UDINT</span> | 主狀態機，決定目前處於哪個流程步驟。 |
| <span class="cfg-local">error</span> | <span class="cfg-type">SMC_ERROR</span> | 發生錯誤時儲存錯誤碼。 |
| <span class="cfg-local">camBuilder</span> | <span class="cfg-type">SMCB.CamBuilder</span> | MainTask 中用來建立 CamOnline 的建構器。 |
| <span class="cfg-local">camSegments</span> / <span class="cfg-local">camSegmentsMultitask</span> | <span class="cfg-type">ARRAY OF SMC_CAM_SEGMENT</span> | 分別儲存 CamOnline 與 CamOnlineMultitask 的 Segments。 |
| <span class="cfg-local">CamOnline</span> / <span class="cfg-local">CamOnlineMultitask</span> | <span class="cfg-type">MC_CAM_REF</span> | 線上與多工線上建立的凸輪參考。 |
| <span class="cfg-local">camIdBeforeCreate</span> | <span class="cfg-type">UDINT</span> | safeCam 建表前的 CamId，用於偵測新凸輪是否寫入完成。 |
| <span class="cfg-local">mcpMaster</span>... | <span class="cfg-type">MC_Power</span> | 四個軸的電源功能塊。 |
| <span class="cfg-local">mvMaster</span> | <span class="cfg-type">MC_MoveVelocity</span> | 控制 Master 軸速度的命令。 |
| <span class="cfg-local">ctsSlaveOffline</span>... | <span class="cfg-type">MC_CamTableSelect</span> | 三個從軸對應的凸輪表選擇器。 |
| <span class="cfg-local">camInSlaveOffline</span>... | <span class="cfg-type">MC_CamIn</span> | 三個從軸對應的 CamIn。 |

狀態常數（`STATE_*`）則明確標示出流程的每個階段，方便在 Trace 中觀察流程推進。

---

## 七、特別的演算法與觀念

### 7.1 多工安全的凸輪建立流程

這個範例帶出一個實務上非常重要的觀念：  
**在多任務環境下建立或修改凸輪時，必須透過安全機制來「交換」凸輪，而不能直接共用未保護的指標或記憶體。**

關鍵元件包括：

- <span class="cfg-custom">CamBuilder.WriteMulticoreSafe(GVL.safeCam)</span>：在 BuilderTask 中建立好凸輪後，將結果寫入一個多工安全的容器 `safeCam`。  
- `<span class="cfg-global">GVL.safeCam.CamId</span>`：每建立一個新凸輪，CamId 都會改變，MainTask 只要比對 ID 是否變化，就能知道是否有新版本可以讀取。  
- `<span class="cfg-func">safeCam.GetCopy()</span>`：在 MainTask 中用這個函數取得一份獨立的 `MC_CAM_REF` 與 Segments 陣列，不需要擔心 BuilderTask 同時修改記憶體。  

### 7.2 比較 Offline／Online／Multitask 三種來源

雖然三個凸輪在本範例中使用相同的幾何參數（Poly5＋Line＋Poly5），但它們代表三種不同的維護模式：

- **CamOffline**：透過工具離線編輯、匯入或隨專案一起提供，適合穩定的加工流程。  
- **CamOnline**：由程式在 MainTask 中動態建立，適合根據配方或條件即時調整。  
- **CamOnlineMultitask**：由專責任務建立，MainTask 只負責讀取，適合計算量大或需分離實時計算的情況。  

這個範例讓三個從軸同時跟隨三種來源的凸輪，你可以在視覺化與 Trace 中驗證它們的曲線是否一致，以及在不同建表模式下，系統的負載與反應。

---

## 八、重要參數與設定位置

| 參數／設定 | 所在位置 | 說明 |
|------------|----------|------|
| <span class="cfg-global">safeCam</span> | `GVL.st` | 多工安全的凸輪參考，BuilderTask 寫入、MainTask 讀出。 |
| <span class="cfg-const">MAX_NUM_OF_CAM_SEGMENTS</span> | `PLC_PRG` 常數區 | 陣列大小，限制可使用的 Segments 數量。 |
| CamBuilder 段落邊界（160/140 → 200/220、360/360） | `PLC_PRG` 與 `MultitaskCamBuilder` | 決定凸輪形狀；可調整以測試不同運動曲線。 |
| MainTask／BuilderTask 週期 | `TaskConfiguration.md` | 影響線上建表與多工回應時間。 |
| <span class="cfg-local">mvMaster.Velocity</span> 等 | `PLC_PRG` 中 `STATE_MOVEMENT` | 決定主軸運動速度與加減速特性。 |

在真實機台上，你可以保留這個架構，將建立凸輪的部分換成根據工單資料、配方或外部系統計算的參數。

---

## 九、建議閱讀與修改順序

1. **先看 `GVL.st`**  
   - 了解 <span class="cfg-global">safeCam</span> 的角色，以及為什麼需要多工安全的容器。  
2. **再看 `MultitaskCamBuilder`**  
   - 搭配註解理解 BuildCam 如何觸發一次性建表，以及 WriteMulticoreSafe 的用法。  
3. **接著看 `PLC_PRG` 的狀態機**  
   - 從 STATE\_CREATE\_ONLINE\_TABLE 開始，一步一步追蹤到 STATE\_MOVEMENT，弄清楚每個狀態在做什麼。  
4. **最後對照 `DeviceTree_Axes.md` 與 `TraceConfig.md`**  
   - 在視覺化和 Trace 中觀察 Master 與三個從軸的曲線，確認 Offline／Online／Multitask 三者是否如預期一致。  

修改時建議先只動凸輪幾何（Poly5／Line 參數），確認你能預測運動效果；再考慮調整任務週期與主軸速度。

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">CamTable</span> | 主從軸位置對應表，用來定義凸輪運動。 |
| <span class="cfg-name">CamOffline</span> | 離線建立並隨專案提供的凸輪表。 |
| <span class="cfg-name">CamOnline</span> | 由 MainTask 線上建立的凸輪表。 |
| <span class="cfg-name">CamOnlineMultitask</span> | 由 BuilderTask 建立並透過 safeCam 分享的凸輪表。 |
| <span class="cfg-global">GVL.safeCam</span> | 多工安全凸輪參考，用於跨任務交換凸輪。 |
| <span class="cfg-custom">CamBuilder</span> | 用程式組裝凸輪 Segments 的工具物件。 |
| <span class="cfg-func">MC_CamTableSelect()</span> | SoftMotion 功能塊，用來選擇從軸使用哪一個凸輪表。 |
| <span class="cfg-func">MC_CamIn()</span> | SoftMotion 功能塊，讓從軸依照選定的凸輪表運動。 |

