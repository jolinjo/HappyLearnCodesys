/// Comptues the maximum curvature of a path object.
FUNCTION ComputeMaxCurvature : BOOL
VAR_IN_OUT CONSTANT
    geo : SMC_GeoInfo;
END_VAR
VAR_OUTPUT
    kappa : LREAL;
END_VAR
VAR
    dR : LREAL;
    dA : LREAL;
    dB : LREAL;
END_VAR

CASE geo.iMoveType OF
SMC_MOVTYP.LIN,
SMC_MOVTYP.LINADDAXES,
SMC_MOVTYP.LINNODELTA,
SMC_MOVTYP.LINPOS,
SMC_MOVTYP.MCOMMAND,
SMC_MOVTYP.INITPOS:
    kappa := 0;
    ComputeMaxCurvature := TRUE;

SMC_MOVTYP.SPLINE,
SMC_MOVTYP.SPLINE3D,
SMC_MOVTYP.SPLINE3D_5:
    dR := SMC_CalcSplineMinCurvatureRadius(ADR(geo));

    IF dR > 0 THEN
        kappa := 1/dR;
        ComputeMaxCurvature := TRUE;
    ELSE
        ComputeMaxCurvature := FALSE;
	END_IF

SMC_MOVTYP.CCLW,
SMC_MOVTYP.CLW:
    dR := geo.dP3;

    IF dR > 0 THEN
        kappa := 1/dR;
        ComputeMaxCurvature := TRUE;
    ELSE
        ComputeMaxCurvature := FALSE;
	END_IF

SMC_MOVTYP.ELLCCLW,
SMC_MOVTYP.ELLCLW:
    dA := geo.dP3;
    dB := geo.dP4;

    IF dA > 0 AND dB > 0 THEN
        kappa := MAX(dA / (dB*dB), dB / (dA*dA));
        ComputeMaxCurvature := TRUE;
    ELSE
        ComputeMaxCurvature := FALSE;
	END_IF

ELSE
    ComputeMaxCurvature := FALSE;
END_CASE