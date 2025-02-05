# Lab 4: Convolutional Neural Network (CNN)

### Topic: Advanced Sequential Circuit Design

| Submit | Cycle time | Area | Latency | Performance | Rank | Pass Rate|
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 2nd demo | 50 | 3516201 | 24450000 | 8.61469E+12 | 122 / 141 | 89.17% |

Performance = Area * Latency * Cycle time

### Description
The goal of this lab is to implement a **Convolutional Neural Network (CNN)** that processes image inputs using convolution, padding, max pooling, activation functions, and a fully connected layer. The system applies **softmax** at the final stage to generate classification probabilities.

### Functionality
1. **Image Input & Preprocessing**
    - The system receives a **5x5x3 image** over **75 clock cycles**.
    - The **Kernel** is received over **12 cycles** representing two **3x2x2 kernels**.
    - The **Weight matrix** for the fully connected layer is received over **24 cycles**.
    - Padding is applied based on **Opt** input: **Zero Padding (0)** or **Replication Padding (1)**.

2. **Convolution Layer**
    - The system applies convolution using the provided kernels.
    - The convolution formula:
      \[ Out[m,n] = \sum \sum Img[m,n]_{ij} \times Kernel[m-i,n-j] \]

3. **Pooling & Activation**
    - **Max Pooling** with a **3x3 window** downsizes the feature map.
    - Activation functions: **Sigmoid (Opt = 0)** or **Tanh (Opt = 1)**.

4. **Fully Connected Layer & Softmax**
    - The **fully connected layer** maps the feature map to output probabilities.
    - **Softmax** converts the result into a probability distribution.

### I/O Specification
| Signal Name  | Type   | Width | Description |
|-------------|--------|------|-------------|
| clk         | input  | 1    | Global clock signal |
| rst_n       | input  | 1    | Active-low reset signal |
| in_valid    | input  | 1    | High when input is valid |
| Img         | input  | 32   | Image input in raster order |
| Kernel_ch1  | input  | 32   | First convolution kernel |
| Kernel_ch2  | input  | 32   | Second convolution kernel |
| Weight      | input  | 32   | Weights for fully connected layer |
| Opt         | input  | 1    | Selects activation & padding method |
| out_valid   | output | 1    | High when output is valid |
| out         | output | 32   | CNN-processed output |
