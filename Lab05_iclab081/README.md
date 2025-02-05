# Lab 5: Template Matching with Image Processing (TMIP)

### Topic: Introduction to Macros and SRAM

| Submit | Cycle time | Area | Latency | Performance | Rank | Pass Rate|
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 3rd demo | 20 | 281625.0499 | 281508 | x | x | 78.34% |

Performance = Area^2 * Latency * Cycle time

### Description
The goal of this lab is to implement **Template Matching with Image Processing (TMIP)** using the **Cross Correlation** method. The system detects objects in an image by matching a predefined template and applies various image processing techniques such as grayscale transformation, max pooling, filtering, and negative transformation.

### Functionality
1. **Template Matching (Cross Correlation)**
    - Detects objects in an image using a **3×3 template**.
    - The formula for cross correlation:
      \[ R(x,y) = \sum Template(x',y') \times Image(x+x', y+y') \]
    - Zero padding is applied before the correlation.

2. **Image Processing Operations**
    - **Grayscale Transformation:**
      - **Max Method:** Uses the maximum of RGB components.
      - **Average Method:** Averages RGB values and rounds down.
      - **Weighted Method:** Uses human eye sensitivity weights.
    - **Max Pooling:** A **2×2 filter** selects max values (stride=2).
    - **Negative Image Transformation:** Converts grayscale values as:
      \[ Negative(x,y) = 255 - Grayscale(x,y) \]
    - **Horizontal Flip:** Mirrors the image horizontally.
    - **Image Filtering:** Applies a **3×3 median filter** to reduce noise.

3. **Processing Rules**
    - Image sizes: **4×4, 8×8, 16×16** (template size is always **3×3**).
    - Actions include grayscale conversion, pooling, filtering, and correlation.
    - The first action must be **grayscale transformation**, and the last action must be **cross correlation**.
    - After 8 sets of actions, a new pattern starts.


### I/O Specification
| Signal Name  | Type   | Width | Description |
|-------------|--------|------|-------------|
| clk         | input  | 1    | Global clock signal |
| rst_n       | input  | 1    | Active-low reset signal |
| in_valid    | input  | 1    | High when image, template, and image size are valid |
| in_valid2   | input  | 1    | High when action is valid |
| image       | input  | 8    | RGB image elements in raster order |
| template    | input  | 8    | Template elements in raster order |
| image_size  | input  | 2    | Size of input image (4×4, 8×8, 16×16) |
| action      | input  | 3    | Specifies image processing operation |
| out_valid   | output | 1    | High when output is valid |
| out_value   | output | 20   | Processed output matrix in raster scan order |
