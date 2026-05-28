set ECO_MODE	"peco"
#set eco_enable_more_scenarios_than_hosts "true"
set eco_strict_pin_name_equivalence "true"
set DESIGN_MODULE DIG_TOP

#set_multi_scenario_license_limit -feature PrimeTime 99
#set_multi_scenario_license_limit -feature PrimeTime-SI 99

set sub_module 		"DIG_TOP"
set cur_dir			[pwd]

echo "cur_dir=$cur_dir"

set scenario_cases [list \
	[list post	max] \
	[list post	min] \
]

set hname [getenv HOSTNAME]
set_host_options -name host_${hname}	-submit_command "ssh" -max_cores 1 -num_processes 2 ${hname}

#set_host_options -name host_newmoon-008	-submit_command "ssh" -max_cores 1 -num_processes 4 newmoon-008
#set_host_options -name host_newmoon-009	-submit_command "ssh" -max_cores 1 -num_processes 4 newmoon-009
#set_host_options -name host_newmoon-010	-submit_command "ssh" -max_cores 1 -num_processes 4 newmoon-010
#set_host_options -name host_newmoon-011	-submit_command "ssh" -max_cores 1 -num_processes 4 newmoon-011

start_hosts
report_host_usage

setenv PROMPT_MODE "true"

foreach scenario $scenario_cases {
	set PLACEMENT	[lindex $scenario 0]
	set OP_COND		[lindex $scenario 1]

	set scenario_name ${PLACEMENT}_${OP_COND}

	create_scenario \
		-name ${scenario_name} \
		-image ../session/${PLACEMENT}_${OP_COND}
}

current_session -all

remote_execute { 
#	set pba_aocvm_only_mode					"true"
	set pba_exhaustive_endpoint_path_limit	"25000"
	set eco_instance_name_prefix			"PTECO_INST_"
	set eco_net_name_prefix					"PTECO_NET_"

#	set eco_alternative_cell_attribute_restrictions {cell_footprint}
}

set eco_margin	0.05

current_scenario {\
	post_max	post_min \
}

echo "Info: Fix Setup Violation ..."
#fix_eco_timing	-verbose -type setup -methods {size_cell}
#fix_eco_timing	-verbose -hold_margin $eco_margin -type setup -methods {size_cell}
set setup_option	""
append setup_option " -verbose -hold_margin $eco_margin -type setup -methods {size_cell}"

if { $ECO_MODE=="peco" } {
	append setup_option " -physical_mode open_site"
	#append setup_option " -power_mode total -leakage_scenario norm_max_ti -dynamic_scenario norm_max_ti"

	remote_execute {
		set power_enable_analysis true
		set power_clock_network_include_register_clock_pin_power false
		set eco_allow_filler_cells_as_open_sites 	"true"
		set eco_allow_insert_buffer_always_on_cells	"false"
		set_eco_options -physical_tech_lib_path	../../../../be/tech.lef.gz \
						-physical_lib_path		../../../../be/DIG_TOP.lef.gz \
						-physical_design_path	../../../../be/DIG_TOP.def.gz \
						-log_file ../dmsa_lef_def.spi.setup.log
		report_eco_options
	}
}

remote_execute -verbose { report_power }
echo "setup_option=$setup_option"
eval fix_eco_timing $setup_option

remote_execute {
	write_changes -format icctcl -output ../../rpt/eco.setup.tcl
}

echo "Info: Fix Hold Violation ..."
#fix_eco_timing	-verbose -type hold -methods {insert_buffer}
#fix_eco_timing	-verbose -setup_margin $eco_margin -type hold -methods {insert_buffer} \
#				-buffer_list {
#					hd_hvt_bufd1 hd_hvt_bufd2 hd_hvt_bufd3 hd_hvt_bufd4 hd_hvt_bufd5 hd_hvt_bufd6 hd_hvt_bufd7 hd_hvt_bufd8 hd_hvt_bufd9 \
#					hd_bufd1 hd_bufd2 hd_bufd3 hd_bufd4 hd_bufd5 hd_bufd6 hd_bufd7 hd_bufd8 hd_bufd9 \
#					hd_hvt_delay1d1 hd_hvt_delay2d1 hd_hvt_delay3d1 \
#				}
set hold_option	""
append hold_option	" -verbose -setup_margin $eco_margin -type hold -methods {insert_buffer}"
append hold_option	" -buffer_list { \
						BUF_D0P7_N_S7P94TR_C60L04 BUF_D10_N_S7P94TR_C60L04 BUF_D12_N_S7P94TR_C60L04 BUF_D14_N_S7P94TR_C60L04	\
						BUF_D16_N_S7P94TR_C60L04 BUF_D1P5_N_S7P94TR_C60L04 BUF_D1_N_S7P94TR_C60L04 BUF_D20_N_S7P94TR_C60L04		\
						BUF_D24_N_S7P94TR_C60L04 BUF_D28_N_S7P94TR_C60L04 BUF_D2_N_S7P94TR_C60L04 BUF_D32_N_S7P94TR_C60L04		\
						BUF_D3_N_S7P94TR_C60L04 BUF_D4_N_S7P94TR_C60L04 BUF_D5_N_S7P94TR_C60L04 BUF_D6_N_S7P94TR_C60L04			\
						BUF_D7_N_S7P94TR_C60L04 BUF_D8_N_S7P94TR_C60L04 CLKBUF_D10_N_S7P94TR_C60L04 CLKBUF_D12_N_S7P94TR_C60L04	\
						CLKBUF_D14_N_S7P94TR_C60L04 CLKBUF_D16_N_S7P94TR_C60L04 CLKBUF_D3_N_S7P94TR_C60L04 CLKBUF_D4_N_S7P94TR_C60L04	\
						CLKBUF_D5_N_S7P94TR_C60L04 CLKBUF_D6_N_S7P94TR_C60L04 CLKBUF_D7_N_S7P94TR_C60L04 CLKBUF_D8_N_S7P94TR_C60L04		\
						DLY2_D1_N_S7P94TR_C60L04 DLY2_D2_N_S7P94TR_C60L04	\
					} "

	if { $ECO_MODE=="peco" } {
		append hold_option	" -physical_mode open_site"
	#	append hold_option	" -power_mode leakage -leakage_scenario norm_min_ti -dynamic_scenario norm_min_ti"
	
		remote_execute {
			set power_enable_analysis true
			set power_clock_network_include_register_clock_pin_power false
			set eco_allow_filler_cells_as_open_sites 	"true"
			set eco_allow_insert_buffer_always_on_cells	"false"
			set_eco_options -physical_tech_lib_path	../../../../be/tech.lef.gz \
						-physical_lib_path		../../../../be/DIG_TOP.lef.gz \
						-physical_design_path	../../../../be/DIG_TOP.def.gz \
						-log_file ../dmsa_lef_def.spi.hold.log			
			report_eco_options
		}
	}

remote_execute -verbose { report_power }
echo "hold_option=$hold_option"
eval fix_eco_timing $hold_option

remote_execute {
	write_changes -format icctcl -output ../../rpt/eco.hold.tcl
}

remote_execute {
	set rpt_dir	../../rpt/$TOP_DESIGN/${PLACEMENT}

	report_constraint -all_violators -significant_digits 3 -nosplit \
						> ${rpt_dir}/teco1_$TOP_DESIGN.constraints_all.$mode.rpt

	report_timing -path_type full -delay_type max -nosplit -input_pins -nets -max_paths 1 -sort_by slack -pba_mode path -path_type full_clock_expanded \
						> ${rpt_dir}/teco2_$TOP_DESIGN.timing_setup_slack.$mode.rpt
}

quit
