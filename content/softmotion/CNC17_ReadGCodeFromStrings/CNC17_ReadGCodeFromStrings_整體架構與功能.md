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

# CNC17_ReadGCodeFromStrings — 整體架構與功能說明

---

## 一、這個專案在做什麼？

本範例示範如何 **不使用檔案系統，而從程式內建字串／串流讀取 G-code**，並配合子程式表與 Lookup 機制執行 CNC 程式。核心是 <span class="cfg-func">SMC_ReadNCFromStream</span>：它將一組 `SMC_StringStream2` 當作 G-code 來源，搭配實作 <span class="cfg-type">SMC_INCLookup</span> 的 <span class="cfg-custom">LookupStream</span> 來解析子程式（例如 SUB1），最後再透過 <span class="cfg-func">SMC_NCInterpreter</span>、<span class="cfg-func">SMC_CheckVelocities</span> 與插補器驅動兩軸。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務配置

`TaskConfiguration.md`：

| 任務名稱 | 類型 | 週期 | 優先權 | POU 清單 |
|----------|------|------|--------|----------|
| BusTask | Cyclic | t#3ms | 1 | `Ipo` |
| PathTask | Cyclic | t#10ms | 10 | `Path` |
| VISU_TASK | Cyclic | t#100ms | 31 | `VisuElems.Visu_Prg` |

- **PathTask（Path）**：以 10 ms 週期讀取字串 G-code、解譯與速度檢查。  
- **BusTask（Ipo）**：以 3 ms 週期插補與驅動兩軸。

### 2.2 軸與裝置

`DeviceTree_Axes.md`：

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| X_Drive | SM_Drive_Virtual | - |
| Y_Drive | SM_Drive_Virtual | - |

兩支虛擬軸組成二軸龍門，由 `Ipo` 程式透過 <span class="cfg-func">SMC_TRAFO_Gantry2</span> / <span class="cfg-func">SMC_TRAFOF_Gantry2</span> 與 <span class="cfg-func">SMC_ControlAxisByPos</span> 驅動。

### 2.3 函式庫

`Libraries.md` 顯示：

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | 基礎運動控制。 |
| <span class="cfg-name">#SM3_Basic_Visu</span> | 視覺化輔助。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 凸輪相關。 |
| <span class="cfg-name">#SM3_CNC</span> | CNC 解碼、從串流讀取 G-code、插補等。 |
| <span class="cfg-name">#System_VisuElem3DPath</span> | 3D Path 視覺化。 |
| <span class="cfg-name">#System_VisuElemCamDisplayer</span> | 凸輪顯示。 |

---

## 三、控制流程：由淺入深

整體資料流如下：

> PathTask：`sGCode`（主程式字串）→ StringStream2 → ReadNCFromStream → NCInterpreter → CheckVelocities  
> BusTask：插補器 Ipo 從 Path 的 `cv.poqDataOut` 取樣 → 座標轉換 → 兩軸驅動

### 3.1 PathTask：從字串／串流讀取 G-code

`Path` 程式（`Path.st`）的重點在於：

1. **主程式字串 `sGCode`**：  
   ```text
   N0 F100
   N10 SUB1{10, 50, 0}
   N20 G1 Y50
   N30 SUB1{50, 20, 100}
   ```  
   這是一段簡化 G-code，呼叫子程式 `SUB1` 兩次，傳入不同參數。  
2. **子程式表 `aSubs`**：  
   - 型態為 `ARRAY[0..0] OF SubProgram`，內容為一個 SUB1 的宣告文字，內含三個參數 `#p1`、`#p2`、`#p3`，並定義三段 `G1 X...` 移動。  
3. **LookupStream FB `subs`**：  
   - 型態為 <span class="cfg-custom">LookupStream</span>，實作 <span class="cfg-type">SMC_INCLookup</span> 介面。  
   - 負責在 G-code 解譯遇到 SUB1 呼叫時，回傳對應的串流來源。  
