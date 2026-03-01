# 教學網站擴充與維護說明

本文給「之後接手或自己回來改」的人用，說明如何更新內容、新增範例、以及調整設定。細節以目前實作為準，若目錄或檔名有改動請同步改這份文件。

---

## 1. 如何同步內容（Markdown 與 ST）

- **原始來源**：教學用的 Markdown 與 `.st` 檔請維持在專案根目錄的 `ExampleFile/`、`授權相關/` 等既有位置，不要直接改 `tutorial-site/content/` 裡的副本。
- **同步腳本**：`tutorial-site/scripts/sync-content.js`
  - **執行方式**：在**專案根目錄**（Codesys-Project）執行：
    ```bash
    node tutorial-site/scripts/sync-content.js
    ```
  - **作用**：依腳本內的 `mappings` 陣列，把每個 `source` 檔案複製到對應的 `target`；若 `target` 在 `tutorial-site/content/softmotion/` 下，會一併把該來源目錄內所有 `.st` 複製到同一目標目錄。
- **新增一筆要同步的檔案**：
  1. 打開 `tutorial-site/scripts/sync-content.js`。
  2. 在 `mappings` 陣列裡新增一項：
     ```js
     {
       source: "ExampleFile/你的範例目錄/你的範例英文名稱_整體架構與功能.md",
       target: "tutorial-site/content/softmotion/你的範例目錄/你的範例英文名稱_整體架構與功能.md",
     },
     ```
     說明檔檔名規則：**範例英文名稱_整體架構與功能.md**（與範例資料夾同名＋`_整體架構與功能.md`）。
  3. 存檔後再執行一次 `node tutorial-site/scripts/sync-content.js`。
- 同步完成後，若網站正在跑，重新整理即可；若為靜態 build，需重新執行 `npm run build`（或部署時會自動重建）。

---

## 2. 如何新增 SoftMotion 以外的範例（或新學習路線）

目前學習地圖與範例詳情頁都綁在 `lib/learningMap.ts` 與 `app/softmotion/`。若要新增「另一個函式庫」的一整條學習路線（例如 PLCopen、CNC 單獨一條），可以這樣擴充：

### 2.1 在 `lib/learningMap.ts` 裡加一組 library

- 在 `LibraryId` 型別中加上新的 id（例如 `"plcopen"`）。
- 在 `learningMap.libraries` 陣列中 push 一個新物件，結構與現有 `softmotion` 相同：
  - `id`、`name`、`description`
  - `sections`：每個 section 有 `id`、`title`、`description`、`examples`。
  - 每個 example 要有：`id`（會變成 URL slug）、`title`、`projectName`、`category`、`order`、`mdPath`（相對於 `content/`）、`summary`。

### 2.2 新增對應的頁面路徑

- 若新路線的 URL 要長得像 `/plcopen`、`/plcopen/[slug]`：
  - 新增 `app/plcopen/page.tsx`（學習地圖總覽，可複製 `app/softmotion/page.tsx` 的邏輯，改為讀取 `learningMap` 裡 `id === "plcopen"` 的 library）。
  - 新增 `app/plcopen/[slug]/page.tsx`（範例詳情頁，可複製 `app/softmotion/[slug]/page.tsx`，改為從該 library 的 sections/examples 裡用 `params.slug` 找 example，並用 `example.mdPath` 讀 Markdown、同目錄下列出 .st 並用 Shiki 高亮）。
- 若暫時只想「在現有 SoftMotion 底下多幾個範例」，只需在 `learningMap.ts` 的 `softmotion` 的某個 `section.examples` 裡追加新 example，並在 `sync-content.js` 的 `mappings` 裡加上對應的 md（與 .st 會自動複製）。

### 2.3 搜尋要不要包含新頁面

- 搜尋範圍由 `lib/searchIndex.ts` 的 `getSearchableDocs()` 決定。
- 現在會遍歷 `learningMap.libraries` 裡每個 library 的每個 section 的每個 example，再加上總覽、授權三份、開發規範一份。
- 若你新增了 `plcopen` 等 library，要在 `getSearchableDocs()` 裡用同樣方式把新 library 的 examples 與總覽 md 路徑加進去，搜尋結果才會出現新頁面。

