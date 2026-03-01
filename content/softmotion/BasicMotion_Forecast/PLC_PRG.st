/// 此程式示範 SoftMotion 的「預測（Forecast）」功能：
/// - 先為軸啟用一段時間長度的 Forecast 視窗。
/// - 再發出一個絕對位置運動命令。
/// - 同時計算「若未來軸要到達某個目標位置，大約需要多久時間」，
///   並讀出該時刻的速度與加速度等設定值，方便做提前干涉或安全檢查。
PROGRAM PLC_PRG
VAR
	/// 控制整體流程的狀態機。
	state : UDINT;
    /// 儲存各階段發生的錯誤碼（來自 MC_/SMC_* 功能塊）。
    error : SMC_ERROR;

    /// 設定 Forecast 視窗長度的功能塊。
	setForecast : SMC_SetForecast;
    /// 啟用後可讀取 Forecast 中的預估資訊（本範例主要示範啟用，讀值由 readSetValues 搭配使用）。
	getForecast : SMC_GetForecast;

    /// Drive 軸的上電與驅動控制。
	mcp : MC_Power;
    /// Drive 軸的絕對位置運動命令。
	ma : MC_MoveAbsolute;

    /// 計算到達指定位置所需時間的功能塊。
	timeToPosition : SMC_GetTravelTime;
    /// 在給定時間偏移處讀出預估的 SetPosition／SetVelocity／SetAcceleration。
	readSetValues : SMC_ReadSetValues;
END_VAR
VAR CONSTANT
	/// 軸上電與伺服啟動階段。
	STATE_POWER_DRIVE : UDINT := 0;
	/// 設定 Forecast 視窗長度並啟用預測功能。
	STATE_SET_FORECAST : UDINT := 10;
	/// 發出實際移動命令並持續計算預估到達時間與預估 Set 值。
	STATE_MOVE_TO_POSITION : UDINT := 20;
	/// 任一階段出錯時進入錯誤狀態（基準值）。
	STATE_ERROR : UDINT := 1000;
END_VAR

/// 主狀態機：從軸上電、開啟 Forecast，到發出運動命令並計算預估時間。
CASE state OF
STATE_POWER_DRIVE:
	/// 啟動 Drive 軸的伺服與驅動。
	mcp.Enable := TRUE;
	mcp.bDriveStart := TRUE;
	mcp.bRegulatorOn := TRUE;

	IF mcp.Status THEN
		/// 軸已準備就緒，進入設定 Forecast 階段。
		state := STATE_SET_FORECAST;
	ELSIF mcp.Error THEN
		/// 若上電失敗，記錄錯誤碼並轉入錯誤狀態。
		error := mcp.ErrorID;
		state := state + STATE_ERROR;
	END_IF

STATE_SET_FORECAST:
	/// 啟動 Forecast 設定，指定預測時間範圍（例如 0.3 秒內的預測）。
	setForecast.Execute := TRUE;
	setForecast.ForecastDuration := 0.3;

	/// 啟用取得 Forecast 資訊的功能塊，之後可搭配 readSetValues 使用。
	getForecast.Enable := TRUE;

	IF setForecast.Done THEN
		/// 成功設定 Forecast 視窗後，開始發出實際移動命令。
		state := STATE_MOVE_TO_POSITION;
	ELSIF setForecast.Error THEN
		/// 若設定 Forecast 失敗，記錄錯誤碼並轉入錯誤狀態。
		error := setForecast.ErrorID;
		state := state + STATE_ERROR;
	END_IF

STATE_MOVE_TO_POSITION:
	/// 發出絕對位置移動命令，目標位置為 10 單位。
	ma.Execute := TRUE;
	ma.Position := 10;
	ma.Velocity := 20;
	ma.Acceleration := 200;
	ma.Deceleration := 200;
	ma.Jerk := 1000;

	/// 啟用 GetTravelTime，計算「從目前狀態到達位置 8」大約需要多久。
	timeToPosition.Enable := TRUE;
	timeToPosition.Position := 8;

	/// 若移動命令本身出錯，記錄錯誤碼並轉入錯誤狀態。
	IF ma.Error THEN
		error := ma.ErrorID;
		state := state + STATE_ERROR;
	END_IF
END_CASE

/// 將 Forecast 與移動相關功能塊實際連接到 Drive 軸。
setForecast(Axis:= Drive);
getForecast(Axis:= Drive);

mcp(Axis:= Drive);
ma(Axis:= Drive);

timeToPosition(Axis:= Drive);
/// 使用 timeToPosition 計算出的 Duration 當作 TimeOffset，
/// 讀出「預計在該時刻」的 SetPosition／SetVelocity／SetAcceleration。
readSetValues(
	Axis:= Drive,
	Enable:= timeToPosition.Valid,
	TimeOffset:= timeToPosition.Duration);
