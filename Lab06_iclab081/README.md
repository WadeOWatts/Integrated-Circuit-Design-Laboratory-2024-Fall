# Lab 6: Matrix Determinant Calculator

### Topic: Introduction to Synthesis Flow with Synopsys Design Compiler

| Submit | Cycle time | Area | Latency | Performance | Rank | Pass Rate|
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 2nd demo | 16.5 | 964647.635 | 10000 | 1.54E+17 | 122 / 141 | 89.17% |

Performance = Area^2 * Latency * Cycle time

### Description
The goal of this lab is to design a **Matrix Determinant Calculator** that decodes **Hamming code-encoded data**, corrects single-bit errors, and computes the determinant of **2×2, 3×3, and 4×4 matrices** based on input instructions.

### Functionality
1. **Hamming Code Decoding**
    - Input data is encoded using **15-11 Hamming code** (for matrix data) and **9-5 Hamming code** (for mode selection).
    - The decoder corrects **single-bit errors** before processing.

2. **Matrix Determinant Calculation**
    - The matrix size is determined by **decoded in_mode**:
      - **2×2 matrix** → Outputs **9 determinants**.
      - **3×3 matrix** → Outputs **4 determinants**.
      - **4×4 matrix** → Outputs **1 determinant**.
    - The determinant calculation follows a specific submatrix extraction process.

3. **Processing Rules**
    - **Input signal in_valid** stays high for **16 cycles**.
    - Data is received sequentially over **16 input cycles**.
    - Once calculation completes, **out_valid** is raised for **1 cycle**.
    - **out_valid must not overlap with in_valid**.

### I/O Specification (Top Design)
| Signal Name  | Type   | Width | Description |
|-------------|--------|------|-------------|
| clk         | input  | 1    | Global clock signal |
| rst_n       | input  | 1    | Active-low reset signal |
| in_valid    | input  | 1    | High when input is valid |
| in_data     | input  | 15   | Encoded matrix data (15-bit Hamming code) |
| in_mode     | input  | 9    | Encoded operation mode (9-bit Hamming code) |
| out_valid   | output | 1    | High when output is valid |
| out_code    | output | 207  | Computed determinant result |

### I/O Specification (Soft IP)
| Signal Name  | Type   | Width | Description |
|-------------|--------|------|-------------|
| IN_code     | input  | IP_BIT + 4 | Encoded data that needs to be decoded |
| OUT_code    | output | IP_BIT  | Decoded data with error correction applied |
