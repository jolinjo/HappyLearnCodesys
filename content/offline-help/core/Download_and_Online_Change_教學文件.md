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

# Download and Online Change 程式下載與線上修改 教學整理

> 本文件基於 CODESYS Offline Help 中下列主題整理而成：  
> - `Working with Controller Networks`（`_cds_struct_dataexchange.html`）  
> - `Downloading an Application to the PLC`（`_cds_struct_application_transfer_to_plc.html`）  
> - `Application at Runtime`（`_cds_struct_application_in_operation.html`）  
> - `Updating an Application on the PLC`（`_cds_struct_update_application_on_plc.html`）  
> - `Copying Files to/from the PLC`（`_cds_copy_files_from_to_plc.html`）  
> 目標是用「第一次把專案下載到實機」的故事線，說明 Download 與 Online Change 的完整流程與差異。

---

## 1. 情境說明：第一次把專案下載到 PLC

典型的實務情境是這樣的：

1. 你已經在 CODESYS 中建立好一個 Application，完成基本 I/O 組態與程式撰寫。
2. 需要把程式下載到實際 PLC（或軟體 PLC，例如 `CODESYS Control Win`），讓機台真正動起來。
3. 後續在調機與修正階段，會反覆針對小變更使用 **Online Change**，減少停機時間。

這份文件將依以下流程說明：

1. 建立與 PLC 的通訊與安全設定。
2. 編譯專案與登入 Login。
3. Download（完整下載）與啟動 Application。
4. 建立 Boot application 讓 PLC 上電自動啟動。
5. 使用 Online Change 進行小幅修改。
6. 利用檔案複製與備份確保現場可回復。

---

## 2. 建立與 PLC 的通訊與安全設定

在可以下載程式之前，需要先：

- **設定通訊路徑**：
  - 在工具列或 `Online → Communication Settings` 中，選擇對應的 Gateway 與目標裝置。
  - 例如透過 Ethernet、Serial、或本機 `CODESYS Control Win`。
- **確認使用者與加密設定**：
  - 若裝置啟用 **Device User Management** 或加密通訊：
    - 需要在 CODESYS 開發系統中準備好相對應的憑證與帳號。
    - 相關設定位於 Device Editor 的 `Communication Settings` 與安全性標籤頁。

當這些條件滿足後，才能安全地進行 Login 與 Download。

---

## 3. 編譯與登入：從專案到 PLC 的第一步

### 3.1 編譯專案（Build / Compile）

在 Download 前，必須確保專案可以 **無錯誤編譯**：

- 使用 `Project → Build` 或快捷鍵（通常是 `F11`）。
- 若有錯誤（Errors），需先在編譯訊息中逐項修正。
- 警告（Warnings）則視情況處理：
  - 例如未使用變數、名稱過長等，雖不會阻擋下載，但會影響品質。

### 3.2 Login 到 PLC

當編譯通過後：

- 使用 `Online → Login`：
  - CODESYS 會與選定的 PLC 建立連線。
  - 若第一次登入，且 PLC 上沒有對應專案，系統會提示是否要下載。
- 視安全設定不同，可能會：
  - 要求輸入使用者帳號 / 密碼。
  - 顯示憑證與信任關係提示。

一旦 Login 成功，就可以進行 Download。

---

## 4. 完整 Download：完整更新與啟動流程

### 4.1 Download 的概念

根據 `Downloading an Application to the PLC`：

- **Download** 會對 Application 重新進行：
  - 語法檢查（Syntax check）。
  - 編譯（Compiler 產生二進位碼）。
  - 將新的程式碼下載到 PLC。
- 在 Download 過程中：
  - 既有程式會被 **停止**。
  - 初始化邏輯與變數會依設定重新執行。

這種方式的優點是：

- 會建立一個 **明確、乾淨的啟動狀態**。
- 適合：
  - 結構性變更（新增 Task、改變資料結構、大幅重構）。
  - 版本切換或現場導入前的正式發布。

### 4.2 Download 的實務步驟

典型步驟如下：

1. 確認通訊設定與編譯無誤。
2. 執行 `Online → Login`。
3. 在提示視窗中選擇 **Download**：
   - 若專案變更需要完整下載，狀態列會顯示：  
     `Program modified (Full download)`。
4. 等待 Download 完成後，使用 `Online → Run` 或工具列按鈕啟動 Application。

在這個階段，Application 已在 PLC 上執行，並開始與現場 I/O 互動。

---

## 5. Boot Application：讓 PLC 上電自動啟動

實務上，大多數 PLC 需要 **上電自動啟動應用程式**。

在 CODESYS 中，通常會：

- 在 Login 並成功 Download 與 Run 之後：
  - 使用 `Online → Create boot project`（不同版本文字可能略有差異）。
