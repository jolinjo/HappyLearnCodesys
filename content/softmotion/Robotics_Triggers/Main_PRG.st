(* 
    檔案用途：
      示範如何在二維軸組上指令一段直線運動，並透過 SoftMotion 的觸發機制
      （SMC_GroupPrepareTrigger + SMC_GroupReadTrigger）在路徑中某一相對位置執行動作。
    教學重點：
      - 觀察「準備 Trigger → 指令移動 → 讀取 Trigger 狀態」的完整流程。
      - 練習使用 triggerTime 判斷觸發點是否會在本次週期內被通過，並做出反應。
      - 理解 MainTask 與 Planning_PRG（SMC_TuneCPKernel）之間的合作關係。
*)
PROGRAM Main_PRG
VAR
    power : SMC_GroupPower := (Enable:= TRUE, bRegulatorOn:= TRUE, bDriveStart:= TRUE);
    enable : MC_GroupEnable;

	prepTrigger : SMC_GroupPrepareTrigger := (Position:= (MvtPosition:= 0.6));
    moveLinear : MC_MoveLinearAbsolute := (
        Position:= (c:= (X:= 20, Y:= 10)),
        Velocity:= 30,
        Acceleration:= 1000,
        Deceleration:= 1000,
        Jerk:= 10000,
        CoordSystem:= SMC_COORD_SYSTEM.MCS);
    readTrigger : SMC_GroupReadTrigger;
    readPosMCS : MC_GroupReadActualPosition := (
        CoordSystem:= SMC_COORD_SYSTEM.MCS);

    state : INT;
END_VAR
VAR_OUTPUT
    triggerFired : BOOL;
END_VAR
VAR CONSTANT
    STATE_INIT : INT := 0;
    STATE_POWER_AND_ENABLE : INT := 10;
    STATE_COMMAND_MOVEMENT_WITH_TRIGGER : INT := 20;
    STATE_ENABLE_READ_TRIGGER : INT := 30;
    STATE_CHECK_TRIGGER : INT := 40;
    STATE_TRIGGER_FIRED : INT := 50;
END_VAR

// Read the position and trigger information at the start of
// each cycle, so that the values are up to date in the state
// machine.
readPosMCS(AxisGroup:= AxisGroup);
readTrigger(AxisGroup:= AxisGroup);

CASE state OF
STATE_INIT:
    // Wait until SMC_TuneCPKernel in the planning task is Done.
    IF Planning_PRG.initDone THEN
        state := STATE_POWER_AND_ENABLE;
	END_IF

STATE_POWER_AND_ENABLE:
    // Power on all axes and enable the axis group.
    power(AxisGroup:= AxisGroup);
    enable(AxisGroup:= AxisGroup, Execute:= power.Status);

    IF enable.Done THEN
        readPosMCS.Enable := TRUE;
        state := STATE_COMMAND_MOVEMENT_WITH_TRIGGER;
    END_IF

STATE_COMMAND_MOVEMENT_WITH_TRIGGER:
    // Prepare a trigger at a movement relative position of 0.6
    // (0.0 is the start of the movement, 1.0 the end of the movement).
    prepTrigger.PositionType := SMC_TriggerPositionType.MvtRelative;
    prepTrigger.Position.MvtPosition := 0.6;
    prepTrigger(AxisGroup:= AxisGroup, Execute:= TRUE);

    // Command a movement once the trigger has been successfully prepared.
    // The trigger will be attached to this movement.
    moveLinear(AxisGroup:= AxisGroup, Execute:= prepTrigger.Prepared);

    IF moveLinear.CommandAccepted THEN
        state := STATE_ENABLE_READ_TRIGGER;
	END_IF

STATE_ENABLE_READ_TRIGGER:
    // Start reading the trigger information using the TriggerId returned
    // by SMC_GroupPrepareTrigger.
    readTrigger.TriggerId := prepTrigger.TriggerId;
    readTrigger.Enable := TRUE;

    state := STATE_CHECK_TRIGGER;

STATE_CHECK_TRIGGER:
    // Check the trigger status. Once it is Active, the triggerTime is valid
    // and can be evaluated.
    IF readTrigger.TriggerInfo.status = SMC_TRIGGER_STATUS.Active THEN
        // If the triggerTime is smaller than the task cycle time (4ms),
        // the axis group will pass the trigger point in this cycle.
        IF readTrigger.TriggerInfo.triggerTime <= 0.004 THEN
            // React to the trigger.
            triggerFired := TRUE;
            state := STATE_TRIGGER_FIRED;
		END_IF
	END_IF

END_CASE

moveLinear(AxisGroup:= AxisGroup);