4. **String Stream 與 ReadNCFromStream**：  
   - `aStringStream[0]`：在 `bExecute` 上升緣時，初始化為主程式 `sProgramName`（例如 "CNC"），並將 `sGCode` 寫入，標記 `SetEndOfData()`。  
   - `NUM_CHAINS := SMC_CNC_LibParams.MAX_SUBPROGRAM_NESTING_DEPTH+1`：給不同巢狀層級使用各自的 `SMC_StringStream2`。  
   - 在初始化時，`rnc.aStream[i] := aStringStream[i]` 將這些 StringStream 指派給 <span class="cfg-func">SMC_ReadNCFromStream</span> `rnc`。  
   - 執行時：`rnc(bExecute := bExecute, sentences := sentences, lookupCNCProgram := subs)`，從串流讀取 G-code 並產生 `sentences`。  
5. **RefillData 支援**：  
   - 若 `aStringStream[rnc.nActiveChain].refillData` 為 TRUE，代表因 G20 等跳轉導致需要重新填入同一串流，此時程式會重新將 `sGCode` 加回該 StringStream 並再度 `SetEndOfData()`。  
6. **解譯與速度檢查**：  
   - <span class="cfg-func">SMC_NCInterpreter</span> `interpreter` 使用 `sentences` 與緩衝 `aBufInterpreter` 產生路徑佇列。  
   - <span class="cfg-func">SMC_CheckVelocities</span> `cv` 對 `interpreter.poqDataOut` 做速度檢查並輸出 `poqPath`。  
7. **G-code Viewer**：  
   - <span class="cfg-func">SMC_GCodeViewer</span> `gcv` 以 `interpreter.GCodeText` 為來源，搭配 `bufGCV` 建立 3D Path 顯示用的資料，並追蹤 `Ipo.smci.actObjectId`。

### 3.2 BusTask：插補與軸控制

`Ipo` 程式（`Ipo.st`）：

```pascal
PROGRAM Ipo
VAR
	trafo: SMC_TRAFO_Gantry2;
	p1,p2: SMC_ControlAxisByPos;
	trafof: SMC_TRAFOF_Gantry2;
	smci: SMC_Interpolator;
	mcp1, mcp2: MC_Power;
END_VAR
```

雖然匯出檔中未包含完整實作，但對照 CNC10 / CNC01 類似結構，可推知：

- `mcp1` / `mcp2`：上電 `X_Drive` / `Y_Drive`。  
- `smci`：插補器，`poqDataIn := Path.cv.poqPath`。  
- `trafo` / `trafof`：將插補結果 Map 到兩軸。  
- `p1` / `p2`：使用 <span class="cfg-func">SMC_ControlAxisByPos</span> 將位置寫入 `X_Drive` / `Y_Drive`。

---

## 四、各支程式／功能塊負責哪些功能？

### 4.1 `Path.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 將硬編碼的主 G-code 字串 `sGCode` 與子程式表 `aSubs` 包裝成多個 `SMC_StringStream2`。  
  - 將這些 StringStream 提供給 <span class="cfg-func">SMC_ReadNCFromStream</span> `rnc` 使用（支援巢狀子程式）。  
  - 使用 <span class="cfg-custom">LookupStream</span> 將 G-code 內的子程式名稱（SUB1）映射到對應的串流。  
  - 呼叫 Interpreter / CheckVel 產生 `poqPath`。  
  - 搭配 GCodeViewer 提供視覺化資料。  

### 4.2 `LookupStream.st`

- **類型**：FUNCTION_BLOCK（實作 <span class="cfg-type">SMC_INCLookup</span>）。  
- **介面**：  
  - 輸入：`nNumSPs`（子程式數量）、`psp`（指向 SubProgram 陣列）。  
- **職責**：  
  - 在 <span class="cfg-func">SMC_ReadNCFromStream</span> 需要查詢某子程式時，根據 `psp` 陣列與名稱回傳對應的串流索引或內容。  
  - 實際邏輯封裝在匯出檔其餘部分，這裡只看到介面。  

### 4.3 `Ipo.st`

