(* 
    檔案用途：
      封裝多軸 Jog 功能的高階介面，讓使用者只需給定前進／後退按鍵陣列與
      Jog 參數（座標系、速度、加速度、Jerk 等），就能以群組方式手動點動機器人。
    教學重點：
      - 觀察如何在外層再包一層狀態機，管理 SMC_GroupJog2 的 Enable、參數變更、
        安全停止（MC_GroupHalt）與錯誤重置流程。
      - 理解 CoordSystem（cs）、ABC_as_ACS 等 Jog 設定，如何連動到底層 jog2 FB。
*)
PROGRAM GroupJog2
VAR_IN_OUT
    AxisGroup : AXIS_GROUP_REF_SM3 ;
END_VAR
VAR_INPUT
    Enable : BOOL ;
    Forward : ARRAY[0..5] OF BOOL ;
    Backward : ARRAY[0..5] OF BOOL ;
    AdditionalAxesForward : ARRAY[0..SM3_Robotics.SMRB.MAX_ADD_AXES - 1] OF BOOL;
    AdditionalAxesBackward : ARRAY[0..SM3_Robotics.SMRB.MAX_ADD_AXES - 1] OF BOOL;
    cs : SMC_COORD_SYSTEM := SMC_COORD_SYSTEM.MCS ;
    ABC_as_ACS : BOOL ;
    MaxLinearDistance : LREAL ;
    MaxAngularDistance : LREAL ;
    Velocity : LREAL ;
    Acceleration : LREAL ;
    Deceleration : LREAL ;
    Jerk : LREAL ;
    VelFactor : LREAL ;
    AccFactor : LREAL ;
    JerkFactor : LREAL ;
END_VAR
VAR_OUTPUT
    Active : BOOL ;
    Done : BOOL ;
    Error : BOOL ;
    ErrorID : SMC_ERROR ;
    CurrentPosition : SMC_POS_REF ;
    CurrentAdditionalAxesPositions : SMC_ADDITIONAL_AXES_VALUES_ARRAY;
END_VAR
VAR
	jog2 : SMC_GroupJog2 := ();

	gr : MC_GroupReset;

	halt : MC_GroupHalt := (Deceleration:= 1E4, Jerk:= 5E5) ;

	grap : MC_GroupReadActualPosition := (Enable := TRUE, CoordSystem := SM3_Robotics.SMC_COORD_SYSTEM.MCS);
    setConfig : SMC_SetKinConfiguration ;

    state : UDINT ;
    EnableOld : BOOL ;
END_VAR

IF Enable AND NOT EnableOld THEN
    jog2(AxisGroup:= AxisGroup, Enable:= FALSE);
    halt.Execute := FALSE ;
    setConfig(AxisGroup:= AxisGroup, Execute:= FALSE);
    ErrorID := SMC_NO_ERROR ;
    state := 10 ;
ELSIF NOT Enable AND EnableOld THEN
    halt(AxisGroup := AxisGroup, Execute:= FALSE) ;
    state := 50 ;
END_IF

CASE state OF
10:
    jog2.CoordSystem := cs ;
    jog2.ABC_as_ACS := ABC_as_ACS ;
    jog2.MaxLinearDistance := MaxLinearDistance ;
    jog2.MaxAngularDistance := MaxAngularDistance ;
    jog2.Velocity := Velocity ;
    jog2.Acceleration := Acceleration ;
    jog2.Deceleration := Deceleration ;
    jog2.Jerk := Jerk ;
    jog2.VelFactor := VelFactor ;
    jog2.AccFactor := AccFactor ;
    jog2.JerkFactor := JerkFactor ;
    jog2.Enable := TRUE ;

    IF grap.Valid THEN
        setConfig.ConfigData := grap.KinematicConfig ;
        setConfig.Execute := TRUE ;
        state := state + 10 ;
    END_IF

20:
    IF setConfig.Done THEN
        setConfig.Execute := FALSE ;
        state := state + 10 ;
    ELSIF setConfig.Error THEN
        setConfig.Execute := FALSE ;
        ErrorID := setConfig.ErrorID ;
        state := 1000 ;
	END_IF

30:
    IF jog2.Error THEN
        ErrorID := jog2.ErrorID ;
        state := 1000 ;
	ELSIF cs <> jog2.CoordSystem OR
          ABC_as_ACS <> jog2.ABC_as_ACS OR
          MaxLinearDistance <> jog2.MaxLinearDistance OR
          MaxAngularDistance <> jog2.MaxAngularDistance OR
          VelFactor <> jog2.VelFactor OR
          AccFactor <> jog2.AccFactor OR
          JerkFactor <> jog2.JerkFactor OR
          Velocity <> jog2.Velocity OR
          Acceleration <> jog2.Acceleration OR
          Deceleration <> jog2.Deceleration OR
          Jerk <> jog2.Jerk
    THEN
        jog2.Enable := FALSE ;
        state := 10 ;
    END_IF

50:
    jog2.Enable := FALSE ;
    halt.Execute := TRUE ;
    state := state + 10 ;

60:
    IF halt.Done THEN
        halt.Execute := FALSE ;
        state := 500 ;
	END_IF

END_CASE

jog2(
    AxisGroup := AxisGroup,
    Forward:= Forward,
    Backward:= Backward,
    AdditionalAxesForward:= AdditionalAxesForward,
    AdditionalAxesBackward:= AdditionalAxesBackward,
    CurrentPosition=> CurrentPosition,
    CurrentAdditionalAxesPositions=> CurrentAdditionalAxesPositions);

halt(AxisGroup:= AxisGroup);
grap(AxisGroup:= AxisGroup);
setConfig(AxisGroup:= AxisGroup);

Active := 0 < state AND state < 500 ;
Done := state = 500 ;
Error := state >= 1000 ;

EnableOld := Enable ;