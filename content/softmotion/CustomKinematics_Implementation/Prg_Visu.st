(* 
    檔案用途：
      建立一個簡單的測試與視覺程式，用來驗證自訂 Gantry3C 運動學：
      - 啟動並啟用 AxisGroup；
      - 提供線性與直接移動指令（mla、mda）；
      - 呼叫 Jog FB 讓使用者在 MCS / ACS 中點動 TCP 或關節；
      - 呼叫 SMC_TRAFOF_Gantry3C 計算並正規化 TCP 位置，供視覺模板顯示。
    教學重點：
      - 將自訂 kinematics（Gantry3C）與 Jog、視覺化整合成一個可互動的測試環境。
      - 觀察 AxisGroup Power / Enable 流程與 jog、mla、mda 之間的關係。
*)
/// This is a simple program to test the Gantry3C kinematics.
/// The visualization can be used to Jog the robot(in axis and cartesian space) and command movements like
/// MC_MoveLinearAbsolute and MC_MoveDirectAbsolute.
/// The axisgroup will be powered and enabled immediately when the application is started so that the user
/// can start controlling the robot directly
PROGRAM Prg_Visu
VAR
	gpow : SMC_GroupPower :=(Enable := TRUE, bRegulatorOn := TRUE, bDriveStart := TRUE) ;
	gen : MC_GroupEnable;

	mla : MC_MoveLinearAbsolute :=(Velocity := 100, Acceleration := 1000, Deceleration := 1000, Jerk := 10000,
								   CoordSystem := SMC_COORD_SYSTEM.MCS);
	mda : MC_MoveDirectAbsolute :=(CoordSystem := SMC_COORD_SYSTEM.MCS);

	istate : INT;

	Gantry3C_Visu_Calc : SMC_TRAFOF_Gantry3C;
	jog : jog;

END_VAR

CASE istate OF
0:
	IF gpow.Status THEN
		gen.Execute := TRUE;
		istate := istate +10;
	END_IF
10:
	IF gen.Done THEN
		istate := istate +10;
	END_IF

END_CASE

gpow(AxisGroup := AxisGroup);
gen(AxisGroup := Axisgroup);
jog(AxisGroup := Axisgroup);
mla(AxisGroup := Axisgroup);
mda(Axisgroup := AxisGroup);
Gantry3C_Visu_Calc(	DriveX:= DriveX, DriveY:= DriveY, DriveZ:= DriveZ, DriveC:=DriveC,
					minX:= -10, maxX:= 500, minY:= -10, maxY:= 500, minZ := -10, maxZ := 500);