- 這會在 PLC 的檔案系統中建立一份：
  - **Boot application**（開機啟動程式）。
- 之後每次 PLC 上電或重新啟動時：
  - Runtime 會自動載入這份 boot project，依保留變數與設定啟動。

建議流程：

1. 在實機完成基本測試、確認行為正確後再建立 Boot application。
2. 若日後有大幅更新，需要重新產生新的 Boot project 覆蓋舊版本。

---

## 6. Updating an Application：Download vs Online Change

`Updating an Application on the PLC` 說明了兩種更新方式：

### 6.1 Download（再次完整下載）

- 行為：
  - 重新編譯並停止目前程式。
  - 重新初始化 Application。
- 優點：
  - 狀態乾淨、可預期。
  - 適合大幅變更（資料結構、任務架構、I/O 組態等）。
- 缺點：
  - 會中斷機台運轉，需要排程停機時間。

### 6.2 Online Change（線上變更）

- 行為：
  - 僅下載 **修改過的部分** 程式碼到 PLC。
  - 程式持續執行，不會強制 Stop。
- 適用情境：
  - 小範圍修正（例如條件判斷、參數常數、某個邏輯分支）。
  - 測試期間快速微調控制邏輯。
- 風險：
  - 若變更範圍過大，**程式實際狀態可能難以推估**。
  - 某些變更（例如資料型別、I/O 組態）可能無法透過 Online Change 安全套用。

### 6.3 狀態列提示：可以 Online Change 嗎？

在 Login 或編輯過程中，CODESYS 會檢查當前專案與 PLC 上專案的差異，並顯示：

- `Program modified (Full download)`：
  - 只能透過完整 Download 更新。
- `Program modified (Online change)`：
  - 可以選擇 Online Change。

實務上，建議策略：

- 只要有 **結構性變更或安全疑慮**，一律使用 Download。
- Online Change 僅用於：
  - 單純修正邏輯條件或小範圍調整。
  - 確定不會改變資料佈局與 I/O 映射。

---

## 7. 簡化流程：從第一次下載到後續維護

以下是一個簡化的「實務流程腳本」：

1. **專案完成初版**
   - 建立 Device Tree 與 I/O Mapping（參考 `IO_Configuration_教學文件.md`）。
   - 設定 Task 與 Application 結構（參考 `Application_Programming_Overview_教學文件.md`）。
2. **設定通訊與安全**
   - 配置 Gateway、PLC 位址、使用者管理與加密選項。
3. **編譯與登入**
   - Build 專案 → 修正所有 Errors。  
   - `Online → Login` 連線至目標 PLC。
4. **第一次 Download 與啟動**
   - 選擇 Download，等待程式下載完成。
   - `Online → Run` 啟動 Application。
   - 進行基本功能測試與安全確認。
5. **建立 Boot application**
   - 確認一切正常後，建立 boot project 讓 PLC 上電自行啟動。
6. **後續小變更**
   - 若狀態列顯示 `Program modified (Online change)` 且變更範圍小：
     - 使用 Online Change 減少停機時間。
   - 若需要調整資料結構 / I/O / 任務配置：
     - 排程停機並執行完整 Download。

---

## 8. 檔案複製與備份的關聯（與後續文件銜接）

`Copying Files to/from the PLC` 說明如何在 Device Editor 的 `Files` 標籤頁：

- 在 PC 與 PLC 之間複製檔案：
  - 設定 `Host` 端目錄（例如 `D:\FileTransferWithPLC`）。
  - 設定 `Runtime` 端目錄（PLC 內部檔案系統路徑）。
  - 選取檔案與方向按鈕，雙向複製。

這功能通常搭配：

- 備份 boot project、設定檔（例如配方、日志配置）。
- 從 PLC 抓取診斷資料或 log 檔供分析。

更完整的備份與長期運轉策略，會在 **`Runtime_Operation_and_Backup_教學文件.md`** 中詳細說明。

---

## 9. 小結：怎麼選擇 Download 還是 Online Change？

可以用下列幾個問題來快速判斷：

1. **這次變更會不會動到資料結構 / I/O / 任務架構？**
   - 會 → 建議完整 Download。
2. **機台允許短暫停機嗎？**
   - 可以停機 → 優先選擇 Download，狀態單純且可預期。
   - 不方便停機 → 僅在變更極小且風險可控時使用 Online Change。
3. **是否已建立對應版本的 Boot application 與備份？**
   - 若沒有，應該在 Download 穩定後儘快建立，搭配備份流程。

掌握上述原則，就能在實務專案中，以安全且高效率的方式管理 CODESYS 應用程式的下載與更新流程。 

