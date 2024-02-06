#
# This file contains BSP utility procedures related to timers.
#

# Set a default system timer device.
proc set_timer_defaults { { default_sys_timer "CHOOSE_DEFAULT" } } {
    # Don't change system timer settings if requested.
    if { $default_sys_timer == "DONT_CHANGE" } {
        return
    }

    if { $default_sys_timer == "CHOOSE_DEFAULT" } {
        # Determine default system timer device.
        set default_sys_timer [choose_default_sys_timer]
    }

    # Set system timer setting to use it.
    set_setting hal.sys_clk_timer $default_sys_timer

    if {$default_sys_timer == "none"} {
        log_default "No system timer device"
    } else {
        log_default "System timer device is $default_sys_timer"
    }
}

# Select a device connected to the CPU as the default system timer device.
# Default action is return any timer whose name matches .*sys_clk.*;
# If none are present, then return the first timer found.
# If no timers found, returns "none".
proc choose_default_sys_timer {} {
    # Get all slaves attached to the CPU.
    set slave_descs [get_slave_descs]
    set first_timer "none"

    foreach slave_desc $slave_descs {
        # Assume it is a timer if the slave descriptor is tagged
        # with the "timer" configuration assignment.
        if { [is_timer_device $slave_desc] } {
            # Lookup module class name for slave descriptor.
            set module_name [get_module_name $slave_desc]

            # If module instance name has "sys_clk" in it, choose it
            # immediately.
            if { [regexp .*sys_clk.* $module_name] } {
                return $slave_desc
            }

            if {$first_timer == "none"} {
                set first_timer $slave_desc
            }
        }
    }

    return $first_timer 
}
