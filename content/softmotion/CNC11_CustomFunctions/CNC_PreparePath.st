PROGRAM CNC_PreparePath
VAR_INPUT
	xStart : BOOL;
	sFileName : STRING := 'Application/CNC.cnc';
END_VAR
VAR_OUTPUT
	xStartIpo : BOOL;
	poqPath : POINTER TO SMC_Outqueue;
END_VAR
VAR
	iState : INT;
	rncf2 : SMC_ReadNCFile2 := (bParenthesesAsComments:= FALSE);
	nci : SMC_NCInterpreter;
	cv : SMC_CheckVelocities;
	aBufInterpreter : ARRAY[0..99] OF SMC_GeoInfo;
	gcv : SMC_GCodeViewer;

	bufGCV : ARRAY[0..99] OF SMC_GCODEVIEWER_DATA;

    aCNCFunctions : ARRAY[0..0] OF SMC_NC_GFunction :=
        [(stName:= 'SEL', iFunc:= GVL.g_Sel)];

    funTable : SMC_NC_GFunctionTable :=
        (numFunctions:= 1,
         pFunction:= ADR(aCNCFunctions)) ;

	vars : ARRAY[0..0] OF SMC_SingleVar :=
		[
			(strVarName:= 'LONGLINE',
			 eVarType:= SMC_VARTYPE.SMC_TYPE_BOOL,
			 pAdr:= ADR(GVL.g_longline))
		];

	varList : SMC_VARLIST := (wNumberVars:= 1, psvVarList:= ADR(vars));
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
		xStartIpo := FALSE;
		rncf2(bExecute:= FALSE);
		nci(bExecute:= FALSE, sentences:= rncf2.sentences);
		cv(bExecute:= FALSE);

		xStart:=FALSE;
		iState := 10;
	END_IF

10:	// start reading and processing
	rncf2(
        bExecute:= TRUE,
		sFileName:= sFileName,
        pCustomFunTable:= ADR(funTable),
		pvl:= ADR(varList));

	nci(
        bExecute:= TRUE ,
		sentences:= rncf2.sentences,
		nSizeOutQueue:= SIZEOF(aBufInterpreter) ,
		pbyBufferOutQueue:= ADR(aBufInterpreter));

	cv(
        bExecute:= TRUE,
		poqDataIn:= nci.poqDataOut);

	xStartIpo := TRUE;
	IF NOT cv.bBusy THEN
		iState := 0;
	END_IF
END_CASE