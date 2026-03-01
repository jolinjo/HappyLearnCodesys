(* 
    檔案用途：
      作為 Tripod_PlanningTask 任務掛載的主程式佔位元，對應到 DeviceTree 中
      Tripod 軸組的運動規劃。原始 XML 中此程式內容極少，本範例主要將
      運動邏輯放在 Robot 與相關 FB 中。
    教學重點：
      - 認識「規劃任務」與「主控制任務」可以分開掛載不同 PROGRAM。
      - 在實際專案中，這裡可以擴充為離線軌跡產生、路徑平滑化等較重的運算。
*)
PROGRAM Tripod_PlanningPrg

;