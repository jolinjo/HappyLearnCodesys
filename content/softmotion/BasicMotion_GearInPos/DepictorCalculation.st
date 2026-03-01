/// 此程式負責將輸送帶的幾何形狀與當前位置轉換成可視化元件，供 3D/2D 視覺化畫面使用。
/// 透過 BeltDepictor 功能塊與 Master 軸的位置，讓使用者在視覺化畫面上看到輸送帶隨 Master 軸移動。
PROGRAM DepictorCalculation
VAR
    /// 表示輸送帶外觀與位置的描繪功能塊。
    beltFB : BeltDepictor :=
        (posOrigin:= (dX:= 0, dY:= 0, dZ:= 0),
         length:= Const.BELTLENGTH,
         width:= Const.BELTWIDTH,
         height:= Const.BELTHEIGHT);
END_VAR

/// 以 Master 軸的實際位置驅動描繪功能塊，更新輸送帶在畫面上的位置。
beltFB(beltPos:= Master.fSetPosition);