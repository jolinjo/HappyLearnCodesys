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

# IO Configuration I/O 組態與 Device Tree 教學整理

> 本文件基於 CODESYS Offline Help 中下列主題整理而成：  
> - `Configuring I/O Links`（`_cds_struct_io_configuration.html`）  
> - `Device Tree and Device Editor`（`_cds_device_tree_device_editor.html`）  
> - `Mapping a Hardware Structure in the Device Tree`（`_cds_mapping_hardware_in_device_tree.html`）  
> - `Configuring Devices and I/O Mapping`（`_cds_configuring_devices_mapping_ios.html`）  
> 目標是用實務角度說明 Device Tree 與 I/O Mapping 的使用方式，而不是逐字翻譯原始說明。

---

## 1. 整體概念總覽 Overview

在 CODESYS 中，**IO Configuration I/O 組態** 主要包含兩個層面：

- **Device Tree 裝置樹**
  - 以樹狀方式描述實際控制網路中的硬體結構：PLC、Fieldbus、I/O 模組、驅動器等。
  - 每個節點對應一個 **Device 物件**，背後由「Device Description 裝置描述檔」定義能力與參數。
- **I/O Mapping I/O 對應**
  - 把裝置的 **實體 I/O 通道（Inputs / Outputs）**，連結到專案中的 **變數或 Function Block 實例**。
  - 讓應用程式可以以「變數」的方式讀寫硬體，而不用直接處理位址。

實務上，可以把整個流程想成：

1. 在 **Device Tree** 中 **建立硬體結構**（加入 PLC、Fieldbus、I/O 模組）。
2. 透過 **Device Editor** 設定通訊參數、掃描實際硬體。
3. 在 **I/O Mapping** 畫面中，將 I/O 通道 **Mapping 到變數或 FB**。
4. 在 ST 程式中使用這些變數，達成控制邏輯。

---

## 2. Device Tree 裝置樹概念

### 2.1 Device Tree 的角色

根據 `Device Tree and Device Editor`：

- Device Tree 顯示整個 **控制器與現場匯流排拓樸**：
  - 根節點是 `<project name>`（專案名稱）。
  - 底下可以有一個或多個 **Device 物件**（目標裝置 / PLC）。
  - 每個 Device 物件下方，可以再掛 Fieldbus、驅動器、I/O 模組等。
- 可在此完成：
  - 新增 / 更新 / 刪除裝置。
  - 掃描實際硬體（Scan Devices / Scan for Devices）。
  - 設定通訊與 I/O Mapping。

### 2.2 節點類型與階層

常見節點：

- `<project name>`
  - 象徵整個專案的根節點。
- `Device`（例如 `CODESYS Control Win`、實際 PLC 型號）
  - 對應單一控制器或軟體 PLC。
  - 通常會帶有一個 `PLC Logic` 子節點。
- `PLC Logic`
  - 純組織用途，用來承載：
    - `Application` 物件
    - `GVL` / `Text List` / `Visualization` 等程式物件。
- `Application`
  - 一個應用程式執行體，底下可以掛：
    - `POU`（PROGRAM / FUNCTION_BLOCK / FUNCTION）
    - `GVL`、`Task Configuration`、Library Manager 等。
- Fieldbus / I/O Modules / Drives / Devices
  - 對應真實匯流排與 I/O 模組，例如 `CAN-bus`、`CANopen_Device`、`EtherCAT Master` 等。

### 2.3 插入與命名規則

官方建議的命名與插入規則（節錄重點）：

- 只能在 `<project name>` 下方插入 **Device 物件**。
- `Application` 一定插在某個 **可程式化 Device** 的 `PLC Logic` 之下。
- 名稱建議：
  - 長度不超過 80 字元（超過會有編譯器警告）。
  - 僅使用英數字與底線 `_`。
  - 第一個字元必須是字母或底線。
- 允許 **Parent / Child Application** 結構：
  - Child Application 可以存取 Parent 的物件，反向不行。
  - 進行 Online Change 時，如果修改 Parent，Child 可能會被從控制器移除，需要重下載。

---

## 3. 建立硬體結構 Mapping a Hardware Structure

### 3.1 從標準專案開始

根據 `Mapping a Hardware Structure in the Device Tree`，一般建議流程如下：

1. 在 `File → New Project` 中選擇 **Standard Project**。
2. 選擇目標裝置，例如：
   - `CODESYS Control Win`。
