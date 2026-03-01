(* 
    檔案用途：
      示範如何在一段正在執行的軸組運動中「中斷、插入中間動作、再從中斷點繼續」，
      使用 MC_GroupInterrupt / MC_GroupContinue / SMC_GroupGetContinuePosition 等 FB。
    教學重點：
      - 看懂完整的狀態機：啟動 → 兩段線性運動 → 中斷 → 執行中間運動 → 回到中斷點 → 繼續原運動。
      - 理解 continueData（SMC_AXIS_GROUP_CONTINUE_DATA）如何在 Interrupt 與 Continue 之間傳遞。
      - 練習在有插補運動的情況下，安全地中斷並恢復軌跡。
*)
PROGRAM PLC_PRG
VAR_OUTPUT
    Error : BOOL ;
	Done : BOOL ;
	Position : SMC_POS_REF ;
END_VAR
VAR
    power : SMC_GroupPower := (bRegulatorOn:= TRUE, bDriveStart:= TRUE) ;
    enable : MC_GroupEnable ;

	readPos : SMC_GroupReadSetPosition :=
		(CoordSystem:= SMC_COORD_SYSTEM.MCS) ;

    moveLinearA: MC_MoveLinearAbsolute :=
		(Position:= (c:= (X:= 100, Y:= 90, Z:= 10)),
	     CoordSystem:= SMC_COORD_SYSTEM.MCS,
		 Velocity:= VEL,
	     Acceleration:= ACC,
		 Deceleration:= ACC,
	     Jerk:= JERK) ;

	moveLinearB: MC_MoveLinearAbsolute :=
		(Position:= (c:= (X:= 150, Y:= 10, Z:= -20)),
         CoordSystem:= SMC_COORD_SYSTEM.MCS,
		 Velocity:= VEL,
	     Acceleration:= ACC,
		 Deceleration:= ACC,
	     Jerk:= JERK,
		 BufferMode:= MC_BUFFER_MODE.BlendingHigh) ;

     startVelocityB : SMC_StartVelocity := (
        Factor:= 1,
        Axes:= SMC_StartVelocityAxes.KINEMATIC);

	interrupt : MC_GroupInterrupt ;
	cont : MC_GroupContinue ;
	getContinuePos : SMC_GroupGetContinuePosition ;
	data : SMC_AXIS_GROUP_CONTINUE_DATA ;

	movePTP : MC_MoveDirectRelative :=
		(Distance:= (c:= (X:= 0, Y:= 0, Z:= 55)),
		 CoordSystem:= SMC_COORD_SYSTEM.MCS);

	moveToContinuePos : MC_MoveLinearAbsolute :=
		(Velocity:= VEL,
		 Acceleration:= ACC,
		 Deceleration:= ACC,
		 Jerk:= Jerk) ;

    state : UDINT ;
END_VAR
VAR CONSTANT
	STATE_POWER_ON : UDINT := 0 ;
	STATE_START_MOVING : UDINT := 10 ;
	STATE_INTERRUPT : UDINT := 20 ;
	STATE_INTERMEDIATE_MOVEMENT : UDINT := 30 ;
	STATE_GET_CONTINUE_POS : UDINT := 40 ;
	STATE_MOVE_TO_CONTINUE_POS : UDINT := 50 ;
	STATE_CONTINUE : UDINT := 60 ;
	STATE_FINISH_MOVE : UDINT := 70 ;
	STATE_DONE : UDINT := 80 ;
	STATE_ERROR : UDINT := 1000 ;

	VEL : LREAL  := 50 ;
    ACC : LREAL  := 500 ;
    JERK : LREAL := 10000 ;
END_VAR

CASE state OF
STATE_POWER_ON:
    power.Enable := TRUE ;
    enable.Execute := TRUE ;

    IF power.Status AND enable.Done THEN
		moveLinearA.Execute := TRUE ;
		readPos.Enable := TRUE ;
        state := STATE_START_MOVING ;
	END_IF

STATE_START_MOVING:
    IF moveLinearA.CommandAccepted THEN
        moveLinearB.Execute := TRUE ;
	END_IF

	IF moveLinearB.Active THEN
		interrupt.Execute := TRUE ;
		state := STATE_INTERRUPT ;
	END_IF

STATE_INTERRUPT:
    IF interrupt.Done THEN
		movePTP.Execute := TRUE ;
        state := STATE_INTERMEDIATE_MOVEMENT ;
	END_IF

STATE_INTERMEDIATE_MOVEMENT:
	IF movePTP.Done THEN
		getContinuePos.Execute := TRUE ;
		state := STATE_GET_CONTINUE_POS ;
	END_IF

STATE_GET_CONTINUE_POS:
	IF getContinuePos.Done THEN
		moveToContinuePos.Position := getContinuePos.Position ;
		moveToContinuePos.CoordSystem := getContinuePos.CoordSystem ;
		moveToContinuePos.Execute := TRUE ;
		state := STATE_MOVE_TO_CONTINUE_POS ;
	END_IF

STATE_MOVE_TO_CONTINUE_POS:
	IF moveToContinuePos.Done THEN
		cont.Execute := TRUE ;
		state := STATE_CONTINUE ;
	END_IF

STATE_CONTINUE:
    IF cont.Done THEN
        state := STATE_FINISH_MOVE ;
	END_IF

STATE_FINISH_MOVE:
    IF moveLinearB.Done THEN
        state := STATE_DONE ;
	END_IF
END_CASE

power(AxisGroup:= AxisGroup) ;
enable(AxisGroup:= AxisGroup) ;
readPos(AxisGroup:= AxisGroup, Position=> Position) ;
moveLinearA(AxisGroup:= AxisGroup) ;
startVelocityB();

moveLinearB(
    AxisGroup:= AxisGroup,
    TransitionMode:= startVelocityB.TransitionMode,
    TransitionParameter:= startVelocityB.TransitionParameter) ;

interrupt(AxisGroup:= AxisGroup, continueData:= data) ;
cont(AxisGroup:= AxisGroup, continueData:= data) ;
getContinuePos(AxisGroup:= AxisGroup, continueData:= data) ;
movePTP(AxisGroup:= AxisGroup) ;
moveToContinuePos(AxisGroup:= AxisGroup) ;

IF moveLinearA.Error OR moveLinearB.Error OR interrupt.Error OR cont.Error OR
   getContinuePos.Error OR movePTP.Error OR moveToContinuePos.Error
THEN
	state := STATE_ERROR ;
END_IF

Error := state = STATE_ERROR ;
Done := state = STATE_DONE ;