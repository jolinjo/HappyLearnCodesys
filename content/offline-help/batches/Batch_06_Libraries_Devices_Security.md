# Batch 06：函式庫、裝置、套件與安全性

## 1. 批次目的

- 整理 Offline Help 中關於「函式庫管理」、「裝置與套件」、以及「安全性」的章節。
- 產生一組偏向系統管理與維運的教學文件，適合負責平台維護或建構通用環境的人員。

## 2. 來源主題（對應 Offline Help）

皆位於 TOC 的：

- `Engineering` → `Development System` → `CODESYS Essentials`

本批要處理的節點：

- `Using the Command-Line Interface`（`_cds_commandline.html`）
- `Using Libraries`（`_cds_struct_installing_libraries.html` 及其子頁）
- `Managing Devices`（`_cds_struct_managing_devices.html` 及其子頁）
- `Managing Packages and Licenses`（`_cds_struct_managing_packages_and_licenses.html` 及其子頁）
- `Using Scripts`（`_cds_struct_using_scripts.html`）
- `Security`（`_cds_struct_security.html` 及其子頁）

## 3. 輸出教學檔案規劃（zh-TW）

本批次建議產生以下 Markdown 檔案（放到 `Offline-Help/zh-TW/`）：

1. `Libraries_and_Devices_教學文件.md`
   - 函式庫安裝／更新、Repository 管理、Device 安裝與管理。
2. `Packages_Licenses_and_Scripts_教學文件.md`
   - Package 安裝／移除、授權管理、CODESYS Script / Command-line 基本用法。
3. `Security_BestPractices_教學文件.md`
   - 整理開發系統、Runtime/PLC、WebVisu 的安全性要點與常見 FAQ。

## 4. 轉換指引（給轉換腳本／模型）

- 遵守 `HelpConversion_規則說明.md` 中的通用規則。
- `Libraries_and_Devices_教學文件.md`：
  - 以「如何讓團隊共用函式庫與裝置描述」為主線。
  - 條列操作步驟與實務建議（例如版本管理、相容性注意事項）。
- `Packages_Licenses_and_Scripts_教學文件.md`：
  - 說明 CODESYS Package 與 License 的基本概念與操作路徑。
  - 簡介 Script 與 Command-line 能解決的典型問題（大量建置、批次部署等），不需展開完整 API。
- `Security_BestPractices_教學文件.md`：
  - 以「實務安全建議」角度重寫 Security 章節：
    - 使用者管理、憑證管理、加密通訊策略。
    - FAQ 部分用條列整理，避免逐字翻譯。 

