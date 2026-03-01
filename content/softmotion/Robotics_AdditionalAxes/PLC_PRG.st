(* 
    檔案用途：
      示範如何在一個軸組中同時控制主軸（X/Y/Z）與兩個附加軸（DriveAdd1、DriveAdd2），
      透過 MC_MoveDirectAbsolute 與 MC_MoveLinearAbsolute 指令，實作「主軸路徑＋附加軸距離」的同步運動。
    教學重點：
      - 觀察 POS1 / POS2 與 DIST1 / DIST2 的搭配，理解附加軸位置如何隨主軸路徑一起變化。
      - 認識 MC_GroupReadActualPosition / MC_GroupReadActualVelocity 如何讀出主軸與附加軸的即時狀態供 Trace 觀察。
      - 練習在簡單範例中思考：當增加附加軸時，如何保持路徑描述清楚且參數集中管理。
*)
PROGRAM PLC_PRG
VAR
    movePTP: MC_MoveDirectAbsolute := (
        CoordSystem:= SMC_COORD_SYSTEM.MCS,
        BufferMode:= MC_BUFFER_MODE.Buffered);

	moveLin: MC_MoveLinearAbsolute := (
        Velocity:= 100,
        Acceleration:= 7000,
        Deceleration:= 7000,
        Jerk:= 100000,
        CoordSystem:= SMC_COORD_SYSTEM.MCS,
        BufferMode:= MC_BUFFER_MODE.BlendingHigh);

	POS1 : SMC_POS_REF := (c:= (X:= 50, Y:= 50));
    DIST1 : SMC_ADDITIONAL_AXES_VALUES_ARRAY := [10, 20];

    POS2 : SMC_POS_REF := (c:= (X:= 50, Y:= -50));
    DIST2 : SMC_ADDITIONAL_AXES_VALUES_ARRAY := [-10, -20];

    pw : SMC_GroupPower;
    en : MC_GroupEnable;
    readPos : MC_GroupReadActualPosition := (
        CoordSystem:= SMC_COORD_SYSTEM.MCS);

    readVel : MC_GroupReadActualVelocity := (
        CoordSystem:= SMC_COORD_SYSTEM.MCS);

	sv: SMC_StartVelocity;

    Ready: BOOL;
END_VAR