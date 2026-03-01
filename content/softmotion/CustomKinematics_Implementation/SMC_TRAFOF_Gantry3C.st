(* 
    檔案用途：
      針對 Gantry3C 自訂運動學，將各軸的實際位置（DriveX/Y/Z/C）轉換為 TCP 位置（dx,dy,dz,dAzimuth），
      並依照設定的 min/max 範圍做正規化，方便在視覺模板中顯示。
    教學重點：
      - 理解 Offset（dOffset*）與 min/max 顯示範圍如何影響可視化座標。
      - 觀察正規化流程如何把實際座標壓縮到 -1..1 或類似比例，方便視窗呈現。
      - 作為自訂 Kinematics 用於視覺化轉換的範例，未牽涉運動控制本身。
*)
/// This FB transforms the input axes values of a Gantry3C Transformation to its respective TCP values.
/// Additionally the axes values are normalised to be used along with the visualization template
/// TRAFOF_Gantry3C_YZ to visualize the movements of the kinematics.
FUNCTION_BLOCK SMC_TRAFOF_Gantry3C
VAR_IN_OUT
    /// Reference to X-axis
    DriveX: AXIS_REF_SM3;
    /// Reference to Y-axis
    DriveY: AXIS_REF_SM3;
    /// Reference to Z-axis
    DriveZ: AXIS_REF_SM3;
    /// Reference to A-axis
    DriveC: AXIS_REF_SM3;
END_VAR
VAR_INPUT
    /// Offset position for X-axis
    dOffsetX:LREAL;
    /// Offset position for Y-axis
    dOffsetY:LREAL;
    /// Offset position for Z-axis
    dOffsetZ:LREAL;
    /// Offset position for A-axis
    dOffsetA:LREAL;
    /// Minimum display area of axis X for visualization
    minX:LREAL;
    /// Maximal display area of axis X for visualization
    maxX:LREAL;
    /// Minimum display area of axis Y for visualization
    minY:LREAL;
    /// Maximal display area of axis Y for visualization
    maxY:LREAL;
    /// Minimum display area of axis Z for visualization
	minZ:LREAL;
    /// Maximal display area of axis Z for visualization
	maxZ : LREAL;

END_VAR
VAR_OUTPUT
    /// position of the TCP in X axis
    dx: LREAL;
    /// position of the TCP in Y axis
    dy: LREAL;
    /// position of the TCP in Z axis
	dz: LREAL;
    /// position of the TCP in C axis
	dAzimuth:LREAL;
END_VAR
VAR
	/// normalised position
    dnx, dny, dnz:LREAL;
    dnxt, dnyt, dnzt:LREAL;
	sAz, cAz : LREAL;
    dm: LREAL;
END_VAR

dx:=DriveX.fActPosition-dOffsetX;
dy:=DriveY.fActPosition-dOffsetY;
dz:=DriveZ.fActPosition-dOffsetZ;
dAzimuth:=DriveC.fActPosition-dOffsetA;

sAz := SIN(dAzimuth/180.0*SMC_PI);
cAz := COS(dAzimuth/180.0*SMC_PI);

IF maxx > minx AND maxy > miny AND maxZ > minZ THEN
	dm := MAX(ABS(maxx), ABS(minx));
	dm := MAX(dm, ABS(maxy));
	dm := MAX(dm, ABS(miny));
	dm := MAX(dm, ABS(maxz));
	dm := MAX(dm, ABS(minz));

	dnx := (DriveX.fActPosition-dOffsetX)/dm;
	dny := (DriveY.fActPosition-dOffsetY)/dm;
	dnz := (DriveZ.fActPosition-dOffsetZ)/dm;


	dnxt := dx/dm;
	dnyt := dy/dm;
	dnzt := dz/dm;
END_IF
