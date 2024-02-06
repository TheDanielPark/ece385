#
# This file contains BSP utility procedures related to the linker script.
#

# Set default linker script memory regions
proc set_default_memory_regions { { default_memory_regions "CHOOSE_DEFAULT" } } {
    # Don't change memory regions settings if requested.
    if { $default_memory_regions == "DONT_CHANGE" } {
        return
    }

    add_default_memory_regions
}

# Set default mapping of default linker script sections
proc set_default_sections_mapping { { default_sections_mapping "CHOOSE_DEFAULT" } } {
    # Don't change sections mapping if requested.
    if { $default_sections_mapping == "DONT_CHANGE" } {
        return
    }
   
    if { $default_sections_mapping == "CHOOSE_DEFAULT" } {
         set default_data_sections_mapping [choose_default_memory "DATA"]
    } else {
        set default_data_sections_mapping $default_sections_mapping
    }

    log_default "Default data linker sections mapped to $default_data_sections_mapping"
    
    add_default_linker_section_mappings $default_data_sections_mapping
}

# Set specified mapping of specified linker script sections (if any).
# Section mappings are specified in the following format:
#   <section_name>=<region_name>
proc set_specified_section_mappings { { section_mappings "" } } {
    foreach {mapping} $section_mappings {
        set parsed_mapping [split $mapping =]

        if { [llength $parsed_mapping] != 2 } {
            error "set_specified_section_mappings: Format for $mapping doesn't match <section_name>=<region_name> format"
        }

        set section_name [lindex $parsed_mapping 0]
        set region_name [lindex $parsed_mapping 1]

        log_default "Setting specified section $section_name to map to region $region_name"
        add_section_mapping $section_name $region_name
    }
}

# Deletes all existing (current) memory regions.
proc delete_all_memory_regions {} {
    # Gets a list of the currently defined memory regions.
    set current_regions [get_current_memory_regions]

    foreach { region_info } $current_regions {
        set region_name [lindex $region_info 0]
        delete_memory_region $region_name
    }
}


# Deletes all existing (current) section mappings
proc delete_all_section_mappings {} {
    # Gets a list of the currently defined section mappings.
    set current_sections [get_current_section_mappings]

    foreach { section_info } $current_sections {
        set section_name [lindex $section_info 0]
        delete_section_mapping $section_name
    }
}

# Sets thread stack size setting to best guess value for system
proc calculate_thread_stack_size {} {
     # Get thread number supported by DPX processor
    set thread_num [get_nios2_dpx_thread_num]
    if {$thread_num == ""} {
        error "get_nios2_dpx_thread_num: number of threads found for BSP DPX processor"
    }

     # Gets a list of the currently defined section mappings.
    set stack_region_name [get_section_mapping ".stack"]
    if {$stack_region_name == ""} {
        error "get_section_mapping: no .stack section mapping found"
    }

     # Gets a list of the currently defined section mappings.
    set shared_region_count 0
    set current_sections [get_current_section_mappings]
    foreach { section_info } $current_sections {
        set region_name [lindex $section_info 1]
        if {$region_name == $stack_region_name} {
       set shared_region_count [expr $shared_region_count + 1]
  }
    }

    # we will scale the stack memory region size down if it is shared with other sections.
    set stack_scale 1.0 
    # rule of thumb scale factor to share stack with others (e.g. rwdata)
    if {$shared_region_count > 1} {
  set stack_scale .75 
    }

    # Get the memory region info.
    set region_info [get_memory_region $stack_region_name]

    if {$region_info == ""} {
        error "get_nios2_dpx_thread_num: no memory region info for region $stack_region_name"
    }

    # Extract the slave descriptor from the memory region info.
    set stack_region_size [lindex $region_info 3]

    set thread_stack_size [expr {$stack_region_size * $stack_scale / $thread_num}]
    set thread_stack_size [expr int($thread_stack_size)]

    set_setting "lwhal.thread_stack_size" $thread_stack_size 
}

# Choose default memory.  
#
# The default action is to find the largest, volatile memory, as determined 
# by address span.  If all memories are non-volatile, then we fall back to 
# the largest non-volatile memory.
#
# The legal values for the inst_data parameter are:
#   ANY     Consider any memory connected to any of the CPU masters
#   INST    Only consider memories connected to CPU instruction master
#   DATA    Only consider memories connected to CPU data master
#
# Returns the name of the chosen region.

proc choose_default_memory { { inst_data "ANY" } } {
    set max_mem_region_span 0
    set max_mem_region_name ""

    set max_non_volatile_region_span 0
    set max_non_volatile_region_name ""

    # Gets a list of the currently defined memory regions.
    set current_regions [get_current_memory_regions]

    foreach { region_info } $current_regions {
        set region_name [lindex $region_info 0]
        set slave_desc [lindex $region_info 1]
        set offset [lindex $region_info 2]
        set span [lindex $region_info 3]

        set consider_memory 1

        if { $inst_data == "INST" } {
            set consider_memory [is_connected_to_instruction_master $slave_desc]
        }
        if { $inst_data == "DATA" } {
            set consider_memory [is_connected_to_data_master $slave_desc]
        }

        if { $consider_memory } {
            if { [is_non_volatile_storage $slave_desc] } {
                if {$span > $max_non_volatile_region_span} {
                    set max_non_volatile_region_span $span
                    set max_non_volatile_region_name $region_name
                }
            } else {
                if {$span > $max_mem_region_span} {
                    set max_mem_region_span $span
                    set max_mem_region_name $region_name
                }
            }
        }
    }

    if {$max_mem_region_span != 0} {
        return $max_mem_region_name
    } else {
        return $max_non_volatile_region_name
    }
}


# Map all sections required by the linker script generator to
# the specified memory regions.
proc add_default_linker_section_mappings {data_region_name} {
    add_section_mapping ".rodata" $data_region_name
    add_section_mapping ".rwdata" $data_region_name
    add_section_mapping ".bss" $data_region_name
    add_section_mapping ".heap" $data_region_name
    add_section_mapping ".stack" $data_region_name

    calculate_thread_stack_size
}

# Returns the slave descriptor associated with the specified section.
proc get_section_slave_desc {sectionName} {
    # Get the memory region this section is mapped to.
    set region_name [get_section_mapping $sectionName]

    if {$region_name == ""} {
        error "get_section_slave_desc: no section mapping for section $sectionName"
    }

    return [get_memory_region_slave_desc $region_name]
}

# Returns the slave descriptor associated with the specified memory region.
proc get_memory_region_slave_desc {region_name} {
    # Get the memory region info.
    set region_info [get_memory_region $region_name]

    if {$region_info == ""} {
        error "get_memory_region_slave_desc: no memory region info for region $region_name"
    }

    # Extract the slave descriptor from the memory region info.
    set region_slave_desc [lindex $region_info 1]

    if {$region_slave_desc == ""} {
        error "get_memory_region_slave_desc: slave descriptor not found in memory region info $region_info"
    }

    return $region_slave_desc;
}
