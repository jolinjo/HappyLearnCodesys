PROGRAM Control
VAR
	pow1, pow2 : MC_Power := (Enable:= TRUE, bRegulatorOn:= TRUE, bDriveStart:= TRUE);
	cap1, cap2 : SMC_ControlAxisByPos := (bAvoidGaps:= FALSE);
	ipo : SMC_Interpolator := (
		iVelMode:= SMC_INT_VELMODE.QUADRATIC,
		dwIpoTime:= dwTaskCycleMicros,
		dJerkMax:= dJerkMax);

	bInitialized : BOOL;
END_VAR

pow1(Axis := Drive1);
pow2(Axis := Drive2);

IF NOT bInitialized THEN
	IF pow1.Status AND pow2.Status THEN
		bInitialized := TRUE;
	END_IF
END_IF

ipo(bExecute:= bInitialized, poqDataIn := Path.poqDataOut);

cap1(Axis := Drive1,
     iStatus := ipo.iStatus,
	 bEnable := ipo.bWorking,
	 fSetPosition := ipo.piSetPosition.dX);

cap2(Axis := Drive2,
     iStatus := ipo.iStatus,
	 bEnable := ipo.bWorking,
	 fSetPosition := ipo.piSetPosition.dY);