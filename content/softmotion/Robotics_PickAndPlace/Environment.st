(*
    檔案用途：
      負責「環境」相關的裝置控制，包括旋轉工作台與輸送帶的驅動，
      並管理所有圓錐（Cone）與圓環（Ring）的狀態機，提供給機器人程式使用。
    教學重點：
      - 將與機器人本體無關、但會影響工作流程的設備集中在一支 PROGRAM 中管理。
      - 觀察如何透過 FUNCTION_BLOCK 實例（Cone、Ring）與指標，建立物件之間的關聯。
      - 使用簡單的初始化旗標 bInit 來區分「第一次循環」與「正常運轉」的寫法。
*)
PROGRAM Environment
VAR_OUTPUT
	cone1, cone2, cone3 : Cone;
	ring1, ring2 : Ring;
	bRingOnTable : BOOL;
	pActiveCone : POINTER TO Cone;	//the cone corresponding to PCS_2
END_VAR
VAR
	powRotaryTable : MC_Power := (Enable := TRUE, bRegulatorOn := TRUE, bDriveStart := TRUE);
	powConveyorBelt : MC_Power := (Enable := TRUE, bRegulatorOn := TRUE, bDriveStart := TRUE);
	mvRotaryTable : MC_MoveVelocity := (Execute := TRUE, Velocity := 50, Acceleration := 30, Deceleration := 30, Jerk := 1000);
	mvConveyorBelt : MC_MoveVelocity := (Execute := TRUE, Velocity := 300, Acceleration := 150, Deceleration := 150, Jerk := 1000);

	ring1StartPos : MC_COORD_REF := (X := 75, Y := 100, Z := 0);
	ring2StartPos : MC_COORD_REF := (X := -75, Y := 100, Z := 0);
	bInit : BOOL := TRUE;
END_VAR

//moving rotary-table-/ conveyor-belt-drive
powRotaryTable(Axis := DriveRotaryTable);
powConveyorBelt(Axis := DriveConveyorBelt);
IF NOT (powRotaryTable.Status AND powConveyorBelt.Status) THEN
	RETURN;
END_IF
mvRotaryTable(Axis := DriveRotaryTable);
mvConveyorBelt(Axis := DriveConveyorBelt);

//state-machines of cones / handling of PCS_2
IF bInit THEN
	cone1.Start();
END_IF
cone1(pActiveCone := pActiveCone, pPreviousCone := ADR(cone3));
cone2(pActiveCone := pActiveCone, pPreviousCone := ADR(cone1));
cone3(pActiveCone := pActiveCone, pPreviousCone := ADR(cone2));

//state-machines of rings / handling of PCS_1
IF bInit THEN
	ring1.startPos := ring1StartPos;
	ring2.startPos := ring2StartPos;
END_IF
ring1(pOtherRing := ADR(ring2));
ring2(pOtherRing := ADR(ring1));
bRingOnTable := ring1.bOnTable OR ring2.bOnTable;

bInit := FALSE;