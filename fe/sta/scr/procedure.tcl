#------------------------------------------------------------------------------
#
#	Procedures
#
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# 	Define Virtual Clocks
#------------------------------------------------------------------------------
proc define_virtual_clocks {} {
	foreach_in_collection clk_list [get_real_clocks] {
		set period [get_attribute $clk_list period]

		if { $period!="" } {
			create_clock \
				-name ~[get_names $clk_list] \
				-period $period \
				-waveform [list 0 [expr $period/2.0]] ;
		}
	}

	echo ""
	echo "Info: [sizeof_collection [get_virtual_clocks]] virtual clocks defined..."
	foreach_in_collection clock [get_virtual_clocks] {
		echo "  Clock name   : [get_attribute $clock name]"
		echo "        period : [get_attribute $clock period] ns"
	}

#	foreach_in_collection itr $virtual_clocks {
#		set rest [remove_from_collection $virtual_clocks $itr]
#		if {[llength $rest] != 0} {
#			set_false_path -from $itr  -to $rest
#			set_false_path -from $rest -to $itr
#			echo ""
#			echo "Info: set_false_paths"
#			echo "        -from" \[[get_names $itr]\]
#			echo "        -to  " \[[get_names $rest]\]
#			echo "Info: set_false_paths"
#			echo "        -from" \[[get_names $rest]\]
#			echo "        -to  " \[[get_names $itr]\]
#		}
#	}
#	
#	foreach_in_collection vclk $virtual_clocks {
#		set rclk [lrange [split [get_names $vclk] ~] 1 end]
#		set rest [remove_from_collection $real_clocks [get_clocks $rclk]]
#		if {[llength $rest] != 0} {
#			set_false_path -from $vclk -to $rest
#			set_false_path -from $rest -to $vclk
#			echo ""
#			echo "Info: set_false_paths"
#			echo "        -from" \[[get_names $vclk]\]
#			echo "        -to  " \[[get_names $rest]\]
#			echo "Info: set_false_paths"
#			echo "        -from" \[[get_names $rest]\]
#			echo "        -to  " \[[get_names $vclk]\]
#		}
#	}
}

#------------------------------------------------------------------------------
#   get_source_pin
#		- get a source pin from any reference pin
#------------------------------------------------------------------------------
proc get_source_pin { reference_pin } {
	set ref_class [get_attribute $reference_pin object_class -quiet]
	if { "$ref_class" == "port" } {
		set source_pin [get_ports $reference_pin]
	} else {
		set source_pin [get_pins \
			-of_objects [get_nets -of $reference_pin] \
			-leaf \
			-filter {pin_direction==out} \
		]
	}
	return [get_object_name $source_pin]
}

#------------------------------------------------------------------------------
#  set_dont_touch_primitives 
#		- set dont_touch attribute to desired primitives
#------------------------------------------------------------------------------
proc set_dont_touch_primitives { primitive_list } {
	foreach p $primitive_list {
		set design_before_uniquify [get_designs -quiet *$p*] 
		set design_after_uniquify  [get_designs -quiet -regexp .*_${p}_\[0-9\]\+] 
		set dont_touch_designs [add_to_collection \
			$design_before_uniquify \
			$design_after_uniquify \
		]
		if { [sizeof_collection $dont_touch_designs] != 0 } {
			set_dont_touch $dont_touch_designs
			foreach_in_collection d $dont_touch_designs {
				echo "Info: set_dont_touch [get_object_name $d]"
			}
		}
	}
}

proc get_dont_touch_primitives {list_only rpt_file} {
	if {$rpt_file==1} {
		global sta_dir
		set file ${sta_dir}/sdc/dont_touch.tcl
		echo "" > $file
	}

	set prim_cells [add_to_collection \
		[get_cells -hier * -filter {is_hierarchical==false&&full_name=~*/I_SC*&&(ref_name=~*CK*||ref_name=~CKLNQ*)}] \
		[get_cells -hier * -filter {is_hierarchical==false&&full_name=~*/I_DEL*&&ref_name=~DEL*}] \
	]
	set prim_cells [add_to_collection $prim_cells [get_cells -hier * -filter {is_hierarchical==false&&full_name=~*/I_DEL*&&ref_name=~*INV*}]]
	set prim_cells [add_to_collection $prim_cells [get_cells -hier * -filter {is_hierarchical==false&&full_name=~*/I_INST*&&ref_name=~TIE*}]]
	set prim_cells [add_to_collection $prim_cells [get_cells -hier * -filter {is_hierarchical==false&&full_name=~*/DNT_gated_se*&&ref_name=~CKLNQ*}]]
	set prim_cells [add_to_collection $prim_cells [get_cells -hier * -filter {is_hierarchical==false&&full_name=~*/I_PAD*&&ref_name=~PD*}]]

	if { $list_only==1 } {
		return $prim_cells
	} else {
		foreach_in_collection cell $prim_cells {
			set_dont_touch $cell
			echo "Info: set_dont_touch [get_object_name $cell]"
			if {$rpt_file==1} {
				echo "set_dont_touch \[get_cells [get_object_name $cell]\]"  >> $file
			}
		}
		echo ""
	}
}

#------------------------------------------------------------------------------
#   intersect_collections
#		- 
#------------------------------------------------------------------------------
proc intersect_collections { a b } {
    set intersect {}
	foreach_in_collection i $a {
		foreach_in_collection j $b {
		   	if { \
			   [get_object_name $i] == [get_object_name $j] && \
			   [get_attribute $i object_class] == [get_attribute $j object_class] \
			} {
			   	set intersect [add_to_collection $intersect $j]
			}
		}
	}
	return $intersect
}

#------------------------------------------------------------------------------
#   get_names
#		- build a list of object names
#------------------------------------------------------------------------------
# For PrimeTime in which "get_object_name" works on single object only
proc get_names { c } {
	set names ""
	foreach_in_collection i $c {
		lappend names [get_object_name $i]
	}
	return $names
}

#------------------------------------------------------------------------------
#   get_real_clocks
#		- build a collection of real clocks discarding virtual clocks
#------------------------------------------------------------------------------
proc get_real_clocks {} {
	set clocks ""
	foreach_in_collection clk [get_clocks *] {
		if {[get_attribute $clk sources] != ""} {
			set clocks [add_to_collection $clocks $clk]
		}
	}
	return $clocks
}

#------------------------------------------------------------------------------
#   get_virtual_clocks
#		- build a collection of virtual clocks having no source
#------------------------------------------------------------------------------
proc get_virtual_clocks {} {
	set clocks ""
	foreach_in_collection clk [get_clocks *] {
		if {[get_attribute $clk sources] == ""} {
			set clocks [add_to_collection $clocks $clk]
		}
	}
	return $clocks
}

