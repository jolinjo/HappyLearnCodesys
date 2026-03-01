/// Limits the velocity on the path so that the tangent velocity will not
/// exceed a configured maximum angular velocity.
FUNCTION_BLOCK LimitTangentVelocity
VAR_INPUT
    /// Starts on rising edge
	Execute : BOOL;
    /// Input path queue
	poqDataIn : POINTER TO SMC_OUTQUEUE;
    /// The size of pbyBufferOutQueue in bytes
	nSizeOutQueue : UDINT;
    /// The buffer for the output queue
	pbyBufferOutQueue : POINTER TO ARRAY[0..0] OF SMC_GEOINFO;

    /// The maximum allowed angular velocity of the tangent, in [°/s].
    /// Must be positive.
    maxAngularVelocity_deg : LREAL;

    /// The feature bit (0..31) used for smoothing (controlled by G38/G39)
    featureFlag : USINT;
END_VAR
VAR_OUTPUT
    /// Indicates the entire input path has been processed
	Done : BOOL;
    /// Indicates the function block is still busy processing
	Busy : BOOL;
    /// An error has occurred
	Error : BOOL;
    /// Error-ID
	ErrorID : SMC_ERROR;
    /// Output path queue
	poqDataOut : POINTER TO SMC_OUTQUEUE;

    /// The minimum path velocity computed so far.  Reset on a rising
    /// edge of Execute, initialized with -1.
    velMin : LREAL;
END_VAR
VAR
	m_data : SMC_OUTQUEUE := (byGenerator := 19);

	m_featureFlag : USINT;
    m_maxAngularVelocity_rad : LREAL;

	m_state : UDINT;
	m_oldExecute : BOOL;

	m_geo : SMC_GeoInfo;
END_VAR
VAR_TEMP
    xdwAddr : __XWORD;

    pgeo : POINTER TO SMC_GeoInfo;
    kappa_max : LREAL;
    ok : BOOL;
    vel : LREAL;
END_VAR
VAR CONSTANT
	STATE_IDLE : UDINT := 0;
	STATE_INIT : UDINT := 1;
	STATE_RUN  : UDINT := 10;
	STATE_DONE : UDINT := 500;
	STATE_ERROR : UDINT := 1000;
END_VAR

poqDATAOUT := ADR(m_data);

IF Execute THEN
	IF NOT m_oldExecute THEN
		SMC_OutQueueInit(ADR(m_data));

        // Checks of input parameters and additional initialization can
        // be done here.
        IF featureFlag > 31 THEN
			m_state := STATE_ERROR;
			ErrorID := SMC_INVALID_FEATURE_FLAG;
        ELSIF maxAngularVelocity_deg <= 0 THEN
            m_state := STATE_ERROR;
            ErrorID := SMC_INVALID_PARAMETER;
		ELSE
			m_featureFlag := featureFlag;
            m_maxAngularVelocity_rad := maxAngularVelocity_deg * SMC_FACTOR_DEG_TO_RAD;
            velMin := -1;
		    m_state := STATE_INIT;
        END_IF
		OnExit();
		RETURN;
	END_IF
ELSIF NOT Execute AND m_state >= STATE_DONE THEN
    m_state := STATE_IDLE;
    ErrorID := SMC_NO_ERROR;
    OnExit();
    RETURN;
END_IF

/// Cyclically copy the pointers. This is done to support
/// an online change where objects can move in memory.
m_data.pbyBuffer := pbyBufferOutQueue;
xdwAddr := m_data.pbyBuffer;
IF (xdwAddr MOD 4) > 0 THEN
    m_state := STATE_ERROR;
    ErrorID := SMC_GEOINFO_BUFFER_MISALIGNED;
    OnExit();
	RETURN;
END_IF

SMC_SetQueueCapacity(ADR(m_data), nSizeOutQueue);

IF m_state = STATE_IDLE THEN
	OnExit();
	RETURN;
ELSIF m_state = STATE_INIT THEN
	// Wait until input queue has been set by previous
	// path processing function block
	IF poqDataIn <> 0 THEN
		m_state := STATE_RUN;
	END_IF
