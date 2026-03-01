# CODESYS Development System 概觀 Overview 教學整理

> 本文件基於 CODESYS Offline Help 中 `CODESYS Development System`、`Overview`、`Whitepaper: Modularization from the User Perspective` 與 `Compatibility` 相關章節，整理成易讀、實務導向的繁體中文說明。

---

## 1. CODESYS Development System 是什麼？

- **CODESYS Development System** 是一套符合 IEC 61131‑3 標準的 PLC / 控制器程式設計工具，提供 32‑bit 與 64‑bit 版本。
- 下載位置：
  - **CODESYS Store International**：`https://store.codesys.com`
  - **CODESYS Store North America**：`https://us.store.codesys.com`
- 在整個 CODESYS 平台中，它扮演「核心工程工具」的角色：
  - 撰寫 IEC 61131‑3 程式（ST / FBD / LD / SFC / CFC…）。
  - 組態裝置、I/O 與通訊。
  - 整合可視化（Visualization）、Motion、Fieldbus、Script 等功能。

---

## 2. CODESYS Help 使用方式 Using the CODESYS Help

在 Offline Help 中，CODESYS 的說明通常分成兩大部分：

- **Concepts 概念篇**：
  - 解釋某個主題背後的設計觀念與工作流程。
  - 會搭配 step‑by‑step 的操作說明。
- **Reference 參考篇**：
  - 完整列出選單、視窗、參數與程式語言元素的細節。

### 2.1 如何開啟說明

- 在開發系統中，將滑鼠游標停在某個 **物件 / 功能鍵 / 編輯器內元素** 上，按下 `F1`：
  - 會開啟對應主題的說明頁。
- 也可以透過選單 `Help` 中的項目開啟說明與搜尋。
- 在 **Offline Help** 模式下：
  - 支援 **全文搜尋**，並提供索引（Index）搜尋。
  - Offline Help 搜尋會自動使用 `AND` 與萬用字元規則：
    - 例如搜尋 `Device Diagnosis` 等同於 `Device AND Diagnosis`。
    - `*` 字元本身會被視為字元，不建議當萬用字元輸入。

### 2.2 選擇線上或離線說明

- 在 `Options → CODESYS → Help`（實際路徑依版本略有不同）中，可以選擇：
  - 使用 **Offline Help**（本機 HTML）。
  - 或使用 **Online Help**（瀏覽器連到官方網站）。
- 通常建議：
  - **開發環境固定版本＋內部網路限制**：優先安裝 Offline Help，速度快且不受網路影響。
  - **需要查最新功能**：搭配 Online Help，可以直接取得較新版本的說明。

---

## 3. CODESYS 系統架構總覽 System Overview

根據 `Overview` 章節，CODESYS 整體可想成以下幾個層面：

1. **Development System（你現在使用的 IDE）**
  - IEC 61131‑3 編輯與專案管理。
  - 內含編譯器、除錯工具、HMI/Visualization 編輯器等。
2. **Runtime System（安裝在 PLC / IPC 上的執行環境）**
  - 執行從 Development System 下載過去的應用程式。
  - 由各設備或平台廠商整合提供（例如 CODESYS Control for Raspberry Pi）。
3. **附加功能與 Add‑ons**
  - 例如：
    - `CODESYS SoftMotion`（軸控制 / CNC / Robotics）。
    - `CODESYS Visualization`（畫面視覺化）。
    - `CODESYS Application Composer`（模組化應用組態）。
  - 透過 **Add‑on Packages** 安裝、授權與更新。

對使用者而言，可以把它理解為：

- **核心 IDE** 負責寫程式與組態。
- **Runtime + Device Descriptions** 決定程式實際跑在哪裡、支援哪些功能。
- **Add‑ons / Packages** 則是把特定領域（Motion、Safety、Robotics…）的工具加進 IDE 裡。

---

## 4. 主要功能 Features（精簡版）

根據 `Overview` 內的 Features 表格，CODESYS Development System 提供的工程功能大致可整理為：

- **專案建置與精靈**
  - 以精靈建立標準專案與裝置樹。
  - 對應說明：`Creating and Configuring a Project`。
- **介面自訂 Customizing UI**
  - 自訂選單、工具列、快捷鍵、視窗配置。
  - 對應說明：`Customizing the User Interface`。
- **多種 IEC 語言與編輯器**
  - ST、FBD、LD、IL、SFC，以及 CFC / Extended CFC。
  - 對應說明：`Programming Languages and Editors`。
- **輸入輔助 Input Assistance**
  - 型別提示、自動補齊、宣告輔助等。
  - 對應說明：`Using Input Assistance`。
- **物件導向程式設計 OOP**
  - 支援 IEC 61131‑3 3rd Edition 的物件導向設計：
    - 繼承、介面、方法、屬性、抽象類別等。
  - 對應說明：`Object-Oriented Programming`。
- **專案比較 Project Comparison**
  - 包含圖形編輯器差異比較。
  - 對應說明：`Comparing Projects`。
- **函式庫 Library 機制**
  - 協助重用程式碼與跨專案分享。
  - 對應說明：`Using Libraries`。
- **除錯與上線 Debug & Online**
  - 中斷點、單步執行、線上監看、Trace 等。
  - 對應說明：`Testing and Debugging`。
- **多 CPU 平台編譯**
  - 針對多種 CPU 平台最佳化編譯器與編譯選項。
- **安全性與保護**
  - 專案保護、應用程式加密、裝置使用者管理等。
  - 對應說明：`Protecting and Saving Projects`、`Protecting an Application`、`Handling of Device User Management`、`Managing Packages and Licenses`。
