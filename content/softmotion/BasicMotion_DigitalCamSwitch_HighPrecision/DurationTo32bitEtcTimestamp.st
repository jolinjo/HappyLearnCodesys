/// Converts duration in seconds to 32bit EtherCAT timestamp in nanoseconds.
FUNCTION DurationTo32bitEtcTimestamp : UDINT
VAR_IN_OUT
    Axis : AXIS_REF_SM3;
	ETCMaster : IODrvEtherCAT;
END_VAR
VAR_INPUT
    duration : LREAL;
END_VAR
VAR
    timestamp64Bit : ULINT;
END_VAR

timestamp64Bit := DurationTo64bitEtcTimestamp(Axis, ETCMaster, duration);
DurationTo32bitEtcTimestamp := TO_UDINT(timestamp64Bit AND 16#FFFF_FFFF);