#------------------------------------------------------------------------------
#   get_reset_ports
#		- build a collection of asynchronous clear/preset ports
#------------------------------------------------------------------------------
proc get_reset_ports {} {
	set ports ""
	foreach_in_collection this_port [all_inputs] {
		set fanouts [all_fanout -from $this_port -endpoints_only -flat]
		set clock_pin  [filter_collection $fanouts "full_name =~ *clocked_on*"]
		set clear_pin  [filter_collection $fanouts "full_name =~ */clear"]
		set preset_pin [filter_collection $fanouts "full_name =~ */preset"]
		set mapped_rn  [filter_collection $fanouts "full_name =~ */RN"]
		set mapped_sn  [filter_collection $fanouts "full_name =~ */SN"]
		if {($clear_pin!="" || $preset_pin!="" || $mapped_rn!="" || $mapped_sn!="") && $clock_pin==""} {
			set ports [add_to_collection $ports $this_port]
		}
	} 
	return $ports
}

#------------------------------------------------------------------------------
#   get_clocking_ports
#	- build a collection of ports that fanout to clock pin of sequential cells
#------------------------------------------------------------------------------
proc get_clocking_ports {} {
	set ports ""
	foreach_in_collection this_port [all_inputs] {
		set fanouts [all_fanout -from $this_port -endpoints_only -flat]
		set clock_pin  [filter_collection $fanouts "full_name =~ *clocked_on*"]
		set mapped_ck  [filter_collection $fanouts "full_name =~ */CK"]
		set mapped_ckn [filter_collection $fanouts "full_name =~ */CKN"]
		set clear_pin  [filter_collection $fanouts "full_name =~ */clear"]
		set preset_pin [filter_collection $fanouts "full_name =~ */preset"]
		if {($clock_pin!="" || $mapped_ck!="" || $mapped_ckn!="") && $clear_pin=="" && $preset_pin==""} {
			set ports [add_to_collection $ports $this_port]
		}
	} 
	return $ports
}

#------------------------------------------------------------------------------
#   get_clock_ports
#		- build a collection of ports declared as clocks' source
#------------------------------------------------------------------------------
proc get_clock_ports {} {
	set ports ""
	foreach_in_collection this_clock [all_clocks] {
		set source_of_clock [get_attribute [get_clocks $this_clock] sources]
		foreach_in_collection one_source $source_of_clock {   
			set object_type [get_attribute $one_source object_class] 
			if {$object_type == "port"} { 
				set ports [add_to_collection $ports $one_source]
			}
		} 
	}
	return $ports
}

#------------------------------------------------------------------------------
#   get_clock_pins
#		- build a collection of pins declared as clocks' source
#------------------------------------------------------------------------------
proc get_clock_pins {} {
	set pins ""
	foreach_in_collection this_clock [all_clocks] {
		set source_of_clock [get_attribute [get_clocks $this_clock] sources]
		foreach_in_collection one_source $source_of_clock {   
			set object_type [get_attribute $one_source object_class] 
			if {$object_type == "pin"} { 
				set pins [add_to_collection $pins $one_source]
			}
		} 
	}
	return $pins
}

#------------------------------------------------------------------------------
#   get_undefined_clock_ports
#		- build a collection of clock ports that is not defined as clock yet
#------------------------------------------------------------------------------
proc get_undefined_clock_ports {} { 
	set undefined [remove_from_collection \
		[get_ports [get_clocking_ports]] \
		[get_ports [get_clock_ports]] \
	]

	if { [sizeof_collection $undefined] != 0 } {
		echo "Undefined Clock Ports : [get_names $undefined]"
	}
	return $undefined
}

#------------------------------------------------------------------------------
#   all_input_but_clock
#		- build a list of all input ports except for clocks
#------------------------------------------------------------------------------
proc all_input_but_clock {} { 
    global synopsys_program_name
   	if { "$synopsys_program_name"=="dc_shell"} {
		set ports [filter_collection \
			[all_inputs] \
			"is_on_clock_network == false" \
		]
	} else {
		set ports [remove_from_collection \
			[all_inputs] \
			[get_clock_ports] \
		]
	}
	return $ports
}

#------------------------------------------------------------------------------
#   all_output_but_clock
#		- build a list of all input ports except for clocks
#------------------------------------------------------------------------------
proc all_output_but_clock {} { 
    global synopsys_program_name
   	if { "$synopsys_program_name"=="dc_shell"} {
		set ports [filter_collection \
			[all_outputs] \
			"is_on_clock_network == false" \
		]
	} else {
	    set ports ""
	   	set clock_sources [add_to_collection [get_clock_ports] [get_clock_pins]]
		foreach_in_collection this_port [all_outputs] {
			set fanins [all_fanin -to $this_port -flat]
			set common [intersect_collections $clock_sources $fanins]
			if { [sizeof_collection $common] == 0 } {
			    set ports [add_to_collection $ports $this_port]
			}
		} 
	}
	return $ports
}

#------------------------------------------------------------------------------
#   set_io_timing
#
#------------------------------------------------------------------------------
proc argHandler {args} {
	parse_proc_arguments -args $args results
	foreach argname [array names results] {
		echo "  $argname = $results($argname)"
	}
	echo "  Bool = $results(-Bool)"
}

define_proc_attributes argHandler -info "argument processor" \
-define_args {
	{-Oos "oos help" AnOos one_of_string {required value_help {values {a b}}}}
	{-Int "int help" AnInt int optional}
 	{-Float "float help" AFloat float optional}
 	{-Bool "bool help" "" boolean optional}
 	{-String "string help" AString string optional}
 	{-List "list help" AList list optional}
}

# for top module
proc set_virtual_clock_timing {} {
	set virtual_clocks [get_virtual_clocks]
	set real_clocks [get_real_clocks]
	foreach_in_collection itr $virtual_clocks {
		set rest [remove_from_collection $virtual_clocks $itr]
		if {[llength $rest] != 0} {
			set_false_path -from $itr  -to $rest
			set_false_path -from $rest -to $itr
			echo ""
			echo "Info: set_false_paths"
			echo "        -from" \[[get_names $itr]\]
			echo "        -to  " \[[get_names $rest]\]
			echo "Info: set_false_paths"
			echo "        -from" \[[get_names $rest]\]
			echo "        -to  " \[[get_names $itr]\]
		}
	}

	foreach_in_collection vclk $virtual_clocks {
		set rclk_tmp [lrange [split [get_names $vclk] ~] 1 end]
		regsub {_RISE|_FALL} $rclk_tmp {} rclk
		set rest [remove_from_collection $real_clocks [get_clocks $rclk]]
		if {[llength $rest] != 0} {
			set_false_path -from $vclk -to $rest
			set_false_path -from $rest -to $vclk
			echo ""
			echo "Info: set_false_paths"
			echo "        -from" \[[get_names $vclk]\]
			echo "        -to  " \[[get_names $rest]\]
			echo "Info: set_false_paths"
			echo "        -from" \[[get_names $rest]\]
			echo "        -to  " \[[get_names $vclk]\]
		}
	}
}