3. 建立後，在 Device Tree 中會自動出現：
   - `Device (CODESYS Control Win)`  
   - `PLC Logic`  
   - `Application`  
   - `Library Manager`、`PLC_PRG`、`Task Configuration` 等。

這個結構就是最基本的「單一 PLC + 單一 Application」架構。

### 3.2 加入 Fieldbus 與 I/O 模組

將硬體拓樸映射到 Device Tree 的典型步驟：

1. 在 `Device` 節點上點右鍵，選擇 **Add Device**。
2. 在對話框中選擇適當的 Fieldbus，例如：
   - `CAN-bus`、`EtherCAT Master`、`PROFINET Controller`…。
3. 在新加入的 Fieldbus 上再次使用 **Add Device**：
   - 插入 `CANopen_Device`、I/O 模組或驅動器等。
4. 如需更換型號，可使用 **Update Device**：
   - 在同一階層以不同裝置型號取代現有節點，保留可相容的下層組態。

這樣建立起來的 Device Tree，應盡量貼近實際現場的 PLC + 匯流排 + I/O 配置。

### 3.3 掃描現場硬體 Scan for Devices

若現場硬體已接線完成，可以反向由硬體掃描來產生 Device Tree 結構：

1. 在 Device Tree 中選擇某個控制器或 Fieldbus 節點。
2. 右鍵選擇 **Scan for Devices**。
3. CODESYS 會：
   - 建立暫時連線至控制器。
   - 掃描目前匯流排上的裝置（站號、型號等）。
4. 在掃描結果對話框中：
   - 可選擇 `Show differences to project` 只顯示「尚未在專案內」的裝置。
   - 使用 `Copy to Project` 將硬體實際配置套入 Device Tree。

這個方式特別適合：

- 現場裝置已由他人安裝好，開發者只需「認領」既有硬體配置。

---

## 4. Device Editor 與 I/O Mapping 基本觀念

### 4.1 Device Editor 概要

在 Device Tree 中 **雙擊某個 Device 節點**，會開啟對應的 **Device Editor**，可在其中設定：

- 通訊設定（Communication Settings）。
- 匯流排與模組參數。
- `I/O Mapping` 標籤頁（連結 I/O 通道與變數）。
- `PLC Settings`、`Status`、`IEC Objects` 等其他頁面。

不同裝置類型可能擁有：

- 通用的 **Generic Device Editor** 標籤。
- 由裝置描述檔提供的 **裝置專屬標籤**。

### 4.2 I/O Mapping 是什麼？

根據 `Configuring Devices and I/O Mapping` → `General information about I/O mapping`：

- **I/O Mapping** 就是把「裝置的 Input / Output 通道」映射到「專案中的變數」：
  - 可以是既有變數（如 `Application.PLC_PRG.xStartButton`）。
  - 也可以在 I/O Mapping 內 **直接建立新的全域變數**。
- 幾個重要原則：
  - 映射到 **Input** 的變數 **在程式中不可寫入**（只讀）。
  - 一個變數 **只能映射到一個 Input 通道**。
  - 可以在 I/O Mapping 中指定變數對應的 **初始值 / Default Value**。
  - 裝置可以決定是否允許：
    - 映射至結構（STRUCT）。
    - 映射至 Function Block 實例。
  - 可修改或固定 I/O 位址（如 `QB0` → `QB1`），以符合實際接線配置。

### 4.3 AT 宣告與 I/O Mapping 的取捨

除了在 I/O Mapping 中做 Mapping，也可以在程式碼使用 **AT 宣告** 直接指定位址，例如：

```iecst
VAR_GLOBAL
    xStart AT %IX0.0 : BOOL;
END_VAR
```

但官方明確提醒：

- Device Configuration 經常會變動（例如插拔模組、改位址）。
- 建議 **優先使用 Device Editor 中的 I/O Mapping**，讓位址配置由裝置描述與編輯器負責管理。
- 使用 AT 宣告時，需注意：
  - 只適用於 Local / Global 變數，不可用於 Function Block 的 I/O 參數。
  - 無法產生「隱含的 Force 變數」。

---

## 5. I/O Mapping 實務流程範例

以下示範一個常見場景：  
**將實體輸入點（例如 `%IX0.0`）對應到 ST 程式中的變數，並在程式中使用。**

### 5.1 宣告目標變數（既有變數映射）

在 `PLC_PRG` 或其他 POU 中宣告變數：

