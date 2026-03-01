/// 此程式示範如何在執行期間「線上建立凸輪表」，並比較：
/// 1. 在本任務中直接用 CamBuilder 建立的 Online Table（CamOnline）。
/// 2. 由另一個任務 MultitaskCamBuilder 建立、透過 safeCam 共享的 OnlineMultitask Table（CamOnlineMultitask）。
/// 接著將這兩種來源的凸輪分別指派給不同從軸，與一個事先離線建立的 CamOffline 一起比較實際運動行為。
PROGRAM PLC_PRG
VAR
	/// 主狀態機，用來依序執行建立凸輪、觸發多工建立、讀回、多軸上電與運動。
	state : UDINT;
    /// 儲存各階段發生的錯誤碼（來自 CamBuilder、safeCam.GetCopy 或 MC_* 功能塊）。
    error : SMC_ERROR;

    /// 在 MainTask 中用來建立「線上」凸輪的建構器。
    camBuilder : SMCB.CamBuilder;

	/// 存放 MainTask 線上建立凸輪 Segments 的緩衝陣列。
	camSegments: ARRAY[0..MAX_NUM_OF_CAM_SEGMENTS-1] OF SMC_CAM_SEGMENT;
	/// 指向線上建立的凸輪（CamOnline）的參考。
	CamOnline: MC_CAM_REF;

    /// 用來記錄 safeCam 在啟動 Multitask 建立前的 CamId，以便偵測新凸輪是否寫入完成。
    camIdBeforeCreate : UDINT;
    /// 存放由 MultitaskCamBuilder 建立、經 safeCam 取得的凸輪 Segments。
    camSegmentsMultitask : ARRAY[0..MAX_NUM_OF_CAM_SEGMENTS-1] OF SMC_CAM_SEGMENT;
    /// 指向多工安全建立結果複製出來的凸輪（CamOnlineMultitask）。
    CamOnlineMultitask : MC_CAM_REF;

	/// 主軸與三個從軸的電源功能塊。
	mcpMaster, mcpSlaveOffline, mcpSlaveOnline, mcpSlaveOnlineMultitask : MC_Power;
	/// 控制主軸以固定速度運行的速度模式命令。
	mvMaster : MC_MoveVelocity;
	/// 三個從軸的 CamTableSelect，用於選擇 Offline／Online／OnlineMultitask 三種 Cam。
	ctsSlaveOffline, ctsSlaveOnline, ctsSlaveOnlineMultitask : MC_CamTableSelect;
	/// 三個從軸對應的 CamIn，將從軸導入凸輪運動。
	camInSlaveOffline, camInSlaveOnline, camInSlaveOnlineMultitask : MC_CamIn;
END_VAR
VAR CONSTANT
	/// 在 MainTask 中建立線上 CamOnline 的階段。
	STATE_CREATE_ONLINE_TABLE : UDINT := 0;
    /// 記錄 safeCam 目前 CamId 的階段，準備啟動多工建立。
    STATE_INIT_ONLINE_TABLE_MULTITASK : UDINT := 10;
    /// 觸發 MultitaskCamBuilder 開始建立凸輪。
    STATE_START_CREATE_ONLINE_TABLE_MULTITASK : UDINT := 20;
    /// 等待 Multitask 任務完成建立，並透過 safeCam 讀回 CamOnlineMultitask。
    STATE_READ_ONLINE_TABLE_MULTITASK : UDINT := 30;
	/// 四條軸上電、等待皆就緒。
	STATE_POWER_DRIVES : UDINT := 40;
	/// 對三個從軸選擇對應的 CamTable（Offline／Online／OnlineMultitask）。
	STATE_SELECT_TABLE : UDINT := 50;
	/// 啟動主軸運動與三個從軸的 CamIn，同步比較三種凸輪效果。
	STATE_MOVEMENT : UDINT := 60;

	/// 發生錯誤時跳往此基準，實際錯誤狀態為 STATE_ERROR + 原狀態值。
	STATE_ERROR : UDINT := 1000;

    /// 本範例同樣使用三段 Segments 建立凸輪，與其他 Cam 範例一致。
    MAX_NUM_OF_CAM_SEGMENTS : INT := 3;
END_VAR