proc set_io_timing_top {args} {
	parse_proc_arguments -args $args results

	set input_ports    [get_ports  $results(-input)]
	set output_ports   [get_ports  $results(-output)]
	set virtual_clocks [get_clocks $results(-virtual)]
	set TRANS_IN       $results(-trans_in)
	set DELAY_IN       $results(-delay_in)
	set DELAY_OUT      $results(-delay_out)

	echo ""
	echo "Info: non-clock input ports identified"
	echo \[[get_names $input_ports]\]

	echo ""
	echo "Info: non-clock output ports identified"
	echo \[[get_names $output_ports]\]

	set_input_transition  $TRANS_IN $input_ports
	echo ""
	echo "Info: set_input_transition $TRANS_IN on input ports"

	foreach_in_collection itr $virtual_clocks {
		set_input_delay  $DELAY_IN  -clock $itr $input_ports  -add_delay
		set_output_delay $DELAY_OUT -clock $itr $output_ports -add_delay
		set_multicycle_path 2 -setup -from $itr -to $itr
		set_multicycle_path 1 -hold  -from $itr -to $itr
		echo ""
		echo "Info: input  delay of $DELAY_IN was set w.r.t [get_names $itr]"
		echo "Info: output delay of $DELAY_OUT was set w.r.t [get_names $itr]"
		echo "Info: multicycle path set on feedback path from input ports to output ports w.r.t [get_names $itr]"
	}

}

define_proc_attributes set_io_timing_top \
  -info "Perform set_input_delay and set_output_delay on ports" \
  -define_args {
	{-virtual   "a list of virtual clocks" virtual_clock_list list}
	{-real      "a list of real clocks"    real_clock_list    list}
	{-input     "a list of input ports"    input_port_list    list}
	{-output    "a list of output ports"   output_port_list   list}
	{-trans_in  "input transition (ns)"    TRANS_IN           float}
	{-delay_in  "input delay (ns)"         DELAY_IN           float}
	{-delay_out "output delay (ns)"        DELAY_OUT          float}
  }


# for sub modules
proc set_io_timing {args} {
	global top_module
	global PLACEMENT

	parse_proc_arguments -args $args results

	set input_ports    [get_ports  $results(-input)]
	set output_ports   [get_ports  $results(-output)]
	set real_clocks    [get_clocks $results(-real)]
	set virtual_clocks [get_clocks $results(-virtual)]
	set DELAY_IN       $results(-delay_in)
	set DELAY_OUT      $results(-delay_out)

	echo ""
	echo "Info: non-clock input ports identified"
	echo \[[get_names $input_ports]\]

	echo ""
	echo "Info: non-clock output ports identified"
	echo \[[get_names $output_ports]\]

	foreach_in_collection itr $virtual_clocks {
		set period [get_attribute $itr period]
		regexp {~(.*)} [get_object_name $itr] all rclk

#		if { [regexp (sddev_sdio|sdio_host_top|nfc_top) $top_module] } {
#				set delays	[expr $period * 0.2]
#		} else {
#			if { [regexp -nocase (clk_arm|clk_ahs|clk_ahb|clk_apb|ahb_clk|apb_clk) [get_names $itr]] } {
#				set delays	[expr $period * 0.1]
#			} else {
#				if { [regexp (ipsec_top) $top_module] } {
#					set delays	[expr $period * 0.7]
#				} else {
#					set delays	[expr $period * 0.6]
#				}
#			}
#		}

		if { [regexp (ipsec_top) $top_module] } {
			set delays	[expr $period * 0.3]
		} elseif { [regexp (cpu_top) $top_module] } {
			set delays	[expr $period * 0.3]
		} elseif { [regexp (gdm7243_core) $top_module] } {
			set delays	[expr $period * 0.5]
		} elseif { [regexp (nfc_top) $top_module] } {
			if { [regexp (clk_flash*) [get_names $itr]] } {
				set delays	[expr $period * 0.1]
			} elseif { [regexp (clk_dqs*) [get_names $itr]] } {
				set delays	[expr $period * 0.3]
			} else {
				set delays	[expr $period * 0.6]
			}
		} else {
			set delays	[expr $period * 0.6]
		}
		if { $delays > 3.0 } {
			set delays	3.0
		}

		set_input_delay  $delays			 -clock $itr $input_ports  -add_delay
		set_output_delay $delays			 -clock $itr $output_ports -add_delay
		set_max_delay    [expr $period * 1.0] -from $itr -fall_to [get_clocks $rclk]
		set_max_delay    [expr $period * 1.0] -fall_from [get_clocks $rclk] -to $itr
		set_max_delay    [expr $period * 2.0] -from $itr -to $itr
		echo ""
		echo "Info: input  delay of $delays set w.r.t [get_names $itr]"
		echo "Info: output delay of $delays set w.r.t [get_names $itr]"
		echo "Info: set_max_delay [expr $period*1.0] on half clock path from input ports to negative flops set w.r.t [get_names $itr]"
		echo "Info: set_max_delay [expr $period*1.0] on half clock path from negative flops to output ports set w.r.t [get_names $itr]"
		echo "Info: set_max_delay [expr $period*2.0] on feedthrough path from input ports to output ports set w.r.t [get_names $itr]"
	}

	foreach_in_collection itr $virtual_clocks {
		set rest [remove_from_collection $virtual_clocks $itr]
		if {[llength $rest] != 0} {
			set_false_path -from $itr  -to $rest
			set_false_path -from $rest -to $itr
			echo ""
			echo "Info: set_false_paths"
			echo "        -from" \[[get_names $itr]\]
			echo "        -to  " \[[get_names $rest]\]
			echo "Info: set_false_paths"
			echo "        -from" \[[get_names $rest]\]
			echo "        -to  " \[[get_names $itr]\]
		}
	}

	foreach_in_collection vclk $virtual_clocks {
		set rclk_tmp [lrange [split [get_names $vclk] ~] 1 end]
		regsub {_RISE|_FALL} $rclk_tmp {} rclk
		set rest [remove_from_collection $real_clocks [get_clocks $rclk]]
		if {[llength $rest] != 0} {
			set_false_path -from $vclk -to $rest
			set_false_path -from $rest -to $vclk
			echo ""
			echo "Info: set_false_paths"
			echo "        -from" \[[get_names $vclk]\]
			echo "        -to  " \[[get_names $rest]\]
			echo "Info: set_false_paths"
			echo "        -from" \[[get_names $rest]\]
			echo "        -to  " \[[get_names $vclk]\]
		}
	}
}

define_proc_attributes set_io_timing \
  -info "Perform set_input_delay and set_output_delay on ports" \
  -define_args {
	{-virtual   "a list of virtual clocks" virtual_clock_list list}
	{-real      "a list of real clocks"    real_clock_list    list}
	{-input     "a list of input ports"    input_port_list    list}
	{-output    "a list of output ports"   output_port_list   list}
	{-delay_in  "input delay (ns)"         DELAY_IN           float}
	{-delay_out "output delay (ns)"        DELAY_OUT          float}
  }

