# CODESYS SoftMotion 官網教學與範例總覽

本文件整理自 CODESYS 官方文件與 Help 入口（`content.helpme-codesys.com`），彙總 **SoftMotion** 在安裝目錄下 `CODESYS SoftMotion\\Examples` 與 `CODESYS SoftMotion\\Examples\\Tutorial` 中常見的教學與範例專案，並以「一個範例一小節」的方式說明重點與適用情境。

---

## 範例索引

| # | 類別 | 範例名稱 | 專案檔名 |
|---|------|----------|----------|
| 1 | PLCopen 基礎 | 單軸運動控制 | PLCopenSingle.project |
| 2 | PLCopen 基礎 | 控制器位置環（SM_Drive_PosControl） | PosControl.project |
| 3 | PLCopen 基礎 | 虛擬時間軸電子凸輪 | PLCopenMulti.project |
| 4 | BasicMotion | Cam 匯出與匯入 | BasicMotion_CamExportAndImport.project |
| 5 | BasicMotion | CamIn 起動模式 | BasicMotion_CamIn_StartModes.project |
| 6 | BasicMotion | 線上建立凸輪表 | BasicMotion_CreateCamTableOnline.project |
| 7 | BasicMotion | 高精度數位凸輪開關 | BasicMotion_DigitalCamSwitch_HighPrecision.project |
| 8 | BasicMotion | Forecast / Look-ahead | BasicMotion_Forecast.project |
| 9 | BasicMotion | GearInPos 齒輪同步 | BasicMotion_GearInPos.project |
| 10 | BasicMotion | 速度 Override | BasicMotion_Override.project |
| 11 | BasicMotion | 多軸同步運動 | BasicMotion_SynchronizedMotion.project |
| 12 | PLCopen 進階 | 單軸 PLCopen 變體 | PLCopenSingle2.project |
| 13 | PLCopen 進階 | 多軸 + 多組 CAM | PLCopenMultiCAM.project |
| 14 | 機器人 | Pick & Place 機器人 | Robotics_PickAndPlace.project / Robotics_PickAndPlace_without_Depictor.project |
| 15 | 機器人 | 機器人附加軸 | Robotics_AdditionalAxes.project |
| 16 | 機器人 | 動態模型 | Robotics_DynamicModel.project |
| 17 | 機器人 | 中斷與繼續 | Robotics_Interrupt_Continue.project |
| 18 | 機器人 | Jog 手動點動 | Robotics_Jogging.project |
| 19 | 機器人 | 觸發（Triggers） | Robotics_Triggers.project |
| 20 | 機器人 | 進階觸發（Triggers Advanced） | Robotics_Triggers_Advanced.project |
| 21 | 機構學 | 自訂機構學 Library | CustomKinematics.project |
| 22 | 機構學 | 自訂機構學實作 | CustomKinematics_Implementation.project |
| 23 | CNC | CNC Example 01：直接 OutQueue | CNC01_direct.project |
| 24 | CNC | CNC Example 02：線上解碼與變數 | CNC02_online.project |
| 25 | CNC | CNC Example 03：線上路徑前處理 | CNC03_prepro.project |
| 26 | CNC | CNC 表格編輯 | CNC04_table.project |
| 27 | CNC | CNC Example 05：由檔案產生 CNC | CNC05_File.project |
| 28 | CNC | 檔案 + 3D 路徑視覺化 | CNC06_File_3DPath.project |
| 29 | CNC | Subprogram 子程式 | CNC07_Subprogram.project |
| 30 | CNC | CNC Example 08：附加軸 | CNC08_AdditionalAxes.project |
| 31 | CNC | CNC Example 09：刀長補正 | CNC09_ToolLengthCorr.project |
| 32 | CNC | CNC Example 10：動態 CNC 路徑 | CNC10_DynamicPath.project |
| 33 | CNC | 自訂功能／自訂 G-code | CNC11_CustomFunctions.project |
| 34 | CNC | ReadNCFile2 + Token Modifier | CNC12_TokenModifier.project |
| 35 | CNC | 讀取插補器狀態 | CNC13_ReadInterpolatorState.project |
| 36 | CNC | PathPreprocessing 綜合範例 | CNC14_PathPreprocessing.project |
| 37 | CNC | 大型 G-code 程式 | CNC15_LargeGCode.project |
| 38 | CNC | G31 探針（清除剩餘距離） | CNC16_G31.project |
| 39 | CNC | 從字串／串流讀取 G-code | CNC17_ReadGCodeFromStrings.project |

