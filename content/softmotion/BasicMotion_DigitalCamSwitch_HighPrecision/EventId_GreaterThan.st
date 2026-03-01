/// Returns whether the given event Id id1 is greater than the event Id id2.
/// Note that if id2 is not valid, id1 is considered greater.
FUNCTION EventId_GreaterThan : BOOL
VAR_INPUT
    id1 : UDINT;
END_VAR
VAR_IN_OUT CONSTANT
    id2 : EventId;
END_VAR

IF NOT id2.valid THEN
    EventId_GreaterThan := TRUE;
ELSE
    // Greater than check with handling of 32-bit overflows
    EventId_GreaterThan :=
        (id1 > id2.id AND id1 - id2.id < 16#7FFF_FFFF) OR_ELSE
        (id1 < id2.id AND id2.id - id1 > 16#7FFF_FFFF);
END_IF