- **類型**：PROGRAM。  
- **職責**（依變數命名推估）：  
  - 上電 `X_Drive` / `Y_Drive`。  
  - 使用插補器 `smci` 對 `Path.cv.poqPath` 進行插補。  
  - 透過 `trafo` / `trafof` 將插補路徑轉成兩軸 SetPosition。  
  - 透過 `p1` / `p2`（<span class="cfg-func">SMC_ControlAxisByPos</span>）寫入軸位置。

---

## 五、函式庫與函式／功能塊一覽

| 名稱 | 類別 | 用途 |
|------|------|------|
| <span class="cfg-func">SMC_ReadNCFromStream</span> | FB | 從一組串流（如 StringStream）讀取 G-code，支援多層子程式。 |
| <span class="cfg-func">SMC_NCInterpreter</span> | FB | 將 `sentences` 解譯為幾何段佇列。 |
| <span class="cfg-func">SMC_CheckVelocities</span> | FB | 對路徑做速度檢查。 |
| <span class="cfg-func">SMC_GCodeViewer</span> | FB | 提供 G-code 與插補物件給 3D Path 等視覺化元件。 |
| <span class="cfg-type">SMC_StringStream2</span> | 型態 | 對應一段 G-code 字串的串流來源。 |
| <span class="cfg-type">SubProgram</span> | 型態 | 描述單一 SUB 程式名稱與內文。 |
| <span class="cfg-type">SMC_INCLookup</span> | 介面 | 讓使用者定義如何從子程式名稱查出對應 G-code 來源。 |
| <span class="cfg-func">SMC_Interpolator</span> | FB | 插補器。 |
| <span class="cfg-func">SMC_ControlAxisByPos</span> | FB | 軸位置控制。 |
| <span class="cfg-func">SMC_TRAFO_Gantry2</span> / <span class="cfg-func">SMC_TRAFOF_Gantry2</span> | FB | 2 軸龍門座標轉換。 |
| <span class="cfg-func">MC_Power</span> | FB | 軸上電。 |

---

## 六、變數與常數一覽

本範例未定義 GVL 檔；重要變數均在 `Path` 與 `Ipo` 內。

### 6.1 `Path` 主要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">bExecute</span> | <span class="cfg-type">BOOL</span> | 啟動讀取與解譯。 |
| <span class="cfg-local">sProgramName</span> | <span class="cfg-type">STRING</span> | 主程式名稱（例如 "CNC"）。 |
| <span class="cfg-local">sGCode</span> | <span class="cfg-type">STRING(255)</span> | 內建的主 G-code 內容。 |
| <span class="cfg-local">aSubs</span> | <span class="cfg-type">ARRAY[0..0] OF SubProgram</span> | 子程式表，目前只定義 SUB1。 |
| <span class="cfg-local">rnc</span> | <span class="cfg-type">SMC_ReadNCFromStream</span> | 串流版 ReadNC。 |
| <span class="cfg-local">interpreter</span> | <span class="cfg-type">SMC_NCInterpreter</span> | 解譯 G-code。 |
| <span class="cfg-local">cv</span> | <span class="cfg-type">SMC_CheckVelocities</span> | 速度檢查。 |
| <span class="cfg-local">gcv</span> | <span class="cfg-type">SMC_GCodeViewer</span> | 視覺化。 |
| <span class="cfg-local">sentences</span> | <span class="cfg-type">SMC_GSentenceQueue</span> | ReadNCFromStream 與 Interpreter 間的 G-code 句子隊列。 |
| <span class="cfg-local">aStringStream</span> | <span class="cfg-type">ARRAY[0..NUM_CHAINS-1] OF SMC_StringStream2</span> | 每一巢狀層級的字串串流。 |
| <span class="cfg-local">subs</span> | <span class="cfg-type">LookupStream</span> | 子程式名稱映射至串流的 Lookup FB。 |
| <span class="cfg-local">NUM_CHAINS</span> | <span class="cfg-type">UDINT</span> | 最大巢狀子程式層級 +1。 |

