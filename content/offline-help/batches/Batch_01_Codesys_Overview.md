# Batch 01：CODESYS 概觀與入門教學

## 1. 批次目的

- 覆蓋 Offline Help 中「CODESYS Essentials」最前面的入門內容，幫讀者快速理解開發環境與第一個專案。
- 產生 1～2 份高層級教學文件，之後前端網站可當作「入門導覽」章節。

## 2. 來源主題（對應 Offline Help）

皆位於 TOC 的：

- `Engineering` → `Development System` → `CODESYS Essentials`

本批要處理的節點：

- `CODESYS Development System`（`_cds_start_page.html`）
- `Overview`（`_cds_development_system.html`）
- `Whitepaper: Modularization from the User Perspective`（`_cds_codesys_modularization.html`）
- `Compatibility`（`_rtsl_compatibility.html`）
- `Configuring CODESYS`（`_cds_struct_configuring_development_system.html` 與其子頁）
  - `Configuring the CODESYS Options`（`_cds_configuring_dev_sys_options.html`）
  - `Customizing the User Interface`（`_cds_struct_userinterface_usage.html` 及其子頁）
  - `Installing CODESYS Offline Help`（`_cds_installing_offlinehelp.html`）
    - `Extending CODESYS Offline Help with Your Own Contents`（`_cds_extending_offlinehelp.html`）
- `Your First CODESYS Program`（`_cds_tutorial_refrigerator_control.html` 及其子頁）

## 3. 輸出教學檔案規劃（zh-TW）

本批次應產生以下 Markdown 檔案（放到 `Offline-Help/zh-TW/`）：

1. `CODESYS_Overview_教學文件.md`
   - 說明整體開發環境、相容性、模組化概念。
2. `CODESYS_GettingStarted_教學文件.md`
   - 整合「Configuring CODESYS」與「Your First CODESYS Program」，作為一步步完成第一個專案的教學。

## 4. 轉換指引（給轉換腳本／模型）

- 遵守 `HelpConversion_規則說明.md` 中的通用規則。
- `CODESYS_Overview_教學文件.md`：
  - 先用一段中文概述 CODESYS Development System 與相容性重點。
  - 將 Whitepaper 與 Compatibility 的重要結論濃縮為條列，不需要逐字翻譯。
  - 對「Configuring CODESYS」只做高層級介紹，細節留待未來專章。
- `CODESYS_GettingStarted_教學文件.md`：
  - 以「建立第一個專案」為故事線，串起：
    - 安裝／啟用 Offline Help（簡述）。
    - 基本選項設定、介面自訂（只挑實務常用的步驟）。
    - 官方冰箱範例（`Your First CODESYS Program`）步驟，重寫成清楚的操作流程。
  - 每個大步驟都搭配簡短說明＋必要時的 ST 片段或畫面描述（不用貼 HTML 原圖）。 

