set TOP_DESIGN DIG_TOP

set report_default_significant_digits 6 ;

source .synopsys_pt.setup
set_app_var timing_disable_clock_gating_checks false
set_app_var timing_report_unconstrained_paths true
set_app_var rc_degrade_min_slew_when_rd_less_than_rnet true
set_app_var timing_save_pin_arrival_and_slack true
set_app_var svr_keep_unconnected_nets true
set_app_var timing_enable_preset_clear_arcs false
set_app_var auto_wire_load_selection false
set_app_var timing_early_launch_at_borrowing_latches false

# OCV
set_app_var timing_remove_clock_reconvergence_pessimism true
set_app_var read_parasitics_load_locations true

# PT-SI
set_app_var si_enable_analysis true
set_app_var si_xtalk_double_switching_mode			clock_network

# CCS
set_app_var report_capacitance_use_ccs_receiver_model true ; # default : true
set_app_var rc_driver_model_mode advanced                   ; # default : advanced
set_app_var rc_receiver_model_mode advanced                 ; # default : advanced
set_app_var delay_calc_waveform_analysis_mode full_design ; # default : disable

#echo "1)target_library=${target_library}"
if { $mode == "max" } {
	set link_library              "* $SS_CASE" 
	set target_library            "$SS_CASE"
} else {
	set link_library              "* $FF_CASE" 
	set target_library            "$FF_CASE"
}
#echo "2)target_library=${target_library}"
list_libraries

if { $PLACEMENT == "pre" } {
	read_verilog	../../syn/net/final.$TOP_DESIGN.v
} else {
	read_verilog	../../../be/DIG_TOP_nopg.v
}

current_design $TOP_DESIGN
link_design $TOP_DESIGN

if { $PLACEMENT == "post" } {
	echo "spef_file= 01_sspg_0p6750v_m40c_Cmax.spef"
	read_parasitics -keep_capacitive_coupling ../../../be/DIG_TOP_Cmax.spef.gz
} else {
	echo "spef_file= 04_ffpg_0p8250v_125c_Cmin.spef"
	read_parasitics -keep_capacitive_coupling ../../../be/DIG_TOP_Cmin.spef.gz
}
#	DIG_TOP.spef.gz

if { $mode == "max" } {
	set StrOpCond sspg_0p6750v_m40c
} else {
	set StrOpCond ffpg_0p8250v_125c
}

set_operating_conditions \
	-analysis_type on_chip_variation \
	$StrOpCond

#read_sdc -version 1.4 ../../syn/sdc/final.$TOP_DESIGN.sdc
set sdc_write "true"
source ../../syn/scr/system_clock_info.tcl

echo "PLACEMENT=$PLACEMENT"

if { $PLACEMENT == "post" } {
	set real_clocks [get_clocks *]
	set virtual_clocks [get_clocks -quiet ~*]
	if { [sizeof_collection $virtual_clocks] > 0 } {
		set real_clocks [remove_from_collection $real_clocks $virtual_clocks]
	}
	set_propagated_clock $real_clocks

	foreach clk [get_object_name $real_clocks] {
		set rest [remove_from_collection [get_clocks $real_clocks] [get_clocks $clk]]
		set_false_path -from [get_clocks $clk] -to $rest
		set_false_path -from $rest -to [get_clocks $clk]
		echo "Info: set_false_path between \[$clk\] and \[[get_object_name $rest]\]"
	}
}

update_timing -full

set rpt_dir	../rpt/$TOP_DESIGN/${PLACEMENT}
if { ![file isdirectory $rpt_dir] } {
	file mkdir $rpt_dir
}

check_timing -verbose         > ${rpt_dir}/1_$TOP_DESIGN.check_timing.$mode.rpt
report_global_timing          > ${rpt_dir}/2_$TOP_DESIGN.report_global_timing.$mode.rpt
report_clock -skew -attribute > ${rpt_dir}/3_$TOP_DESIGN.report_clock.$mode.rpt
report_analysis_coverage      > ${rpt_dir}/4_$TOP_DESIGN.report_anlysis_coverage.$mode.rpt
report_timing -path_type full -delay_type min -nosplit -input_pins -nets -max_paths 1000 -sort_by group \
							  > ${rpt_dir}/5_$TOP_DESIGN.timing_hold_group.$mode.rpt
report_timing -path_type full -delay_type min -nosplit -input_pins -nets -max_paths 1000 -sort_by slack \
							  > ${rpt_dir}/6_$TOP_DESIGN.timing_hold_slack.$mode.rpt
report_timing -path_type full -delay_type max -nosplit -input_pins -nets -max_paths 1000 -sort_by group \
							  > ${rpt_dir}/7_$TOP_DESIGN.timing_setup_group.$mode.rpt
report_timing -path_type full -delay_type max -nosplit -input_pins -nets -max_paths 1000 -sort_by slack \
						  > ${rpt_dir}/8_$TOP_DESIGN.timing_setup_slack.$mode.rpt
report_constraint -all_violators -significant_digits 3 -nosplit \
						  > ${rpt_dir}/9_$TOP_DESIGN.constraints_all.$mode.rpt
report_constraint -max_transition -all_violators -nosplit -sig 3 > ${rpt_dir}/10_$TOP_DESIGN.report_constraint_max_transition
report_constraint -max_capacitance -all_violators -nosplit -sig 3 > ${rpt_dir}/11_$TOP_DESIGN.report_constraint_max_capacitance
if { $PLACEMENT == "pre" } {
	write_sdc -version 1.4      ../sdc/final.$TOP_DESIGN.sdc
} else {
	write_sdf ./../out/$TOP_DESIGN.primetime.$mode.sdf

	report_annotated_parasitics \
		-list_not_annotated \
		-max 100000 \
		> $rpt_dir/10_$TOP_DESIGN.not_annotated.rpt

	report_timing -path_type full -delay_type max -nosplit -input_pins -nets -max_paths 100 -sort_by slack -pba_mode path -path_type full_clock_expanded \
						> ${rpt_dir}/11_$TOP_DESIGN.timing_setup_slack.$mode.rpt
	report_timing -path_type full -delay_type min -nosplit -input_pins -nets -max_paths 100 -sort_by slack -pba_mode path -path_type full_clock_expanded \
						> ${rpt_dir}/11_$TOP_DESIGN.timing_hold_slack.$mode.rpt
}

#------------------------------------------------------------------------------
#   Save Session
#------------------------------------------------------------------------------
set session_dir ../session
if { ![file isdirectory $session_dir] } {
	file mkdir $session_dir
}
set session_name $session_dir/${PLACEMENT}_${mode}
save_session $session_name

remove_design -all
