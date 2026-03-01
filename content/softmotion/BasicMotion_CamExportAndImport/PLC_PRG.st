/// 此程式示範如何在執行階段以程式方式建立一個凸輪（Cam），
/// 並將其匯出成檔案，再從檔案匯入回系統中，以驗證 cam 匯出／匯入流程。
/// 流程大致分為：
/// 1. 使用 SMCB.CamBuilder 拼出一條由多個 Segments 組成的凸輪曲線。
/// 2. 將凸輪資料寫入一個 MC_CAM_REF 緩衝區。
/// 3. 透過 SMC_WriteCAM 將凸輪存成檔案。
/// 4. 再用 SMC_ReadCAM 從檔案讀回凸輪，確認檔案格式與內容可正確載入。
PROGRAM PLC_PRG
VAR
	/// 控制流程用的狀態機，決定目前執行到哪一個步驟。
	state : UDINT;
    /// 儲存 CamBuilder 或相關函式塊回傳的錯誤碼。
    error : SMC_ERROR;

    /// 用來逐步建立凸輪曲線的建構器物件。
    camBuilder : SMCB.CamBuilder;
	/// 存放匯出用凸輪 Segments 的陣列緩衝區。
	camSegmentsExport: ARRAY[0..MAX_NUM_OF_CAM_SEGMENTS-1] OF SMC_CAM_SEGMENT;
	/// 指向凸輪資料的參考結構，供寫入與匯出功能塊使用。
	camRefExport: MC_CAM_REF;
    /// 將記憶體中的凸輪資料寫成檔案的功能塊。
    writeCam : SMC_WriteCAM;
    /// 從檔案讀回凸輪資料的功能塊。
    readCam : SMC_ReadCAM;
END_VAR
VAR_TEMP
    /// 可用來儲存匯出後取得的凸輪 ID（本範例暫未使用，預留擴充）。
    camId : UDINT;
END_VAR
VAR CONSTANT
	/// 建立凸輪的狀態：呼叫 CamBuilder 並組裝 Segments。
	STATE_CREATE_CAM : UDINT := 0;
    /// 將已建立好的凸輪匯出成 CAM 檔案。
    STATE_EXPORT_CAM : UDINT := 10;
    /// 從剛剛匯出的檔案開始讀回凸輪。
    STATE_START_IMPORT_CAM : UDINT := 20;
    /// 完成建立與匯出／匯入流程。
    STATE_DONE : UDINT := 500;
	/// 任一階段發生錯誤時進入此狀態。
	STATE_ERROR : UDINT := 1000;
    /// 本範例將凸輪切成三個 Segments 來示範。
    MAX_NUM_OF_CAM_SEGMENTS : INT := 3;
    /// 匯出時使用的凸輪檔名。
    EXPORT_CAM_FILE_NAME : STRING := 'exportedCam.cam';
END_VAR

/// 依照狀態機切換建立／匯出／匯入的步驟。
CASE state OF
STATE_CREATE_CAM:
	/// 初始化凸輪建構器，清除先前內容。
	camBuilder.Init();

	/// 依序加入三段凸輪 Segments：
	/// - 第一段：使用 Poly5，從隱含邊界開始（通常代表從目前位置平順銜接）。
	camBuilder.Append(SMCB.Poly5(SMCB.BoundImplicit(), SMCB.BoundImplicit()));
    /// - 第二段：一段線性運動，從 (160,140) 到 (200,220)，加速度限制 2。
    camBuilder.Append(SMCB.Line(SMCB.Bound(160, 140, 2), SMCB.Bound(200, 220, 2)));
    /// - 第三段：再次用 Poly5 平順接到 (360,360) 並在終點保持速度為 0。
    camBuilder.Append(SMCB.Poly5(SMCB.BoundImplicit(), SMCB.Bound(360, 360, 0, 0)));

	/// 檢查建構過程中是否已經累積錯誤。
	IF camBuilder.IsErrorPending(errorID=> error) THEN
        state := state + STATE_ERROR;
	ELSE
		/// 將 camRefExport 初始化為指向 camSegmentsExport 陣列。
		SMCB.InitCamRef(camRefExport, ADR(camSegmentsExport), XSIZEOF(camSegmentsExport));
		/// 將 camBuilder 目前的凸輪內容寫入 camRefExport。
		error := camBuilder.Write(camRefExport);

		/// 若無錯誤，進入匯出檔案的狀態；否則跳到錯誤狀態。
		IF error = SMC_NO_ERROR THEN
			state := STATE_EXPORT_CAM;
		ELSE
       	 	state := state + STATE_ERROR;
		END_IF
    END_IF

STATE_EXPORT_CAM:
    /// 呼叫寫入 CAM 檔案的功能塊，將記憶體中的凸輪匯出為檔案。
    writeCam(
        cam:= camRefExport,
        bExecute:= TRUE,
        sFileName:= EXPORT_CAM_FILE_NAME);

    /// 匯出成功則進入「開始匯入」狀態；若發生錯誤則進入錯誤狀態。
    IF writeCam.bDone THEN
        state := STATE_START_IMPORT_CAM;
    ELSIF writeCam.bError THEN
        state := state + STATE_ERROR;
    END_IF

STATE_START_IMPORT_CAM:
    /// 從剛剛匯出的檔案讀回凸輪，確認檔案格式正確且可重新載入。
    readCam(
        bExecute:= TRUE,
        sFileName:= EXPORT_CAM_FILE_NAME);

    IF readCam.bDone THEN
        /// 匯入成功即宣告整個流程完成。
        state := STATE_DONE;
    ELSIF readCam.bError THEN
        /// 任一錯誤都會讓狀態跳轉到錯誤處理路徑。
        state := state + STATE_ERROR;
    END_IF
END_CASE