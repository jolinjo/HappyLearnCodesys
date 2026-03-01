(* 
    檔案用途：
      作為 Jogging 範例的主程式，負責：
      - 啟動六軸機器人與兩個附加軸（線性、旋轉）的軸組；
      - 呼叫 GroupJog2 依照 Forward / Backward 按鍵進行多軸 Jog；
      - 提供視覺化用的 Depictor 資料與 MCS/附加軸座標框架。
    教學重點：
      - 了解如何將 GroupJog2 這類 Jog 功能塊，整合到完整的 PLC_PRG 狀態機中。
      - 觀察 Depictor 相關資料結構（DepictorFrame 等）如何從實際軸位置推算出畫面姿態。
      - 練習從操作者介面（Forward/Backward 陣列）一路追到 AxisGroup 的運動行為。
*)
PROGRAM PLC_PRG
VAR_INPUT
    Forward : ARRAY[0..5] OF BOOL ;
    Backward : ARRAY[0..5] OF BOOL ;
    AdditionalAxesForward : ARRAY[0..SM3_Robotics.SMRB.MAX_ADD_AXES - 1] OF BOOL;
    AdditionalAxesBackward : ARRAY[0..SM3_Robotics.SMRB.MAX_ADD_AXES - 1] OF BOOL;

    iCoordSystem : UDINT := 1 ;
    ABC_as_ACS : BOOL := TRUE ;
    Velocity : LREAL := 50 ;
    Acceleration : LREAL := 500 ;
    Deceleration : LREAL := 500 ;
    Jerk : LREAL := 10000 ;
    VelFactor : LREAL := 0.2 ;
    AccFactor : LREAL := 0.2 ;
    JerkFactor : LREAL := 0.2 ;
    MaxLinearDistance : LREAL := 100 ;
    MaxAngularDistance : LREAL := 45 ;
    reset : BOOL ;

    MoveTo : BOOL ;
    posToMove_ACS : SMC_POS_REF ;
END_VAR
VAR_OUTPUT
    Error : BOOL ;
    CurrentPosition : SMC_POS_REF ;
    CurrentAdditionalAxesPositions : SMC_ADDITIONAL_AXES_VALUES_ARRAY;
    statusText : STRING(255) ;
    PosMCS : SMC_POS_REF ;
    MCS : DepictorFrame ;
    AddAxisLinearFrame : DepictorFrame ;
    AddAxisRotaryFrame : DepictorFrame ;
END_VAR
VAR
    pw : SMC_GroupPower ;
    en : MC_GroupEnable ;
    dep : SM3_Depictor.SMC_R_ArticBot_6DOF_Data;
    depFrameMCS_Translated : SM3_Depictor.DepictorFrame ;
    depFrameAngularVel : SM3_Depictor.DepictorFrame ;
    greset : MC_GroupReset ;
    grs : MC_GroupReadStatus ;
	gre : MC_GroupReadError ;
    grp : SMC_GroupReadSetPosition := (Enable:= TRUE, CoordSystem:= SMC_COORD_SYSTEM.MCS) ;
    gst : SMC_GroupSetTool ;
    gmcs : MC_SetCoordinateTransform := (
        CoordTransform:= (X:= 400, Y:= 100, Z:= 20, A:= 90, B:= 0, C:= 0),
        CoordSystem:= SMC_COORD_SYSTEM.MCS) ;

    AddAxis_Linear_InitPose : MC_COORD_REF := (X:= 400, Y:= 400, Z:= 20, A:= 0, B:= 0, C:= 0);
    AddAxis_Rotary_InitPose : MC_COORD_REF := (X:= 800, Y:= 100, Z:= 20, A:= 0, B:= 0, C:= 0);

    mda: MC_MoveDirectAbsolute := (CoordSystem:= SMC_COORD_SySTEM.ACS) ;

    state : UDINT ;

    readSetVel : SMC_GroupReadSetVelocity := (
        Enable:= TRUE,
        CoordSystem:= SMC_COORD_SYSTEM.MCS) ;

    RangVel : SMC_Matrix3 := SMC_MATRIX3_IDENTITY ;
END_VAR
VAR_TEMP
    cs : SMC_COORD_SYSTEM ;
    angVel : SMC_VECTOR3D ;
    angVelMag : LREAL ;
    dRoll_Rad : LREAL ;
    dPitch_Rad : LREAL ;
    dYaw_Rad : LREAL ;
END_VAR
VAR CONSTANT
    DEP_FRAME_IDENTIFY : DepictorFrame := (X:= 0, Y:= 0, Z:= 0, Yaw:= 0, Pitch:= 0, Roll:= 0) ;
END_VAR

CASE iCoordSystem OF
0:
    cs := SMC_COORD_SYSTEM.ACS ;

1:
    cs := SMC_COORD_SYSTEM.MCS ;

2:
    cs := SMC_COORD_SYSTEM.WCS ;

3:
    cs := SMC_COORD_SYSTEM.TCS ;

ELSE
    cs := SMC_COORD_SYSTEM.ACS ;
END_CASE

CASE state OF
0:
    pw.Enable := TRUE ;
    en.Execute := TRUE ;
    grs.Enable := TRUE ;
	gre.Enable := TRUE ;

    IF pw.Status AND en.Done THEN
        gst.ToolOffset.X := 20 ;
        gst.ToolOffset.Y := 15 ;
        gst.ToolOffset.Z := 45 ;
        gst.ToolOffset.A := 0 ;
        gst.ToolOffset.B := 20 ;
        gst.ToolOffset.C := 0 ;
        gst.Execute := TRUE ;
        state := 5 ;
	END_IF

5:
    IF gst.Done THEN
        gmcs.Execute := TRUE ;
        state := state + 1 ;
	END_IF

