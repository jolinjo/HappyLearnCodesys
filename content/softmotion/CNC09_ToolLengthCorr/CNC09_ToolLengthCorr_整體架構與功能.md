<style>
html, body, #preview, .markdown-preview, .markdown-body, .markdown-preview-section,
[id^="preview"], [class*="markdown-preview"] {
  background-color: #FDF5E6 !important;
  font-size: 14px;
}

/* 程式／術語：只用同一套等寬字體；用顏色區分型別 */
.cfg-func,
.cfg-global,
.cfg-local,
.cfg-custom,
.cfg-const,
.cfg-keyword,
.cfg-type,
.cfg-arg,
.cfg-name,
code {
  font-family: ui-monospace, "Cascadia Code", "Source Code Pro", Consolas, Monaco, "Courier New", monospace;
}

/* 移除反引號 inline code 的灰底樣式（只靠顏色規則） */
.markdown-preview-section :not(pre) > code,
.markdown-preview :not(pre) > code,
.markdown-body :not(pre) > code {
  background: transparent !important;
  padding: 0 !important;
  border: none !important;
  border-radius: 0 !important;
  box-shadow: none !important;
}

.cfg-func   { color: #6f42c1 !important; background: none !important; }
.cfg-global { color: #953800 !important; background: none !important; }
.cfg-local  { color: #0a6c0a !important; background: none !important; }
.cfg-custom { color: #8250df !important; background: none !important; }
.cfg-const  { color: #0d9488 !important; background: none !important; }
.cfg-keyword{ color: #0550ae !important; background: none !important; }
.cfg-type   { color: #cf222e !important; background: none !important; }
.cfg-arg    { color: #c2410c !important; background: none !important; }
.cfg-name   { color: #b45309 !important; background: none !important; }
</style>

**顏色對應**：<span class="cfg-func">內建函數</span> <span class="cfg-global">全域變數</span> <span class="cfg-local">區域變數</span> <span class="cfg-custom">自訂函數</span> <span class="cfg-const">常數</span> <span class="cfg-keyword">保留字</span> <span class="cfg-type">型態</span> <span class="cfg-arg">引數</span> <span class="cfg-name">專有名詞</span>

# CNC09_ToolLengthCorr — 整體架構與功能說明

---

## 一、這個專案在做什麼？

本範例示範如何在 CNC 流程中加入 **刀長補正（Tool Length Compensation）**：透過 <span class="cfg-func">SMC_ToolLengthCorr</span> 在插補器與座標轉換之間插入一層補償，使 Z 方向的 SetPosition 會依照目前刀具的實際長度做修正，搭配 G-code 中的 G43 等指令，達成多支刀具自動補償、仍保持工件基準面不變。

---

## 二、使用情境與硬體／通訊架構

### 2.1 任務與程式

`TaskConfiguration.md`：

| 任務名稱 | 類型 | 週期 | 優先權 | POU 清單 |
|----------|------|------|--------|----------|
| MotionTask | Cyclic | t#gc_dwCycle | 1 | `CNC` |
| PathTask | Cyclic | t#20ms | 5 | `CNC_PreparePath` |
| VISU_TASK | Cyclic | t#100ms | 31 | `VisuElems.Visu_Prg` |

- **PathTask（CNC_PreparePath）**：讀檔、解譯與速度檢查，產生不含刀長補正的路徑佇列。  
- **MotionTask（CNC）**：插補 + 座標轉換 + 刀長補正 + 四軸驅動。  

### 2.2 軸與裝置

`DeviceTree_Axes.md`：

| 軸名稱 | 類型 | 綁定任務 |
|--------|------|----------|
| AxisX | SM_Drive_Virtual | - |
| AxisY | SM_Drive_Virtual | - |
| AxisZ | SM_Drive_Virtual | - |
| AxisA | SM_Drive_Virtual | - |

其中 X/Y/Z 為三軸 CNC 主軸，A 軸可作為附加軸（例如旋轉軸）。刀長補正主要影響 Z 方向的 SetPosition。

### 2.3 函式庫

`Libraries.md`：

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | SoftMotion 基礎運動控制。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 凸輪相關。 |
| <span class="cfg-name">#System_VisuElem3DPath</span> | 3D Path 視覺化。 |
| <span class="cfg-name">#System_VisuElemCamDisplayer</span> | 凸輪視覺化。 |

---

## 三、控制流程：由淺入深

### 3.1 PathTask：讀檔、解譯與速度檢查

`CNC_PreparePath.st`：

```pascal
PROGRAM CNC_PreparePath
VAR_INPUT
	xStart: BOOL;
	sFileName: STRING := 'Application/CNC.cnc';
END_VAR
VAR_OUTPUT
	xStartIpo: BOOL;
	poqPath: Pointer to SMC_Outqueue;
END_VAR
VAR
	iState: INT;
	rncf2 : SMC_ReadNCFile2;
	nci : SMC_NCInterpreter;
	cv : SMC_CheckVelocities;
	aBufInterpreter : ARRAY[0..99] OF SMC_GeoInfo ;
END_VAR
```

與 CNC05 類似，流程為：

1. `poqPath := cv.poqDataOut`：PathTask 輸出為速度檢查後的路徑佇列。  
2. 狀態機 `iState`：  
   - `0`（idle）：等待 `xStart = TRUE`，並將三個 FB 的 `bExecute` 清為 FALSE。  
   - `10`：  
     - `rncf2(bExecute := TRUE, sFileName := sFileName)`：從 `Application/CNC.cnc` 讀取 G-code。  
     - `nci(bExecute := TRUE, sentences := rncf2.sentences, ...)`：解譯 G-code 為幾何段。  
     - `cv(bExecute := TRUE, poqDataIn := nci.poqDataOut)`：速度檢查。  
     - `xStartIpo := TRUE`，檢查完成後回到 `iState := 0`。  

此階段尚未考慮刀長補正，產生的是「理論路徑」。

### 3.2 MotionTask：插補、刀長補正與四軸驅動

`CNC.st`：

```pascal
PROGRAM CNC
VAR
	iState: INT;
	pX, pY, pZ, pA: MC_Power;

	ipo: SMC_Interpolator;
	trafo: SMC_TRAFO_Gantry3;
	trafof: SMC_TRAFOF_Gantry3D;
	cabpX, cabpY, cabpZ, cabpA: SMC_ControlAxisByPos;

	tlc : SMC_ToolLengthCorr;
END_VAR
```

1. 四軸上電：四個 <span class="cfg-func">MC_Power</span> `pX/Y/Z/A` 對 `AxisX/Y/Z/A` 上電。  
2. 狀態機 `iState`：  
   - `0`：等待四軸 `Status` 全為 TRUE。  
   - `100`：呼叫 `Interpolation()`。  
3. 在 `Interpolation()` 中（匯出檔未顯示，但依變數可推測）：  
   - <span class="cfg-func">SMC_Interpolator</span> `ipo` 從 `CNC_PreparePath.poqPath` 消費路徑佇列，產生未補償的 SetPosition（X/Y/Z/A）。  
   - 將 `ipo` 的輸出與目前刀具／補償資料交給 <span class="cfg-func">SMC_ToolLengthCorr</span> `tlc` 做 Z 方向補償，得到補償後的位置資訊。  
   - `trafo/trafof` 將補償後的機械座標轉換為三軸（X/Y/Z）與附加軸 A 對應的驅動座標。  
   - 四個 `cabpX/Y/Z/A` 以 <span class="cfg-func">SMC_ControlAxisByPos</span> 把結果寫入各軸。

**重點**：刀長補正是在「插補器輸出後、座標轉換前」作用，避免影響插補內部的速度與路徑計算，同時又能正確反映在實際 Z 軸位移上。

---

## 四、各支程式負責哪些功能？

### 4.1 `CNC.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 四軸上電。  
  - 呼叫 `Interpolation()` 執行插補、刀長補正與四軸位置控制。  
- **關鍵元件**：  
  - `ipo`：插補器。  
  - `tlc`：<span class="cfg-func">SMC_ToolLengthCorr</span>，負責刀長補償。  
  - `trafo/trafof`：三軸座標轉換。  
  - `cabpX/Y/Z/A`：四軸位置控制。

### 4.2 `CNC_PreparePath.st`

- **類型**：PROGRAM。  
- **職責**：  
  - 從檔案讀取 G-code。  
  - 解譯與速度檢查，輸出不含刀長補償的路徑佇列。  
  - 通知 MotionTask 何時可以啟動插補。  

### 4.3 `GVL.st`

```pascal
VAR_GLOBAL CONSTANT
	gc_dwCycle : DWORD := 4000;
	gc_eOriConvention : SMC_ORI_CONVENTION := SMC_ORI_CONVENTION.ZYZ;
END_VAR
```

- **職責**：  
  - `gc_dwCycle` 定義 MotionTask 插補週期。  
  - `gc_eOriConvention` 指定姿態轉換慣例（例如 ZYZ），供解譯器與座標轉換使用。

---

## 五、函式庫與函式／功能塊一覽

| 名稱 | 類別 | 用途 |
|------|------|------|
| <span class="cfg-func">SMC_ReadNCFile2</span> | FB | 從檔案系統讀取 G-code。 |
| <span class="cfg-func">SMC_NCInterpreter</span> | FB | 解譯 G-code 句子為幾何段。 |
| <span class="cfg-func">SMC_CheckVelocities</span> | FB | 速度檢查與限制。 |
| <span class="cfg-func">SMC_Interpolator</span> | FB | 插補路徑。 |
| <span class="cfg-func">SMC_ToolLengthCorr</span> | FB | 刀長補償：根據刀具資料修正位置資訊。 |
| <span class="cfg-func">SMC_TRAFO_Gantry3</span> / <span class="cfg-func">SMC_TRAFOF_Gantry3D</span> | FB | 三軸龍門座標轉換。 |
| <span class="cfg-func">SMC_ControlAxisByPos</span> | FB | 軸位置控制。 |
| <span class="cfg-func">MC_Power</span> | FB | 軸上電。 |

---

## 六、變數與常數一覽

本範例未使用 RETAIN／PERSISTENT。

### 6.1 全域常數（`GVL.st`）

| 名稱 | 型態 | 預設值 | 說明 |
|------|------|--------|------|
| <span class="cfg-const">gc_dwCycle</span> | <span class="cfg-type">DWORD</span> | 4000 | MotionTask 週期（μs）。 |
| <span class="cfg-const">gc_eOriConvention</span> | <span class="cfg-type">SMC_ORI_CONVENTION</span> | ZYZ | 姿態轉換慣例。 |

### 6.2 `CNC` 主要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">pX/pY/pZ/pA</span> | <span class="cfg-type">MC_Power</span> | 四軸上電與驅動啟動。 |
| <span class="cfg-local">ipo</span> | <span class="cfg-type">SMC_Interpolator</span> | 插補器。 |
| <span class="cfg-local">trafo/trafof</span> | <span class="cfg-type">SMC_TRAFO_Gantry3</span> / <span class="cfg-type">SMC_TRAFOF_Gantry3D</span> | 三軸龍門與浮點版轉換。 |
| <span class="cfg-local">cabpX/Y/Z/A</span> | <span class="cfg-type">SMC_ControlAxisByPos</span> | 四軸位置控制。 |
| <span class="cfg-local">tlc</span> | <span class="cfg-type">SMC_ToolLengthCorr</span> | 刀長補償 FB。 |

### 6.3 `CNC_PreparePath` 主要變數

與 CNC05 類似，這裡不再逐一列出。

---

## 七、特別的演算法與觀念

### 7.1 為什麼刀長補正要放在 Interpolator 與 Trafo 之間？

若在插補前就把 G-code 座標改成「已補償」的值，會導致：

- 插補器認為路徑本身發生了改變，影響速度與加減速規劃。  
- 不同刀具之間切換時，甚至會產生不連續的跳躍。  

將 <span class="cfg-func">SMC_ToolLengthCorr</span> 放在插補器與座標轉換之間，可以：

- 保持插補看到的仍是「理論路徑」。  
- 僅在輸出給實際軸之前修正位置。  
- 配合 G43 等指令，在換刀時平順地調整 Z 軸基準，而不改變原路徑幾何。  

### 7.2 多刀具與 Z 高度一致性

在實際機台中，每支刀的長度略有差異；透過：

- 刀具資料表（不在本匯出檔中，但在完整專案內可設定每支刀長）。  
- G43 / G49 等 G-code 指令啟用 / 關閉補償。  
- `SMC_ToolLengthCorr` 根據當前刀具與偏移量修正 SetPosition。  

可以做到：  
- 不論用哪支刀，工件表面 Z=0 的位置都一致。  
- 換刀後只需要更新刀具資料，不必重新生成 G-code。  

---

## 八、重要參數與設定位置

| 參數 | 檔案 / 位置 | 說明 |
|------|-------------|------|
| <span class="cfg-const">gc_dwCycle</span> | `GVL.st` | MotionTask 週期。 |
| <span class="cfg-const">gc_eOriConvention</span> | `GVL.st` | 姿態轉換慣例。 |
| G-code 檔名 `sFileName` | `CNC_PreparePath.st` | 要讀取的主程式檔案（預設 `Application/CNC.cnc`）。 |

---

## 九、建議閱讀與修改順序

1. 先看 `GVL.st`、`TaskConfiguration.md` 與 `DeviceTree_Axes.md`，搞清四軸與任務結構。  
2. 再看 `CNC_PreparePath.st`，理解 ReadNCFile2 + NCInterpreter + CheckVel 的檔案式讀取流程。  
3. 閱讀 `CNC.st`，特別關注 `tlc : SMC_ToolLengthCorr` 的存在，並在 CODESYS 原始專案中查看 `Interpolation()` 的實作位置，確認補償 FB 實際串接點。  
4. 若要實際應用刀長補償，需在 CNC 專案中設定刀具資料表與對應 G-code 指令；本說明檔可作為理解補償位置與資料流的基礎。  

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-name">Tool Length Compensation</span> | 刀長補償，補償刀具實際長度與程式長度差異。 |
| <span class="cfg-func">SMC_ToolLengthCorr</span> | SoftMotion 刀長補償功能塊。 |
| <span class="cfg-name">G43</span> | 啟用刀長補償的 G-code 指令。 |
| <span class="cfg-name">AxisA</span> | 本範例中的附加軸，可用於旋轉或其他輔助運動。 |

