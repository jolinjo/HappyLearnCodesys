/// Converts duration in seconds to 64bit EtherCAT timestamp in nanoseconds.
FUNCTION DurationTo64bitEtcTimestamp : ULINT
VAR_IN_OUT
    Axis : AXIS_REF_SM3;
	ETCMaster : IODrvEtherCAT;
END_VAR
VAR_INPUT
    duration : LREAL;
END_VAR
VAR
    curTime_ns : ULINT;
	error : SMC_ERROR ;
END_VAR

{IF defined (pou: AXIS_REF_SM3.GetTimestampActValues)}
// GetTimeStampActValues exists for SoftMotion version 4.19.0.0 and higher.
error := Axis.GetTimestampActValues(CurrentActTime=> curTime_ns);
IF error = SMC_NOT_IMPLEMENTED THEN
	// No EtherCAT drive, fall back to default implementation
	curTime_ns := ETCMaster.DCClockReferenceTime;
END_IF
{ELSE}
curTime_ns := ETCMaster.DCClockReferenceTime;
{END_IF}
DurationTo64bitEtcTimestamp := curTime_ns + TO_ULINT(duration*1E9);