PROGRAM CNC
VAR
	iState: INT;
	pX, pY, pZ, pA: MC_Power;

	ipo: SMC_Interpolator;
	trafo: SMC_TRAFO_Gantry3;
	trafof: SMC_TRAFOF_Gantry3D;
	cabpX, cabpY, cabpZ, cabpA: SMC_ControlAxisByPos;

	tlc : SMC_ToolLengthCorr;
END_VAR

pX(
	Enable:= TRUE,
	bRegulatorOn:= TRUE,
	bDriveStart:= TRUE,
	Axis:= AxisX);
pY(
	Enable:= TRUE,
	bRegulatorOn:= TRUE,
	bDriveStart:= TRUE,
	Axis:= AxisY);
pZ(
	Enable:= TRUE,
	bRegulatorOn:= TRUE,
	bDriveStart:= TRUE,
	Axis:= AxisZ);
pA(
	Enable:= TRUE,
	bRegulatorOn:= TRUE,
	bDriveStart:= TRUE,
	Axis:= AxisA);

CASE iState OF
0:
	IF pX.Status AND pY.Status AND pZ.Status AND pA.Status THEN
		iState := 100;
	END_IF
100:
	Interpolation();
END_CASE