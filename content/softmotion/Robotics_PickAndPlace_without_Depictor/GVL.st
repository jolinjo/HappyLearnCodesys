(* 
    檔案用途：定義本範例中 Tripod 機器人、輸送帶與旋轉工作台的幾何位置常數，
              以及用來切換「自動／手動放環」的全域旗標。
    教學重點：這些數值會直接影響實際運動軌跡與畫面位置，修改前請先對照
              `DeviceTree_Axes.md` 與各 POU 程式中的使用方式再調整。
*)
VAR_GLOBAL CONSTANT
	gcTripodTransX : LREAL := 0;
	gcTripodTransY : LREAL := 0;
	gcTripodTransZ : LREAL := 1700;

	gcTripodSize : LREAL := 180;

	gcBeltTransX : LREAL := 0;
	gcBeltTransY : LREAL := 500;
	gcBeltTransZ : LREAL := 0;

	gcTableTransX : LREAL := 0;
	gcTableTransY : LREAL := -500;
	gcTableTransZ : LREAL := 0;

	gcTCP_Ring : LREAL := 0.02 * gcTripodSize + 15;

	gcTripod1PosOrig : LREAL := 50;
	gcTripod2PosOrig : LREAL := 75;
	gcTripod3PosOrig : LREAL := 25;
END_VAR
VAR_GLOBAL
	gbSetRing : BOOL;
	gbAutomatic : BOOL := TRUE;
END_VAR