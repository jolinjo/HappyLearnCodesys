/// 這是 GearInPos 範例的主控程式，負責：
/// 1. 啟動三個軸（Master 輸送帶軸、Slave 鋸片滑台軸、Tool 刀具上下軸）的伺服驅動。
/// 2. 以固定速度驅動輸送帶（Master 軸）前進。
/// 3. 在光遮斷器偵測到工件後，利用 MC_GearInPos 讓鋸片滑台（Slave 軸）在指定位置與輸送帶同步。
/// 4. 控制刀具（Tool 軸）完成一次切割動作，並將鋸片滑台與刀具移回安全待命位置。
PROGRAM PLC_PRG
VAR
    /// 控制 Tool 軸（刀具上下移動）的電源功能塊。
    pwTool   : MC_Power := (bRegulatorOn:= TRUE, bDriveStart:= TRUE);
    /// 控制 Master 軸（輸送帶）的電源功能塊。
    pwMaster : MC_Power := (bRegulatorOn:= TRUE, bDriveStart:= TRUE);
    /// 控制 Slave 軸（鋸片滑台）的電源功能塊。
    pwSlave  : MC_Power := (bRegulatorOn:= TRUE, bDriveStart:= TRUE);

    /// 用於在指定位置讓 Slave 軸與 Master 軸進行齒輪同步的功能塊。
    gearInPos: MC_GearInPos := (
         RatioNumerator:= 1,
         RatioDenominator:= 1);

    /// 控制輸送帶（Master 軸）以固定速度運轉的速度模式運動命令。
	moveBelt : MC_MoveVelocity := (
        Velocity:= 250,
        Acceleration:= 500,
        Deceleration:= 500,
        Jerk:= 5000);

    /// 控制刀具（Tool 軸）上下移動的絕對位置運動命令。
    moveTool : MC_MoveAbsolute := (
        Velocity:= 500,
        Acceleration:= 10000,
        Deceleration:= 10000,
        Jerk:= 200000) ;

    /// 控制鋸片滑台（Slave 軸）回到待命位置的絕對位置運動命令。
    moveSlave : MC_MoveAbsolute := (
        Velocity:= 400,
        Acceleration:= 5000,
        Deceleration:= 5000,
        Jerk:= 100000) ;

    /// 主狀態機，決定目前處於哪一個控制階段。
	state : UDINT;
END_VAR
VAR CONSTANT
	/// 軸上電與伺服準備階段。
	STATE_POWER : UDINT := 0;
	/// 等待工件被光遮斷器偵測到。
	STATE_WAIT_FOR_WORKPIECE : UDINT := 10;
    /// 已下達 GearInPos 命令，等待 Master 與 Slave 軸真正進入同步。
    STATE_WAIT_FOR_SYNC : UDINT := 20;
    /// 刀具由原點移動到切削位置。
    STATE_MOVE_TOOL_0 : UDINT := 30;
    /// 刀具由切削位置返回原點。
    STATE_MOVE_TOOL_1 : UDINT := 40;
    /// 鋸片滑台回到待命位置。
    STATE_MOVE_TO_REST : UDINT := 50;
END_VAR

/// 依照不同狀態執行對應的軸控制與命令切換。
CASE state OF
STATE_POWER:
    /// 依序啟動三個軸的電源與驅動，等待皆準備就緒。
    pwTool.Enable := TRUE;
    pwMaster.Enable := TRUE;
    pwSlave.Enable := TRUE;

    IF pwTool.Status AND pwMaster.Status AND pwSlave.Status
    THEN
        /// 當三個軸皆就緒後，啟動輸送帶以固定速度前進，並進入等待工件的狀態。
        moveBelt.Execute := TRUE;
        state := STATE_WAIT_FOR_WORKPIECE;
    END_IF

STATE_WAIT_FOR_WORKPIECE:
    /// 一旦模擬程式回報偵測到工件，即準備計算齒輪同步的關鍵位置。
    IF SimulateWorkpiece.WorkpieceDetected THEN
        /// MasterSyncPosition：以目前 Master 位置為基準，再加上工件從光遮斷器到同步點的距離，
        ///                     並略為提前 10% 工件長度，讓切割動作在工件進入同步位置前啟動。
        gearInPos.MasterSyncPosition := Master.fSetPosition + (Const.SYNCPOS - Const.LIGHTBARRIERPOS) + Const.WORKPIECELENGTH*0.1;
        /// SlaveSyncPosition：Slave 軸達到此位置時，即與 Master 軸進入同步狀態。
        gearInPos.SlaveSyncPosition:= Const.SYNCPOS;
        /// MasterStartDistance：當 Master 再前進一定距離後才真正執行齒輪同步，避免命令一下達就立即啟動。
        gearInPos.MasterStartDistance := 0.75*(Const.SYNCPOS - Const.LIGHTBARRIERPOS);
        /// 下達齒輪同步命令，進入等待同步完成的狀態。
        gearInPos.Execute := TRUE;
        state := STATE_WAIT_FOR_SYNC;
    END_IF

STATE_WAIT_FOR_SYNC:
    /// 當 GearInPos 回報已進入同步狀態，代表鋸片滑台與輸送帶已對齊。
    IF gearInPos.InSync THEN
        /// 將刀具移至帶寬加上刀尖偏移的位置，模擬切入工件。
        moveTool.Position := Const.BELTWIDTH + Const.TIPOFFSET;
        moveTool.Execute := TRUE;
        state := STATE_MOVE_TOOL_0;
    END_IF

STATE_MOVE_TOOL_0:
    /// 刀具到達切削位置後，關閉 Execute，準備指令返回原點。
    IF moveTool.Done THEN
        moveTool.Execute := FALSE;
        state := STATE_MOVE_TOOL_1;
    END_IF

STATE_MOVE_TOOL_1:
    /// 將刀具目標位置設回 0（原點），啟動回程。
    moveTool.Position := 0;
    moveTool.Execute := TRUE;

    IF moveTool.Done THEN
        /// 切割動作完成後，關閉齒輪同步與刀具運動命令，
        /// 再讓鋸片滑台移往較安全的待命位置。
        gearInPos.Execute := FALSE;
        moveTool.Execute := FALSE;
        moveSlave.Execute := TRUE;
        moveSlave.Position := 0.5*(Const.SYNCPOS + Const.LIGHTBARRIERPOS);
        state := STATE_MOVE_TO_REST;
    END_IF

STATE_MOVE_TO_REST:
    /// 鋸片滑台回到待命位置後，關閉命令並回到等待下一塊工件的狀態。
    IF moveSlave.Done THEN
        moveSlave.Execute := FALSE;
        state := STATE_WAIT_FOR_WORKPIECE ;
    END_IF
END_CASE

/// 將電源功能塊實際連接到三個軸上。
pwTool(Axis:= Tool);
pwMaster(Axis:= Master);
pwSlave(Axis:= Slave);

/// 持續以速度模式驅動輸送帶（Master 軸）。
moveBelt(Axis:= Master);

/// 在 Master 與 Slave 之間建立齒輪同步關係。
gearInPos(Master:= Master, Slave:= Slave);

/// 控制刀具與鋸片滑台的點到點移動。
moveTool(Axis:= Tool);
moveSlave(Axis:= Slave);