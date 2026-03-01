## CODESYS 開發規範：CFC / SFC / ST / FBD / LD 運用指引

本文件針對使用 CODESYS（特別是 SoftMotion 示例）時，如何在專案中合理運用 **CFC / SFC / ST / FBD / LD（含 LD2）** 等 IEC 61131-3 語言，建立一套「可長期維護、易於協作與教學」的開發習慣。

---

## 1. 語言定位與使用情境

### 1.1 ST（Structured Text）

- **定位**
  - 作為專案的「程式邏輯核心語言」。
  - 適合高複雜度邏輯、數學運算、資料處理、通訊協定、可重複利用的功能模組。
- **典型用途**
  - 標準功能方塊（Function Block）實作，例如：
    - 軸控制封裝（回零、點位移動、點到點流程）。
    - 通訊封裝（Modbus / TCP / 自訂協定）。
    - 資料運算（插補、補償、濾波）。
  - 工具函式（Function），例如：
    - 單純計算或邏輯判斷。
    - 資料結構處理（陣列、紀錄型別）。
- **優點**
  - 靠近一般軟體工程語言，容易導入軟體開發最佳實務（重構、單元測試、設計模式）。
  - 文字檔對版本控制（Git 等）非常友善，Diff 及 Code Review 容易。
  - 易於封裝、抽象，建立「公司級共用函式庫」。
- **不建議的用法**
  - 硬要用 ST 寫高度圖形化、流程導向的邏輯，反而不利於操作人員理解。

### 1.2 CFC（Continuous Function Chart）

- **定位**
  - 作為「功能方塊與訊號的拼裝層」，提供直覺的資料流視覺化。
  - 適合**功能方塊**之間的連線、簡單邏輯組合與訊號流向展示。業界比喻：**ST 是在「寫文章」、SFC 是在「排劇本」、CFC 是在「拉電路圖」**；CFC 允許自由擺放 FB 並用線串接訊號，不像 FBD 有嚴格階梯限制。
- **典型用途**
  - 將多個 ST 實作的 Function Block 串接起來，形成一個「站別」或「模組」邏輯。
  - 做簡單互鎖、基本安全條件、啟停條件的圖形化描述：
    - 例如：`Start AND NOT Stop AND SafetyOK` → `EnableAxis`.
  - 作為對初學者或現場人員說明邏輯的「示意圖」。
- **CFC 核心應用場景（情境）**：訊號處理與演算法串接（如秤重 Raw→Filter→Scale→Limit）；工站級邏輯組裝（底層 FB 與感測器、按鈕、互鎖串接）；PID 與閉迴路（壓力/溫度控制，設定值與回饋進 PID 方塊）。
- **CFC 五大實務好處**：① 線上除錯時數值顯示在線條上，易查 AND 閘哪一腳為 FALSE；② 自由擺放、無階梯限制；③ 方塊右上角執行序號可手動調整，避免競爭風險；④ 封裝成 FB 後在 CFC 多次拉出實例即可；⑤ 圖印出來後維護員能看懂訊號流向。
- **優點**
  - 資料流與訊號方向一眼可見，易於講解與教學。
  - 對電機與現場工程背景的開發者非常直覺。
- **風險與限制**
  - 專案規模變大時，CFC 畫面容易變得過於擁擠，難以閱讀與維護。
  - 圖形檔在版本控制系統中不易比對與合併，合併衝突不易解決。
  - 不適合實作複雜演算法或大量條件分支，應避免在 CFC 直接堆疊過多邏輯。

### 1.3 SFC（Sequential Function Chart）

- **定位**
  - 作為「流程 / 狀態機」的上層語言，用來描述系統運行階段與步驟轉換。
  - 對應現場常見的自動循環與工藝流程；可視為自動化設備的「劇本」，走向可線性、可循環、可並行。
- **典型用途**
  - 自動運轉流程：
    - `Idle` → `Prepare` → `AutoRun` → `Stop` → `ErrorHandling`。
  - 多階段加工或工藝流程：
    - `Load` → `Clamp` → `Process` → `Unclamp` → `Unload`。
  - 以 Step / Transition 形式管理模式與狀態旗標。
- **優點**
  - 流程的每一步與切換條件清楚可視化，對操作員與維護人員十分友善。
  - 易於對照操作說明書與 FMEA，作為安全與流程審查的基礎。
- **風險與限制**
  - 若 Step 過度細分或在 Step 內硬塞太多邏輯，會導致圖面複雜、難以維護。
  - 核心計算與機構細節不宜直接寫在 SFC Step 內，應委派給下層 FB / 程式。

#### SFC 執行邏輯要點（防坑指南）

- **是否一定要回到前面的 Step？** 不必。最後一個 Step 若後面沒有接轉移條件（Transition），程式會停在該 Step 並持續執行其內容。適用情境：單次任務（如自動校準，跑完停於 `Step_Finish` 等人工 Reset）、報警停機（如 `Step_Error` 需死守直到故障排除）。若為**自動循環生產**，實務上通常會連回 `Step_Idle`（待機）以利連續作業。
- **可否同時有兩個（或多個）Step 並行執行？** 可以。使用 **並行分支（Parallel Branch）**：在 SFC 中以**雙橫線（=====）**表示，多條路徑同時出發；在下一組雙橫線處**匯合（Sync）**，等所有分支都到達後才進入下一步。例如：空瓶定位後，路徑 A 下降灌裝頭、路徑 B 啟動除塵風扇，兩者並行，匯合後再進入「瓶子移出」。
- **匯合等待**：並行分支中，先完成的路徑會停在最後一個 Step 等待較慢的一邊；只有全部到達匯合點才會繼續。
- **轉移條件（Transition）**：結果必須為 **BOOL**，可為複雜運算式（如 `i_Sensor1 AND (r_CurrentWeight > 500.0)`）；過長時可封裝成獨立的「轉移物件」用 ST 撰寫。**何時檢測？** PLC 為掃描式：每個**任務週期（Task Cycle）**都會執行當前 Step 的程式碼，**接著立即檢測** Step 下方的 Transition。條件為 FALSE 則下一週期繼續同一 Step；為 TRUE 則切換到下一步。
- **Step 動作限定符（Qualifier）**：**N (Non-stored)**：Step 激活期間動作持續執行，最常用。**P (Pulse)**：進入 Step 的當週期只執行一次。**L (Time Limited)**：僅在指定時間內執行，時間到後仍須等 Transition 成立才跳步。
- **注意**：避免無轉移條件的迴圈造成死循環與 Watchdog 報錯；善用 Step 的隱含變數（如 `StepName.x` 是否激活、`StepName.t` 已激活時間）做逾時監控。

