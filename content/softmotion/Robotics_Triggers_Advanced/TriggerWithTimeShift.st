(* 
    檔案用途：
      封裝 SoftMotion 觸發的「準備、監控與時間位移」邏輯，提供可重複使用的功能塊，
      讓使用者可以指定觸發位置型態與 TimeShift，並取得剩餘觸發時間與觸發狀態。
    教學重點：
      - 比較 STATE_PREPARE_TRIGGER、STATE_MONITOR_TRIGGER、STATE_DECREMENT_REMAINING_TRIGGER_TIME
        等狀態之間的關係，理解如何在每個匯流排週期持續更新 TriggerTime。
      - 注意 TimeShift 為正／負時，TriggerTime 的意義與判斷條件（<= BUS_CYCLE_TIME_IN_S）。
      - 了解 Aborted / Done / Error 等輸出旗標如何反映觸發在實際運行中的各種結束情況。
*)
FUNCTION_BLOCK TriggerWithTimeShift
VAR_IN_OUT
    AxisGroup : AXIS_GROUP_REF_SM3;
END_VAR
VAR_INPUT
    Execute : BOOL;
    PositionType : SMC_TriggerPositionType;
    Position : SMC_TriggerPosition;
    /// The time shift in seconds that the trigger should fire before (positive value)
    /// or after (negative value) the trigger position has been reached.
    /// Please note: Positive time shifts cannot always be met, see the documentation of
    /// ``TriggerTime`` for additional information.
    TimeShift : LREAL;
END_VAR
VAR_OUTPUT
    Busy : BOOL;
    /// The trigger got aborted, i.e. no movement was commanded in the cycle
    /// when the trigger was prepared.
    Aborted : BOOL;
    /// The Trigger is Done in the cycle after the trigger has been reached
    /// or if the movement that the trigger was assigned to got aborted (i.e.
    /// the trigger will never be reached).
    Done : BOOL;
    Error : BOOL;
    ErrorID : SMC_ERROR;
    /// The trigger has been successfully prepared and will be attached to the next
    /// commanded movement.
    TriggerPrepared : BOOL;
    /// The trigger time becomes valid, when the trigger position is part of the known
    /// trajectory.
    TriggerTimeValid : BOOL;
    /// The time in seconds until the trigger position including time shift is reached.
    /// The time is based on the start of the bus task cycle.
    /// Only valid if ``TriggerTimeValid`` is set.
    /// Can be negative, if the time until the trigger position is reached is smaller
    /// than the defined positive time shift. For example, the trigger position is 50 ms
    /// away from the start of the movement, but a positive time shift of 150 ms was
    /// defined. Since the start of the movement does not get delayed, the trigger
    /// will get noticed 100 ms too late.
    TriggerTime : LREAL;
    /// The trigger position including time shift is reached this cycle.
    TriggerReachedThisCycle : BOOL;
END_VAR
VAR
    m_state : INT;

    m_prepareTrigger : SMC_GroupPrepareTrigger;
    m_readTrigger : SMC_GroupReadTrigger;

    m_oldExecute : BOOL;
END_VAR
VAR_TEMP
    triggerTimeWithoutTimeShift : LREAL;
END_VAR
VAR CONSTANT
    STATE_IDLE : INT := 0;
    STATE_PREPARE_TRIGGER : INT := 10;
    STATE_MONITOR_TRIGGER : INT := 20;
    STATE_DECREMENT_REMAINING_TRIGGER_TIME : INT := 30;
    STATE_TRIGGER_FIRED : INT := 100;
    STATE_DONE : INT := 500;
    STATE_ABORTED : INT := 600;
    STATE_ERROR : INT := 1000;
END_VAR

IF Execute AND NOT m_oldExecute THEN
    m_prepareTrigger(
        AxisGroup:= AxisGroup,
        Execute:= FALSE);
    m_readTrigger(
        AxisGroup:= AxisGroup,
        Enable:= FALSE);

    m_state := STATE_PREPARE_TRIGGER;
ELSIF NOT Execute AND (Done OR Error OR Aborted) THEN
    m_state := STATE_IDLE;
    ErrorID := SMC_NO_ERROR;
END_IF

CASE m_state OF
STATE_PREPARE_TRIGGER:
    m_prepareTrigger(
        AxisGroup:= AxisGroup,
        Execute:= TRUE,
        PositionType:= PositionType,
        Position:= Position);

    IF m_prepareTrigger.Done THEN
        m_state := STATE_MONITOR_TRIGGER;
    ELSIF m_prepareTrigger.Error THEN
        m_state := STATE_ERROR;
        ErrorID := m_prepareTrigger.ErrorID;
    ELSIF m_prepareTrigger.CommandAborted THEN
        m_state := STATE_ABORTED;
    END_IF

STATE_MONITOR_TRIGGER:
    m_readTrigger(
        AxisGroup:= AxisGroup,
        Enable:= TRUE,
        TriggerId:= m_prepareTrigger.TriggerId);

    IF m_readTrigger.TriggerInfo.status = SMC_TRIGGER_STATUS.Active THEN
        triggerTimeWithoutTimeShift := m_readTrigger.TriggerInfo.triggerTime;
        TriggerTime := triggerTimeWithoutTimeShift - TimeShift;

        IF TriggerTime <= GVL.BUS_CYCLE_TIME_IN_S THEN
            m_state := STATE_TRIGGER_FIRED;
        ELSIF triggerTimeWithoutTimeShift <= GVL.BUS_CYCLE_TIME_IN_S THEN
            m_state := STATE_DECREMENT_REMAINING_TRIGGER_TIME;
        END_IF
    ELSIF m_readTrigger.TriggerInfo.status = SMC_TRIGGER_STATUS.Error THEN
        m_state := STATE_ERROR;
        ErrorID := m_readTrigger.TriggerInfo.errorId;
    ELSIF m_readTrigger.TriggerInfo.status <> SMC_TRIGGER_STATUS.Enabled THEN
        /// The movement that the trigger was assigned to got aborted.
        /// The trigger will never be reached. Switch to Done.
        m_state := STATE_DONE;
    END_IF

STATE_DECREMENT_REMAINING_TRIGGER_TIME:
    TriggerTime := TriggerTime - GVL.BUS_CYCLE_TIME_IN_S;
    IF TriggerTime <= GVL.BUS_CYCLE_TIME_IN_S THEN
        m_state := STATE_TRIGGER_FIRED;
    END_IF

STATE_TRIGGER_FIRED:
    m_state := STATE_DONE;
    TriggerTime := 0;
END_CASE

Busy := m_state > STATE_IDLE AND m_state < STATE_DONE;
TriggerPrepared := m_prepareTrigger.Prepared AND m_state > STATE_IDLE;
TriggerTimeValid :=
    m_state = STATE_MONITOR_TRIGGER AND m_readTrigger.TriggerInfo.status = SMC_TRIGGER_STATUS.Active
    OR m_state = STATE_DECREMENT_REMAINING_TRIGGER_TIME
    OR m_state = STATE_TRIGGER_FIRED;
TriggerReachedThisCycle := m_state = STATE_TRIGGER_FIRED;
Aborted := m_state = STATE_ABORTED;
Done := m_state = STATE_DONE;
Error := m_state = STATE_ERROR;

m_oldExecute := Execute;