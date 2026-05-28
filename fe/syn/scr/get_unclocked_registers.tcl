proc get_unclocked_registers {} {
	set seq_cells [all_registers -cells]
	set reg_num [sizeof_collection $seq_cells]
	set num_without_clocks $reg_num
	set regs_without_clock $seq_cells
	set des_clocks [get_clocks *]
	foreach_in_collection col_clk $des_clocks {
		set this_clock [get_object_name $col_clk]
		set this_clock_regs [all_registers -cells -clock $this_clock]
		set size_this_clock [sizeof_collection $this_clock_regs]
		set num_without_clocks [expr $num_without_clocks - $size_this_clock]
		set regs_without_clock [remove_from_collection $regs_without_clock $this_clock_regs]
	}
	echo "List of registers whose clock pins donot receive clock"
	foreach c [get_object_name $regs_without_clock] {
		echo "$c"
	}

	query_objects $regs_without_clock
}