### 1.4 FBD（Function Block Diagram，功能塊圖）

- **定位**
  - 圖形化的功能塊連線語言，與 CFC 類似，但通常採「網路 / Page」方式呈現，版面較規整。
  - 適合中小型邏輯網路、訊號處理與控制迴路。
- **典型用途**
  - 將 PID、比較器、計時器、邏輯閘等功能塊以圖形方式串接。
  - 簡單的模擬量處理（比例縮放、限制、濾波）。
  - 單一控制迴路（例如溫控、壓力控制）之內部邏輯。
- **優點**
  - 與模擬控制與控制理論中的框圖概念接近，對有控制背景的人直覺。
  - 比 CFC 更偏向「整齊排列的網路」，在較小規模下畫面清楚。
  - 對梯形圖較不熟悉、但習慣方塊圖的開發者友善。
- **風險與限制**
  - 與 CFC 一樣，圖形檔在版本控制中不易比對與合併。
  - 當控制邏輯跨多個網路或頁面時，訊號追蹤仍可能困難。
  - 核心演算法不適合在 FBD 中直接堆疊，仍應封裝為 ST Function / FB。

### 1.5 LD / LD2（Ladder Diagram，梯形圖）

- **定位**
  - 從繼電器邏輯演化而來的語言，對純電氣背景的工程師尤其熟悉。
  - CODESYS 中的 `LD` 與 `LD2` 在語意上相似，多為編輯器與版面配置差異，可視為同一家族。
- **典型用途**
  - 安全迴路與互鎖邏輯的圖形化呈現（緊急停止、護罩開關、雙手啟動等）。
  - 簡單的啟停控制與保持電路（Self-hold）。
  - 將 IO 狀態以接點 / 線圈方式顯示，方便與實際配線圖對照。
- **優點**
  - 對現場電氣技術員與維護人員非常親切，便於現場溝通與除錯。
  - 「一路一路看下來」的閱讀方式，適合檢查安全與互鎖條件。
  - 配合註解，可直接對照電氣原理圖，降低誤解。
- **風險與限制**
  - 不適合描述高層流程與狀態機（比 SFC 難以掌握全局）。
  - 大量邏輯堆在同一網路或多跨網路時，閱讀成本高。
  - 與 FBD / CFC 類似，對版本控制與合併不友善，建議將關鍵邏輯下沉至 ST。

---

## 2. 推薦的分層架構

為了兼顧 **可讀性、可維護性、版本控管與教學需求**，建議以「三層式」結構設計專案：

### 2.1 上層：流程與狀態控制（以 SFC 為主）

- 責任範圍
  - 定義機台或產線的主要運轉流程與狀態：
    - 開機 / 待機 / 自動 / 手動 / 停機 / 抱警 / 復歸。
  - 在每個 Step 中：
    - 啟動或停止對應的機構功能方塊。
    - 設定模式旗標（如 `bAutoMode`, `bManualMode`）。
    - 監控條件是否達成以進入下一步（完成信號、安全信號、操作員輸入）。
- 設計原則
  - 每個 Step 的職責要明確，避免「一個 Step 做太多事」。
  - Transition 條件盡量簡潔易懂，複雜條件應封裝成 ST 函式或布林變數。
  - 流程較大的系統可拆成多個子 SFC（子流程 / 子站）。

#### 模式與狀態的拆分（主控與流程分離）

一般設備常有「**模式**」（如：準備未了 / 準備完成 / 單動運行 / 全自動運行）與「**狀態**」（如：緊急停止 / 啟動 / 停止 / 暫停）。**不要把模式與動作流程全擠在同一個 SFC**，否則會變成難以維護的「義大利麵條程式」。建議做法：

- **主控層（Master）**：負責模式切換（未復歸 → 復歸中 → 準備完成 → 單動 / 全自動），可用一個 SFC 或 ST 狀態機處理。
- **執行層**：獨立的 SFC（如 `SFC_AutoCycle`）只負責「自動運行」的步驟（Step A → Step B → Step C），不負責暫停/停止的連線邏輯。
- **利用 CODESYS 內建旗標控制 SFC**（推薦）：
  - **SFCPause (BOOL)**：設為 TRUE 時，整個 SFC **凍結**在當前 Step，所有動作暫停 → 對應「暫停」。
  - **SFCInit (BOOL)**：設為 TRUE 時，無論程式在哪一步，都會**立刻跳回**最開始的 Init Step → 對應「停止 / 緊急停止」。
- 實務上：用一個 ST 程式（如 `PRG_ModeControl`）處理按鈕邏輯、Manual/Auto 判斷，並控制 `SFCPause`、`SFCInit`；SFC 只專心畫「自動流程」，畫面保持簡潔。

**命名與邏輯對應建議**（可放在 GVL）：

| 類別 | 名稱範例 | 說明 | 對應 SFC 動作 |
|------|----------|------|----------------|
| 模式 | eMode_NotReady / eMode_Ready / eMode_Manual / eMode_Auto | 未復歸 / 準備完成 / 單動 / 全自動 | 處於 Init 或 Error / Ready Step / Manual 分支 / Auto 分支 |
| 狀態 | i_Btn_EStop / i_Btn_Start / i_Btn_Stop / i_Btn_Pause | 緊急停止 / 啟動 / 停止 / 暫停 | 觸發 SFCInit、切斷 Output / 設 bRunning、解除 SFCPause / 完成當前循環回 Ready / SFCPause := TRUE |

### 2.2 中層：模組 / 站別邏輯與訊號組裝（以 CFC 為主，可輔以 LD）

- 責任範圍
  - 以「站別」或「機構」為單位，將輸入輸出訊號與功能方塊串接起來。
  - 實作：
    - 基本啟停條件與互鎖。
    - 安全條件檢查與 Error 訊號彙整。
    - 站別內各軸、IO 的簡單邏輯組合。
- 設計原則
  - 將畫面依機構或功能區切分，避免單一 CFC 畫面過於龐大。
  - 一條 CFC「區塊」只表達一段明確的邏輯，並在文件中搭配說明其用途。
  - 避免在 CFC 中堆疊多層條件判斷與計算，應該將複雜邏輯下沉至 ST FB。

