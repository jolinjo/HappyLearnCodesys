// MOTION_PRG：雙凸輪表交替同步範例主程式
// 使用虛擬主軸 Virtual 帶動從軸 Drive，透過 CamIn1 / CamIn2 與兩份凸輪表 Example1 / Example2
// 示範如何在不中斷運動的情況下，平順地在兩個凸輪曲線之間來回切換
PROGRAM MOTION_PRG
VAR
	// Power：對從軸 Drive 上電與啟動的 MC_Power 功能塊（Enable/Regulator/DriveStart 預設為 TRUE）
	// PowerVirtual：對虛擬主軸 Virtual 上電與啟動的 MC_Power 功能塊
	Power, PowerVirtual : MC_Power := (
		Enable := TRUE,
		bRegulatorOn := TRUE,
		bDriveStart := TRUE
	);
	// MoveVirtual：以速度模式驅動虛擬主軸 Movement 的 MC_MoveVelocity 功能塊
	// 預設速度為 1，具備加減速度與 Jerk 設定，讓運動更平順
	MoveVirtual : MC_MoveVelocity := (
		Velocity := 1,
		Acceleration := 100,
		Deceleration := 100,
		Jerk := 1000
	);
	// TableSelect1 / TableSelect2：分別用來選取 Example1 / Example2 兩份凸輪表的功能塊
	TableSelect1 : MC_CamTableSelect;
	TableSelect2 : MC_CamTableSelect;
	// CamIn1 / CamIn2：實際把從軸 Drive 依照凸輪表與虛擬主軸 Virtual 同步的功能塊
	CamIn1 : MC_CamIn;
	CamIn2 : MC_CamIn;
	
	// state：控制整體流程的狀態機（0=上電、10=選表並啟動、20/30=在兩個 CamIn 之間交替）
	state : INT;
END_VAR
VAR CONSTANT
	// STATE_POWER_ON：系統上電與虛擬軸/從軸準備完成前的狀態
	STATE_POWER_ON : INT := 0;
	// STATE_START_SYNC：選取兩份凸輪表並啟動第一個 CamIn，同步開始運動的狀態
	STATE_START_SYNC : INT := 10;
	// STATE_RESTART_CAM_IN_1：在 CamIn2 已經接手控制時，準備重新啟動 CamIn1 的狀態
	STATE_RESTART_CAM_IN_1 : INT := 20;
	// STATE_RESTART_CAM_IN_2：在 CamIn1 已經接手控制時，準備重新啟動 CamIn2 的狀態
	STATE_RESTART_CAM_IN_2 : INT := 30;
END_VAR

// 週期性呼叫 Power 與 PowerVirtual，確保 Drive 與 Virtual 軸都維持在上電啟動狀態
Power(Axis := Drive);
PowerVirtual(Axis := Virtual);

// 依 state 狀態決定目前要執行哪一段多凸輪交替流程
CASE state OF
// STATE_POWER_ON：等待兩個軸都成功上電
STATE_POWER_ON:
	// 當 Drive 與 Virtual 同時完成 Power.Status，代表可進入下一步設定凸輪同步
	IF Power.Status AND PowerVirtual.Status THEN
		state := STATE_START_SYNC;
	END_IF

