/// This function block shows how to use the output Events from
/// SMC_DigitalCamSwitch_HighPrecision to program a Beckhoff EL2252
/// digital output card.
///
/// The function block assumes that the PDO configuration of the
/// EL2252 contains the outputs to control the two channels
/// and the Feedback input.
/// The PDO values should get mapped to the ``In`` and ``Out``
/// variables of this function block (see the I/O mapping page
/// in the device editor of the EL2252).
///
/// Please note that one track is mapped to one channel of the EL2252 card.
/// The term track and channel are used interchangeably.
FUNCTION_BLOCK DigitalCamSwitch_EL2252
VAR_IN_OUT CONSTANT
    /// The events computed by SMC_DigitalCamSwitch_Forecast.
    Events : SMC_CAMSWITCH_TRACKS_EVENTS;
END_VAR
VAR_IN_OUT
    Axis : AXIS_REF_SM3;
	ETCMaster : IODrvEtherCAT;
END_VAR
VAR_INPUT
    /// Enables the function block.  Enable this function block with the
    /// same signal that enables the SMC_DigitalCamSwitch_HighPrecision
    /// function block.
    Enable : BOOL;
    /// The task interval of the bus task in seconds.
    taskInterval_s : LREAL;
    /// The required inputs of the EL2252.
    In : EL2252_In;
END_VAR
VAR_OUTPUT
    Busy : BOOL ;
    Error : BOOL ;
    /// The outputs, to be mapped to the I/O channels of the EL2252
    Out : EL2252_Out;
    /// Indicates how many events could not be programmed, because the
    /// duration until the event occured was too short (less than
    /// MIN_CYCLES cycles).
    missedCounter : UDINT;
END_VAR
VAR
    state : UDINT;
    EnableOld : BOOL;
    /// Stores for each track the last processed
    /// toggle event id.  This is done to avoid to program
    /// the same switch event twice.
    aLastEventIds : ARRAY[1..GVL_EL2252.NUM_CHANNELS] OF EventId;
END_VAR
VAR_TEMP
    channel : UDINT;
    nextEvents : ARRAY[1..GVL_EL2252.NUM_CHANNELS] OF EL2252_Event;
    eventIdx : UDINT;
    id : UDINT;
    lowestDuration : LREAL := FPU.GetLRealSpecialVal(FPU.ESpecial_FP_Value.PosInf);
    doInputsMatchOutputs : BOOL;
END_VAR
VAR CONSTANT
    EL2252_ACTIVATE_PREPARE : USINT := 0;
    EL2252_ACTIVATE_EVENT : USINT := 3;
    // Time in cycles the output card needs to program an event
    MIN_CYCLES : UDINT := 4;

    STATE_IDLE   : UDINT := 0;
    STATE_INIT : UDINT := 10;
    STATE_CHECK_FOR_EVENT : UDINT := 20;
    STATE_ACTIVATE_EVENT_IN_EL2252 : UDINT := 30;
    STATE_WAIT_UNTIL_THE_INPUTS_MATCH_THE_OUTPUTS : UDINT := 40;
    STATE_ERROR : UDINT := 1000;
END_VAR

IF Enable AND NOT EnableOld THEN
    state := STATE_INIT ;
ELSIF NOT Enable THEN
    state := STATE_IDLE ;
END_IF

CASE state OF
STATE_INIT:
    missedCounter := 0;
    FOR channel := 1 TO GVL_EL2252.NUM_CHANNELS DO
        // Reset stored toggle event id.
        EventId_Init(aLastEventIds[channel]);
    END_FOR
    state := STATE_CHECK_FOR_EVENT;

STATE_CHECK_FOR_EVENT:
    /// Get the next event for each channel.
    FOR channel := 1 TO GVL_EL2252.NUM_CHANNELS DO
        nextEvents[channel].isValid := FALSE;
        nextEvents[channel].activate := FALSE;

        FOR eventIdx := 1 TO Events[channel].numEvents DO
            id := Events[channel].a[eventIdx].ToggleEventId;

            IF EventId_GreaterThan(id, aLastEventIds[channel]) THEN
                IF IsValidDuration(Events[channel].a[eventIdx].Duration) THEN
                    nextEvents[channel].isValid := TRUE;
                    nextEvents[channel].event := Events[channel].a[eventIdx];
                    EXIT;
                ELSE
                    OnMissedEvent(Axis, ETCMaster, channel, Events[channel].a[eventIdx]);
                END_IF
            END_IF
        END_FOR
    END_FOR

    /// Find the event (or events if the events of different channels
    /// have the same duration) with the lowest duration (i.e. the
    /// event that will trigger next).
    FOR channel := 1 TO GVL_EL2252.NUM_CHANNELS DO
        IF nextEvents[channel].isValid THEN
            lowestDuration := MIN(lowestDuration, nextEvents[channel].event.Duration);
        END_IF
    END_FOR

    /// Check which events match the lowestDuration and activate these events.
    FOR channel := 1 TO GVL_EL2252.NUM_CHANNELS DO
        IF nextEvents[channel].isValid AND lowestDuration = nextEvents[channel].event.Duration THEN
            nextEvents[channel].activate := TRUE;
        END_IF
    END_FOR

    /// Write the outputs
    FOR channel := 1 TO GVL_EL2252.NUM_CHANNELS DO
        IF nextEvents[channel].activate THEN
            EventId_Set(aLastEventIds[channel], nextEvents[channel].event.ToggleEventId);

            Out.activate := EL2252_ACTIVATE_PREPARE;
            Out.startTime := DurationTo64bitEtcTimestamp(Axis, ETCMaster, nextEvents[channel].event.Duration);
            Out.channels[channel].output := nextEvents[channel].event.NewValue;

			LogEvent(
                prefix:= 'EL2252: ',
                track:= channel,
                event:= nextEvents[channel].event,
                etcTimestamp:= Out.startTime,
                missed:= FALSE);

            state := STATE_ACTIVATE_EVENT_IN_EL2252;
        END_IF
    END_FOR

STATE_ACTIVATE_EVENT_IN_EL2252:
    Out.activate := EL2252_ACTIVATE_EVENT;

    state := STATE_WAIT_UNTIL_THE_INPUTS_MATCH_THE_OUTPUTS;

STATE_WAIT_UNTIL_THE_INPUTS_MATCH_THE_OUTPUTS:
    doInputsMatchOutputs := TRUE;
    FOR channel := 1 TO GVL_EL2252.NUM_CHANNELS DO
        doInputsMatchOutputs :=
            doInputsMatchOutputs
            AND In.channels[channel].output = Out.channels[channel].output
            AND In.channels[channel].triState = Out.channels[channel].triState;
    END_FOR

    IF doInputsMatchOutputs THEN
        state := STATE_CHECK_FOR_EVENT;
    END_IF
END_CASE

IF IsBusy() THEN
    /// Check for events that will be missed.
    FOR channel := 1 TO GVL_EL2252.NUM_CHANNELS DO
        FOR eventIdx := 1 TO Events[channel].numEvents DO
            id := Events[channel].a[eventIdx].ToggleEventId;

            IF EventId_GreaterThan(id, aLastEventIds[channel])
               AND NOT IsValidDuration(Events[channel].a[eventIdx].Duration)
            THEN
                OnMissedEvent(Axis, ETCMaster, channel, Events[channel].a[eventIdx]);
            END_IF
        END_FOR
    END_FOR
END_IF

OnExit();