**快速跳轉：**  
- [一、SoftMotion 概述](#一softmotion-概述)  
- [學習地圖](#學習地圖)（[Basic Motion](#學習地圖一-basic-motion-由淺入深) · [Robotics](#學習地圖二-robotics-由淺入深) · [CNC](#學習地圖三-cnc-由淺入深)）  
- [二、PLCopen 與 BasicMotion 基礎運動控制範例](#二plcopen-與-basicmotion-基礎運動控制範例)  
- [三、機器人與機構學範例](#三機器人與機構學範例)  
- [四、CNC 與路徑處理範例](#四cnc-與路徑處理範例)  
- [五、範例對照總表](#五範例對照總表)  
- [六、官方文件連結（英文）](#六官方文件連結英文)  
- [七、與本目錄的對應](#七與本目錄的對應)

---

## 一、SoftMotion 概述

**CODESYS SoftMotion** 是整合於 IEC 61131-3 CODESYS 開發系統的運動控制套件，提供：

- **單軸與多軸運動控制**
- **電子凸輪（Electronic Cams）與齒輪**
- **同步運動與軸組（Axis Group）控制**
- **CNC / G-code 解碼與插補器**
- **機器人與多種標準／自訂機構學**
- **可視化工具（Cam Editor、CNC 編輯器、3D Path、Depictor 等）**

官方產品頁（SoftMotion）：  
`https://www.codesys.com/products/codesys-motion-cnc-robotics/softmotion.html`

範例安裝路徑（以 CODESYS 3.5.x 為例，實際版本號可能不同）：

- 一般範例：`C:\Program Files\CODESYS 3.5.x\CODESYS\CODESYS SoftMotion\Examples\`
- Tutorial 範例：`C:\Program Files\CODESYS 3.5.x\CODESYS\CODESYS SoftMotion\Examples\Tutorial\`

---

## 學習地圖

若要**系統性學習** SoftMotion，建議依「單軸 → 多軸／凸輪 → 機器人／CNC」的順序，先建立 PLCopen 與軸控概念，再進入軸組與路徑。以下按 **Basic Motion**、**Robotics**、**CNC** 三條主線，由淺入深排列範例順序，並標出各範例中需掌握的 **Function Block／觀念**。

---

### 學習地圖（一）Basic Motion：由淺入深

| 順序 | 範例專案 | 主要掌握的 FB／觀念 |
|------|----------|----------------------|
| 1 | **PLCopenSingle** | **MC_Power**（軸上電、Enable）、**MC_MoveAbsolute**（絕對定位）；Execute / Done / Busy 的呼叫與復歸；虛擬軸的加入與 Online 監看。 |
| 2 | **PLCopenSingle2** | 在單軸基礎上集中宣告並初始化 **MC_Power / MC_MoveVelocity / MC_MoveAbsolute**，示範如何先設定好預設運動參數，供 VISU 或其他程式重複使用。 |
| 3 | **BasicMotion_SynchronizedMotion** | **多軸同步鏈**：Master → Slave0（**MC_GearIn** 齒輪）→ Slave1（**MC_Phasing** 相位偏移）→ Drive（**SMC_BacklashCompensation** 背隙補償）；Master 以絕對定位來回運動，其餘三軸依齒輪比、相位與背隙補償同步跟隨。 |
| 4 | **BasicMotion_Override** | **MC_SetOverride / SMC_GetOverride**：在單一絕對位置命令執行期間，依條件（例如實際位置門檻）動態調整 **VelFactor**，平滑改變整體速度而不中斷運動。 |
| 5 | **PLCopenMulti** | **虛擬主軸** + **電子凸輪**：**MC_CamTableSelect**、**MC_CamIn**（Master/Slave、Periodic、Offset/Scaling）；**MC_MoveVelocity** 驅動主軸；**SMC_GetTappetValue**（Tappet 開關）。 |
| 6 | **BasicMotion_CamIn_StartModes** | **MC_CamIn** 的 **StartMode**（absolute / relative）、**MasterAbsolute / SlaveAbsolute**、**BufferMode**；避免 Cam 接入時位置躍變。 |
| 7 | **BasicMotion_CamExportAndImport** | Cam Editor 的**匯出／匯入**；凸輪表檔案格式與跨專案共用。 |
| 8 | **BasicMotion_CreateCamTableOnline** | **執行期建立凸輪表（單任務 + 多任務）**：在 MainTask 以 **CamBuilder** 建立 CamOnline，在 BuilderTask 以 **WriteMulticoreSafe + GVL.safeCam** 建立多工安全凸輪，再用 **GetCopy** 讀出 CamOnlineMultitask，三種 Cam 同時驅動不同從軸以便比較。 |
| 9 | **BasicMotion_DigitalCamSwitch_HighPrecision** | **數位凸輪開關**：依軸位置精準觸發輸出；解析度、濾波與任務週期。 |
| 10 | **BasicMotion_GearInPos** | **MC_GearInPos**：在條件滿足時掛上齒輪、設定齒輪比；主從軸位置同步的進階用法。 |
| 11 | **BasicMotion_Forecast** | **SMC_SetForecast / SMC_GetTravelTime / SMC_ReadSetValues**：設定 Forecast 視窗，計算「到達指定位置需要多久」，並在該預估時間點讀出未來的 SetPosition / SetVelocity / SetAcceleration，用於 look-ahead 與提早觸發 I/O。 |
| 12 | **PosControl** | **SM_Drive_PosControl**：控制器內建位置環；Scaling/Mapping、**SMC_PosControlInput/Output**；死區與 Kp 調機、Trace 量測。 |
| 13 | **PLCopenMultiCAM** | **雙凸輪交替**：兩個 **MC_CamTableSelect / MC_CamIn** 共享一組 Virtual/Drive 主從軸，透過狀態機與 Buffered 模式在 Example1／Example2 之間平順切換。 |

**學習主線**：先會單軸啟停與定位（1～2）→ 再會兩軸同步與 Override（3～4）→ 接著凸輪與 Tappet（5～6）→ 凸輪進階與齒輪（7～11）→ 最後位置環與多 CAM（12～13）。

---

### 學習地圖（二）Robotics：由淺入深

| 順序 | 範例專案 | 主要掌握的 FB／觀念 |
|------|----------|----------------------|
| 1 | **Robotics_PickAndPlace** | **軸組（Axis Group）**、**Tripod** 機構學；**MC_GroupEnable**；**MC_MoveDirectAbsolute / MC_MoveDirectRelative / MC_MoveLinear**；**PCS_1 / PCS_2** 與 **MC_TrackRotaryTable**、**MC_TrackConveyorBelt**（動態座標追蹤）；取放料狀態機與 bCommandAccepted。 |
| 2 | **Robotics_Jogging** | **Jog** 點動：增量或連續運動、速度與軟體限位、安全區；HMI 與軸組的介接。 |
| 3 | **Robotics_Triggers** | **Trigger**：在路徑上的位置或時間點觸發 I/O；Trigger 設定與與運動的同步。 |
| 4 | **Robotics_Triggers_Advanced** | 多條 Trigger、條件式觸發、與外部裝置的進階同步。 |
| 5 | **Robotics_Interrupt_Continue** | **中斷與繼續**：**MC_Stop / MC_Halt / MC_Continue** 或自訂狀態機；安全停止後如何平滑回到路徑。 |
| 6 | **Robotics_AdditionalAxes** | 機器人**外掛軸**：在軸組外增加額外軸（旋轉台、滑台）；與主軸組的協調與任務分工。 |
| 7 | **Robotics_DynamicModel** | **動態模型**：質量、慣量、負載對軌跡的影響；速度／加速度限制與補償。 |
| 8 | **CustomKinematics** | 自訂機構學**介面**：**MC_KIN_REF_SM3**、**ISMKinematicsWithInfo2** 等；Library 專案結構。 |
| 9 | **CustomKinematics_Implementation** | 自訂機構學**實作**：正逆解、軸對應；將自訂機構學掛到 Axis Group 並實際運動。 |

**學習主線**：先從 Pick & Place 建立軸組與動態座標概念（1）→ 再學 Jog、Trigger、中斷繼續等操作與安全（2～5）→ 接著附加軸與動態模型（6～7）→ 最後自訂機構學（8～9）。

---

### 學習地圖（三）CNC：由淺入深

| 順序 | 範例專案 | 主要掌握的 FB／觀念 |
|------|----------|----------------------|
| 1 | **CNC01_direct** | **SMC_OutQueue** 編譯模式；**SMC_Interpolator**（poqDataIn、dwIpoTime）；**SMC_ControlAxisByPos**；Gap 避免（bAvoidGaps、fGapVelocity 等）；CNC 編輯器與 Din66025、Path Switch Points。 |
| 2 | **CNC04_table** | **CNC Table 編輯器**：以表格編輯路徑、與圖形編輯切換；欄位自訂。 |
| 3 | **CNC02_online** | **SMC_CNC_REF** 編譯模式；**SMC_NCDecoder**；變數解碼；**PathTask**（解碼／前處理）與 **IpoTask**（插補）的**任務分離**。 |
| 4 | **CNC03_prepro** | **路徑前處理**：**SMC_SmoothPath**、G51/G50；Decoder → SmoothPath → CheckVelocities → Interpolator 的鏈結。 |
| 5 | **CNC08_AdditionalAxes** | **附加軸**：在 G-code 中加入 A 軸；**SMC_POSINFO**、**SMC_ControlAxisByPos** 寫入附加軸；Gap 避免。 |
| 6 | **CNC09_ToolLengthCorr** | **SMC_ToolLengthCorr**：刀長補正、G43；插補器與轉換之間的補償鏈結。 |
| 7 | **CNC10_DynamicPath** | **動態路徑（不經 G-code）**：在 PLC 中組裝 **SMC_OUTQUEUE** / **SMC_GEOINFO**，用 **SMC_CalcLengthGeo / SMC_AppendObj** 依點列（xp/yp）動態產生線段並標記 bEndOfList，經 CheckVel → Interpolator → 軸控制。 |
| 8 | **CNC05_File** | **SMC_ReadNCFile2**、**SMC_NCInterpreter**：從檔案讀取 ASCII G-code 並執行；大型程式與 Online 解碼。 |
| 9 | **CNC06_File_3DPath** | **SMC_PathCopier***、**PositionTracker**；**Path3D** 視覺化與 **VisuStruct3DTrack**。 |
| 10 | **CNC07_Subprogram** | **子程式**：獨立 .cnc 檔、搜尋目錄、參數傳遞、巢狀呼叫；SMC_ReadNCFile2 與 SMC_NCInterpreter 的 Subprogram 支援。 |
| 11 | **CNC14_PathPreprocessing** | **前處理綜合**：G51/G52、G40～G43、G60/G61、G70/G71；多個前處理 FB 的串接與順序。 |
| 12 | **CNC12_TokenModifier** | **SMC_ITokenModifier**：在 **SMC_ReadNCFile2 / SMC_ReadNCFromStream** 讀檔時由 Token Modifier 改寫 G-code Token（官方範例為 F 單位從 mm/min 轉 mm/s）。 |
| 13 | **CNC13_ReadInterpolatorState** | **Interpolator 狀態**：目前物件、位置、bEndOfPath 等；**Block Search / Resume** 的基礎。 |
| 14 | **CNC15_LargeGCode** | **大型 G-code**：FILE 模式、分批讀取、串流式處理與緩衝策略。 |
| 15 | **CNC16_G31** | **G31 探針**：Quick Stop、**SMC_SetInterpreterStartPosition**、**bAcknProbe**；清除剩餘距離與以實際停止點續跑。 |
| 16 | **CNC17_ReadGCodeFromStrings** | **SMC_ReadNCFromStream**：從字串／串流讀取 G-code；與 Token Modifier 的搭配。 |
| 17 | **CNC11_CustomFunctions** | **自訂 G/M code**：在 CNC 流程中掛入自訂功能、對應到 PLC 邏輯。 |

**學習主線**：先建立 OutQueue + Interpolator + 軸控制（1～2）→ 再學線上解碼與前處理（3～4）→ 附加軸與刀長、動態路徑（5～7）→ 檔案與 3D、子程式（8～10）→ 前處理綜合與 Token、狀態讀取（11～13）→ 大型檔、探針、串流與自訂功能（14～17）。

---

## 二、PLCopen 與 BasicMotion 基礎運動控制範例

### 1. 單軸運動控制（Controlling the Movement of Single Axes）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `PLCopenSingle.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 使用 **PLCopen 標準化 Function Blocks** 控制單一虛擬軸 `Drive`。
- 以 ST 撰寫 `MOTION_PRG`，用 `CASE iStatus` 依序呼叫 **MC_Power** → **MC_MoveAbsolute**（移到 `p`）→ 再移回 0。
- 展示最基本的 **上電、運動、完成偵測、關閉 Execute** 的寫法。

**適合**：SoftMotion 入門與 PLCopen 單軸基本流程練習。

---

### 2. 控制器位置環（Position Control on the Controller with SM_Drive_PosControl）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `PosControl.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 以 **SM_Drive_PosControl** 由 CODESYS 控制器實作位置迴路，驅動只提供速度輸入與位置回授（例如：變頻器 + 編碼器）。
- 說明 **Scaling / Mapping**（編碼器每轉脈衝數、應用單位 360° 等）與位置控制迴路參數（`D`、`Kp`、位寬、最大位置誤差）。
- 使用 **SMC_PosControlInput / Output** 將硬體限位、QuickStop 等 I/O 與軸結合。
- 利用 **Trace** 量測設定位置與實際位置之時間差，調整死區時間與增益。

**適合**：速度型驅動 + 編碼器、需在 PLC 端關閉迴路的應用。

---

### 3. 虛擬時間軸電子凸輪（Controlling a Cam Drive with a Virtual Time Axis）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `PLCopenMulti.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 以虛擬主軸 `Virtual` 搭配從軸 `Drive` 建立 **週期性凸輪**，模擬「時間軸」帶動實際線性軸。
- 在 Application 下加入 Cam 物件、設定 Tappet，並使用 **MC_CamTableSelect** 選擇 Cam，**MC_CamIn** 實際執行。
- 使用 **MC_MoveVelocity** 讓虛擬主軸以固定速度旋轉；並用 **SMC_GetTappetValue** 讀取凸輪開關狀態。

**適合**：了解電子凸輪、虛擬主軸與 Tappet 開關的整體使用流程。

---

### 4. Cam 匯出與匯入（BasicMotion_CamExportAndImport）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `BasicMotion_CamExportAndImport.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 示範在 **Cam Editor** 中定義凸輪後，如何將 Cam Table **匯出為檔案**，以及從檔案再次匯入。
- 搭配 Cam 物件的屬性與編譯格式（多項式、表格等）設定，說明如何在專案間共用凸輪。

**適合**：需要管理多組凸輪、或在多個專案之間共享凸輪資料的情境。

---

### 5. CamIn 起動模式（BasicMotion_CamIn_StartModes）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `BasicMotion_CamIn_StartModes.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 聚焦 **MC_CamIn.StartMode / MasterAbsolute / SlaveAbsolute / BufferMode** 不同組合對起動行為的影響。
- 比較 **absolute / relative** 起動方式，說明如何避免掛上 Cam 時產生位置躍變。
- 展示切換不同凸輪時如何配置緩衝模式以保持運動連續。

**適合**：需要在運轉中切換凸輪、或精細控制 Cam 接入方式的應用。

---

### 6. 線上建立凸輪表（BasicMotion_CreateCamTableOnline）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `BasicMotion_CreateCamTableOnline.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 使用程式在 **執行期建立 Cam Table**，而不是預先在 Editor 畫好。
- 透過 CamBuilder 或相關 FB，疊加 Line / Poly5 / Poly7 等片段，組成一張完整凸輪。
- 適合從配方、外部資料或 HMI 參數動態生成凸輪。

**適合**：需要依產品規格或工單即時調整凸輪曲線的機台。

---

### 7. 高精度數位凸輪開關（BasicMotion_DigitalCamSwitch_HighPrecision）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `BasicMotion_DigitalCamSwitch_HighPrecision.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 示範 **數位凸輪開關** 功能：依軸位置高度精準地開關輸出，取代機械凸輪開關。
- 著重在解析度、延遲與抖動控制，搭配高速任務與適當濾波確保精度。

**適合**：高速包裝、印刷、貼標等需要精準出膠／切刀／噴印觸發的應用。

---

### 8. Forecast / Look-ahead（BasicMotion_Forecast）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `BasicMotion_Forecast.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 利用 SoftMotion 的 **Forecast / look-ahead** 功能，預測未來短時間內的軸位置或路徑。
- 可用來提早觸發 I/O、預熱設備，或計算驅動前饋（feedforward）與負載需求。

**適合**：對時序要求嚴格、需「提早知道軸會到哪裡」的控制策略。

---

### 9. GearInPos 齒輪同步（BasicMotion_GearInPos）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `BasicMotion_GearInPos.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 示範 **MC_GearInPos**：在主軸到達指定位置或條件時，才將從軸「掛上齒輪」並設置齒輪比。
- 典型案例為包裝／捲料設備，在產品到位後才與主軸同步捲動或送料。

**適合**：需要條件式掛齒輪、避免整段行程都強制齒輪同步的機台。

---

### 10. 速度 Override（BasicMotion_Override）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `BasicMotion_Override.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 示範如何在軸運動過程中 **平滑修改速度／加減速度 Override 比例**。
- 著重於避免產生速度突變或同步問題，通常會使用 SoftMotion 的 Override 機制而非直接改速度參數。

**適合**：需要 HMI 旋鈕或設定值調整整機速度（如 50%～120%）的應用。

---

### 11. 多軸同步運動（BasicMotion_SynchronizedMotion）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `BasicMotion_SynchronizedMotion.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 以 Master 軸為主，透過 **MC_GearIn**（Master → Slave0）、**MC_Phasing**（Slave0 → Slave1）、**SMC_BacklashCompensation**（Slave1 → Drive）串成一條多軸同步鏈。  
- Master 軸執行 0 ↔ 100 的來回絕對定位，其餘三軸依齒輪比、相位偏移與背隙補償自動跟隨，可在 Trace 中清楚觀察每一節的差異。
- 展示如何以 PLCopen FB 讓兩軸保持相對位置或速度關係，例如輸送帶與壓輥同步。

**適合**：任何需要兩軸以上協調運動的系統（捲料線、搬運平台、雙驅龍門等）。

---

### 12. 單軸 PLCopen 變體／初始化範本（PLCopenSingle2）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `PLCopenSingle2.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 在 `MOTION_PRG` 中集中宣告並初始化三個常用功能塊：**MC_Power**、**MC_MoveVelocity**、**MC_MoveAbsolute**，預先設定好上電、速度模式與絕對定位的預設參數。
- 實際呼叫順序與觸發條件通常由 Visu 或其他程式控制，本範例重點在「把運動控制 FB 的參數集中管理、方便重複使用」。

**適合**：想將單軸運動指令做成「參數已設定好」的範本，供其他程式或 HMI 直接操作的情境。

---

### 13. 雙凸輪交替同步（PLCopenMultiCAM）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `PLCopenMultiCAM.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 以虛擬主軸 `Virtual` 與從軸 `Drive` 為基礎，同時選取兩張凸輪表 **Example1 / Example2**，並分別對應到 **CamIn1 / CamIn2**。
- 透過整數變數 `state` 組成狀態機，搭配 **MC_CamTableSelect / MC_CamIn** 的 `StartMode`、`BufferMode` 與 `EndOfProfile`，在兩張凸輪表之間反覆、平順地交替控制從軸。
- 搭配 Trace 觀察主軸位置、從軸位置與 `CamIn1.Active / CamIn2.Active`、`InSync` 等訊號，可以清楚看到凸輪切換時軸運動的連續性。

**適合**：需要在不同凸輪輪廓之間反覆切換，且要求切換過程不中斷、不產生速度突變的應用。

---

## 三、機器人與機構學範例

### 14. Pick & Place 機器人（Robotics_PickAndPlace）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `Robotics_PickAndPlace.project`、`Robotics_PickAndPlace_without_Depictor.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 使用 **三腳架（Tripod）軸組 + 旋轉桌 + 輸送帶** 實現取放料流程：從旋轉桌取環，放到輸送帶上的圓錐。
- 使用 **PCS_1 / PCS_2** 搭配 `MC_TrackRotaryTable`、`MC_TrackConveyorBelt` 追蹤旋轉桌與輸送帶移動。
- `Robot` 程式中以狀態機呼叫 PLCopen 群組指令（MC_GroupEnable、MC_MoveDirectAbsolute、MC_MoveLinear 等）完成一整套 Pick & Place 動作。
- 帶 Depictor 版本提供 3D 動畫；不帶 Depictor 版本則使用簡化視覺化。

**適合**：理解多軸軸組、動態座標系與同步追蹤的綜合範例（對應你專案中的 `Robotics_PickAndPlace` 目錄）。

---

### 15. 機器人附加軸（Robotics_AdditionalAxes）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `Robotics_AdditionalAxes.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 示範在現有機器人（例如 Tripod、SCARA 或 6 軸手臂）之外加入 **外掛軸（如旋轉台或輸送軸）**。
- 說明如何在軸組與附加軸之間分工，並在運動規劃中同時控制。

**適合**：有機器人本體外，還需要額外軸（如第 7 軸、外部滑台）的應用。

---

### 16. 動態模型（Robotics_DynamicModel）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `Robotics_DynamicModel.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 著重於 **動態模型（質量、慣量、負載）** 對機器人運動的影響。
- 展示如何根據模型限制速度與加速度，或利用模型提升軌跡精度與穩定性。

**適合**：高速或重載機器人應用，需要考慮動態效應與補償者。

---

### 17. 中斷與繼續（Robotics_Interrupt_Continue）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `Robotics_Interrupt_Continue.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 示範在機器人運動過程中 **中斷（例如安全門、急停）並安全停止**，之後再 **平滑回到路徑繼續運動**。
- 使用 MC_Stop、MC_Halt、MC_Continue 或自訂狀態機管理中斷與回復。

**適合**：對安全與復歸流程有嚴格要求的機台（協作機器人、門禁保護等）。

---

### 18. Jog 手動點動（Robotics_Jogging）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `Robotics_Jogging.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 實作 **Jog 點動**：透過 HMI 按鍵或方向鍵控制機器人以固定速度或固定增量移動。
- 考慮軟體限位、安全區域與速度上限，避免手動調試時造成危險。

**適合**：教導點、維修與線上手動操作需求的系統。

---

### 19. 觸發（Robotics_Triggers）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `Robotics_Triggers.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 在機器人路徑上設定 **Trigger 點**，於特定位置或時間觸發 I/O 或事件（拍照、吹氣、打標等）。
- 基礎版本示範單一或少數 Trigger，強調與位置同步。

**適合**：需要在運動軌跡上的特定點觸發外部設備的應用。

---

### 20. 進階觸發（Robotics_Triggers_Advanced）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `Robotics_Triggers_Advanced.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 在 `Robotics_Triggers` 基礎上增加 **多條 Trigger 線、條件式觸發與較複雜的同步邏輯**。
- 展示如何在高密度 Trigger 場景下仍維持可靠性與可維護性。

**適合**：對觸發邏輯複雜、需多事件同步的高階應用。

---

### 21. 自訂機構學 Library（CustomKinematics）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CustomKinematics.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 提供 **自訂機構學介面與 Library 專案**，定義如 `MC_KIN_REF_SM3`、`ISMKinematicsWithInfo2` 等介面。
- 做為自訂機構學實作的基礎與範本。

**適合**：需要自行實作特殊機構學（非標準 Tripod/SCARA/6 軸）的開發者。

---

### 22. 自訂機構學實作（CustomKinematics_Implementation）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CustomKinematics_Implementation.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 在 `CustomKinematics` 基礎上給出完整實作範例，例如自訂的 Gantry 結構或其他特殊機構。
- 示範如何將自訂機構學套用到 Axis Group 並實際驅動軸。

**適合**：打算真正把自訂機構學用在機台上的實作參考。

---

## 四、CNC 與路徑處理範例

### 23. CNC Example 01：直接產生 OutQueue（CNC01_direct）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC01_direct.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 兩軸 CNC（X/Y），在平面上依指定速度與加減速走四個點，並設置兩個 Path Switch Points。
- 使用編譯模式 **SMC_OutQueue**，NC 程式直接編譯成 GEOINFO 佇列，執行時不需解碼器。
- 以 **SMC_Interpolator** 接收 OutQueue 並產生離散路徑點，再透過 `SMC_ControlAxisByPos` 與座標轉換（如 SM_Trafo）控制實際軸。

**適合**：了解 CNC + OutQueue + Interpolator 最基本架構。

---

### 24. CNC Example 02：線上解碼與變數（CNC02_online）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC02_online.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 在 CNC 程式中使用變數（例如 `g_x`, `g_y`），並於執行時解碼成路徑。
- 編譯模式 **SMC_CNC_REF**：CNC 程式編譯成 SMC_GEOINFO 陣列，由 **SMC_NCDecoder** 在運轉中解碼到 SMC_OUTQUEUE。
- 採 Task 分離：**PathTask**（解碼與前處理） + **IpoTask**（插補），提升效能與即時性。

**適合**：需依參數動態變更路徑的 CNC 應用。

---

### 25. CNC Example 03：線上路徑前處理（CNC03_prepro）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC03_prepro.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 在 `CNC02_online` 的架構上加入 **SMC_SmoothPath** 等前處理，將轉角以 Spline 平滑化。
- 支援 G51/G50 等指令，並可在 CNC 編輯器中使用「Show preprocessed path」檢視前處理後路徑。

**適合**：希望 CNC 路徑轉角不暫停、走圓角／光順軌跡的應用。

---

### 26. CNC 表格編輯（CNC04_table）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC04_table.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 示範使用 **CNC Table（表格）編輯器** 建立與編輯 CNC 路徑。
- 可在圖形編輯與表格編輯之間切換，並自行自訂表格欄位以符合應用需求。

**適合**：偏好以「表格」維護 G-code／路徑資料的開發者。

---

### 27. 由檔案產生 CNC（CNC05_File）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC05_File.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 示範如何從 **控制器檔案系統中的 ASCII G-code 檔** 讀取程式並執行。
- 以 **SMC_ReadNCFile2 + SMC_NCInterpreter** 取代傳統編譯模式，特別適用於 **大型程式或外部產生 G-code**。

**適合**：刀路由 CAM 或外部系統產生，需在 PLC 上讀檔執行的 CNC 應用。

---

### 28. 檔案 + 3D 路徑視覺化（CNC06_File_3DPath）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC06_File_3DPath.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 在 `CNC05_File` 的基礎上，加入 **3D Path 視覺化**，顯示程式路徑與實際軌跡。
- 使用 `SMC_PathCopier*`、`PositionTracker` 等 FB 將刀路轉為 `VisuStruct3DTrack` 資料，搭配 `Path3D` 元件呈現。

**適合**：需要在調試時檢視 CNC 3D 刀路與實際運動差異的應用。

---

### 29. Subprogram 子程式（CNC07_Subprogram）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC07_Subprogram.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 示範 G-code **Subprogram** 機制：將常用加工（鑽孔、換刀等）寫成獨立 `.cnc` 檔，於主程式呼叫。
- 使用 `SMC_ReadNCFile2` + `SMC_NCInterpreter`，展示子程式搜尋目錄、參數傳遞與巢狀呼叫。

**適合**：G-code 結構需要高度重用與模組化的 CNC 專案。

---

### 30. CNC Example 08：附加軸（CNC08_AdditionalAxes）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC08_AdditionalAxes.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 在 `CNC01_direct` 的基礎上新增 **附加軸 A**，於每段運動中額外控制 A 軸位置。
- 以 `SMC_ControlAxisByPos` 將插補器輸出的 `piSetPosition.dA` 直接寫入 A 軸，並透過 Gap 避免處理不連續。

**適合**：多軸 CNC 中需同時控制主路徑與附加軸（例如刀頭角度）的應用。

---

### 31. 刀長補正（CNC09_ToolLengthCorr）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC09_ToolLengthCorr.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 使用 `SMC_ToolLengthCorr` 於插補器與座標轉換之間，對 Z 方向施做 **刀具長度補償**。
- 配合 G43 與工具資料，確保更換刀具後加工高度仍正確。

**適合**：需要多支刀具、不同長度自動補償的 CNC 機台。

---

### 32. 動態 CNC 路徑（CNC10_DynamicPath）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC10_DynamicPath.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 在 PLC 程式中直接組裝 `SMC_OUTQUEUE` 與 `SMC_GEOINFO` 結構，**完全不依賴 G-code 檔或 CNC 編輯器**。
- 以陣列（如 `xp` / `yp`）定義一串目標點，使用 `SMC_CalcLengthGeo` 計算幾何長度，`SMC_AppendObj` 依序產生線段並寫入 OutQueue，最後以 `bEndOfList` 標記路徑結束。
- 典型架構為：Path 程式負責組佇列與 `SMC_CheckVelocities`，Ipo 程式負責 `SMC_Interpolator`、座標轉換與 `SMC_ControlAxisByPos` 驅動實際軸。

**適合**：路徑由 PLC 邏輯或外部資料動態產生，無固定 G-code 檔案可用的情境。

---

### 33. 自訂功能／自訂 G-code（CNC11_CustomFunctions）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC11_CustomFunctions.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 展示如何在 CNC 執行流程中掛入 **自訂 G/M code 功能塊**，透過 `SMC_NC_GFunctionTable` 將字串（如 `SEL`）對應到 PLC 端 FB（實作 `SMC_NC_IFunction`）。
- 使用變數列表（`SMC_SingleVar` / `SMC_VARLIST`）將 G-code 變數名（如 `LONGLINE`）綁定到 PLC 全域變數，讓 G-code 參數可直接驅動 PLC 邏輯或做偵錯。

**適合**：需要擴充 G-code 語意、支援機台客製指令或讓 G-code 與 PLC 狀態互相控制的開發者。

---

### 34. ReadNCFile2 + Token Modifier（CNC12_TokenModifier）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC12_TokenModifier.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 使用 `SMC_ITokenModifier` 介面，在 `SMC_ReadNCFile2` / `SMC_ReadNCFromStream` 讀取 G-code 時 **於解譯前動態修改 Token**（例如 F 字單位轉換、替換指令等）。
- 官方示範為將 F-word（mm/min）換算為 mm/s：讀到 `F6000` 等 Token 後，在 Modifier 中對數值除以 60，改寫後再交給 Interpreter。

**適合**：需要在匯入 G-code 時做單位轉換或批次替換的情境。

---

### 35. 讀取插補器狀態（CNC13_ReadInterpolatorState）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC13_ReadInterpolatorState.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 聚焦於如何從 `SMC_Interpolator` / `SMC_Interpolator2Dir` 讀取目前物件編號、SetPosition、是否在路徑末端（`bEndOfPath`）等狀態。
- 展示以這些狀態為基礎實作 **Block Search / Resume**，在中斷或停止後重新對齊 CNC 程式位置並安全續跑。

**適合**：需要實作「斷點續切、程式區段跳轉、插補器監控」等高階 CNC 功能的專案。

- 聚焦如何從 `SMC_Interpolator` / `SMC_Interpolator2Dir` 讀取目前物件、位置、是否在路徑末端等狀態。
- 有助於實作 **Block Search / Resume** 等功能，在中斷後回到路徑中間繼續加工。

**適合**：需要高階 CNC 控制（如斷電續切、區段跳轉）的應用。

---

### 36. PathPreprocessing 綜合範例（CNC14_PathPreprocessing）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC14_PathPreprocessing.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 匯集多種 **路徑前處理 FB**（例如平滑、圓角、刀具半徑／長度補償、角落停頓抑制、附加軸平滑等），組成 Decoder → 多級 Preprocessing → Interpolator 的完整鏈結。
- 範例中對應 G51/G52、G40～G43、G60/G61、G70/G71 等指令，示範多個前處理功能同時作用時的先後順序與互相影響。

**適合**：需要同時使用多種前處理功能、追求高品質刀路（光順、補償、無停頓）的 CNC 機台。

- 集中展示各種 **路徑前處理指令**：G51/G52（平滑／圓角）、G40～G43（刀具半徑與長度補償）、G60/G61（迴圈抑制）、G70/G71（附加軸平滑）等。
- 強調 Decoder → 多個前處理 FB → Interpolator 的完整鏈結。

**適合**：需要全面使用前處理功能、並理解其組合效果的開發者。

---

### 37. 大型 G-code 程式（CNC15_LargeGCode）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC15_LargeGCode.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 針對 **超大型 G-code 檔**（例如外部 CAM 匯出、路徑極長的加工），說明如何採用 FILE 模式與 **分批讀取 / 滾動式緩衝（streaming）** 來避免一次載入全部程式。
- 搭配 PathTask / IpoTask 分離與適當佇列深度，維持插補端連續供料，同時控制記憶體用量與啟動時間。

**適合**：航太／模具等大型刀路、或雲端／外部系統持續下發 G-code 的應用。

- 探討處理 **超大型 G-code** 時的策略：FILE 模式、分批讀取與預處理，避免一次載入整個檔案。
- 常搭配 Online 解碼與滾動式緩衝（streaming）降低記憶體壓力與啟動延遲。

**適合**：加工路徑極長或由外部系統連續串流 G-code 的應用。

---

### 38. G31 探針（清除剩餘距離）（CNC16_G31）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC16_G31.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 實作 G31 探針：沿指定方向移動至目標位置，但 **一旦探針或感測器觸發即在當前實際位置停下**，並清除程式中剩餘移動距離。
- 使用 Quick Stop、`SMC_SetInterpreterStartPosition` 與 `bAcknProbe` 等機制，讓後續 G-code 以「實際停止點」為新起點繼續加工或量測。

**適合**：工件找正、Z 高度量測、接觸式探測等需要依感測器位置自動修正程式座標的 CNC 應用。

- 實作 G31 探針：向目標位置移動，**一旦探針或光柵觸發，即在當前位置停下**，並清除剩餘距離。
- 使用 Quick Stop、`SMC_SetInterpreterStartPosition` 與 `bAcknProbe` 等機制，讓後續 G-code 以實際停止位置為起點繼續。

**適合**：工件找正、量測與需要依感測器位置調整程式起點的 CNC 應用。

---

### 39. 從字串／串流讀取 G-code（CNC17_ReadGCodeFromStrings）

| 項目 | 內容 |
|------|------|
| **專案名稱** | `CNC17_ReadGCodeFromStrings.project` |
| **路徑** | `..\CODESYS SoftMotion\Examples\Tutorial` |

**重點：**

- 示範使用 `SMC_ReadNCFromStream` 從 **字串或串流來源**（例如通訊封包、網路 Socket、檔案分段傳輸）讀取 G-code，而非一次性 FILE。
- 可與 Token Modifier、Interpreter、Preprocessing 串接，實作「線上產生刀路、即時下發並邊解碼邊執行」的 CNC 架構。

**適合**：遠端下載程式、雲端刀路服務、即時優化或動態產生 G-code 的高彈性應用。

- 類似 FILE 範例，但 G-code 來源是 **字串或串流（Stream）**，例如通訊或網路傳來的程式段。
- 使用 `SMC_ReadNCFromStream` 搭配 Token Modifier／Interpreter 處理連續資料。

**適合**：遠端下載程式、線上產生刀路並即時下發的高彈性 CNC 應用。

---

## 五、範例對照總表

| 類別 | 專案檔名 | 重點摘要 |
|------|----------|----------|
| PLCopen 基礎 | PLCopenSingle.project | 單軸 PLCopen、MC_Power + MC_MoveAbsolute、CASE 狀態機 |
| PLCopen 基礎 | PosControl.project | SM_Drive_PosControl、速度給定 + 編碼器回授、位置迴路調機 |
| PLCopen 基礎 | PLCopenMulti.project | 虛擬主軸 + 電子凸輪、MC_CamTableSelect、MC_CamIn、Tappet |
| BasicMotion | BasicMotion_CamExportAndImport.project | Cam Editor 定義、匯出匯入凸輪表 |
| BasicMotion | BasicMotion_CamIn_StartModes.project | MC_CamIn 起動模式與 absolute/relative 行為 |
| BasicMotion | BasicMotion_CreateCamTableOnline.project | 執行期以 CamBuilder 建立線上凸輪，並透過 safeCam 與多任務建立第二組凸輪，三種 Cam 來源同時比較 |
| BasicMotion | BasicMotion_DigitalCamSwitch_HighPrecision.project | 高精度數位凸輪開關、位置驅動輸出 |
| BasicMotion | BasicMotion_Forecast.project | Forecast / GetTravelTime / ReadSetValues 預測到達時間與未來 Set 值 |
| BasicMotion | BasicMotion_GearInPos.project | MC_GearInPos 有條件掛齒輪 |
| BasicMotion | BasicMotion_Override.project | 平滑速度／加速度 Override 調整 |
| BasicMotion | BasicMotion_SynchronizedMotion.project | 齒輪 + 相位 + 背隙補償的多軸同步鏈示例 |
| PLCopen 進階 | PLCopenSingle2.project | 單軸 PLCopen 結構最佳化與封裝 |
| PLCopen 進階 | PLCopenMultiCAM.project | 多組 CAM、多從軸主從關係 |
| 機器人 | Robotics_PickAndPlace.project | Tripod + 旋轉桌 + 輸送帶 Pick & Place，PCS_1/PCS_2 追蹤 |
| 機器人 | Robotics_AdditionalAxes.project | 機器人外掛軸控制 |
| 機器人 | Robotics_DynamicModel.project | 動態模型與速度／加速度限制 |
| 機器人 | Robotics_Interrupt_Continue.project | 中斷停止與平滑繼續運動 |
| 機器人 | Robotics_Jogging.project | Jog 手動點動與安全限位 |
| 機器人 | Robotics_Triggers.project | 基本 Trigger 位置觸發 I/O |
| 機器人 | Robotics_Triggers_Advanced.project | 多 Trigger 線與條件式觸發 |
| 機構學 | CustomKinematics.project | 自訂機構學介面與 Library 定義 |
| 機構學 | CustomKinematics_Implementation.project | 自訂機構學實作與 Axis Group 應用 |
| CNC | CNC01_direct.project | SMC_OutQueue、兩軸 CNC、基礎 Interpolator 架構 |
| CNC | CNC02_online.project | SMC_CNC_REF、變數解碼、PathTask / IpoTask 分離 |
| CNC | CNC03_prepro.project | SMC_SmoothPath 等路徑前處理、G51/G50 |
| CNC | CNC04_table.project | CNC Table 表格編輯路徑 |
| CNC | CNC05_File.project | 從檔案讀取 ASCII G-code 並執行 |
| CNC | CNC06_File_3DPath.project | G-code 檔 + 3D Path 視覺化 |
| CNC | CNC07_Subprogram.project | G-code Subprogram（子程式）結構 |
| CNC | CNC08_AdditionalAxes.project | CNC 附加軸 A，同步控制主路徑與附加軸 |
| CNC | CNC09_ToolLengthCorr.project | 刀長補正與 G43 支援 |
| CNC | CNC10_DynamicPath.project | PLC 端動態組裝 SMC_OUTQUEUE |
| CNC | CNC11_CustomFunctions.project | 自訂 G/M code 與自訂功能 |
| CNC | CNC12_TokenModifier.project | Token Modifier，匯入時動態修改 G-code |
| CNC | CNC13_ReadInterpolatorState.project | Interpolator 狀態讀取與 Block Search 應用 |
| CNC | CNC14_PathPreprocessing.project | 多種前處理功能綜合示範 |
| CNC | CNC15_LargeGCode.project | 大型 G-code 分批與串流處理 |
| CNC | CNC16_G31.project | G31 探針與清除剩餘距離 |
| CNC | CNC17_ReadGCodeFromStrings.project | 從字串／串流來源讀取 G-code |

---

## 六、官方文件連結（英文）

- SoftMotion 概覽（Basic）：  
  `https://content.helpme-codesys.com/en/CODESYS%20SoftMotion/_sm_overview_basic.html`
- 運動控制章節：  
  `https://content.helpme-codesys.com/en/CODESYS%20SoftMotion/_sm_f_motion_control.html`
- 機器人章節：  
  `https://content.helpme-codesys.com/en/CODESYS%20SoftMotion/_sm_f_robotics.html`
- CNC Editor / DIN 66025 基本：  
  `https://content.helpme-codesys.com/en/CODESYS%20SoftMotion/_sm_cnc_edt_basics.html`
- 各範例的詳細說明：可於 Help 入口搜尋專案名稱，例如 `PLCopenSingle`、`CNC02_online`、`Robotics_PickAndPlace` 等。

---

## 七、與本目錄的對應

本專案 `ExampleFile/` 目錄下，已依照本總覽的分類與專案名稱建立對應資料夾，並透過 `parse_codesys_xml.py` 自動從 CODESYS XML 匯出檔還原 ST 程式與說明檔。  
目前已整理完成的 SoftMotion 官方範例與本專案目錄對照如下（僅列出已做「XML 匯出解析＋教材式說明」的範例）：

| 類別 | 官網範例專案 | 本專案目錄（ExampleFile 下） | 說明 |
|------|--------------|-------------------------------|------|
| 機器人 | Robotics_PickAndPlace.project | `Robotics_PickAndPlace/` | 已從 `Robotics_PickAndPlace_xml.export` 還原 `Robot.st`、`Environment.st`、`Cone.st`、`Ring.st`、`GVL.st` 等，並完成教材式 `Robotics_PickAndPlace_整體架構與功能.md`。 |
| 機器人 | Robotics_PickAndPlace_without_Depictor.project | `Robotics_PickAndPlace_without_Depictor/` | 結構與 PickAndPlace 類似，但不依賴 3D Depictor；已還原程式並撰寫對應說明。 |
| 機器人 | Robotics_Jogging.project | `Robotics_Jogging/` | 已解析 PLC_PRG / GroupJog2，完成 Jog 教學向的說明檔。 |
| 機器人 | Robotics_Triggers.project | `Robotics_Triggers/` | 已解析 Main_PRG / Planning_PRG，說明 Trigger 基本用法與時序。 |
| 機器人 | Robotics_Triggers_Advanced.project | `Robotics_Triggers_Advanced/` | 已解析 GlueApplication、TriggerWithTimeShift 等，完成進階 Trigger 教材說明。 |
| 機器人 | Robotics_Interrupt_Continue.project | `Robotics_Interrupt_Continue/` | 已整理中斷／續行流程與 `MC_GroupInterrupt`／`MC_GroupContinue` 用法。 |
| 機器人 | Robotics_AdditionalAxes.project | `Robotics_AdditionalAxes/` | 已解析 PLC_PRG，示範主軸＋附加軸同步運動與 Trace。 |
| 機器人 | Robotics_DynamicModel.project | `Robotics_DynamicModel/` | 已還原動力學模型 `DynModel_Scara2_Z`、測試程式與 Demo 狀態機，並完成詳細說明。 |
| 機構學 | CustomKinematics_Implementation.project | `CustomKinematics_Implementation/` | 已解析 `Jog`、`Prg_Visu`、`SMC_TRAFOF_Gantry3C`，整理為自訂機構學實作與 Jog/視覺化的教材。 |

未列在上表的 BasicMotion / CNC 範例，目前仍依照本文件的「學習地圖」與索引說明原始官方專案與路徑，尚未在 `ExampleFile/` 下做 XML 解析與完整教材化；若未來在專案中額外引入，可依本表格式增加對照條目。

若日後 CODESYS 官網或 SoftMotion 版本更新導致範例內容變動，請以最新官方文件與實際安裝目錄中的專案為準，並視需要同步更新本說明檔案與 `ExampleFile/` 內的還原程式與說明。

若日後 CODESYS 官網或 SoftMotion 版本更新導致範例內容變動，請以最新官方文件與實際安裝目錄中的專案為準，並視需要同步更新本說明檔案。

---

## 附錄：.library 與 XML 匯出檔解析說明

### A. .library 檔案（較難還原程式碼）

若在範例目錄下放置 CODESYS 匯出的 **.library** 檔（例如 `Robotics_PickAndPlace.library`），可依下列結構理解其內容；**程式本體（ST/CFC）無法從 .library 直接還原成可讀文字**，需在 CODESYS 內開啟或改用 XML 匯出。

| 項目 | 說明 |
|------|------|
| **本體** | 標準 **ZIP** 壓縮檔，可用 `unzip -l Robotics_PickAndPlace.library` 檢視內容。 |
| **內部檔案** | 多為 **UUID 檔名**：`<uuid>.meta`（中繼資料）、`<uuid>.object`（物件內容）；另可能有 `*.auxiliary`、`poolcontext.pool.*.precompileinfo.auxiliary` 等。 |
| **專案根節點** | 最大的 XML 結構通常對應 **專案根**（`<ProjectRoot>`），為 **UTF-16LE** 編碼的 XML，內容為樹狀 Key/SubKeys/Values，描述專案與設定。 |
| **POU／程式** | 各 POU 對應的 **.object** 多為 **CODESYS 二進位序列化格式**，無法用一般腳本還原成 ST 原始碼。 |

---

### B. XML 匯出檔（可完整解析程式碼）✅

改用以 **XML 方式匯出** 的檔案（例如 `Robotics_PickAndPlace_xml.export`），**可以完整解析**並還原所有 POU 的宣告與實作程式碼。

#### 檔案格式

| 項目 | 說明 |
|------|------|
| **編碼** | **UTF-8** 純文字，可直接用文字編輯器或腳本讀取。 |
| **根節點** | `<ExportFile>`，內含 `<StructuredView>` 與多個樹狀節點。 |
| **POU 辨識** | 每個 POU 對應一組 `<Single Type="{6198ad31-...}" Method="IArchivable">`，其下 **MetaObject** 的 `<Single Name="Name" Type="string">` 即為 POU 名稱（如 `Robot`、`Environment`、`Cone`、`Ring`、`DepictorCalculations`、`Tripod_PlanningPrg`）。 |
| **宣告（Declaration）** | 在 **Interface** → **TextDocument** → **TextBlobForSerialisation**（`Type="string"`）內，即為 ST 的 VAR / VAR_INPUT 等宣告區。 |
| **實作（Implementation）** | 在 **Implementation** → **TextDocument** → **TextBlobForSerialisation**（`Type="string"`）內，即為 ST 的程式本體。 |
| **XML 跳脫** | 程式碼中的 `<`、`>` 會寫成 `&lt;`、`&gt;`，還原時需替換回原字元。 |

#### 本目錄實際解析結果

已對 **`ExampleFile/Robotics_PickAndPlace_xml.export`** 進行解析，可正確讀取以下 POU 的宣告與實作：

| POU 名稱 | 類型 | 說明 |
|----------|------|------|
| **Cone** | FUNCTION_BLOCK | 輸送帶上的圓錐、MC_TrackConveyorBelt、PCS_2 追蹤。 |
| **Ring** | FUNCTION_BLOCK | 旋轉桌上的環、MC_TrackRotaryTable、PCS_1 追蹤。 |
| **Environment** | PROGRAM | 旋轉桌／輸送帶驅動、cone1/2/3 與 ring1/2 狀態機、bRingOnTable。 |
| **Robot** | PROGRAM | 三軸上電、SetPosition、SetCoordinateTransform、MC_GroupEnable、取放料狀態機（40～120）。 |
| **DepictorCalculations** | PROGRAM | Tripod 與輸送帶標記的視覺化計算。 |
| **Tripod_PlanningPrg** | PROGRAM | 主程式入口（實作僅 `;`，實際邏輯在 Robot / Environment 等）。 |

因此，若需要**從匯出檔自動還原範例程式**，請在 CODESYS 使用 **「匯出為 XML」**（或匯出為 `.xml.export`），再以腳本或本文件說明之節點路徑擷取 `TextBlobForSerialisation` 內容，即可得到可讀的 ST 程式碼。

---

### C. 除 POU 外，XML 中還有哪些資訊可幫助了解專案／需注意的設定

從同一份 XML 匯出檔還可解析下列內容，方便**還原專案架構、對照文件、或檢查重要設定**。建議在接手新專案或比對範例時，一併檢視這些區塊。

#### 1. 裝置樹與軸／軸組結構（Device tree, Axes, Axis Group）

| XML 可讀內容 | 說明 | 你可注意的事 |
|--------------|------|----------------|
| **Device** 下節點名稱 | 例如 `CODESYS Control Win V3`、`Plc Logic`、`Application`。 | 確認目標 PLC 型號與專案層級是否正確。 |
| **SoftMotion General Axis Pool** | 軸池名稱與路徑（Path：Device → Plc Logic → Application）。 | 運動軸一定掛在此池下；若沒有此節點，代表未加 SoftMotion。 |
| **各軸名稱與類型** | 例如 `Tripod1` / `Tripod2` / `Tripod3`、`DriveRotaryTable`、`DriveConveyorBelt` 的 **Name**，以及 **Type** 對應的驅動類型（如 `SM_Drive_Virtual`）。 | 確認軸數量、命名與虛擬/實體驅動類型；實機時會改為實際驅動型號。 |
| **軸的 Task 綁定** | 搜尋 `Task` 或 `#buscycletask`。 | 運動軸通常綁在 **#buscycletask**；若綁錯任務，會影響週期與即時性。 |
| **軸組（Axis Group）** | 例如 **Tripod**：`MainKinematics` 的 **FBName**（如 `TRAFO.Kin_Tripod_Linear`）、**AxisMapping**（Tripod1/2/3）、**PlanningTaskName**（如 `Tripod_PlanningTask`）。 | 確認機構學 FB、軸順序與規劃任務名稱；規劃任務週期會影響軌跡精度。 |
| **機構學參數** | 軸組底下的 **ParameterValues**（如 `dOuterRadius`、`dInnerRadius`、`dLength`、`dDistance`、`dAxisAngle` 及其數值）。 | 幾何參數錯誤會導致逆解/正解錯誤；遷移專案時務必對照。 |

#### 2. 任務設定（Task Configuration）

| XML 可讀內容 | 說明 | 你可注意的事 |
|--------------|------|----------------|
| **Task Configuration** 節點 | 位於 Application 下，名稱常為「任务配置」或「Task Configuration」。 | 所有 IEC 任務的週期、優先順序與 POU 清單都在這裡。 |
| **各任務名稱與類型** | **Name**（如 `MainTask`、`Tripod_PlanningTask`、`VISU_TASK`）、**Kindoftask**（`Cyclic` / `Freewheeling`）。 | 運動與規劃建議用 Cyclic；視覺化可用較長週期（如 50 ms）。 |
| **Interval** | `<Single Name="Time" Type="string">t#4ms</Single>`、`t#8ms`、`50`（單位在 Unit，如 ms）。 | **MainTask 週期**（如 4 ms）直接影響控制迴路與運動指令更新率；改動後要重新評估即時性。 |
| **Priority** | 數字愈小優先權愈高（如 1、2、31）。 | 規劃任務通常需高於視覺化、低於或等於 MainTask，避免搶佔導致抖動。 |
| **PouList** | 每個任務底下 **PouList** 中的 **Name**（如 Robot、Environment、DepictorCalculations、Tripod_PlanningPrg、VisuElems.Visu_Prg）。 | 確認哪個 POU 在哪個任務執行；Robot/Environment 與軸組規劃任務的搭配錯誤會造成不同步。 |

#### 3. 全域變數與常數（GVL）

| XML 可讀內容 | 說明 | 你可注意的事 |
|--------------|------|----------------|
| **GVL** 節點 | **Name** 為 `GVL`（或專案自訂名稱），內容在 **Interface** → **TextDocument** → **TextBlobForSerialisation**。 | 與 POU 相同方式可還原成 ST 宣告。 |
| **VAR_GLOBAL CONSTANT** | 例如 `gcTripodTransX/Y/Z`、`gcBeltTransX/Y/Z`、`gcTableTransX/Y/Z`、`gcTCP_Ring`、`gcTripod1/2/3PosOrig`。 | 這些常數定義座標系偏移、機構尺寸與原點；**遷機或改機構時必須一起調整**。 |
| **VAR_GLOBAL** 變數 | 例如 `gbSetRing`、`gbAutomatic`。 | 若有多台或 HMI 連動，需確認這些旗標的寫入來源與時機。 |

#### 4. 函式庫與參數（Library Manager）

| XML 可讀內容 | 說明 | 你可注意的事 |
|--------------|------|----------------|
| **Library Manager** 的 **Items** / **ParameterTable** | 每個 **Name** 即函式庫識別（如 `#SM3_Basic`、`#SM3_CamBuilder`、`SM3_Robotics`、`#System_VisuElem3DPath`）。 | 確認專案引用了哪些 SoftMotion / 視覺化庫；缺少會編譯失敗。 |
| **PlaceholderResolution** | 庫的實際解析名稱與版本（如 `SM3_Robotics, 4.0.0.0 (3S - ...)`）。 | 不同 CODESYS 或 SoftMotion 版本可能解析到不同版本；升級後要檢查相容性。 |
| **庫參數（ParameterTable / Values）** | 例如 **#SM3_Basic** 的 `GC_SMC_FILE_MAXCAMEL`、`GC_SMC_FILE_MAXCAMTAP`、`GC_SMC_SET_VALUE_BUFFER_SIZE_BASE2_EXP`；**#SM3_CamBuilder** 的 `MAX_CAM_SEGMENT_COUNT`；**#System_VisuElem3DPath** 的 `GC_POINTS_PER_POLYGON`。 | 影響凸輪表大小、緩衝與 3D 顯示點數；大專案或高精度顯示時可能需要調大。 |

#### 5. Trace / 除錯設定

| XML 可讀內容 | 說明 | 你可注意的事 |
|--------------|------|----------------|
| **Trace** 節點 | **TraceDataConfig**、**TraceOutputConfig**、**Record** 底下的 **VariableList**。 | 可還原「錄了哪些變數」；例如 `Robot.readPos.Position.c.X/Y/Z`、`Robot.state`。 |
| **TaskName**、**BufferEntries**、**RefreshDuration** | Trace 綁定的任務、緩衝筆數、更新間隔。 | 確認 Trace 任務與 MainTask 一致，避免採樣與控制不同步；大緩衝會佔記憶體。 |

#### 6. 其他可選但有用的節點

- **Path** 陣列：每個物件的階層路徑（如 `Device` → `PLC逻辑` → `Application`），有助於還原樹狀結構或撰寫匯入腳本。
- **BusCycleTaskGuid**、**NeedsBusCycle**：與匯流排週期任務的關聯，用於確認 I/O 與運動是否在同一週期。
- **SymbolLibraryConfiguration**、**UnicodeStrings**：專案層級選項，若需重現完全相同編譯環境可一併匯出比對。

總結：除 POU 程式外，**任務週期與優先權、軸組機構學參數、GVL 常數、函式庫清單與庫參數、Trace 變數**都是專案能否正確運行與重現的關鍵；接手或比對專案時，建議從 XML 一併擷取並檢查上述設定。

---

### D. 建議作法

- **要版本管理／比對程式**：優先使用 **XML 匯出**（`.xml.export`），可腳本解析並還原成 `.st`。  
- **僅分享專案**：使用 `.library` 即可；若事後需要程式文字，再對同一專案做一次 XML 匯出。  
- 本目錄下 **Robotics_PickAndPlace** 已具備手動維護的 `.st` 與說明檔；若希望與官方範例同步，可定期以 XML 匯出覆蓋或比對。