// STATE_START_SYNC：選取兩份凸輪表並啟動第一個 CamIn，同時啟動虛擬主軸
STATE_START_SYNC:
	// 兩個凸輪表都使用 MasterAbsolute = FALSE、SlaveAbsolute = FALSE，
	// 可以在兩個表之間切換時，自動讓從軸運動盡量平順、不產生速度突變。
	TableSelect1(
		Execute := TRUE,
		Master := Virtual,
		Slave := Drive,
		CamTable := Example1,
		Periodic := FALSE,
		MasterAbsolute := FALSE,
		SlaveAbsolute := FALSE
	);
	// 將 TableSelect1 產生的 CamTableID 指派給 CamIn1
	CamIn1.CamTableID := TableSelect1.CamTableID;

	// 同樣方式選取第二份凸輪表 Example2，對應 CamIn2
	TableSelect2(
		Execute := TRUE,
		Master := Virtual,
		Slave := Drive,
		CamTable := Example2,
		Periodic := FALSE,
		MasterAbsolute := FALSE,
		SlaveAbsolute := FALSE
	);
	CamIn2.CamTableID := TableSelect2.CamTableID;

	// 等兩個 TableSelect 都完成後，啟動第一個 CamIn，並啟動虛擬主軸
	IF TableSelect1.Done AND TableSelect2.Done THEN
		// 先以距離模式 ramp_in_dist 啟動 CamIn1，使進入同步時的速度變化更平順
		CamIn1.StartMode := ramp_in_dist;
		CamIn1.MasterSyncPosition := 2;
		CamIn1.MasterStartDistance := 1;
		CamIn1.Execute := TRUE;

		// 啟動虛擬主軸的速度模式運動
		MoveVirtual.Execute := TRUE;

		// 完成初次同步之後，準備在 CamIn1 / CamIn2 之間交替接手控制
		state := STATE_RESTART_CAM_IN_2;
	END_IF

// STATE_RESTART_CAM_IN_1：當 CamIn2 正在控制從軸時，重新啟動 CamIn1，讓它在適當時機接手
STATE_RESTART_CAM_IN_1:
	IF CamIn2.Active THEN
		// 當 CamIn2 處於 Active 狀態時，先呼叫一次 CamIn1(Execute:=FALSE)
		// 讓功能塊結束前一次命令，準備以 Buffered 方式重新啟動
		CamIn1(Master := Virtual, Slave := Drive, Execute := FALSE);

		// 這次以 relative 模式與緩衝模式 Buffered 重新啟動 CamIn1，
		// 讓它在 CamIn2 結束輪廓時平順接手從軸控制權。
		CamIn1.StartMode := relative;
		CamIn1.BufferMode := MC_BUFFER_MODE.Buffered;
		CamIn1.Execute := TRUE;

		// 下一輪改由 CamIn2 準備重新啟動，形成兩個凸輪表交替的循環
		state := STATE_RESTART_CAM_IN_2;
	END_IF

// STATE_RESTART_CAM_IN_2：當 CamIn1 正在控制從軸時，重新啟動 CamIn2，讓它在適當時機接手
STATE_RESTART_CAM_IN_2:
	IF CamIn1.Active THEN
		// 當 CamIn1 處於 Active 狀態時，先結束前一次 CamIn2 命令
		CamIn2(Master := Virtual, Slave := Drive, Execute := FALSE);

		// 同樣以 relative 模式與 Buffered 緩衝方式啟動 CamIn2，
		// 好讓它在 CamIn1 結束輪廓時平順接手控制權
		CamIn2.StartMode := relative;
		CamIn2.BufferMode := MC_BUFFER_MODE.Buffered;
		CamIn2.Execute := TRUE;

		// 下一輪再由 CamIn1 準備重新啟動，持續在兩個凸輪表之間切換
		state := STATE_RESTART_CAM_IN_1;
	END_IF
END_CASE

// 週期性呼叫 MoveVirtual，讓虛擬主軸維持在速度模式運動
MoveVirtual(Axis := Virtual);

// 週期性呼叫 CamIn1 與 CamIn2，讓兩個功能塊依目前設定控制從軸 Drive
CamIn1(Master := Virtual, Slave := Drive);
CamIn2(Master := Virtual, Slave := Drive);

// 當 CamIn2 報告 EndOfProfile，代表第二份凸輪表執行完畢，
// 此時再呼叫一次 CamIn1 讓它接手控制權，以實現輪流接手的行為
IF CamIn2.EndOfProfile THEN
	CamIn1(Master := Virtual, Slave := Drive);
END_IF