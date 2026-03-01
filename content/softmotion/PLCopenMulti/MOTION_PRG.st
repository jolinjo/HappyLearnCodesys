// MOTION_PRG：多軸凸輪（Cam）同步範例的主控制程式
// 主要負責準備兩個軸的上電、選取凸輪表、啟動 CamIn 同步，以及以虛擬主軸帶動從軸運動
PROGRAM MOTION_PRG
VAR
	// power1, power2：對實體軸與虛擬軸分別上電的 MC_Power 功能塊
	power1, power2: MC_Power;
	// TableSelect：從函式庫中選取欲使用的凸輪表（Cam Table）的功能塊
	TableSelect: MC_CamTableSelect;
	// CamIn：根據選取的凸輪表，讓從軸跟隨主軸的凸輪同步功能塊
	CamIn: MC_CamIn;
	// Tappet：用來取得某一位置是否落在特定凸輪段內的 SMC_GetTappetValue 函數
	Tappet: SMC_GetTappetValue;
	// MoveVirtual：對虛擬主軸送出速度模式命令的 MC_MoveVelocity 功能塊
	MoveVirtual: MC_MoveVelocity;
END_VAR