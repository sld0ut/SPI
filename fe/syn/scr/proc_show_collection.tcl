
# ⓒ 2014 Synopsys, Inc. All rights reserved. 
# # This script is proprietary and confidential information of 
# Synopsys, Inc. and may be used and disclosed only as authorized 
# per your agreement with Synopsys, Inc. controlling such use and disclosure.

#################################################
#Author Narendra Akilla
#Applications Consultant
#Company Synopsys Inc.
#Not for Distribution without Consent of Synopsys
#proc_show_collection - prints collection items per line for easy reading
#################################################

proc proc_show_collection { args } {

    #version 1.11
    #define_args fix for 1603
    #support added for lists also
    parse_proc_arguments -args ${args} opt

    set force [info exists opt(-force)]

    set coll $opt(coll) 

    if {[regexp {^_sel[0-9]+$} $coll]} { set size [sizeof_collection $coll] ; set is_list 0 } else { set size [llength $coll] ; set is_list 1 }

    if {$size < 5000 || $force} {
      if {$is_list} {
        echo [join $coll \n]
        echo "Size of list: $size"
      } else {
        echo [join [get_attr -quiet $coll full_name] \n]
        echo "Size of collection: $size"
      }
    } else {
      echo "Size of Collection/List is $size, use -force to display" ;
    }
}

define_proc_attributes proc_show_collection -info "USER PROC:displays items in a collection line by line" \
      -define_args { \
                  { -force "Force display" 	""     		boolean optional }
                  { coll   "Collection"     	"collection"    	list 	required }
                  }

echo "\tproc_show_collection"