#################################################################################
#	Report Memory Information
#################################################################################
proc report_mem {name} {
	global rpt_dir

	current_design $name 

	set rf_memories		[get_cells -hier * -filter {ref_name=~cmos28lpp_rf*&&is_hierarchical==false}]
	set sr_memories		[get_cells -hier * -filter {ref_name=~cmos28lpp_ra*&&is_hierarchical==false}]
	set rom_memories	[get_cells -hier * -filter {ref_name=~cmos28lpp_vromp*&&is_hierarchical==false}]

#	echo "rf_memories	=[get_names $rf_memories]"
#	echo "sr_memories	=[get_names $sr_memories]"
#	echo "rom_memories	=[get_names $rom_memories]"

	set memories	[list ]
	set mem_cnt		0
	if { [sizeof_collection $rf_memories]!=0 } {
		set memories	[add_to_collection $memories $rf_memories]
		set mem_cnt		[expr $mem_cnt+1]
	}
	if { [sizeof_collection $sr_memories]!=0 } {
		set memories	[add_to_collection $memories $sr_memories]
		set mem_cnt		[expr $mem_cnt+1]
	}
	if { [sizeof_collection $rom_memories]!=0 } {
		set memories	[add_to_collection $memories $rom_memories]
		set mem_cnt		[expr $mem_cnt+1]
	}

	if { $mem_cnt==0 } {
		echo "there are no memories ..."
		return 0
	}

	set Macros [list ]
	foreach_in_collection m $memories {
		set ref [get_attribute $m ref_name]
		lappend Macros $ref
	}

	set Macros [lsort -unique $Macros]
	set mem_list	[list ]

	set file	$rpt_dir/${name}_mem.info.rpt
	set fp [open $file w]

	set total_cnt	0
	foreach ref $Macros {
		if { [regexp -expanded {(cmos28lpp_vromp|cmos28lpp_rf|cmos28lpp_ra).*} $ref all] } {
			set ins [get_references -quiet -hier $ref]

			if { [sizeof_collection $ins] > 0 } {
				for {set i 0} {$i<[sizeof_collection $ins]} {incr i 1} {
					lappend hier_list [list $ref [get_object_name [index_collection $ins \
						[expr [sizeof_collection $ins] - $i - 1]]]]
					set hier [get_object_name [index_collection $ins \
						[expr [sizeof_collection $ins] - $i - 1]]]
					echo "$ref, $hier"
					puts $fp "$ref $hier"
					set total_cnt	[expr $total_cnt+1]
				}
			}
		}
	}
	echo "Total Memory instances in $name : $total_cnt"
	puts $fp "Total Memory instances in $name : $total_cnt"
	close $fp
}

proc report_design_area {name level} {
	global	syn_home

	current_design $name 

	set rf_memories		[get_cells -hier * -filter {ref_name=~cmos28lpp_rf*&&is_hierarchical==false}]
	set sr_memories		[get_cells -hier * -filter {ref_name=~cmos28lpp_ra*&&is_hierarchical==false}]
	set rom_memories	[get_cells -hier * -filter {ref_name=~cmos28lpp_vromp*&&is_hierarchical==false}]

#	echo "rf_memories	=[get_names $rf_memories]"
#	echo "sr_memories	=[get_names $sr_memories]"
#	echo "rom_memories	=[get_names $rom_memories]"

	set memories	[list ]
	set mem_cnt		0
	if { [sizeof_collection $rf_memories]!=0 } {
		set memories	[add_to_collection $memories $rf_memories]
		set mem_cnt		[expr $mem_cnt+1]
	}
	if { [sizeof_collection $sr_memories]!=0 } {
		set memories	[add_to_collection $memories $sr_memories]
		set mem_cnt		[expr $mem_cnt+1]
	}
	if { [sizeof_collection $rom_memories]!=0 } {
		set memories	[add_to_collection $memories $rom_memories]
		set mem_cnt		[expr $mem_cnt+1]
	}

	set Macros [list ]
	foreach_in_collection m $memories {
		set ref [get_attribute $m ref_name]
		lappend Macros $ref
	}

	set Macros [lsort -unique $Macros]
	set mem_list	[list ]

	set mem_area	0
	foreach ref $Macros {
		if { [regexp -expanded {(cmos28lpp_vromp|cmos28lpp_rf|cmos28lpp_ra).*} $ref all] } {
			set ins [get_references -quiet -hier $ref]

			if { [sizeof_collection $ins] > 0 } {
				for {set i 0} {$i<[sizeof_collection $ins]} {incr i 1} {
					lappend hier_list [list $ref [get_object_name [index_collection $ins \
						[expr [sizeof_collection $ins] - $i - 1]]]]
				}

				set area [get_attribute [index_collection $ins 0] area]
				set leakage [get_attribute [index_collection $ins 0] cell_leakage_power]
				set num  [sizeof_collection $ins]
				regexp -expanded {([0-9]+)x([0-9]+)m([0-9]+)} $ref all depth width mux

				set mem_area	[expr $mem_area+$area*$num]

				echo "ins=[get_names $ins], $ref"
				set mem_cnt	[sizeof_collection $ins]
				lappend mem_list	[list $ref $depth $width $mem_cnt $mux $area]
			}
		}
	}

	source $syn_home/scr/common/area_report.tcl

	set total_area	[format "%.2f" [area_report -levels $level]]
	set sc_area		[format "%.2f" [expr $total_area-$mem_area]]
	set mem_area	[format "%.2f" $mem_area]

	echo "total_area	= $total_area"
	echo "sc_area		= $sc_area"
	echo "memory area	= $mem_area"
}

proc report_sub_mem {name} {
	current_design $name 

	set rf_memories		[get_cells -hier * -filter {ref_name=~cmos28lpp_rf*&&is_hierarchical==false}]
	set sr_memories		[get_cells -hier * -filter {ref_name=~cmos28lpp_ra*&&is_hierarchical==false}]
	set rom_memories	[get_cells -hier * -filter {ref_name=~cmos28lpp_vromp*&&is_hierarchical==false}]

#	echo "rf_memories	=[get_names $rf_memories]"
#	echo "sr_memories	=[get_names $sr_memories]"
#	echo "rom_memories	=[get_names $rom_memories]"

	set memories	[list ]
	set mem_cnt		0
	if { [sizeof_collection $rf_memories]!=0 } {
		set memories	[add_to_collection $memories $rf_memories]
		set mem_cnt		[expr $mem_cnt+1]
	}
	if { [sizeof_collection $sr_memories]!=0 } {
		set memories	[add_to_collection $memories $sr_memories]
		set mem_cnt		[expr $mem_cnt+1]
	}
	if { [sizeof_collection $rom_memories]!=0 } {
		set memories	[add_to_collection $memories $rom_memories]
		set mem_cnt		[expr $mem_cnt+1]
	}

	if { $mem_cnt==0 } {
		echo "there are no memories ..."
		report_area;
		return 0
	}

	set Macros [list ]
	foreach_in_collection m $memories {
		set ref [get_attribute $m ref_name]
		lappend Macros $ref
	}

	set Macros [lsort -unique $Macros]
	set mem_list	[list ]

	set total_area	0
	foreach ref $Macros {
		if { [regexp -expanded {(cmos28lpp_vromp|cmos28lpp_rf|cmos28lpp_ra).*} $ref all] } {
			set ins [get_references -quiet -hier $ref]

			if { [sizeof_collection $ins] > 0 } {
				for {set i 0} {$i<[sizeof_collection $ins]} {incr i 1} {
					lappend hier_list [list $ref [get_object_name [index_collection $ins \
						[expr [sizeof_collection $ins] - $i - 1]]]]
				}

				set area [get_attribute [index_collection $ins 0] area]
				set leakage [get_attribute [index_collection $ins 0] cell_leakage_power]
				set num  [sizeof_collection $ins]
				regexp -expanded {([0-9]+)x([0-9]+)m([0-9]+)} $ref all depth width mux

				set total_area	[expr $total_area+$area*$num]

				echo "ins=[get_names $ins], $ref"
				set mem_cnt	[sizeof_collection $ins]
				lappend mem_list	[list $ref $depth $width $mem_cnt $mux $area]
			}
		}
	}

	make_file $name ${mem_list};

	report_area;
	echo "\n"

	set all_cells   [get_cells  -hier * -filter {is_hierarchical==false}]
	set n_cells [sizeof_collection $all_cells]

	echo "total memory area = $total_area"
	echo "n_instances = $n_cells"

	return $total_area
}

