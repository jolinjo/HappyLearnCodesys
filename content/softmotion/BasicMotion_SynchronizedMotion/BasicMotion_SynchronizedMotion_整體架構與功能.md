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

# BasicMotion_SynchronizedMotion — 整體架構與功能說明

---

## 一、這個專案在做什麼？

這個範例示範一條多軸同步鏈的組合：  
以 <span class="cfg-name">Master</span> 軸為基準，先用 <span class="cfg-func">MC_GearIn()</span> 建立 Master 與 <span class="cfg-name">Slave0</span> 的齒輪關係，  
再用 <span class="cfg-func">MC_Phasing()</span> 在 <span class="cfg-name">Slave0</span> 與 <span class="cfg-name">Slave1</span> 之間加入相位偏移，  
最後透過 <span class="cfg-func">SMC_BacklashCompensation()</span> 把 <span class="cfg-name">Slave1</span> 與 <span class="cfg-name">Drive</span> 串接並補償背隙。  
整條鏈的結果是：當 Master 軸以絕對位置指令來回移動時，其餘三軸會按照齒輪比、相位與背隙補償同步運動。

---

## 二、使用情境與硬體／軸架構

### 2.1 任務與程式

根據 `TaskConfiguration.md`：

| 任務名稱 | 類型 | 週期 | 優先權 | POU 清單 |
|----------|------|------|--------|----------|
| MainTask | Cyclic | t#20ms | 1 | `PLC_PRG` |

MainTask 每 20 ms 更新整條同步鏈的狀態。

### 2.2 軸與角色

`DeviceTree_Axes.md` 描述了四條虛擬軸：

| 軸名稱 | 類型 | 角色 |
|--------|------|------|
| <span class="cfg-name">Master</span> | <span class="cfg-name">SM_Drive_Virtual</span> | 基準軸，直接接受絕對位置命令。 |
| <span class="cfg-name">Slave0</span> | <span class="cfg-name">SM_Drive_Virtual</span> | 以齒輪比 3:2 跟隨 Master。 |
| <span class="cfg-name">Slave1</span> | <span class="cfg-name">SM_Drive_Virtual</span> | 以相位偏移 30 度跟隨 Slave0。 |
| <span class="cfg-name">Drive</span> | <span class="cfg-name">SM_Drive_Virtual</span> | 透過背隙補償跟隨 Slave1，可想像為實際驅動機構。 |

Trace 設定追蹤了四條軸的 SetPosition／SetVelocity／SetAcceleration，可用來觀察同步鏈中每一節的效果。

---

## 三、控制流程：由淺入深

### 3.1 整體流程概觀

從 `PLC_PRG` 的狀態機 <span class="cfg-local">state</span> 來看，流程可以概括為：

1. **STATE\_POWER**：啟動四條軸，並同時啟用齒輪、相位與背隙補償。  
2. **STATE\_COMMAND\_POS0**：命令 Master 軸移動到位置 100。  
3. **STATE\_COMMAND\_POS1**：命令 Master 軸回到位置 0。  
4. 回到 **STATE\_COMMAND\_POS0**，形成「0 ↔ 100」來回循環。  

在這個過程中，Slave0、Slave1 與 Drive 不需要額外的 Move 命令，而是透過齒輪／相位／背隙補償自動跟隨。

### 3.2 由 Master 到 Drive 的同步鏈

可以把整個系統想像成：

```text
Master --(GearIn)--> Slave0 --(Phasing)--> Slave1 --(BacklashCompensation)--> Drive
```

當 Master 軸往返 0 與 100 之間時：

- Slave0 會依照 3:2 的齒輪比運動。  
- Slave1 在 Slave0 的基礎上再加上 30 度的相位偏移。  
- Drive 則在 Slave1 的基礎上加一段背隙補償動作。  

搭配 Trace，可以清楚看到每一層的 SetPosition 差異。

---

## 四、各程式負責哪些功能？

本範例只有 `PLC_PRG` 一支程式。

### 4.1 `PLC_PRG` — 多軸同步鏈示範程式

- **類型**：PROGRAM。  
- **職責**：  
  - 上電四條軸。  
  - 啟動齒輪同步（Master → Slave0）、相位調整（Slave0 → Slave1）與背隙補償（Slave1 → Drive）。  
  - 讓 Master 軸在兩個位置之間來回運動，作為整條同步鏈的驅動來源。  
- **與硬體的關係**：  
  - 在真實應用中，可以對應到主軸（Master）、中間傳動軸（Slave0／Slave1）與最終負載軸（Drive），例如：  
    - 印刷機中的多色印筒同步。  
    - 包裝機中多段機構的相位校正與齒輪比調整。  