/// 主狀態機：按步驟建立線上／多工凸輪並驅動軸運動。
CASE state OF
STATE_CREATE_ONLINE_TABLE:
	/// 在 MainTask 中建立一條線上凸輪，流程與 CamExportAndImport 範例相似。
	camBuilder.Init();

	camBuilder.Append(SMCB.Poly5(SMCB.BoundImplicit(), SMCB.BoundImplicit()));
    camBuilder.Append(SMCB.Line(SMCB.Bound(160, 140, 2), SMCB.Bound(200, 220, 2)));
    camBuilder.Append(SMCB.Poly5(SMCB.BoundImplicit(), SMCB.Bound(360, 360, 0, 0)));

	IF camBuilder.IsErrorPending(errorID=> error) THEN
        state := state + STATE_ERROR;
	ELSE
		/// 將 CamOnline 參考指向本任務中的 camSegments 緩衝。
		SMCB.InitCamRef(CamOnline, ADR(camSegments), XSIZEOF(camSegments));
		/// 寫入線上建立的凸輪資料。
		error := camBuilder.Write(CamOnline);

		IF error = SMC_NO_ERROR THEN
			/// 線上 Cam 建立成功，準備啟動多工建立。
			state := STATE_INIT_ONLINE_TABLE_MULTITASK;
		ELSE
       	 	state := state + STATE_ERROR;
		END_IF
    END_IF

STATE_INIT_ONLINE_TABLE_MULTITASK:
    /// 記錄 safeCam 當前的 CamId，之後只要 CamId 改變就代表多工建立完成。
    camIdBeforeCreate := GVL.safeCam.CamId;

    state := STATE_START_CREATE_ONLINE_TABLE_MULTITASK;

STATE_START_CREATE_ONLINE_TABLE_MULTITASK:
    /// 對 MultitaskCamBuilder 發出一次性建立命令，由 BuilderTask 建立第二份凸輪。
    MultitaskCamBuilder.BuildCam := TRUE;

    state := STATE_READ_ONLINE_TABLE_MULTITASK;

STATE_READ_ONLINE_TABLE_MULTITASK:
    /// 若多工建立程序本身回報錯誤，直接記錄錯誤碼並跳往錯誤狀態。
    IF MultitaskCamBuilder.Error THEN
        error := MultitaskCamBuilder.ErrorId;
        state := state + STATE_ERROR;
    /// 若偵測到 safeCam.CamId 與原本不同，表示新的凸輪已寫入成功。
    ELSIF GVL.safeCam.CamId <> camIdBeforeCreate THEN
        /// 透過 safeCam.GetCopy() 將多工建立好的凸輪複製到本任務的 CamOnlineMultitask 與對應陣列。
        error := GVL.safeCam.GetCopy(
            camRef:= CamOnlineMultitask,
            pCamSegments:= ADR(camSegmentsMultitask),
            arraySize:= XSIZEOF(camSegmentsMultitask));

        IF error = SMC_NO_ERROR THEN
			state := STATE_POWER_DRIVES;
		ELSE
       	 	state := state + STATE_ERROR;
		END_IF
    END_IF

STATE_POWER_DRIVES:
	/// 依序啟動主軸與三個從軸，等待全部就緒或任何一軸出錯。
	mcpMaster.bDriveStart := TRUE;
	mcpMaster.bRegulatorOn := TRUE;
	mcpMaster.Enable := TRUE;

	mcpSlaveOffline.bDriveStart := TRUE;
	mcpSlaveOffline.bRegulatorOn := TRUE;
	mcpSlaveOffline.Enable := TRUE;

	mcpSlaveOnline.bDriveStart := TRUE;
	mcpSlaveOnline.bRegulatorOn := TRUE;
	mcpSlaveOnline.Enable := TRUE;

    mcpSlaveOnlineMultitask.bDriveStart := TRUE;
	mcpSlaveOnlineMultitask.bRegulatorOn := TRUE;
	mcpSlaveOnlineMultitask.Enable := TRUE;

	IF mcpMaster.Status AND mcpSlaveOffline.Status AND mcpSlaveOnline.Status AND mcpSlaveOnlineMultitask.Status THEN
		state := STATE_SELECT_TABLE;
	ELSIF mcpMaster.Error THEN
		error := mcpMaster.ErrorID;
		state := state + STATE_ERROR;
	ELSIF mcpSlaveOffline.Error THEN
		error := mcpSlaveOffline.ErrorID;
		state := state + STATE_ERROR;
	ELSIF mcpSlaveOnline.Error THEN
		error := mcpSlaveOnline.ErrorID;
		state := state + STATE_ERROR;
    ELSIF mcpSlaveOnlineMultitask.Error THEN
        error := mcpSlaveOnlineMultitask.ErrorID;
		state := state + STATE_ERROR;
	END_IF

