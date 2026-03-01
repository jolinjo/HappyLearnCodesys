PROGRAM CNC_PreparePath
VAR_INPUT
	xStart: BOOL;
	sFileName: STRING := 'Application/CNC2Main.cnc';
END_VAR
VAR_OUTPUT
	xStartIpo: BOOL;
	poqPath: Pointer to SMC_Outqueue;
END_VAR
VAR
	iState: INT;
	rncf2 : SMC_ReadNCFile2 := (aSubProgramDirs := ['Application/']);
	nci : SMC_NCInterpreter;
	cv : SMC_CheckVelocities;
	aBufInterpreter : ARRAY[0..99] OF SMC_GeoInfo ;
    dnccs : SMC_DisplayNCCallstack;

	sentenc: SMC_GSentenceQueue;
	asv : ARRAY[0..1] OF SMC_SingleVar := [
  	(strVarName := 'G_X', eVarType := SMC_TYPE_REAL, pAdr := ADR(g_x)),
  	(strVarName := 'G_Y', eVarType := SMC_TYPE_REAL, pAdr := ADR(g_y))];
	vl : SMC_VarList := (wNumberVars := 2, psvVarList := ADR(asv[0]));
END_VAR

poqPath := cv.poqDataOut;
dnccs(
    csi := nci.CallstackInfo,
    ipo := CNC.ipo,
    Enable := TRUE);

CASE iState OF
0:	// idle
	IF xStart THEN
		iState:=10;
		xStartIpo := FALSE;
		rncf2(bExecute:=FALSE);
		nci(bExecute:=FALSE,sentences := rncf2.sentences);
		cv(bExecute:=FALSE);
		xStart:=FALSE;
	END_IF

10:	// start reading and processing
	rncf2(
        bExecute:=TRUE ,
		sFileName:=sFileName ,
		pvl:= ADR(vl));

	nci(
        bExecute:=TRUE ,
		sentences := rncf2.sentences,
		nSizeOutQueue:=SIZEOF(aBufInterpreter) ,
		pbyBufferOutQueue:=ADR(aBufInterpreter),
        bEnableSyntaxChecks:= TRUE,
        eOriConv:= SMC_ORI_CONVENTION.ZYZ);

	cv(
        bExecute:= TRUE,
		poqDataIn:=nci.poqDataOut);

	xStartIpo := TRUE;
	IF NOT cv.bBusy THEN
		iState:=0;
	END_IF
END_CASE