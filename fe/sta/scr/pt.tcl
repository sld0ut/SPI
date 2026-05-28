
set PLACEMENT	"pre"
set mode_list 	[list max min]

foreach mode $mode_list {
	echo "mode=$mode"
	source ../scr/primetime_run.tcl
}
exit