---

## 五、函式庫與函式／功能塊一覽

### 5.1 函式庫

根據 `Libraries.md`：

| 庫名稱 | 解析版本／備註 |
|--------|----------------|
| <span class="cfg-name">#SM3_Basic</span> | 提供 MC\_* 運動控制功能塊與軸控制。 |
| <span class="cfg-name">#SM3_CamBuilder</span> | 雖有引用，但本範例主要使用齒輪／相位／背隙補償功能。 |

### 5.2 主要功能塊

| 名稱 | 類型 | 用途 | 主要引數 | 回傳／狀態 |
|------|------|------|----------|------------|
| <span class="cfg-func">MC_Power()</span> | FUNCTION\_BLOCK | 對四條軸上電與啟動驅動。 | <span class="cfg-arg">Axis</span>；<span class="cfg-arg">Enable</span>；<span class="cfg-arg">bDriveStart</span>；<span class="cfg-arg">bRegulatorOn</span>。 | `Status`、`Error`。 |
| <span class="cfg-func">MC_MoveAbsolute()</span> | FUNCTION\_BLOCK | 對 Master 軸發出絕對位置運動命令。 | <span class="cfg-arg">Axis</span>；<span class="cfg-arg">Execute</span>；<span class="cfg-arg">Position</span>；<span class="cfg-arg">Velocity</span> 等。 | `Done`、`Error`。 |
| <span class="cfg-func">MC_GearIn()</span> | FUNCTION\_BLOCK | 建立主從齒輪關係（Master → Slave0）。 | <span class="cfg-arg">Master</span>；<span class="cfg-arg">Slave</span>；<span class="cfg-arg">RatioNumerator</span>；<span class="cfg-arg">RatioDenominator</span>；<span class="cfg-arg">Execute</span> 等。 | `InSync`、`Error`、`ErrorID`。 |
| <span class="cfg-func">MC_Phasing()</span> | FUNCTION\_BLOCK | 在兩軸之間添加相位偏移（Slave0 → Slave1）。 | <span class="cfg-arg">Master</span>；<span class="cfg-arg">Slave</span>；<span class="cfg-arg">PhaseShift</span>；<span class="cfg-arg">Velocity</span> 等。 | `Done`、`Error`。 |
| <span class="cfg-func">SMC_BacklashCompensation()</span> | FUNCTION\_BLOCK | 在 Master/Slave 之間加入背隙補償（Slave1 → Drive）。 | <span class="cfg-arg">Master</span>；<span class="cfg-arg">Slave</span>；<span class="cfg-arg">fBacklash</span>；<span class="cfg-arg">fCompensationVel</span> 等。 | `Error`、`ErrorID`。 |

---

## 六、變數與常數一覽

本範例未使用 RETAIN／PERSISTENT 變數。

### 6.1 `PLC_PRG` 中的重要變數

| 名稱 | 型態 | 說明 |
|------|------|------|
| <span class="cfg-local">pwDrive</span> / <span class="cfg-local">pwMaster</span> / <span class="cfg-local">pwSlave0</span> / <span class="cfg-local">pwSlave1</span> | <span class="cfg-type">MC_Power</span> | 四條軸的上電功能塊。 |
| <span class="cfg-local">gearing</span> | <span class="cfg-type">MC_GearIn</span> | 設定 Master → Slave0 的齒輪比與動作。 |
| <span class="cfg-local">phasing</span> | <span class="cfg-type">MC_Phasing</span> | 設定 Slave0 → Slave1 的相位偏移。 |
| <span class="cfg-local">backlash</span> | <span class="cfg-type">SMC_BacklashCompensation</span> | 設定 Slave1 → Drive 的背隙補償行為。 |
| <span class="cfg-local">moveAbsolute</span> | <span class="cfg-type">MC_MoveAbsolute</span> | 對 Master 軸發出 0 ↔ 100 的往返位置命令。 |
| <span class="cfg-local">state</span> | <span class="cfg-type">UDINT</span> | 狀態機目前的狀態。 |

### 6.2 狀態常數

| 名稱 | 值 | 說明 |
|------|----|------|
| <span class="cfg-const">STATE_POWER</span> | 0 | 軸上電並啟用同步鏈。 |
| <span class="cfg-const">STATE_COMMAND_POS0</span> | 10 | 命令 Master 軸移動到位置 100。 |
| <span class="cfg-const">STATE_COMMAND_POS1</span> | 20 | 命令 Master 軸回到位置 0。 |

