# Lab 12: Train Tour APR II

### Topic: APRII: Things to Do After Layout (IR Drop, Power Analysis...)

### Description
In this lab, you will complete the **backend flow (APR)** for **Lab03** using **TA-provided netlist files** and perform **IR drop and Power Analysis** for the layout.

## Inputs and Outputs
### **Input Signals**
| Signal Name | Bit Width | Description |
|------------|----------|-------------|
| clk        | 1        | Global clock signal. All signals are sampled on the positive edge. |
| rst_n      | 1        | Global reset signal (Active LOW). |
| in_valid   | 1        | High when the input is valid. |
| tetrominoes | 3       | Denotes the type of the tetromino. |
| position   | 3        | Marks the location of the leftmost block of the tetromino. |

### **Output Signals**
| Signal Name  | Bit Width | Description |
|-------------|----------|-------------|
| score_valid | 1        | High when score is valid for every (tetrominoes, position) set. |
| score       | 4        | Score earned per round. |
| tetris_valid | 1       | High at the end of the current round, aligned with the last `score_valid`. |
| tetris      | 12x6     | A 12x6 unpacked array recording the **Tetris map** of the current round. |
| fail        | 1        | `1`: Player loses, `0`: Player wins. |

## Layout Specifications
### **1. Timing Constraints**
- `CHIP.sdc` period: **3.5ns**
- Input/Output delay: **1.75ns**

### **2. Core & IO Power Pads**
- At least **one pair per side**.

### **3. Floorplanning**
| Specification | Requirement |
|--------------|------------|
| Core Size    | Defined by user |
| Core to IO Boundary | Each side must be **>100** |

### **4. Power Planning**
#### **Core Ring**
| Side | Metal Layer | Width |
|------|------------|------|
| Top & Bottom | Odd-numbered | 9 |
| Left & Right | Even-numbered | 9 |
| Wire Grouping | Interleaving, at least 4 pairs |

#### **Stripes**
| Direction | Metal Layer | Width |
|-----------|------------|------|
| Vertical  | Even-numbered | Defined by user |
| Horizontal | Odd-numbered | Defined by user |
| Pairs | Defined by user |

### **5. Timing Analysis**
| Metric | Requirement |
|--------|------------|
| Timing Slack | No negative slack after **Post-Route** setup/hold analysis |
| Design Rule Violation (DRV) | Fanout, capacitance, and transition violations **must be 0** after setup/hold analysis |

### **6. Design Verification**
| Check | Requirement |
|--------|------------|
| **LVS** | No violations after `verify connectivity` |
| **DRC** | No violations after `verify DRC` |
| **Post-Filler Checks** | Re-run **DRC & LVS** after placing fillers |

### **7. Rail Analysis**
| Metric | Threshold |
|--------|------------|
| **VCC** | **≥ 1.7V** |
| **GND** | **≤ 0.1V** |
| **IR Drop** | **≤ 2mV** |
