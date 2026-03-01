(*
    檔案用途：
      在規劃任務中呼叫 SMC_TuneCPKernel，設定 SoftMotion 規劃器的預測時間，
      讓 SMC_GroupReadTrigger 能夠在觸發點到達前一段時間就算出 triggerTime。
    教學重點：
      - 認識「規劃任務」在 Trigger 範例中的角色：負責路徑規劃核心參數，而非直接控制軸。
      - fPlanningForecastDuration 設為 0.1 秒，對應到 MainTask 4ms 週期，約可提前 25 個週期得知觸發時間。
*)
PROGRAM Planning_PRG
VAR_OUTPUT
    initDone : BOOL;
END_VAR
VAR
    tuneCpKernel : SMC_TuneCPKernel;
END_VAR

// Set the fPlanningForecastDuration to 100ms. This makes it possible for SMC_GroupReadTrigger to
// report the triggerTime 100ms before the trigger point will be reached.
tuneCpKernel(AxisGroup:= axisGroup, Execute:= TRUE, fPlanningForecastDuration:= 0.1);
initDone := tuneCpKernel.Done;