# Batch 05：下載、測試、除錯與執行階段

## 1. 批次目的

- 聚焦在「程式下載到 PLC、測試、除錯、監控與更新」的整體流程。
- 讓讀者能從這一批教學文件掌握應用程式在 PLC 上完整生命週期的「線上部分」。

## 2. 來源主題（對應 Offline Help）

皆位於 TOC 的：

- `Engineering` → `Development System` → `CODESYS Essentials`

本批要處理的節點：

- `Working with Controller Networks`（`_cds_struct_dataexchange.html` 及其子頁，僅做總覽）
- `Downloading an Application to the PLC`（`_cds_struct_application_transfer_to_plc.html` 及其子頁）
- `Testing and Debugging`（`_cds_struct_test_application.html` 及其子頁）
- `Application at Runtime`（`_cds_struct_application_in_operation.html` 及其子頁）
- `Updating an Application on the PLC`（`_cds_struct_update_application_on_plc.html` 及其子頁）
- `Copying Files to/from the PLC`（`_cds_copy_files_from_to_plc.html`）

## 3. 輸出教學檔案規劃（zh-TW）

本批次建議產生以下 Markdown 檔案（放到 `Offline-Help/zh-TW/`）：

1. `Download_and_Online_Change_教學文件.md`
   - 包含：建立連線、產生程式碼、下載、登入、啟動、Boot application、Online Change、更新流程。
2. `Debug_and_Monitoring_教學文件.md`
   - 包含：Simulation、Breakpoints、Stepping、Forcing、Watch List、Trace、Task 監看、PLC Log。
3. `Runtime_Operation_and_Backup_教學文件.md`
   - 包含：應用程式在運行中的監控方式、系統變數操作、備份與還原、檔案複製（File Transfer）。

## 4. 轉換指引（給轉換腳本／模型）

- 遵守 `HelpConversion_規則說明.md` 中的通用規則。
- `Download_and_Online_Change_教學文件.md`：
  - 以「第一次把專案下載到實機」作為故事線，條列：
    - 設定通訊、建置程式碼、下載、登入、啟動、製作 Boot application。
  - 解釋 Online Change 與完整 Download 的差異與適用情境。
- `Debug_and_Monitoring_教學文件.md`：
  - 聚焦在「開發階段」的工具使用：Simulation、Breakpoints、Step、Force、Watch、Trace。
  - 每個工具給一個簡短實務例子（例如用 Trace 看馬達速度回授）。
- `Runtime_Operation_and_Backup_教學文件.md`：
  - 說明在長期運轉中的日常操作：
    - 利用系統變數控制 Run/Stop。
    - 查看 Task 狀態與 PLC Log。
    - 備份／還原 Runtime 與應用程式，及透過檔案複製做設定檔管理。 

