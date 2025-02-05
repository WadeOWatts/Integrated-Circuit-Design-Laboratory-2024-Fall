# Lab 10: Coverage & Assertion for Stock Trading Program

### Topic: SystemVerilog Verification

| Submit | Simulation time of coverage | Performance | Rank | Pass Rate|
| :---: | :---: | :---: | :---: | :---: |
| 2nd demo | 2604102 | 2604102 | 105 / 136 | 81.93% |

Performance = Simulation time of coverage

### Description
This lab focuses on verifying the **Stock Trading Program** from **Lab09** by implementing **coverage-driven verification and assertions**. The goal is to ensure the correctness of the design under various conditions and detect potential issues through rigorous pattern testing.

### Tasks
1. **Pattern Generation (`PATTERN.sv`)**
    - Generate test patterns that meet **coverage requirements**.
    - Send patterns to `Program.sv` following **Lab09 specifications**.
    - Verify **output signal correctness**.
2. **Assertions & Coverage (`CHECKER.sv`)**
    - Implement **cover groups** to measure test case effectiveness.
    - Write **assertions** to detect specification violations.

### Coverage Requirements
| Requirement | Condition |
|------------|-----------|
| **Formula Selection** | Each **Formula_Type** must be tested **at least 150 times** |
| **Mode Selection** | Each **Mode** must be tested **at least 150 times** |
| **Formula x Mode Coverage** | All **Formula x Mode** combinations must be tested **at least 150 times** |
| **Warning Message Coverage** | `No_Warn`, `Date_Warn`, `Data_Warn`, and `Risk_Warn` must each appear **at least 50 times** (sampled when `out_valid` is high) |
| **Action Transition Coverage** | Each **transition** from `Index_Check → Check_Valid_Date` must be tested **at least 300 times** (sampled at `posedge clk` when `sel_action_valid` is high) |
| **Update Variation Coverage** | Create bins for **Update action variations** with `auto_bin_max = 32`, ensuring all bins are hit at least **once** |

### Assertion Requirements
| Assertion | Description |
|-----------|-------------|
| **Reset Condition** | All output signals must be `0` after reset. |
| **Latency Limit** | Each operation must complete within **1000 cycles**. |
| **Completion Rule** | If `complete = 1`, then `warn_msg = 2'b00` (No_Warn). |
| **Valid Timing Rule** | Each input valid signal must be **1-4 cycles** after the previous input valid falls. |
| **No Overlapping Inputs** | No input valid signals should **overlap**. |
| **Out Valid Rule** | `out_valid` must be **high for exactly 1 cycle**. |
| **Next Operation Timing** | The next operation must be **1-4 cycles** after `out_valid` falls. |
| **Date Validation** | Input dates must follow **real calendar rules** (e.g., `2/29`, `3/0`, `4/31`, `13/1` are invalid). |
| **AXI4 Validity Rule** | `AR_VALID` and `AW_VALID` should not **overlap**. |

### Important Notes
- **Assertions must immediately terminate** the program if a violation occurs.
- Display assertion violations as **“Assertion X is violated”**.
- **Message format must follow `00_TESTBED/message.txt`**.
- If the test fails on an **incorrect design**, output **“Wrong Answer”** and stop execution.
