# Lab 7: Convolution with Clock Domain Crossing

### Topic: Static Timing Analysis

| Submit | Cycle time | Area | Latency | Performance | Rank | Pass Rate|
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 1st demo | 47.1 | 109220.2 | 990000 | 1.18098E+16 | 73 / 138 | 83.13% |

Performance = Area^2 * Latency

### Description
The goal of this lab is to implement **Convolution with Clock Domain Crossing (CDC)** by computing the **convolution of a 6×6 matrix with six 2×2 kernels** while managing data transfer between different clock domains using **Handshake and FIFO synchronizers**.

### Functionality
1. **Matrix Convolution**
    - Given a **6×6 input matrix (M)** and **six 2×2 kernels (K)**, compute the convolution result **C5×5** using:
      \[ C_{i,j,k} = M_{j,k} \times K_{i,0,0} + M_{j,k+1} \times K_{i,0,1} + M_{j+1,k} \times K_{i,1,0} + M_{j+1,k+1} \times K_{i,1,1} \]
    - Output the result **element-by-element** in the order **C0,0,0 → C5,4,4**.

2. **Clock Domain Synchronization**
    - **Input matrix M and kernel K are received in clk1 domain.**
    - **Handshake synchronizer** transfers data from **clk1 to clk2 domain**.
    - **Computation is performed in clk2 domain**.
    - **FIFO synchronizer** transfers results back to **clk1 domain**.
    - **Output elements are released in clk1 domain**.

3. **CDC Verification Requirements**
    - No **error messages**, **violations**, or **issues in violation.csv**.
    - **CDC Phases (Paris, Schemes, Convergence, Functional, Metastability) should be correct**.
    - **All CDC Configuration sections must be correct**.

### I/O Specification
| Signal Name  | Type   | Width | Description |
|-------------|--------|------|-------------|
| clk1        | input  | 1    | Clock 1 with periods 4.1ns, 7.1ns, 17.1ns, 47.1ns |
| clk2        | input  | 1    | Clock 2 with period 10.1ns |
| rst_n       | input  | 1    | Active-low asynchronous reset |
| in_valid    | input  | 1    | High when `in_row` and `in_kernel` are valid |
| in_row      | input  | 18   | Unsigned 6-element matrix row (3 bits per element) |
| in_kernel   | input  | 12   | Unsigned 2×2 kernel (3 bits per element) |
| out_valid   | output | 1    | High when output data is valid |
| out_data    | output | 8    | Unsigned result for convolution output |

### Processing Steps
1. **Receive Input in clk1 Domain**
    - Input matrix **M** (6×6) and kernels **K** (six 2×2) are received.
2. **Transfer Data to clk2 Domain**
    - Use **Handshake synchronizer** for secure data transfer.
3. **Perform Convolution in clk2 Domain**
    - Compute **C5×5** for each kernel.
4. **Transfer Results to clk1 Domain**
    - Use **FIFO synchronizer** for output buffering.
5. **Output Convolution Result**
    - **out_valid** is high for **150 cycles** as data is released.