proc report_ip_mem {name} {
	set rf_memories		[get_cells -hier * -filter {ref_name=~cmos28lpp_rf*&&is_hierarchical==false}]
	set sr_memories		[get_cells -hier * -filter {ref_name=~cmos28lpp_ra*&&is_hierarchical==false}]
	set rom_memories	[get_cells -hier * -filter {ref_name=~cmos28lpp_vromp*&&is_hierarchical==false}]

	set Macros [list ]
	foreach_in_collection m [add_to_collection [add_to_collection $rf_memories $sr_memories] $rom_memories] {
		set ref [get_attribute $m ref_name]
		lappend Macros $ref
	}

	set Macros [lsort -unique $Macros]

	set inst_list	[list ]

	set wimax_list	[list ]
	set wlan_list	[list ]
	set lte_list	[list ]

	foreach ref $Macros {
		if { [regexp -expanded {(cmos28lpp_vromp|cmos28lpp_rf|cmos28lpp_ra).*} $ref all] } {
			set ins [get_references -quiet -hier $ref]

			if { [sizeof_collection $ins] > 0 } {
				for {set i 0} {$i<[sizeof_collection $ins]} {incr i 1} {
					lappend hier_list [list $ref [get_object_name [index_collection $ins \
						[expr [sizeof_collection $ins] - $i - 1]]]]
				}

				set area [get_attribute [index_collection $ins 0] area]

				set num  [sizeof_collection $ins]
				regexp -expanded {([0-9]+)x([0-9]+)m([0-9]+)} $ref all depth width mux
				lappend inst_list [list $ref $depth $width $num $mux $area]

				set wimax_cnt	0
				set wlan_cnt	0
				set lte_cnt		0
				foreach i [get_names $ins] {
					set ip	[string trim $i I_PD_CORE/I_CORE/I_]
					set idx	[string first "/" $ip]
					set ip_name	[string tolower [string range $ip 0 [expr $idx-1]]]
					echo "ip=$ip,idx=$idx, ip_name=$ip_name"
					if { $ip_name=="wimax"} {
						set wimax_cnt	[expr $wimax_cnt+1]
					} elseif { $ip_name=="wlan"} {
						set wlan_cnt	[expr $wlan_cnt+1]
					} elseif { $ip_name=="lte"} {
						set lte_cnt		[expr $lte_cnt+1]
					}
				}

				if { $name=="wimax" && $wimax_cnt>0 } {
					lappend wimax_list	[list $ref $depth $width $wimax_cnt $mux $area]
				} elseif { $name=="wlan" && $wlan_cnt>0 } {
					lappend wlan_list	[list $ref $depth $width $wlan_cnt $mux $area]
				} elseif { $name=="lte" && $lte_cnt>0 } {
					lappend lte_list	[list $ref $depth $width $lte_cnt $mux $area]
				}
			}
		}
	}

	if { $name=="wimax" } {
		make_file $name ${wimax_list};
	} elseif { $name=="wlan" } {
		make_file $name ${wlan_list};
	} elseif { $name=="lte" } {
		make_file $name ${lte_list};
	}
}


proc make_file {name m_list} {
	global	rpt_dir

	set file	$rpt_dir/${name}_mem.rpt
	set fp [open $file w]

	puts $fp "Memory instances in $name"
	puts $fp [format "%-35s %6s %6s %3s %3s %11s " \
		Name Depth Width Ins Mux Area \
	]

	set total 	0
	set t_area	0

	foreach i $m_list {
		puts $fp [format "%-35s %6d %6d %3d %3d %11.3f" \
			[lindex $i 0 ] \
			[lindex $i 1 ] \
			[lindex $i 2 ] \
			[lindex $i 3 ] \
			[lindex $i 4 ] \
			[lindex $i 5 ] \
		]
		set total	[expr $total  + [lindex $i 3]]
		set t_area	[expr $t_area + [lindex $i 3]*[lindex $i 5]]
	}

	puts $fp [format "========================================"]
	puts $fp [format "%-49s %3d\t\t%11.3f" Total $total $t_area]

	echo "\ttotal_inst = $total"

	close $fp
}

proc div_grp_with_mtype {fp cnt ip_list} {
	set ip_list		[lsort $ip_list]

	set	rom_list	[list ]
	set s1p_list	[list ]
	set s2p_list	[list ]
	set ram_list	[list ]
	foreach mem $ip_list {
		set mem_hier		[lindex $mem 0]
		set mem_type		[lindex $mem 1]
		set mem_depth		[lindex $mem 2]
		set mem_width		[lindex $mem 3]
		set mem_mux			[lindex $mem 4]
		set mem_area		[lindex $mem 5]

		if { [regexp {vromp} $mem_type]} {
			lappend rom_list	[list $mem_hier $mem_type $mem_depth $mem_width $mem_mux $mem_area]
		} else {
			lappend ram_list	[list $mem_hier $mem_type $mem_depth $mem_width $mem_mux $mem_area]

			if { [regexp {ra1|rf1} $mem_type]} {
				lappend s1p_list	[list $mem_hier $mem_type $mem_depth $mem_width $mem_mux $mem_area]
			} else {
				lappend s2p_list	[list $mem_hier $mem_type $mem_depth $mem_width $mem_mux $mem_area]
			}
		}
	}

	set rom_cnt	[div_grp_with_clksrc $fp $cnt $rom_list]
	set ram_cnt	[div_grp_with_clksrc $fp $rom_cnt $ram_list]
#	set s1p_cnt	[div_grp_with_clksrc $fp $rom_cnt $s1p_list]
#	set s2p_cnt	[div_grp_with_clksrc $fp $s1p_cnt $s2p_list]

	return $ram_cnt
}

