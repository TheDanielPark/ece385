#
# This file contains BSP utility procedures related to instruction exception.
#

# Set a default hal.enable_instruction_related_exceptions_api.
proc set_exception_defaults { { default_exception "CHOOSE_DEFAULT" } } {
    # Don't change exception settings if requested.
    if { $default_exception == "DONT_CHANGE" } {
        return
    }

    if { $default_exception == "CHOOSE_DEFAULT" } {
        # Determine default exception.
        set default_exception [choose_default_exception]
    }

    # Set exception setting
    set_setting hal.enable_instruction_related_exceptions_api $default_exception
}

# Return default exception to "true" if MMU, MPU or one of the other advanced 
# exceptions settings is enabled, else otherwise.
proc choose_default_exception {} {
    set cpu_name [get_cpu_name]
    
    set mmu_present [ get_assignment $cpu_name "embeddedsw.CMacro.MMU_PRESENT" ]
    set mpu_present [ get_assignment $cpu_name "embeddedsw.CMacro.MPU_PRESENT" ]
    
    # Empty string if MMU/MPU is enabled.
    if { $mmu_present == "" || $mmu_present == "true" ||
         $mpu_present == "" || $mpu_present == "true" } {
             return "true"
    } else {
        # MMU and MPU are disabled, check for advanced exception settings.
        set inst_exception [ get_assignment $cpu_name "embeddedsw.CMacro.HAS_ILLEGAL_INSTRUCTION_EXCEPTION" ]
        set memory_exception [ get_assignment $cpu_name "embeddedsw.CMacro.HAS_ILLEGAL_MEMORY_ACCESS_EXCEPTION" ]
        set slave_exception [ get_assignment $cpu_name "embeddedsw.CMacro.HAS_SLAVE_ACCESS_ERROR_EXCEPTION" ]
        set division_exception [ get_assignment $cpu_name "embeddedsw.CMacro.HAS_DIVISION_ERROR_EXCEPTION" ]
        set imprecise_mem_exception [ get_assignment $cpu_name "embeddedsw.CMacro.HAS_IMPRECISE_ILLEGAL_MEMORY_ACCESS_EXCEPTION" ]
        set extra_exception [ get_assignment $cpu_name "embeddedsw.CMacro.HAS_EXTRA_EXCEPTION_INFO" ]
        
        if { $inst_exception == "" || $inst_exception == "true" || 
             $memory_exception == "" || $memory_exception == "true" ||
             $slave_exception == "" || $slave_exception == "true" ||
             $division_exception == "" || $division_exception == "true" ||
             $imprecise_mem_exception == "" || $imprecise_mem_exception == "true" ||
             $extra_exception == "" || $extra_exception == "true" } {             
             return "true"
        }
    }

    return "false"
}
