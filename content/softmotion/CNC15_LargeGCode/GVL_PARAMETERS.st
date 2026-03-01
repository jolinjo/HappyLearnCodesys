VAR_GLOBAL
	piMaxDifference : SMC_PosInfo := (dX:= 0.1, dY:= 0.1, dZ:= 0.1, dA := 0.04, dB := 0.04, dC := 0.04);
	dAngleTol : LREAL := 0.01;
	dMinCurvatureRadius : LREAL := 0.015;

	dwTaskCycleMicros : DWORD := 4000;
	dJerkMax : LREAL := 10000;
END_VAR