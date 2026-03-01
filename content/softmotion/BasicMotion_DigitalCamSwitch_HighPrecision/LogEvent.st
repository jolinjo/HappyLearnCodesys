FUNCTION LogEvent
VAR_INPUT
    prefix : STRING;
    track : UDINT;
    event : SMC_CAMSWITCH_TOGGLE_EVENT;
    etcTimestamp : ULINT;
    missed : BOOL;
END_VAR

SM0.DoLog(CmpLog.LogClass.LOG_INFO,
    CONCAT(prefix,
    CONCAT(SEL(missed, 'Event tr=', 'MISSED Event tr='),
    CONCAT(TO_STRING(track),
    CONCAT(', sw=',
    CONCAT(TO_STRING(event.SwitchNumber),
    CONCAT(', id=',
    CONCAT(TO_STRING(event.ToggleEventId),
    CONCAT(', v=',
    CONCAT(TO_STRING(event.NewValue),
    CONCAT(', timestamp=',
           TO_STRING(etcTimestamp))))))))))));