END_IF

IF STATE_IDLE < m_state AND m_state < STATE_DONE THEN
	IF poqDataIn = 0 OR pbyBufferOutQueue = 0 OR nSizeOutQueue = 0 THEN
		OnExit();
		RETURN;
	ELSIF poqDataIn^.wOUTQUEUEStructID <> 16#9878 THEN
		m_state := STATE_ERROR;
		ErrorID := SMC_NO_OUTQUEUE_TYPE;
		OnExit();
		RETURN;
	END_IF
	m_data.strProgramName := poqDataIn^.strProgramName;

	// output queue full -> wait
	IF poqDataIn^.nCapacity = 0 OR m_data.bFull THEN
		OnExit();
		RETURN;
	END_IF

	// Wait until input queue is filled
	IF (NOT poqDataIn^.bEndOfList AND NOT poqDataIn^.bFull) OR_ELSE
       SMC_GetCount(poqDataIn) = 0
    THEN
		m_data.bEndOfList := poqDataIn^.bEndOfList;
		IF m_data.bEndOfList THEN
			m_state := STATE_DONE;
		END_IF
		OnExit();
		RETURN;
	END_IF
END_IF

CASE m_state OF
STATE_RUN:
	pgeo := SMC_GetObj(poqDataIn, 0);

    // Handle G75 (queue synchronization) which will empty the queue of
	// all preprocessing blocks until the interpolator has reached the
	// lookahead.
    IF pgeo^.iMoveType = SMC_MOVTYP.MCOMMAND AND pgeo^.iHelpID[0] = -3 THEN (* queue emptied *)
        SMC_DeleteObj(poqDataIn, 0);
        OnExit();
        RETURN;
    ELSIF pgeo^.iMoveType = SMC_MOVTYP.MCOMMAND AND pgeo^.iHelpID[0] = -2 THEN (* queue filling object *)
		ErrorID := SMC_OutQueue_AppendChecked(m_data, pgeo^);
        IF ErrorID <> SMC_NO_ERROR THEN
			m_state := STATE_ERROR;
		END_IF
		// Signal to previous FB that the G75 has been processed
        pgeo^.iHelpID[0] := -3;
        OnExit();
        RETURN;
    END_IF

    // Our velocity limitation comes here. This modifies an element from the
    // input queue and copies the modified element to the output queue.
    // Finally, the element is removed from the input queue

	// Copy the element.  This is done to avoid accidentally modifying an element
	// from the input queue, which is not recommended.
    m_geo := pgeo^;

    // Note: the feature flags set in the G-Code with G38/G39 can be queried
    // by reading m_geo.dwFeatureFlags, like this:
    IF (SHR(m_geo.dwFeatureFlags, m_featureFlag) AND 1) = 1 THEN
        // feature is turned on

        ok := ComputeMaxCurvature(m_geo, kappa=> kappa_max);
        IF NOT ok THEN
            // Curvature cannot be computed
            m_state := STATE_ERROR;
		    ErrorID := SMC_INVALID_PARAMETER;
		    OnExit();
		    RETURN;
		END_IF

        // Compute maximum allowed path velocity based on maximum curvature
        // and maximum allowed angular velocity
        IF kappa_max = 0 THEN
            // No curvature, no limitation necessary
            vel := m_geo.dVel;
        ELSE
            vel := m_maxAngularVelocity_rad / kappa_max;
		END_IF

        IF velMin < 0 OR vel < velMin THEN
            velMin := vel;
		END_IF

        // Set new maximum velocity for the element
        m_geo.dVel := MIN(m_geo.dVel, vel);
	END_IF

	ErrorID := SMC_OutQueue_AppendChecked(m_data, m_geo);

    IF ErrorID <> SMC_NO_ERROR THEN
        m_state := STATE_ERROR;
    ELSE
		SMC_DeleteObj(poqDataIn, 0);

		IF SMC_GetCount(poqDataIn) = 0 AND_THEN poqDataIn^.bEndOfList THEN
			m_data.bEndOfList := TRUE;
			m_state := STATE_DONE;
		END_IF
	END_IF
END_CASE

OnExit();