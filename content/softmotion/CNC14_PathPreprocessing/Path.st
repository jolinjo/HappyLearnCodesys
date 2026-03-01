PROGRAM Path
VAR_INPUT
    bExecute : BOOL;
END_VAR
VAR
    dec : SMC_NCDecoder := (bEnableSyntaxChecks:= TRUE);

    sp : SMC_SmoothPath := (
		eMode:= SMC_SMOOTHPATHMODE.SP_SPLINE5_MIN_CURVATURE,
        bSymmetricalDistances:= TRUE,
        bImprovedSymmetricCuts:= TRUE);

    limitTangentVel : LimitTangentVelocity := (maxAngularVelocity_deg:= 45, featureFlag:= 0);

    cv : SMC_CheckVelocities;

    aBufDec : ARRAY[0..15] OF SMC_GeoInfo;
    aBufSp : ARRAY[0..15] OF SMC_GeoInfo;
    aBufLimit : ARRAY[0..99] OF SMC_GeoInfo;
END_VAR

dec(
	ncprog:= CNC,
	bExecute:= bExecute,
	nSizeOutQueue:= SIZEOF(aBufDec),
	pbyBufferOutQueue:= ADR(aBufDec));

sp(
    bExecute:= bExecute,
    poqDataIn:= dec.poqDataOut,
    nSizeOutQueue:= SIZEOF(aBufSp),
    pbyBufferOutQueue:= ADR(aBufSp));

limitTangentVel(
	Execute:= bExecute,
	poqDataIn:= sp.poqDataOut,
	nSizeOutQueue:= SIZEOF(aBufLimit),
	pbyBufferOutQueue:= ADR(aBufLimit));

cv(
	bExecute:= bExecute,
	poqDataIn:= limitTangentVel.poqDataOut);