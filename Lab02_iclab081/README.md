# Lab 2: Three-Inning Baseball Game

### Topic: Sequential Circuits

| Submit | Cycle time | Area | Latency | Performance | Rank | Pass Rate|
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 1st demo | 10 | 5438.664 | 99 | 538427.736 | 130 / 154 | 97.45% |

Performance = Area * Latency

### Description
The goal of this lab is to design a simplified **baseball game system** that tracks the progress of a three-inning game. The system simulates various batter actions (e.g., hits, home runs, walks), updates base runner status, and calculates scores. A state machine is used to manage inning transitions, track outs, and determine the final game result.

### Functionality
1. **Game Rules & State Tracking**
    - The game consists of **three innings**, with each inning divided into a **top half (Team A bats)** and **bottom half (Team B bats).**
    - Each team has **three outs per half-inning**, after which the sides switch.
    - Runs are scored when a batter or runner returns to **home plate**.
    - The game determines a winner based on the final scores after **three innings**.

2. **Batter Actions & Effects**
    The batter can perform **eight different actions**, affecting runners and scores:
    - **Walk (3’d0):** Batter advances to 1B; runners advance if possible.
    - **Single (3’d1):** Batter to 1B; runners advance with special rules if there are 2 outs.
    - **Double (3’d2):** Batter to 2B; runners advance based on outs.
    - **Triple (3’d3):** Batter to 3B; all runners score.
    - **Home Run (3’d4):** Batter and all runners score.
    - **Bunt (3’d5):** Only happens with 0 or 1 out; batter out, runners advance.
    - **Ground Ball (3’d6):** May cause a **double play** if there is a runner on 1B.
    - **Fly Ball (3’d7):** Can result in a **sacrifice fly** if there is a runner on 3B.

### I/O Specification
| Signal Name | Type   | Width | Definition |
|------------|--------|------|------------|
| clk        | input  | 1    | Clock signal |
| rst_n      | input  | 1    | Active-low reset |
| in_valid   | input  | 1    | High when input is valid |
| inning     | input  | 2    | Current inning number |
| half       | input  | 1    | Top (0) or bottom (1) of inning |
| action     | input  | 3    | Batter action code |
| out_valid  | output | 1    | High when output is valid |
| score_A    | output | 8    | Team A’s score |
| score_B    | output | 8    | Team B’s score |
| result     | output | 2    | Final game result |

