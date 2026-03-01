/// 此程式示範在同一條主軸（Master）上，使用三種不同的 CamIn 啟動模式
/// 來啟動三個從軸（SlaveAbsolute、SlaveRampIn、SlaveRampInDist），方便比較各種 Cam 啟動行為。
/// - 先啟動 Master 軸以速度模式運轉
/// - 讀取 Master 目前實際位置
/// - 依不同設定啟動 CamTableSelect 與 CamIn 功能塊
/// - 搭配 R_TRIG 只在「上緣」時觸發一次啟動命令
PROGRAM PLC_PRG
VAR
	/// 控制 Master 與三個從軸上電的電源功能塊。
	pwMaster: MC_Power;
	pwSlaveAbsolute: MC_Power;
	pwSlaveRampIn: MC_Power;
	pwSlaveRampInDist: MC_Power;

	/// 控制 Master 以速度模式運轉，以及讀取 Master 實際位置的功能塊。
	mvMaster: MC_MoveVelocity;
	rapMaster: MC_ReadActualPosition;

	/// 三個從軸對應的 CamTableSelect，用來選擇不同的凸輪表。
	ctsSlaveAbsolute: MC_CamTableSelect;
	ctsSlaveRampIn: MC_CamTableSelect;
	ctsSlaveRampInDist: MC_CamTableSelect;
	/// 三個從軸對應的 CamIn 功能塊，用來決定何時、以何種模式啟動凸輪運動。
	ciSlaveAbsolute: MC_CamIn;
	ciSlaveRampIn: MC_CamIn;
	ciSlaveRampInDist: MC_CamIn;

	/// 用來偵測「開始凸輪」命令的上升沿，避免重複觸發。
	R_TRIG_StartCamming: R_TRIG;
END_VAR