### 2.3 底層：核心算法與共用功能（以 ST 為主）

- 責任範圍
  - 統一定義並實作所有可重複利用的功能，作為「公司級函式庫」。
  - 常見模組：
    - 軸控制：回原點、點位移動、回零檢查、定位完成判斷等。
    - 訊號去抖動、計時、計數器。
    - 通訊封包解析與封裝。
    - 資料計算（速度規劃、加減速曲線、插補演算法）。
- 設計原則
  - 使用清晰的 Input / Output 介面，避免過度依賴全域變數。
  - 嚴格區分「狀態」與「指令」，例如：
    - `Enable`, `Start`, `Reset` 為輸入命令。
    - `Busy`, `Done`, `Error`, `ErrorID` 為輸出狀態。
  - 盡量保持 FB 的單一職責，方便未來測試與重用。

### 2.4 SFC 與 FB 的介面：握手機制（Handshaking）

SFC 指揮 FB 工作時，業界常用三種方式；**最推薦「布林標誌握手機制」**，邏輯清晰且易除錯。

- **方式一：布林標誌握手（最推薦）**  
  SFC 的 Step 只負責「舉旗子」，FB 看到旗子才動作，做完後 FB 回報另一面旗子，SFC 看到回報才跳下一步。  
  - SFC Step 動作（N）：`GVL.St1_Start := TRUE;`  
  - FB：`i_Execute` 為 TRUE 時執行動作，完成後 `o_Done := TRUE`。  
  - SFC Transition：`GVL.St1_Done`。  
  優點：SFC 與 FB 界線明確，除錯時易分辨是「SFC 沒發指令」還是「FB 沒做完」；適合 FB 動作時間遠大於 SFC 掃描週期的情況。
- **方式二：SFC 動作限定符**  
  在 Step 右鍵「新增動作」，選擇限定符 **N**（Step 激活期間變數為 TRUE）或 **P**（進入 Step 時給一脈衝），直接關聯到 FB 的 `xEnable` / `xExecute`，無需在 Step 內寫 ST。
- **方式三：Step 內直接呼叫 FB**  
  在 Step 關聯的 Action 中寫 ST 呼叫 FB 實例。注意：若多個 Step 共用同一 FB 實例並各自寫入參數，易產生邏輯衝突，較不建議。

**多工站握手機制建議結構**（可定義為 `ST_Station_Ctrl`）：

| 訊號 | 方向 | 說明 |
|------|------|------|
| xStart | SFC → FB | 命令：主控叫你開始 |
| xBusy | FB → SFC | 回報：正在忙，轉盤別動 |
| xDone | FB → SFC | 回報：做完且已回安全位 |
| xError | FB → SFC | 報警：卡住，需停機 |

---

## 3. 實務開發規範建議

### 3.1 語言選擇準則

- **優先順序建議**
  - 流程 / 狀態機：**優先使用 SFC**。
  - 核心運算與可共用邏輯：**優先使用 ST**。
  - 功能方塊與訊號組裝、教學示意：**優先使用 CFC**。
- **避免情境**
  - 不在 CFC 或 SFC 內直接編寫大量計算與複雜條件。
  - 不在 ST 中硬寫完整的大型流程狀態機而完全不使用 SFC，導致現場難以理解。

### 3.2 專案結構建議（示意）

- `Programs/` 或類似資料夾中，可考慮以下分層：
  - `Flow/`：SFC 主流程與子流程。
  - `Stations/`：各站別或各機構之 CFC / LD 程式。
  - `FBs/`：全部共用的 ST Function Block 實作。
  - `Funcs/`：純計算或工具性 ST Function。
- 在範例專案中，可為每一層加入簡短說明文件（Markdown），協助初學者理解用途。
- **I/O 與變數組織**：建議用 **結構體（STRUCT）** 依實體元件（氣缸、軸、真空、安全、三色燈等）分組，在 GVL 中以「一個變數代表一個元件」（例如 `St1_Cyl_Loader : ST_Cylinder`），再透過 Device Editor 的 I/O Mapping 對應到實際通道。程式碼易讀、易維護，且不依賴 `AT %IX...` 硬編碼。詳細範例與命名邏輯見 Offline-Help 中的 **I/O 組態教學 §5.5 用結構體組織 I/O 變數**。

### 3.3 版本控管與協作

- 優先將關鍵邏輯集中在 ST 中，方便：
  - 使用 Git 等版本控管工具進行 Diff 與 Review。
  - 進行功能比較、Bug 追蹤與分支管理。
- 避免頻繁對同一個大型 CFC / SFC 繪圖檔進行多人同時修改，以降低合併衝突風險。
- 對於圖形程式（CFC / SFC），應輔以：
  - 說明文件（如本目錄下的 Markdown）。
  - 版本變更紀錄（Changelog），記錄每次邏輯調整的目的。

### 3.4 教學與文件化

- 對於初學者：
  - 以 CFC / SFC 作為入門說明介面，搭配示意圖講解流程與訊號流向。
  - 再逐步引導閱讀 ST 程式，理解實際演算法與實作細節。
- 推薦做法：
  - 每個主要 SFC Step / CFC 區塊在文件中都配一段白話描述，說明其控制目標與條件。
  - 對於重要 FB，在 ST 程式註解中描述使用方式、前提條件與狀態轉換邏輯（註解採繁體中文撰寫）。

---

## 4. 在 SoftMotion 範例中的應用建議

針對 SoftMotion 相關範例專案，可採用以下思路進行教學與擴充：

- 將官方範例中的：
  - 流程控制部分整理成 SFC 範例，示範如何管理機台狀態。
  - 單軸 / 多軸控制邏輯封裝為 ST Function Block，便於在不同專案重用。
  - IO 與軸控制的關係以 CFC 呈現，方便展示啟停條件、互鎖與安全邏輯。
- 在本目錄中，可對每一個例題增加：
  - 一小節說明其 SFC / CFC / ST 分工。
  - 未來實際專案如何將範例「升級」為可維護架構的建議。

---

## 5. 實際範例：語言搭配與使用情境

以下以幾個典型機台 / 產線情境，說明各語言的實際運用方式與優缺點取捨。

### 5.1 範例一：單軸定位站（簡易上下料機構）

