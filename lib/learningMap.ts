// SoftMotion 等教學路線的型別與資料定義
// 之後前端頁面會直接依這裡的結構來產生學習地圖

export type LibraryId = "softmotion";

export interface ExampleMeta {
  /** 之後用在 URL 的 slug，例如 basicmotion-gearinpos */
  id: string;
  /** 顯示給使用者看的標題（中文為主） */
  title: string;
  /** 官方專案名稱，例如 BasicMotion_GearInPos.project */
  projectName: string;
  /** 分類：BasicMotion / Robotics / CNC / PLCopen / 其他 */
  category: "PLCopen" | "BasicMotion" | "Robotics" | "CNC" | "Other";
  /** 在該 section 中的建議學習順序（從 1 開始） */
  order: number;
  /** 對應的說明 Markdown 相對路徑（相對於 tutorial-site/content） */
  mdPath: string;
  /** 簡短摘要，一兩句話說明這個範例在學什麼 */
  summary: string;
  /** 對應的 Offline Help 文章 id 清單，用來在範例頁面顯示延伸閱讀連結 */
  relatedHelpIds?: string[];
}

export interface LearningSection {
  /** 內部 id，例如 basic-motion、robotics、cnc */
  id: string;
  /** 顯示標題 */
  title: string;
  /** 區塊說明文字（可顯示在學習地圖頁上方） */
  description: string;
  /** 本區塊底下的範例清單 */
  examples: ExampleMeta[];
}

export interface LearningLibrary {
  id: LibraryId;
  name: string;
  description: string;
  sections: LearningSection[];
}

export interface LearningMap {
  libraries: LearningLibrary[];
}

