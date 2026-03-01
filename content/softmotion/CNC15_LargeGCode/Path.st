PROGRAM Path
VAR_OUTPUT
	poqDataOut : POINTER TO SMC_OUTQUEUE;
END_VAR
VAR
	rncf : SMC_ReadNCFile2;
	ip : SMC_NCInterpreter;
	smm : SMC_SmoothMerge;
	smp : SMC_SmoothPath;

	cv : SMC_CheckVelocities;

	aBufIp : ARRAY[0..130] OF SMC_GeoInfo;
	aBufSmm  : ARRAY[0..15] OF SMC_GeoInfo;
	aBufSmp : ARRAY[0..99] OF SMC_GeoInfo;
END_VAR
VAR_TEMP
	counter : DINT;
END_VAR

// Set this value depending on your other tasks, PLC performance, and G-Code
counter := 25;

WHILE counter > 0 AND
      (poqDataOut = 0 OR_ELSE (NOT poqDataOut^.bFull AND NOT poqDataOut^.bEndOfList))
DO
	rncf(
		bExecute:= TRUE,
		sFileName:= '_cnc/CNC.cnc');

	ip(
		sentences:= rncf.sentences,
		bExecute:= rncf.bExecute,
		nSizeOutQueue:= SIZEOF(aBufIp),
		pbyBufferOutQueue:= ADR(aBufIp));

	smm(
		bExecute:= ip.bExecute,
		poqDataIn:= ip.poqDataOut,
		nSizeOutQueue:= SIZEOF(aBufSmm),
		pbyBufferOutQueue:= ADR(aBufSmm),
		piMaxDifference:= piMaxDifference,
        usiMaxDegree:= 5,
        wFeatureFlag:= 1,
		dMinimumCurvatureRadius:= dMinCurvatureRadius);

	smp(
		bExecute:= ip.bExecute,
		poqDataIn:= smm.poqDataOut,
		eMode:= SMC_SMOOTHPATHMODE.SP_SPLINE5_MIN_CURVATURE,
		eAddAxMode:= SMC_SMOOTHPATHADDAXMODE.SPAA_EXACT,
		nSizeOutQueue:= SIZEOF(aBufSmp),
		pbyBufferOutQueue:= ADR(aBufSmp),
		dAngleTol:= dAngleTol,
		bSymmetricalDistances:= TRUE,
		bImprovedSymmetricCuts:= TRUE);

	cv(
		bExecute:= ip.bExecute,
		poqDataIn:= smp.poqDataOut,
		dAngleTol:= dAngleTol);

	counter := counter - 1;
END_WHILE

poqDataOut := cv.poqDataOut;