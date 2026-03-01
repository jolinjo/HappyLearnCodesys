(* 
    檔案用途：
      封裝一個 Jog 功能塊，讓使用者可以同時在「軸空間（ACS）」與「笛卡兒空間（MCS）」下
      以按鍵方式點動 Gantry3C 自訂運動學的 TCP 位置。
    教學重點：
      - 利用兩個 SMC_GroupJog2 實例（jog_mcs、jog_axes）分別處理 TCP Jog 與關節 Jog。
      - 理解來自視覺介面的按鍵輸入（Jog_TCP_*、Jog_Drive_*）如何對應到 Forward/Backward 陣列。
      - 作為「自訂運動學上層 Jog 介面」的範例，可套用到其他 kinematics。
*)
/// This FB combines jogging in both axis space as well as cartesian space.
/// It uses two instances of SMC_GroupJog2. One for axis space and the other for cartesian space.
/// This FB can be used along with the visu templates V_RobotPosition_axes
/// and V_RobotPosition_cart_Jog to jog any kinematics in cartesian and axis space.

FUNCTION_BLOCK Jog
VAR_IN_OUT
	/// Reference to Axisgroup
	AxisGroup : AXIS_GROUP_REF_SM3;
END_VAR
VAR_INPUT
	/// Inputs (from the visu) to jog the robot in cartesian space
	Jog_TCP_Xp : BOOL;
	Jog_TCP_Xn : BOOL;
	Jog_TCP_Yp : BOOL;
	Jog_TCP_Yn : BOOL;
	Jog_TCP_Zp : BOOL;
	Jog_TCP_Zn : BOOL;
	Jog_TCP_Ap : BOOL;
	Jog_TCP_An : BOOL;
	Jog_TCP_Bp : BOOL;
	Jog_TCP_Bn : BOOL;
	Jog_TCP_Cp : BOOL;
	Jog_TCP_Cn : BOOL;

	/// Inputs (from the visu) to jog the robot in axis space
	Jog_Drive_Xp : BOOL;
	Jog_Drive_Xn : BOOL;
	Jog_Drive_Yp : BOOL;
	Jog_Drive_Yn : BOOL;
	Jog_Drive_Zp : BOOL;
	Jog_Drive_Zn : BOOL;
	Jog_Drive_Cp : BOOL;
	Jog_Drive_Cn : BOOL;

END_VAR
VAR
	/// SMC_GroupJog2 for cartesian space
	jog_mcs : SMC_GroupJog2 :=(Enable := TRUE, MaxLinearDistance := 2, MaxAngularDistance := 1,
							VelFactor := 1, AccFactor := 1, JerkFactor := 1,
							Velocity := 100, Acceleration := 1000, Deceleration := 1000, Jerk := 1000,
						    CoordSystem:= SMC_COORD_SYSTEM.MCS);

	/// SMC_GroupJog2 for axes space
	jog_axes : SMC_GroupJog2 :=(Enable := TRUE, MaxLinearDistance := 2, MaxAngularDistance := 1,
							VelFactor := 1, AccFactor := 1, JerkFactor := 1,
							Velocity := 100, Acceleration := 1000, Deceleration := 1000, Jerk := 1000,
						    CoordSystem:= SMC_COORD_SYSTEM.ACS);
END_VAR

jog_mcs.Forward[0] := Jog_TCP_Xp;
jog_mcs.Forward[1] := Jog_TCP_Yp;
jog_mcs.Forward[2] := Jog_TCP_Zp;
jog_mcs.Forward[3] := Jog_TCP_Ap;
jog_mcs.Forward[4] := Jog_TCP_Bp;
jog_mcs.Forward[5] := Jog_TCP_Cp;

jog_mcs.Backward[0] := Jog_TCP_Xn;
jog_mcs.Backward[1] := Jog_TCP_Yn;
jog_mcs.Backward[2] := Jog_TCP_Zn;
jog_mcs.Backward[3] := Jog_TCP_An;
jog_mcs.Backward[4] := Jog_TCP_Bn;
jog_mcs.Backward[5] := Jog_TCP_Cn;

jog_axes.Forward[0] := Jog_Drive_Xp;
jog_axes.Forward[1] := Jog_Drive_Yp;
jog_axes.Forward[2] := Jog_Drive_Zp;
jog_axes.Forward[3] := Jog_Drive_Cp;

jog_axes.Backward[0] := Jog_Drive_Xn;
jog_axes.Backward[1] := Jog_Drive_Yn;
jog_axes.Backward[2] := Jog_Drive_Zn;
jog_axes.Backward[3] := Jog_Drive_Cn;

jog_mcs(AxisGroup := Axisgroup);
jog_axes(AxisGroup := Axisgroup);