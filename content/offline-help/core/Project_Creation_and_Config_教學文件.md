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

# Project Creation and Configuration 專案建立與設定 教學整理

> 本文件依據 Offline Help 中 `Creating and Configuring a Project`、`Creating Standard Projects`、`Adding Objects`、`Changing the Compiler Version` 等章節整理而成，說明如何從零開始建立 CODESYS 專案並完成基本設定。

---

## 1. 什麼是 CODESYS 專案？What is a project?

在 CODESYS 中，一個 **Project 專案** 是一個完整的工程單位，包含：

- **純程式物件（POUs）**
  - Programs、Function Blocks、Functions。
  - Global Variable Lists（GVL）。
- **讓應用程式能在 PLC 上執行所需的其它物件**
  - Task Configuration（任務設定）。
  - Library Manager。
  - Device / I/O 組態。
  - Symbol Configuration。
  - 可視化（Visualization）。
  - 外部檔案（例如設定檔、腳本）。

其它幾個重點：

- 一個 Project 可以包含 **多個 Application** 與 **多個 Device**。
- 裝置相關與 Application 相關的物件，透過 **Devices View（Device Tree）** 管理。
- 專案層級（Project‑wide）的 POUs，透過 **POUs View** 管理。
- 專案的基本資訊與設定放在：
  - `Project Settings`（編譯、語言、Security 等）。
  - `Project Information`（作者、版本、描述、檔案資訊）。
- 每個專案都記錄了 **建立時所用的 CODESYS 版本**：
  - 當你用另一版本開啟時，IDE 會提示是否需要更新檔案格式、Library 版本等。

實務建議：

- 對於正式專案，建議在 `Project Information` 中清楚填寫：
  - 專案用途、硬體平台、CODESYS 版本、主要開發者。
  - 方便日後維護與交接。

---

## 2. 建立 Standard Project Creating Standard Projects

Offline Help 的建議流程如下，這裡改寫為實務步驟。

### 2.1 建立新專案

1. 於主選單點選 `File → New Project`。
2. 在專案範本列表中選擇：
   - `Projects → Standard Project`。
3. 輸入：
   - `Name 專案名稱`：例如 `MyProject`。
   - `Location 儲存路徑`。
4. 按下 `OK` 後，會出現 **Standard Project** 對話框。

### 2.2 選擇裝置與語言

在 Standard Project 對話框中：

- **Device**：
  - 例如選擇 `CODESYS Control Win` 或目標 PLC 所對應的 Device。
- **PLC_PRG in**：
  - 建議選擇 `Structured Text (ST)` 作為主要程式語言。

按下 `OK` 後：

- 在視窗標題列可以看到專案名稱，例如 `MyProject`。
- 在 Device Tree 中自動建立結構，包括：
  - `Device`（你的 PLC 或 SoftPLC）。
  - 其下的 `PLC Logic`。
  - `Application` 節點，並已包含：
    - `Library Manager`：預設載入 `Standard.library`（基本計數器、計時器、字串函式等）。
    - `Task Configuration`：預設 `MainTask` 會執行標準 Program `PLC_PRG`。

此時，只要在 `PLC_PRG` 中撰寫正確的程式，就可以直接下載並於 PLC 上運行，不一定需要再建立其它 Program。

> 註：新版 Service Pack 預設會啟用 `Project → Project Settings → Security → Integrity check`，協助偵測專案完整性問題。

---

## 3. 在專案中加入物件 Adding Objects

`Adding Objects` 章節示範了在專案中新增各種物件的方式。

### 3.1 基本新增流程

1. 在 Device Tree 或 POU Tree 中選擇一個節點，例如 `Application`。
2. 在主選單選 `Project → Add Object`。
3. 依目前選取節點的類型，CODESYS 會列出可新增的物件清單。

### 3.2 範例：新增一個 ST Program

1. 在 Device Tree 中選擇 `Application`。
2. `Project → Add Object → POU`。
3. 在 `Add POU` 對話框中設定：
   - `Type`：`Program`。
   - `Implementation language`：`Structured Text (ST)`。
   - `Name`：例如 `MainControl`。
4. 按 `Add` 後：
   - 在 Device Tree 的 `Application` 下會新增一個 `MainControl` Program 物件。

接著，你可以：

- 在 `Task Configuration` 中建立或修改 Task，讓它呼叫 `MainControl`。
- 或把此 Program 當成子程序，用於其它 Program / FB 中。

### 3.3 物件屬性與資料夾

- 於 Device Tree 或 POU Tree 中選擇任一物件，右鍵選單選 `Properties`：
  - 可設定物件相關參數，若啟用 User Management，亦可在此限制讀寫權限。
- 為了整理結構，可在某些節點下建立 **Folder**：
  - 選取節點 → 右鍵 `Add Folder` → 輸入資料夾名稱。
  - 再透過拖曳方式將物件移入資料夾。
  - 注意：Device node 的層級結構本身不能任意新增自訂資料夾，只能在允許的位置使用 Folder 物件做邏輯分組。

### 3.4 從空白處新增物件到 POUs