proc div_grp_with_clksrc {fp cnt ip_list} {
	global	SYN_MARGIN
#	echo "ip_list=$ip_list"
	if { $ip_list=="" } {
		return $cnt
	}

	###########################################################
	# clock frequency grouping
	###########################################################
	set mlist_freq	[list ]
	foreach mem $ip_list {
		set mem_hier		[lindex $mem 0]
		set mem_type		[lindex $mem 1]
		set mem_depth		[lindex $mem 2]
		set mem_width		[lindex $mem 3]
		set mem_mux			[lindex $mem 4]
		set mem_area		[lindex $mem 5]

		set clk_src 	[find_csrc_mem $mem_type $mem_hier 1]
		set clk_per 	[expr [get_attribute [get_clocks $clk_src] period]/$SYN_MARGIN]
		set clk_freq	[format "%d" [expr int(1/$clk_per*1000)]]

		lappend mlist_freq	[list $clk_freq $clk_src \
								$mem_hier $mem_type $mem_depth $mem_width $mem_mux $mem_area]
	}
	set ip_list	[lsort $mlist_freq]

	###########################################################
	# memory grouping
	###########################################################
	set mlist [lsort $ip_list]
	echo "mlist=$mlist"

	set prev_freq	""
	set prev_mtype	""
	set mem_cnt	1
	foreach mem $mlist {
		set clk_freq		[lindex $mem 0]
		set clk_sname		[lindex $mem 1]
		set mem_hier		[lindex $mem 2]
		set mem_type		[lindex $mem 3]
		set mem_depth		[lindex $mem 4]
		set mem_width		[lindex $mem 5]
		set mem_mux			[lindex $mem 6]
		set mem_area		[lindex $mem 7]

		echo "\t"

		set new_grp	0
		regsub -all {/} $mem_hier {.} mem_hier

		if { $prev_freq != "" } {
			if { $prev_freq != $clk_freq } {
				set new_grp	1
			} else {
				set mem_cnt	[expr $mem_cnt+1]
#				if { $mem_cnt>100 } {
#					if { $prev_mtype!=$mem_type } {
#						set mem_cnt	1
#						set new_grp	1
#					}
#				}
				set prev_mtype	$mem_type
			}
		} else {
			set new_grp	1
		}
		set prev_freq	$clk_freq

		set mem_type	[format "%*s" 35 $mem_type]
		set clk_sname	[format "%*s" 45 $clk_sname]

		regsub -all {([a-zA-Z0-9_]+).} $mem_hier {\1 } wrap_name
		set wrap_name	[string toupper $wrap_name]
#		echo "1.wrap_name=$wrap_name"
		regsub -all {I_} $wrap_name {} wrap_name
#		regsub -all {[0-9]} $wrap_name {} wrap_name
		regsub -all {CORE } $wrap_name {} wrap_name
		if { [string length $wrap_name] > 50 } {
			regsub -all {MEM } $wrap_name {} wrap_name
			regsub -all {IP } $wrap_name {} wrap_name
			regsub -all {PHY } $wrap_name {} wrap_name
			regsub -all {PHY[a-zA-Z0-9_] } $wrap_name {} wrap_name
		}
#		echo "2.wrap_name=$wrap_name"
		regexp -expanded { \
					([a-zA-Z0-9_]+)\s+\
					([a-zA-Z0-9_]+)\s+\
					([a-zA-Z0-9_]+)} \
				$wrap_name all h0 h1 h2
#		echo "3.wrap_name=$wrap_name, $h0,$h1,$h2"

		if { $new_grp==1 } {
			set scnt	0
			set gcnt	$cnt
			if { $cnt<10 } {
				set grp_name	[format "%*s" 20 "Memory Group 0$cnt"]
#				set wrap_name	"AAAA"
			} else {
				set grp_name	[format "%*s" 20 "Memory Group $cnt"]
#				set wrap_name	"BBBB"
			}
			set cnt [expr $cnt+1]
		} else {
			set scnt	[expr $scnt+1]
				set grp_name	[format "%*s" 20 ""]
#				set wrap_name	"CCCC"
		}

		set wrap_name	MEM_G${gcnt}_${h0}_${h1}_${h2}
		set wrap_name	${wrap_name}_${clk_freq}M_${scnt}
		set wrap_name	[format "%*s" 60 $wrap_name]		
		set clk_fname	[format "%*s" 4 $clk_freq]

		echo "\t($new_grp,$cnt,$mem_cnt)"
		echo "\tmem_hier=$mem_hier"
		echo "\tmem_type=$mem_type"
		echo "\tmem_area=$mem_area um^2"
		echo "\t$prev_freq"
		echo "\t$clk_sname"
		echo "\t$clk_freq MHz, $clk_per"
		echo "\twrap_name=$wrap_name"

		if { [regexp {_vrom} $mem_type] } {
			set rd_clk_name	[format "%*s" 5 "CLK"]		
			set wr_clk_name	[format "%*s" 5 ""]		
		} elseif { [regexp {_rf1|_ra1} $mem_type] } { 
			set rd_clk_name	[format "%*s" 5 "CLK"]		
			set wr_clk_name	[format "%*s" 5 "CLK"]		
		} else {
			set rd_clk_name	[format "%*s" 5 "CLKA"]		
			set wr_clk_name	[format "%*s" 5 "CLKB"]		
		}
		puts $fp [format "$grp_name $mem_type  1 $wrap_name $clk_fname $rd_clk_name $wr_clk_name   $mem_hier"]
	}

	return $cnt
}

proc report_mem_area {a} {
	global rpt_dir

	set rpt_file	${rpt_dir}/${a}_mem.rpt

	current_design $a

	set hier_list [list ]
	set inst_list [list ]

	set rf_memories		[get_cells -hier * -filter {ref_name=~cmos28lpp_rf*&&is_hierarchical==false}]
	set sr_memories		[get_cells -hier * -filter {ref_name=~cmos28lpp_ra*&&is_hierarchical==false}]
	set rom_memories	[get_cells -hier * -filter {ref_name=~cmos28lpp_vromp*&&is_hierarchical==false}]

	set Macros [list ]
	foreach_in_collection m [add_to_collection [add_to_collection $rf_memories $sr_memories] $rom_memories] {
		set ref [get_attribute $m ref_name]
		lappend Macros $ref
	}

	set Macros [lsort -unique $Macros]

	foreach ref $Macros {
		if { [regexp -expanded {(cmos28lpp_vromp|cmos28lpp_rf|cmos28lpp_ra).*} $ref all] } {
			set ins [get_references -quiet -hier $ref]
			if { [sizeof_collection $ins] > 0 } {
				for {set i 0} {$i<[sizeof_collection $ins]} {incr i 1} {
					lappend hier_list [list [get_object_name [index_collection $ins \
						[expr [sizeof_collection $ins] - $i - 1]]]]
				}

	#			set area [get_attribute [index_collection $ins 0] area]
	#			set leakage [get_attribute [index_collection $ins 0] cell_leakage_power]
	#			echo "$ref:area=$area, leakage=$leakage"

				regexp -expanded {([0-9]+)x([0-9]+)m([0-9]+)} $ref all depth width mux

				set num 1
				foreach i [get_names $ins] {
					set area	[get_attribute $i area]
					echo "$i:area=$area"

					lappend inst_list [list $i $ref $depth $width $num $mux $area]
				}
			}
		}
	}

	set fp [open $rpt_file w]

	puts $fp "Memory instances"
	puts $fp [format "%-60s %-35s %6s %6s %3s %3s %11s " \
		Hierarchy Name Depth Width Ins Mux Area \
	]

	set total 0
	set t_area	0

	set inst_list	[lsort $inst_list]

	foreach i $inst_list {
		puts $fp [format "%-60s %-35s %6d %6d %3d %3d %11.3f" \
			[lindex $i 0 ] \
			[lindex $i 1 ] \
			[lindex $i 2 ] \
			[lindex $i 3 ] \
			[lindex $i 4 ] \
			[lindex $i 5 ] \
			[lindex $i 6 ] \
		]
		set total	[expr $total  + [lindex $i 4]]
		set t_area	[expr $t_area + [lindex $i 4]*[lindex $i 6]]
	}

	puts $fp [format "==================================================================================="]
	puts $fp [format "%-110s %3d\t\t%11.3f" Total $total $t_area]

	close $fp
}

