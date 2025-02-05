# Lab 3: Tetris

### Topic: Testbench and Pattern

| Submit | Cycle time | Area | Latency | Performance | Rank | Pass Rate|
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 2nd demo | 20 | 120375.8 | 31809 | 76580676444 | 137 / 145 | 92.36% |

Performance = Area * Latency * Cycle time

### Description
The goal of this lab is to design a **Tetris game system** that simulates the placement of tetriminoes on a 6x12 grid. The system should correctly position, stack, and clear lines while maintaining an accumulated score. The implementation must also handle game-over conditions and reset when a new round begins.

### Functionality
1. **Tetrimino Placement**
    - There are **8 types** of tetriminoes, each represented by a 3-bit input.
    - The **X position** (column) of the tetrimino is given as input.
    - The tetrimino falls until it lands on the bottom or another block.

2. **Line Clearing & Scoring**
    - When a row is completely filled, it is cleared from the grid.
    - Each cleared row awards **one point**.
    - Blocks above the cleared row shift downward accordingly.

3. **Game Over Condition**
    - If a new tetrimino **cannot fit** after clearing filled lines, the game terminates early.
    - The score resets, and a new round starts.

4. **Pattern Handling**
    - The system reads **patterns** from an input file, which contains sequences of tetrimino placements.
    - Each round consists of **16 tetrimino placements** unless the game ends early.
    - The system maintains an internal state without external answer files.

### I/O Specification
| Signal Name  | Type   | Width | Description |
|-------------|--------|------|-------------|
| clk         | input  | 1    | Global clock signal |
| rst_n       | input  | 1    | Active-low reset signal |
| in_valid    | input  | 1    | High when input is valid |
| tetrominoes | input  | 3    | Represents the type of tetrimino |
| position    | input  | 3    | X position (column) of the tetrimino |
| score_valid | output | 1    | High when score is valid |
| score       | output | 4    | Player's accumulated score |
| tetris_valid| output | 1    | High when final Tetris board is valid |
| tetris      | output | 72   | 6x12 grid representing the board state |
| fail        | output | 1    | High if the game ends early |
