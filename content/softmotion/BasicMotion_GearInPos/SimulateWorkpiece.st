/// 此程式負責在沒有實體感測器與工件的情況下，模擬一塊工件在輸送帶上移動，
/// 並依據工件與光遮斷器的相對位置，輸出「是否偵測到工件」的訊號與工件中心位置。
PROGRAM SimulateWorkpiece
VAR_INPUT
    /// 光遮斷器在輸送帶座標系下的 X 位置（單位 mm）。
    LightBarrierPos : LREAL := Const.LIGHTBARRIERPOS ;
    /// 工件的長度（單位 mm）。
    WorkpieceLength : LREAL := CONST.WORKPIECELENGTH ;
END_VAR
VAR_OUTPUT
    /// 當工件經過光遮斷器時，此輸出為 TRUE。
    WorkpieceDetected : BOOL ;
    /// 工件中心在輸送帶座標系下的 X 位置。
    WorkPiecePos : LREAL ;
END_VAR
VAR
    /// 工件模擬的狀態機，目前是「初始化」或「工件運行中」。
    state : UDINT;
    /// 用來記錄 Master 軸在工件產生當下的位置，用於處理位置換算與週期性回捲。
    masterOffset : LREAL;
END_VAR
VAR CONSTANT
    /// 初始化狀態：產生一塊新的工件並重設位置。
    STATE_INIT : UDINT := 0;
    /// 工件正在輸送帶上移動的狀態。
    STATE_WORKPIECE_ACTIVE : UDINT := 10;
END_VAR

/// 依狀態機決定工件當前位置與是否需要重新產生工件。
CASE state OF
STATE_INIT:
    /// 將工件中心放在輸送帶左端外側，準備讓輸送帶帶動工件往右移動。
    WorkPiecePos := -Const.BELTLENGTH/2;
    /// 記錄此時 Master 軸的位置，作為後續換算的基準點。
    masterOffset := Master.fSetPosition;
    /// 進入工件運行狀態。
    state := STATE_WORKPIECE_ACTIVE;

STATE_WORKPIECE_ACTIVE:
    /// 若 Master 軸位置因為週期性回捲而小於基準值，將基準值往回平移一個週期，維持連續位移。
    IF Master.fSetPosition < masterOffset THEN
        masterOffset := masterOffset - Master.fPositionPeriod ;
    END_IF

    /// 依 Master 軸位移量計算工件中心在輸送帶上的實際位置。
    WorkPiecePos := -Const.BELTLENGTH/2 + (Master.fSetPosition - masterOffset);

    /// 當工件通過輸送帶右端（加上一半工件長度）時，重新回到初始化狀態，準備下一塊工件。
    IF WorkPiecePos >= Const.BELTLENGTH/2 - WorkpieceLength/2 THEN
        state := STATE_INIT;
    END_IF
END_CASE

/// 當工件區間覆蓋到光遮斷器位置時，即視為「感測到工件」。
WorkpieceDetected :=
    WorkPiecePos - WorkpieceLength/2 <= LightBarrierPos AND
    WorkPiecePos + WorkpieceLength/2 >= LightBarrierPos;