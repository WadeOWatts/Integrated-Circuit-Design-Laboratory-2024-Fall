# 2024 Autumn ICLAB Midterm Project: Image Signal Processor (ISP) for Camera Auto Focus & Auto Exposure Algorithm

| Submit | Cycle time | Area | Latency | Performance | Rank | Pass Rate|
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 2nd demo | 5.7 | 556917.2 | 292803 | 1.55128E+18 | 136 / 141 | 81.52% |

Performance = Area * (Latency * Cycle time)^2

## Description
This project focuses on designing **Auto Focus (AF)** and **Auto Exposure (AE)** algorithms using **Verilog**. The goal is to compute the optimal focal length and adjust image brightness to a specified level. The **AXI4 transmission protocol** is used for **reading/writing image data** from and to external **DRAM**. To optimize resource utilization, **SRAM** is recommended for managing large image data.

### **Key Learning Objectives**
- Implementation of **Auto Focus & Auto Exposure algorithms**.
- **AXI4 protocol** for DRAM communication.
- **SRAM usage** for optimized memory management.
- **Verilog-based hardware design**.

## Functional Overview

### **1. Auto Focus (AF)**
- Extracts a center region of the image and converts it to grayscale.
- Computes contrast values along **x** and **y** axes.
- Selects the focal length with the highest contrast.
- If multiple contrasts are equal, the lowest index is chosen.

### **2. Auto Exposure (AE)**
- Adjusts image brightness based on a **specified ratio**.
- Caps values exceeding **255**.
- Computes the **average brightness** of the adjusted image.
- Allows a precision error margin of **±1**.

## Inputs and Outputs
### **Input Signals**
| Signal Name | Bit Width | Description |
|------------|----------|-------------|
| clk        | 1        | System clock. All signals sampled on the **positive edge**. |
| rst_n      | 1        | Asynchronous active-low reset. |
| in_valid   | 1        | High when input is valid. |
| in_pic_no  | 4        | Selects image from DRAM. Valid only when `in_valid = 1`. |
| in_mode    | 1        | **0** = Auto Focus, **1** = Auto Exposure. Valid only when `in_valid = 1`. |
| in_ratio_mode | 2    | Selects exposure ratio (0.25x, 0.5x, 1x, 2x). Valid only for Auto Exposure mode. |

### **Output Signals**
| Signal Name  | Bit Width | Description |
|-------------|----------|-------------|
| out_valid   | 1        | High when output data is valid. Cannot overlap with `in_valid`. |
| out_data    | 8        | Best contrast index (AF) or mean adjusted brightness (AE). |

## System Architecture
The system consists of **three** main modules:
- **PATTERN.v**: Sends instructions and verifies outputs.
- **ISP.v**: Implements **Auto Focus & Auto Exposure** algorithms and **AXI4** communication.
- **pseudo DRAM.v**: Stores images and handles AXI4 memory transactions.

## Design Constraints
| Constraint | Requirement |
|------------|------------|
| **Clock Period** | Max **20ns** |
| **Latency** | **≤ 20000 cycles** per operation |
| **Total Area** | **≤ 750,000** (ISP + SRAM) |
