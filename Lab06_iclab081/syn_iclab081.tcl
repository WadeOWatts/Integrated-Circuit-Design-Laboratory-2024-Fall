#======================================================
# (A) Global Parameters
#======================================================
set DESIGN "MDC"
set CYCLE 16.5
set INPUT_DLY [expr 0.5*$CYCLE]
set OUTPUT_DLY [expr 0.5*$CYCLE]

#======================================================
# (B) Read RTL Code
#======================================================
set hdlin_auto_save_templates TRUE
analyze -f sverilog $DESIGN\.v 
analyze -f sverilog HAMMING_IP.v
elaborate $DESIGN  
elaborate HAMMING_IP

current_design $DESIGN
link

#======================================================
#  (C) Global Setting
#======================================================
set_wire_load_mode top
#======================================================
#  (D) Set Design Constraints
#======================================================
create_clock -name clk -period $CYCLE [get_ports clk] 
set_dont_touch_network             [get_clocks clk]
set_fix_hold                       [get_clocks clk]
set_clock_uncertainty       0.1    [get_clocks clk]

set_input_transition        0.5    [all_inputs] 
set_clock_transition        0.1    [all_clocks] 

set_input_delay   -max  $INPUT_DLY  -clock clk   [all_inputs] ;  # set_up time check 
set_input_delay   -min  0           -clock clk   [all_inputs] ;  # hold   time check 
set_output_delay  -max  $OUTPUT_DLY -clock clk   [all_outputs] ; # set_up time check 
set_output_delay  -min  0           -clock clk   [all_outputs] ; # hold   time check 
set_input_delay 0 -clock clk clk
set_input_delay 0 -clock clk rst_n

set_load 0.05 [all_outputs]

set_max_transition      3       [all_inputs]   ; # U18 LUT Max Transition Value  
set_max_capacitance     0.15    [all_inputs]   ; # U18 LUT Max Capacitance Value
set_max_fanout          10      [all_inputs]   ;
set_max_area            1000000                ;

report_clock -skew clk
check_timing

#======================================================
#  (E) Optimization
#======================================================
check_design > Report/$DESIGN\.check
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]
set_fix_hold [all_clocks]
compile_ultra

#======================================================
#  (F) Output Reports 
#======================================================
report_design  >  Report/$DESIGN\.design
report_resource >  Report/$DESIGN\.resource
report_timing -max_paths 3 >  Report/$DESIGN\.timing
report_area >  Report/$DESIGN\.area
report_power > Report/$DESIGN\.power
report_clock > Report/$DESIGN\.clock
report_port >  Report/$DESIGN\.port
report_power >  Report/$DESIGN\.power

#======================================================
#  (G) Change Naming Rule
#======================================================
set bus_inference_style "%s\[%d\]"
set bus_naming_style "%s\[%d\]"
set hdlout_internal_busses true
change_names -hierarchy -rule verilog
define_name_rules name_rule -allowed "a-z A-Z 0-9 _" -max_length 255 -type cell
define_name_rules name_rule -allowed "a-z A-Z 0-9 _[]" -max_length 255 -type net
define_name_rules name_rule -map {{"\\*cell\\*" "cell"}}
define_name_rules name_rule -case_insensitive
change_names -hierarchy -rules name_rule

#======================================================
#  (H) Output Results
#======================================================
set verilogout_higher_designs_first true
write -format verilog -output Netlist/$DESIGN\_SYN.v -hierarchy
write -format ddc     -hierarchy -output $DESIGN\_SYN.ddc
write_sdf -version 3.0 -context verilog -load_delay cell Netlist/$DESIGN\_SYN.sdf -significant_digits 6
write_sdc Netlist/$DESIGN\_SYN.sdc

#======================================================
#  (I) Finish and Quit
#======================================================
report_area
report_timing 
exit