- **Fieldbus / I/O 支援**
  - 以 Device Tree / I/O Mapping 方式組態各種現場匯流排。
  - 對應說明：`Configuring I/O Links`。

實務上，你可以把這些功能看成「IDE 內建的子系統」，往後的教學文件會各自展開說明。

---

## 5. 模組化架構 Whitepaper：Modularization from the User Perspective

自 CODESYS 3.5 SP17 起，官方對整個開發系統做了大幅的 **模組化重構**：

- 過去：大部分功能都被打包在單一安裝檔與單一版本。
- 現在：許多功能拆成獨立的 **Add‑on**：
  - 程式語言編輯器、Fieldbus 組態工具、可視化、符號設定、SoftMotion 等，都能各自版本化與更新。
  - 核心僅保留：UI 框架、編譯器前端、專案處理與通訊等基礎元件。

### 5.1 對使用者的好處

依白皮書摘要，主要好處有：

- **功能完成即可發佈**：
  - 不再受限於一年一次的 Service Pack 發佈節奏。
- **可以在穩定環境中試用 Beta Add‑on**：
  - 生產用安裝保持穩定，平行建立一套「試用安裝」。
- **只安裝需要的元件**：
  - 減少磁碟空間占用與啟動負擔，提昇效能。

### 5.2 使用 CODESYS Installer 管理安裝

模組化之後，**CODESYS Installer** 成為核心工具：

- 可以在同一台 PC 上管理多個 **獨立安裝**：
  - 例如：`3.5.19_Production`、`3.5.19_Testing`。
- 對每個安裝決定：
  - 要裝哪些 Add‑ons。
  - 要不要接收 Beta 更新。
  - 要不要鎖定不更新（維持維護用環境）。
- 在開發系統中，**Notification Center** 也會提示有無對應安裝的更新。

實務建議：

- 團隊可以約定一個「標準安裝」，由一人測試新版本後，透過 Installer 匯出描述檔，再讓其他成員匯入，確保每個人環境一致。

---

## 6. 相容性 Compatibility（概念整理）

關於相容性，官方文件區分幾個層面：

1. **專案相容性（Project Compatibility）**
2. **程式碼相容性（Code Compatibility）**
3. **Runtime 相容性（Runtime System Compatibility）**
4. **函式庫相容性（Library Compatibility）**
5. **裝置描述與 Runtime 相容性（Device Description vs. Runtime）**

### 6.1 專案相容性（Projects）

- 新版 CODESYS 開啟舊專案時，會盡量保持在「相容模式」：
  - 如果修改內容不需要新功能，專案儲存格式會盡量維持舊版。
  - 一旦變更會導致需要新資料格式，IDE 會跳出提示，讓你有機會「回復變更」。
- 舊版 CODESYS 開啟新版專案：
  - 技術上有時「可以開」，但官方 **強烈不建議**。
  - 若缺少必要的 plug‑in 類型，載入時會看到警告或紅叉標示。

### 6.2 程式碼相容性（Code）

- 新版 CODESYS 無法保證產出的程式碼與舊版 **二進位完全一致**：
  - 編譯器、語言編輯器與 Fieldbus 組態工具都可能影響結果。
- 若要「在不做 Online Change 或 Download 的情況下登入現場控制器」：
  - 必須使用與當初下載程式時 **完全相同版本** 的 CODESYS 安裝。
  - 這部分可透過 CODESYS Installer 協助還原對應安裝版本。

### 6.3 Runtime 與函式庫相容性

- 一般情況下：
  - **新 IDE + 舊 Runtime**：通常可行，但新功能可能因 Runtime 不支援而無法使用。
  - **舊 IDE + 新 Runtime**：可能因安全性更新而不相容，不建議。
- Compiled Library 的建議：
  - 應該用「需要支援的最舊 CODESYS 版本」來建置，確保能在較新 IDE 中使用。
  - 舊 IDE 通常無法使用由較新版本建立的 compiled library。

### 6.4 專案與 Boot Project / Retain 的相容性

- 針對 Boot Project 與 Retain 檔案，CODESYS 利用 **checksum 檢查變數配置**：
  - 若 Retain 與程式不相容，可以透過設定選擇：
    - 直接初始化 Retain。
    - 保留在 stop + exception 狀態，等待手動處理。
    - 或拒絕載入 boot project。

實務建議：

- 對於需要長期維護的專案，應記錄：
  - 當初下載時的 CODESYS 版本、Runtime 版本與 Device Description 版本。
  - 若必須升級，務必安排完整回歸測試。

---

## 7. 設定介面與說明語言 Language Settings

在 `Options → International Settings` 中可以：

- 設定 **開發系統介面語言**（IDE UI）。
- 分開設定 **說明文件語言**（Help Language）。

此外，也可以在命令列啟動 CODESYS 時加入參數，指定啟動時使用的語言；這對於多語系團隊或教學環境很有幫助。

---

## 8. 小結：從 Overview 檔案學到的幾件事

1. **CODESYS Development System** 是整個平台的工程核心，負責專案建立、程式設計與除錯。
2. **Offline / Online Help** 是學習與查詢的重要工具，善用 `F1` 可以快速找到對應說明。
3. **模組化與 Installer** 讓 Add‑on 可以獨立更新，方便實務上維護多套安裝。
4. **相容性觀念** 很重要：專案／程式碼／Runtime／函式庫都有各自的相容性規則。
5. 透過這些概念，後續看到 SoftMotion、CNC、Robotics 等教學文件時，可以更清楚它們如何嵌在整體 CODESYS 架構之中。

