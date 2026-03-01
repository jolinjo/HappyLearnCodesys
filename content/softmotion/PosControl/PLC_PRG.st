// PLC_PRG：位置控制（PosControl）範例主程式
// 透過 MC_Power、MC_MoveVelocity、MC_MoveRelative 等功能塊，示範對 SM_Drive_PosControl 軸進行速度與位置控制
PROGRAM PLC_PRG
VAR
	// mcp：基本上電與啟用用的 MC_Power 功能塊，預設 Enable=TRUE
	mcp: MC_Power := (Enable := TRUE);
	// mcmv：速度模式運動用的 MC_MoveVelocity，預設以 360 單位/秒 的速度運轉
	mcmv: MC_MoveVelocity := (
		Velocity := 360,
		Acceleration := 1000,
		Deceleration := 1000
	);
	// mcr：重置軸錯誤與狀態的 MC_Reset 功能塊
	mcr: MC_Reset;
	// mcsp：設定當前實際位置為指定位置的 MC_SetPosition 功能塊
	mcsp: MC_SetPosition;
	// mcmr：相對移動用的 MC_MoveRelative，預設距離 360、速度 360、加減速度 1000
	mcmr: MC_MoveRelative := (
		Distance := 360,
		Velocity := 360,
		Acceleration := 1000,
		Deceleration := 1000
	);
END_VAR

// 將軸 SM_Drive_PosControl 的實際啟動/調節器狀態旗標強制為 TRUE，
// 模擬實際硬體已經準備就緒，方便在模擬環境下進行測試
SM_Drive_PosControl.in.bDriveStartRealState := TRUE;
SM_Drive_PosControl.in.bRegulatorRealState := TRUE;

// 週期性呼叫各個運動控制功能塊，讓它們持續對 SM_Drive_PosControl 軸產生對應的控制效果
mcp(Axis := SM_Drive_PosControl);
mcmv(Axis := SM_Drive_PosControl);
mcr(Axis := SM_Drive_PosControl);
mcsp(Axis := SM_Drive_PosControl);
mcmr(Axis := SM_Drive_PosControl);

