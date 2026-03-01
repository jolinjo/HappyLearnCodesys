PROGRAM CNC_PreparePath
VAR_INPUT
	xStart : BOOL;
	sFileName : STRING := 'Application/CNC_PathSpeed.cnc';
END_VAR
VAR_OUTPUT
	xStartIpo : BOOL;
	poqPath : POINTER TO SMC_Outqueue;
END_VAR
VAR
	iState: INT;
    aModifySpeed : ARRAY[0..NUM_MODIFIERS-1] OF TokenModifySpeed ;
	rncf : SMC_ReadNCFile2 := (aSubProgramDirs := ['Application/']);
	nci : SMC_NCInterpreter;
	cv : SMC_CheckVelocities;
	aBufInterpreter : ARRAY[0..99] OF SMC_GeoInfo ;
	gcv : SMC_GCodeViewer;
	bufGCV : ARRAY[0..99] OF SMC_GCODEVIEWER_DATA;
END_VAR
VAR_TEMP
    i : UDINT;
END_VAR
VAR CONSTANT
	// SMC_ReadNCFile2 expects this number of modifiers in the input
	// aTokenModifier.
	NUM_MODIFIERS : UDINT := SMC_CNC_LibParams.MAX_SUBPROGRAM_NESTING_DEPTH+1;
END_VAR

poqPath := cv.poqDataOut;

gcv(
	GCodeText:= nci.GCodeText,
	bEnable:= TRUE,
	interpolatedObjectId:= CNC.ipo.actObjectId,
	uiNumberOfBufferEntries:= SIZEOF(bufGCV)/SIZEOF(bufGCV[0]),
	pBuffer:= ADR(bufGCV));

CASE iState OF
0:	// idle
	IF xStart THEN
		iState := 10;
		xStartIpo := FALSE;

        i := 0 ;
        WHILE i < NUM_MODIFIERS DO
            rncf.aTokenModifier[i] := aModifySpeed[i] ;
            i := i + 1 ;
        END_WHILE

		rncf(bExecute:= FALSE);
		nci(bExecute:= FALSE, sentences:= rncf.sentences);
		cv(bExecute:= FALSE);
		xStart := FALSE;
	END_IF

10:	// start reading and processing
	rncf(
        bExecute:= TRUE,
		sFileName:= sFileName);

	nci(
        bExecute:= TRUE ,
		sentences:= rncf.sentences,
		nSizeOutQueue:= SIZEOF(aBufInterpreter),
		pbyBufferOutQueue:= ADR(aBufInterpreter),
        bEnableSyntaxChecks:= TRUE);

	cv(
        bExecute:= TRUE,
		poqDataIn:= nci.poqDataOut);

	xStartIpo := TRUE;
	IF NOT cv.bBusy THEN
		iState := 0;
	END_IF
END_CASE