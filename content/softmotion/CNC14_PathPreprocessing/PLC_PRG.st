PROGRAM PLC_PRG
VAR_INPUT
    bStart : BOOL ;
END_VAR
VAR
    ipo : SMC_Interpolator ;

    trafo : SMC_TRAFO_GantryCutter2 ;

    pwX, pwY, pwC : MC_Power ;

    cabpX, cabpY, cabpC : SMC_ControlAxisByPos ;
END_VAR

pwX(Axis:= DriveX,
    Enable:= TRUE,
    bRegulatorOn:= TRUE,
    bDriveStart:= TRUE) ;

pwY(Axis:= DriveY,
    Enable:= TRUE,
    bRegulatorOn:= TRUE,
    bDriveStart:= TRUE) ;

pwC(Axis:= DriveC,
    Enable:= TRUE,
    bRegulatorOn:= TRUE,
    bDriveStart:= TRUE) ;

ipo(
	bExecute:= bStart,
	poqDataIn:= Path.cv.poqDataOut,
	iVelMode:= SMC_INT_VELMODE.QUADRATIC,
	dwIpoTime:= 4000,
	dLastWayPos:= ipo.dWayPos,
	dJerkMax:= 10000) ;

trafo(
	pi:= ipo.piSetPosition,
	v:= ipo.vecActTangent,
	iDirectionR:= 1) ;

cabpX(
    Axis:= DriveX,
    iStatus:= ipo.iStatus,
    bEnable:= ipo.bWorking,
    bAvoidGaps:= FALSE,
    fSetPosition := trafo.dx) ;

cabpY(
    Axis:= DriveY,
    iStatus:= ipo.iStatus,
    bEnable:= ipo.bWorking,
    bAvoidGaps:= FALSE,
    fSetPosition := trafo.dy) ;

cabpC(
    Axis:= DriveC,
    iStatus:= ipo.iStatus,
    bEnable:= ipo.bWorking,
    bAvoidGaps:= FALSE,
    fSetPosition := trafo.dr) ;