# Lab 8: Self-Attention Hardware Accelerator

### Topic: Low Power Design

| Submit | Cycle time | Area | Latency | Gated Power | Performance | Rank | Pass Rate|
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 1st demo | 50 | 2148906.225 | 7200 | 0.0194 | 15007961078 | 128 / 141 | 84.94% |

Performance = Area * Latency * Total power gated with CG

### Description
The goal of this lab is to design a **Self-Attention Hardware Accelerator** that efficiently processes **matrix operations for input sizes of 1×8, 4×8, and 8×8**. The design replaces the Softmax function with **ReLU** for simplicity and incorporates **clock gating** to optimize power usage.

### Functionality
1. **Self-Attention Computation**
    - Compute **Query (Q), Key (K), and Value (V) matrices**:
      \[ Q = XW_Q, \quad K = XW_K, \quad V = XW_V \]
    - Compute scaled dot-product attention:
      \[ S = ReLU(QK^T / 3) \]
    - Compute final output:
      \[ P = S \times V \]

2. **Processing Stages**
    - **Stage 1 (SA_wocg.v)**: Self-attention without clock gating.
    - **Stage 2 (SA.v)**: Self-attention with **clock gating**, controlled by `cg_en` signal.

3. **Data Processing Sequence**
    - **Input Signals**:
      - `T` (sequence length) is received first.
      - `in_data` is received over **T×8 cycles**.
      - `W_Q`, `W_K`, and `W_V` are each received over **64 cycles**.
    - **Output Signals**:
      - `out_data` is outputted over **T×8 cycles** in **raster scan order**.

### Clock Gating Implementation
- **SA_wocg (without clock gating):**
  - Standard self-attention processing.
- **SA (with clock gating):**
  - If `cg_en` is **high**, the processing blocks perform clock gating.
  - If `cg_en` is **low**, the processing blocks follow `clk`.

### I/O Specification
| Signal Name  | Type   | Width | Description |
|-------------|--------|------|-------------|
| clk         | input  | 1    | Clock signal |
| rst_n       | input  | 1    | Active-low reset signal |
| cg_en       | input  | 1    | Enables clock gating if high |
| in_valid    | input  | 1    | High when input is valid |
| T           | input  | 4    | Sequence length (T = 1, 4, 8) |
| in_data     | input  | 8    | Input sequence data (signed, -128~127) |
| W_Q         | input  | 8    | Query weight matrix (signed, -128~127) |
| W_K         | input  | 8    | Key weight matrix (signed, -128~127) |
| W_V         | input  | 8    | Value weight matrix (signed, -128~127) |
| out_valid   | output | 1    | High when output is valid |
| out_data    | output | 64   | Self-attention output in raster scan order |

### Processing Steps
1. **Receive Input Data**
    - Read `T`, `in_data`, `W_Q`, `W_K`, and `W_V`.
2. **Compute Self-Attention**
    - Generate `Q`, `K`, `V` matrices.
    - Compute scaled dot-product attention (`ReLU(QK^T / 3)`).
    - Compute final output (`P = S × V`).
3. **Output Result**
    - `out_valid` is high when `out_data` is ready.
    - `out_data` is output in **T×8 cycles**.
