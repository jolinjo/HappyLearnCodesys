(* 
    檔案用途：
      模擬一個「點膠＋UV 固化」的應用範例，控制二軸平面運動，同時配合多個觸發點
      來開關膠閥、UV 燈與膠料補充訊號。
    教學重點：
      - 了解如何將一連串線性運動切成多段（GLUE_POSITIONS），並在特定段落上掛載 TriggerWithTimeShift。
      - 觀察不同 PositionType（MvtRelative、MvtDistance、PlaneIntersection）與 TimeShift 正負值的用法。
      - 練習從狀態機 m_state 的角度閱讀「初始化 → 上電 → 多段運動＋觸發 → 監控觸發 → 結束」的流程。
*)
PROGRAM GlueApplication
VAR_OUTPUT
    EnableGlue : BOOL;
    EnableUVLamp : BOOL;
    RefillGlueStorage : BOOL;
END_VAR
VAR
    m_state : INT;
    m_groupPower : SMC_GroupPower;
    m_groupEnable : MC_GroupEnable;

    m_moveLinearAbsolutes : ARRAY[0..MOVEMENT_COUNT - 1] OF MC_MoveLinearAbsolute;

    m_enableGlueTrigger : TriggerWithTimeShift;
    m_disableGlueTrigger : TriggerWithTimeShift;
    m_refillGlueStorageTrigger : TriggerWithTimeShift;
    m_enableUVLampTrigger : TriggerWithTimeShift;
    m_disableUVLampTrigger : TriggerWithTimeShift;
END_VAR
VAR CONSTANT
    MOVEMENT_COUNT : UINT := 5;

    /// The delay in seconds between starting the glue tool and
    /// the first contact with the surface or the delay between
    /// stopping the glue tool and the stop of contact with the
    /// surface.
    GLUE_ON_OFF_DELAY : LREAL := 0.05;
    /// The delay in seconds when the UV-lamp should turn off
    /// after applying glue to the surface. Has to be negative
    /// for the trigger to fire after the position has been
    /// passed.
    UV_LAMP_OFF_DELAY : LREAL := -1.5;

    GLUE_POSITIONS : ARRAY[0..MOVEMENT_COUNT - 1] OF SMC_POS_REF :=
        [
            (c:= (X:= 10)),
            (c:= (X:= 10, Y:= 2)),
            (c:= (X:= 0, Y:= 2)),
            (c:= (X:= 0, Y:= 4)),
            (c:= (X:= 10, Y:= 4))
        ];

    STATE_INIT : INT := 0;
    STATE_POWER_AND_ENABLE : INT := 10;
    STATE_COMMAND_FIRST_MOVEMENT_WITH_TRIGGERS : INT := 20;
    STATE_COMMAND_SECOND_MOVEMENT : INT := 30;
    STATE_COMMAND_THIRD_MOVEMENT_WITH_TRIGGERS : INT := 40;
    STATE_COMMAND_FOURTH_MOVEMENT : INT := 50;
    STATE_COMMAND_FIFTH_MOVEMENT_WITH_TRIGGERS : INT := 60;
    STATE_MONITOR_MOVEMENTS_AND_TRIGGERS : INT := 70;
    STATE_DONE : INT := 500;
END_VAR

CASE m_state OF
STATE_INIT:
    IF Planning_PRG.initDone THEN
        InitializeMovementPOUs();
        m_state := STATE_POWER_AND_ENABLE;
    END_IF

STATE_POWER_AND_ENABLE:
    m_groupPower.Enable := TRUE;
    m_groupPower.bDriveStart := TRUE;
    m_groupPower.bRegulatorOn := TRUE;

    m_groupEnable.Execute := m_groupPower.Status;

    IF m_groupPower.Status AND m_groupEnable.Done THEN
        m_state := STATE_COMMAND_FIRST_MOVEMENT_WITH_TRIGGERS;
    END_IF

