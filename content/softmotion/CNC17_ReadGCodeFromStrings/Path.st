PROGRAM Path
VAR_INPUT
	bExecute : BOOL ;
    sProgramName : STRING := 'CNC' ;

	// The main G-Code.
    sGCode : STRING(255) :=
'N0 F100
N10 SUB1{10, 50, 0}
N20 G1 Y50
N30 SUB1{50, 20, 100}' ;

	// The table of subprograms.
	aSubs : ARRAY[0..0] OF SubProgram := [
            (stName := 'SUB1',
			 stContent := '
SUBPROGRAM SUB1{#p1 : LREAL, #p2 : LREAL, #p3 : LREAL}
N10 G1 X#p1
N20 G1 X#p2
N30 G1 X#p3
END_SUBPROGRAM')
        ] ;
END_VAR
VAR_OUTPUT
	poqPath : POINTER TO SMC_OUTQUEUE;
END_VAR
VAR
	rnc : SMC_ReadNCFromStream;
	interpreter: SMC_NCInterpreter;
	aBufInterpreter : ARRAY[0..99] OF SMC_GeoInfo ;

	gcv : SMC_GCodeViewer;
	bufGCV : ARRAY[0..99] OF SMC_GCODEVIEWER_DATA;

	cv : SMC_CheckVelocities;

	sentences : SMC_GSentenceQueue;

	aStringStream: ARRAY[0..NUM_CHAINS-1] OF SMC_StringStream2 ;

    subs : LookupStream := (nNumSPs:= 1, psp:= ADR(aSubs)) ;

	bExecuteOld: BOOL;
END_VAR
VAR_TEMP
    i : UDINT ;
END_VAR
VAR CONSTANT
    NUM_CHAINS : UDINT := SMC_CNC_LibParams.MAX_SUBPROGRAM_NESTING_DEPTH+1 ;
END_VAR

IF bExecute AND NOT bExecuteOld THEN
    // Load G-Code into first stream
    aStringStream[0].Init(sProgramName) ;
    aStringStream[0].AppendData(sGCode) ;
    aStringStream[0].SetEndOfData() ;

    // Initialize the streams of SMC_ReadNCFromStream to string streams for all chains.
    i := 0 ;
    WHILE i < NUM_CHAINS DO
        rnc.aStream[i] := aStringStream[i] ;
        i := i + 1 ;
    END_WHILE

    rnc(bExecute:= FALSE, sentences:= sentences, lookupCNCProgram:= subs) ;
    interpreter(sentences:= sentences, bExecute:= FALSE, bAbort:= TRUE) ;
    interpreter.bAbort := FALSE ;
ELSIF NOT bExecute AND bExecuteOld THEN
    ;
END_IF

rnc(bExecute:= bExecute, sentences:= sentences, lookupCNCProgram:= subs) ;
interpreter(bExecute:= bExecute, sentences:= sentences,
    pbyBufferOutQueue:= ADR(aBufInterpreter),
    nSizeOutQueue:= SIZEOF(aBufInterpreter)) ;

IF aStringStream[rnc.nActiveChain].refillData THEN
    // In case of jumps in the G-Code (G20), it can happen that
    // the g-code needs to be read again from the beginning.
    // This is signalled using the "refillData" output.
    aStringStream[rnc.nActiveChain].AppendData(sGCode) ;
    aStringStream[rnc.nActiveChain].SetEndOfData() ;
END_IF

cv(bExecute:= bExecute,
	poqDataIn:= interpreter.poqDataOut);

gcv(
	GCodeText:= interpreter.GCodeText,
	bEnable:= TRUE,
	interpolatedObjectId:= Ipo.smci.actObjectId,
	uiNumberOfBufferEntries:= SIZEOF(bufGCV)/SIZEOF(bufGCV[0]),
	pBuffer:= ADR(bufGCV));

poqPath := cv.poqDataOut;

bExecuteOld := bExecute ;