- **需求描述**
  - 一支伺服軸，負責從「待料位」移動到「加工位」，再退回原位。
  - 具備「自動模式 / 手動點動 / 急停與安全門」等基本功能。
- **建議語言搭配**
  - **SFC**
    - 描述狀態流程：`Idle` → `Home` → `WaitStart` → `MoveToWork` → `WaitProcessDone` → `MoveToHome`。
    - 每個 Step 只負責切換指令（例如給 `CmdHome`, `CmdMoveToWork`）。
  - **ST**
    - 將單軸控制封裝為 `FB_AxisSingleStation`：
      - Inputs：`CmdHome`, `CmdMoveToPosWork`, `CmdMoveToPosHome` 等。
      - Outputs：`bBusy`, `bDone`, `bError`, `udiErrorID`。
    - 內部處理回零、定位、錯誤判斷等細節。
  - **CFC / FBD**
    - 在站別的 CFC / FBD 畫面中，將：
      - 安全門、急停、啟動按鈕等 IO 與 `FB_AxisSingleStation` 的 Enable / Start 端子串接。
    - 初學者可經由此畫面了解「哪些條件滿足時馬達會動」。
  - **LD / LD2**
    - 若團隊電氣背景濃厚，可用 LD / LD2 畫出：
      - 急停迴路、護罩互鎖、自保持啟動線路。
    - 優勢是能直接與電氣原理圖對照，方便維護。
- **綜合說明**
  - 流程變動時，主要改 SFC；訊號接線或安全邏輯改 CFC / LD；軸控制細節改 ST FB。
  - 區分清楚之後，長期擴充與教學皆較容易。

### 5.2 範例二：多工位輸送線（多站同步 / 互鎖）

- **需求描述**
  - 一條輸送線上有多個工位（Station1~StationN），每站有感測器與執行元件。
  - 需要站間互鎖（前一站未完成，下一站不得進料），並具備總體自動 / 手動控制。
- **建議語言搭配**
  - **SFC**
    - 頂層 SFC 管理整線狀態：`LineIdle`, `LineAuto`, `LineStop`, `LineError`。
    - 每一站可選擇：
      - 用子 SFC 描述站內流程，或
      - 由頂層 SFC 透過旗標驅動各站別邏輯。
  - **ST**
    - 為每一站建立 `FB_StationX`，內含：
      - 站內步驟狀態（可以是小型 SFC 或 ST 模擬狀態機）。
      - 感測器與執行元件邏輯。
    - 再建立共用工具 FB，如 `FB_InterlockManager` 整理站間互鎖。
  - **CFC / FBD**
    - 在每一站的 CFC / FBD 畫面上，將：
      - 該站的感測器、氣缸 / 馬達訊號接到 `FB_StationX` 上。
      - 簡單互鎖（例如「前一站 OK 且當前站空閒才允許進料」）可直接以 FBD / CFC 表示。
  - **LD / LD2**
    - 使用 LD / LD2 描繪安全迴路及總急停 / 區域急停之邏輯。
    - 若某些站別邏輯與繼電器思維高度一致，也可選擇用 LD 實作該部分。
- **綜合說明**
  - 站數增加時，主要增的是 ST FB 實例與 CFC / FBD 接線，頂層 SFC 只需小量調整。
  - 這種結構在規模擴張及日後維護時具備良好可伸縮性。

### 5.3 範例三：三軸機床上料 + 供料機控制

- **需求描述**
  - 一台三軸（X/Y/Z）加工機，搭配簡易上料機構與一組震動供料機或皮帶供料機。
  - 流程為：供料機出料 → 機床夾持工件 → 完成加工 → 退料或下料至料盒。
- **建議語言搭配**
  - **SFC**
    - 頂層流程例如：
      - `Idle` → `WaitPart` → `PickFromFeeder` → `Clamp` → `MachineProcess` → `Unclamp` → `Unload`.
    - 針對「等待供料」、「缺料 / 堵料」等情況，設計對應 Error / Retry 分支。
  - **ST**
    - 建立：
      - `FB_3AxisMachining`：負責三軸插補點位、加工路徑進給與安全檢查。
      - `FB_FeederControl`：負責供料機啟停、料位偵測、防堵料計時邏輯。
    - 將三軸的進給與安全（行程極限、軟極限）封裝在 FB 內，避免上層流程誤用。
  - **FBD / CFC**
    - 在機床站的 CFC / FBD 中：
      - 將三軸伺服驅動的 Enable / Power / Ready / Fault 訊號與 `FB_3AxisMachining` 串接。
      - 將供料機馬達、震動盤、光電感測器與 `FB_FeederControl` 串接。
    - 比較清楚地展示「哪些安全條件滿足才允許啟動供料與加工」。
  - **LD / LD2**
    - 使用 LD / LD2 描繪：
      - 主接觸器與馬達驅動器電源的互鎖。
      - 安全門 / 护罩 / 急停的安全鏈。
    - 維護人員可直接對照實體接觸器與迴路理解邏輯。
- **綜合說明**
  - 三軸加工路徑與供料演算法多半較複雜，應堅持放在 ST FB 中；CFC / FBD 僅負責拼裝與顯示。
  - 流程調整（例如增加清理動作或換刀步驟）以修改 SFC 為主，對底層 FB 影響較小。

### 5.4 範例四：轉盤四分割多工站製程（每站獨立工作）

- **需求描述**
  - 一個四分割轉盤，每個 Index 位置是一個工站（例如：上料、預加工、主加工、檢測 / 下料）。
  - 轉盤按固定節拍旋轉，各工站在停靠期間獨立作業。
- **建議語言搭配**
  - **SFC**
    - 頂層 SFC 管理轉盤節拍與總體狀態：
      - `Idle` → `Indexing` → `Processing` → `Error`。
    - 可在 `Processing` Step 中，依時間或條件觸發各工站子流程。
  - **ST**
    - 每個工站實作獨立 FB，如：
      - `FB_StationLoad`, `FB_StationPreProcess`, `FB_StationMainProcess`, `FB_StationInspect`.
    - 轉盤本身的 Index 控制封裝為 `FB_IndexTable`：
      - 處理目標工位計數、到位感測確認、夾治具鎖定等。
  - **CFC / FBD**
    - 為每個工站建立一張 CFC / FBD 畫面：
      - 清楚顯示該工站的 IO（氣缸、真空、感測器）與站內 FB 的串接。
    - 轉盤 Index 驅動相關訊號可單獨一張 CFC / FBD，說明互鎖邏輯（例如：所有工站都收刀 / 退回安全位才允許旋轉）。
  - **LD / LD2**
    - 安全迴路與轉盤鎖銷、夾具鎖緊等高安全需求邏輯可用 LD / LD2 呈現。
    - 若有硬體安全繼電器或安全 PLC，可對應到 LD 圖上輕鬆說明。
