#
# This file contains BSP utility procedures related to the bootloader.
# It relies on procedures provided in bsp-linker-utils.tcl.
#

# Set default bootloader settings
proc set_bootloader_defaults { { use_bootloader "CHOOSE_DEFAULT" } } {
    # Don't change bootloader settings if requested.
    if { $use_bootloader == "DONT_CHANGE" } {
        return
    }

    if { $use_bootloader == "CHOOSE_DEFAULT" } {
        # Determine whether a bootloader is required or not
        # and set the associated setting.
        set use_bootloader [choose_default_use_bootloader]
    }

    if {$use_bootloader} { 
        log_default "Bootloader located at the reset address."
        log_default "Application ELF not allowed to contain code at the reset address."
    } else {
        log_default "No bootloader located at the reset address."
        log_default "Application ELF allowed to contain code at the reset address."
    }

    # If an external bootloader isn't used than can put code a reset address.
    set_setting hal.linker.allow_code_at_reset [expr !$use_bootloader]

    # Now set the default alt_load() settings.
    # Assume that alt_load() is enabled if there is no bootloader.
    set_default_alt_load_settings [expr !$use_bootloader]
}

# Use bootloader when .text and reset don't use the same memory resource
# and reset is located in a flash device.
# Returns a boolean.
proc choose_default_use_bootloader {} {
    set textSlaveDesc [get_section_slave_desc ".text"]
    set resetSlaveDesc [get_reset_slave_desc]
    set sameResource [are_same_resource $textSlaveDesc $resetSlaveDesc]
    set flash [is_flash $resetSlaveDesc]

    return [expr !$sameResource && $flash]
}

# Set defaults associated with the alt_load() routine.
proc set_default_alt_load_settings {enable_alt_load} {
    set_setting hal.linker.enable_alt_load $enable_alt_load

    if { $enable_alt_load } {
        log_default "The alt_load() facility is enabled."
    } else {
        log_default "The alt_load() facility is disabled."
    }

    # Determine if alt_load() needs to copy some exceptions before main().
    set copy_rodata [choose_default_alt_load_copy_rodata $enable_alt_load]
    set copy_rwdata [choose_default_alt_load_copy_rwdata $enable_alt_load]
    set copy_exceptions [choose_default_alt_load_copy_exceptions $enable_alt_load]
    set_setting hal.linker.enable_alt_load_copy_rodata $copy_rodata
    set_setting hal.linker.enable_alt_load_copy_rwdata $copy_rwdata
    set_setting hal.linker.enable_alt_load_copy_exceptions $copy_exceptions

    if {$copy_rodata} {
        log_default "The .rodata section is copied into RAM by alt_load()."
    }
    if {$copy_rwdata} {
        log_default "The .rwdata section is copied into RAM by alt_load()."
    }
    if {$copy_exceptions} {
        log_default "The .exceptions section is copied into RAM by alt_load()."
    }
}

# .rodata section
proc choose_default_alt_load_copy_rodata {enable_alt_load} {
    set textSlaveDesc [get_section_slave_desc ".text"]
    set rodataSlaveDesc [get_section_slave_desc ".rodata"]
    set sameResource [are_same_resource $textSlaveDesc $rodataSlaveDesc]
    set nonVolatile [is_non_volatile_storage $rodataSlaveDesc]

    return [expr $enable_alt_load && !$sameResource && !$nonVolatile]
}

# .rwdata section
proc choose_default_alt_load_copy_rwdata {enable_alt_load} {
    return [expr $enable_alt_load]
}

# .exceptions section
proc choose_default_alt_load_copy_exceptions {enable_alt_load} {
    set textSlaveDesc [get_section_slave_desc ".text"]
    set exceptionSlaveDesc [get_exception_slave_desc]
    set sameResource [are_same_resource $textSlaveDesc $exceptionSlaveDesc]
    set nonVolatile [is_non_volatile_storage $exceptionSlaveDesc]

    return [expr $enable_alt_load && !$sameResource && !$nonVolatile]
}