```iecst
VAR
    xStartButton  : BOOL;   (* 啟動按鈕輸入 *)
    xMotorEnable  : BOOL;   (* 馬達啟動信號輸出 *)
END_VAR
```

### 5.2 在 I/O Mapping 連結既有變數

1. 在 Device Tree 中，雙擊某個支援 I/O Mapping 的 Device 或模組。
2. 開啟 `<device name> I/O Mapping` 標籤頁。
3. 在表格中找到對應的輸入通道（例如型別為 `BOOL` 的輸入點）。
4. 在 **Variable 欄位** 雙擊該列：
   - 使用右側的 `...`（Input Assistant）選擇 `Application.PLC_PRG.xStartButton`。
5. 完成後會看到：
   - 該通道的位址被「刪除線」標示，代表它現在由變數管理。
   - Mapping 欄會顯示「已映射到既有變數」的圖示。

這樣一來，控制程式就可以透過 `xStartButton` 直接讀取實體輸入狀態。

### 5.3 在 I/O Mapping 直接建立新變數

若尚未宣告變數，也可以在 I/O Mapping 直接建立：

1. 在 `Variable` 欄中雙擊某個輸入或輸出通道。
2. 直接輸入一個簡單變數名稱，例如 `xEmergencyStop`。
3. 按下 Enter：
   - CODESYS 會自動在專案中建立一個 **隱含全域變數**。
   - 並將這個變數與該通道位址做映射。

之後即可在任何 POU 中使用 `xEmergencyStop`，就像一般的全域變數。

### 5.4 Byte / Word 通道與位元通道

很多 I/O 模組會以 **BYTE / WORD / DWORD** 表示一組通道，並在其下方展開各個 bit 通道：

- 你可以選擇：
  - 在 **根節點**（例如 `%QB0`）上映射一個整數／字節型別變數。
  - 或在各個 **bit 通道**（例如 `%QB0.0`, `%QB0.1`）上分別映射 `BOOL` 變數。
- 編輯器會強制遵守以下規則：
  - 只能選擇「整個 Byte 映射一次」**或**「bit-by-bit 分散映射」，不能同時兩種都設定。

範例：假設你映射了整個 `QB0` 至變數 `byOutputs`，程式可以這樣寫：

```iecst
VAR
    byOutputs : BYTE;
END_VAR

(* 將第 0、1 bit 設為 1，其餘保留 *)
byOutputs := byOutputs OR 16#03;
```

---

## 6. Online Config Mode 與硬體測試

在沒有完整應用程式之前，也可以利用 **Online Config Mode** 來快速驗證 I/O 接線與匯流排狀態。

### 6.1 Simple Online Configuration Mode

根據 `Checking the controller configuration with the help of the Online Config Mode command`：

- 在 Device Tree 中，針對某個 PLC 物件：
  - 右鍵 → `Online Config Mode`。
- CODESYS 會：
  - 建立一個隱含的應用程式 `HiddenOnlineConfigModeApp`。
  - 自動下載到 PLC，並初始化一次所有 I/O。
  - 讓你能在沒有正式程式的情況下：
    - 讀取 I/O 狀態。
    - 在 I/O Mapping 視窗中直接寫入輸出。
    - 檢查診斷訊息與硬體狀態。

在此模式下：

- I/O Mapping 介面中沒有 `Prepared Value` 欄位。
- 直接編輯 `Current Value` 就會立即寫入輸出。

### 6.2 Advanced Online Configuration Mode（Parameter Mode）

若控制器上已經有正式應用程式，且裝置支援：

- 使用 `Online Config Mode` 之後，可以在對話框中選擇 **Parameter Mode**。
- 這樣可以：
  - 不需標準 Login / Download 就讀取裝置參數。
  - 保持現有應用程式不被影響。
- 適合在現場只想「看參數、不動程式」的維護情境。

---

## 7. I/O Mapping 進階功能與常見設定

### 7.1 讀取 PLC 參數檔到組態

若 PLC 上的 I/O 參數曾被其他方式修改（例如 HMI/Visualization）：

- 控制器上可能存在 `IoConfig.par` 參數檔。
- 可以在 Device Editor 中使用：
  - `Read PLC Parameter File to Configuration` 指令，  
  將現場實際使用的參數讀回專案中，保持一致。

### 7.2 修改與固定 I/O 位址

在 I/O Mapping 中，可以針對通道的 **根位址** 做修改，例如：

