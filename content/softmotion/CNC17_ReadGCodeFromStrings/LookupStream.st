// If subprograms are used, this FB returns the stream that
// corresponds to a given subprogram.
// This implementation works based on an array of
// subprograms.
FUNCTION_BLOCK LookupStream IMPLEMENTS SMC_INCLookup
VAR_INPUT
	// Number of subprograms.
    nNumSPs : UDINT;
	// Pointer to array of subprograms.
    psp : POINTER TO SubProgram;
END_VAR