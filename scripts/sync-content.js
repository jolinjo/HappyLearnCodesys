// 同步現有教學 Markdown 檔到 tutorial-site/content 目錄的工具腳本
// 執行位置預期為專案根目錄：node tutorial-site/scripts/sync-content.js

import fs from "fs";
import path from "path";

/** @typedef {{ source: string; target: string }} Mapping */

/** @type {Mapping[]} */
const mappings = [
  // SoftMotion 總覽與學習地圖
  {
    source: "ExampleFile/CODESYS_SoftMotion_官網教學與範例總覽.md",
    target:
      "tutorial-site/content/softmotion/CODESYS_SoftMotion_官網教學與範例總覽.md",
  },
  // SoftMotion 範例說明（檔名：範例英文名稱_整體架構與功能.md）
  // PLCopen
  { source: "ExampleFile/PLCopenSingle/PLCopenSingle_整體架構與功能.md", target: "tutorial-site/content/softmotion/PLCopenSingle/PLCopenSingle_整體架構與功能.md" },
  { source: "ExampleFile/PLCopenSingle2/PLCopenSingle2_整體架構與功能.md", target: "tutorial-site/content/softmotion/PLCopenSingle2/PLCopenSingle2_整體架構與功能.md" },
  { source: "ExampleFile/PLCopenMulti/PLCopenMulti_整體架構與功能.md", target: "tutorial-site/content/softmotion/PLCopenMulti/PLCopenMulti_整體架構與功能.md" },
  { source: "ExampleFile/PLCopenMultiCAM/PLCopenMultiCAM_整體架構與功能.md", target: "tutorial-site/content/softmotion/PLCopenMultiCAM/PLCopenMultiCAM_整體架構與功能.md" },
  { source: "ExampleFile/PosControl/PosControl_整體架構與功能.md", target: "tutorial-site/content/softmotion/PosControl/PosControl_整體架構與功能.md" },
  // BasicMotion
  { source: "ExampleFile/BasicMotion_GearInPos/BasicMotion_GearInPos_整體架構與功能.md", target: "tutorial-site/content/softmotion/BasicMotion_GearInPos/BasicMotion_GearInPos_整體架構與功能.md" },
  { source: "ExampleFile/BasicMotion_CamIn_StartModes/BasicMotion_CamIn_StartModes_整體架構與功能.md", target: "tutorial-site/content/softmotion/BasicMotion_CamIn_StartModes/BasicMotion_CamIn_StartModes_整體架構與功能.md" },
  { source: "ExampleFile/BasicMotion_SynchronizedMotion/BasicMotion_SynchronizedMotion_整體架構與功能.md", target: "tutorial-site/content/softmotion/BasicMotion_SynchronizedMotion/BasicMotion_SynchronizedMotion_整體架構與功能.md" },
  { source: "ExampleFile/BasicMotion_Override/BasicMotion_Override_整體架構與功能.md", target: "tutorial-site/content/softmotion/BasicMotion_Override/BasicMotion_Override_整體架構與功能.md" },
  { source: "ExampleFile/BasicMotion_CamExportAndImport/BasicMotion_CamExportAndImport_整體架構與功能.md", target: "tutorial-site/content/softmotion/BasicMotion_CamExportAndImport/BasicMotion_CamExportAndImport_整體架構與功能.md" },
  { source: "ExampleFile/BasicMotion_CreateCamTableOnline/BasicMotion_CreateCamTableOnline_整體架構與功能.md", target: "tutorial-site/content/softmotion/BasicMotion_CreateCamTableOnline/BasicMotion_CreateCamTableOnline_整體架構與功能.md" },
  { source: "ExampleFile/BasicMotion_DigitalCamSwitch_HighPrecision/BasicMotion_DigitalCamSwitch_HighPrecision_整體架構與功能.md", target: "tutorial-site/content/softmotion/BasicMotion_DigitalCamSwitch_HighPrecision/BasicMotion_DigitalCamSwitch_HighPrecision_整體架構與功能.md" },
  { source: "ExampleFile/BasicMotion_Forecast/BasicMotion_Forecast_整體架構與功能.md", target: "tutorial-site/content/softmotion/BasicMotion_Forecast/BasicMotion_Forecast_整體架構與功能.md" },
  // Robotics
  { source: "ExampleFile/Robotics_PickAndPlace/Robotics_PickAndPlace_整體架構與功能.md", target: "tutorial-site/content/softmotion/Robotics_PickAndPlace/Robotics_PickAndPlace_整體架構與功能.md" },
  { source: "ExampleFile/Robotics_PickAndPlace_without_Depictor/Robotics_PickAndPlace_without_Depictor_整體架構與功能.md", target: "tutorial-site/content/softmotion/Robotics_PickAndPlace_without_Depictor/Robotics_PickAndPlace_without_Depictor_整體架構與功能.md" },
  { source: "ExampleFile/Robotics_Jogging/Robotics_Jogging_整體架構與功能.md", target: "tutorial-site/content/softmotion/Robotics_Jogging/Robotics_Jogging_整體架構與功能.md" },
  { source: "ExampleFile/Robotics_Triggers/Robotics_Triggers_整體架構與功能.md", target: "tutorial-site/content/softmotion/Robotics_Triggers/Robotics_Triggers_整體架構與功能.md" },
  { source: "ExampleFile/Robotics_Triggers_Advanced/Robotics_Triggers_Advanced_整體架構與功能.md", target: "tutorial-site/content/softmotion/Robotics_Triggers_Advanced/Robotics_Triggers_Advanced_整體架構與功能.md" },
  { source: "ExampleFile/Robotics_Interrupt_Continue/Robotics_Interrupt_Continue_整體架構與功能.md", target: "tutorial-site/content/softmotion/Robotics_Interrupt_Continue/Robotics_Interrupt_Continue_整體架構與功能.md" },
  { source: "ExampleFile/Robotics_AdditionalAxes/Robotics_AdditionalAxes_整體架構與功能.md", target: "tutorial-site/content/softmotion/Robotics_AdditionalAxes/Robotics_AdditionalAxes_整體架構與功能.md" },
  { source: "ExampleFile/Robotics_DynamicModel/Robotics_DynamicModel_整體架構與功能.md", target: "tutorial-site/content/softmotion/Robotics_DynamicModel/Robotics_DynamicModel_整體架構與功能.md" },
  // 機構學
  { source: "ExampleFile/CustomKinematics_Implementation/CustomKinematics_Implementation_整體架構與功能.md", target: "tutorial-site/content/softmotion/CustomKinematics_Implementation/CustomKinematics_Implementation_整體架構與功能.md" },
  // CNC
  { source: "ExampleFile/CNC01_direct/CNC01_direct_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC01_direct/CNC01_direct_整體架構與功能.md" },
  { source: "ExampleFile/CNC02_online/CNC02_online_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC02_online/CNC02_online_整體架構與功能.md" },
  { source: "ExampleFile/CNC03_prepro/CNC03_prepro_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC03_prepro/CNC03_prepro_整體架構與功能.md" },
  { source: "ExampleFile/CNC04_table/CNC04_table_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC04_table/CNC04_table_整體架構與功能.md" },
  { source: "ExampleFile/CNC05_File/CNC05_File_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC05_File/CNC05_File_整體架構與功能.md" },
  { source: "ExampleFile/CNC06_File_3DPath/CNC06_File_3DPath_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC06_File_3DPath/CNC06_File_3DPath_整體架構與功能.md" },
  { source: "ExampleFile/CNC07_Subprogram/CNC07_Subprogram_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC07_Subprogram/CNC07_Subprogram_整體架構與功能.md" },
  { source: "ExampleFile/CNC08_AdditionalAxes/CNC08_AdditionalAxes_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC08_AdditionalAxes/CNC08_AdditionalAxes_整體架構與功能.md" },
  { source: "ExampleFile/CNC09_ToolLengthCorr/CNC09_ToolLengthCorr_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC09_ToolLengthCorr/CNC09_ToolLengthCorr_整體架構與功能.md" },
  { source: "ExampleFile/CNC10_DynamicPath/CNC10_DynamicPath_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC10_DynamicPath/CNC10_DynamicPath_整體架構與功能.md" },
  { source: "ExampleFile/CNC11_CustomFunctions/CNC11_CustomFunctions_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC11_CustomFunctions/CNC11_CustomFunctions_整體架構與功能.md" },
  { source: "ExampleFile/CNC12_TokenModifier/CNC12_TokenModifier_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC12_TokenModifier/CNC12_TokenModifier_整體架構與功能.md" },
  { source: "ExampleFile/CNC13_ReadInterpolatorState/CNC13_ReadInterpolatorState_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC13_ReadInterpolatorState/CNC13_ReadInterpolatorState_整體架構與功能.md" },
  { source: "ExampleFile/CNC14_PathPreprocessing/CNC14_PathPreprocessing_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC14_PathPreprocessing/CNC14_PathPreprocessing_整體架構與功能.md" },
  { source: "ExampleFile/CNC15_LargeGCode/CNC15_LargeGCode_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC15_LargeGCode/CNC15_LargeGCode_整體架構與功能.md" },
  { source: "ExampleFile/CNC16_G31/CNC16_G31_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC16_G31/CNC16_G31_整體架構與功能.md" },
  { source: "ExampleFile/CNC17_ReadGCodeFromStrings/CNC17_ReadGCodeFromStrings_整體架構與功能.md", target: "tutorial-site/content/softmotion/CNC17_ReadGCodeFromStrings/CNC17_ReadGCodeFromStrings_整體架構與功能.md" },
  // 授權相關
  {
    source: "授權相關/01_RTE環境與支援硬體.md",
    target:
      "tutorial-site/content/licensing/01_RTE環境與支援硬體.md",
  },
  {
    source: "授權相關/02_授權版本模組與費用.md",
    target:
      "tutorial-site/content/licensing/02_授權版本模組與費用.md",
  },
  {
    source: "授權相關/03_函式庫總覽與分類.md",
    target:
      "tutorial-site/content/licensing/03_函式庫總覽與分類.md",
  },
  // 開發規範
  {
    source:
      "ExampleFile/CODESYS_開發規範_CFC_SFC_ST.md",
    target:
      "tutorial-site/content/guidelines/CODESYS_開發規範_CFC_SFC_ST.md",
  },
];