---

## 3. 如何新增「只有一個」新範例（例如多一個 BasicMotion 範例）

1. **在來源目錄準備好檔案**  
   - 在 `ExampleFile/` 下建立新資料夾（例如 `BasicMotion_NewExample/`），放入：
     - `BasicMotion_NewExample_整體架構與功能.md`（規則：**範例英文名稱_整體架構與功能.md**）
     - 需要的 `.st` 檔。
2. **同步腳本**  
   - 在 `sync-content.js` 的 `mappings` 裡加一筆該範例的 md 路徑（source → target 到 `tutorial-site/content/softmotion/BasicMotion_NewExample/...`），然後執行一次同步。
3. **學習地圖**  
   - 在 `lib/learningMap.ts` 裡，找到合適的 `section`（例如 Basic Motion），在 `examples` 陣列中 push 一筆新的 `ExampleMeta`（`id`、`title`、`projectName`、`category`、`order`、`mdPath`、`summary`）。
4. **搜尋**  
   - 不需改，`getSearchableDocs()` 已經會從 `learningMap` 讀取所有 example 的 `mdPath`，新 example 會自動被搜尋到。

完成後重新 build 或重新整理即可看到新範例出現在學習地圖與範例詳情頁，且 ST 會自動被列出並高亮。

---

## 4. 授權頁、開發規範頁多一個子主題時

- **授權**：若未來多一份 `04_xxx.md`，需要：
  1. 在 `sync-content.js` 的 `mappings` 加一筆複製到 `tutorial-site/content/licensing/04_xxx.md`。
  2. 在 `app/licensing/page.tsx` 的 `LICENSING_DOCS` 陣列加一筆 `{ id, title, path }`。
  3. 在 `app/licensing/LicensingTabs.tsx` 裡，Tab 的按鈕與內容是依 `items` 動態產生，只要 page 傳入的 `contents` 有這筆就會多一個 Tab。
- **開發規範**：若多一份規範 md，可仿照 `app/guidelines/page.tsx` 再開一個 route（例如 `/guidelines/other`），或在同一頁用 Tab／分段呈現，並在 `searchIndex.ts` 的 `getSearchableDocs()` 裡加一筆對應的 doc。

---

## 5. Shiki 語法高亮（ST）與主題

- **目前實作**：`lib/syntaxHighlighter.ts` 使用 Shiki，語言用 `pascal` 近似 ST，主題用 `github-dark`。
- **改主題**：在 `createHighlighter` 時把 `themes` 換成其他內建主題（如 `one-dark-pro`），並在 `highlightSt` 的 `codeToHtml` 裡指定 `theme`。
- **改 ST 專用顏色**：若要更貼近 CODESYS 風格，可考慮為 Shiki 註冊自訂的 `st` 語言 grammar（關鍵字、註解、字串等），再在 `highlightSt` 裡用 `lang: "st"`；目前僅用 Pascal 替代，未註冊自訂語言。

---

## 6. 快速檢查清單（更新內容後）

- [ ] 已執行 `node tutorial-site/scripts/sync-content.js`（在專案根目錄）。
- [ ] 若有新增範例，已於 `lib/learningMap.ts` 加入對應的 example 與正確的 `mdPath`。
- [ ] 若有新增需同步的 md，已在 `sync-content.js` 的 `mappings` 加入一筆。
- [ ] 需要搜尋得到的新頁面，已在 `lib/searchIndex.ts` 的 `getSearchableDocs()` 中有對應的 doc（若完全依 learningMap + 授權/規範清單產生，通常只需維護 learningMap 與授權/規範列表即可）。
- [ ] 重新執行 `cd tutorial-site && npm run build` 確認無錯誤。

---

*最後更新：與目前 tutorial-site 實作一致；若目錄或檔名有變動請同步改此文件。*
