#==========================================================================================
# Synthesis Main Script - using Design Compiler
# Modified by Y.G. Kim at 3th, April 2021
#==========================================================================================

remove_design -all
set_host_options -max_cores 8

#---------- Set Top Desgin Name ---------
set TOP_DESIGN DIG_TOP

#---------- Time Stamp ------------------
set dc_start_time [clock seconds]
set dc_rundate    [clock format [clock seconds] -format %Y_%m_%d_%I:%M%p]

#---------- Write Log -------------------
puts              "INFO: DC_SYNTHESIS starts - $dc_rundate"
set   dc_run_log  [open "../log/$TOP_DESIGN.run.log" a]

puts  -nonewline $dc_run_log "PERSEUS_INFO: DC_SYNTHESIS started ..."
close $dc_run_log

set    dc_event_run_log [open ../log/$TOP_DESIGN.event.log a]
puts  $dc_event_run_log "step DC_SYNTHESIS start [clock format [clock seconds] \
                      -format %Y_%m_%d_%I:%M%p] ([clock seconds])"
close $dc_event_run_log

set work_library "work"
define_design_lib work -path "work_dir"

#---------- Formality -------------------
set_svf ../svf/$TOP_DESIGN.svf

#---------- RTL Setting -----------------
set hdlin_prohibit_nontri_multiple_drivers     true
set hdlin_allow_mixed_blocking_and_nonblocking true
set hdlin_check_no_latch                       true
set enable_keep_signal						   true
set hdlin_keep_signal_name                     user
#---------- Set Don't Use Cell ----------
source -verbose -echo ../scr/dont_use_cells.tcl

#---------- Read Verilog ----------------
analyze -f verilog -lib work ${rtl_dir}/sim/salus8_spi_202408/src/DIG_TOP.v
analyze -f vhdl	   -lib work ${rtl_dir}/sim/salus8_spi_202408/src/spi_slave/SPI_TOP_R0.vhd

#set vlog_files [glob ${rtl_dir}/sim/mipi_lbpamid_proj5_2023_04/src/*.v]
#analyze -f verilog -lib work $vlog_files

elaborate -lib work $TOP_DESIGN -update
current_design $TOP_DESIGN
link

list_libs
uniquify

#=================================================================

write -f ddc     -hier -o   ../ddc/gtech.$TOP_DESIGN.ddc
write -f verilog -hier -o   ../net/gtech.$TOP_DESIGN.v

#---------- Read SDC --------------------
#read_sdc ../scr/system_clock_info.sdc
set sdc_write "false"
source ../scr/system_clock_info.tcl
#---------- DC Setting ------------------
set compile_slack_driven_buffering                true
set_wire_load_mode                                top
set compile_delete_unloaded_sequential_cells      true
set compile_seqmap_propagate_constants            false
set dont_bind_unused_pins_to_logic_constant       true
set synlib_model_map_effort                       high
set compile_seqmap_synchronous_extraction         true
set timing_enable_multiple_clocks_per_reg         true
set compile_seqmap_identify_shift_registers       false
set power_cg_flatten                              true
set timing_non_unate_clock_compatibility          true 
set case_analysis_with_logic_constants            true

set_fix_multiple_port_nets -all  -buffer_constants  
set collection_result_display_limit -1
set_cost_priority -delay  

#---------- Area Constraints ------------
set_max_area 0

#---------- Operating Conditions Constraints ------------
set_operating_condition -max "sspg_0p6750v_m40c" -min "ffpg_0p8250v_125c" 

#---------- DC Setting ------------------
source ../scr/all_inputs_minus_clocks.tcl

group_path -name group_output -to   [all_outputs]
group_path -name group_inputs -from [all_inputs_minus_clocks]
group_path -name f2f -from [all_registers]           -to [all_registers] -critical_range 0.7
group_path -name i2f -from [all_inputs_minus_clocks] -to [all_registers] -critical_range 0.7
group_path -name f2o -from [all_registers]           -to [all_outputs]   -critical_range 0.7
group_path -name i2o -from [all_inputs_minus_clocks] -to [all_outputs]   -critical_range 0.7

#---------- Sanity Check ----------------
check_design                             > ../rpt/pre/$TOP_DESIGN.check_design_pre_compile.rpt
report_net_fanout -threshold 50 -nosplit > ../rpt/pre/$TOP_DESIGN.fanout_pre_compile.rpt

#---------- Misc Constraints ------------
source -verbose -echo ../scr/dont_touch_constraint.tcl
set verilogout_no_tri  "true"

#==========================================================================================
# Compile 
#==========================================================================================
set auto_wire_load_selection "false"
set_wire_load_mode "enclosed"
#set_wire_load_model -name "ZeroWireload" [get_designs]
set compile_seqmap_propagate_constants		"true"
set compile_seqmap_propagate_high_effort	"true"

