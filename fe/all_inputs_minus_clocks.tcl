proc all_inputs_minus_clocks {} {
  # create a collection of all input ports
  set nonclockports [all_inputs]
  foreach_in_collection i [all_clocks] {
    # get the collection containing any potential port/pin clock sources
    set clkport [get_ports -quiet [get_attribute -quiet $i sources]]

    # remove this clock port (if any) from our non-clock input collection
    set nonclockports [remove_from_collection $nonclockports $clkport]
  }
  return $nonclockports
}
