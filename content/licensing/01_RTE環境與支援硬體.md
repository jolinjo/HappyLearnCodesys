# CODESYS RTE 環境與支援硬體

> 資料來源：CODESYS 官網與說明文件，供開發選型參考。

---

## 一、RTE（Runtime Environment）簡介

CODESYS Control RTE（Real-Time Environment）是執行於工業 PC 或嵌入式控制器上的**軟體 PLC 即時執行環境**，可搭配 CODESYS Development System 以 IEC 61131-3 進行程式開發與下載。

- **Control RTE SL**：適用於 **Windows** 的即時軟體 PLC（如 Beckhoff CX 等）。
- **Control for Linux ARM SL**：適用於 **Linux（Debian 系）** 的 ARM 平台執行環境。
- **Control Runtime Toolkit**：供裝置製造商將 CODESYS Control 移植到**自訂硬體**的開發套件。

---

## 二、開發環境中的設備類型（RTE / Win 與 32/64 位元）

在 CODESYS 專案中新增設備時，於 **PLC → SoftMotion PLC** 下會看到四種目標，差異如下。

### 2.1 RTE 與 Win 的差異

| 設備名稱 | 說明 | 適用情境 |
|----------|------|----------|
| **CODESYS Control RTE V3** | **RTE = Real-Time Extension**。使用即時擴充（如 IntervalZero RTX、Beckhoff 即時核心），PLC 掃描週期具**即時性、可預測**。 | 現場控制、運動控制、對掃描時間要求嚴格的應用；Beckhoff CX 等即時 Windows 控制器。 |
| **CODESYS Control Win V3** | **Win = 標準 Windows**。在一般 Windows 上執行，**無即時核心**，掃描週期會受 Windows 排程影響。 | 本機模擬、開發除錯、不需硬即時的應用、或沒有安裝 RTE 的 PC。 |

**簡單區分**：  
- 要**即時、穩定週期** → 選 **RTE**（且硬體需已安裝對應的 RTE 套件）。  
- 要**在一般 PC 上跑模擬/開發** → 選 **Win**。

### 2.2 32 位元（V3）與 64 位元（V3 x64）的差異

| 設備名稱 | 架構 | 說明 |
|----------|------|------|
| **CODESYS Control RTE V3** / **CODESYS Control Win V3** | **32 位元** | 程式與資料位址空間受 32 bit 限制；部分現場匯流排或驅動僅提供 32 bit 版。 |
| **CODESYS Control RTE V3 x64** / **CODESYS Control Win V3 x64** | **64 位元** | 可定址較大記憶體，適合大型專案；需在 64 位元 Windows 上執行，部分附加元件可能僅支援 32 bit。 |

選擇時需與**實際執行環境**一致：若目標機是 64 位元 Windows 且已安裝對應 RTE，應選 **RTE V3 x64**；若僅在本機用一般 Windows 模擬，可選 **Win V3** 或 **Win V3 x64**。

### 2.3 四種設備對照表

| 設備 | 即時性 | 位元 | 典型用途 |
|------|--------|------|----------|
| CODESYS Control RTE V3 | 即時（RTE） | 32 bit | 即時控制、32 bit 硬體或驅動 |
| CODESYS Control RTE V3 x64 | 即時（RTE） | 64 bit | 即時控制、64 bit 工業 PC |
| CODESYS Control Win V3 | 非即時（標準 Windows） | 32 bit | 本機模擬、開發 |
| CODESYS Control Win V3 x64 | 非即時（標準 Windows） | 64 bit | 本機模擬、開發、大記憶體需求 |

---

## 三、支援的作業系統與 CPU 架構

| 平台類型 | 作業系統 | CPU 架構 | 說明 |
|----------|----------|----------|------|
| **Windows** | Windows 8 / 10 / Embedded Windows | x86（單核）、x64（多核） | CODESYS Control RTE SL，適用 PC-based 控制器 |
| **Linux** | Debian-based Linux（32/64 bit） | ARMv7、ARMv8 | CODESYS Control for Linux ARM SL |
| **Linux** | 標準 Linux | x86、ARM | 透過 Runtime Toolkit 或 Store 現成 RTE 產品支援 |
| **自訂平台** | 依實作而定 | x86、ARM 等 | 使用 CODESYS Control Runtime Toolkit 移植 |

**注意**：RTE 不適合在**容器（Container）**或**虛擬機器（VM）**內執行，需在實體或嵌入式硬體上運行。

---

## 四、具體硬體與介面支援

### 4.1 CODESYS Control RTE SL（Windows / Beckhoff CX）

- **適用硬體**：Beckhoff CX 系列嵌入式 PC、一般 x86/x64 工業 PC（執行 Windows）。
- **乙太網路晶片**：Realtek、Intel 等常見晶片組。
- **CAN 介面卡**（選配）：
  - **Peak**：PCIe、MiniPCIe
  - **Ixxat**：SJA1000（PCI）
  - **Automata**：全系列 PCI（1/2 通道）

### 4.2 現場匯流排（Fieldbus）支援

RTE 可搭配對應授權與設備，支援下列通訊協定（依產品與授權而異）：

| 類型 | 協定 |
|------|------|
| **乙太網路型** | EtherCAT、PROFINET、EtherNet/IP、Sercos III（部分僅 32 bit） |
| **現場匯流排** | CANopen、Modbus TCP/Serial、PROFIBUS、J1939 |
| **其他** | CAN-PCI 卡（Peak、Ixxat、Automata）、OPC UA Server |

### 4.3 裝置製造商與自訂硬體

- 透過 **CODESYS Control Runtime Toolkit** 可將執行環境移植到**非標準平台**。
- 執行系統可依硬體能力做**模組化調整**，Store 中也有針對常見標準平台的**現成 SoftPLC** 可選購。

---

## 五、相關連結

- [CODESYS Control 產品頁](https://www.codesys.com/products/codesys-runtime/control.html)
- [CODESYS Control Runtime Toolkit](https://www.codesys.com/products/codesys-runtime/runtime-toolkit.html)
- [CODESYS Control for Linux ARM SL（Store）](https://store.codesys.com/en/codesys-control-for-linux-arm-sl-1.html)
- [CODESYS Control RTE SL（Store）](https://store.codesys.com/en/codesys-control-rte-sl-1.html)

---

*最後整理：依官網與說明文件為準，實際支援以 CODESYS 與各硬體廠商公告為準。*
