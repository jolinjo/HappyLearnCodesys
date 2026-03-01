(* 
    檔案用途：定義本範例中三角機器人、輸送帶與旋轉工作台的幾何位置常數，
              以及用來切換「自動／手動放環」的全域旗標。
    教學重點：這些數值會直接影響實際運動軌跡與畫面位置，修改前請先對照
              `DeviceTree_Axes.md` 與各 POU 程式中的使用方式再調整。
*)
VAR_GLOBAL CONSTANT
    gcTripodTransX : LREAL := 0;       // Tripod 機構在世界座標中的 X 平移量
    gcTripodTransY : LREAL := 0;       // Tripod 機構在世界座標中的 Y 平移量
    gcTripodTransZ : LREAL := 1700;    // Tripod 機構在世界座標中的 Z 平移量（機器人高度）

    gcTripodSize : LREAL := 180;       // Tripod 幾何尺寸基準，影響工作空間與 TCP 半徑

    gcBeltTransX : LREAL := 0;         // 輸送帶座標系（PCS_2）在世界座標中的 X 位置
    gcBeltTransY : LREAL := 500;       // 輸送帶座標系在世界座標中的 Y 位置
    gcBeltTransZ : LREAL := 0;         // 輸送帶座標系在世界座標中的 Z 位置

    gcTableTransX : LREAL := 0;        // 旋轉工作台座標系（PCS_1）在世界座標中的 X 位置
    gcTableTransY : LREAL := -500;     // 旋轉工作台座標系在世界座標中的 Y 位置
    gcTableTransZ : LREAL := 0;        // 旋轉工作台座標系在世界座標中的 Z 位置

    gcTCP_Ring : LREAL := 0.02 * gcTripodSize + 15;   // 末端工具座標系到圓環下緣的距離

    gcTripod1PosOrig : LREAL := 50;    // Tripod1 初始軸位置
    gcTripod2PosOrig : LREAL := 75;    // Tripod2 初始軸位置
    gcTripod3PosOrig : LREAL := 25;    // Tripod3 初始軸位置
END_VAR
VAR_GLOBAL
    gbSetRing : BOOL;                  // TRUE：由操作者手動要求在轉盤上放一個新環
    gbAutomatic : BOOL := TRUE;        // TRUE：環依邏輯自動連續產生；FALSE：完全由 gbSetRing 控制
END_VAR