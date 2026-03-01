/// 此程式示範多軸同步運動的組合：
/// - 以 Master 軸為基準，使用 MC_GearIn 建立 Master 與 Slave0 的齒輪關係。
/// - 再用 MC_Phasing 對 Slave0 與 Slave1 之間添加相位偏移。
/// - 最後透過 SMC_BacklashCompensation 將 Slave1 與 Drive 串起來並補償背隙。
/// - 由 Master 軸執行來回絕對位置運動，其餘三軸依照齒輪／相位／背隙補償同步跟隨。
PROGRAM PLC_PRG
VAR
    /// 控制四條軸（Drive / Master / Slave0 / Slave1）上電與驅動啟動的功能塊。
    pwDrive  : MC_Power := (bRegulatorOn:= TRUE, bDriveStart:= TRUE);
    pwMaster : MC_Power := (bRegulatorOn:= TRUE, bDriveStart:= TRUE);
    pwSlave0 : MC_Power := (bRegulatorOn:= TRUE, bDriveStart:= TRUE);
    pwSlave1 : MC_Power := (bRegulatorOn:= TRUE, bDriveStart:= TRUE);

    /// 建立 Master 與 Slave0 之間的齒輪關係（3:2），並設定加減速與 Jerk。
    gearing: MC_GearIn := (
         RatioNumerator:= 3,
         RatioDenominator:= 2,
         Acceleration:= 1000,
         Deceleration:= 1000,
         Jerk:= 20000,
         BufferMode:= MC_BUFFER_MODE.Aborting);

    /// 在 Slave0 與 Slave1 之間添加 30 度相位偏移，並設定相位變換時的速度與加減速。
    phasing : MC_Phasing := (
        PhaseShift:= 30,
        Velocity:= 100,
        Acceleration:= 1000,
        Deceleration:= 1000,
        Jerk:= 20000);

    /// 在 Slave1 與 Drive 之間加入背隙補償，補償量 5，並指定補償時的運動參數。
    backlash : SMC_BacklashCompensation := (
        fBacklash:= 5,
        fCompensationVel:= 10,
        fCompensationAcc:= 100,
        fCompensationDec:= 100,
        fCompensationJerk:= 2000);

    /// Master 軸用來回的絕對位置運動命令（0 ↔ 100）。
	moveAbsolute : MC_MoveAbsolute := (
        Velocity:= 50,
        Acceleration:= 500,
        Deceleration:= 500,
        Jerk:= 5000) ;

    /// 簡單的兩段狀態機：在 0 與 100 之間來回運動。
	state : UDINT;
END_VAR
VAR CONSTANT
	/// 軸上電並啟用齒輪、相位與背隙補償的階段。
	STATE_POWER : UDINT := 0;
	/// 命令 Master 軸移動到位置 100 的階段。
	STATE_COMMAND_POS0 : UDINT := 10;
    /// 命令 Master 軸回到位置 0 的階段。
	STATE_COMMAND_POS1 : UDINT := 20;
END_VAR

/// 狀態機：上電 → Master 到 100 → Master 回 0 → 重複往返。
CASE state OF
STATE_POWER:
    /// 啟動四條軸。
    pwDrive.Enable := TRUE;
    pwMaster.Enable := TRUE;
    pwSlave0.Enable := TRUE;
    pwSlave1.Enable := TRUE;

    /// 當四條軸都準備就緒後，啟用齒輪、相位與背隙補償，並進入第一個運動命令。
    IF pwDrive.Status AND pwMaster.Status AND pwSlave0.Status AND pwSlave1.Status
    THEN
        gearing.Execute := TRUE;
        phasing.Execute := TRUE;
        backlash.bExecute := TRUE;
        state := STATE_COMMAND_POS0;
    END_IF

STATE_COMMAND_POS0:
    /// 命令 Master 軸移動到位置 100。
    moveAbsolute.Execute := TRUE;
    moveAbsolute.Position := 100;

    /// 到達後停止命令，轉換到回程狀態。
    IF moveAbsolute.Done THEN
        moveAbsolute.Execute := FALSE;
        state := STATE_COMMAND_POS1;
    END_IF

STATE_COMMAND_POS1:
    /// 命令 Master 軸回到位置 0。
    moveAbsolute.Execute := TRUE;
    moveAbsolute.Position := 0;

    /// 回到 0 後再次切換到 100，形成持續往返的動作。
    IF moveAbsolute.Done THEN
        moveAbsolute.Execute := FALSE;
        state := STATE_COMMAND_POS0;
    END_IF
END_CASE

/// 將四個 Power 功能塊連接到對應軸。
pwDrive(Axis:= Drive);
pwMaster(Axis:= Master);
pwSlave0(Axis:= Slave0);
pwSlave1(Axis:= Slave1);

/// Master 軸執行來回絕對位置運動。
moveAbsolute(Axis:= Master);

/// 三個從層級的同步鏈：Master → Slave0（齒輪）→ Slave1（相位）→ Drive（背隙補償）。
gearing(Master:= Master, Slave:= Slave0);
phasing(Master:= Slave0, Slave:= Slave1);
backlash(Master:= Slave1, Slave:= Drive);