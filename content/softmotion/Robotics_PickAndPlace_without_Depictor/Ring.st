(* 
    檔案用途：
      以狀態機方式描述單一圓環（Ring）從轉盤待命、被機器人取走、
      一直到被放到圓錐上、再回到初始狀態的整個流程。
    教學重點：
      - 使用 MC_TrackRotaryTable 取得轉盤上物件的即時位置，並映射到 PCS_1。
      - 觀察如何根據 Robot 的輸出旗標（bReadyForMotion、bRingAttached、pTargetCone）
        來協調「轉盤上兩個圓環」與「機器人」之間的合作。
      - 練習閱讀以 DINT state 切分的多段狀態（0/10/20/30/40/50），對照實際動作想像流程。
*)
FUNCTION_BLOCK Ring
VAR_INPUT
	pOtherRing : POINTER TO Ring;
	startPos : MC_COORD_REF;
END_VAR
VAR_OUTPUT
	pos : MC_COORD_REF;
	state : DINT;
	bOnTable : BOOL;
END_VAR
VAR
	stateOld : DINT;
	fTemp : LREAL;
	f : SMC_Frame;
	rotaryTableOrigin : MC_COORD_REF := (X := gcTableTransX, Y := gcTableTransY, Z := gcTableTransZ);
	initialObjectPosition : MC_COORD_REF := (Y := 400, Z := 20 + 10);
	trt : MC_TrackRotaryTable := (RotaryTableOrigin := rotaryTableOrigin, initialObjectPosition := initialObjectPosition, CoordSystem := SMC_COORD_SYSTEM.PCS_1);
	pCone : POINTER TO Cone;
END_VAR

REPEAT
	stateOld := state;
	CASE state OF
	0:	//ring at original position
		pos := startPos;
		IF Robot.bReadyForMotion AND
		   (pOtherRing^.state = 0 OR pOtherRing^.state >= 40) AND
		   (gbSetRing OR gbAutomatic) THEN
			trt(Execute := FALSE, AxisGroup := Tripod, RotaryTable := DriveRotaryTable);
			trt.Execute := TRUE;
			state := state + 10;
		END_IF

	10:	//linking PCS_1 to the position of the ring
		IF trt.Done THEN
			state := state + 10;
		END_IF

	20:	//ring on rotary-table, wait until robot is free
		trt.cs.GetPose(cs := f, fTime := Tripod1.fTaskCycle);
		SMC_Frame_To_CoordRef(c := pos, f := f);
		IF NOT Robot.bRingAttached THEN
			state := state + 10;
		END_IF

	30: //waiting for takeoff
		trt.cs.GetPose(cs := f, fTime := Tripod1.fTaskCycle);
		SMC_Frame_To_CoordRef(c := pos, f := f);
		IF Robot.bRingAttached THEN
			state := state + 10;
		END_IF

	40:	//ring attached to robot
		pos.X := Robot.readPos.Position.c.X;
		pos.Y := Robot.readPos.Position.c.Y;
		pos.Z := Robot.readPos.Position.c.Z - gcTCP_Ring;
		IF NOT Robot.bRingAttached THEN
			pCone := Robot.pTargetCone;
			state := state + 10;
		END_IF

	50:	//ring placed on cone
		pos.X := pCone^.pos.X;
		pos.Y := pCone^.pos.Y;
		pos.Z := pCone^.pos.Z;
		IF NOT pCone^.bOnBelt THEN
			state := 0;
		END_IF
	END_CASE

	trt(AxisGroup := Tripod, RotaryTable := DriveRotaryTable);
UNTIL state = stateOld
END_REPEAT

bOnTable := state = 20 OR state = 30;