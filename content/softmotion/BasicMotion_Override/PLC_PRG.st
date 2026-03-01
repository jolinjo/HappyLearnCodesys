/// 此程式示範如何使用 Override（速度覆寫）功能：
/// - 先以 50% 的速度因子啟動一段絕對位置運動。
/// - 當軸位置超過一個門檻（例如 > 5）時，再將 Override 調低為 25%，
///   讓同一個運動命令在途中「變慢」，而不需要重新下達新的運動命令。
PROGRAM PLC_PRG
VAR
	/// 控制 Drive 軸上電與啟動的功能塊。
	power : MC_Power;
	/// 設定軸的速度 Override 因子的功能塊。
	setOverride : MC_SetOverride;
	/// 讀取目前 Override 設定（例如 VelFactor）的功能塊。
	getOverride : SMC_GetOverride;
	/// 對 Drive 軸發出絕對位置運動命令的功能塊。
	moveAbsolute: MC_MoveAbsolute;
    /// 讀取 Drive 軸當前實際位置的功能塊。
    readPosition : MC_ReadActualPosition;

	/// 狀態機，負責切換「上電 → 發動運動 → 變更 Override → Idle」。
	state : UDINT;
END_VAR
VAR CONSTANT
	/// 軸上電與伺服啟動階段。
	STATE_POWER : UDINT := 0;
	/// 發出運動命令並設定初始 Override（0.5）階段。
	STATE_COMMAND_MOVEMENT : UDINT := 10;
    /// 監看位置並在門檻後變更 Override（降到 0.25）的階段。
	STATE_CHANGE_OVERRIDE : UDINT := 20;
	/// 完成變更後進入 Idle（不再修改命令）的狀態。
	STATE_IDLE : UDINT := 30;
END_VAR

/// 依照狀態機切換上電、運動與 Override 的變更時機。
CASE state OF
	STATE_POWER:
		/// 啟動 Drive 軸的電源與驅動。
		power.Enable := TRUE;
		power.bDriveStart := TRUE;
		power.bRegulatorOn := TRUE;

		/// 軸一旦準備就緒就進入下個階段。
		IF power.Status THEN
			state := STATE_COMMAND_MOVEMENT;
		END_IF

	STATE_COMMAND_MOVEMENT:
		/// 啟用 Override 功能，先將速度因子設為 0.5（50%）。
		setOverride.Enable := TRUE;
		setOverride.VelFactor := 0.5;

		/// 發出絕對位置運動命令，目標位置 10，速度 20，基本加減速度與 Jerk。
		moveAbsolute.Execute := TRUE;
		moveAbsolute.Position := 10;
		moveAbsolute.Velocity := 20;
		moveAbsolute.Acceleration := 100;
		moveAbsolute.Deceleration := 100;
		moveAbsolute.Jerk := 1000;

        /// 命令送出後，進入「等待條件再調整 Override」的狀態。
        state := STATE_CHANGE_OVERRIDE;

    STATE_CHANGE_OVERRIDE:
        /// 當讀到的位置有效，且實際位置已超過 5 時，把 Override 調低到 25%。
        IF readPosition.Valid AND readPosition.Position > 5 THEN
		    setOverride.VelFactor := 0.25;
		    state := STATE_IDLE;
        END_IF
END_CASE

/// 將所有功能塊實際連接到 Drive 軸。
power(Axis:= Drive);
setOverride(Axis:= Drive);
getOverride(Axis:= Drive, Enable:= TRUE);
moveAbsolute(Axis:= Drive);
readPosition(Axis:= Drive, Enable:= TRUE);