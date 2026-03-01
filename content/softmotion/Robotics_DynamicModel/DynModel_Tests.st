(* 
    檔案用途：
      透過 Test_DynModel_Scara2_Z 功能塊，對 Scara 動力學模型做單元測試，
      包含檢查螺旋軸定義（CheckScrewAxis）與靜止扭矩計算（CheckStandstillTorque）。
    教學重點：
      - 示範如何以簡單狀態機包裝一組動力學測試，將結果輸出為 successful / error。
      - 幫助使用者在將模型套用到 PLC_PRG 前，先驗證模型本身是否合理。
*)
PROGRAM DynModel_Tests
VAR_OUTPUT
	successful: BOOL;
	error : BOOL;
END_VAR
VAR
	state : INT;
	tester : Test_DynModel_Scara2_Z;
END_VAR

CASE state OF
	0:
		IF tester.CheckScrewAxis() THEN
			state := state + 10;
		ELSE
			state := state + 1000;
		END_IF

	10:
		IF tester.CheckStandstillTorque() THEN
			state := state + 10;
		ELSE
			state := state + 1000;
		END_IF

	20:
		state := 100;
END_CASE

successful := state = 100;
error := state >= 1000;