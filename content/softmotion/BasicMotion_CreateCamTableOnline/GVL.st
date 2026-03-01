/// 本全域變數表用來儲存「多工安全」的凸輪參考物件，
/// 讓在 BuilderTask 中建立的凸輪可以安全地分享給 MainTask 使用。
{attribute 'qualified_only'}
VAR_GLOBAL
    /// 透過 CamBuilder.WriteMulticoreSafe() 寫入的安全凸輪參考，
    /// 內含凸輪 ID 與在多核、多任務環境下安全複製所需的資訊。
    safeCam : SMCB.CAM_REF_MULTICORE_SAFE;
END_VAR