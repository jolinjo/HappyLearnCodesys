PROGRAM Path
VAR_OUTPUT
    poqDataOut : POINTER TO SMC_OUTQUEUE;
END_VAR
VAR
    read : SMC_ReadNCFile2 := (sFileName:= 'Application/gcode.cnc');
    inter : SMC_NCInterpreter;
    cv : SMC_CheckVelocities;

    bufIpo : ARRAY[0..99] OF SMC_GEOINFO;
END_VAR

read(bExecute:= TRUE);

inter(
    sentences:= read.sentences,
    bExecute:= read.bExecute,
    nSizeOutQueue:= SIZEOF(bufIpo),
    pbyBufferOutQueue:= ADR(bufIpo),
	piStartPosition:= Main.setStart.StartPos);

cv(bExecute:= read.bExecute,
   poqDataIn:= inter.poqDataOut);

poqDataOut := cv.poqDataOut;