PROGRAM Path
VAR_INPUT
	sFile : STRING := '_cnc/test.cnc';
    sSub : STRING := '';
END_VAR
VAR_OUTPUT
	poqDataOut : POINTER TO SMC_OUTQUEUE;
END_VAR
VAR
	rncf : SMC_ReadNCFile2 := (bExecute:= TRUE);

	ipr : SMC_NCInterpreter := (
		bExecute:= TRUE,
		nSizeOutQueue:= SIZEOF(aBufIpr),
		eOriConv:= SMC_ORI_CONVENTION.ZYZ);

	cv : SMC_CheckVelocities := (bExecute:= TRUE, dAngleTol:= dAngleTol);

    aBufIpr : ARRAY[0..15] OF SMC_GeoInfo;

    bInit : BOOL := TRUE;
END_VAR

IF bInit THEN
    rncf.sFileName := sFile;
    rncf.aSubProgramDirs[0] := sSub;
    bInit := FALSE;
END_IF

rncf();

ipr(sentences := rncf.sentences,
	pbyBufferOutQueue:= ADR(aBufIpr));

cv(poqDataIn := ipr.poqDataOut);

poqDataOut := cv.poqDataOut;