- **綜合說明**
  - 工站數量擴充（四分割 → 六分割）時，主要是新增 / 調整 ST FB 與 CFC 畫面，SFC 僅需更新節拍與同步方式。
  - 這種結構適合多專案複用，只要替換各工站 FB 即可對應不同製程。

### 5.5 範例五：SCARA 機械手 + 輸送帶飛抓上料

- **需求描述**
  - 一台 SCARA 機械手從連續運行的輸送帶上「飛抓」工件，再放置到定位治具或托盤。
  - 需要處理工件偵測、位置追蹤、時間 / 速度同步與安全互鎖。
- **建議語言搭配**
  - **SFC**
    - 描述高層動作模式：
      - `Idle` → `WaitConveyorReady` → `TrackingPick` → `Place` → `Return`.
    - 流程中處理「無料」、「逃料」、「暫停輸送帶」等例外情況。
  - **ST**
    - 關鍵邏輯以 ST 實作：
      - `FB_ConveyorTracking`：根據光電觸發時間、編碼器脈衝，計算工件在機械手座標系中的即時位置。
      - `FB_ScaraMotion`：封裝 SCARA 的點位運動、插補指令、安全範圍限制。
    - Tracking 演算法（速度、加減速、補償）強烈建議全部 ST 實作，利於調整與重用。
  - **FBD / CFC**
    - 以 FBD / CFC 處理：
      - 輸送帶變頻器 / 驅動啟停條件。
      - 光電感測器、編碼器信號前處理（濾波、邊沿偵測、超時判斷）。
    - 同時將 `FB_ConveyorTracking` 與 `FB_ScaraMotion` 的介面串接，做為教學示意圖。
  - **LD / LD2**
    - 對於與實際安全有關的邏輯（保護門、光柵、急停、機械手安全區），使用 LD / LD2 表示。
    - 方便與安全電路設計人員共同檢查。
- **綜合說明**
  - 飛抓系統對時間與位置同步要求高，演算法與調變必須集中於 ST。
  - 透過 SFC、CFC / FBD、LD / LD2 的搭配，可同時滿足：
    - 控制工程師對精度與演算法的要求。
    - 現場維護人員對流程與安全迴路可視化的需求。

---

## 6. 初學者常見盲點與觀念釐清（情境 Q&A）

以下整理初學者在實作「汽缸 + CFC + SFC」時常有的疑問，與業界常用做法對應，方便對照文件與實作。

### 6.0 比喻：醫生與病歷表（資料與邏輯的對應）

理解「結構體」與「功能塊」時，可用**醫生診療**來類比，方便記憶誰是「資料」、誰是「邏輯」、誰要「實例化」。

| 術語 | 比喻 | 程式中的身份 |
|------|------|----------------|
| **ST_Cylinder** | 病歷表**格式**（空白表格） | DUT：定義要有哪些欄位（感測器、輸出、錯誤旗標） |
| **St1_Cyl_Pusher** | **1 號病人**的病歷表（已填寫的那一份） | 結構體的**實例**：存這支汽缸真正的 IO 狀態，通常放在 GVL |
| **FB_Cylinder** | 醫生的**標準診療手冊**（怎麼看病、開處方） | 功能塊**定義**：寫好一套控制邏輯，用 ST 實作 |
| **fb_PusherLogic** | **負責 1 號病人**的那位醫生 | 功能塊的**實例**：真正在執行診斷、寫處方的那一個「大腦」 |

**一句話對應**：

- **病歷表格式（DUT）**：只定義「有哪些欄位」，**不能**寫「如果發燒就開退燒藥」這類邏輯。
- **病歷表實例（STRUCT 實例）**：某一支汽缸的「當前狀態」——感測器亮了沒、電磁閥有沒有輸出，都寫在這張表上；硬體、HMI 都看這張表。
- **診療手冊（FB 定義）**：只寫一次，裡面是「如果手動按下就輸出、如果安全不 OK 就切斷」等規則。
- **醫生（FB 實例）**：每個病人可以配一位醫生；程式裡每支汽缸配一個 FB 實例，每位醫生拿的是**不同病人的病歷表**。

**關鍵動作**：`fb_PusherLogic(Cyl := St1_Cyl_Pusher);`

- 意思等同：「請**負責 1 號病人的醫生**（`fb_PusherLogic`），拿著**1 號病人的病歷表**（`St1_Cyl_Pusher`）開始看病。」
- 醫生（FB）根據手冊（內部 ST 邏輯）讀病歷表上的感測器、按鈕、安全訊號，判斷後在病歷表的「輸出欄位」寫上該不該出氣；PLC 硬體與 HMI 再根據這張病歷表去驅動電磁閥與顯示狀態。

**為什麼要分開實例化？**

- 若有 10 支汽缸：只需要 **1 本診療手冊**（1 個 FB 定義），但需要 **10 張病歷表**（10 個 STRUCT 實例，在 GVL）與 **10 位醫生**（10 個 FB 實例，在 POU）。每位醫生每次只處理一張病歷表，不會搞混。

以下 6.1～6.3 的釐清，都可用上述比喻對照。

### 6.1 結構體（STRUCT）與功能塊（FB）的關係

- **盲點**：以為在結構體裡可以寫邏輯，或不知道「誰負責資料、誰負責邏輯」。
- **釐清**（對照 6.0 比喻）：
  - **結構體（DUT）**：只是「資料的容器」＝**病歷表格式**，定義有哪些欄位（感測器、輸出、錯誤旗標）；**不能**在裡面寫 IF、計時器等邏輯。
  - **功能塊（FB）**：負責「邏輯」＝**診療手冊／醫生**，用 ST 撰寫；介面可引用外部結構體（`VAR_IN_OUT Cyl : ST_Cylinder`），讀寫該實例的欄位（看病歷、寫處方）。
- **實務**：先定義 `ST_Cylinder`（DUT），再寫 `FB_Cylinder`（FB）引用該結構體；在 CFC 中「拉 FB 方塊 + 連到 GVL 的結構體實例」。

