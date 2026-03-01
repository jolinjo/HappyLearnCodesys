# Batch 03：I/O 組態與應用程式程式設計總覽

## 1. 批次目的

- 將 Offline Help 中關於「I/O 組態」與「一般應用程式程式設計」整理成入門＋總覽教學。
- 不進入過細的語法（運算子、變數型別已由其他批次處理），而是從架構與流程角度說明。

## 2. 來源主題（對應 Offline Help）

皆位於 TOC 的：

- `Engineering` → `Development System` → `CODESYS Essentials`

本批要處理的節點：

- `Configuring I/O Links`（`_cds_struct_io_configuration.html` 及其子頁）
  - `Device Tree and Device Editor`（`_cds_device_tree_device_editor.html`）
  - `Mapping a Hardware Structure in the Device Tree`（`_cds_mapping_hardware_in_device_tree.html`）
  - `Configuring Devices and I/O Mapping`（`_cds_configuring_devices_mapping_ios.html`）
- `Programming of Applications`（`_cds_struct_application_programming.html` 及其子頁，**不含**純語法細節批次會再處理）
  - `Designating Identifiers`（`_cds_naming_identifiers.html`）
  - `UTF-8 Encoding`（`_cds_utf8_encoding.html`）
  - `Variable Declaration` 家族只做高層級說明（詳細型別、運算子另批）
  - 任務設定（Task Configuration）只保留總覽，詳細設定可另開專章。

## 3. 輸出教學檔案規劃（zh-TW）

本批次建議產生以下 Markdown 檔案（放到 `Offline-Help/zh-TW/`）：

1. `IO_Configuration_教學文件.md`
   - 說明 Device Tree、Device Editor、I/O Mapping 的基本概念與常見步驟。
2. `Application_Programming_Overview_教學文件.md`
   - 站在專案架構角度解釋「應用程式程式設計」的流程：
     - 命名規則、編碼（UTF‑8）、變數宣告的層級（全域／區域／任務）、Task 簡介。

## 4. 轉換指引（給轉換腳本／模型）

- 遵守 `HelpConversion_規則說明.md` 中的通用規則。
- `IO_Configuration_教學文件.md`：
  - 用圖像化描述（文字）說明 Device Tree 的層級結構（PLC → Bus → Modules → Channels）。
  - 實務流程示例：
    - 新增裝置 → 掃描硬體 → 設定 I/O → 做 I/O Mapping 到變數。
- `Application_Programming_Overview_教學文件.md`：
  - 聚焦在「專案邏輯如何分拆」：
    - `PROGRAM`/`FUNCTION_BLOCK`/`FUNCTION` 的角色。
    - 命名規範與變數生命週期。
    - Task 的存在意義與何時需要調整週期時間、優先權。
  - 不在此檔中詳細展開各種變數型別或運算子，只做導覽並連結到對應教學檔案（如運算子、變數型別批次）。 

