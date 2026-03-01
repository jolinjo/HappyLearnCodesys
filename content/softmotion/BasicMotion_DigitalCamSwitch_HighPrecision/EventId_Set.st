FUNCTION EventId_Set
VAR_IN_OUT
    lte : EventId;
END_VAR
VAR_INPUT
    id : UDINT;
END_VAR

lte.id := id;
lte.valid := TRUE;