#compile_ultra -scan -no_seq_output_inversion -no_boundary_optimization -no_autoungroup
compile_ultra -no_seq_output_inversion -no_boundary_optimization -no_autoungroup
if { $ToolVersion > 2013.01 } {
	optimize_netlist -area
}

check_design                              > ../rpt/pre/$TOP_DESIGN.check_design.rpt
report_net_fanout -threshold 50 -nosplit  > ../rpt/pre/$TOP_DESIGN.fanout.rpt
report_resources -nosplit -hierarchy      > ../rpt/pre/$TOP_DESIGN.resources.rpt
check_timing                              > ../rpt/pre/$TOP_DESIGN.check_timing.rpt

#---------- Check Point Option ----------
define_name_rules verilog -type net  -allowed "A-Z 0-9 _ /"
report_name_rules verilog 
change_names -hier -rules   verilog  

#---------- Check Point -----------------
write -f ddc     -hier -o   ../ddc/ultra.$TOP_DESIGN.ddc
write -f verilog -hier -o   ../net/ultra.$TOP_DESIGN.v
write_sdc -version 1.4      ../sdc/ultra.$TOP_DESIGN.sdc

report_reference -nosplit > ../rpt/ult/$TOP_DESIGN.ref.rpt
report_qor                > ../rpt/ult/$TOP_DESIGN.qor

report_timing -nosplit -max_paths 5000 -input -nets -cap -tran -nosplit -sig 3                 > ../rpt/ult/$TOP_DESIGN.group.rpt
report_timing -nosplit -max_paths 5000 -input -nets -cap -tran -nosplit -sig 3 -sort_by slack  > ../rpt/ult/$TOP_DESIGN.slack.rpt
report_timing -nosplit -max_paths 2000 -input -nets -cap -tran -nosplit -sig 3 -group f2f      > ../rpt/ult/$TOP_DESIGN.f2f.rpt
report_timing -nosplit -max_paths 2000 -input -nets -cap -tran -nosplit -sig 3 -group i2f      > ../rpt/ult/$TOP_DESIGN.i2f.rpt
report_timing -nosplit -max_paths 2000 -input -nets -cap -tran -nosplit -sig 3 -group f2o      > ../rpt/ult/$TOP_DESIGN.f2o.rpt
report_timing -nosplit -max_paths 2000 -input -nets -cap -tran -nosplit -sig 3 -group i2o      > ../rpt/ult/$TOP_DESIGN.i2o.rpt

report_area -nosplit -hier                    > ../rpt/ult/$TOP_DESIGN.area.rpt
report_constraint -all_violators -nosplit     > ../rpt/ult/$TOP_DESIGN.const.rpt
report_dont_touch -nosplit -class cell        > ../rpt/ult/$TOP_DESIGN.dont_touch.rpt
get_lib_cells */* -filter "dont_use==true"    > ../rpt/ult/$TOP_DESIGN.dont_use.rpt

##---------- Check Point Option ----------
#define_name_rules verilog -type port -allowed "a-z A-Z 0-9 _ /"
#define_name_rules verilog -type net  -allowed "a-z 0-9 _ /"

#report_name_rules verilog 

# variable setting for verilog out
#change_names -hier -rules   verilog  

puts "Adding prefix to all sub_modules"
set dc_topcell_name [get_object_name [current_design]]
set dc_modes [all_design]
puts "Top Module Name: $dc_topcell_name"
set dc_allmod_excluded_topmod [remove_from_collection $dc_modes $dc_topcell_name]
foreach_in_collection mod $dc_allmod_excluded_topmod { rename_design -prefix ${dc_topcell_name}_ $mod }
set dc_new_modes [all_design]
foreach_in_collection dc_nmodes $dc_new_modes { puts "[get_object_name $dc_modes]" }

#---------- Check Point -----------------
write -f ddc     -hier -o   ../ddc/final.$TOP_DESIGN.ddc
write -f verilog -hier -o   ../net/final.$TOP_DESIGN.v
set sdc_write "true"
source ../scr/system_clock_info.tcl
if { $ToolVersion > 2016.12 } {
#	write_sdc -version 2.1      ../sdc/iccom.$TOP_DESIGN.sdc
}
write_sdf -version 1.0      ../sdf/final.$TOP_DESIGN.sdf
write_sdc -version 1.4      ../sdc/final.$TOP_DESIGN.sdc


report_reference -nosplit > ../rpt/fin/$TOP_DESIGN.ref.rpt
report_qor                > ../rpt/fin/$TOP_DESIGN.qor

report_timing -nosplit -max_paths 5000 -input -nets -cap -tran -nosplit -sig 3                 > ../rpt/fin/$TOP_DESIGN.setup_group.rpt
report_timing -nosplit -max_paths 5000 -input -nets -cap -tran -nosplit -sig 3 -sort_by slack  > ../rpt/fin/$TOP_DESIGN.setup_slack.rpt
report_timing -nosplit -max_paths 2000 -input -nets -cap -tran -nosplit -sig 3 -group f2f      > ../rpt/fin/$TOP_DESIGN.setup_f2f.rpt
report_timing -nosplit -max_paths 2000 -input -nets -cap -tran -nosplit -sig 3 -group i2f      > ../rpt/fin/$TOP_DESIGN.setup_i2f.rpt
report_timing -nosplit -max_paths 2000 -input -nets -cap -tran -nosplit -sig 3 -group f2o      > ../rpt/fin/$TOP_DESIGN.setup_f2o.rpt
report_timing -nosplit -max_paths 2000 -input -nets -cap -tran -nosplit -sig 3 -group i2o      > ../rpt/fin/$TOP_DESIGN.setup_i2o.rpt

report_area -nosplit -hier                    > ../rpt/fin/$TOP_DESIGN.area.rpt
report_constraint -all_violators -nosplit     > ../rpt/fin/$TOP_DESIGN.const.rpt
report_dont_touch -nosplit -class cell        > ../rpt/fin/$TOP_DESIGN.dont_touch.rpt
get_lib_cells */* -filter "dont_use==true"    > ../rpt/fin/$TOP_DESIGN.dont_use.rpt