Trace 設定中包含四條軸的 SetPosition／SetVelocity／SetAcceleration，能清楚看到整條同步鏈的效果。

---

## 七、特別的演算法與觀念

### 7.1 齒輪、相位與背隙補償的組合觀念

這個範例的核心觀念是「把多種同步機制串起來」：

1. **GearIn（Master → Slave0）**  
   - 透過齒輪比 3:2 決定 Slave0 與 Master 之間的位置與速度比例。  
   - 動作類似「電子齒輪箱」，非常適合取代機械齒輪。  
2. **Phasing（Slave0 → Slave1）**  
   - 在已有齒輪關係的基礎上，增加一個固定相位偏移（例如 30 度），常見於多工位同步。  
3. **BacklashCompensation（Slave1 → Drive）**  
   - 用來補償最後一段傳動（例如齒輪／皮帶／轉接機構）的背隙，使 Drive 動作更接近理想運動。  

在這樣的組合下，Master 實際上只需要關心自己的位置命令，其餘三軸的運動都是「被動導出」的。

### 7.2 狀態機簡化與學習重點

範例刻意讓狀態機保持非常簡單，只在 0 與 100 之間來回切換，讓你可以把注意力放在：

- Power／GearIn／Phasing／Backlash 是否都在正確時機啟用。  
- Trace 裡四條軸的軌跡是否符合你對「同步鏈」的直覺。  

在實務專案中，你會把這個結構嵌入到更大的狀態機裡，例如搭配 Cam 運動或更多安全邏輯。

---

## 八、重要參數與設定位置

| 參數／設定 | 所在位置 | 說明 |
|------------|----------|------|
| <span class="cfg-arg">RatioNumerator</span> / <span class="cfg-arg">RatioDenominator</span> | `PLC_PRG` 中 `gearing` 初始值 | 決定 Master → Slave0 的齒輪比。 |
| <span class="cfg-arg">PhaseShift</span> | `PLC_PRG` 中 `phasing` 初始值 | 決定 Slave0 → Slave1 的相位偏移。 |
| <span class="cfg-arg">fBacklash</span> | `PLC_PRG` 中 `backlash` 初始值 | 背隙補償量，決定 Drive 相對 Slave1 的微調行程。 |
| <span class="cfg-arg">Velocity</span> 等 | `PLC_PRG` 中 `moveAbsolute` 初始值 | Master 軸來回運動的速度與加減速設定。 |
| MainTask 週期 t#20ms | `TaskConfiguration.md` | 影響同步更新頻率與數值解析度。 |

這些參數是調整同步行為的主要工具：齒輪比與 PhaseShift 會改變從軸的位置關係，Backlash 會影響最終負載的反應感覺。

---

## 九、建議閱讀與修改順序

1. **先看 `DeviceTree_Axes.md` 與 `TaskConfiguration.md`**  
   - 了解四條軸的角色與任務週期。  
2. **再看 `PLC_PRG` 變數宣告區**  
   - 特別注意 `gearing`、`phasing`、`backlash` 之間的關係與初始化參數。  
3. **接著看狀態機**  
   - 理解何時啟用同步鏈（STATE\_POWER），以及 Master 如何在兩個位置之間來回。  
4. **最後用 Trace 觀察四條軸的 SetPosition**  
   - 比較 Master、Slave0、Slave1 與 Drive 的軌跡，試著用齒輪比與相位偏移來解釋它們的差異。  

修改時，可以先只調整齒輪比與 PhaseShift，再看看 Slave0／Slave1 的軌跡怎麼變，等熟悉後再動背隙補償的參數。

---

## 十、名詞對照

| 英文 / 符號 | 說明 |
|-------------|------|
| <span class="cfg-func">MC_GearIn()</span> | 建立兩軸之間齒輪比關係的功能塊（電子齒輪）。 |
| <span class="cfg-func">MC_Phasing()</span> | 在已有齒輪關係的基礎上新增相位偏移。 |
| <span class="cfg-func">SMC_BacklashCompensation()</span> | 在 Master/Slave 之間補償背隙影響的功能塊。 |
| <span class="cfg-name">Master</span> | 基準軸，直接接受絕對位置命令。 |
| <span class="cfg-name">Slave0</span> | 以齒輪比跟隨 Master 的從軸。 |
| <span class="cfg-name">Slave1</span> | 在 Slave0 的基礎上加上相位偏移的從軸。 |
| <span class="cfg-name">Drive</span> | 經背隙補償後的最終負載軸。 |

