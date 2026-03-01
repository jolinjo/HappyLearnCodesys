(* 
    檔案用途：
      控制 Tripod 三角機器人完成「從旋轉工作台拾取圓環，放置到輸送帶上圓錐」的
      完整 Pick & Place 循環，並回報目前是否可動作與是否已夾持圓環。
    教學重點：
      - 觀察如何使用多顆 MC_Power、MC_SetPosition、MC_MoveLinear* 等運動控制 FB
        來建立啟動流程與多段直線軌跡。
      - 搭配座標系（WCS、PCS_1、PCS_2）與位置常數，理解不同工位之間的轉換。
      - 透過整數變數 state 所構成的狀態機，練習閱讀與設計順序控制流程。
*)
PROGRAM Robot
VAR_OUTPUT
    bReadyForMotion : BOOL;
	bRingAttached : BOOL;
	bDontChangePCS_2 : BOOL;	//there are several commands using PCS_2, which shall not change in the meantime
	pTargetCone : POINTER TO Cone;
END_VAR
VAR
    pwA1 : MC_Power := (Enable:= TRUE, bRegulatorOn:= TRUE, bDriveStart:= TRUE);
    pwA2 : MC_Power := (Enable:= TRUE, bRegulatorOn:= TRUE, bDriveStart:= TRUE);
    pwA3 : MC_Power := (Enable:= TRUE, bRegulatorOn:= TRUE, bDriveStart:= TRUE);
    spA1, spA2, spA3 : MC_SetPosition;

	enable : MC_GroupEnable;
	setCoord : MC_SetCoordinateTransform;
    mcs : MC_COORD_REF;

    mvToRing : MC_MoveLinearAbsolute := (Velocity := VEL, Acceleration := ACC, Deceleration := ACC, Jerk := JRK, Name:= 'Move to ring');
	mvToRestPos : MC_MoveLinearAbsolute := (Velocity := VEL, Acceleration := ACC, Deceleration := ACC, Jerk := JRK, Name:= 'Move to rest position');
	mvAboveCone : MC_MoveLinearAbsolute := (Velocity := VEL, Acceleration := ACC, Deceleration := ACC, Jerk := JRK, Name:= 'Move above cone');
	mvUpFromRing : MC_MoveLinearRelative := (Velocity := VEL, Acceleration := ACC, Deceleration := ACC, Jerk := JRK, Name:= 'Move up from ring');

	mvDownToCone : MC_MoveLinearAbsolute := (Velocity := VEL, Acceleration := ACC, Deceleration := ACC, Jerk := JRK, Name:= 'Move down to cone');
	mvUpFromCone : MC_MoveLinearAbsolute := (Velocity := VEL, Acceleration := ACC, Deceleration := ACC, Jerk := JRK, Name:= 'Move up from cone');

    mvBack : MC_MoveLinearAbsolute := (Velocity := VEL, Acceleration := ACC, Deceleration := ACC, Jerk := JRK, Name:= 'Move back');

	readStatus : MC_GroupReadStatus;
    readPos : MC_GroupReadActualPosition;

	state : INT;
	ton : TON := (PT := T#200MS);
END_VAR
VAR CONSTANT
    VEL : LREAL :=   1000 ;
    ACC : LREAL :=  10000 ;
    JRK : LREAL := 100000 ;

    POS_ABOVE_RING_PCS_1 : SMC_POS_REF := (c:= (X:= 0, Y:= 0, Z:= gcTCP_Ring)) ;
    POS_ABOVE_CONE_PCS_2 : SMC_POS_REF := (c:= (X:= 0, Y:= 0, Z:= 200)) ;
    POS_ON_CONE_PCS_2 : SMC_POS_REF := (c:= (X:= 0, Y:= 0, Z:= gcTCP_Ring)) ;
    POS_REST_WCS : SMC_POS_REF := (c:= (X:= 0, Y:= 0, Z:= 300)) ;
END_VAR

pwA1(Axis:= Tripod1);
pwA2(Axis:= Tripod2);
pwA3(Axis:= Tripod3);

CASE state OF
0:
    IF pwA1.Status AND pwA2.Status AND pwA3.Status THEN
        state := state + 10;
	END_IF

10:	//starting at given axis-positions
    spA1(Axis:= Tripod1, Execute:= TRUE, Position:= gcTripod1PosOrig);
    spA2(Axis:= Tripod2, Execute:= TRUE, Position:= gcTripod2PosOrig);
    spA3(Axis:= Tripod3, Execute:= TRUE, Position:= gcTripod3PosOrig);

    IF spA1.Done AND spA2.Done AND spA3.Done THEN
		setCoord(AxisGroup := Tripod, Execute := FALSE);
        state := state + 10;
	END_IF

20:	//telling the robot its position in space
	mcs.X := gcTripodTransX;
	mcs.Y := gcTripodTransY;
	mcs.Z := gcTripodTransZ;
    setCoord(
	        AxisGroup := Tripod,
            Execute := TRUE,
            CoordTransform := mcs,
            CoordSystem := SMC_COORD_SYSTEM.MCS);

    IF setCoord.Done THEN
        state := state + 10;
	END_IF

30: //enabling the axis group
    enable(AxisGroup:= Tripod, Execute:= TRUE);
    IF enable.Done THEN
		state := state + 10;
    END_IF

40:
	IF Environment.bRingOnTable THEN
		//approaching a ring on the table
		mvToRing(AxisGroup:= Tripod, Execute := FALSE);
		mvToRing.Position := POS_ABOVE_RING_PCS_1 ;
		mvToRing.BufferMode := MC_BUFFER_MODE.BlendingHigh;
		mvToRing.TransitionMode := MC_TRANSITION_MODE.TMCornerDistance;
		mvToRing.TransitionParameter[0] := 500;
		mvToRing.CoordSystem := SMC_COORD_SYSTEM.PCS_1;
		mvToRing.Execute := TRUE;
    	state := state + 10;
	END_IF

50:
    IF mvToRing.Done THEN
		ton(IN := FALSE);
		state := state + 10;
	END_IF

60:
	ton(IN := TRUE);
	//waiting some time (following the ring)
	IF ton.Q THEN
		//moving upwards (still in PCS_1)
		mvUpFromRing(AxisGroup:= Tripod, Execute := FALSE);
		mvUpFromRing.Distance.c.Z := 150;
		mvUpFromRing.CoordSystem := SMC_COORD_SYSTEM.PCS_1;
		mvUpFromRing.BufferMode := MC_BUFFER_MODE.Buffered;
		mvUpFromRing.TransitionMode := MC_TRANSITION_MODE.TMNone;
		mvUpFromRing.Execute := TRUE;
		state := state + 10;
	END_IF

70:
	IF mvUpFromRing.CommandAccepted THEN
		//neutral position
		mvToRestPos(AxisGroup:= Tripod, Execute := FALSE);
		mvToRestPos.Position := POS_REST_WCS ;
		mvToRestPos.CoordSystem := SMC_COORD_SYSTEM.WCS;
		mvToRestPos.BufferMode := MC_BUFFER_MODE.BlendingHigh;
		mvToRestPos.TransitionMode := MC_TRANSITION_MODE.TMCornerDistance;
		mvToRestPos.TransitionParameter[0] := 500 ;
		mvToRestPos.Execute := TRUE;
		state := state + 10;
	END_IF

80:
	IF mvToRestPos.CommandAccepted THEN
		//moving to some position above the next cone
		pTargetCone := Environment.pActiveCone;
		mvAboveCone(AxisGroup:= Tripod, Execute := FALSE);
		mvAboveCone.Position := POS_ABOVE_CONE_PCS_2 ;
		mvAboveCone.CoordSystem := SMC_COORD_SYSTEM.PCS_2;
		mvAboveCone.BufferMode := MC_BUFFER_MODE.BlendingHigh;
		mvAboveCone.TransitionMode := MC_TRANSITION_MODE.TMCornerDistance;
        mvAboveCone.TransitionParameter[0] := 1000 ;
		mvAboveCone.Execute := TRUE;
		state := state + 10;
	END_IF

90:
	IF mvAboveCone.CommandAccepted THEN
		//approaching the cone
		mvDownToCone(AxisGroup:= Tripod, Execute := FALSE);
		mvDownToCone.Position := POS_ON_CONE_PCS_2 ;
		mvDownToCone.BufferMode := MC_BUFFER_MODE.BlendingHigh;
		mvDownToCone.TransitionMode := MC_TRANSITION_MODE.TMCornerDistance;
		mvDownToCone.CoordSystem := SMC_COORD_SYSTEM.PCS_2;
		mvDownToCone.TransitionParameter[0] := 500;
		mvDownToCone.Execute := TRUE;
		state := state + 10;
	END_IF

100:
	IF mvDownToCone.Done THEN
		//moving upwards (still following the belt)
		mvUpFromCone(AxisGroup:= Tripod, Execute := FALSE);
		mvUpFromCone.Position := POS_ABOVE_CONE_PCS_2 ;
		mvUpFromCone.BufferMode := MC_BUFFER_MODE.Buffered;
		mvUpFromCone.TransitionMode := MC_TRANSITION_MODE.TMNone;
		mvUpFromCone.CoordSystem := SMC_COORD_SYSTEM.PCS_2;
		mvUpFromCone.Execute := TRUE;
		state := state + 10;
	END_IF

110:
	IF mvUpFromCone.CommandAccepted THEN
		//moving back
		mvBack(AxisGroup:= Tripod, Execute := FALSE);
		mvBack.Position := POS_REST_WCS ;
		mvBack.CoordSystem := SMC_COORD_SYSTEM.WCS;
		mvBack.BufferMode := MC_BUFFER_MODE.BlendingHigh;
		mvBack.TransitionMode := MC_TRANSITION_MODE.TMCornerDistance;
		mvBack.TransitionParameter[0] := 500;
		mvBack.Execute := TRUE;
		state := state + 10;
	END_IF

120:
	IF mvBack.CommandAccepted THEN
		state := 40;
	END_IF

END_CASE

mvToRing(AxisGroup := Tripod);
mvUpFromRing(AxisGroup := Tripod);
mvToRestPos(AxisGroup := Tripod);
mvAboveCone(AxisGroup := Tripod);
mvDownToCone(AxisGroup := Tripod);
mvUpFromCone(AxisGroup := Tripod);
mvBack(AxisGroup := Tripod);

readStatus(AxisGroup := Tripod, Enable := TRUE);
readpos(AxisGroup:= Tripod, Enable:= TRUE, CoordSystem:= SMC_COORD_SYSTEM.WCS);

bReadyForMotion := NOT readStatus.GroupDisabled AND NOT readStatus.GroupErrorStop;
bRingAttached := state >= 70 AND state <= 100;
bDontChangePCS_2 := state >= 90 AND state <= 110;