proc get_minfo {file mem_hier mem_type h_flag grp_num} {
	global	SYN_MARGIN

	set mem_info	[list ]
	set flag		0

	set clk_src [find_csrc_mem $mem_type $mem_hier 1]
	set clk_per [expr [get_attribute [get_clocks $clk_src] period]/$SYN_MARGIN]

	set clk_sname	[get_names $clk_src]
	set clk_freq	[expr int(1/$clk_per*1000)]
#	regsub -all {/} $mem_hier {.} mem_hier

	set mem_type	[format "%*s" 35 $mem_type]
	set clk_sname	[format "%*s" 45 $clk_sname]
	set clk_fname	[format "%*s" 4 $clk_freq]

	puts $file [format "$mem_type $clk_sname $clk_fname  $mem_hier"]

	return [get_names $clk_src]
}

proc find_csrc_mem {mem_type mem_hier mode} {
	# mode=0	slow
	# mode=1	fast

	if { [regexp {cmos28lpp_vromp} $mem_type] } {
		set clock		[get_attribute [get_timing_path -from $mem_hier/Q*]	endpoint_clock]
	} else { 
		set clock		[get_attribute [get_timing_path -to $mem_hier/D*]	startpoint_clock]
	}

	echo "\t\t"
	echo "\t\t(find_csrc_mem)mem_type=$mem_type"
	echo "\t\t(find_csrc_mem)mem_hier=$mem_hier"
	echo "\t\t(find_csrc_mem)clock=[get_names $clock]"

	if { [get_names $clock]=="" } {
		echo "\t\t\t(find_csrc_mem)no clock definition ..."
		set ref_clk	CLK_2X
		return $ref_clk
	}

	set	ref_per	0
	set ref_clk	[list ]
	foreach_in_collection clk $clock {
		set clk_per	[format "%.3f" [get_attribute [get_clocks $clk] period]]
#		echo "\t\t(find_csrc_mem)clk=[get_names $clk], clk_per=$clk_per"
		if { $ref_per==0 } {
			set ref_per $clk_per
			set ref_clk	$clk
		} else {
			if { $mode==0 } {
				if { $ref_per >= $clk_per } {
					set clk_per	$ref_per
					set ref_clk	$clk
				}
			} else {
				if { $ref_per <= $clk_per } {
					set clk_per	$ref_per
					set ref_clk	$clk
				}
			}
		}
	}

	return [get_names $ref_clk]
}

proc find_wrappers {all_wrapper num} {

	set wlist	[list ]
	foreach wrap $all_wrapper {
		set proc_num	[lindex $wrap 0]
		set wrapper		[lindex $wrap 1]

		if { $proc_num==$num } {
			lappend wlist	[list $wrapper:1]
		}
	}

	return $wlist
}

proc find_macro_number {macro_list macro} {

	set mm_num	0
	foreach mm $macro_list {
		set name	[lindex $mm 0]
		set num		[lindex $mm 1]

		if { $name==$macro } {
			echo "\tmacro=$mm, name=$name, num=$num"
			set mm_num	$num
		}
	}

	return $mm_num
}

###############################################

proc my_change_link {args} {
# Example :
# 1) my_change_link I_ALU/U5 core_slow.db:ssc_core_slow/and2b6
# 2) my_change_link "U9 I_ALU/U23 I_CONTROL/U10" core_slow.db:ssc_core_slow/and2b6
# 3) set weak_clock_cells [get_cell -hier CLKBUF* ]
#    my_change_link $weak_clock_cells core_slow.db:ssc_core_slow/clk1a6
# 4) my_change_link clk1a3 core_slow.db:ssc_core_slow/clk1a6

	set tempcells [lindex $args 0]
	set final_ref_cell [lindex $args 1]
	if { [sizeof_coll [get_cell $final_ref_cell] ] !=1 } {
		echo "ERROR: Cannot find library cell $final_ref_cell"
			return {0}
	}
	set mycells [get_cell $tempcells]
	if { [sizeof_coll $mycells]==0  } {
		echo "INFO: Finding and replacing cells with this refernce($tempcells)...."
		set mycells [get_cell -hier * -filter "@ref_name==$tempcells"]
		if { [sizeof_coll $mycells]==0  } {
			echo "ERROR: Cannot find any cell with reference $tempcells"
			return {0}
		}
	}
	set my_top_design [current_design]

	foreach_in_collection onecell $mycells { 
		set fname [get_attribute [get_cell [get_object_name $onecell] ] full_name] 
		set sname [get_attribute [get_cell [get_object_name $onecell] ] name] 
		if {$sname != $fname} { 
			set parent_charnum [string last $sname $fname]
				incr parent_charnum -2
				set parent_instance [string range $fname 0 $parent_charnum]
				redirect /dev/null {current_design [get_attribute $parent_instance ref_name]}
		}
		echo "INFO: Changing reference of cell $fname to $final_ref_cell ...." 
			change_link $sname $final_ref_cell 
			redirect /dev/null {current_design $my_top_design } 
	}
}

proc listrev {str} {
	set l [llength $str]
	set l [expr $l-1]
	set rev	""
	for {set i $l} {$i>=0} {incr i -1} {
		lappend rev [lindex $str $i]
	}
	puts "revesred lists=$rev"
	return $rev
}

proc get_bist_clocks {bist_clk} {
	global P_CLK_SHIFT
	echo ""
	echo "Info: Definition to BIST Clocks ..."
	set i 0
	foreach lst $bist_clk { 
		set idx		[lindex $lst 0]
		set port	[lindex $lst 1]
		set period	[lindex $lst 2]

		if { $idx=="0" } {
			set clk_name	BIST_CON_CLK_${i}
		} else {
			set clk_name	BIST_CLK_${i}
		}

		create_clock \
			-name $clk_name \
			[get_ports $port] \
			-period $period \
			-waveform [list 0 [expr $period/2.0]] ;

		set i [expr $i+1]
	}

	create_clock \
		-name BIST_PIPE_SCLK \
		[get_port i_pipe_sclk] \
		-period $P_CLK_SHIFT \
		-waveform [list 0 [expr $P_CLK_SHIFT/2.0]];
}

proc get_bist_scan_clocks {bist_scan_clk} {
	set i 0
	foreach lst $bist_scan_clk { 
		set port	[lindex $lst 0]
		set period	[lindex $lst 1]

		create_clock \
			-name TEST_CLK_BIST_${i} \
			[get_ports $port] \
			-period $period \
			-waveform [list 0 [expr $period/2.0]] ;

		set i [expr $i+1]
	}
}

