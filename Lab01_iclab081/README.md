# Lab 1: Credit Card Validator and Snack Purchase Calculator

## Description
This repository contains the Verilog implementation of a **Credit Card Validator and Snack Purchase Calculator**. The goal of this lab is to design a system that verifies a credit card number and determines the maximum number of snacks that can be purchased within the available balance.

## Functionality
### 1. Credit Card Validation
The system checks whether the provided **16-digit credit card number** is valid using the following steps:
- Multiply all odd-positioned digits by 2, sum up the individual digits.
- Add the even-positioned digits.
- If the total sum is divisible by 10, the card is valid.

### 2. Snack Purchase Calculation
Once the card is validated, the system determines how many snacks can be purchased based on:
- **Input Money (9 bits)**: The available balance in the card.
- **Snack Requirements (32 bits)**: 8 types of snacks, each requiring a specific quantity.
- **Snack Prices (32 bits)**: Corresponding prices for each snack type.
- The system prioritizes purchasing the most expensive snacks first, ensuring exact amounts are bought.

### 3. Output
- **out_valid**: `1` if the credit card is valid, otherwise `0`.
- **out_change**: Remaining balance if the card is valid; otherwise, it returns the original balance.

## Files
- `credit_card_checker.v` - Module for validating the credit card number.
- `snack_calculator.v` - Module for calculating snack purchases.
- `lab1_tb.v` - Testbench for simulation.
- `README.md` - This file.

## Author
[Your Name]
