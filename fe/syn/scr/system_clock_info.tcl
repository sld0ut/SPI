if { ![info exists mode] } {
	set mode "max"
}
if { ![info exists sdc_write] } {
	set sdc_write "false"
}
echo "mode=$mode"
echo "sdc_write=$sdc_write"
source ../scr/procedure.tcl

set sclock_port_name    SCLK
set cclock_port_name	CSN

set sclk_period          20
if { $sdc_write=="true" } {
	set clk_scaling_factor  1.00
	set INOUT_DELAY			1.5
} else {
	set clk_scaling_factor  0.70
	set INOUT_DELAY			1.0
}

set clk_skew  0.3
set clk_setup 0.3
set clk_hold  0.3

set sclock_period  [expr $sclk_period * $clk_scaling_factor]
set cclock_period  [expr $sclk_period * $clk_scaling_factor]

create_clock -name s_clk -period $sclock_period -waveform "0.0 [expr ($sclock_period / 2)]"  [get_ports $sclock_port_name ]
create_clock -name c_clk -period $sclock_period -waveform "0.0 [expr ($sclock_period / 2)]"  [get_ports $cclock_port_name ]

set real_clock_groups [list \
	s_clk \
	c_clk \
]

set async_clock_groups [list \
]

set SyncClkGrp_0 [list \
	s_clk\
	c_clk\
]

if { [llength $async_clock_groups] > 0 } {
	foreach clk $async_clock_groups {

		set_clock_uncertainty        $clk_skew  [get_clocks $clk]
		set_clock_uncertainty -setup $clk_setup [get_clocks $clk]
		set_clock_uncertainty -hold  $clk_hold  [get_clocks $clk]

		set rest [remove_from_collection [get_clocks $real_clock_groups] [get_clocks $clk]]
		set_false_path -from [get_clocks $s_clk] -to $rest
		set_false_path -from $rest -to [get_clocks $clk]
		echo "Info: set_false_path between \[$clk\] and \[[get_object_name $rest]\]"
	}
} else {
	foreach clk $real_clock_groups {
		set_clock_uncertainty        $clk_skew  [get_clocks $clk]
		set_clock_uncertainty -setup $clk_setup [get_clocks $clk]
		set_clock_uncertainty -hold  $clk_hold  [get_clocks $clk]
		echo "Info: set_clock_uncertainty $clk"
	}
}

#set AllSyncGrp [list \
#]
#
#
#if { [llength $AllSyncGrp] > 0 } {
#	foreach SyncGrp $AllSyncGrp {
#		set SyncClocks [get_clocks $SyncGrp]
#		set rest [remove_from_collection [get_real_clocks] $SyncClocks]
#		set_false_path -from $SyncClocks -to $rest
#		set_false_path -from $rest       -to $SyncClocks
#		echo ""
#		echo "Info: set_false_paths"
#		echo "        -from/to" \[[get_names $SyncClocks]\]
#		echo "        -from/to" \[[get_names $rest]\]
#	}
#}

#
set all_inputs	[all_inputs]
set all_outputs	[all_outputs]

set all_inputs	[remove_from_collection $all_inputs [get_ports SCLK]]
set all_inputs	[remove_from_collection $all_inputs [get_ports RSTB]]
set all_inputs	[remove_from_collection $all_inputs [get_ports CSN]]

echo "all_inputs= [get_object_name $all_inputs]"
echo "all_outputs= [get_object_name $all_outputs]"


# define virtual clock
create_clock -name ~s_clk -period $sclock_period -waveform "0.0 [expr ($sclock_period / 2)]"
create_clock -name ~c_clk -period $sclock_period -waveform "0.0 [expr ($sclock_period / 2)]"

set virtual_clock_groups [list \
	~s_clk \
	~c_clk \
]

set INOUT_DELAY	1.0

if { [llength $virtual_clock_groups] > 1 } {
	echo "virtual_clock_groups=[llength $virtual_clock_groups]"
	foreach vc $virtual_clock_groups {

		set_input_delay  $INOUT_DELAY  -clock $vc	-add_delay	$all_inputs		
		set_output_delay $INOUT_DELAY  -clock $vc	-add_delay	$all_outputs	

		set rc [lindex [split $vc ~] end]
		set rest [remove_from_collection [get_clocks *] [get_clocks [list $rc $vc]]]
		set_false_path -from [get_clocks $vc] -to $rest
		set_false_path -from $rest -to [get_clocks $vc]
		echo "Info: set_false_path between \[$vc\] and \[[get_object_name $rest]\]"
	}
}

set_max_delay [expr $INOUT_DELAY*6.0] -from [get_ports $all_inputs	-filter {port_direction==in}]
set_max_delay [expr $INOUT_DELAY*6.0] -to	[get_ports $all_outputs -filter {port_direction==out}]

set_driving_cell -lib_cell BUF_D1_N_S7P94TR_C60L04 [get_ports * -filter {port_direction==in}] -no_design_rule
set_false_path -from [all_inputs] -to [all_outputs]

set_load 0.5 [all_outputs]

report_case_analysis
report_clock
report_clock -skew 
set power_enable_analysis true
if { "$synopsys_program_name"=="dc_shell" } {
	report_timing_requirements
	report_port

	foreach clk_src [get_names [get_real_clocks]] {
		echo "clk_src=$clk_src"
		set regs_list  "regs_on_clock {$clk_src}"
		set_switching_activity \
			-static_probability 0.5 \
			-toggle_rate 0.05 \
			-base_clock $clk_src \
			-type $regs_list \
			-hier
	}
} else {
	if { $mode=="min" } {
		set static_pb	0.5
		set toggle_rt	0.05
	} else {
		set static_pb	0.02
		set toggle_rt	0.03
	}
	echo "static_pb	=$static_pb"
	echo "toggle_rt	=$toggle_rt"

	foreach clk_src [get_object_name [all_clocks]] {
		echo "clk_src=$clk_src"
		set_switching_activity \
			-static_probability $static_pb \
			-toggle_rate $toggle_rt \
			-base_clock $clk_src \
			-type registers \
			-hier
	}

	report_switching_activity
}