proc write_flatten {design net top} {
	global syn_dir
	global DSTAMP
	set verilog_dir $syn_dir/veri

	set DESIGN_MODULE $design
	current_design $DESIGN_MODULE

	remove_design -all
	read_verilog ${net}

	current_design $DESIGN_MODULE
	set_fix_multiple_port_nets -all -buffer_constants [get_designs *]
	change_names -rules verilog -hierarchy -verbose
	write -hier -f verilog -output $verilog_dir/${DESIGN_MODULE}.hier.v

	set fp_ci	[open $verilog_dir/core_init					r]
	#
	set all_core_values [list ]
	while { [gets $fp_ci cline] >= 0 } {
		lappend all_core_values $cline
	}

	set all_core_outputs [list ]
	if { $top == 1} {
		set core_outputs	[get_object_name [get_pins I_PD_CORE/* -filter "pin_direction==out"]]
		set core_outputs	[lsort $core_outputs]
		set cnt 0
		foreach out $core_outputs {
			set a [string first "/" $out]
			set b [string length $out]
			set c [string range $out [expr $a+1] [expr $b-1]]
			set d [regsub -all {\[} $c {_}]
			set e [regsub -all {\]} $d {_}]
			set sig_name  [get_object_name [get_nets -of [get_pins $out]]]
			if { [llength $sig_name] > 0 } {
				set inst_name U_${e}
				set sig_value [lindex $all_core_values $cnt]
				echo "core_output=$out, $inst_name $sig_name $sig_value a=$a b=$b c=$c d=$d e=$e"
				lappend all_core_outputs [list $inst_name $sig_name $sig_value $c]
				set cnt [expr $cnt+1]
			}
		}
		write -hier -f verilog -output $verilog_dir/${DESIGN_MODULE}.before.remove_core.v
		set core_name [get_attribute [get_cells I_PD_CORE] ref_name]
		remove_design $core_name
#		remove_cell I_PD_CORE
	}
	write -hier -f verilog -output $verilog_dir/${DESIGN_MODULE}.before.flat.v

	set_dont_touch [get_nets *]
	ungroup -all -flatten

#	define_name_rules verilog -check_bus_indexing_use_type_info
	change_names -rules verilog -hierarchy -verbose

	write -hier -f verilog -output		$verilog_dir/${DESIGN_MODULE}.flat.v
#	write -pg -hier -f verilog -output	$verilog_dir/${DESIGN_MODULE}.flat.pre.pg.v

	set fp_r	[open $verilog_dir/${DESIGN_MODULE}.flat.v		r]
	set fp_w	[open $verilog_dir/${DESIGN_MODULE}.flat.pg.v	w]
	set fp_c	[open $verilog_dir/dump_core.v					w]

	echo "DESIGN_MODULE=${DESIGN_MODULE}"

	set first_module	1
	set first_wire		1
	set first_cell		1
	set core_cell		0
	while { [gets $fp_r sline] >= 0 } {
		if { [regexp {wire } $sline] } {
			if { $first_wire == 1 } {
				puts $fp_w [format "inout  VDD, VSS;"]
				puts $fp_w [format "wire  TIEHI;"]
				puts $fp_w [format "wire  TIELOW;"]
				puts $fp_w [format "TIEHHVT	U_TIEHI  (.VDD(VDD), .VSS(VSS), .Z(TIEHI));"]
				puts $fp_w [format "TIELHVT U_TIELOW (.VDD(VDD), .VSS(VSS), .Z(TIELOW));"]
				set first_wire  0
			}
		}

		if { [regexp { U[0-9] \( } $sline] } {
			if { $first_cell == 1 } {
				echo "first_cell=$sline, [llength $all_core_outputs]"
				set first_cell	0
				puts $fp_c [format "integer c;"]
				puts $fp_c [format "initial begin"]
				puts $fp_c [format "\tc = \$fopen\(\"../../../fe/syn/veri/core_init\",   \"w\"\);"]
				puts $fp_c [format "end"]
				puts $fp_c [format "always \@\(posedge tb_top.I_DUT.I_PD_CORE.RESET_INT\) begin"]
				foreach c $all_core_outputs {
					if { [regexp {test_so|u_coef_tbl_out|u_LABEL_BUF_out} [lindex $c 3]] } {
						echo "\t!!!inst=[lindex $c 0], sig=[lindex $c 1]"
						puts $fp_w [format "BUFFD0HVT [lindex $c 0] (.VDD(VDD), .VSS(VSS), .I(TIELOW), .Z([lindex $c 1]));"]
					} else {
						echo "\tinst=[lindex $c 0], sig=[lindex $c 1], val=[lindex $c 2]"
						if { [lindex $c 2] == "0" } {
							puts $fp_w [format "BUFFD0HVT [lindex $c 0] (.VDD(VDD), .VSS(VSS), .I(TIELOW), .Z([lindex $c 1]));"]
						} else {
							puts $fp_w [format "BUFFD0HVT [lindex $c 0] (.VDD(VDD), .VSS(VSS), .I(TIEHI), .Z([lindex $c 1]));"]
						}
						puts $fp_c [format "\t\$fwrite(c, \"%%b\\n\", tb_top.I_DUT.I_PD_CORE.[lindex $c 3]);"]
					}
				}
				puts $fp_c [format "end"]

			}
		}

		if { [regexp {1'b1|1'b0} $sline] } {
			#echo "TIE..."
			regsub -all {1'b1} $sline {TIEHI}	tmp0
			regsub -all {1'b0} $tmp0  {TIELOW}	tmp1
			#echo "  $sline"
			#echo "  $tmp0"
			#echo "  $tmp1"
			set sline	$tmp1
		}

		if { [regexp { \( \.} $sline] } {
			set start	[string first " \( \." $sline]
			set sline	[string replace $sline $start [expr $start+3] " (.VDD(VDD), .VSS(VSS), ."]
		}

		if { [regexp { I_PD_CORE \(} $sline] } {
			puts $fp_w [format "/*"]
			set core_cell	1
		}

		puts $fp_w [format "$sline"]

		if { [regexp {module ANA1703_CHIP \( } $sline] } {
			if { $first_module == 1 } {
				puts $fp_w [format "VDD, VSS,"]
				set first_module  0
			}
		}

		if { [regexp { \);} $sline] } {
			if { $core_cell == 1 } {
				puts $fp_w [format "*/"]
				set core_cell	0
			}
		}
	}
	close $fp_r
	close $fp_w
	close $fp_c
	close $fp_ci

	file copy -force 	$verilog_dir/${DESIGN_MODULE}.flat.pg.v \
						$verilog_dir/${DESIGN_MODULE}.flat.pg.${DSTAMP}.v
}

proc get_unclocked_registers {} {
	set seq_cells [all_registers -cells]
	set reg_num [sizeof_collection $seq_cells]
	echo "Total Registers = $reg_num"
	set num_without_clocks $reg_num
	set regs_without_clock $seq_cells
	set des_clocks [get_clocks *]
	foreach_in_collection col_clk $des_clocks {
		set this_clock [get_object_name $col_clk]
		set this_clock_regs [all_registers -cells -clock $this_clock]
		set size_this_clock [sizeof_collection $this_clock_regs]
		echo "\tthis_clock=$this_clock, $size_this_clock"
		set num_without_clocks [expr $num_without_clocks - $size_this_clock]
		set regs_without_clock [remove_from_collection $regs_without_clock $this_clock_regs]
	}
	echo "\tList of registers whose clock pins donot receive clock"
	query_objects $regs_without_clock
}
