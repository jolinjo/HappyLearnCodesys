(* 
    檔案用途：
      定義一具 3 自由度 Scara+Z 機構的動力學模型，包含各連桿的幾何尺寸、
      質量、慣性矩與螺旋軸（screw axes），並實作 SMDYN.ISMDynamics 介面，
      供 SoftMotion 的動力學模組計算關節扭矩與負載效應。
    教學重點：
      - 觀察 m_aM（各連桿質心座標）、m_aG（空間慣性）、m_aS（螺旋軸）三組資料的物理意義。
      - 理解 DOF 與臂長／質量等常數，如何對應到實際 Scara 幾何結構。
      - 作為自訂機構動力學定義的範例，供其他機構參考套用。
*)
FUNCTION_BLOCK DynModel_Scara2_Z IMPLEMENTS SMDYN.ISMDynamics
VAR CONSTANT
	/// Degrees of freedom.
	DOF : DINT := 3;
	/// All length values in [m]
	armOneLength : LREAL := 0.4;
	armTwoLength : LREAL := 0.3;
	baseHeight : LREAL := 0.6;
	armOneHeight : LREAL := 0.06;
	armTwoHeight : LREAL := 0.06;
	zAxisLength : LREAL := 0.3;
	zAxisOffset : LREAL := -0.05;
	/// All mass values in [kg]
	armOneMass : LREAL := 3;
	armTwoMass : LREAL := 4;
	zAxisMass : LREAL := 1;

	/// The home position of all link frames. |aM[i]| contains
    /// the frame of the ith link expressed in the coordinates of the
    /// (i-1)th link frame.
    /// All frames are expected to be situated at the link's center
    /// of mass.
    m_aM : ARRAY[0..SMRB.MAX_VEC_DIM] OF SM3M.SMC_Frame := [
        /// All values of vT in [m]
        ///
        /// The center of mass of arm 1 expressed in the base coordinate system 0:
        (mR:= (
            aElems:= [
                1, 0, 0,
                0, -1, 0,
                0, 0, -1]),
         vT:= (dX:= armOneLength / 2.0, dY:= 0, dZ:= baseHeight + armOneHeight / 2.0)),
        /// The center of mass of arm 2 expressed in the coordinate system of arm 1:
        (mR:= (
            aElems:= [
                1, 0, 0,
                0, 1, 0,
                0, 0, 1]),
         vT:= (dX:= armOneLength / 2.0 + armTwoLength / 2.0, dY:= 0, dZ:= armOneHeight / 2.0 + armTwoHeight / 2.0)),
        /// The center of mass of the z-axis expressed in the coordinate system of arm 2:
        (mR:= (
            aElems:= [
                1, 0, 0,
                0, 1, 0,
                0, 0, 1]),
         vT:= (dX:= armTwoLength / 2.0, dY:= 0, dZ:= zAxisLength / 2.0 - armTwoHeight / 2.0 + zAxisOffset)),
        /// One additional array entry, to handle an arbitrary load at the TCP, expressed
		/// in the coordinate system of the z-axis.
        (mR:= (
            aElems:= [
                1, 0, 0,
                0, 1, 0,
                0, 0, 1]),
         vT:= (dX:= 0, dY:= 0, dZ:= - zAxisLength / 2.0))];

	/// The spatial inertia matrices of all links, expressed in the
    /// respectives link's frame.
    m_aG : ARRAY[0..SMRB.MAX_VEC_DIM-1] OF SMDYN.DynSpatialInertia := [
        /// All inertia values in [kg m²]
        /// and all mass values in [kg]
        /// Arm 1
        (I:= (
            aElems:= [
                0, 0, 0,
                0, 1/12.0 * armOneMass * armOneLength * armOneLength, 0,
                0, 0, 1/12.0 * armOneMass * armOneLength * armOneLength]),
         m:= armOneMass),
        /// Arm 2
        (I:= (
            aElems:= [
                0, 0, 0,
                0, 1/12.0 * armTwoMass * armTwoLength * armTwoLength, 0,
                0, 0, 1/12.0 * armTwoMass * armTwoLength * armTwoLength]),
         m:= armTwoMass),
        /// z-axis
        (I:= (
            aElems:= [
                1/12.0 * zAxisMass * zAxisLength * zAxisLength, 0, 0,
                0, 1/12.0 * zAxisMass * zAxisLength * zAxisLength, 0,
                0, 0, 0]),
         m:= zAxisMass)];

	/// The screw axes of all joints, expressed in the base frame.
    m_aS : ARRAY[0..SMRB.MAX_VEC_DIM-1] OF TwistVec := [
		/// Angular velocities in [rad/s] and linear velocities in [m/s].
        /// Screw axis of arm 1
        (w:= (dX:= 0, dY:= 0, dZ:= 1),
         v:= (dX:= 0, dY:= 0, dZ:= 0)),
        /// Screw axis of arm 2
        (w:= (dX:= 0, dY:= 0, dZ:= 1),
         v:= (dX:= 0, dY:= -armOneLength, dZ:= 0)),
        /// Screw axis of the z-axis
        (w:= (dX:= 0, dY:= 0, dZ:= 0),
         v:= (dX:= 0, dY:= 0, dZ:= 1))];
END_VAR
VAR
    /// The home position of all link frames. |m_aM_inv[i]| contains
    /// the frame of the (i-1) link expressed in the coordinates of the
    /// ith link frame.
    /// All frames are expected to be situated at the link's center
    /// of mass.
    m_aM_inv : ARRAY[0..SM3M.SMC_MAX_VEC_DIM] OF SM3M.SMC_Frame;
    /// The screw axes of all joints, expressed in the link's frame.
    m_aA : ARRAY[0..SM3M.SMC_MAX_VEC_DIM-1] OF TwistVec;
END_VAR