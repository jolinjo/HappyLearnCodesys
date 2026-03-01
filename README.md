# CODESYS 教學網站

針對初學者設計的 CODESYS / SoftMotion 與相關授權、開發規範教學網站，以「學習地圖」與人性化解說陪伴你一步一步補齊觀念。

---

## 建立初心

這個網站的目標**不是**塞一堆指令或手冊給你，而是：

- **用比較人話的方式**，把 CODESYS、SoftMotion、授權選型與開發規範串成一條清楚的學習路線。
- **讓你知道先學什麼、再學什麼、為什麼這樣排**，透過學習地圖與建議順序降低入門門檻。
- **每個範例都有教練式、人性化的中文解說**，重點放在概念與理解，而不只是貼程式碼。
- **方便查詢**：提供站內搜尋，可查函數／功能塊名稱（如 MC_Power、SMC_ReadNCFile2）或關鍵字，結果來自範例說明、授權與開發規範文件。

希望無論是剛接觸 CODESYS 的工程師或學生，都能在這裡「看得懂、願意看下去」，並在需要時快速找到對應說明。

---

## 文件整理來源

本站內容整理自以下來源，僅供學習使用：

| 類型 | 說明 |
|------|------|
| **CODESYS 官方文件與 Offline Help** | 概觀、入門、專案生命週期、程式設計基礎、下載除錯與執行階段、函式庫／裝置／套件與安全性等章節，經整理與中文化摘要。 |
| **CODESYS SoftMotion 官網教學與範例** | 官方範例專案（如 PLCopen 單軸／多軸、BasicMotion 齒輪／凸輪、Robotics、CNC 等）的架構說明與程式解說，改寫為適合閱讀的教學文件。 |
| **授權與 RTE 說明** | RTE 環境與支援硬體、授權版本／模組與費用、函式庫總覽與分類等，整理自官方資訊與實務筆記。 |
| **開發規範** | CFC / SFC / ST 等開發規範與實務建議，彙整自團隊或社群經驗與最佳實務。 |

內容會隨 CODESYS 版本與官方文件更新而調整，若與官方最新文件有出入，請以 CODESYS 官方文件為準。

---

## 技術說明

- **框架**：Next.js（App Router）、TypeScript、React  
- **樣式**：Tailwind CSS  
- **部署**：GitHub Pages（靜態匯出），推送後由 GitHub Actions 自動建置與部署。

### 「同步網站」= 使用本 repo（tutorial-site）的 Git

本資料夾 **tutorial-site** 是獨立的 Git 儲存庫（HappyLearnCodesys），與上層專案目錄分開。  
**同步網站** 指：在本資料夾內進行 `git add`、`git commit`、`git push`；推送到 `main` 後會自動觸發 GitHub Actions 建置並更新 GitHub Pages，無需手動上傳。

```bash
cd tutorial-site
git add .
git commit -m "更新內容"
git push origin main
```

### 若更新了開發規範（來自上層 ExampleFile）

開發規範的**原始檔**在上層專案的 `ExampleFile/CODESYS_開發規範_CFC_SFC_ST.md`。要讓網站顯示最新內容：

1. **在上層專案根目錄**執行同步腳本，把規範複製進 tutorial-site 的 content：
   ```bash
   node tutorial-site/scripts/sync-guidelines.mjs
   ```
2. **在 tutorial-site 目錄**提交並推送（即完成同步網站）：
   ```bash
   cd tutorial-site
   git add content/guidelines/
   git commit -m "sync: 更新開發規範"
   git push origin main
   ```
   推送後 GitHub Actions 會自動建置並部署，數分鐘內線上站即更新。

### GitHub Pages 設定

- 本 repo 已設定 `.github/workflows/deploy-pages.yml`，推送到 `main` 即觸發部署。
- 請在 GitHub 此 repo 的 **Settings → Pages** 中，將 **Source** 設為 **GitHub Actions**（若尚未設定）。

---

© jolinjo
