# Lab 9: Stock Trading Program

### Topic: Introduction to SystemVerilog & Advanced Testbench

| Submit | Cycle time | Area | Latency | Performance | Rank | Pass Rate|
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 2nd demo | 10.8 | 87731.88 | 846183 | 8.01762E+11 | 133 / 135 | 81.32% |

Performance = Area * Latency * Cycle time

### Description
The **Stock Trading Program** assesses **market risks** using **four key indices** and allows users to update historical data. The program performs **index checks, updates**, and **validity verification** to ensure accurate market analysis. 

### Functionality
1. **Index Check**
    - Computes risk assessment based on a **selected formula and mode**.
    - Compares results against predefined thresholds.
    - Outputs a **warning message** if the risk is high.
2. **Update**
    - Modifies existing **market indices data** in **DRAM**.
    - Updates **date and index variations** while ensuring data validity.
3. **Check Valid Date**
    - Ensures today’s date is valid compared to **DRAM-stored dates**.
    - Issues warnings if inconsistencies exist.

### Formula Computation
| Formula | Input | Computation |
|---------|------|-------------|
| **A**  | `3'd0` | R = floor [(I_A + I_B + I_C + I_D) / 4] |
| **B**  | `3'd1` | R = max(I_A, I_B, I_C, I_D) - min(I_A, I_B, I_C, I_D) |
| **C**  | `3'd2` | R = min(I_A, I_B, I_C, I_D) |
| **D**  | `3'd3` | Counts indices >= 2047 |
| **E**  | `3'd4` | Counts indices >= TI_A, TI_B, TI_C, TI_D |
| **F**  | `3'd5` | Computes max-arg mean for G(A), G(B), G(C), G(D) |
| **G**  | `3'd6` | Sorts G-values and computes weighted sum |
| **H**  | `3'd7` | Computes average of G-values |

- **Indices**: `I(A), I(B), I(C), I(D)` are from early trading.
- **Threshold values**: Change based on selected **mode** (`Insensitive`, `Normal`, `Sensitive`).
- **Warnings** are issued when R >= Threshold).

### Warning Messages
| Action | Warning Code |
|--------|--------------|
| **Index Check** | `2'b00` = `Date_Warn`, `2'b01` = `Risk_Warn` |
| **Update** | `2'b01` = `Data_Warn` |
| **Check Valid Date** | `2'b10` = `Date_Warn` |
| **No Warning** | `2'b00` |

### I/O Specification
| Signal Name  | Type   | Width | Description |
|-------------|--------|------|-------------|
| clk         | input  | 1    | Clock signal |
| rst_n       | input  | 1    | Active-low reset signal |
| sel_action_valid | input  | 1  | High when action selection is valid |
| formula_valid | input  | 1  | High when formula type is provided |
| mode_valid  | input  | 1    | High when mode selection is valid |
| date_valid  | input  | 1    | High when today’s date is valid |
| data_no_valid | input  | 1  | High when DRAM data selection is valid |
| index_valid | input  | 1    | High when index data is valid |
| D           | input  | 72   | Input data signal |
| out_valid   | output | 1    | High when output is valid |
| warn_msg    | output | 2    | Warning message output |
| complete    | output | 1    | High if operation completes successfully |

### Processing Steps
1. **Receive Inputs**
    - Select **formula, mode, date, and index values**.
    - Validate today’s date against DRAM-stored data.
2. **Compute Index Check or Update Data**
    - Use the selected **formula** to compute risk assessment.
    - Update DRAM-stored indices based on **index variations**.
3. **Issue Warning or Complete Action**
    - If today's date is earlier than DRAM's date, issue `Date_Warn`.
    - If risk exceeds the threshold, issue `Risk_Warn`.
    - If indices exceed max/min values, issue `Data_Warn`.
    - Otherwise, complete action successfully (`No_Warn`).

### AXI4 Lite Communication
- **DRAM read and write operations** follow the **AXI4 Lite protocol**.
- SystemVerilog implementation must correctly handle **latency variations (1 ≤ latency ≤ 100)**.

