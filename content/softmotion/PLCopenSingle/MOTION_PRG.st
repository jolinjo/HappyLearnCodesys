// MOTION_PRG：單軸往返絕對定位範例主程式
// 在虛擬軸 Drive 上先移動到正向位置 p，再移回原點，透過 iStatus 狀態機反覆執行
PROGRAM MOTION_PRG
VAR
	// iStatus：控制整個運動流程的狀態機編號（0=上電、1=移到 p、2=移回 0）
	iStatus: INT;
	// Power：對軸 Drive 送出啟動命令的 MC_Power 功能塊
	Power: MC_Power;
	// MoveAbsolute：對軸 Drive 送出絕對定位命令的 MC_MoveAbsolute 功能塊
	MoveAbsolute: MC_MoveAbsolute;
	// p：目標位置，單位為軸所對應的工程單位（例如度、mm），預設為 100
	p: REAL := 100;
END_VAR

// 依目前 iStatus 狀態，決定要執行哪一段運動流程
CASE iStatus OF
// 狀態 0：先對軸 Drive 上電並啟動
0:
	// 持續呼叫 Power，要求啟用調節器與啟動軸
	Power(Enable := TRUE, bRegulatorOn := TRUE, bDriveStart := TRUE, Axis := Drive);
	// 當 Power.Status 變為 TRUE，代表軸已經成功上電並可控制
	IF Power.Status THEN
		// 進入下一個狀態：準備做第一次 MoveAbsolute
		iStatus := iStatus + 1;
	END_IF

// 狀態 1：從目前位置移動到目標位置 p
1:
	// 持續以 Execute=TRUE 呼叫 MoveAbsolute，命令軸移動到位置 p
	MoveAbsolute(
		Execute := TRUE,
		Position := p,
		Velocity := 100,
		Acceleration := 100,
		Deceleration := 100,
		Axis := Drive
	);
	// Done 變為 TRUE 表示運動已完成
	IF MoveAbsolute.Done THEN
		// 將 Execute 設為 FALSE 讓指令結束，避免持續佔用功能塊
		MoveAbsolute(Execute := FALSE, Axis := Drive);
		// 進入下一個狀態：從 p 移回原點 0
		iStatus := iStatus + 1;
	END_IF

// 狀態 2：從位置 p 移回位置 0
2:
	// 再次使用 MoveAbsolute，這次目標位置改為 0
	MoveAbsolute(
		Execute := TRUE,
		Position := 0,
		Velocity := 100,
		Acceleration := 100,
		Deceleration := 100,
		Axis := Drive
	);
	// 第二次運動完成後
	IF MoveAbsolute.Done THEN
		// 結束本次 MoveAbsolute 命令
		MoveAbsolute(Execute := FALSE, Axis := Drive);
		// 將狀態改回 1，形成「p 與 0 之間往返運動」的循環
		iStatus := 1;
	END_IF
END_CASE