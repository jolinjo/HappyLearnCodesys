(*
    檔案用途：
      以狀態機方式描述單一圓錐（Cone）在輸送帶上的一生：
      何時出現、如何被輸送帶帶動、何時離開工作區域，以及如何更新 PCS_2。
    教學重點：
      - 透過 MC_TrackConveyorBelt 追蹤輸送帶上的物件位置，並與 Tripod 軸組連動。
      - 觀察 REPEAT / UNTIL 與 state / stateOld 的組合，如何實作「直到狀態穩定」的迴圈。
      - 理解 pActiveCone 與 pPreviousCone 指標，如何在三顆圓錐之間接續產生與移動。
*)
FUNCTION_BLOCK Cone
VAR_IN_OUT
	pActiveCone : POINTER TO Cone;
END_VAR
VAR_INPUT
	pPreviousCone : POINTER TO Cone;
END_VAR
VAR_OUTPUT
	pos : MC_COORD_REF;
	state : DINT;
	bOnBelt : BOOL;
END_VAR
VAR
	conveyorBeltOrigin : MC_COORD_REF := (X := gcBeltTransX, Y := gcBeltTransY, Z := gcBeltTransZ);
	initialConePosition : MC_COORD_REF := (X := -925, Z := 125);
	tcb : MC_TrackConveyorBelt := (ConveyorBeltOrigin := conveyorBeltOrigin,
								   InitialObjectPosition := initialConePosition,
								   CoordSystem := SMC_COORD_SYSTEM.PCS_2);
	f : SMC_Frame;
	stateOld : DINT;
END_VAR

REPEAT
	stateOld := state;
	CASE state OF
	0:	//cone invisible
		IF NOT Robot.bDontChangePCS_2 THEN
			IF pPreviousCone^.bOnBelt AND pPreviousCone^.pos.X >= -250 THEN
				tcb(Execute := FALSE, AxisGroup := Tripod, ConveyorBelt := DriveConveyorBelt);
				tcb.Execute := TRUE;
				state := state + 10;
			END_IF
		END_IF
	10:	//linking PCS_2 to the position of the cone
		IF tcb.Done THEN
			bOnBelt := TRUE;
			pActiveCone := THIS;
			state := state + 10;
		END_IF
	20:	//cone on belt
		tcb.cs.GetPose(cs := f, fTime := Tripod1.fTaskCycle);
		SMC_Frame_To_CoordRef(c := pos, f := f);
		IF pos.X >= gcBeltTransX + 725 THEN
			bOnBelt := FALSE;
			state := 0;
		END_IF
	END_CASE
	tcb(AxisGroup := Tripod, ConveyorBelt := DriveConveyorBelt);
UNTIL state = stateOld
END_REPEAT