/**
 * 確保目標檔案所在的資料夾存在（遞迴建立）。
 * @param {string} filePath
 */
function ensureDirForFile(filePath) {
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

/**
 * 複製單一檔案（覆寫），若來源不存在則給出提示但不中斷整體流程。
 * @param {string} source
 * @param {string} target
 */
function copyFile(source, target) {
  if (!fs.existsSync(source)) {
    console.warn(`[略過] 找不到來源檔案：${source}`);
    return;
  }

  ensureDirForFile(target);
  fs.copyFileSync(source, target);
  console.log(`[OK] ${source} -> ${target}`);
}

/**
 * 將來源目錄下所有 .st 檔複製到目標目錄（與 Markdown 同一個範例資料夾）。
 * 僅處理 target 路徑在 tutorial-site/content/softmotion 下的 mapping。
 */
function copyStFiles(projectRoot, source, target) {
  const targetNorm = target.replace(/\\/g, "/");
  if (!targetNorm.includes("tutorial-site/content/softmotion/")) {
    return;
  }

  const sourceDir = path.dirname(path.join(projectRoot, source));
  const targetDir = path.dirname(path.join(projectRoot, target));

  if (!fs.existsSync(sourceDir)) {
    return;
  }

  ensureDirForFile(path.join(targetDir, "dummy"));
  const entries = fs.readdirSync(sourceDir, { withFileTypes: true });
  for (const ent of entries) {
    if (!ent.isFile() || !ent.name.toLowerCase().endsWith(".st")) {
      continue;
    }
    const srcPath = path.join(sourceDir, ent.name);
    const tgtPath = path.join(targetDir, ent.name);
    copyFile(srcPath, tgtPath);
  }
}

function main() {
  const projectRoot = process.cwd();

  console.log("開始同步 Markdown 與 ST 內容到 tutorial-site/content");
  console.log(`專案根目錄：${projectRoot}`);
  console.log("----");

  for (const mapping of mappings) {
    const sourcePath = path.join(projectRoot, mapping.source);
    const targetPath = path.join(projectRoot, mapping.target);
    copyFile(sourcePath, targetPath);
    copyStFiles(projectRoot, mapping.source, mapping.target);
  }

  console.log("----");
  console.log("同步完成。若有新增範例或文件，請在 sync-content.js 中補上對應的 mapping。");
}

main();