### 6.2 實例化：GVL 放什麼、POU/CFC 放什麼？

- **盲點**：FB 與結構體是否都要實例化？會不會搞混「資料實例」與「邏輯實例」？
- **釐清**（對照 6.0 比喻）：
  - **GVL**：只放 **病歷表（結構體實例）**，例如 `St1_Cyl_Pusher : ST_Cylinder`。用途：對接硬體 Mapping、給 HMI 讀寫、跨站讀取狀態——所有需要「看這支汽缸狀態」的地方都看這張表。
  - **POU（如 PRG_Station1）**：放 **醫生（FB 實例）**，例如 `fb_PusherLogic : FB_Cylinder`。用途：執行控制邏輯；醫生不必放在 GVL，避免全域混亂與誤改。
- **一句話**：**資料（STRUCT／病歷表）上 GVL，邏輯（FB／醫生）留 POU/CFC 宣告區。**

### 6.3 一行關鍵程式碼：`fb_PusherLogic(Cyl := St1_Cyl_Pusher);`

- **盲點**：在 CFC 或 ST 裡看到這行，不知道在做什麼。
- **釐清**（對照 6.0 比喻）：這是「**讓醫生拿著病歷表開始看病**」的動作。
  - `fb_PusherLogic`：FB 實例 ＝ **負責這支汽缸的醫生**。
  - `Cyl := St1_Cyl_Pusher`：把 GVL 裡的結構體實例（**這支汽缸的病歷表**）傳給 FB 的 `VAR_IN_OUT`。
  - 執行後：醫生（FB）根據手冊讀病歷、寫處方；FB 會讀取該結構體的感測器、寫入輸出欄位（如 `o_Fwd_SV`），PLC/HMI 透過同一份結構體看到結果。
- **在 CFC 中**：不需手寫這行；在畫布上把「輸入盒填 `GVL_IO.St1_Cyl_Pusher`」連到方塊的 `Cyl` 腳位，即等同「把病歷表交給這位醫生」，效果等同於上述呼叫。

### 6.4 CFC 中方塊與實例、紅線、VAR_IN_OUT

- **盲點**：畫布上拉了方塊卻出現「未知操作符」或「必須為 VAR_IN_OUT 'Cyl' 賦值」。
- **釐清**：
  - 方塊必須對應到「已在該 POU 宣告區宣告的 FB 實例」：在方塊中間點選後按 F2，從「局部變量」選取該實例名稱（如 `St1_fb_Cyl_Pusher`）。
  - `VAR_IN_OUT`（如 `Cyl`）**一定要接線**：在 CFC 中拉一個「輸入」元件，填入 `GVL_IO.St1_Cyl_Pusher` 並連到該腳位；未接線會出現紅線且編譯報錯。
- **小技巧**：宣告區若被收合，可將 CFC 視窗頂部分隔線往下拉；若為表格模式，可切換到「Textual」以看到 `VAR ... END_VAR`。

### 6.5 不同工站是否用不同 CFC？實例名稱要不要帶工站名？

- **實務**：不同工站建議用**不同 CFC POU**（如 `PRG_Station1`、`PRG_Station2`），邏輯隔離、易維護。
- **實例名稱**：在**同一個** CFC 內部，FB 實例名稱可以不帶工站（如 `fb_Pusher`、`fb_Lifter`），因為變數已在該 POU 的局部範圍；若要方便全域搜尋與監控，可加前綴（如 `St1_fb_Pusher`）。**GVL 的結構體實例一定要區分工站**（如 `St1_Cyl_Pusher`），否則名稱衝突。

### 6.6 汽缸互鎖寫在哪裡？怎麼接？

- **建議**：寫在 **CFC（中層）**，用 AND、NOT 方塊組合。
- **範例**：兩支汽缸 A、B 互鎖（A 伸出時 B 不能動，反之亦然）。
  - A 的 `xSafety_OK` ← `gvl_sys.bSafety_OK AND NOT (B.o_Fwd_SV)`。
  - B 的 `xSafety_OK` ← `gvl_sys.bSafety_OK AND NOT (A.o_Fwd_SV)`。
- **注意**：互鎖建議用「輸出訊號」（`o_Fwd_SV`）而非僅感測器，這樣在汽缸移動中、尚未到位時也能保護。若畫面線太多，可用「連接標記」（如 C-1）做無線對接，並建議將標記改名為有意義名稱（如 `St1_Safety_Interlock`）。

### 6.7 運行中要看汽缸 IO 狀態，去哪裡看？

- **CFC**：Online 時線條會變色（如 TRUE 藍色）；連到結構體的輸入盒旁可點「+」展開，看內部 `i_FwdLimit`、`o_Fwd_SV` 等即時值。
- **GVL**：打開 GVL_IO，展開對應結構體實例，可一次看全站/全機汽缸狀態。
- **Watch List**：把 `GVL_IO.St1_Cyl_Pusher`、`GVL_Auto.St1.xPusher_Ext_Req` 等拖進監看表，自訂儀表板，調機最方便。
- **IO Mapping**：若要確認邏輯是否正確對到實體點位，可到硬體配置的 Digital Output / Input 的 IEC 物件對照。

### 6.8 CFC 引腳設為 TRUE/FALSE、註解、AND/NOT 方塊

- **設為 TRUE/FALSE**：拖曳「輸入(Input)」元件到畫布，連到該腳位，在輸入盒內鍵入 `TRUE` 或 `FALSE`；或直接在腳位旁可輸入處鍵入（依版本而定）。
- **註解**：從工具箱拖入「註釋(Comment)」元件，在 ??? 處輸入說明；或用「矩形」框住一區塊並加標題，標示該區功能（如「第一站汽缸互鎖」）。
- **AND / NOT**：拖入「運算塊(Box)」，在 ??? 處輸入 `AND` 或 `NOT`；若 AND 要三輸入以上，可右鍵該方塊選「插入輸入引腳」。對單一輸入做取反也可在引腳上右鍵選「取反(Negate)」，會出現小圓圈。

---

## 7. 汽缸模組化完整範例（DUT / FB / GVL / CFC 與互鎖）

以下以「兩支汽缸（推料、升降）、手自動切換、安全互鎖、單/雙電控共用」為例，給出可複製的架構與程式碼要點，方便對照 2～3 節的分層與命名。

### 7.1 結構體定義（DUT）：ST_Cylinder