### 6.2 `Ipo` 主要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">smci</span> | <span class="cfg-type">SMC_Interpolator</span> | 插補器。 |
| <span class="cfg-local">trafo</span>, <span class="cfg-local">trafof</span> | <span class="cfg-type">SMC_TRAFO_Gantry2</span> / <span class="cfg-type">SMC_TRAFOF_Gantry2</span> | 座標轉換。 |
| <span class="cfg-local">p1</span>, <span class="cfg-local">p2</span> | <span class="cfg-type">SMC_ControlAxisByPos</span> | 軸位置控制。 |
| <span class="cfg-local">mcp1</span>, <span class="cfg-local">mcp2</span> | <span class="cfg-type">MC_Power</span> | 軸上電。 |

---

## 七、特別的演算法與觀念

### 7.1 從檔案到串流的思維轉換

在前面如 `CNC05_File` 一類範例，G-code 來源是檔案系統；本範例則改用：

- **主 G-code 用一個長字串表示**（`sGCode`）。  
- **子程式表 `aSubs` 用多個小字串表示**。  
- **StringStream2** 將這些字串包裝成「可反覆讀取的串流」。  

如此一來，G-code 可以來自任何來源：通訊資料、網路封包、資料庫欄位等，只要轉成字串並寫入 StringStream 即可，不再受限於檔案系統。

### 7.2 巢狀子程式與多串流

`NUM_CHAINS := SMC_CNC_LibParams.MAX_SUBPROGRAM_NESTING_DEPTH+1` 表示支援多層巢狀子程式；每一層有一個對應的 `SMC_StringStream2`，並由 ReadNCFromStream 的 `nActiveChain` 來指出當前正在處理哪一層。

當 G-code 中發生跳轉或呼叫子程式時：

- ReadNCFromStream 會切換 `nActiveChain`，並透過 `LookupStream` 決定該層應該讀哪個串流。  
- 當需要重新讀取某段（例如 G20 之後），會透過 `refillData` 要求重新把原始 G-code 字串塞回對應的 StringStream。

---

## 八、重要參數與設定位置

| 參數 | 檔案 / 位置 | 說明 |
|------|-------------|------|
| `sGCode` | `Path.st` | 主程式 G-code 字串，可改為由設定檔或通訊來源組成。 |
| `aSubs` | `Path.st` | 子程式表，新增 SUB 時需擴充此陣列與 LookupStream 的邏輯。 |
| `NUM_CHAINS` | `Path.st` 常數 | 最大巢狀深度 +1，必須與庫設定相容。 |
| BusTask/PathTask 週期 | `TaskConfiguration.md` | 影響串流讀取／解譯與插補平滑度。 |

---

## 九、建議閱讀與修改順序

1. 先看 `TaskConfiguration.md` 與 `DeviceTree_Axes.md`，理解任務與兩軸結構。  
2. 再看 `Path.st`，特別是 `sGCode`、`aSubs`、`aStringStream` 與 `SMC_ReadNCFromStream` 的關係。  
3. 接著閱讀 `LookupStream.st`，了解如何設計自己的子程式 Lookup。  
4. 最後看 `Ipo.st`，確認插補與軸控制如何接上 `Path.poqPath`。  
5. 若要實際應用，可將 `sGCode` 改為通訊接收到的字串，並在 `bExecute` 上升緣時把最新程式寫入 StringStream 中。

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">Stream</span> / 串流 | 一種「資料來源」抽象，可來自字串、檔案、通訊等。 |
| <span class="cfg-type">SMC_StringStream2</span> | SoftMotion 提供的字串串流實作，用於 ReadNCFromStream。 |
| <span class="cfg-type">SubProgram</span> | 描述子程式名稱與 G-code 內容的結構。 |
| <span class="cfg-type">SMC_INCLookup</span> | 讓使用者實作如何根據子程式名稱找到對應串流的介面。 |
| <span class="cfg-name">Read from Strings</span> | 在本範例中指：不從檔案系統，而是從程式內建的字串或通訊緩衝讀取 G-code。 |

