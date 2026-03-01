(*
    檔案用途：
      與基礎 Triggers 範例類似，在規劃任務中呼叫 SMC_TuneCPKernel，
      但這裡的預測時間 fPlanningForecastDuration 根據 GVL.MAX_TRIGGER_FORECAST_DURATION 動態決定，
      以涵蓋膠閥與 UV 燈兩種不同延遲的最大值。
    教學重點：
      - 從觸發應用的角度理解「規劃器預測時間」與「周邊設備延遲」之間的關係。
      - 認識如何透過 GVL 將機台整體時序需求集中配置，再由 Planning_PRG 套用到規劃核心。
*)
PROGRAM Planning_PRG
VAR_OUTPUT
    initDone : BOOL;
END_VAR
VAR
    tuneCPKernel : SMC_TuneCPKernel;
END_VAR

tuneCPKernel(
    AxisGroup:= AxisGroup,
    Execute:= TRUE,
    fPlanningForecastDuration:= GVL.MAX_TRIGGER_FORECAST_DURATION);

initDone := tuneCPKernel.Done;