```iec-st
TYPE ST_Cylinder :
STRUCT
    i_FwdLimit : BOOL;  // 前進到位感測器
    i_BwdLimit : BOOL;  // 後退到位感測器
    o_Fwd_SV   : BOOL;  // 伸出電磁閥輸出 (單/雙電控皆用)
    o_Bwd_SV   : BOOL;  // 縮回電磁閥輸出 (僅雙電控用，單電控不接線)
    xError     : BOOL;  // 汽缸異常狀態
END_STRUCT
END_TYPE
```

- 單動／雙動電磁閥可**共用同一結構體**：雙電控時兩個輸出都接線；單電控時 `o_Bwd_SV` 不接線，FB 內強制設為 FALSE。

### 7.2 功能塊（FB）：FB_Cylinder（ST 實作）

- **介面要點**：`VAR_IN_OUT Cyl : ST_Cylinder`；輸入含 `xIsDSV`（是否雙電控）、`xAutoMode`、`xAuto_Cmd`、`xManual_Cmd`、`xSafety_OK`。
- **邏輯要點**：
  - 先依 `xAutoMode` 決定 `Cyl.o_Fwd_SV` 來自自動或手動指令。
  - 若 `xIsDSV` 為 TRUE：`Cyl.o_Bwd_SV := NOT Cyl.o_Fwd_SV`，且安全不 OK 時兩輸出皆 FALSE。
  - 若 `xIsDSV` 為 FALSE：`Cyl.o_Bwd_SV := FALSE`，安全不 OK 時僅切斷 `o_Fwd_SV`。
- **進階**：可加 `xWaitSensor`、`xDone` 做「等感測器才完成」或「輸出即完成」（類 M 碼）：`xWaitSensor = TRUE` 時，`xDone` 等對應感測器到位才為 TRUE；`xWaitSensor = FALSE` 時，輸出指令一下達即視為完成，SFC 可立刻跳下一步，節拍快。逾時監控用 TON 寫在 FB 內，將結果寫入 `Cyl.xError`。
- **FB 與多支汽缸**：同一個 FB 只需寫一次邏輯，在程式中宣告多個實例（如 `fb_Pusher`、`fb_Lifter`）即可；修改 FB 一次，全機汽缸邏輯同步更新。

### 7.3 全域變數（GVL_IO）：資料實例

```iec-st
{attribute 'qualified_only'}
VAR_GLOBAL
    St1_Cyl_Pusher : ST_Cylinder;
    St1_Cyl_Lifter : ST_Cylinder;
END_VAR
```

- 僅放**結構體實例**，供 IO Mapping、HMI、CFC 連線使用。

### 7.4 CFC 畫面：實例、連線與互鎖

- **宣告區（同一 POU）**：`St1_fb_Cyl_Pusher : FB_Cylinder;`、`St1_fb_Cyl_Lifter : FB_Cylinder;`（兩位「醫生」）。
- **畫布**（對照 6.0 醫生／病歷表比喻）：
  - 拉兩個 FB 方塊，方塊內指定上述兩個實例名稱（F2 → 局部變量）。
  - 每個方塊的 `Cyl` 腳位接輸入盒，分別填 `GVL_IO.St1_Cyl_Pusher`、`GVL_IO.St1_Cyl_Lifter`（把對應的「病歷表」交給每位醫生）。
  - `xIsDSV`、`xAutoMode`、`xAuto_Cmd`、`xManual_Cmd`、`xSafety_OK` 依 2、8 節從 GVL_Sys、GVL_Auto、GVL_HMI 連線；其中 `xSafety_OK` 改為「系統安全 AND 互鎖」：
    - 推料：`xSafety_OK` ← `gvl_sys.bSafety_OK AND NOT (St1_Cyl_Lifter.o_Fwd_SV)`。
    - 升降：`xSafety_OK` ← `gvl_sys.bSafety_OK AND NOT (St1_Cyl_Pusher.o_Fwd_SV)`。
- 這樣即完成「兩支汽缸互鎖 + 手自動 + 安全」的模組化組裝；主程式（SFC）只需下自動指令，不必再管手自動切換細節。

**術語與命名（業界常用）**

- **電磁閥**：Solenoid Valve；單電控 Single Solenoid Valve、雙電控 Double Solenoid Valve；縮寫 SV、SOL，電路圖有時以 Y 表示線圈。
- **感測器**：Sensor；縮寫 SNS、SEN；近接 Proximity (Prox)、光電 Photoelectric (PE)、極限開關 Limit Switch (LS)。
- **命名建議**：以設備名稱為首，同設備訊號會群組在一起，例：`Cyl1_Ext_HmiReq`（手動伸出請求）、`Cyl1_Ext_SfcReq`（自動伸出請求）；或放在結構體內如 `GVL_IO.St1_Cyl_Pusher.o_Fwd_SV`（伸出電磁閥輸出）。

---

## 8. GVL 分層、區分工站與 MainTask 設定

### 8.1 GVL 分層建議（四層）

| GVL 名稱 | 存放內容 | 目的 |
|----------|----------|------|
| GVL_IO | 設備結構體實例（如 St1_Cyl_Pusher） | 硬體 Mapping、HMI 顯示、跨站讀狀態 |
| GVL_HMI | 按鈕、燈號等 BOOL（或 ST_Station_HMI） | 觸控螢幕讀寫 |
| GVL_Auto | 自動流程指令（如 req_Pusher_Ext）或 ST_Auto_Cmd | SFC 指揮 CFC 的橋樑 |
| GVL_Sys | bAutoMode、bSafety_OK、bReset_Active 等 | 全機模式與安全 |

- **手動／自動觸發訊號**：手動來自 HMI → 放 GVL_HMI；自動來自 SFC/流程 → 放 GVL_Auto；系統模式與安全 → GVL_Sys。建議加上 `{attribute 'qualified_only'}`，使用時必須寫 `GVL_IO.xxx`，避免撞名並利於自動完成。

**四層 GVL 範例程式碼（可複製對照）**

