/// 本全域常數表定義輸送帶、工件與鋸片工具的幾何尺寸與同步位置，供 BasicMotion_GearInPos 範例的所有程式共用。
{attribute 'qualified_only'}
VAR_GLOBAL CONSTANT
    /// 鋸片與工件同步時的 X 座標位置。
    SYNCPOS : LREAL := 0;

    /// 光遮斷器在輸送帶座標系下的 X 座標位置。
    LIGHTBARRIERPOS : LREAL := -300;

    /// 工件的幾何尺寸（長、寬、高，單位 mm）。
    WORKPIECELENGTH : LREAL := 200;
    WORKPIECEWIDTH : LREAL := 120;
    WORKPIECEHEIGHT : LREAL := 10;

    /// 輸送帶的外觀尺寸（長、寬、高，單位 mm）。
    BELTLENGTH : LREAL:= 1000;
    BELTWIDTH : LREAL:= 150;
    BELTHEIGHT : LREAL:= 50;

    /// 鋸片切削端相對於連桿末端的偏移距離（單位 mm）。
    TIPOFFSET : LREAL := 8 ;
END_VAR