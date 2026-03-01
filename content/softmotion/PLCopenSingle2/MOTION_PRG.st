// MOTION_PRG：示範同時準備速度模式與絕對定位的運動控制功能塊
// 在這個範例中只宣告並初始化 MC_Power、MC_MoveVelocity、MC_MoveAbsolute，實際呼叫可能在其他程式或可視化中完成
PROGRAM MOTION_PRG
VAR
	// mcp：軸上電與啟動用的 MC_Power 功能塊，預設啟用 Enable/調節器/啟動軸
	mcp: MC_Power := (
		Enable := TRUE,
		bRegulatorOn := TRUE,
		bDriveStart := TRUE
	);
	// mcmv：速度模式運動用的 MC_MoveVelocity，預設速度 100、加減速度 100，方向為正向
	mcmv: MC_MoveVelocity := (
		Velocity := 100,
		Acceleration := 100,
		Deceleration := 100,
		Direction := positive
	);
	// mcma：絕對定位用的 MC_MoveAbsolute，預設目標位置 180、速度 100、加減速度 100，方向為正向
	mcma: MC_MoveAbsolute := (
		Position := 180,
		Velocity := 100,
		Acceleration := 100,
		Deceleration := 100,
		Direction := positive
	);
END_VAR