```iec-st
// GVL_IO：硬體資料層
{attribute 'qualified_only'}
VAR_GLOBAL
    St1_Cyl_Pusher : ST_Cylinder;
    St1_Cyl_Lifter : ST_Cylinder;
    St2_Cyl_Clamp  : ST_Cylinder;
END_VAR

// GVL_HMI：人機介面層（可改為 ST_Station_HMI 結構體以區分工站）
{attribute 'qualified_only'}
VAR_GLOBAL
    St1_btn_Pusher_Ext : BOOL;
    St1_btn_Pusher_Ret : BOOL;
    St1_btn_Lifter_Up  : BOOL;
    lamp_Pusher_Error  : BOOL;
    lamp_Safety_Indicator : BOOL;
END_VAR

// GVL_Auto：自動流程指令層（或改用 ST_Auto_Cmd 結構體）
{attribute 'qualified_only'}
VAR_GLOBAL
    St1_req_Pusher_Ext : BOOL;
    St1_req_Lifter_Dn  : BOOL;
    bFastMode_Active   : BOOL;
END_VAR

// GVL_Sys：系統全域狀態層（不區分工站）
{attribute 'qualified_only'}
VAR_GLOBAL
    bAutoMode     : BOOL;
    bSafety_OK    : BOOL;
    bReset_Active : BOOL;
    bEmergencyStop : BOOL;
END_VAR
```

### 8.2 區分工站（含 HMI、Auto）

- **GVL_IO / GVL_Auto**：強烈建議區分工站（如 `St1_Cyl_Pusher`、`GVL_Auto.St1.xPusher_Ext_Req`），避免多站時名稱衝突與邏輯混亂。
- **GVL_HMI**：也要區分工站。做法一：前綴命名（如 `St1_btn_Pusher_Ext`）。做法二（推薦）：定義 `ST_Station_HMI` 結構體（如 `btn_Manual_Ext`、`btn_Manual_Ret`、`lamp_Status_OK`），在 GVL_HMI 宣告 `St1 : ST_Station_HMI;`、`St2 : ST_Station_HMI;`，路徑即為 `GVL_HMI.St1.btn_Manual_Ext`，清晰且易複製新站。
- **GVL_Sys**：全機共用，不分工站（如 bAutoMode、bSafety_OK）。

### 8.3 ST_Auto_Cmd 是什麼？

- **ST_Auto_Cmd** 是自訂的 DUT（資料結構），用來把「該工站的自動指令」收納成一個結構體，方便 CFC 連線與擴充。
- 範例定義：

```iec-st
TYPE ST_Auto_Cmd :
STRUCT
    xPusher_Ext_Req : BOOL;
    xLifter_Dn_Req  : BOOL;
    xClamp_Open_Req : BOOL;
    xStart_Cycle    : BOOL;
    xStop_Immediate : BOOL;
END_STRUCT
END_TYPE
```

- 在 GVL_Auto 中：`St1 : ST_Auto_Cmd;`、`St2 : ST_Auto_Cmd;`；CFC 中即可連 `GVL_Auto.St1.xPusher_Ext_Req` 等，介面一致、不易連錯站。

### 8.4 SFC 狀態機與「動作細節」放 FB（常變動部分）

- **需求**：大流程用 SFC（開機 → 安全檢查 → 等待啟動 → 執行動作 → 回等待），但「四個汽缸動作（取料 On → 升降 On → 取料 Off → 升降 Off）」常變動，希望改順序或加延時時不必動 SFC。
- **做法**：
  - **SFC**：保留 Init、SafetyCheck、WaitStart、**Execute_Action**、再回到 WaitStart。Execute_Action 步驟內只做兩件事：① 動作 N：`fb_Cycle_Action.xExecute := TRUE;`；② 轉換條件：`fb_Cycle_Action.xDone`。
  - **FB_Cycle_Action（ST）**：內部用 CASE 或子步驟（如 10→20→30→40→50），依序把 `xPusher_Req`、`xLifter_Req` 設為 TRUE/FALSE，並在每一步等待對應感測器（如 `GVL_IO.St1_Cyl_Pusher.i_FwdLimit`）；全部做完後設 `xDone := TRUE` 並將內部狀態歸零。CFC 中把 `fb_Cycle_Action.xPusher_Req`、`xLifter_Req` 連到各汽缸 FB 的 `xAuto_Cmd`。
- **效果**：SFC 只負責「何時開始、何時算完成」；動作細節與感測器等待都在 FB 內，修改時只改 FB，不碰 SFC 圖。
- **注意**：Execute_Action 步驟的動作建議用 **N (Non-stored)** 寫 `fb_Cycle_Action.xExecute := TRUE`；步驟結束後該變數會隨步驟停用而變回 FALSE，FB 內部可在偵測到 xExecute 下降沿時將 xDone 與內部狀態歸零，以備下一循環。

### 8.5 SFC 步驟內「動作」怎麼寫？

- 在步驟上右鍵 → 添加動作 → 語言選 ST；限定符選 **N (Non-stored)**：在該步驟激活期間持續執行。
- 動作內容範例：`GVL_Auto.St1.xPusher_Ext_Req := TRUE;`（或對應您的 GVL_Auto 路徑）。轉換條件欄位填感測器或 FB 完成訊號，例如 `GVL_IO.St1_Cyl_Pusher.i_FwdLimit` 或 `fb_Cycle_Action.xDone`。
- 變數路徑需與 CFC 中接線一致；若出現紅字可按 F2 用輸入助手選取全域變數。

### 8.6 MainTask 設定要點

- **呼叫順序**：先 **SFC**（指揮官）、再 **CFC**（執行兵），例如 1 → PRG_Station1_SFC，2 → PRG_Station1_CFC。同一週期內 SFC 先下指令，CFC 再輸出到 IO。
- **Interval**：Cyclic，建議 `t#20ms` 或 `t#10ms`；汽缸級應用不需 1ms，過快浪費 CPU。
- **Watchdog**：建議啟用，Time 設為 Interval 的 2～3 倍（如 20ms 則 40ms），避免程式卡死。
- 編譯後 Login，在 Task Configuration 的 Monitor 可看 Cycle time 與 Count，確認任務有執行。

---

## 9. 總結

- **SFC**：負責「流程與狀態」—— 讓機台怎麼走每一步一目了然。
- **CFC**：負責「訊號與方塊拼裝」—— 讓訊號流與互鎖邏輯圖形化，方便教學與現場溝通。
- **ST**：負責「核心邏輯與演算法」—— 提供高可讀、易重用且適合版本控管的實作。

在新專案或教學範例中，建議依上述分層與規範進行設計與實作，以兼顧：

- 現場工程師與初學者的學習曲線。
- 長期維護與擴充的彈性。
- 版本控管與團隊協作的效率。

