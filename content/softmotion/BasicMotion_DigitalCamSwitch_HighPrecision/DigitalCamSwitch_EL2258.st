/// This function block shows how to use the output Events from
/// SMC_DigitalCamSwitch_HighPrecision to program a Beckhoff EL2258
/// digital output card.
///
/// The function block assumes that the PDO configuration of the
/// EL2258 contains two channels, each with at least 2 events.
/// The members of the arrays ChannelsOut and ChannelsIn must
/// be mapped to the I/O channels of the EL2258 device in the
/// I/O mapping page of the device editor.
///
/// Please note that one track is mapped to one channel of the EL2258 card.
/// The term track and channel are used interchangeably.
FUNCTION_BLOCK DigitalCamSwitch_EL2258
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
END_VAR
VAR_OUTPUT
    Busy : BOOL ;
    Error : BOOL ;

    /// The output channels, to be mapped to the I/O channels of the EL2258
    ChannelsOut : ARRAY[1..NUM_CHANNELS] OF EL2258_OutChannel ;
    /// The input channels, to be mapped to the I/O channels of the EL2258
    ChannelsIn : ARRAY[1..NUM_CHANNELS] OF EL2258_InChannel ;

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
    aLastEventIds : ARRAY[1..NUM_CHANNELS] OF EventId;
END_VAR
VAR_TEMP
    channel : UDINT;
    id : UDINT;
    i : UDINT;
    event : POINTER TO SMC_CAMSWITCH_TOGGLE_EVENT;
    etcTimestamp : UDINT;
    nEvents : UDINT;
    missed : BOOL;
END_VAR
VAR CONSTANT
    NUM_CHANNELS : UDINT := 2;
    // Time in cycles the output card needs to program an event
    MIN_CYCLES : UDINT := 6;

    STATE_IDLE   : UDINT := 0;
    STATE_INIT_0 : UDINT := 10;
    STATE_INIT_1 : UDINT := 20;
    STATE_ACTIVE : UDINT := 30;
    STATE_ERROR  : UDINT := 1000;
END_VAR

IF Enable AND NOT EnableOld THEN
    state := STATE_INIT_0 ;
ELSIF NOT Enable THEN
    state := STATE_IDLE ;
END_IF

CASE state OF
STATE_INIT_0:
    missedCounter := 0;
    FOR channel := 1 TO NUM_CHANNELS DO
        // Reset ouput buffer of the terminal EL2258
        ChannelsOut[channel].OutputBufferReset := TRUE;

        // Reset stored toggle event id.
        EventId_Init(aLastEventIds[channel]);
    END_FOR
    state := STATE_INIT_1;

STATE_INIT_1:
    FOR channel := 1 TO NUM_CHANNELS DO
        ChannelsOut[channel].OutputBufferReset := FALSE;
    END_FOR
    state := STATE_ACTIVE;

STATE_ACTIVE:
    FOR channel := 1 TO NUM_CHANNELS DO
        // Previous events already procesed by the output card?
        IF ChannelsIn[channel].OutputOrderFeedback = ChannelsOut[channel].OutputOrderCounter THEN
            // Program the next up to five events for this channel
            nEvents := 0;
            i := 1;
            WHILE i <= Events[channel].numEvents AND nEvents < 5 DO
                event := ADR(Events[channel].a[i]);
                id := event^.ToggleEventId;

                // Only process events with an Id greater then the last processed
                // Id for this switch number.
                IF EventId_GreaterThan(id, aLastEventIds[channel]) THEN
                    etcTimestamp := DurationTo32bitEtcTimestamp(Axis, ETCMaster, event^.Duration);

                    IF event^.Duration < MIN_CYCLES * taskInterval_s THEN
                         // Less then MIN_CYCLES left until the switch occurs.
                         // There is not enough time to program the switch.
                         missedCounter := missedCounter + 1 ;
                         missed := TRUE;
                    ELSE
                         missed := FALSE;
						 ChannelsOut[channel].OutputEventState[nEvents] := event^.NewValue;
						 ChannelsOut[channel].OutputEventTime[nEvents] := etcTimestamp;

						 nEvents := nEvents + 1 ;
                    END_IF

					EventId_Set(aLastEventIds[channel], id);
                    LogEvent(
						prefix:= 'EL2258: ',
                        track:= channel,
                        event:= event^,
                        etcTimestamp:= etcTimestamp,
                        missed:= missed);
                END_IF

                i := i + 1;
            END_WHILE

            IF nEvents > 0 THEN
                ChannelsOut[channel].NoOfOutputEvents := TO_USINT(nEvents);

                // Trigger Multi-Timestamp scheduling
                ChannelsOut[channel].OutputOrderCounter := ChannelsOut[channel].OutputOrderCounter + 1;
            END_IF
        END_IF
    END_FOR
END_CASE

OnExit();