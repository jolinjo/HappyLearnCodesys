/// 此程式在獨立的 BuilderTask 中建立一條凸輪曲線，
/// 並透過 WriteMulticoreSafe() 將結果寫入全域的 GVL.safeCam，
/// 讓 MainTask 可以在另一個任務中安全地讀取並建立 Cam 表。
PROGRAM MultitaskCamBuilder
VAR_INPUT
    /// 外部觸發旗標：當為 TRUE 時執行一次凸輪建立流程。
    BuildCam : BOOL;
END_VAR
VAR_OUTPUT
    /// 若建立或寫入過程出現錯誤則為 TRUE。
    Error : BOOL;
    /// 儲存 CamBuilder 或 WriteMulticoreSafe 回傳的錯誤碼。
    ErrorId : SMC_ERROR;
END_VAR
VAR
    /// 用來在 BuilderTask 中建立凸輪的建構器物件。
    camBuilder : SMCB.CamBuilder;
END_VAR

/// 僅在 BuildCam 被置位時執行一次建立流程，完成後自動清回 FALSE。
IF BuildCam THEN
    /// 立即清除觸發旗標，避免同一次觸發被重複處理。
    BuildCam := FALSE;

    /// 初始化建構器，清除舊有段落。
    camBuilder.Init();
    /// 依序組出與線上建立相同的三段凸輪：
    /// 1. 起始 Poly5，從隱含邊界平順啟動。
    camBuilder.Append(SMCB.Poly5(SMCB.BoundImplicit(), SMCB.BoundImplicit()));
    /// 2. 中間線性段：Master 從 160 到 200、Slave 從 140 到 220、加速度限制 2。
    camBuilder.Append(SMCB.Line(SMCB.Bound(160, 140, 2), SMCB.Bound(200, 220, 2)));
    /// 3. 結束 Poly5，平順收斂到 (360,360)，速度收斂為 0。
    camBuilder.Append(SMCB.Poly5(SMCB.BoundImplicit(), SMCB.Bound(360, 360, 0, 0)));

    /// 先檢查建構器本身是否已有錯誤。
	Error := camBuilder.IsErrorPending(errorID=> ErrorId);

    IF NOT Error THEN
        /// 將建立好的凸輪以「多工安全」方式寫入 GVL.safeCam，
        /// 之後可由其他任務使用 GetCopy() 取出實際凸輪資料。
        ErrorId := camBuilder.WriteMulticoreSafe(GVL.safeCam);
        Error := ErrorId <> SMC_NO_ERROR;
    END_IF
END_IF