// Modifier function block to convert the path velocity (F-Word)
// from mm/min to mm/s.
FUNCTION_BLOCK TokenModifySpeed IMPLEMENTS SMC_ITokenModifier
VAR
    m_state : UDINT := STATE_INIT;

	m_tmpQueue : SMC_TokenQueue;
	m_aBufferTempQueue: ARRAY[0..3] OF SMC_Token;
	m_errorPos : SMC_NC_SourcePosition;
END_VAR
VAR CONSTANT
	STATE_INIT : UDINT := 0;
	STATE_RUNNING : UDINT := 10;
	STATE_DONE : UDINT := 100;
	STATE_ERROR : UDINT := 1000;
END_VAR