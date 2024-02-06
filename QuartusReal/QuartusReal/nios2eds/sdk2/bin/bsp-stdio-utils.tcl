#
# This file contains BSP utility procedures related to stdio devices.
#

# Set a default STDIO device.
proc set_stdio_defaults { { default_stdio "CHOOSE_DEFAULT" } } {
    # Don't change stdio settings if requested.
    if { $default_stdio == "DONT_CHANGE" } {
        return
    }

    if { $default_stdio == "CHOOSE_DEFAULT" } {
        # Get default character device.
        set default_stdio [choose_default_stdio]
    }

    # Set stdio settings to use it.
    set_setting hal.STDIN $default_stdio
    set_setting hal.STDOUT $default_stdio
    set_setting hal.STDERR $default_stdio

    if {$default_stdio == "none"} {
        log_default "No STDIO character device"
    } else {
        log_default "STDIO character device is $default_stdio"
    }
}


# Select a device connected to the CPU as the default STDIO device.
# It gives preference to JTAG UARTs.  
# If no JTAG UARTs are found, it uses the last character device.
# If no character devices are found, it returns "none", otherwise
# it returns the slave descriptor of the selected device.
proc choose_default_stdio {} {
    set last_stdio "none"
    set first_jtag_uart "none"

    # Get all slaves attached to the CPU.
    set slave_descs [get_slave_descs]

    foreach slave_desc $slave_descs {
        # Lookup module class name for slave descriptor.
        set module_name [get_module_name $slave_desc]
        set module_class_name [get_module_class_name $module_name]
            
        # If the module_name contains "stdio", we'll choose it immediately.
        if { [regexp .*stdio.* $module_name] } {
            return $slave_desc
        }

        # Assume it is a JTAG UART if the module class name contains
        # the string "jtag_uart".  In that case, return the first one found.
        if { [regexp .*jtag_uart.* $module_class_name] } {
            if {$first_jtag_uart == "none"} {
                set first_jtag_uart $slave_desc
            }
        }
        
        # Track last character device in case no JTAG UARTs found.
        if { [is_char_device $slave_desc] } {
            set last_stdio $slave_desc
        }        
    }

    if {$first_jtag_uart != "none"} {
        return $first_jtag_uart
    }
    
    return $last_stdio 
}