6:
    IF gmcs.Done THEN
        state := state + 4 ;
	END_IF

10:
    GroupJog2.Enable := TRUE ;

    state := state + 10 ;

20:
    IF GroupJog2.Error THEN
        statusText :=
            CONCAT('GroupJog2 error: ',
            CONCAT(TO_STRING(GroupJog2.ErrorID),
            CONCAT(' ',
                   SMC_ErrorString(
                        GroupJog2.ErrorID,
                        SMC_Language_Type.english)))) ;

        state := 1000 ;
    ELSIF MoveTo THEN
        MoveTo := FALSE ;
        mda.POsition := posToMove_ACS ;
        state := 60 ;
        GroupJog2.Enable := FALSE ;
	END_IF

60:
    IF NOT GroupJog2.Active THEN
        mda.Execute := TRUE ;
        state := state + 10 ;
	END_IF

70:
    IF mda.Done THEN
        mda.Execute := FALSE ;
        state := 10 ;
    ELSIF mda.Error OR mda.CommandAborted THEN
        mda.Execute := FALSE ;
        statusText := 'Error during movement' ;
        state := 1000 ;
	END_IF

900:
    greset.Execute := TRUE ;
    IF greset.Done THEN
        GroupJog2.Enable := FALSE ;
        state := 10 ;
	END_IF

1000:
    IF reset AND grs.GroupErrorStop THEN
        greset.Execute := FALSE ;
        state := 900 ;
        reset := FALSE ;
    ELSIF reset THEN
        GroupJog2.Enable := FALSE ;
        state := 10 ;
	END_IF
END_CASE

IF state >= 10 AND state < 900 AND grs.GroupErrorStop THEN
	IF gre.Valid AND gre.GroupErrorID <> SMC_NO_ERROR THEN
    	statusText :=
        	CONCAT('AxisGroup error: ',
            	   SMC_ErrorString(gre.GroupErrorID, SMC_LANGUAGE_TYPE.english)) ;
	ELSE
		statusText := 'AxisGroup in state GroupErrorStop' ;
	END_IF
    state := 1000 ;
END_IF

pw(AxisGroup:= Robi,
   bRegulatorOn:= TRUE,
   bDriveStart:= TRUE) ;

en(AxisGroup:= Robi) ;

greset(AxisGroup:= Robi) ;
grs(AxisGroup:= Robi) ;
gre(AxisGroup:= Robi) ;
grp(AxisGroup:= Robi, Position=> PosMCS) ;
gst(AxisGroup:= Robi) ;
gmcs(AxisGroup:= Robi) ;
mda(AxisGroup:= Robi) ;

GroupJog2(
    AxisGroup:= Robi,
    Forward:= Forward,
    Backward:= Backward,
    AdditionalAxesForward:= AdditionalAxesForward,
    AdditionalAxesBackward:= AdditionalAxesBackward,
    cs:= cs,
    ABC_as_ACS:= ABC_as_ACS,
    MaxLinearDistance:= MaxLinearDistance,
    MaxAngularDistance:= MaxAngularDistance,
    Velocity:= Velocity,
    Acceleration:= Acceleration,
    Deceleration:= Deceleration,
    Jerk:= Jerk,
    VelFactor:= VelFactor,
    AccFactor:= AccFactor,
    JerkFactor:= JerkFactor) ;

CurrentPosition := GroupJog2.CurrentPosition ;
CurrentAdditionalAxesPositions := Groupjog2.CurrentAdditionalAxesPositions;

dep(AxisGroup:= Robi, trf:= Robi.trafo) ;

depFrameMCS_Translated.X := dep.frame.X ;
depFrameMCS_Translated.Y := dep.frame.Y ;
depFrameMCS_Translated.Z := dep.frame.Z ;
depFrameMCS_Translated.Yaw := 0 ;
depFrameMCS_Translated.Pitch := 0 ;
depFrameMCS_Translated.Roll := 0 ;

readSetVel(AxisGroup:= Robi) ;

IF readSetVel.Valid THEN
    SMC_V3_Set(angVel, readSetVel.Velocity.c.A, readSetVel.Velocity.c.B, readSetVel.Velocity.c.C) ;
ELSE
    SMC_V3_Zero(angVel) ;
END_IF

angVelMag := SMC_V3_NormE(angVel) ;
IF angVelMag > 1e-4 THEN
    SMC_V3_Mult(angVel, angVel, 1/angVelMag) ;
    SMC_CretaeRCSFromZAxis(RangVel, angVel) ;

    SMC_Matrix3_ToYawPitchRoll(RangVel,
        dRoll_rad=> dRoll_rad,
        dPitch_rad=> dPitch_rad,
        dYaw_rad=> dYaw_rad) ;

    depFrameAngularVel.Yaw   := dYaw_Rad * SMC_FACTOR_RAD_TO_DEG ;
    depFrameAngularVel.Pitch := dPitch_Rad * SMC_FACTOR_RAD_TO_DEG ;
    depFrameAngularVel.Roll  := dRoll_Rad * SMC_FACTOR_RAD_TO_DEG ;
END_IF

depFrameAngularVel.X := dep.frame.X ;
depFrameAngularVel.Y := dep.frame.Y ;
depFrameAngularVel.Z := dep.frame.Z ;

SM3_Depictor.COORD_REF_2_DepictorFrame(MCS, gmcs.CoordTransform) ;
SM3_Depictor.COORD_REF_2_DepictorFrame(AddAxisLinearFrame, AddAxis_Linear_InitPose) ;
SM3_Depictor.COORD_REF_2_DepictorFrame(AddAxisRotaryFrame, AddAxis_Rotary_InitPose) ;

IF state < 1000 THEN
    statusText := 'Running' ;
END_IF

Error := state >= 1000 ;
