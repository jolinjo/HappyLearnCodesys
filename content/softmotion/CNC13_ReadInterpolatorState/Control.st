PROGRAM Control
VAR_INPUT
	start : BOOL;
END_VAR
VAR_OUTPUT
	pos_MCS : SMC_Vector3D;
	pos_DCS : SMC_Vector3D;
END_VAR
VAR
    ipo : SMC_Interpolator := (dwIpoTime:= 4000, dJerkMax:= 10000);

    readState : SMC_ReadAdditionalIpoState;

    pw0 : MC_Power := (bRegulatorOn:= TRUE, bDriveStart:= TRUE);
    pw1 : MC_Power := (bRegulatorOn:= TRUE, bDriveStart:= TRUE);

    cap0 : SMC_ControlAxisByPos := (bAvoidGaps:= FALSE);
    cap1 : SMC_ControlAxisByPos := (bAvoidGaps:= FALSE);

    state : UDINT;

	piMCS_to_DCS : SMC_PosInfo;
END_VAR

CASE state OF
0:
    pw0.Enable := TRUE;
    pw1.Enable := TRUE;

    IF pw0.Status AND pw1.Status THEN
        state := 10;
    END_IF

10:
    ipo.bExecute := start;
END_CASE

pw0(Axis:= Drive0);
pw1(Axis:= Drive1);

ipo(poqDataIn := Path.poqDataOut,
    bEmergency_Stop:=
        cap0.bError OR cap0.bStopIpo OR
        cap1.bError OR cap1.bStopIpo);

SMC_V3_Set(pos_MCS, ipo.piSetPosition.dX, ipo.piSetPosition.dY, ipo.piSetPosition.dZ);

readState(
    Enable:= TRUE,
    ipo:= ipo);

IF readState.Valid THEN
	SMC_PosInfo_Trf_Inverse(
		piOut:= piMCS_to_DCS,
		piIn:= readState.State.DCS,
		eOriConv:= readState.State.OriConv);

	SMC_PosInfo_Trf_Apply(
		vDst:= pos_DCS,
		piTrf:= piMCS_to_DCS,
		vSrc:= pos_MCS,
		eOriConv:= readState.State.OriConv);
END_IF

cap0(
    Axis:= Drive0,
    bEnable:= ipo.bWorking,
    iStatus:= ipo.iStatus,
    fSetPosition:= ipo.piSetPosition.dX);

cap1(
    Axis:= Drive1,
    bEnable:= ipo.bWorking,
    iStatus:= ipo.iStatus,
    fSetPosition:= ipo.piSetPosition.dY);