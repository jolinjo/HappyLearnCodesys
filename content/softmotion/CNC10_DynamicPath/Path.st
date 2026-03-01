PROGRAM Path
VAR
	iState: INT;
	CheckVel: SMC_CheckVelocities;

	QUEUE: SMC_OUTQUEUE;
	BUF: ARRAY[0..99] OF SMC_GEOINFO;
	GEO: SMC_GEOINFO:=(dT1:=0, dT2:=1, dToolRadius:=0, dVel:=100, dVelEnd:=100, dAccel:=200, dDecel:=500, iObjNo:=0);
	n: INT:=0;
	xp:ARRAY[1..7] OF REAL:= [100,50,50,10,90,0,0];
	yp:ARRAY[1..7] OF REAL:= [0,100,0,50,100,100,0];

END_VAR

CASE iState OF
0:
	//initialize Queue
	QUEUE.pbyBuffer := ADR(BUF[0]);
	SM3_CNC.SMC_SetQueueCapacity(ADR(QUEUE), SIZEOF(BUF));
	iState := iState + 1;

1: 	//fill queue

	WHILE NOT QUEUE.bFull DO					// when the Queue is full, wait until it has been processed by the following FBs
		n := n + 1;
		GEO.iSourceLine_No := n;
		GEO.piStartPos := GEO.piDestPos;		// copy last destination
		GEO.iMoveType := LIN;					// generate linear movement
		GEO.iObjNo := GEO.iObjNo + 1;			// calculate number
		GEO.piDestPos.dX := xp[n];				// generate position
		GEO.piDestPos.dY := yp[n];
		SMC_CalcLengthGeo(pg := ADR(GEO));		// calculate length of object with the help of the standard function
		SMC_AppendObj(poq:=ADR(QUEUE), pgi:=ADR(GEO));	//append object to queue
		IF n = SIZEOF(xp)/SIZEOF(xp[1]) THEN	// all target positions processed
			QUEUE.bEndOfList := TRUE;
			n := 0;
			iState := 2;
			EXIT;
		END_IF
	END_WHILE

2:	//done
	;
END_CASE

CheckVel(bExecute:=TRUE , poqDataIn:=ADR(queue));
