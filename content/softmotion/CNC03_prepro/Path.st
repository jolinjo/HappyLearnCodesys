PROGRAM Path
VAR
	dec: SMC_NCDecoder;
	SmoothPath: SMC_SmoothPath;
	CheckVel: SMC_CheckVelocities;
	buf1: ARRAY[0..15] OF SMC_GEOINFO;
	buf2: ARRAY[0..99] OF SMC_GEOINFO;
END_VAR