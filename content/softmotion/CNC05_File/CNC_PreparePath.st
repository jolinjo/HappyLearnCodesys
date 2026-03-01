PROGRAM CNC_PreparePath
VAR_INPUT
	xStart: BOOL;
	sFileName: STRING := '_cnc/CNC1.cnc';
END_VAR
VAR_OUTPUT
	xStartIpo: BOOL;
	poqPath: Pointer to SMC_Outqueue;
END_VAR
VAR
	iState: INT;
	rncf2 : SMC_ReadNCFile2;
	nci: SMC_NCInterpreter;
	cv: SMC_CheckVelocities;
	agiBufInterpreter: ARRAY[0..99] OF SMC_GeoInfo;
END_VAR

poqPath := cv.poqDataOut;

CASE iState OF
0:	// idle
	IF xStart THEN
		iState := 10;
		xStartIpo := FALSE;
		rncf2(bExecute:= FALSE);
		nci(bExecute:= FALSE, sentences:= rncf2.sentences);
		cv(bExecute:= FALSE);
		xStart := FALSE;
	END_IF
10:	// start reading and processing
	rncf2(
		bExecute:= TRUE,
		sFileName:= sFilename);
	nci(
		bExecute:= TRUE,
		nSizeOutQueue:= SIZEOF(agiBufInterpreter),
		pbyBufferOutQueue:= ADR(agiBufInterpreter),
		sentences:= rncf2.sentences);
	cv(
		bExecute:= TRUE,
		poqDataIn:= nci.poqDataOut);

	xStartIpo := TRUE;
	IF NOT cv.bBusy THEN
		iState := 0;
	END_IF
END_CASE