STATE_SELECT_TABLE:
	/// SlaveOffline 使用離線預先準備好的 CamOffline。
	ctsSlaveOffline.Periodic := TRUE;
	ctsSlaveOffline.SlaveAbsolute := TRUE;
	ctsSlaveOffline.MasterAbsolute := TRUE;
	ctsSlaveOffline.Execute := TRUE;

	/// SlaveOnline 使用本任務線上建立的 CamOnline。
	ctsSlaveOnline.Periodic := TRUE;
	ctsSlaveOnline.SlaveAbsolute := TRUE;
	ctsSlaveOnline.MasterAbsolute := TRUE;
	ctsSlaveOnline.Execute := TRUE;

    /// SlaveOnlineMultitask 使用由 Multitask 任務建立、經 safeCam 複製的 CamOnlineMultitask。
    ctsSlaveOnlineMultitask.Periodic := TRUE;
	ctsSlaveOnlineMultitask.SlaveAbsolute := TRUE;
	ctsSlaveOnlineMultitask.MasterAbsolute := TRUE;
	ctsSlaveOnlineMultitask.Execute := TRUE;

	IF ctsSlaveOffline.Done AND ctsSlaveOnline.Done AND ctsSlaveOnlineMultitask.Done THEN
		state := STATE_MOVEMENT;
	ELSIF ctsSlaveOffline.Error THEN
		error := ctsSlaveOffline.ErrorID;
		state := state + STATE_ERROR;
	ELSIF ctsSlaveOnline.Error THEN
		error := ctsSlaveOnline.ErrorID;
		state := state + STATE_ERROR;
    ELSIF ctsSlaveOnlineMultitask.Error THEN
		error := ctsSlaveOnlineMultitask.ErrorID;
		state := state + STATE_ERROR;
	END_IF

STATE_MOVEMENT:
	/// 啟動主軸以固定速度運轉。
	mvMaster.Execute := TRUE;
	mvMaster.Velocity := 25;
	mvMaster.Acceleration := 100;
	mvMaster.Deceleration := 100;
	mvMaster.Jerk := 1000;

	/// 將三個從軸同時導入各自的凸輪運動，方便在視覺化與 Trace 中比較三種 Cam 來源。
	camInSlaveOffline.Execute := TRUE;
	camInSlaveOnline.Execute := TRUE;
    camInSlaveOnlineMultitask.Execute := TRUE;

	IF mvMaster.Error THEN
		error := mvMaster.ErrorID;
		state := state + STATE_ERROR;
	ELSIF camInSlaveOffline.Error THEN
		error := camInSlaveOffline.ErrorID;
		state := state + STATE_ERROR;
	ELSIF camInSlaveOnline.Error THEN
		error := camInSlaveOnline.ErrorID;
		state := state + STATE_ERROR;
    ELSIF camInSlaveOnlineMultitask.Error THEN
		error := camInSlaveOnlineMultitask.ErrorID;
		state := state + STATE_ERROR;
	END_IF
END_CASE

/// 將電源功能塊實際連接到四個軸。
mcpMaster(Axis:= Master);
mcpSlaveOffline(Axis:= SlaveOffline);
mcpSlaveOnline(Axis:= SlaveOnline);
mcpSlaveOnlineMultitask(Axis:= SlaveOnlineMultitask);

/// 三個從軸各自選擇離線、線上與多工線上的凸輪表。
ctsSlaveOffline(
	Master:= Master,
	Slave:= SlaveOffline,
	CamTable:= CamOffline);

ctsSlaveOnline(
	Master:= Master,
	Slave:= SlaveOnline,
	CamTable:= CamOnline);

ctsSlaveOnlineMultitask(
	Master:= Master,
	Slave:= SlaveOnlineMultitask,
	CamTable:= CamOnlineMultitask);

/// 主軸速度模式運動。
mvMaster(Axis:= Master);

/// 三個從軸依照前一階段選好的 CamTableID 進入凸輪運動。
camInSlaveOffline(
	Master:= Master,
	Slave:= SlaveOffline,
	CamTableID:= ctsSlaveOffline.CamTableID);

camInSlaveOnline(
	Master:= Master,
	Slave:= SlaveOnline,
	CamTableID:= ctsSlaveOnline.CamTableID);

camInSlaveOnlineMultitask(
	Master:= Master,
	Slave:= SlaveOnlineMultitask,
	CamTableID:= ctsSlaveOnlineMultitask.CamTableID);