- 將 `QB0` 改成 `QB1`，以符合實際接線。
- 修改後該通道會出現「位址固定」圖示。
- 之後即使在 Device Tree 中調整模組順序，CODESYS 也不會自動改寫這個位址。

若要恢復自動配置：

- 再次編輯位址欄位，清空內容並按 Enter，  
位址會回到裝置描述預設的配置。

### 7.3 產生隱含 Force 變數

在 `PLC Settings` 中啟用：

- `Generate force variables for IO mapping`

編譯後，系統會為每一個有 I/O Mapping 的通道建立兩個隱含變數：

- `<device>_<channel>_<IECaddress>_force : BOOL`
  - 控制是否啟用強制。
- `<device>_<channel>_<IECaddress>_value : <channel type>`
  - 指定要強制的值。

實務應用（簡化範例）：

```iecst
VAR
    xForceStart       : BOOL;  (* 來自 HMI 的啟動測試按鈕 *)
END_VAR

(* 假設系統產生的隱含變數名稱如下，只為示意 *)
VAR_EXTERNAL
    Dev1_DI0_%IX0_0_force : BOOL;
    Dev1_DI0_%IX0_0_value : BOOL;
END_VAR

IF xForceStart THEN
    Dev1_DI0_%IX0_0_value := TRUE;
    Dev1_DI0_%IX0_0_force := TRUE;
ELSE
    Dev1_DI0_%IX0_0_force := FALSE;
END_IF;
```

注意限制：

- 只有在 I/O Mapping 中「有變數映射」的通道，才會產生 Force 變數。
- 透過 AT 宣告映射的 I/O 位址，不會自動產生這些 Force 變數。

### 7.4 監看 I/O Mapping 與跨裝置編輯

在專案中若有多個 PLC / Device：

- 可以在 Device Tree 根節點上使用 **Edit I/O Mapping** 指令：
  - 彙整顯示所有裝置的 I/O Mapping。
  - 支援依變數名稱搜尋與篩選。
- 也可以在特定 Device 物件上使用同樣指令：
  - 僅顯示該 Device 及其子節點的 I/O Mapping。

這對於大型系統中追蹤某個變數的 I/O 映射關係特別有幫助。

---

## 8. 實務建議與常見錯誤

### 8.1 實務建議

- **先畫出硬體拓樸，再建立 Device Tree**
  - 建議先用簡單圖示標出 PLC、匯流排與 I/O 模組，再依圖建立或掃描 Device Tree。
- **優先使用 I/O Mapping，而不是全部用 AT 宣告**
  - 除非是非常固定的特殊位址，否則交由 Device Editor 管理位置較易維護。
- **清楚命名變數與裝置**
  - 例如：`xStart_Machine1`、`xDoorClosed_Safety`，利於後續搜尋與維護。
- **善用 Online Config Mode 測試接線**
  - 尤其在程式尚未完成前，先確認硬體接線與通訊是否正常。
- **為重要 I/O 建立 Force 變數視覺化頁面**
  - 在調機與維護階段，可以直接透過 HMI 驗證輸出動作。

### 8.2 常見錯誤與陷阱

- **同一變數映射到多個 Input**
  - 會違反 I/O Mapping 限制，導致編譯錯誤或邏輯混亂。
- **同時對同一位址使用 I/O Mapping 與 AT 宣告**
  - 可能造成重複寫入或不可預期結果，應避免。
- **變更 Device Tree 結構卻忘記檢查 I/O Mapping**
  - 插拔模組或改變順序後，未重新檢查位址，容易導致 I/O 對錯點。
- **在測試時啟用 Force，卻忘記關閉**
  - 建議在調機流程中明確列出「解除所有 Force」的步驟，或在程式中提供一鍵清除機制。

---

## 9. 小結：I/O 組態在專案中的定位

1. **Device Tree** 是實際硬體結構的「地圖」，決定 PLC 與匯流排／裝置的拓樸。
2. **I/O Mapping** 把這張地圖上的每一個 I/O 點，對應到程式中的「變數與 Function Block」。
3. 善用 **Scan for Devices**、**Online Config Mode** 與 **Force 變數**，可以大幅簡化現場導入與除錯時間。
4. 往後在學習 Task、變數型別與除錯工具時，都會頻繁回到這個主題；可把本文件視為「Device Tree 與 I/O Mapping 的總覽入口」，並搭配其他教學（例如 Application Programming、Variables & Types、Debug and Monitoring）一起閱讀。

