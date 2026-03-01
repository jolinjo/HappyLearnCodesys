PROGRAM Main
VAR_OUTPUT
    setStart: SMC_SetInterpreterStartPosition;
END_VAR
VAR
	pwX: MC_Power;
	pwY: MC_Power;
    ipo : SMC_Interpolator;
	capX: SMC_ControlAxisByPos;
	capY: SMC_ControlAxisByPos;
    trafo : SMC_TRAFO_Gantry2;
	trafoF: SMC_TRAFOF_Gantry2;
END_VAR