STATE_COMMAND_FIRST_MOVEMENT_WITH_TRIGGERS:
    m_enableGlueTrigger.Position.MvtPosition := 0.5;
    m_enableGlueTrigger.PositionType := SMC_TriggerPositionType.MvtRelative;
    m_enableGlueTrigger.TimeShift := GLUE_ON_OFF_DELAY;
    m_enableGlueTrigger(AxisGroup:= AxisGroup, Execute:= TRUE);

    m_enableUVLampTrigger.Position.MvtPosition := 0.5;
    m_enableUVLampTrigger.PositionType := SMC_TriggerPositionType.MvtRelative;
    m_enableUVLampTrigger(AxisGroup:= AxisGroup, Execute:= TRUE);

    m_moveLinearAbsolutes[0](
        AxisGroup:= AxisGroup,
        Execute:= m_enableGlueTrigger.TriggerPrepared AND m_enableUVLampTrigger.TriggerPrepared);

    IF m_moveLinearAbsolutes[0].CommandAccepted THEN
        m_state := STATE_COMMAND_SECOND_MOVEMENT;
    END_IF

STATE_COMMAND_SECOND_MOVEMENT:
    m_moveLinearAbsolutes[1](AxisGroup:= AxisGroup, Execute:= TRUE);

    IF m_moveLinearAbsolutes[1].CommandAccepted THEN
        m_state := STATE_COMMAND_THIRD_MOVEMENT_WITH_TRIGGERS;
    END_IF

STATE_COMMAND_THIRD_MOVEMENT_WITH_TRIGGERS:
    m_refillGlueStorageTrigger.Position.MvtPosition := 5;
    m_refillGlueStorageTrigger.PositionType := SMC_TriggerPositionType.MvtDistance;
    m_refillGlueStorageTrigger(AxisGroup:= AxisGroup, Execute:= TRUE);

    m_moveLinearAbsolutes[2](
        AxisGroup:= AxisGroup,
        Execute:= m_refillGlueStorageTrigger.TriggerPrepared);

    IF m_moveLinearAbsolutes[2].CommandAccepted THEN
        m_state := STATE_COMMAND_FOURTH_MOVEMENT;
    END_IF

STATE_COMMAND_FOURTH_MOVEMENT:
    m_moveLinearAbsolutes[3](AxisGroup:= AxisGroup, Execute:= TRUE);

    IF m_moveLinearAbsolutes[3].CommandAccepted THEN
        m_state := STATE_COMMAND_FIFTH_MOVEMENT_WITH_TRIGGERS;
    END_IF

STATE_COMMAND_FIFTH_MOVEMENT_WITH_TRIGGERS:
    m_disableGlueTrigger.Position.Plane.CoordSystem := SMC_COORD_SYSTEM.MCS;
    m_disableGlueTrigger.Position.Plane.Distance := 5;
    m_disableGlueTrigger.Position.Plane.NormalVector.dX := 1;
    m_disableGlueTrigger.PositionType := SMC_TriggerPositionType.PlaneIntersection;
    m_disableGlueTrigger.TimeShift := GLUE_ON_OFF_DELAY;
    m_disableGlueTrigger(AxisGroup:= AxisGroup, Execute:= TRUE);

    m_disableUVLampTrigger.Position := m_disableGlueTrigger.Position;
    m_disableUVLampTrigger.PositionType := SMC_TriggerPositionType.PlaneIntersection;
    m_disableUVLampTrigger.TimeShift := UV_LAMP_OFF_DELAY;
    m_disableUVLampTrigger(AxisGroup:= AxisGroup, Execute:= TRUE);

    m_moveLinearAbsolutes[4](
        AxisGroup:= AxisGroup,
        Execute:= m_disableGlueTrigger.TriggerPrepared AND m_disableUVLampTrigger.TriggerPrepared);

    IF m_moveLinearAbsolutes[4].CommandAccepted THEN
        m_state := STATE_MONITOR_MOVEMENTS_AND_TRIGGERS;
    END_IF

STATE_MONITOR_MOVEMENTS_AND_TRIGGERS:
    CallTriggers();
    EvaluateTriggers();

    IF m_moveLinearAbsolutes[MOVEMENT_COUNT - 1].Done
       AND NOT EnableGlue
       AND NOT EnableUVLamp
       AND NOT RefillGlueStorage
    THEN
        m_state := STATE_DONE;
    END_IF
END_CASE

m_groupPower(AxisGroup:= AxisGroup);
m_groupEnable(AxisGroup:= AxisGroup);
CallMovements();