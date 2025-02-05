# OT Exercise

## Design Description
The project is focused on creating a **Ramen Vending Machine** to handle student orders efficiently at NYCU. The machine will allow students to select from various types of ramen and bowl sizes.

### **Ramen Types & Ingredients**

| **Ramen Type** | **Portion** | **Noodles** (g) | **Broth** (ml) | **Tonkotsu Soup** (ml) | **Soy Sauce** (ml) | **Miso** (ml) |
|----------------|-------------|-----------------|----------------|------------------------|--------------------|---------------|
| **TONKOTSU**   | Small (1'b0) |100| 300             | 150            | 0                      | 0                  | 
| **TONKOTSU_SOY** | Small (1'b0) |100| 300             | 100            | 30                     | 0                  | 
| **MISO**       | Small (1'b0) |100| 400             | 0              | 0                      | 30                  | 
| **MISO_SOY**   | Small (1'b0) |100| 300             | 70             | 15                     | 15                 |
| **TONKOTSU**   | Big (1'b1)   |150| 500             | 200            | 0                      | 0                  | 
| **TONKOTSU_SOY** | Big (1'b1)   |150| 500             | 150            | 50                     | 0                  | 
| **MISO**       | Big (1'b1)   |150| 500             | 0              | 50                     | 50                 | 
| **MISO_SOY**   | Big (1'b1)   |150| 500             | 100            | 25                     | 25                 | 

#### **Initial Stock**:
- **12000g noodles**
- **41000ml broth**
- **9000ml tonkotsu soup**
- **1000ml miso**
- **1500ml soy sauce**

---

## **Input and Output Signals**

### **Input Signals**

| **Signal Name** | **Bit Width** | **Description**                            |
|-----------------|---------------|--------------------------------------------|
| **clk**         | 1             | Clock signal                               |
| **rst_n**       | 1             | Active-low reset signal                   |
| **in_valid**    | 1             | High when all input is valid               |
| **portion**     | 1             | 1'b0 for small, 1'b1 for big portion       |
| **ramen_type**  | 2             | Type of ramen: TONKOTSU, TONKOTSU_SOY, MISO, MISO_SOY |
| **selling**     | 1             | High when the vending machine is operating |

### **Output Signals**

| **Signal Name**  | **Bit Width** | **Description**                                 |
|------------------|---------------|-------------------------------------------------|
| **out_valid_order** | 1           | High when the order response is valid           |
| **success**      | 1             | Order response: 1'b0 for insufficient ingredients, 1'b1 for success |
| **sold_num**     | 28            | Number of ramen sold (divided by type)          |
| **total_gain**   | 15            | Total gain from sales                           |