export const learningMap: LearningMap = {
  libraries: [
    {
      id: "softmotion",
      name: "CODESYS SoftMotion",
      description:
        "從單軸運動開始，逐步學到凸輪、齒輪、機器人與 CNC 的完整 SoftMotion 學習路線。",
      sections: [
        {
          id: "basic-motion",
          title: "Basic Motion：由淺入深的基礎運動控制",
          description:
            "從 PLCopen 單軸、多軸同步，到齒輪同步與數位凸輪，建立軸控與電子凸輪的觀念。",
          examples: [
            { id: "plcopen-single", title: "單軸運動控制", projectName: "PLCopenSingle.project", category: "PLCopen", order: 1, mdPath: "softmotion/PLCopenSingle/PLCopenSingle_整體架構與功能.md", summary: "使用 MC_Power、MC_MoveAbsolute 控制單一虛擬軸，建立上電、運動、完成偵測的基本流程。", relatedHelpIds: ["codesys-overview"] },
            { id: "plcopen-single2", title: "單軸 PLCopen 變體／初始化範本", projectName: "PLCopenSingle2.project", category: "PLCopen", order: 2, mdPath: "softmotion/PLCopenSingle2/PLCopenSingle2_整體架構與功能.md", summary: "集中宣告並初始化 MC_Power、MC_MoveVelocity、MC_MoveAbsolute，預設參數供 Visu 或程式重複使用。", relatedHelpIds: ["codesys-overview"] },
            { id: "basicmotion-synchronized-motion", title: "多軸同步運動", projectName: "BasicMotion_SynchronizedMotion.project", category: "BasicMotion", order: 3, mdPath: "softmotion/BasicMotion_SynchronizedMotion/BasicMotion_SynchronizedMotion_整體架構與功能.md", summary: "Master → Slave0（MC_GearIn）→ Slave1（MC_Phasing）→ Drive（背隙補償）多軸同步鏈。" },
            { id: "basicmotion-override", title: "速度 Override", projectName: "BasicMotion_Override.project", category: "BasicMotion", order: 4, mdPath: "softmotion/BasicMotion_Override/BasicMotion_Override_整體架構與功能.md", summary: "運動過程中平滑修改速度／加減速度 Override 比例，避免速度突變。" },
            { id: "plcopen-multi", title: "虛擬時間軸電子凸輪", projectName: "PLCopenMulti.project", category: "PLCopen", order: 5, mdPath: "softmotion/PLCopenMulti/PLCopenMulti_整體架構與功能.md", summary: "虛擬主軸 + 從軸建立週期性凸輪，MC_CamTableSelect、MC_CamIn、SMC_GetTappetValue。" },
            { id: "basicmotion-camin-startmodes", title: "CamIn 起動模式", projectName: "BasicMotion_CamIn_StartModes.project", category: "BasicMotion", order: 6, mdPath: "softmotion/BasicMotion_CamIn_StartModes/BasicMotion_CamIn_StartModes_整體架構與功能.md", summary: "三種 CamIn 起動模式比較，理解如何避免凸輪接入時的位置躍變與速度突變。" },
            { id: "basicmotion-camexport-and-import", title: "Cam 匯出與匯入", projectName: "BasicMotion_CamExportAndImport.project", category: "BasicMotion", order: 7, mdPath: "softmotion/BasicMotion_CamExportAndImport/BasicMotion_CamExportAndImport_整體架構與功能.md", summary: "在 Cam Editor 中匯出／匯入凸輪表，專案間共用凸輪資料。" },
            { id: "basicmotion-create-camtable-online", title: "線上建立凸輪表", projectName: "BasicMotion_CreateCamTableOnline.project", category: "BasicMotion", order: 8, mdPath: "softmotion/BasicMotion_CreateCamTableOnline/BasicMotion_CreateCamTableOnline_整體架構與功能.md", summary: "執行期以 CamBuilder 建立凸輪表，從配方或 HMI 參數動態生成凸輪。" },
            { id: "basicmotion-digital-camswitch-high-precision", title: "高精度數位凸輪開關", projectName: "BasicMotion_DigitalCamSwitch_HighPrecision.project", category: "BasicMotion", order: 9, mdPath: "softmotion/BasicMotion_DigitalCamSwitch_HighPrecision/BasicMotion_DigitalCamSwitch_HighPrecision_整體架構與功能.md", summary: "依軸位置精準觸發輸出，解析度、濾波與任務週期設定。" },
            { id: "basicmotion-gearinpos", title: "GearInPos 齒輪同步", projectName: "BasicMotion_GearInPos.project", category: "BasicMotion", order: 10, mdPath: "softmotion/BasicMotion_GearInPos/BasicMotion_GearInPos_整體架構與功能.md", summary: "在指定條件下掛上齒輪，讓從軸與主軸在特定位置範圍內同步，切割與送料機台典型做法。" },
            { id: "basicmotion-forecast", title: "Forecast / Look-ahead", projectName: "BasicMotion_Forecast.project", category: "BasicMotion", order: 11, mdPath: "softmotion/BasicMotion_Forecast/BasicMotion_Forecast_整體架構與功能.md", summary: "預測到達指定位置所需時間與未來 Set 值，用於提早觸發 I/O 或前饋控制。" },
            { id: "poscontrol", title: "控制器位置環（SM_Drive_PosControl）", projectName: "PosControl.project", category: "PLCopen", order: 12, mdPath: "softmotion/PosControl/PosControl_整體架構與功能.md", summary: "由控制器實作位置迴路，速度給定 + 編碼器回授，Scaling/Mapping 與 Trace 調機。" },
            { id: "plcopen-multi-cam", title: "雙凸輪交替同步", projectName: "PLCopenMultiCAM.project", category: "PLCopen", order: 13, mdPath: "softmotion/PLCopenMultiCAM/PLCopenMultiCAM_整體架構與功能.md", summary: "兩張凸輪表平順交替控制從軸，狀態機與 BufferMode、EndOfProfile 搭配。" },
          ],
        },
        {
          id: "robotics",
          title: "Robotics：Tripod 機器人與座標系運動",
          description:
            "從 Pick & Place 學會軸組、PCS/WCS 座標系與動態追蹤，再學 Jog、Trigger、中斷繼續與附加軸。",
          examples: [
            { id: "robotics-pick-and-place", title: "Pick & Place 機器人", projectName: "Robotics_PickAndPlace.project", category: "Robotics", order: 1, mdPath: "softmotion/Robotics_PickAndPlace/Robotics_PickAndPlace_整體架構與功能.md", summary: "Tripod + 旋轉桌 + 輸送帶取放料，PCS_1/PCS_2、MC_TrackRotaryTable、MC_TrackConveyorBelt。" },
            { id: "robotics-pick-and-place-without-depictor", title: "Pick & Place（無 Depictor）", projectName: "Robotics_PickAndPlace_without_Depictor.project", category: "Robotics", order: 2, mdPath: "softmotion/Robotics_PickAndPlace_without_Depictor/Robotics_PickAndPlace_without_Depictor_整體架構與功能.md", summary: "與 PickAndPlace 相同流程，不依賴 3D Depictor，簡化視覺化。" },
            { id: "robotics-jogging", title: "Jog 手動點動", projectName: "Robotics_Jogging.project", category: "Robotics", order: 3, mdPath: "softmotion/Robotics_Jogging/Robotics_Jogging_整體架構與功能.md", summary: "HMI 按鍵或方向鍵控制機器人點動，軟體限位與安全區域。" },
            { id: "robotics-triggers", title: "觸發（Triggers）", projectName: "Robotics_Triggers.project", category: "Robotics", order: 4, mdPath: "softmotion/Robotics_Triggers/Robotics_Triggers_整體架構與功能.md", summary: "路徑上設定 Trigger 點，於特定位置或時間觸發 I/O（拍照、吹氣、打標等）。" },
            { id: "robotics-triggers-advanced", title: "進階觸發（Triggers Advanced）", projectName: "Robotics_Triggers_Advanced.project", category: "Robotics", order: 5, mdPath: "softmotion/Robotics_Triggers_Advanced/Robotics_Triggers_Advanced_整體架構與功能.md", summary: "多條 Trigger、條件式觸發與較複雜的同步邏輯。" },
            { id: "robotics-interrupt-continue", title: "中斷與繼續", projectName: "Robotics_Interrupt_Continue.project", category: "Robotics", order: 6, mdPath: "softmotion/Robotics_Interrupt_Continue/Robotics_Interrupt_Continue_整體架構與功能.md", summary: "中斷後安全停止，再平滑回到路徑繼續運動，MC_Stop、MC_Halt、MC_Continue。" },
            { id: "robotics-additional-axes", title: "機器人附加軸", projectName: "Robotics_AdditionalAxes.project", category: "Robotics", order: 7, mdPath: "softmotion/Robotics_AdditionalAxes/Robotics_AdditionalAxes_整體架構與功能.md", summary: "在軸組外加入外掛軸（旋轉台、滑台），與主軸組協調。" },
            { id: "robotics-dynamic-model", title: "動態模型", projectName: "Robotics_DynamicModel.project", category: "Robotics", order: 8, mdPath: "softmotion/Robotics_DynamicModel/Robotics_DynamicModel_整體架構與功能.md", summary: "質量、慣量、負載對軌跡的影響，速度／加速度限制與補償。" },
          ],
        },
        {
          id: "kinematics",
          title: "機構學：自訂機構學實作",
          description:
            "自訂機構學介面與實作，將自訂機構學掛到 Axis Group 並實際驅動軸。",
          examples: [
            { id: "custom-kinematics-implementation", title: "自訂機構學實作", projectName: "CustomKinematics_Implementation.project", category: "Other", order: 1, mdPath: "softmotion/CustomKinematics_Implementation/CustomKinematics_Implementation_整體架構與功能.md", summary: "自訂機構學完整實作範例，正逆解、軸對應，掛到 Axis Group 並驅動。" },
          ],
        },
        {
          id: "cnc",
          title: "CNC：從 OutQueue 到 Online 解碼",
          description:
            "從最基本的 OutQueue + Interpolator 架構開始，到線上解碼、前處理、檔案、附加軸、探針與自訂 G-code。",
          examples: [
            { id: "cnc01-direct", title: "CNC Example 01：直接產生 OutQueue", projectName: "CNC01_direct.project", category: "CNC", order: 1, mdPath: "softmotion/CNC01_direct/CNC01_direct_整體架構與功能.md", summary: "兩軸 CNC 最基本架構，NC 直接編譯成 OutQueue，SMC_Interpolator 驅動軸。" },
            { id: "cnc02-online", title: "CNC Example 02：線上解碼與變數", projectName: "CNC02_online.project", category: "CNC", order: 2, mdPath: "softmotion/CNC02_online/CNC02_online_整體架構與功能.md", summary: "SMC_CNC_REF、SMC_NCDecoder，變數解碼，PathTask 與 IpoTask 分離。" },
            { id: "cnc03-prepro", title: "CNC Example 03：線上路徑前處理", projectName: "CNC03_prepro.project", category: "CNC", order: 3, mdPath: "softmotion/CNC03_prepro/CNC03_prepro_整體架構與功能.md", summary: "SMC_SmoothPath 等前處理，G51/G50，轉角平滑化。" },
            { id: "cnc04-table", title: "CNC 表格編輯", projectName: "CNC04_table.project", category: "CNC", order: 4, mdPath: "softmotion/CNC04_table/CNC04_table_整體架構與功能.md", summary: "CNC Table 編輯器建立與編輯路徑，表格與圖形編輯切換。" },
            { id: "cnc05-file", title: "CNC Example 05：由檔案產生 CNC", projectName: "CNC05_File.project", category: "CNC", order: 5, mdPath: "softmotion/CNC05_File/CNC05_File_整體架構與功能.md", summary: "SMC_ReadNCFile2、SMC_NCInterpreter，從檔案讀取 ASCII G-code 並執行。" },
            { id: "cnc06-file-3dpath", title: "檔案 + 3D 路徑視覺化", projectName: "CNC06_File_3DPath.project", category: "CNC", order: 6, mdPath: "softmotion/CNC06_File_3DPath/CNC06_File_3DPath_整體架構與功能.md", summary: "SMC_PathCopier、PositionTracker，Path3D 視覺化刀路與實際軌跡。" },
            { id: "cnc07-subprogram", title: "Subprogram 子程式", projectName: "CNC07_Subprogram.project", category: "CNC", order: 7, mdPath: "softmotion/CNC07_Subprogram/CNC07_Subprogram_整體架構與功能.md", summary: "獨立 .cnc 子程式、搜尋目錄、參數傳遞與巢狀呼叫。" },
            { id: "cnc08-additional-axes", title: "CNC Example 08：附加軸", projectName: "CNC08_AdditionalAxes.project", category: "CNC", order: 8, mdPath: "softmotion/CNC08_AdditionalAxes/CNC08_AdditionalAxes_整體架構與功能.md", summary: "G-code 中附加 A 軸，SMC_ControlAxisByPos 寫入附加軸，Gap 避免。" },
            { id: "cnc09-tool-length-corr", title: "CNC Example 09：刀長補正", projectName: "CNC09_ToolLengthCorr.project", category: "CNC", order: 9, mdPath: "softmotion/CNC09_ToolLengthCorr/CNC09_ToolLengthCorr_整體架構與功能.md", summary: "SMC_ToolLengthCorr、G43，插補器與座標轉換間的刀長補償。" },
            { id: "cnc10-dynamic-path", title: "CNC Example 10：動態 CNC 路徑", projectName: "CNC10_DynamicPath.project", category: "CNC", order: 10, mdPath: "softmotion/CNC10_DynamicPath/CNC10_DynamicPath_整體架構與功能.md", summary: "PLC 中組裝 SMC_OUTQUEUE/SMC_GEOINFO，SMC_CalcLengthGeo、SMC_AppendObj 動態產生路徑。" },
            { id: "cnc11-custom-functions", title: "自訂功能／自訂 G-code", projectName: "CNC11_CustomFunctions.project", category: "CNC", order: 11, mdPath: "softmotion/CNC11_CustomFunctions/CNC11_CustomFunctions_整體架構與功能.md", summary: "自訂 G/M code 掛入 CNC 流程，SMC_NC_GFunctionTable、SMC_NC_IFunction。" },
            { id: "cnc12-token-modifier", title: "ReadNCFile2 + Token Modifier", projectName: "CNC12_TokenModifier.project", category: "CNC", order: 12, mdPath: "softmotion/CNC12_TokenModifier/CNC12_TokenModifier_整體架構與功能.md", summary: "SMC_ITokenModifier 在讀檔時動態修改 Token（如 F 單位 mm/min 轉 mm/s）。" },
            { id: "cnc13-read-interpolator-state", title: "讀取插補器狀態", projectName: "CNC13_ReadInterpolatorState.project", category: "CNC", order: 13, mdPath: "softmotion/CNC13_ReadInterpolatorState/CNC13_ReadInterpolatorState_整體架構與功能.md", summary: "讀取目前物件、SetPosition、bEndOfPath，Block Search / Resume 基礎。" },
            { id: "cnc14-path-preprocessing", title: "PathPreprocessing 綜合範例", projectName: "CNC14_PathPreprocessing.project", category: "CNC", order: 14, mdPath: "softmotion/CNC14_PathPreprocessing/CNC14_PathPreprocessing_整體架構與功能.md", summary: "G51/G52、G40～G43、G60/G61、G70/G71，多個前處理 FB 串接。" },
            { id: "cnc15-large-gcode", title: "大型 G-code 程式", projectName: "CNC15_LargeGCode.project", category: "CNC", order: 15, mdPath: "softmotion/CNC15_LargeGCode/CNC15_LargeGCode_整體架構與功能.md", summary: "FILE 模式、分批讀取、串流式處理與緩衝策略。" },
            { id: "cnc16-g31", title: "G31 探針（清除剩餘距離）", projectName: "CNC16_G31.project", category: "CNC", order: 16, mdPath: "softmotion/CNC16_G31/CNC16_G31_整體架構與功能.md", summary: "探針觸發即停、SMC_SetInterpreterStartPosition、bAcknProbe，以實際停止點續跑。" },
            { id: "cnc17-read-gcode-from-strings", title: "從字串／串流讀取 G-code", projectName: "CNC17_ReadGCodeFromStrings.project", category: "CNC", order: 17, mdPath: "softmotion/CNC17_ReadGCodeFromStrings/CNC17_ReadGCodeFromStrings_整體架構與功能.md", summary: "SMC_ReadNCFromStream 從字串或串流讀取 G-code，與 Token Modifier 搭配。" },
          ],
        },
      ],
    },
  ],
};
