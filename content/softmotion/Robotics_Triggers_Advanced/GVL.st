{attribute 'qualified_only'}
(* 
    檔案用途：
      定義與觸發計時相關的全域常數，包括匯流排週期時間與觸發預測最大時間。
    教學重點：
      - BUS_CYCLE_TIME_IN_US / BUS_CYCLE_TIME_IN_S：提供 TriggerWithTimeShift 參考的基礎時間單位。
      - MAX_TRIGGER_FORECAST_DURATION：根據膠閥與 UV 燈的延遲，自動計算規劃器需要預測的最長時間。
*)
VAR_GLOBAL CONSTANT
    /// 匯流排週期時間（微秒）。
    BUS_CYCLE_TIME_IN_US : DWORD := 4000;
    /// 匯流排週期時間（秒）。
    BUS_CYCLE_TIME_IN_S : LREAL := TO_LREAL(BUS_CYCLE_TIME_IN_US) * 1E-6;
    /// 規劃器需預測的最大觸發時間，取膠閥與 UV 燈延遲的較大值。
    MAX_TRIGGER_FORECAST_DURATION : LREAL := MAX(GlueApplication.GLUE_ON_OFF_DELAY, GlueApplication.UV_LAMP_OFF_DELAY);
END_VAR