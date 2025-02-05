# 2024 Autumn ICLAB Final Project: Image Signal Processor (ISP) for Camera Auto Focus & Auto Exposure Algorithm

| Submit | Cycle time | Area | Latency | Performance | Rank | Pass Rate|
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 1st demo | 6 | 230866.474 | 180594 | 2.71063E+17 | 118 / 134 | 77.46% |

Performance = Area * (Latency * Cycle time)^2

## Description
This project focuses on implementing **autofocus (AF) and auto-exposure (AE) algorithms** using **HDL**, integrating **AXI4 protocol** for **DRAM communication**. **SRAM** is encouraged for efficiency. It enhances **HDL proficiency**, **memory management**, and **image processing** skills, providing practical experience in **hardware design, optimization, and real-world imaging system implementation**.

## Functional Overview
### Auto Focus
1. Given 3 contrasts (0 to 2), extract the central region for processing.
2. Convert the selection area to grayscale:
   G_center(i, j) = 0.25 * I_center(i, j, 0) + 0.5 * I_center(i, j, 1) + 0.25 * I_center(i, j, 2)
3. Compute the difference between each element along x-axis and y-axis.
4. Divide the summed value by the processed image’s area.
5. Find the maximum contrast value and select the optimal solution.

### Auto Exposure
1. Input the image and desired exposure adjustment ratio.
2. Adjust the image based on the selected ratio and constrain values between 0 and 255.
3. Compute the average brightness after adjustment.
4. Return the calculated average brightness.

### Average of Min and Max in the Picture
1. Identify the maximum and minimum values in each RGB channel.
2. Compute the average of maximum and minimum values.
3. Output the result.

## Inputs and Outputs
### **Input Signals**
| Signal Name | Bit Width | Description |
|------------|----------|-------------|
| `clk`           | 1        | Global clock signal, positive edge-triggered |
| `rst_n`         | 1        | Active-low reset signal |
| `in_valid`      | 1        | High when input data is valid |
| `in_pic_no`     | 4        | Selects the picture from DRAM |
| `in_mode`       | 2        | Algorithm selection: `0` = AF, `1` = AE, `2` = Min-Max Avg |
| `in_ratio_mode` | 2        | Exposure ratio selection (`0.25x`, `0.5x`, `1x`, `2x`), valid if `in_mode = 1` |

### **Output Signals**
| Signal Name  | Bit Width | Description |
|-------------|----------|-------------|
| `out_valid`     | 1        | High when output data is valid |
| `out_data`      | 8        | Computed result: contrast (AF), brightness (AE), or Min-Max Avg |

## Design
The system consists of three components:
- **PATTERN.v**: Sends instructions and verifies output.
- **ISP.v**: Implements autofocus and auto-exposure algorithms.
- **pseudo DRAM.v**: Stores image data, communicating via AXI4.

### AXI4 Protocol Implementation
The design follows AXI4 protocol specifications for reading and writing DRAM image data.

## Design Rules
- **Latency**: Maximum 10,000 cycles per operation.
- **Clock Period**:  Max **20ns** 
- **Total Area**: **≤ 750,000** (ISP + SRAM)
- **Power Planning**:
  - Core-to-IO boundary > 100.
  - Hard macros placed inside core.
  - Power ring interleaved, at least 4 pairs, width ≥ 9.
  - Stripes width ≥ 4, max distance < 200.

