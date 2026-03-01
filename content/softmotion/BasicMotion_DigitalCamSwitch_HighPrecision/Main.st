PROGRAM Main
VAR
    pw : MC_Power;
    mv : MC_MoveVelocity := (Velocity:= 180, Acceleration:= 3600, Deceleration:= 3600, Jerk:= 36000);

    aSwitches : ARRAY[0..7] OF MC_CAMSWITCH_TR := [
        (TrackNumber:= 1,
         FirstOnPosition:= 20,
         LastOnPosition:= 90,
         AxisDirection:= 1,  // positive
         CamSwitchMode:= 0), // position based
        (TrackNumber:= 1,
         FirstOnPosition:= 180,
         LastOnPosition:= 270,
         AxisDirection:= 1,  // positive
         CamSwitchMode:= 0), // position based
        (TrackNumber:= 2,
         FirstOnPosition:= 30,
         LastOnPosition:= 90,
         AxisDirection:= 1,  // positive
         CamSwitchMode:= 0), // position based
        (TrackNumber:= 2,
         FirstOnPosition:= 190,
         LastOnPosition:= 270,
         AxisDirection:= 1,  // positive
         CamSwitchMode:= 0)]; // position based

    switches : MC_CAMSWITCH_REF := (
            NoOfSwitches := 4,
            CamSwitchPtr:= ADR(aSwitches));

    tracks : MC_TRACK_REF :=[
            (OnCompensation:= -0.1,
             OffCompensation:= 0.1),
            (OnCompensation:= 0.05,
             OffCompensation:= -0.05)];

    setForecast : SMC_SetForecast := (ForecastDuration:= 0.15);

    dcs : SMC_DigitalCamSwitch_HighPrecision;
    dcs_el2258 : DigitalCamSwitch_EL2258;
	dcs_el2252 : DigitalCamSwitch_EL2252;

    state : UDINT ;
END_VAR

CASE state OF
0:
    setForecast.Execute := TRUE;
    IF setForecast.Done THEN
        state := state + 10;
    END_IF

10:
    pw.Enable := TRUE;
    pw.bRegulatorOn := TRUE;
    pw.bDriveStart := TRUE;

    IF pw.Status THEN
        state := state + 10;
    END_IF

20:
    IF EtherCAT_Master_SoftMotion.GetBusState() = DED.BUS_STATE.RUNNING THEN
        state := state + 10;
    END_IF

30:
    mv.Execute := TRUE;
    dcs.Enable := TRUE;
    dcs_el2258.Enable := TRUE;
	dcs_el2252.Enable := TRUE;
END_CASE

pw(Axis:= Drive);
mv(Axis:= Drive);
setForecast(Axis:= Drive);
dcs(Axis:= Drive, Switches:= switches, TrackOptions:= tracks);
dcs_el2258(
    Events:= dcs.Events,
    Axis:= Drive,
	ETCMaster:= EtherCAT_Master_SoftMotion,
    taskInterval_s:= Drive.fTaskCycle);
dcs_el2252(
    Events:= dcs.Events,
    Axis:= Drive,
	ETCMaster:= EtherCAT_Master_SoftMotion,
    taskInterval_s:= Drive.fTaskCycle);