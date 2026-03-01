(*
    檔案用途：
      計算用於可視化的標記座標陣列 aafPos，讓視覺介面能畫出輸送帶路徑
      以及 Tripod 運動軌跡的參考線。
    教學重點：
      - 透過 Tripod_Lin_Depictor 取得 Tripod 軸組的線性插補資訊，作為可視化基底。
      - 使用 SIN、COS 與多段 if/else 邏輯，組合出一條封閉的輸送帶路徑。
      - 練習將實際軸位置（DriveConveyorBelt.fSetPosition 等）轉換成畫面上的座標點。
*)
PROGRAM DepictorCalculations
VAR_OUTPUT
	aafPos : ARRAY[0..9] OF ARRAY[0..1] OF LREAL;
END_VAR
VAR
	dep : Tripod_Lin_Depictor;
	fTemp : LREAL;
	i : INT;
END_VAR

//tripod
IF Robot.state >= 40 THEN
	dep(group := Tripod, kin := Tripod.trafo);
END_IF

//markings on belt
FOR i := 0 TO 9 DO
	fTemp := DriveConveyorBelt.fSetPosition + INT_TO_LREAL(i) / 10 * DriveConveyorBelt.fPositionPeriod;
	IF fTemp >= DriveConveyorBelt.fPositionPeriod THEN
		fTemp := fTemp - DriveConveyorBelt.fPositionPeriod;
	END_IF

	IF fTemp <= 1000 THEN
		aafPos[i][0] := fTemp;
		aafPos[i][1] := 50;
	ELSE
		fTemp := fTemp - 1000;
		IF fTemp < 50 * SMC_PI THEN
			aafPos[i][0] := 1000 + 50 * SIN(fTemp / 50);
			aafPos[i][1] := 50 * COS(fTemp / 50);
		ELSE
			fTemp := fTemp - 50 * SMC_PI;
			IF fTemp <= 2000 THEN
				aafPos[i][0] := 1000 - fTemp;
				aafPos[i][1] := -50;
			ELSE
				fTemp := fTemp - 2000;
				IF fTemp < 50 * SMC_PI THEN
					aafPos[i][0] := -1000 - 50 * SIN(fTemp / 50);
					aafPos[i][1] := -50 * COS(fTemp / 50);
				ELSE
					fTemp := fTemp - 50 * SMC_PI;
					aafPos[i][0] := -1000 + fTemp;
					aafPos[i][1] := 50;
				END_IF
			END_IF
		END_IF
	END_IF
END_FOR