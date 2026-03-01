# Batch 02：專案生命週期（建立、匯出、保護）

## 1. 批次目的

- 覆蓋「專案從建立、設定、匯出、比較到保護」的一整條生命週期。
- 產生一份或數份教學文件，讓讀者可以照順序學會管理 CODESYS 專案。

## 2. 來源主題（對應 Offline Help）

皆位於 TOC 的：

- `Engineering` → `Development System` → `CODESYS Essentials`

本批要處理的節點：

- `Creating and Configuring a Project`（`_cds_struct_project_creation.html` 及其子頁）
  - `Creating Standard Projects`（`_cds_creating_standard_project.html`）
  - `Adding Objects`（`_cds_adding_objects.html`）
  - `Changing the Compiler Version`（`_cds_changing_compiler_version.html`）
  - `Opening a V3 Project`（`_cds_opening_project_v3.html`）
  - `Opening a V2.3 Project`（`_cds_opening_project_v23.html`）
  - `Configuring a Project`（`_cds_struct_configuring_project.html` 與其子頁）
- `Exporting and Transferring Projects`（`_cds_struct_project_export_transfer.html` 及其子頁）
- `Comparing Projects`（`_cds_struct_project_comparison.html` 及其子頁）
- `Protecting and Saving Projects`（`_cds_struct_project_protection_storage.html` 及其子頁）
- `Localizing Projects`（`_cds_struct_project_localization.html`）
- `Creating a Project Template`（`_cds_create_project_template.html`）

## 3. 輸出教學檔案規劃（zh-TW）

本批次建議產生以下 Markdown 檔案（放到 `Offline-Help/zh-TW/`）：

1. `Project_Creation_and_Config_教學文件.md`
   - 專案建立、加入物件、變更編譯器版本、開啟舊版專案、專案設定。
2. `Project_Export_Compare_Protect_教學文件.md`
   - 匯出／匯入、傳送專案、專案比較、保護與儲存、在地化與範本。

## 4. 轉換指引（給轉換腳本／模型）

- 遵守 `HelpConversion_規則說明.md` 中的通用規則。
- `Project_Creation_and_Config_教學文件.md`：
  - 以「從零開始建立新專案」為主線，依時間順序說明：
    - 建立 Standard Project。
    - 新增程式、GVL、視覺化等物件。
    - 調整 Compiler 版本、從 V2.3 / V3 匯入舊專案。
    - 常用的 Project Settings（例如目標裝置、語言、儲存設定）。
  - 提供一個簡短 ST 範例，示範建立後最基本的程式架構。
- `Project_Export_Compare_Protect_教學文件.md`：
  - 以條列解說三大面向：
    1. 專案分享：Export / Import / Transfer。
    2. 專案比較：圖形比對、詳細差異檢視的實務使用場景。
    3. 專案保護：唯讀、密碼、Dongle、User Management、在地化與範本。
  - 強調實務流程，例如：
    - 專案交接時的建議流程（建立 Archive → 匯出 → 比對確認）。
    - 如何用 Project Template 統一團隊專案結構。 