若未在 Device Tree 中選取特定物件，只是在 UI 空白處聚焦時選擇 `Project → Add Object`：

- 新增的物件預設會放到 **POUs View**，例如 Text List、通用 POU 等。

---

## 4. 編譯器版本設定 Changing the Compiler Version

> 此段內容來自 `Changing the Compiler Version` 章節，但要注意：在較新版本（尤其模組化之後），官方逐步淡化單一「Compiler Version」概念。此處以 Offline Help 的描述為主，並補充實務建議。

### 4.1 Compiler Version 的角色

在早期架構中：

- 專案可以在 **不同 CODESYS 版本** 間移動，但透過 **相同 Compiler Version** 產生出一致的程式碼。
- Compiler Version 設定存在於 `Project → Project Settings → Compile options` 或 Project Environment 中。

### 4.2 重要選項與注意事項

在 `Project Environment – Compiler version` 對話框中，有一個選項：

- **Do not update**
  - 若勾選：
    - 當你在新環境中開啟舊專案，而且專案原本設定的 Compiler Version 為 `Newest` 時，
    - CODESYS 會繼續使用專案最後一次使用的 Compiler Version，而非環境中目前標記的「最新」版本。

這有助於維持程式碼輸出的穩定性，但也意味著：

- 你需要明確管理專案對應的 Compiler / Runtime 環境，避免在不知情情況下使用過舊版本。

### 4.3 變更 Compiler Version 的步驟（傳統機制）

1. 開啟專案。
2. 在主選單選擇 `Project → Project Settings`。
3. 切換到 `Compile options` 或 `Compiler version` 相關頁籤。
4. 從 `Fix version` 下拉選單選擇目標版本。
5. 按 `OK`，新設定即會立刻生效。

### 4.4 實務建議（結合新模組化架構）

根據模組化白皮書與 Compatibility 章節：

- 在高度模組化的環境中，**單一 Compiler Version** 已不足以描述所有 Add‑on 的版本組合。
- 建議做法：
  - 將「**整個 CODESYS 安裝（含 Add‑ons）版本**」視為一個整體，透過 CODESYS Installer 管理。
  - 需要「完全二進位相容」的維護專案時：
    - 建立一個專門的安裝實例，與當初下載到控制器時使用的版本完全一致。
  - Compiler Version 設定可用來輔助，但不應再完全依賴為唯一保證。

---

## 5. 開啟舊版專案 Opening Projects from Older Versions（概念性說明）

雖然詳細內容在其它章節（如 `Opening a V3 Project`、`Opening a V2.3 Project`），但在專案建立與設定階段，你應該了解以下幾點：

- 新版 CODESYS 可以開啟舊版專案，並盡量維持相容：
  - 在不需要新功能的前提下，專案會保持原本儲存格式。
  - 若進行會破壞相容性的變更，IDE 會提示你，並讓你選擇是否更新。
- 將專案回存成較舊版本（`File → Save as` 到舊格式）時：
  - 僅保證「儲存格式」兼容。
  - 不會自動把 Compiler / Library / Runtime 等全部降版。
  - 有可能在舊版本開啟後仍需手動調整或重新測試。

實務建議：

- 在團隊內部，盡量維持 **一套標準的開發環境**，避免頻繁跨多個大版本來回開啟同一專案。
- 對需要長期維護的專案，記錄清楚：
  - 最早下載到機台時的 CODESYS 安裝版本與 Runtime / Device Description 版本。

---

## 6. 建議的專案建立與設定流程（整理版）

綜合本文件內容，可以將「建立與設定專案」整理成如下步驟：

1. **選擇標準安裝與目標裝置**
   - 由團隊或個人決定使用哪一版本的 CODESYS 安裝與 Runtime。
   - 確認已安裝對應 Device / SoftPLC。
2. **建立 Standard Project**
   - 透過 `File → New Project → Standard Project`。
   - 選擇目標 Device 與主程式語言（建議 ST）。
3. **檢查自動建立的結構**
   - 確認 `Application`、`Task Configuration`、`Library Manager` 已存在。
   - 確認預設 Task 會呼叫 `PLC_PRG` 或你指定的 Program。
4. **加入需要的物件**
   - 使用 `Project → Add Object` 新增 Program / FB / GVL / Text List / Visualization 等。
   - 使用 Folder 整理程式與資料結構。
5. **調整 Project Settings 與 Compiler / Security 選項**
   - 若有特殊需求（例如固定 Compiler Version、啟用/關閉 Integrity Check），在 `Project Settings` 中調整。
   - 規劃專案保護策略（唯讀、密碼、User Management 等），雖然本批次僅提到概念，詳細將在保護與儲存專案的教學文件中展開。
6. **記錄環境資訊**
   - 在 `Project Information` 中記錄 CODESYS 版本與主要設定。
   - 若專案將來需要在不同機台或團隊間傳遞，這些資訊會非常重要。

透過這樣的流程，新專案一開始就有清楚的結構與設定基準，後續在進入「匯出 / 匯入」、「比較」、「保護與在地化」等進階議題時，就能減少許多混亂與誤解。 