report_compile_options -nosplit               > ../rpt/com/$TOP_DESIGN.compile_options.rpt
check_design                                  > ../rpt/com/$TOP_DESIGN.check_design_post_compile.rpt
report_net_fanout -threshold 50 -nosplit      > ../rpt/com/$TOP_DESIGN.fanout_post_compile.rpt
check_timing                                  > ../rpt/com/$TOP_DESIGN.check_timing.rpt
report_area -nosplit -hier                    > ../rpt/com/$TOP_DESIGN.area_hier.rpt
report_hierarchy -nosplit -noleaf             > ../rpt/com/$TOP_DESIGN.hier.rpt
report_constraint -all_violators -nosplit     > ../rpt/com/$TOP_DESIGN.const.rpt
report_power -verbose -nosplit     			  > ../rpt/com/$TOP_DESIGN.power.rpt

#report_timing -nosplit -max_paths 5000 -input -nets -cap -tran -nosplit -sig 3                 > ../rpt/$TOP_DESIGN.setup_group.rpt
#report_timing -nosplit -max_paths 5000 -input -nets -cap -tran -nosplit -sig 3 -sort_by slack  > ../rpt/$TOP_DESIGN.setup_slack.rpt
#report_timing -nosplit -max_paths 2000 -input -nets -cap -tran -nosplit -sig 3 -group f2f      > ../rpt/$TOP_DESIGN.setup_f2f.rpt
#report_timing -nosplit -max_paths 2000 -input -nets -cap -tran -nosplit -sig 3 -group i2f      > ../rpt/$TOP_DESIGN.setup_i2f.rpt
#report_timing -nosplit -max_paths 2000 -input -nets -cap -tran -nosplit -sig 3 -group f2o      > ../rpt/$TOP_DESIGN.setup_f2o.rpt
#report_timing -nosplit -max_paths 2000 -input -nets -cap -tran -nosplit -sig 3 -group i2o      > ../rpt/$TOP_DESIGN.setup_i2o.rpt

#-------------------------
# List Unclocked Registers
#-------------------------
report_clock

source ../scr/get_unclocked_registers.tcl
get_unclocked_registers

#-------------------------
# Time stamp: DC_SYNTH 
#-------------------------
set rundate [clock format [clock seconds] -format %Y_%m_%d_%I:%M%p]
puts "INFO: DC_SYNTHESIS ends - $rundate"

set dc_end_time [clock seconds]
set dc_run_time_in_sec [expr $dc_end_time - $dc_start_time]
set dc_run_time_in_min [expr $dc_run_time_in_sec / 60.0]
set dc_run_time_in_hr  [expr $dc_run_time_in_min / 60.0]

puts "INFO: DC_SYNTHESIS - TOTAL RUN TIME = $dc_run_time_in_sec sec"
puts "INFO: DC_SYNTHESIS - TOTAL RUN TIME = $dc_run_time_in_min min"
puts "INFO: DC_SYNTHESIS - TOTAL RUN TIME = $dc_run_time_in_hr hr"

set    dc_run_log  [open "../log/$TOP_DESIGN.run.log" a]
puts  $dc_run_log " ended in $dc_run_time_in_hr (hr)"
close $dc_run_log

set    dc_event_run_log [open ../log/$TOP_DESIGN.event.log a]
puts  $dc_event_run_log "step DC_SYNTH end [clock format [clock seconds] -format %Y_%m_%d_%I:%M%p] ([clock seconds])"
close $dc_event_run_log

exit
