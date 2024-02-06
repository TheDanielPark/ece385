package require -exact qsys 15.1
#-------------------------------------------------------------------------------
# [1] CORE MODULE ATTRIBUTES
#-------------------------------------------------------------------------------
set_module_property NAME "altera_nios2_gen2"
set_module_property DISPLAY_NAME "Nios II Processor"
set_module_property DESCRIPTION "Altera Nios II Processor"
set_module_property AUTHOR "Altera Corporation"
set_module_property DATASHEET_URL "https://documentation.altera.com/#/link/iga1420498949526/iga1409257893438"
set_module_property GROUP "Embedded Processors"

set_module_property VERSION "18.1"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property INTERNAL false
set_module_property HIDE_FROM_SOPC true
set_module_property HIDE_FROM_QUARTUS true

set_module_property EDITABLE true
set_module_property COMPOSITION_CALLBACK compose
set_module_property VALIDATION_CALLBACK validate

# The legacy core now can be upgraded to gen2
set_module_property UPGRADEABLE_FROM { altera_nios2_qsys 9.0 all altera_nios2_qsys 9.1 all altera_nios2_qsys 10.0 all altera_nios2_qsys 10.1 all altera_nios2_qsys 11.0 all altera_nios2_qsys 11.1 all altera_nios2_qsys 12.0 all altera_nios2_qsys 12.1 all altera_nios2_qsys 13.0 all altera_nios2_qsys 13.1 all altera_nios2_qsys 14.0 all altera_nios2_qsys 14.1 all altera_nios2_qsys 15.0 all altera_nios2_qsys 15.1 all altera_nios2_qsys 16.0 all altera_nios2_qsys 16.1 all}

set_module_property PARAMETER_UPGRADE_CALLBACK upgrade

proc upgrade { kind, version, parameters } {
	set parameter_length [ llength $parameters ]

	# find out which core to be updated 
	for {set i 0} {$i < $parameter_length} {set i [ expr $i + 2 ]} {
	    set param_name [ lindex $parameters $i ]
	    set param_value [ lindex $parameters [ expr $i + 1 ] ]
	    if { [ string match $param_name "impl" ] } {
	        set impl $param_value
	        # once done break
	        break;
	    }
	}
	
	set_interface_upgrade_map { irq hbreak_req d_irq irq jtag_debug_module debug_mem_slave }

	foreach new_parameter [ get_parameters ] {
		set my_param($new_parameter) 1
	}
	
	for {set i 0} {$i < $parameter_length} {set i [ expr $i + 2 ]} {
	    set param_name [ lindex $parameters $i ]
	    set param_value [ lindex $parameters [ expr $i + 1 ] ]
	    
	    if { [ info exists my_param($param_name) ] } {
	    	if { [ string match $param_name "impl" ] } {
	    	    if { [ string match $impl "Small" ] } {
	    	        set_parameter_value impl "Fast"
	    	    } else {
	    	        set_parameter_value impl $param_value
	    	    }
	    	} elseif { [ string match $param_name "setting_branchPredictionType" ] } {
	    	    if { [ string match $param_value "Automatic" ] } {
	    	        if { [ string match $impl "Small" ] } {
	    	            set_parameter_value setting_branchpredictiontype "Static"
	    	        } else {
	    	            set_parameter_value setting_branchpredictiontype "Dynamic"
	    	        }
	    	    } else {
	    	        set_parameter_value setting_branchpredictiontype $param_value
	    	    }
	    	} elseif { [ string match $param_name "dcache_size" ] } {
	    	    if { [ string match $impl "Small" ] } {
	    	        set_parameter_value dcache_size "None"
	    	    } else {
	    	        set_parameter_value dcache_size $param_value
	    	    }
	    	} elseif { [ string match $param_name "mmu_enabled" ] } {
	    	    if { [ string match $impl "Small" ] } {
	    	        set_parameter_value mmu_enabled false
	    	    } else {
	    	        set_parameter_value mmu_enabled $param_value
	    	    }
	    	} elseif { [ string match $param_name "mpu_enabled" ] } {
	    	    if { [ string match $impl "Small" ] } {
	    	        set_parameter_value mpu_enabled false
	    	    } else {
	    	        set_parameter_value mpu_enabled $param_value
	    	    }
	    	} elseif { [ string match $param_name "setting_interruptControllerType" ] } {
	    	    if { [ string match $impl "Small" ] } {
	    	        set_parameter_value setting_interruptControllerType "Internal"
	    	    } else {
	    	        set_parameter_value setting_interruptControllerType $param_value
	    	    }
	    	} elseif { [ string match $param_name "setting_shadowRegisterSets" ] } {
	    	    if { [ string match $impl "Small" ] } {
	    	        set_parameter_value setting_shadowRegisterSets 0
	    	    } else {
	    	        set_parameter_value setting_shadowRegisterSets $param_value
	    	    }
	    	} elseif { [ string match $param_name "dcache_numTCDM" ] } {
	    	    if { [ string match $impl "Small" ] } {
	    	        set_parameter_value dcache_numTCDM 0
	    	    } else {
	    	        set_parameter_value dcache_numTCDM $param_value
	    	    }
	    	} elseif { [ string match $param_name "muldiv_divider" ] } {
	    	    if { $param_value } {
	    	        set_parameter_value dividerType "srt2"
	    	    } else {
	    	        set_parameter_value dividerType "no_div"
	    	    }
        	} elseif { [ string match $param_name "muldiv_multiplierType" ] } {
        	    # DSP and EmbeddedMul are like Auto in gen 1
        	    if { [ string match $param_value "DSPBlock" ] } {
	    	        set_parameter_value mul_shift_choice 0
	    	        set_parameter_value mul_32_impl 3
	    	        set_parameter_value mul_64_impl 0
	    	        set_parameter_value shift_rot_impl 0
	    	    } elseif { [ string match $param_value "EmbeddedMulFast" ] } {
	    	        set_parameter_value mul_shift_choice 0
	    	        set_parameter_value mul_32_impl 2
	    	        set_parameter_value mul_64_impl 0
	    	        set_parameter_value shift_rot_impl 1
	    	    } else {
	    	        set_parameter_value mul_shift_choice 1
	    	        set_parameter_value mul_32_impl 0
	    	        set_parameter_value mul_64_impl 0
	    	        set_parameter_value shift_rot_impl 0
	    	    }
	    	} elseif { [ string match $param_name "debug_level" ] } {
	    	    if { [ string match $param_value "NoDebug" ] } {
	    	        set_parameter_value debug_enabled false
	    	        set_parameter_value debug_hwbreakpoint 0
	    	        set_parameter_value debug_datatrigger 0
	    	        set_parameter_value debug_traceType "none"
	    	        set_parameter_value debug_traceStorage "onchip_trace"
	    	    } elseif { [ string match $param_value "Level1" ] } {
	    	        set_parameter_value debug_enabled true
	    	        set_parameter_value debug_hwbreakpoint 0
	    	        set_parameter_value debug_datatrigger 0
	    	        set_parameter_value debug_traceType "none"
	    	        set_parameter_value debug_traceStorage "onchip_trace"
	    	    } elseif { [ string match $param_value "Level2" ] } {
	    	        set_parameter_value debug_enabled true
	    	        set_parameter_value debug_hwbreakpoint 2
	    	        set_parameter_value debug_datatrigger 2
	    	        set_parameter_value debug_traceType "none"
	    	        set_parameter_value debug_traceStorage "onchip_trace"
	    	    } elseif { [ string match $param_value "Level3" ] } {
	    	        set_parameter_value debug_enabled true
	    	        set_parameter_value debug_hwbreakpoint 2
	    	        set_parameter_value debug_datatrigger 2
	    	        set_parameter_value debug_traceType "instruction_trace"
	    	        set_parameter_value debug_traceStorage "onchip_trace"
	    	    } elseif { [ string match $param_value "Level4" ] } {
	    	        set_parameter_value debug_enabled true
	    	        set_parameter_value debug_enabled true
	    	        set_parameter_value debug_hwbreakpoint 4
	    	        set_parameter_value debug_datatrigger 4
	    	        set_parameter_value debug_traceType "instruction_and_data_trace"
	    	        set_parameter_value debug_traceStorage "on_offchip_trace"
	    	    }
	    	} elseif { [ string match $param_name "mpu_minInstRegionSize" ] } {
	    	    if { $param_value < 8 } {
	    	        set_parameter_value mpu_minInstRegionSize 8 
	    	    } else {
	    	        set_parameter_value mpu_minInstRegionSize $param_value
	    	    }
	    	} elseif { [ string match $param_name "mpu_minDataRegionSize" ] } {
	    	    if { $param_value < 8 } {
	    	        set_parameter_value mpu_minDataRegionSize 8 
	    	    } else {
	    	        set_parameter_value mpu_minDataRegionSize $param_value
	    	    }
	    	} else {
	    		set_parameter_value $param_name $param_value
	    	}
	    }
	}
	
}

#-------------------------------------------------------------------------------
# [2] GLOBAL VARIABLES
#-------------------------------------------------------------------------------
set CLOCK_INTF      "clk"
set I_MASTER_INTF   "instruction_master"
set FA_MASTER_INTF  "flash_instruction_master"
set D_MASTER_INTF   "data_master"
set CI_MASTER_INTF  "custom_instruction_master"
set IRQ_INTF        "irq"
set HBREAK_IRQ_INTF "hbreak_req"
set DEBUG_INTF      "debug_mem_slave"
set EXT_IRQ_INTF    "interrupt_controller_in"
set TCD_INTF_PREFIX "tightly_coupled_data_master_"
set TCD_PREFIX      "tightlyCoupledDataMaster"
set TCI_INTF_PREFIX "tightly_coupled_instruction_master_"
set TCI_PREFIX      "tightlyCoupledInstructionMaster"
set IHP_INTF_PREFIX "instruction_master_high_performance"
set IHP_PREFIX      "instructionMasterHighPerformance"
set DHP_INTF_PREFIX "data_master_high_performance"
set DHP_PREFIX      "dataMasterHighPerformance"
set AV_DEBUG_PORT   "avalon_debug_port"
set DEBUG_HOST_INTF "debug_host_slave"
set CPU_RESET       "cpu_resetrequest"
set PROGRAM_COUNTER "program_counter"
set HW_BREAKTEST    "hardware_break_test"
set ECC_EVENT       "ecc_event"

set MEDIUM_LE_SHIFT "Resource-optimized"
set FAST_LE_SHIFT   "High-performance"

set MUL_NONE        "None"
set MUL_SLOW32      "Resource-optimized 32-bit"
set MUL_FAST32      "High-performance 32-bit"
set MUL_FAST64      "High-performance 64-bit"

set DIV_NONE        "None"
set DIV_SRT2        "SRT Radix-2"

#-------------------------------------------------------------------------------
# [3] SUPPORT ROUTINES
#-------------------------------------------------------------------------------
proc add_text_message {GROUP MSG} {
    
    global seperator_id
    set seperator_id [ expr { $seperator_id + 1 } ]
    set ID "text_${seperator_id}"
    
    add_display_item $GROUP $ID text $MSG
}

set seperator_id 0

proc add_line_separator {GROUP} {
    add_text_message $GROUP      ""
}

proc proc_mul_support_32_bit_multiplication {} {
    # Device family dependent
    # Does not rely on the DSP support
    set device_family [ get_parameter_value deviceFamilyName ]
    set supported_32_bit_mul_family [list]
    # in the future append to this list for supported family
    # all STRATIX device (II-V) except for STRATIX10
    lappend supported_32_bit_mul_family "STRATIX*II"
    lappend supported_32_bit_mul_family "STRATIX*III"
    lappend supported_32_bit_mul_family "STRATIX*IV"
    lappend supported_32_bit_mul_family "STRATIX*V"

    # ARRIA V GZ
    lappend supported_32_bit_mul_family "ARRIA*V*GZ*"
    
    foreach supported_family $supported_32_bit_mul_family {
        if { [ string match -nocase $supported_family "$device_family" ] } {
        return 1   
        }
    }

    return 0
}

proc proc_get_hardware_multiply_present {} {
    set mul_set "[ get_parameter_value multiplierType ]"
    set impl [ get_parameter_value impl ]

    # Non Fast Core do not have hardware multiply = no multiplier
    # RULES: no_mul means no multiplier
    if { [ expr { "$impl" != "Fast" } || { "$mul_set" == "no_mul" } ] } {
        return 0
    } else {
        return 1
    }
}

proc proc_get_hardware_divide_present {} {
    set div_set "[ get_parameter_value dividerType ]"
    set impl [ get_parameter_value impl ]
    if { [ expr { "$impl" != "Fast" } || { "$div_set" == "no_div" } ] } {
        return 0
    } else {
        return 1
    }
}

proc proc_get_bmx_present {} {
    set impl [ get_parameter_value impl ]
    set cpuArchRev [ get_parameter_value cpuArchRev ]
    set shiftype [ get_parameter_value shifterType ]

    # bmx is present when it is fast core and shifter type is fast
    # or it is Small. Both must be Cpu Rev 2
    if { "$impl" == "Small" && $cpuArchRev == 2 } {
        return 1
    }

    # RULES: fast_le_shift means BMX support
    if { [ expr { "$impl" == "Fast" && $cpuArchRev == 2 } ] } {
        if { "$shiftype" == "fast_le_shift" } {
            return 1
        }
    }

    return 0
}

proc proc_get_cdx_present {} {
    set impl [ get_parameter_value impl ]
    set cpuArchRev [ get_parameter_value cpuArchRev ]
    set cdx_present [ proc_get_boolean_parameter cdx_enabled ]

    if { "$impl" == "Small" && $cdx_present && $cpuArchRev == 2 } {
        return 1
    }

    return 0
}

proc proc_get_mpx_present {} {
    set impl [ get_parameter_value impl ]
    set cpuArchRev [ get_parameter_value cpuArchRev ]
    set mpx_enabled [ proc_get_boolean_parameter mpx_enabled ]

    if { "$impl" != "Tiny" && $mpx_enabled && $cpuArchRev == 2 } {
        return 1
    }

    return 0
}

proc proc_get_mpu_present {} {
    set mpu_enable [proc_get_boolean_parameter mpu_enabled]
    set mmu_enable [proc_get_boolean_parameter mmu_enabled]
    set impl [ get_parameter_value impl ]
    set mpu_present [ expr { "$impl" != "Tiny" } && { ! $mmu_enable }  && { $mpu_enable } ]
    return [proc_bool2int $mpu_present]
}

proc proc_get_mmu_present {} {
    set mpu_enable [proc_get_boolean_parameter mpu_enabled]
    set mmu_enable [proc_get_boolean_parameter mmu_enabled]
    set impl [ get_parameter_value impl ]
    set mmu_present [ expr { "$impl" == "Fast" } && { $mmu_enable }  && { ! $mpu_enable } ]
    return [proc_bool2int $mmu_present]
}

proc proc_get_eic_present {} {
    set local_interrupt_type [ get_parameter_value setting_interruptControllerType ]
    set impl [ get_parameter_value impl ]
    if { "${local_interrupt_type}" == "External" && "$impl" != "Tiny" } {
        return 1
    } else {
        return 0
    }
}

proc proc_get_oci_trace_addr_width {} {
    set debug_OCIOnchipTrace [get_parameter_value debug_OCIOnchipTrace]
    switch $debug_OCIOnchipTrace {
        "_128" {
            return    7
        }
        "_256" {
            return    8
        }
        "_512" {
            return    9
        }
        "_1k" {
            return    10
        }
        "_2k" {
            return    11
        }
        "_4k" {
            return    12
        }
        "_8k" {
            return    13
        }
        "_16k" {
            return    14
        }
    }
}

proc proc_not_tiny_core_info {} {
    set impl [ get_parameter_value impl ]
    set not_tiny [ expr { "$impl" != "Tiny" } ]
    return $not_tiny
}

proc proc_get_europa_illegal_mem_exc {} {
    set impl [ get_parameter_value impl ]
    set mpu_enable [proc_get_mpu_present]
    set mmu_enable [proc_get_mmu_present]
    set illegal_mem_exc [proc_get_boolean_parameter setting_preciseIllegalMemAccessException]
    set europa_illegal_mem_exc [ expr { "$impl" != "Tiny" } && { $illegal_mem_exc || $mpu_enable || $mmu_enable } ]
    return $europa_illegal_mem_exc
}

proc proc_bool2int {bool} {
    if { $bool } {
       return 1
    } else {
       return 0
    }
}
proc proc_get_boolean_parameter {PARAM} {
    set bool_value [get_parameter_value $PARAM]
    return [proc_bool2int $bool_value]
}
proc proc_num2sz {NUMBER} {
    if { $NUMBER == 0 } {
        return 1
    }

    if { $NUMBER == 1 } {
        return 1
    }

    return [expr int(ceil(log($NUMBER)/log(2)))]
}

proc proc_span2width { n } {
    return [expr int(ceil(log($n)/log(2)))]    
}

proc proc_num2hex {NUMBER} {
    return [ format "0x%08x" $NUMBER ]
}

proc proc_num2unsigned {NUMBER} {
    return [ format "%u" $NUMBER ]
}

proc proc_set_display_format {NAME DISPLAY_HINT} {
    set_parameter_property  $NAME   "DISPLAY_HINT"      $DISPLAY_HINT
}

# TODO: description as arg
# TODO: do we need "affects_elaboration" often?
# TODO: add description
proc proc_add_parameter {NAME TYPE DEFAULT args} {
    set DESCRIPTION         "set \[$NAME\] value"
    add_parameter           $NAME $TYPE $DEFAULT $DESCRIPTION
    if {$args != ""} then {
        set_parameter_property  $NAME "ALLOWED_RANGES" $args
    }
    set_parameter_property  $NAME "VISIBLE" false
}

proc proc_add_derived_parameter {NAME TYPE DEFAULT args} {
    proc_add_parameter      $NAME $TYPE    $DEFAULT
    set_parameter_property  $NAME "DERIVED" true
    set_parameter_property  $NAME "VISIBLE" true
}

proc proc_add_system_info_parameter {NAME TYPE DEFAULT SYSTEM_INFO_ARG} {
    proc_add_parameter      $NAME   $TYPE           $DEFAULT
    set_parameter_property  $NAME   system_info     "$SYSTEM_INFO_ARG"
}

# TODO: appropriate use of quotation marks?
# TODO: proper use of status=experimentatl for debug mode?
proc proc_set_display_group {NAME GROUP EXPERIMENTAL DISPLAY_NAME args} {
    add_display_item        $GROUP  $NAME               parameter
    set_parameter_property  $NAME   "DISPLAY_NAME"      "$DISPLAY_NAME"
    set display_message     "$args"
    # only show those settings in debug mode
    if { "$EXPERIMENTAL" == "1" } {
        set_parameter_property  $NAME   "STATUS"       "EXPERIMENTAL"
        set_parameter_property  $NAME   "VISIBLE"           false
    } else {
        set_parameter_property  $NAME   "VISIBLE"           true
    }
    
    if { [ expr { "DES_$args" != "DES_" } ] } {
        set_parameter_property  $NAME   "DESCRIPTION"       "[ join $display_message ]"
    }
}

proc proc_set_enable_visible_parameter {NAME ENABLED} {
    if { [ get_parameter_property $NAME "VISIBLE" ] } {
        if { "$ENABLED" == "enable" } {
            set_parameter_property $NAME "ENABLED" 1
        } else {
            set_parameter_property $NAME "ENABLED" 0
        }
    }
}

# Add a particular parameter to the 'group' that will
# affect the resulting output Perl hash
proc proc_set_info_hash_group {INFO_GROUP args} {
    global processor_infos
    foreach arg $args {
        lappend processor_infos($INFO_GROUP) $arg
    }
}

proc proc_set_interface_embeddedsw_cmacro_assignment {interface name value} {
    set name_upper_case "[ string toupper $name ]"
    set embeddedsw_name "embeddedsw.CMacro.${name_upper_case}"
    set_interface_assignment $interface $embeddedsw_name "$value"
}

proc proc_set_interface_embeddedsw_configuration_assignment {interface name value} {
    set embeddedsw_name "embeddedsw.configuration.${name}"
    set_interface_assignment $interface $embeddedsw_name "$value"
}

proc proc_set_module_embeddedsw_cmacro_assignment {name value} {
    set name_upper_case "[ string toupper $name ]"
    set embeddedsw_name "embeddedsw.CMacro.${name_upper_case}"
    set_module_assignment $embeddedsw_name "$value"
}

proc proc_set_module_embeddedsw_configuration_assignment {name value} {
    set embeddedsw_name "embeddedsw.configuration.${name}"
    set_module_assignment $embeddedsw_name "$value"
}

proc proc_validate_address_alignment {memory_address alignment_mask error_msg} {
    set next_valid_increment [ expr $alignment_mask + 0x1 ]
    set valid_address_mask [ expr $alignment_mask ^ 0xffffffff ]
    set previous_valid_address [ proc_num2hex [ expr $memory_address & $valid_address_mask ]]
    set next_valid_address [ proc_num2hex [ expr $previous_valid_address + $next_valid_increment ]]

    if { [ expr $memory_address & $alignment_mask ] != 0x0 } {
        send_message error "$error_msg. ($previous_valid_address or $next_valid_address are acceptable)"
    }
}
                                     
proc proc_validate_device_features {device_feature} {
    set device_features         [ get_parameter_value deviceFeaturesSystemInfo ]

    switch $device_feature {
        "dsp_mul" {
            return [ is_device_feature_exist "DSP" ]
        }
        "DSPBlock" {
            return [ is_device_feature_exist "DSP" ]
        }
        "embedded_mul" {
            return [ is_device_feature_exist "EMUL" ]
        }
        "EmbeddedMulFast" {
            return [ is_device_feature_exist "EMUL" ]
        }
        "M4K" {
            return [ is_device_feature_exist "M4K_MEMORY" ]
        }
        "M-RAM" {
            return [ is_device_feature_exist "MRAM_MEMORY" ]
        }
        "MLAB" {
            return [ is_device_feature_exist "MLAB_MEMORY" ]
        }
        "M9K" {
            return [ is_device_feature_exist "M9K_MEMORY" ]
        }
        "M10K" {
            return [ is_device_feature_exist "M10K_MEMORY" ]
        }
        "M20K" {
            return [ is_device_feature_exist "M20K_MEMORY" ]
        }
        "M144K" {
            return [ is_device_feature_exist "M144K_MEMORY" ]
        }
        "M512" {
            return [ is_device_feature_exist "M512_MEMORY" ]
        }
    }

    return 0
}

# DEVICE_FEATURES
#~~~~~~~~~~~~~~~~
#   MLAB_MEMORY
#   M4K_MEMORY
#   M144K_MEMORY
#   M512_MEMORY
#   MRAM_MEMORY
#   M9K_MEMORY
#   ADDRESS_STALL
#   DSP
#   EMUL
#   DSP_SHIFTER_BLOCK
#   ESB
#   EPCS
#   LVDS_IO
#   HARDCOPY
#   TRANSCEIVER_6G_BLOCK
#   TRANSCEIVER_3G_BLOCK
proc is_device_feature_exist {feature_name} {
    array set feature_array  [get_parameter_value deviceFeaturesSystemInfo]
    foreach one_feature [array names feature_array] {
        if { [ expr { "$one_feature" == "$feature_name" } ] } {
            return $feature_array($one_feature)
        }
    }
    return 0
}

proc proc_get_supported_ram_type {ram} {
    set supported_ram_type_system_info [list]
    set is_tagram_cache [expr { $ram == "cache_tag_ram" }]
    array set feature_array  [get_parameter_value deviceFeaturesSystemInfo]
    foreach one_feature [array names feature_array] {
        if { [ string match "*_MEMORY*" "$one_feature" ] } {
            if { [expr { $is_tagram_cache } && { "$one_feature" == "MLAB_MEMORY" } ] } {
                # MLAB type is not supported for CACHE TAG RAMs so skipping this
            } else {
                if { $feature_array($one_feature) } {
                    lappend supported_ram_type_system_info "$one_feature"
                }
            }
        }
    }
    set supported_ram_type [list]
    foreach ram_type $supported_ram_type_system_info {
        switch $ram_type {
            "M4K_MEMORY" {
                lappend supported_ram_type "M4K"
            }
            "M9K_MEMORY" {
                lappend supported_ram_type "M9K"
            }
            "M10K_MEMORY" {
                lappend supported_ram_type "M10K"
            }
            "M20K_MEMORY" {
                lappend supported_ram_type "M20K"
            }
            "M144K_MEMORY" {
                lappend supported_ram_type "M144K"
            }
            "MRAM_MEMORY" {
                # Basically do nothing for MRAMs
                #lappend supported_ram_type "MRam"
            }
            "MLAB_MEMORY" {
                lappend supported_ram_type "MLAB"
            }
            "M512_MEMORY" {
                lappend supported_ram_type "M512"
            }
            default {
                # Should never enter this function
                send_message error "$ram_type is not a valid ram type"
            }

        }
    }
    # Don't forget the AUTO
    lappend supported_ram_type "Automatic"
    return "$supported_ram_type"
}

proc proc_get_lowest_start_address {slave_map_param} {
    set slave_address [ lsort -ascii [ proc_get_address_map_slaves_start_address $slave_map_param ]]
    if { [ expr { "ADDR_$slave_address" == "ADDR_" } ] } {
        return [ proc_num2unsigned -1 ]
    } else {
        return [ proc_num2unsigned [ lindex $slave_address 0 ]]
    }
}

proc proc_get_higest_end_address {slave_map_param} {
    set slave_address_top [ lindex [ lsort -ascii [ proc_get_address_map_slaves_end_address $slave_map_param ]] end ]
    set slave_address_base [ lindex [ lsort -ascii [ proc_get_address_map_slaves_start_address $slave_map_param ]] 0 ]
        
    if { $slave_address_top == "" } {
        return [ proc_num2unsigned -1 ]
    }

    set anded [ proc_num2hex [ expr $slave_address_top & $slave_address_base ] ]
    set subed [ proc_num2hex [ expr $slave_address_top - $anded ] ]
    for {set i 0} {pow(2,$i) < $subed} {incr i} {}
    set powerof2 [ expr int((pow(2,$i) - 1 )) ]
    set address_top [ proc_num2hex [ expr $powerof2 | $anded ] ]
    
    if { [ expr { "ADDR_$address_top" == "ADDR_" } ] } {
        return [ proc_num2unsigned -1 ]
    } else {
        return [ proc_num2unsigned $address_top ]
    }

}

proc proc_decode_address_map {slave_map_param} {
    set address_map_xml [ get_parameter_value $slave_map_param ]
    return [ decode_address_map $address_map_xml ]
}

proc proc_get_address_map_slaves_name {slave_map_param} {
    set slaves_name [list]
    set address_map_dec [ proc_decode_address_map $slave_map_param]

    foreach slave_info $address_map_dec {
        array set slave_info_array $slave_info
        lappend slaves_name "$slave_info_array(name)"
    }

    foreach dup_check $slaves_name {
        set tmp($dup_check) 1
    }
    set slaves_name [ array names tmp ]

    return $slaves_name
}

proc proc_get_address_map_slaves_start_address {slave_map_param} {
    set slaves_start_address [list]
    set address_map_dec [ proc_decode_address_map $slave_map_param]

    foreach slave_info $address_map_dec {
        array set slave_info_array $slave_info
        lappend slaves_start_address "[ proc_num2hex $slave_info_array(start) ]"
    }
    return $slaves_start_address
}

proc proc_get_address_map_slaves_end_address {slave_map_param} {
    set slaves_end_address [list]
    set address_map_dec [ proc_decode_address_map $slave_map_param]

    foreach slave_info $address_map_dec {
        array set slave_info_array $slave_info
        lappend slaves_end_address "[ proc_num2hex [ expr $slave_info_array(end) - 1 ]]"
    }
    return $slaves_end_address
}

# [TODO]: replace proc_get_address_map_1_slave_start_address == -1
proc proc_is_slave_exist {slave_map_param slave_name} {
    set address_map_dec [ proc_decode_address_map $slave_map_param]
    foreach slave_info $address_map_dec {
        array set slave_info_array $slave_info
        set slave "$slave_info_array(name)"
        if { "$slave" == "$slave_name" } {
            return 1
        }
    }
    return 0
}

proc proc_get_address_map_1_slave_start_address {slave_map_param slave_name} {
    set address_map_dec [ proc_decode_address_map $slave_map_param]
    foreach slave_info $address_map_dec {
        array set slave_info_array $slave_info
        set slave "$slave_info_array(name)"
        if { "$slave" == "$slave_name" } {
            return [ proc_num2hex $slave_info_array(start) ]
        }
    }
    return -1
}

proc proc_get_address_map_1_slave_end_address {slave_map_param slave_name} {
    set address_map_dec [ proc_decode_address_map slave_map_param]
    foreach slave_info $address_map_dec {
        array set slave_info_array $slave_info
        set slave "$slave_info_array(name)"
        if { "$slave" == "$slave_name" } {
            return "[ proc_num2hex [ expr $slave_info_array(end) - 1 ]]"
        }
    }
    return -1
}

proc proc_calc_actual_address {slave_name address_offset} {
    global  TCI_PREFIX
    global  IHP_PREFIX
    
    set tcim_num    [ get_parameter_value icache_numTCIM ]
    
    if { $slave_name == "Absolute" } {
        return [ proc_num2unsigned $address_offset ]
    } else {
        if { [proc_is_slave_exist instSlaveMapParam $slave_name] } {
            set inst_address_base [ proc_get_address_map_1_slave_start_address instSlaveMapParam $slave_name ]
            return [ proc_num2unsigned [ expr $inst_address_base + $address_offset ] ]
        } elseif { [proc_is_slave_exist faSlaveMapParam $slave_name] } {
            set fa_address_base [ proc_get_address_map_1_slave_start_address faSlaveMapParam $slave_name ]
            return [ proc_num2unsigned [ expr $fa_address_base + $address_offset ] ]
        } elseif { [ proc_is_slave_exist ${IHP_PREFIX}MapParam $slave_name ] } {
            set ihp_address_base [ proc_get_address_map_1_slave_start_address ${IHP_PREFIX}MapParam $slave_name ]
            return [ proc_num2unsigned [ expr $ihp_address_base + $address_offset ] ]
        } else {
            foreach i {0 1 2 3} {
                set TCI_NAME  "${TCI_PREFIX}${i}"
                if { $i < $tcim_num } {
                    if { [ proc_is_slave_exist ${TCI_NAME}MapParam $slave_name ] } {
                        set tcim_address_base [ proc_get_address_map_1_slave_start_address ${TCI_NAME}MapParam $slave_name ]
                        return [ proc_num2unsigned [ expr $tcim_address_base + $address_offset ] ]
                    }
                }
            }
        }
        return -1
    }
}


proc proc_get_reset_addr {} {
    return [ proc_calc_actual_address [get_parameter_value resetSlave] [get_parameter_value resetOffset]]
}

proc proc_get_general_exception_addr {} {
    return [ proc_calc_actual_address [get_parameter_value exceptionSlave] [get_parameter_value exceptionOffset]]
}

proc proc_get_fast_tlb_miss_exception_addr {} {
    set mmu_enable [proc_get_mmu_present]
    if { $mmu_enable } {
        return [ proc_calc_actual_address [get_parameter_value mmu_TLBMissExcSlave] [get_parameter_value mmu_TLBMissExcOffset]]
    } else {
        return 0
    }

    return 0
}

proc proc_get_break_addr {} {
    # Use for internal testing
    set debug_enabled                   [ proc_get_boolean_parameter debug_enabled ]
    set break_addr                      [ proc_calc_actual_address [get_parameter_value breakSlave_derived] [get_parameter_value breakOffset]]
    set allow_break_inst                [ proc_get_boolean_parameter setting_allow_break_inst]
    set setting_oci_version             [ get_parameter_value setting_oci_version]
    set cpuArchRev                      [ get_parameter_value cpuArchRev ]
    # Overwrite the break vector when No debug is selected
    if { ($debug_enabled || $allow_break_inst || $cpuArchRev == 1) && $setting_oci_version == 1 } {
        return $break_addr
    }
    return 0
}

proc proc_get_icache_present {} {
    set icache_size                     [ get_parameter_value icache_size ]
    
    return [ expr { "$icache_size" != "0" } ]
}

#TODO: Properly implement this
proc proc_decode_ci_slave { param } {
    regsub -all "/?info>" $param "" param
    regsub -all "\{\""    $param "" param
    regsub -all "\"\}"    $param "" param
    regsub -all " />"     $param "" param
    regsub -all "info/>"  $param "" param
    
    return $param
}

proc proc_has_any_ci_slave { custom_system_info } {

    set has_combo [ proc_has_combo_ci_slave $custom_system_info ]
    set has_multi [ proc_has_multi_ci_slave $custom_system_info ]
    
    set has_any_ci [ expr $has_combo || $has_multi  ]
    
    return $has_any_ci
    
}

proc proc_has_combo_ci_slave { custom_system_info } {

    set ci_ori [ proc_decode_address_map $custom_system_info ]
    set custom_inst_slave [ proc_decode_ci_slave $ci_ori ]
    
    foreach custom_slave $custom_inst_slave {
        array set custom_slave_info $custom_slave
        set custom_slave_type  $custom_slave_info(clockCycleType)
        if { "$custom_slave_type" == "COMBINATORIAL" } {
            return 1
        }
    }
    
    return 0
}

proc proc_has_multi_ci_slave { custom_system_info } {

    set ci_ori [ proc_decode_address_map $custom_system_info ]
    set custom_inst_slave [ proc_decode_ci_slave $ci_ori ]
    
    foreach custom_slave $custom_inst_slave {
        array set custom_slave_info $custom_slave
        set custom_slave_type  $custom_slave_info(clockCycleType)
        if { [ expr { "$custom_slave_type" == "VARIABLE" } || { "$custom_slave_type" == "MULTICYCLE" } ] } {
            return 1
        }
    }
    
    return 0
}

proc proc_validate_offset { slave_name abs_address} {
    set local_data_address_map_dec            [ proc_decode_address_map dataSlaveMapParam ]
    foreach local_data_slave $local_data_address_map_dec {
        array set local_data_slave_info $local_data_slave
        if { "$local_data_slave_info(name)" == "$slave_name" } {
            set SlaveEndAddr [ proc_num2unsigned [ expr { $local_data_slave_info(end) - 1 } ] ]
            if { [ expr { $abs_address > $SlaveEndAddr } ] } {
                return 1
            } else {
                return 0
            }
        }
    }
}

proc proc_width2maxaddr { n } {
      # tcl version 8.0 limitation. Only able to convert float of 2^31 to integer
    if { [ expr { $n == 32 } ] } {
        return [ proc_num2hex 4294967295 ]
    } else {
        set number [ expr int(pow(2,$n) - 1) ]
        return [ proc_num2hex $number ]
    }
}

proc proc_get_cmacro_inst_addr_width {} {
    set ihp [ get_parameter_value instructionMasterHighPerformanceAddrWidth]
    set tcim0 [ get_parameter_value tightlyCoupledInstructionMaster0AddrWidth]
    set tcim1 [ get_parameter_value tightlyCoupledInstructionMaster1AddrWidth]
    set tcim2 [ get_parameter_value tightlyCoupledInstructionMaster2AddrWidth]
    set tcim3 [ get_parameter_value tightlyCoupledInstructionMaster3AddrWidth]
    set im    [ get_parameter_value instAddrWidth ]
    set fa    [ get_parameter_value faAddrWidth ]

    set sorted_inst_addr_width  [ lsort "$im $fa $tcim0 $tcim1 $tcim2 $tcim3 $ihp" ]
    set highest_inst_addr_width [ lindex $sorted_inst_addr_width end ]
    return $highest_inst_addr_width
}

proc proc_get_cmacro_data_addr_width {} {
    set dhp [ get_parameter_value dataMasterHighPerformanceAddrWidth]
    set tcdm0 [ get_parameter_value tightlyCoupledDataMaster0AddrWidth]
    set tcdm1 [ get_parameter_value tightlyCoupledDataMaster1AddrWidth]
    set tcdm2 [ get_parameter_value tightlyCoupledDataMaster2AddrWidth]
    set tcdm3 [ get_parameter_value tightlyCoupledDataMaster3AddrWidth]
    set dm    [ get_parameter_value dataAddrWidth ]

    set sorted_data_addr_width  [ lsort "$dm $tcdm0 $tcdm1 $tcdm2 $tcdm3 $dhp" ]
    set highest_data_addr_width [ lindex $sorted_data_addr_width end ]
    return $highest_data_addr_width
}

proc proc_calculate_ecc_bits { data_sz } {
    for { set ecc_bits 0 } { [ expr { pow(2,$ecc_bits) - $ecc_bits - 1 } < $data_sz]  } { incr ecc_bits } {}
    set ecc_bits [ expr $ecc_bits + 1 ]
    return $ecc_bits
}

proc proc_calculate_tlb_data_size {} {
    set local_finalTlbPtrSz      [ proc_get_final_tlb_ptr_size ]
    set local_mmupid             [ get_parameter_value mmu_processIDNumBits ]
    set local_tlb_num_ways       [ get_parameter_value mmu_tlbNumWays ]
    set local_instaddrwidth      [ get_parameter_value instAddrWidth ]
    set local_dataaddrwidth      [ get_parameter_value dataAddrWidth ]

    set local_tlb_ways_sz        [ proc_num2sz $local_tlb_num_ways ]
    set local_mmu_addr_offset_sz 12
    if { ${local_instaddrwidth} > ${local_dataaddrwidth} } {
        set pfn_size [ expr { ${local_instaddrwidth} - ${local_mmu_addr_offset_sz}} ]
    } else {
        set pfn_size [ expr { ${local_dataaddrwidth} - ${local_mmu_addr_offset_sz}} ]
    }
    set tag_size [ expr {32 - ( ${local_finalTlbPtrSz} - ${local_tlb_ways_sz} ) - ${local_mmu_addr_offset_sz} } ]
    # Cacheable, Readable, Writable, Executable and Global
    set const_size 5
    set tlb_data_size [ expr { ${tag_size} + ${local_mmupid} + ${const_size} + ${pfn_size} } ]
    
    return $tlb_data_size
}

proc proc_calculate_dc_tag_data_size {} {
    set dcache_lineSize_derived  [ get_parameter_value dcache_lineSize_derived ];
    set dcache_size_derived      [ get_parameter_value dcache_size_derived ];
    set local_dataaddrwidth      [ get_parameter_value dataAddrWidth ]

    set dc_bytes_per_line        $dcache_lineSize_derived;
    set dc_cache_wide            [ expr { $dc_bytes_per_line > 4 } ]
    set dc_words_per_line        [ expr { $dc_bytes_per_line>>2 } ];# 8 words/cacheline
    set data_master_addr_sz      $dcache_size_derived
    set dc_num_lines             [ expr { $data_master_addr_sz / $dc_bytes_per_line } ]
    set dc_addr_byte_field_sz    2
    set dc_addr_byte_field_lsb   0
    set dc_addr_byte_field_msb   [ expr { $dc_addr_byte_field_lsb + $dc_addr_byte_field_sz -1 } ]
    set dc_addr_offset_field_sz  [ proc_num2sz $dc_words_per_line ]
    set dc_addr_line_field_sz    [ proc_num2sz $dc_num_lines ]
    if { $dc_cache_wide }  {
        # this line needed the dc_addr_offset_field_sz
        set dc_addr_line_field_lsb [ expr {$dc_addr_byte_field_msb + 2 + $dc_addr_offset_field_sz -1} ]
    } else {
        set dc_addr_line_field_lsb [ expr {$dc_addr_byte_field_msb + 1 } ]
    }
    set dc_addr_line_field_msb   [ expr { $dc_addr_line_field_lsb + $dc_addr_line_field_sz - 1 } ]
    set dc_addr_tag_field_msb    [ expr { $local_dataaddrwidth - 1} ]
    set dc_addr_tag_field_lsb    [ expr { $dc_addr_line_field_msb +1 } ]
    set dc_addr_tag_field_sz     [ expr {$dc_addr_tag_field_msb - $dc_addr_tag_field_lsb + 1 } ]
    set dc_tag_entry_valid_sz    1
    set dc_tag_entry_dirty_sz    1
    #        finals
    set dc_tag_data_sz           [ expr { $dc_addr_tag_field_sz + $dc_tag_entry_valid_sz + $dc_tag_entry_dirty_sz } ]
    
    return $dc_tag_data_sz
}

proc proc_calculate_dc_tag_addr_size {} {
    set dcache_lineSize_derived  [ get_parameter_value dcache_lineSize_derived ];
    set dcache_size_derived      [ get_parameter_value dcache_size ];
    set local_dataaddrwidth      [ get_parameter_value dataAddrWidth ]

    set dc_bytes_per_line        $dcache_lineSize_derived;
    set dc_words_per_line        [ expr { $dc_bytes_per_line>>2 } ];# 8 words/cacheline
    set data_master_addr_sz      $dcache_size_derived
    set dc_num_lines             [ expr { $data_master_addr_sz / $dc_bytes_per_line } ]

    set dc_addr_line_field_sz    [ proc_num2sz $dc_num_lines ]

    set dc_tag_addr_sz           $dc_addr_line_field_sz
    
    return $dc_tag_addr_sz
}

proc proc_calculate_dc_data_addr_size {} {
    set dcache_lineSize_derived  [ get_parameter_value dcache_lineSize_derived ];
    set dcache_size_derived      [ get_parameter_value dcache_size_derived ];
    set local_dataaddrwidth      [ get_parameter_value dataAddrWidth ]

    set dc_bytes_per_line        $dcache_lineSize_derived
    set dc_cache_wide            [ expr { $dc_bytes_per_line > 4 } ]
    set dc_words_per_line        [ expr { $dc_bytes_per_line>>2 } ];# 8 words/cacheline
    set data_master_addr_sz      $dcache_size_derived
    set dc_num_lines             [ expr { $data_master_addr_sz / $dc_bytes_per_line } ]
    set dc_addr_byte_field_sz    2
    set dc_addr_byte_field_lsb   0
    set dc_addr_byte_field_msb   [ expr { $dc_addr_byte_field_lsb + $dc_addr_byte_field_sz -1 } ]
    set dc_addr_offset_field_sz  [ proc_num2sz $dc_words_per_line ]
    set dc_addr_line_field_sz    [ proc_num2sz $dc_num_lines ]
    if { $dc_cache_wide }  {
        # this line needed the dc_addr_offset_field_sz
        set dc_addr_line_field_lsb [ expr {$dc_addr_byte_field_msb + 2 + $dc_addr_offset_field_sz -1} ]
    } else {
        set dc_addr_line_field_lsb [ expr {$dc_addr_byte_field_msb + 1 } ]
    }
    set dc_addr_line_field_msb   [ expr { $dc_addr_line_field_lsb + $dc_addr_line_field_sz - 1 } ]
    set dc_addr_tag_field_msb    [ expr { $local_dataaddrwidth - 1} ]
    set dc_addr_tag_field_lsb    [ expr { $dc_addr_line_field_msb +1 } ]
    set dc_addr_tag_field_sz     [ expr {$dc_addr_tag_field_msb - $dc_addr_tag_field_lsb + 1 } ]
    set dc_addr_line_offset_field_sz  [ expr { $dc_addr_line_field_sz + $dc_addr_offset_field_sz } ]
    if { $dc_cache_wide }  {
        set dc_data_addr_sz      $dc_addr_line_offset_field_sz
    } else {
        set dc_data_addr_sz      $dc_addr_line_field_sz
    }

    return $dc_data_addr_sz
}

proc proc_calculate_ic_tag_data_size {} {
    set local_instaddrwidth      [ get_parameter_value instAddrWidth ]
    set icache_size              [ get_parameter_value icache_size ]
    
    set ic_bytes_per_line        32 ;#32bytes /cacheline
    set ic_words_per_line        [ expr { $ic_bytes_per_line>>2 } ];# 8 words/cacheline
    set ic_total_bytes           $icache_size
    set ic_num_lines             [ expr { $ic_total_bytes / $ic_bytes_per_line } ]
    set ic_offset_field_sz       [ proc_num2sz $ic_words_per_line ]
    set ic_offset_field_lsb      0
    set ic_offset_field_msb      [ expr { $ic_offset_field_lsb + $ic_offset_field_sz -1 } ]
    set ic_line_field_sz         [ proc_num2sz $ic_num_lines ]
    set ic_line_field_lsb        [ expr { $ic_offset_field_msb +1 } ]
    set ic_line_field_msb        [ expr { $ic_line_field_lsb + $ic_line_field_sz -1 } ]
    set ic_tag_field_msb         [ expr { $local_instaddrwidth -3} ]
    set ic_tag_field_lsb         [ expr { $ic_line_field_msb +1 } ]
    set ic_tag_field_sz          [ expr { $ic_tag_field_msb - $ic_tag_field_lsb +1 } ]
    set ic_tag_data_sz           [ expr { $ic_tag_field_sz + $ic_words_per_line } ]
    
    return $ic_tag_data_sz
}

proc proc_calculate_ic_tag_addr_size {} {
    set icache_size              [ get_parameter_value icache_size ]
    
    set ic_bytes_per_line        32 ;#32bytes /cacheline
    set ic_words_per_line        [ expr { $ic_bytes_per_line>>2 } ];# 8 words/cacheline
    set ic_total_bytes           $icache_size
    set ic_num_lines             [ expr { $ic_total_bytes / $ic_bytes_per_line } ]
    set ic_line_field_sz         [ proc_num2sz $ic_num_lines ]

    set ic_tag_addr_sz           $ic_line_field_sz
    
    return $ic_tag_addr_sz
}

proc proc_calculate_ic_data_addr_size {} {
    set icache_size              [ get_parameter_value icache_size ]
    
    set ic_bytes_per_line        32 ;#32bytes /cacheline
    set ic_words_per_line        [ expr { $ic_bytes_per_line>>2 } ];# 8 words/cacheline
    set ic_total_bytes           $icache_size
    set ic_num_lines             [ expr { $ic_total_bytes / $ic_bytes_per_line } ]
    set ic_offset_field_sz       [ proc_num2sz $ic_words_per_line ]
    set ic_line_field_sz         [ proc_num2sz $ic_num_lines ]

    set ic_data_addr_sz          [ expr { $ic_line_field_sz + $ic_offset_field_sz } ]
    
    return $ic_data_addr_sz
}

#-------------------------------------------------------------------------------
# [4] PARAMETERS
#-------------------------------------------------------------------------------
#------------------------------
# [4.1] Actual Parameters
#------------------------------
proc_add_parameter      tmr_enabled                                 BOOLEAN     false
proc_add_parameter      setting_disable_tmr_inj                     BOOLEAN     false
proc_add_parameter      setting_showUnpublishedSettings             BOOLEAN     false
proc_add_parameter      setting_showInternalSettings                BOOLEAN     false
proc_add_parameter      setting_preciseIllegalMemAccessException    BOOLEAN     false
proc_add_parameter      setting_exportPCB                           BOOLEAN     false
proc_add_parameter      setting_exportdebuginfo                     BOOLEAN     false
proc_add_parameter      setting_clearXBitsLDNonBypass               BOOLEAN     true
proc_add_parameter      setting_bigEndian                           BOOLEAN     false
proc_add_parameter      setting_export_large_RAMs                   BOOLEAN     false
proc_add_parameter      setting_asic_enabled                        BOOLEAN     false
proc_add_parameter      register_file_por                           BOOLEAN     false
proc_add_parameter      setting_asic_synopsys_translate_on_off      BOOLEAN     false
proc_add_parameter      setting_asic_third_party_synthesis          BOOLEAN     false
proc_add_parameter      setting_asic_add_scan_mode_input            BOOLEAN     false
proc_add_parameter      setting_oci_version                         INTEGER     1  "1:Version 1" "2:Version 2"
proc_add_parameter      setting_fast_register_read                  BOOLEAN     false
proc_add_parameter      setting_exportHostDebugPort                 BOOLEAN     false
proc_add_parameter      setting_oci_export_jtag_signals             BOOLEAN     false
proc_add_parameter      setting_avalonDebugPortPresent              BOOLEAN     false
proc_add_parameter      setting_alwaysEncrypt                       BOOLEAN     true
proc_add_parameter      io_regionbase                               INTEGER     0
proc_add_parameter      io_regionsize                               INTEGER     0  "0:None"  "4096:4 Kbytes"  "8192:8 Kbytes"   "16384:16 Kbytes"   "32768:32 Kbytes"   "65536:64 Kbytes"   "131072:128 Kbytes"   "262144:256 Kbytes"   "524288:512 Kbytes"  "1048576:1 Mbyte" "2097152:2 Mbytes" "4194304:4 Mbytes" "8388608:8 Mbytes" "16777216:16 Mbytes" "33554432:32 Mbytes" "67108864:64 Mbytes" "134217728:128 Mbytes" "268435456:256 Mbytes" "536870912:512 Mbytes" "1073741824:1 Gbyte" "2147483648:2 Gbytes"
proc_add_parameter      setting_support31bitdcachebypass            BOOLEAN     true
proc_add_parameter      setting_activateTrace                       BOOLEAN     false
proc_add_parameter      setting_allow_break_inst                    BOOLEAN     false
proc_add_parameter      setting_activateTestEndChecker              BOOLEAN     false
proc_add_parameter      setting_ecc_sim_test_ports                  BOOLEAN     false
proc_add_parameter      setting_disableocitrace                     BOOLEAN     false
proc_add_parameter      setting_activateMonitors                    BOOLEAN     true
proc_add_parameter      setting_HDLSimCachesCleared                 BOOLEAN     true
proc_add_parameter      setting_HBreakTest                          BOOLEAN     false
proc_add_parameter      setting_breakslaveoveride                   BOOLEAN     false
proc_add_parameter      mpu_useLimit                                BOOLEAN     false
proc_add_parameter      mpu_enabled                                 BOOLEAN     false
proc_add_parameter      mmu_enabled                                 BOOLEAN     false
proc_add_parameter      mmu_autoAssignTlbPtrSz                      BOOLEAN     true
proc_add_parameter      cpuReset                                    BOOLEAN     false
proc_add_parameter      resetrequest_enabled                        BOOLEAN     true
proc_add_parameter      setting_removeRAMinit                       BOOLEAN     false
proc_add_parameter      setting_tmr_output_disable                  BOOLEAN     false
proc_add_parameter      setting_shadowRegisterSets                  INTEGER     0       "0:63"
proc_add_parameter      mpu_numOfInstRegion                         INTEGER     8       "2"  "3"   "4"   "5"   "6"   "7"   "8"   "9"  "10"  "11"  "12"  "13"  "14"  "15"  "16"  "17"  "18"  "19"  "20"  "21"  "22"  "23"  "24"  "25"  "26"  "27"  "28"  "29"  "30"  "31"  "32"
proc_add_parameter      mpu_numOfDataRegion                         INTEGER     8       "2"  "3"   "4"   "5"   "6"   "7"   "8"   "9"  "10"  "11"  "12"  "13"  "14"  "15"  "16"  "17"  "18"  "19"  "20"  "21"  "22"  "23"  "24"  "25"  "26"  "27"  "28"  "29"  "30"  "31"  "32"
proc_add_parameter      mmu_TLBMissExcOffset                        INTEGER     0
proc_add_parameter      resetOffset                                 INTEGER     0
proc_add_parameter      exceptionOffset                             INTEGER     32
proc_add_parameter      cpuID                                       INTEGER     0
proc_add_parameter      breakOffset                                 INTEGER     32
proc_add_parameter      userDefinedSettings                         STRING      ""
proc_add_parameter      tracefilename                               STRING      ""
proc_add_parameter      resetSlave                                  STRING      "None"
proc_add_parameter      mmu_TLBMissExcSlave                         STRING      "None"
proc_add_parameter      exceptionSlave                              STRING      "None"
proc_add_parameter      breakSlave                                  STRING      "None"
# [SH] Change all Integer type with "_8" back to string since "string:Display name" is allowed
proc_add_parameter      setting_interruptControllerType             STRING      "Internal"  "Internal"  "External"
proc_add_parameter      setting_branchpredictiontype                STRING      "Dynamic"   "Static"  "Dynamic"
proc_add_parameter      setting_bhtPtrSz                            INTEGER     8           "8:256 Entries"  "12:4096 Entries"  "13:8192 Entries"
proc_add_parameter      cpuArchRev                                  INTEGER     "1"  "2: Revision 2 (R2)" "1: Revision 1 (R1)"

# Becomes derived parameter
proc_add_derived_parameter      stratix_dspblock_shift_mul          BOOLEAN     false
proc_add_derived_parameter      shifterType                         STRING      "fast_le_shift"  "medium_le_shift:${MEDIUM_LE_SHIFT}" "fast_le_shift:${FAST_LE_SHIFT}" 
proc_add_derived_parameter      multiplierType                      STRING      "mul_fast32"  "no_mul:${MUL_NONE}" "mul_slow32:${MUL_SLOW32}" "mul_fast32:${MUL_FAST32}"  "mul_fast64:${MUL_FAST64}"

proc_add_parameter      mul_shift_choice                            INTEGER     0    "0:Auto Selection" "1:Manual Selection"
# Only use when they are Manual
proc_add_parameter      mul_32_impl                                 INTEGER     2    "0:None" "1:Logic elements" "2:3 16-bit multipliers" "3:1 32-bit multiplier"
proc_add_parameter      mul_64_impl                                 INTEGER     0    "0:None" "1:1 16-bit multiplier"
proc_add_parameter      shift_rot_impl                              INTEGER     1    "0:Logic elements (non-pipelined)" "1:Logic elements (pipelined)"

proc_add_parameter      dividerType                                 STRING      "no_div"  "no_div:${DIV_NONE}" "srt2:${DIV_SRT2}"
proc_add_parameter      mpu_minInstRegionSize                       INTEGER     12          "8:256 Bytes"  "9:512 Bytes"  "10:1 Kbyte"  "11:2 Kbytes"  "12:4 Kbytes"  "13:8 Kbytes"  "14:16 Kbytes"  "15:32 Kbytes"  "16:64 Kbytes"  "17:128 Kbytes"  "18:256 Kbytes"  "19:512 Kbytes"  "20:1 Mbyte"
proc_add_parameter      mpu_minDataRegionSize                       INTEGER     12          "8:256 Bytes"  "9:512 Bytes"  "10:1 Kbyte"  "11:2 Kbytes"  "12:4 Kbytes"  "13:8 Kbytes"  "14:16 Kbytes"  "15:32 Kbytes"  "16:64 Kbytes"  "17:128 Kbytes"  "18:256 Kbytes"  "19:512 Kbytes"  "20:1 Mbyte"
proc_add_parameter      mmu_uitlbNumEntries                         INTEGER     4           "2:2 Entries"  "4:4 Entries"  "6:6 Entries"  "8:8 Entries"
proc_add_parameter      mmu_udtlbNumEntries                         INTEGER     6           "2:2 Entries"  "4:4 Entries"  "6:6 Entries"  "8:8 Entries"
proc_add_parameter      mmu_tlbPtrSz                                INTEGER     7           "7:128 Entries"  "8:256 Entries"  "9:512 Entries"  "10:1024 Entries"
proc_add_parameter      mmu_tlbNumWays                              INTEGER     16          "8:8 Ways"  "16:16 Ways"
proc_add_parameter      mmu_processIDNumBits                        INTEGER     8           "8:8 Bits"  "9:9 Bits"  "10:10 Bits"  "11:11 Bits"  "12:12 Bits"  "13:13 Bits"  "14:14 Bits"
proc_add_parameter      impl                                        STRING      "Fast"      "Tiny:Nios II/e"  "Fast:Nios II/f"
proc_add_parameter      icache_size                                 INTEGER     4096        "0:None"  "512:512 Bytes"  "1024:1 Kbyte"  "2048:2 Kbytes"  "4096:4 Kbytes"  "8192:8 Kbytes"  "16384:16 Kbytes"  "32768:32 Kbytes"  "65536:64 Kbytes"
proc_add_parameter      fa_cache_line                               INTEGER     2           "2:2" "4:4"
proc_add_parameter      fa_cache_linesize                           INTEGER     0           "0:None" "8:64 Bits"  "16:128 Bits"

# Created new parameter for TagRAM block type
# Old parameter still used for DataRAM block type
proc_add_parameter      icache_tagramBlockType                      STRING      "Automatic" "Automatic"  "M4K"  "M9K" "M10K" "M20K" "M144K"
proc_add_parameter      icache_ramBlockType                         STRING      "Automatic" "Automatic"  "M4K"  "MRam"  "MLAB"  "M9K" "M10K" "M20K" "M144K"
proc_add_parameter      icache_numTCIM                              INTEGER     0           "0:None"  "1:1"  "2:2"  "3:3"  "4:4"
proc_add_parameter      icache_burstType                            STRING      "None"      "None:Disable"  "Sequential:Enable"
proc_add_parameter      dcache_bursts                               STRING      "false"     "false:Disable" "true:Enable"
proc_add_parameter      dcache_victim_buf_impl                      STRING      "ram"       "ram:RAM"   "reg:Registers"
proc_add_parameter      dcache_size                                 INTEGER     2048        "0:None"  "512:512 Bytes"  "1024:1 Kbyte"  "2048:2 Kbytes"  "4096:4 Kbytes"  "8192:8 Kbytes"  "16384:16 Kbytes"  "32768:32 Kbytes"  "65536:64 Kbytes"
proc_add_parameter      dcache_tagramBlockType                      STRING      "Automatic" "Automatic"  "M4K"  "M9K" "M10K" "M20K" "M144K"
proc_add_parameter      dcache_ramBlockType                         STRING      "Automatic" "Automatic"  "M4K"  "MRam"  "MLAB"  "M9K" "M10K" "M20K" "M144K"
proc_add_parameter      dcache_numTCDM                              INTEGER     0           "0:None"  "1:1"  "2:2"  "3:3"  "4:4"
# Adding new parameter for exporting reset/exception/break vectors
proc_add_parameter      setting_exportvectors                       BOOLEAN     false
proc_add_parameter      setting_usedesignware                       BOOLEAN     false
# Parameters for ECC Options
proc_add_parameter      setting_ecc_present                         BOOLEAN     false
proc_add_parameter      setting_ic_ecc_present                      BOOLEAN     true
proc_add_parameter      setting_rf_ecc_present                      BOOLEAN     true
proc_add_parameter      setting_mmu_ecc_present                     BOOLEAN     true
proc_add_parameter      setting_dc_ecc_present                      BOOLEAN     true
proc_add_parameter      setting_itcm_ecc_present                    BOOLEAN     true
proc_add_parameter      setting_dtcm_ecc_present                    BOOLEAN     true
# RAM block type parameter for all NIOS II RAMs
proc_add_parameter      regfile_ramBlockType                        STRING      "Automatic" "Automatic"  "M4K"  "MRam"  "MLAB"  "M9K" "M10K" "M20K" "M144K"
proc_add_parameter      ocimem_ramBlockType                         STRING      "Automatic" "Automatic"  "M4K"  "MRam"  "MLAB"  "M9K" "M10K" "M20K" "M144K"
proc_add_parameter      ocimem_ramInit                              BOOLEAN     false
proc_add_parameter      mmu_ramBlockType                            STRING      "Automatic" "Automatic"  "M4K"  "MRam"  "MLAB"  "M9K" "M10K" "M20K" "M144K"
proc_add_parameter      bht_ramBlockType                            STRING      "Automatic" "Automatic"  "M4K"  "MRam"  "MLAB"  "M9K" "M10K" "M20K" "M144K"
# CDX
proc_add_parameter      cdx_enabled                                 BOOLEAN     false
proc_add_parameter      mpx_enabled                                 BOOLEAN     false
# Debug parameters
proc_add_parameter      debug_enabled                               BOOLEAN     true
proc_add_parameter      debug_triggerArming                         BOOLEAN     true
proc_add_parameter      debug_debugReqSignals                       BOOLEAN     false
proc_add_parameter      debug_assignJtagInstanceID                  BOOLEAN     false
proc_add_parameter      debug_jtagInstanceID                        INTEGER     0       "0:255"
proc_add_parameter      debug_OCIOnchipTrace                        STRING      "_128"  "_128:128"  "_256:256"  "_512:512"  "_1k:1k"  "_2k:2k"  "_4k:4k"  "_8k:8k"  "_16k:16k"
proc_add_parameter      debug_hwbreakpoint                          INTEGER     "0"     "0:0"  "2:2"  "4:4"
proc_add_parameter      debug_datatrigger                           INTEGER     "0"     "0:0"  "2:2"  "4:4"
proc_add_parameter      debug_traceType                             STRING      "none"  "none:None"  "instruction_trace:Instruction Trace"  "instruction_and_data_trace:Instruction and Data Trace"
proc_add_parameter      debug_traceStorage                          STRING      "onchip_trace"  "onchip_trace:On-Chip Trace"  "offchip_trace:Off-Chip Trace"  "on_offchip_trace:On-Chip and Off-Chip Trace"

# Allow user to select their own base and size for each masters available on Nios II
proc_add_parameter      master_addr_map                                    BOOLEAN     false
proc_add_parameter      instruction_master_paddr_base                      INTEGER     "0"
proc_add_parameter      instruction_master_paddr_size                      LONG      0  "0:None"  "4096:4 Kbytes"  "8192:8 Kbytes"   "16384:16 Kbytes"   "32768:32 Kbytes"   "65536:64 Kbytes"   "131072:128 Kbytes"   "262144:256 Kbytes"   "524288:512 Kbytes"  "1048576:1 Mbyte" "2097152:2 Mbytes" "4194304:4 Mbytes" "8388608:8 Mbytes" "16777216:16 Mbytes" "33554432:32 Mbytes" "67108864:64 Mbytes" "134217728:128 Mbytes" "268435456:256 Mbytes" "536870912:512 Mbytes" "1073741824:1 Gbyte" "2147483648:2 Gbytes" "4294967296:4 Gbytes"
proc_add_parameter      flash_instruction_master_paddr_base                INTEGER     "0"
proc_add_parameter      flash_instruction_master_paddr_size                LONG      0  "0:None"  "4096:4 Kbytes"  "8192:8 Kbytes"   "16384:16 Kbytes"   "32768:32 Kbytes"   "65536:64 Kbytes"   "131072:128 Kbytes"   "262144:256 Kbytes"   "524288:512 Kbytes"  "1048576:1 Mbyte" "2097152:2 Mbytes" "4194304:4 Mbytes" "8388608:8 Mbytes" "16777216:16 Mbytes" "33554432:32 Mbytes" "67108864:64 Mbytes" "134217728:128 Mbytes" "268435456:256 Mbytes" "536870912:512 Mbytes" "1073741824:1 Gbyte" "2147483648:2 Gbytes" "4294967296:4 Gbytes"
proc_add_parameter      data_master_paddr_base                             INTEGER     "0"
proc_add_parameter      data_master_paddr_size                             LONG      0  "0:None"  "4096:4 Kbytes"  "8192:8 Kbytes"   "16384:16 Kbytes"   "32768:32 Kbytes"   "65536:64 Kbytes"   "131072:128 Kbytes"   "262144:256 Kbytes"   "524288:512 Kbytes"  "1048576:1 Mbyte" "2097152:2 Mbytes" "4194304:4 Mbytes" "8388608:8 Mbytes" "16777216:16 Mbytes" "33554432:32 Mbytes" "67108864:64 Mbytes" "134217728:128 Mbytes" "268435456:256 Mbytes" "536870912:512 Mbytes" "1073741824:1 Gbyte" "2147483648:2 Gbytes" "4294967296:4 Gbytes"
proc_add_parameter      tightly_coupled_instruction_master_0_paddr_base    INTEGER     "0"
proc_add_parameter      tightly_coupled_instruction_master_0_paddr_size    LONG      0  "0:None"  "4096:4 Kbytes"  "8192:8 Kbytes"   "16384:16 Kbytes"   "32768:32 Kbytes"   "65536:64 Kbytes"   "131072:128 Kbytes"   "262144:256 Kbytes"   "524288:512 Kbytes"  "1048576:1 Mbyte" "2097152:2 Mbytes" "4194304:4 Mbytes" "8388608:8 Mbytes" "16777216:16 Mbytes" "33554432:32 Mbytes" "67108864:64 Mbytes" "134217728:128 Mbytes" "268435456:256 Mbytes" "536870912:512 Mbytes" "1073741824:1 Gbyte" "2147483648:2 Gbytes" "4294967296:4 Gbytes"
proc_add_parameter      tightly_coupled_instruction_master_1_paddr_base    INTEGER     "0"
proc_add_parameter      tightly_coupled_instruction_master_1_paddr_size    LONG      0  "0:None"  "4096:4 Kbytes"  "8192:8 Kbytes"   "16384:16 Kbytes"   "32768:32 Kbytes"   "65536:64 Kbytes"   "131072:128 Kbytes"   "262144:256 Kbytes"   "524288:512 Kbytes"  "1048576:1 Mbyte" "2097152:2 Mbytes" "4194304:4 Mbytes" "8388608:8 Mbytes" "16777216:16 Mbytes" "33554432:32 Mbytes" "67108864:64 Mbytes" "134217728:128 Mbytes" "268435456:256 Mbytes" "536870912:512 Mbytes" "1073741824:1 Gbyte" "2147483648:2 Gbytes" "4294967296:4 Gbytes"
proc_add_parameter      tightly_coupled_instruction_master_2_paddr_base    INTEGER     "0"
proc_add_parameter      tightly_coupled_instruction_master_2_paddr_size    LONG      0  "0:None"  "4096:4 Kbytes"  "8192:8 Kbytes"   "16384:16 Kbytes"   "32768:32 Kbytes"   "65536:64 Kbytes"   "131072:128 Kbytes"   "262144:256 Kbytes"   "524288:512 Kbytes"  "1048576:1 Mbyte" "2097152:2 Mbytes" "4194304:4 Mbytes" "8388608:8 Mbytes" "16777216:16 Mbytes" "33554432:32 Mbytes" "67108864:64 Mbytes" "134217728:128 Mbytes" "268435456:256 Mbytes" "536870912:512 Mbytes" "1073741824:1 Gbyte" "2147483648:2 Gbytes" "4294967296:4 Gbytes"   
proc_add_parameter      tightly_coupled_instruction_master_3_paddr_base    INTEGER     "0"
proc_add_parameter      tightly_coupled_instruction_master_3_paddr_size    LONG      0  "0:None"  "4096:4 Kbytes"  "8192:8 Kbytes"   "16384:16 Kbytes"   "32768:32 Kbytes"   "65536:64 Kbytes"   "131072:128 Kbytes"   "262144:256 Kbytes"   "524288:512 Kbytes"  "1048576:1 Mbyte" "2097152:2 Mbytes" "4194304:4 Mbytes" "8388608:8 Mbytes" "16777216:16 Mbytes" "33554432:32 Mbytes" "67108864:64 Mbytes" "134217728:128 Mbytes" "268435456:256 Mbytes" "536870912:512 Mbytes" "1073741824:1 Gbyte" "2147483648:2 Gbytes" "4294967296:4 Gbytes"
proc_add_parameter      tightly_coupled_data_master_0_paddr_base           INTEGER     "0"
proc_add_parameter      tightly_coupled_data_master_0_paddr_size           LONG      0  "0:None"  "4096:4 Kbytes"  "8192:8 Kbytes"   "16384:16 Kbytes"   "32768:32 Kbytes"   "65536:64 Kbytes"   "131072:128 Kbytes"   "262144:256 Kbytes"   "524288:512 Kbytes"  "1048576:1 Mbyte" "2097152:2 Mbytes" "4194304:4 Mbytes" "8388608:8 Mbytes" "16777216:16 Mbytes" "33554432:32 Mbytes" "67108864:64 Mbytes" "134217728:128 Mbytes" "268435456:256 Mbytes" "536870912:512 Mbytes" "1073741824:1 Gbyte" "2147483648:2 Gbytes" "4294967296:4 Gbytes"
proc_add_parameter      tightly_coupled_data_master_1_paddr_base           INTEGER     "0"
proc_add_parameter      tightly_coupled_data_master_1_paddr_size           LONG      0  "0:None"  "4096:4 Kbytes"  "8192:8 Kbytes"   "16384:16 Kbytes"   "32768:32 Kbytes"   "65536:64 Kbytes"   "131072:128 Kbytes"   "262144:256 Kbytes"   "524288:512 Kbytes"  "1048576:1 Mbyte" "2097152:2 Mbytes" "4194304:4 Mbytes" "8388608:8 Mbytes" "16777216:16 Mbytes" "33554432:32 Mbytes" "67108864:64 Mbytes" "134217728:128 Mbytes" "268435456:256 Mbytes" "536870912:512 Mbytes" "1073741824:1 Gbyte" "2147483648:2 Gbytes" "4294967296:4 Gbytes"
proc_add_parameter      tightly_coupled_data_master_2_paddr_base           INTEGER     "0"
proc_add_parameter      tightly_coupled_data_master_2_paddr_size           LONG      0  "0:None"  "4096:4 Kbytes"  "8192:8 Kbytes"   "16384:16 Kbytes"   "32768:32 Kbytes"   "65536:64 Kbytes"   "131072:128 Kbytes"   "262144:256 Kbytes"   "524288:512 Kbytes"  "1048576:1 Mbyte" "2097152:2 Mbytes" "4194304:4 Mbytes" "8388608:8 Mbytes" "16777216:16 Mbytes" "33554432:32 Mbytes" "67108864:64 Mbytes" "134217728:128 Mbytes" "268435456:256 Mbytes" "536870912:512 Mbytes" "1073741824:1 Gbyte" "2147483648:2 Gbytes" "4294967296:4 Gbytes"
proc_add_parameter      tightly_coupled_data_master_3_paddr_base           INTEGER     "0"
proc_add_parameter      tightly_coupled_data_master_3_paddr_size           LONG      0  "0:None"  "4096:4 Kbytes"  "8192:8 Kbytes"   "16384:16 Kbytes"   "32768:32 Kbytes"   "65536:64 Kbytes"   "131072:128 Kbytes"   "262144:256 Kbytes"   "524288:512 Kbytes"  "1048576:1 Mbyte" "2097152:2 Mbytes" "4194304:4 Mbytes" "8388608:8 Mbytes" "16777216:16 Mbytes" "33554432:32 Mbytes" "67108864:64 Mbytes" "134217728:128 Mbytes" "268435456:256 Mbytes" "536870912:512 Mbytes" "1073741824:1 Gbyte" "2147483648:2 Gbytes" "4294967296:4 Gbytes"
proc_add_parameter      instruction_master_high_performance_paddr_base     INTEGER     "0"
proc_add_parameter      instruction_master_high_performance_paddr_size     LONG      0  "0:None"  "4096:4 Kbytes"  "8192:8 Kbytes"   "16384:16 Kbytes"   "32768:32 Kbytes"   "65536:64 Kbytes"   "131072:128 Kbytes"   "262144:256 Kbytes"   "524288:512 Kbytes"  "1048576:1 Mbyte" "2097152:2 Mbytes" "4194304:4 Mbytes" "8388608:8 Mbytes" "16777216:16 Mbytes" "33554432:32 Mbytes" "67108864:64 Mbytes" "134217728:128 Mbytes" "268435456:256 Mbytes" "536870912:512 Mbytes" "1073741824:1 Gbyte" "2147483648:2 Gbytes" "4294967296:4 Gbytes"
proc_add_parameter      data_master_high_performance_paddr_base            INTEGER     "0"
proc_add_parameter      data_master_high_performance_paddr_size            LONG      0  "0:None"  "4096:4 Kbytes"  "8192:8 Kbytes"   "16384:16 Kbytes"   "32768:32 Kbytes"   "65536:64 Kbytes"   "131072:128 Kbytes"   "262144:256 Kbytes"   "524288:512 Kbytes"  "1048576:1 Mbyte" "2097152:2 Mbytes" "4194304:4 Mbytes" "8388608:8 Mbytes" "16777216:16 Mbytes" "33554432:32 Mbytes" "67108864:64 Mbytes" "134217728:128 Mbytes" "268435456:256 Mbytes" "536870912:512 Mbytes" "1073741824:1 Gbyte" "2147483648:2 Gbytes" "4294967296:4 Gbytes"

#------------------------------
# [4.2] Display Parameter In GUI
#------------------------------
set CORE         "Main"
set CORE_0       "Select an Implementation"
set CORE_2       "Reset Vector"
set CORE_3       "Exception Vector"
set CORE_4       "Fast TLB Miss Exception Vector"

set SLAVE_VECTORS "Vectors"
set EXPORT_VECTORS "Export Vectors Settings"

set CACHE        "Caches and Memory Interfaces"
set ICACHE       "Instruction Cache"
set DCACHE       "Data Cache"
set MEMORY_INTERFACE      "Tightly-coupled Memories"

set ADVANCED     "Advanced Features"
set ADVANCED_1   "General"
set ADVANCED_2   "Exception Checking"
set ADVANCED_3   "Branch Prediction"
set ADVANCED_5   "Internal Verification Settings"

set MMU_MPU      "MMU and MPU Settings"
set MMU          "MMU"
set MPU          "MPU"

set DEBUG        "JTAG Debug"
set DEBUG_1      "JTAG Debug Settings"
set DEBUG_2      "Break Vector"
set DEBUG_3      "Advanced Debug Settings"

set ASIC_SETTINGS "ASIC Settings"

set CI           "Custom Instruction"
set CI_0         "General"

set TEST         "Test"
set HTML_TAB     " &nbsp &nbsp &nbsp &nbsp "
set REG_BLOCK_TYPE "Register File RAM Block Type"
set OCIMEM_BLOCK_TYPE "OCI Memory RAM Block Type"
set PERIPHERAL_REGION "Peripheral Region"

# Original html at //acds/main/regtest/ip/sopc_builder_ip/altera_nios2/scripts/flow/system/merlin_support/_hwtcl_html_table/
set NIOSII_TABLE "<html><table border=\"1\" width=\"100%\">
  <tr bgcolor=\"#C9DBF3\">
    <td>
    </td>
    <td><font size=5>
      Nios II/e
    </font></td>
    <td><font size=5>
      Nios II/f
    </font></td>
  </tr>
  <tr bgcolor=\"#FFFFFF\">
    <td valign=\"top\"><b>
      Summary
    </b></td>
    <td valign=\"top\" width=\"240\"><b>
      Resource-optimized 32-bit RISC
    </b></td>
    <td valign=\"top\" width=\"240\"><b>
      Performance-optimized 32-bit RISC
    </b></td>
  </tr>
  <tr bgcolor=\"#FFFFFF\">
    <td valign=\"top\"><b>
      Features 
    </b></td>
    <td valign=\"top\"><b>
      JTAG Debug<br>
      ECC RAM Protection<br>
    </b></td>
    <td valign=\"top\"><b>
      JTAG Debug<br>
      Hardware Multiply/Divide<br>
      Instruction/Data Caches<br>
      Tightly-Coupled Masters<br>
      ECC RAM Protection<br>
      External Interrupt Controller<br>
      Shadow Register Sets<br>
      MPU<br>
      MMU<br>
    </b></td>
  </tr>
  <tr bgcolor=\"#C9DBF3\">
  <td>RAM Usage</td>
  <td>2 + Options</td>
  <td>2 + Options</td>
  </tr>
       </table></html>"
		  
set JTAG_DEBUG_TABLE "<html><table border=\"1\" width=\"100%\">
  <tr bgcolor=\"#C9DBF3\">
    <th></th>
    <th>Level 1</th>
    <th>Level 2</th>
    <th>Level 3</th>
    <th>Level 4</th>
  </tr>
  <tr bgcolor=\"#FFFFFF\">
    <td valign=\"top\"><b>
      Features</b></td>
    <td valign=\"top\"><b>
      Download Software<br>
      Software Breakpoints
    </b></td>
    <td valign=\"top\">
      Download Software<br>
      Software Breakpoints<br><b>
      2 Hardware Breakpoints<br>
      2 Data Triggers
    </b></td>
    <td valign=\"top\">
      Download Software<br>
      Software Breakpoints<br>
      2 Hardware Breakpoints<br>
      2 Data Triggers<br><b>
      Instruction Trace<br>
      On-Chip Trace
    </b></td>
    <td valign=\"top\">
      Download Software<br>
      Software Breakpoints<br><b>
      4 Hardware Breakpoints<br>
      4 Data Triggers</b><br>
      Instruction Trace<br>
      On-Chip Trace<br><b>
      Data Trace<br>
      Off-chip Trace
    </b></td>
  </tr>
  <tr bgcolor=\"#C9DBF3\">
    <td>RAM Usage</td>
    <td>1</td>
    <td>1</td>
    <td>1 + Trace</td>
    <td>1 + Trace</td>
  </tr>
</table></html>"

			
#-------------------------------------------------------------------------------
# [4.4] Derived Parameter
#-------------------------------------------------------------------------------
proc_add_derived_parameter  resetAbsoluteAddr       INTEGER     0
proc_add_derived_parameter  exceptionAbsoluteAddr   INTEGER     0
proc_add_derived_parameter  breakAbsoluteAddr       INTEGER     0
proc_add_derived_parameter  mmu_TLBMissExcAbsAddr   INTEGER     0
proc_add_derived_parameter  dcache_bursts_derived   STRING      "false"
proc_add_derived_parameter  dcache_size_derived     INTEGER     2048
proc_add_derived_parameter  breakSlave_derived      STRING      "None"

# Dcache lineSize is always 32 bytes
proc_add_derived_parameter  dcache_lineSize_derived INTEGER     32
set_parameter_property      dcache_bursts_derived   "VISIBLE"   "false"
set_parameter_property      dcache_size_derived     "VISIBLE"   "false"
set_parameter_property      dcache_lineSize_derived "VISIBLE"   "false"
set_parameter_property      breakSlave_derived      "VISIBLE"   "false"
set_parameter_property      stratix_dspblock_shift_mul      "VISIBLE"   "false"

# Derived parameter for Dcache bypass type
proc_add_derived_parameter  setting_ioregionBypassDCache     BOOLEAN     false
set_parameter_property      setting_ioregionBypassDCache     "VISIBLE"   "false"
proc_add_derived_parameter  setting_bit31BypassDCache        BOOLEAN     false
set_parameter_property      setting_bit31BypassDCache        "VISIBLE"   "false"

# Additional derived parameter for translate_on_off (ASIC only)
# Overriding the Visible property
proc_add_derived_parameter  translate_on            STRING     { "synthesis translate_on"  }
proc_add_derived_parameter  translate_off           STRING     { "synthesis translate_off" }
set_parameter_property  translate_on  "VISIBLE" false
set_parameter_property  translate_off "VISIBLE" false

proc_add_derived_parameter  debug_onchiptrace       BOOLEAN    false
set_parameter_property  debug_onchiptrace  "VISIBLE" false
proc_add_derived_parameter  debug_offchiptrace       BOOLEAN    false
set_parameter_property  debug_offchiptrace  "VISIBLE" false
proc_add_derived_parameter  debug_insttrace           BOOLEAN    false
set_parameter_property  debug_insttrace  "VISIBLE" false
proc_add_derived_parameter  debug_datatrace           BOOLEAN    false
set_parameter_property  debug_datatrace  "VISIBLE" false

set stratix_dspblock_description {}
append stratix_dspblock_description "<table border=\"1\">"
append stratix_dspblock_description "<tr>"
append stratix_dspblock_description "<th>Name</th>"
append stratix_dspblock_description "<th>Description</th>"
append stratix_dspblock_description "</tr>"
append stratix_dspblock_description "<tr>"
append stratix_dspblock_description "<td>Automatic</td>"
append stratix_dspblock_description "<td>Recommended Multiply/Shift/Rotate Hardware implementations according to Device Family selected</td>"
append stratix_dspblock_description "</tr>"
append stratix_dspblock_description "<tr>"
append stratix_dspblock_description "<td>Manual</td>"
append stratix_dspblock_description "<td>Manually select the Multiply/Shift/Rotate Hardware implementations</td>"
append stratix_dspblock_description "</tr>"
append stratix_dspblock_description "</table>"

set div_description {}
append div_description "<table border=\"1\">"
append div_description "<tr>"
append div_description "<th>Name</th>"
append div_description "<th>Performance</th>"
append div_description "<th>Instructions</th>"
append div_description "</tr>"
append div_description "<tr>"
append div_description "<td>None</td>"
append div_description "<td>-</td>"
append div_description "<td>None</td>"
append div_description "</tr>"
append div_description "<tr>"
append div_description "<td>SRT Radix-2</td>"
append div_description "<td>35 cycles</td>"
append div_description "<td>All divide</td>"
append div_description "</tr>"
append div_description "</table>"

# $CORE
add_display_item            ""                                          $CORE       GROUP tab
add_display_item            "$CORE"                                     $CORE_0       GROUP
proc_set_display_group      cpuArchRev                                  $CORE_0       1   "Architecture Revision"
proc_set_display_group      impl                                        $CORE_0       0   "Nios II Core"
add_text_message   							                            $CORE_0       ${NIOSII_TABLE}

add_display_item            ""                                          $SLAVE_VECTORS   GROUP tab
add_display_item            "$SLAVE_VECTORS"                            $CORE_2         GROUP
add_display_item            "$SLAVE_VECTORS"                            $CORE_3         GROUP
add_display_item            "$SLAVE_VECTORS"                            $CORE_4         GROUP
add_display_item            "$SLAVE_VECTORS"                            $DEBUG_2        GROUP
add_display_item            "$SLAVE_VECTORS"                            $EXPORT_VECTORS        GROUP
add_display_item            "$SLAVE_VECTORS"                            "Address Map"        GROUP
proc_set_display_group      resetSlave                                  $CORE_2       0   "Reset vector memory"
proc_set_display_group      resetOffset                                 $CORE_2       0   "Reset vector offset"
proc_set_display_group      resetAbsoluteAddr                           $CORE_2       0   "Reset vector"
proc_set_display_group      exceptionSlave                              $CORE_3       0   "Exception vector memory"
proc_set_display_group      exceptionOffset                             $CORE_3       0   "Exception vector offset"
proc_set_display_group      exceptionAbsoluteAddr                       $CORE_3       0   "Exception vector"
proc_set_display_group      mmu_TLBMissExcSlave                         $CORE_4       0   "Fast TLB Miss Exception vector memory"
proc_set_display_group      mmu_TLBMissExcOffset                        $CORE_4       0   "Fast TLB Miss Exception vector offset"
proc_set_display_group      mmu_TLBMissExcAbsAddr                       $CORE_4       0   "Fast TLB Miss Exception vector"
proc_set_display_group      breakSlave                                  $DEBUG_2      0   "Break vector memory"
proc_set_display_group      breakOffset                                 $DEBUG_2      0   "Break vector offset"
proc_set_display_group      breakAbsoluteAddr                           $DEBUG_2      0   "Break vector"
proc_set_display_group      setting_exportvectors                       $EXPORT_VECTORS   1   "Export Vectors"
proc_set_display_group      master_addr_map                                   "Address Map"   1   "Manually Set Master Base Address and Size"                               
proc_set_display_group      instruction_master_paddr_base                     "Address Map"   1   "Instruction Master Base Address"
proc_set_display_group      instruction_master_paddr_size                     "Address Map"   1   "Instruction Master Size"        
proc_set_display_group      data_master_paddr_base                            "Address Map"   1   "Data Master Base Address"
proc_set_display_group      data_master_paddr_size                            "Address Map"   1   "Data Master Size"        
proc_set_display_group      instruction_master_high_performance_paddr_base    "Address Map"   1   "Instruction Master High Performance Base Address"
proc_set_display_group      instruction_master_high_performance_paddr_size    "Address Map"   1   "Instruction Master High Performance Size"        
proc_set_display_group      data_master_high_performance_paddr_base           "Address Map"   1   "Data Master High Performance Base Address"
proc_set_display_group      data_master_high_performance_paddr_size           "Address Map"   1   "Data Master High Performance Size"
proc_set_display_group      flash_instruction_master_paddr_base               "Address Map"   1   "Flash Instruction Master Base Address"
proc_set_display_group      flash_instruction_master_paddr_size               "Address Map"   1   "Flash Instruction Master Size"        
proc_set_display_group      tightly_coupled_instruction_master_0_paddr_base   "Address Map"   1   "Tightly coupled Instruction Master 0 Base Address"
proc_set_display_group      tightly_coupled_instruction_master_0_paddr_size   "Address Map"   1   "Tightly coupled Instruction Master 0 Size"        
proc_set_display_group      tightly_coupled_instruction_master_1_paddr_base   "Address Map"   1   "Tightly coupled Instruction Master 1 Base Address"
proc_set_display_group      tightly_coupled_instruction_master_1_paddr_size   "Address Map"   1   "Tightly coupled Instruction Master 1 Size"        
proc_set_display_group      tightly_coupled_instruction_master_2_paddr_base   "Address Map"   1   "Tightly coupled Instruction Master 2 Base Address"
proc_set_display_group      tightly_coupled_instruction_master_2_paddr_size   "Address Map"   1   "Tightly coupled Instruction Master 2 Size"        
proc_set_display_group      tightly_coupled_instruction_master_3_paddr_base   "Address Map"   1   "Tightly coupled Instruction Master 3 Base Address"
proc_set_display_group      tightly_coupled_instruction_master_3_paddr_size   "Address Map"   1   "Tightly coupled Instruction Master 3 Size"        
proc_set_display_group      tightly_coupled_data_master_0_paddr_base          "Address Map"   1   "Tightly coupled Data Master 0 Base Address"
proc_set_display_group      tightly_coupled_data_master_0_paddr_size          "Address Map"   1   "Tightly coupled Data Master 0 Size"        
proc_set_display_group      tightly_coupled_data_master_1_paddr_base          "Address Map"   1   "Tightly coupled Data Master 1 Base Address"
proc_set_display_group      tightly_coupled_data_master_1_paddr_size          "Address Map"   1   "Tightly coupled Data Master 1 Size"        
proc_set_display_group      tightly_coupled_data_master_2_paddr_base          "Address Map"   1   "Tightly coupled Data Master 2 Base Address"
proc_set_display_group      tightly_coupled_data_master_2_paddr_size          "Address Map"   1   "Tightly coupled Data Master 2 Size"        
proc_set_display_group      tightly_coupled_data_master_3_paddr_base          "Address Map"   1   "Tightly coupled Data Master 3 Base Address"
proc_set_display_group      tightly_coupled_data_master_3_paddr_size          "Address Map"   1   "Tightly coupled Data Master 3 Size"               

proc_set_display_format     instruction_master_paddr_base                     "hexadecimal"
proc_set_display_format     flash_instruction_master_paddr_base               "hexadecimal"
proc_set_display_format     data_master_paddr_base                            "hexadecimal"
proc_set_display_format     tightly_coupled_instruction_master_0_paddr_base   "hexadecimal"
proc_set_display_format     tightly_coupled_instruction_master_1_paddr_base   "hexadecimal"
proc_set_display_format     tightly_coupled_instruction_master_2_paddr_base   "hexadecimal"
proc_set_display_format     tightly_coupled_instruction_master_3_paddr_base   "hexadecimal"
proc_set_display_format     tightly_coupled_data_master_0_paddr_base          "hexadecimal"
proc_set_display_format     tightly_coupled_data_master_1_paddr_base          "hexadecimal"
proc_set_display_format     tightly_coupled_data_master_2_paddr_base          "hexadecimal"
proc_set_display_format     tightly_coupled_data_master_3_paddr_base          "hexadecimal"
proc_set_display_format     instruction_master_high_performance_paddr_base    "hexadecimal"
proc_set_display_format     data_master_high_performance_paddr_base           "hexadecimal"

# $CACHE
add_display_item            ""                                          $CACHE      GROUP tab
add_display_item            "$CACHE"                                    $ICACHE     GROUP
add_display_item            "$CACHE"                                    "Flash Accelerator"     GROUP
add_display_item            "$CACHE"                                    $DCACHE     GROUP
add_display_item            "$CACHE"                                    $MEMORY_INTERFACE     GROUP
add_display_item            "$CACHE"                                    $PERIPHERAL_REGION    GROUP
proc_set_display_group      io_regionsize                               $PERIPHERAL_REGION     0   "Size" "All addresses in the peripheral region produces uncacheable data accesses"
proc_set_display_group      io_regionbase                               $PERIPHERAL_REGION     0   "Base Address"
proc_set_display_group      icache_size                                 $ICACHE      0   "Size"
proc_set_display_group      icache_tagramBlockType                      $ICACHE      1   "Tag RAM block type"
proc_set_display_group      icache_ramBlockType                         $ICACHE      1   "Data RAM block type"
proc_set_display_group      icache_burstType                            $ICACHE      0   "Add burstcount signal to instruction_master"
proc_set_display_group      fa_cache_linesize                           "Flash Accelerator"      0   "Line Size" "The Flash accelerator is a small fully-associative cache for real-time applications. Use this when executing directly from on-chip memories such as flash."
proc_set_display_group      fa_cache_line                               "Flash Accelerator"      0   "Number of Cache Lines"
proc_set_display_group      dcache_size                                 $DCACHE      0   "Size"
proc_set_display_group      dcache_tagramBlockType                      $DCACHE      1   "Tag RAM block type"
proc_set_display_group      dcache_ramBlockType                         $DCACHE      1   "Data RAM block type"
proc_set_display_group      dcache_victim_buf_impl                      $DCACHE      0   "Victim buffer implementation"
proc_set_display_group      dcache_bursts                               $DCACHE      0   "Add burstcount signal to data_master"
proc_set_display_group      setting_support31bitdcachebypass            $DCACHE      0   "Use most-significant address bit in processor to bypass data cache" "When this option is enabled, the master interfaces only support up to a 31-bit byte address. Otherwise, they support up to a full 32-bit byte address."

proc_set_display_group      icache_numTCIM                              $MEMORY_INTERFACE      0   "Number of tightly coupled instruction master ports"
proc_set_display_group      dcache_numTCDM                              $MEMORY_INTERFACE      0   "Number of tightly coupled data master ports"


add_display_item            ""                                          "Arithmetic Instructions"       GROUP tab
proc_set_display_group      mul_shift_choice                            "Arithmetic Instructions"       0   "Multiply/Shift/Rotate Hardware" $stratix_dspblock_description
proc_set_display_group      dividerType                                 "Arithmetic Instructions"       0   "Divide Hardware" $div_description
add_display_item            "Arithmetic Instructions"                   "Arithmetic Implementation"     GROUP
proc_set_display_group      mul_32_impl                                 "Arithmetic Implementation"     0   "Multiply Implementation"
proc_set_display_group      mul_64_impl                                 "Arithmetic Implementation"     0   "Multiply Extended Implementation" "32-bit multiply with 64-bit product"
proc_set_display_group      shift_rot_impl                              "Arithmetic Implementation"     0   "Shift/Rotate Implementation"
add_display_item            "Arithmetic Instructions"                   "Summary"     GROUP
add_display_item "Summary" arithmetictable TEXT ""

# $MMU_MPU
add_display_item            ""                                          $MMU_MPU    GROUP tab
add_display_item            "$MMU_MPU"                                  $MMU        GROUP
add_display_item            "$MMU_MPU"                                  $MPU        GROUP
proc_set_display_group      mmu_enabled                                 $MMU       0   "Include MMU"
proc_set_display_group      mmu_processIDNumBits                        $MMU    0   "        Process ID (PID) bits"
proc_set_display_group      mmu_autoAssignTlbPtrSz                      $MMU    0   "Optimize TLB entries base on device family"
proc_set_display_group      mmu_tlbPtrSz                                $MMU    0   "        TLB entries"
proc_set_display_group      mmu_tlbNumWays                              $MMU    0   "        TLB Set-Associativity"
proc_set_display_group      mmu_udtlbNumEntries                         $MMU    0   "        Micro DTLB entries"
proc_set_display_group      mmu_uitlbNumEntries                         $MMU    0   "        Micro ITLB entries"
proc_set_display_group      mmu_ramBlockType                            $MMU    1   "        MMU RAM block type"
proc_set_display_group      mpu_enabled                                 $MPU    0   "Include MPU"
proc_set_display_group      mpu_useLimit                                $MPU    0   "Use Limit for region range"
proc_set_display_group      mpu_numOfDataRegion                         $MPU    0   "        Number of data regions"
proc_set_display_group      mpu_minDataRegionSize                       $MPU    0   "        Minimum data region size"
proc_set_display_group      mpu_numOfInstRegion                         $MPU    0   "        Number of instruction regions"
proc_set_display_group      mpu_minInstRegionSize                       $MPU    0   "        Minimum instruction region size"

# $DEBUG
add_display_item            ""                                          $DEBUG        GROUP       tab
add_display_item            "$DEBUG"                                    $DEBUG_1      GROUP
# add_display_item            "$DEBUG"                                    $DEBUG_3      GROUP
add_display_item            "$DEBUG"                                    $OCIMEM_BLOCK_TYPE      GROUP
add_display_item            "$DEBUG"                                    "Advanced Settings"   GROUP
proc_set_display_group      debug_enabled                               $DEBUG_1      0   "Include JTAG Debug"
add_text_message                                                        $DEBUG_1      "<html>${HTML_TAB}JTAG Target Connection.<br>${HTML_TAB}Enable Software Download and Software Breakpoint.<br>${HTML_TAB}Uses 1 M9K Memory.</html>"
proc_set_display_group      debug_hwbreakpoint                          $DEBUG_1      0   "Hardware Breakpoints" "Monitor Instruction Address"
proc_set_display_group      debug_datatrigger                           $DEBUG_1      0   "Data Triggers" "Monitor Data Address/Value"
proc_set_display_group      debug_traceType                             $DEBUG_1      0   "Trace Types"
proc_set_display_group      debug_traceStorage                          $DEBUG_1      0   "Trace Storage"
proc_set_display_group      debug_OCIOnchipTrace                        $DEBUG_1      0   "Onchip Trace Frame Size"
# add_text_message							$DEBUG_1      ${JTAG_DEBUG_TABLE}
proc_set_display_group      debug_debugReqSignals                       $DEBUG_1      0   "Include debugreq and debugack Signals"
add_text_message                                                        $DEBUG_1      "<html>${HTML_TAB}These signals appear on the top-level Qsys system.<br>${HTML_TAB}You must manually connect these signals to logic external to the Qsys system.</html>"
proc_set_display_group      debug_assignJtagInstanceID                  $DEBUG_1      1   "Assign JTAG Instance ID for debug core manually"
proc_set_display_group      debug_jtagInstanceID                        $DEBUG_1      1   "JTAG Instance ID value"

# add_text_message                                                        $DEBUG_3      "<html>Advance debug licenses can be purchased from MIPS Technologies, Inc. <a href=http://www.mips.com/fs2redirect.htm target=_blank>http://www.mips.com/fs2redirect.htm</a></html>"
proc_set_display_group      ocimem_ramBlockType                         $OCIMEM_BLOCK_TYPE    1   "RAM block type"

proc_set_display_group      setting_oci_version                         "Advanced Settings"    1   "Nios II OCI Version"             "Version 1: Use OCIRAM.\n Version 2: Does not use OCIRAM"
proc_set_display_group      setting_fast_register_read                  "Advanced Settings"    1   "Fast Register Read"              "Speed up General Purpose and Control Registers read accesses by host"
proc_set_display_group      setting_exportHostDebugPort                 "Advanced Settings"    1   "Export Debug Host Slave"         "Export the Debug-MM slave for the Debug Host Slave"

# $ADVANCED
add_display_item            ""                                          $ADVANCED     GROUP tab
add_display_item            "$ADVANCED"                                 $ADVANCED_1   GROUP
add_display_item            "$ADVANCED"                                 $ADVANCED_2   GROUP
add_display_item            "$ADVANCED"                                 $ADVANCED_3   GROUP
add_display_item            "$ADVANCED"                                 "ECC"         GROUP
add_display_item            "$ADVANCED"                                 "RAM Memory Protection"         GROUP
add_display_item            "$ADVANCED"                                 $REG_BLOCK_TYPE    GROUP
add_display_item            "$ADVANCED"                                 $ASIC_SETTINGS   GROUP
add_display_item            "$ADVANCED"                                 $ADVANCED_5   GROUP
proc_set_display_group      tmr_enabled                                 $ADVANCED_1   1   "Nios II Triple Mode Redundancy" "Enable TMR Mode for Nios"
proc_set_display_group      cdx_enabled                                 $ADVANCED_1   1   "CDX (Code Density eXtension) Instructions" "Adds 16-bit and 32-bit instructions"
# proc_set_display_group      mpx_enabled                                 $ADVANCED_1   1   "MPX (Multi-Processor eXtension) Instructions" "Supports LDSEX and STSEX instructions"
# proc_set_display_group      setting_bigEndian                           $ADVANCED_1   1   "Big endian"
proc_set_display_group      setting_ecc_present                         $ADVANCED_1   0   "ECC Present" "Adds ECC Protection to all internal Nios II RAM except for BHT RAM and OCI RAM. Adds ECC Protection to tightly-coupled memories (Data and Instructions)."
proc_set_display_group      setting_interruptControllerType             $ADVANCED_1   0   "Interrupt controller"
proc_set_display_group      setting_shadowRegisterSets                  $ADVANCED_1   0   "Number of shadow register sets (0-63)"
add_line_separator                                                      $ADVANCED_1
proc_set_display_group      cpuReset                                    $ADVANCED_1   0   "Include cpu_resetrequest and cpu_resettaken signals"
add_text_message                                                        $ADVANCED_1       "        These signals appear on the top-level Qsys system. You must manually connect these signals to logic external to the Qsys system"
add_line_separator                                                      $ADVANCED_1
proc_set_display_group      cpuID                                       $ADVANCED_1   0   "CPUID control register value"
add_text_message                                                        $ADVANCED_1       "        Assign unique values for CPUID if system has multiple Nios II cores sharing code"
add_line_separator                                                      $ADVANCED_1
proc_set_display_group      setting_activateTrace                       $ADVANCED_1   0   "Generate trace file during RTL simulation" "Creates a trace file called as \"system_name\"_\"cpu_name\".tr. Please use the nios2-trace command to display it."
proc_set_display_group      tracefilename                               $ADVANCED_1   1   "Trace File Name" "Manually specify trace file name. It will be \<Trace File Name\>.tr"
proc_set_display_group      setting_showUnpublishedSettings             $ADVANCED_1       1   "Show Unpublished Settings"
proc_set_display_group      setting_showInternalSettings                $ADVANCED_1       1   "Show Internal Verification Settings"
set_parameter_property      setting_showUnpublishedSettings "VISIBLE" "true"
set_parameter_property      setting_showInternalSettings    "VISIBLE" "true"
proc_set_display_group      setting_exportdebuginfo                     $ADVANCED_1   1   "Export Instruction Execution States" "Exports Program Counter (PC), Instruction Word (IW) and Exception bit (EXC) as Avalon-ST signals"
proc_set_display_group      setting_preciseIllegalMemAccessException    $ADVANCED_2   0   "Misaligned memory access" "Always present with MMU and MPU"
proc_set_display_group      setting_branchpredictiontype                $ADVANCED_3   0   "Branch prediction type"
proc_set_display_group      setting_bhtPtrSz                            $ADVANCED_3   0   "        Number of entries (2-bits wide)"
proc_set_display_group      bht_ramBlockType                            $ADVANCED_3   1   "BHT RAM Block Type"
proc_set_display_group      regfile_ramBlockType                        $REG_BLOCK_TYPE    1   "RAM block type"
proc_set_display_group      setting_ic_ecc_present                      "ECC"         1   "Instruction Cache ECC Present"
proc_set_display_group      setting_rf_ecc_present                      "ECC"         1   "Register File ECC Present"
proc_set_display_group      setting_dc_ecc_present                      "ECC"         1   "Data Cache ECC Present"
proc_set_display_group      setting_itcm_ecc_present                    "ECC"         1   "Instruction TCM ECC Present"
proc_set_display_group      setting_dtcm_ecc_present                    "ECC"         1   "Data TCM ECC Present"
proc_set_display_group      setting_mmu_ecc_present                     "ECC"         1   "MMU ECC Present"
proc_set_display_group      resetrequest_enabled                        "RAM Memory Protection"   0   "Include reset_req signal for OCI RAM and Multi-Cycle Custom Instructions"

# $TEST
#add_display_item            "$ADVANCED_5"                               $TEST       GROUP
proc_set_display_group      setting_activateMonitors                    $ADVANCED_5       1   "Activate monitors"                         "INTERNAL"
proc_set_display_group      setting_disableocitrace                     $ADVANCED_5       1   "Disable comptr generation"                 "INTERNAL"
proc_set_display_group      setting_clearXBitsLDNonBypass               $ADVANCED_5       1   "Clear X data bits"                         "INTERNAL"
proc_set_display_group      setting_HDLSimCachesCleared                 $ADVANCED_5       1   "HDL simulation caches cleared"             "INTERNAL"
proc_set_display_group      setting_activateTestEndChecker              $ADVANCED_5       1   "Activate test end checker"                 "INTERNAL"
proc_set_display_group      setting_ecc_sim_test_ports                  $ADVANCED_5       1   "Enable ECC simulation test ports"          "INTERNAL"
proc_set_display_group      setting_alwaysEncrypt                       $ADVANCED_5       1   "Always encrypt"                            "INTERNAL"
proc_set_display_group      setting_HBreakTest                          $ADVANCED_5       1   "Add HBreak Request port"                   "INTERNAL"
proc_set_display_group      setting_breakslaveoveride                   $ADVANCED_5       1   "Manually assign break slave"               "INTERNAL"
proc_set_display_group      setting_avalonDebugPortPresent              $ADVANCED_5       1   "Avalon Debug Port Present"                 "INTERNAL"
proc_set_display_group      debug_triggerArming                         $ADVANCED_5       1   "Trigger Arming"                            "INTERNAL"
proc_set_display_group      setting_allow_break_inst                    $ADVANCED_5       1   "Allow Break instructions"                  "INTERNAL"
proc_set_display_group      ocimem_ramInit                              $ADVANCED_5       1   "Initialized OCI RAM"
proc_set_display_group      setting_disable_tmr_inj                     $ADVANCED_5       1   "Disabled TMR Error Injection Port"         "INTERNAL"
proc_set_display_group      userDefinedSettings                         $ADVANCED_5       1   "User Defined Settings"                     "INTERNAL"

proc_set_display_group      setting_asic_enabled                        $ASIC_SETTINGS    1   "ASIC enabled"                              "Adds JTAG Cold Reset synchronous to CPU clock when JTAG Debug is enabled, disables certain design-warning suppresion. Used to enable other ASIC switches"
proc_set_display_group      setting_usedesignware                       $ASIC_SETTINGS    1   "Use Designware Components"                 "Replace multiplier, altsyncrams and shift/rotate blocks with DWC_n2p_mult, DWC_n2p_bcm58 and DW_shifter block respectively"
proc_set_display_group      setting_export_large_RAMs                   $ASIC_SETTINGS    1   "Export Large RAMs"                         "Export RAM interfaces to the top, including Instruction/Data Cache RAMs, MMU TLB RAM and OCI trace/instruction RAMs"
proc_set_display_group      setting_oci_export_jtag_signals             $ASIC_SETTINGS    1   "Export JTAG signals"                       "Export JTAG signals to the top to be connected to an Altera sld_virtual_jtag_basic instance"
proc_set_display_group      setting_asic_third_party_synthesis          $ASIC_SETTINGS    1   "ASIC third party synthesis"                "Removes quartus read comments as HDL"
proc_set_display_group      setting_asic_add_scan_mode_input            $ASIC_SETTINGS    1   "ASIC add scan mode input"                  "Adds a new input, scan mode which is used to select whether the reset synchronizers is fed by reset or \"reset_sources\""
proc_set_display_group      setting_asic_synopsys_translate_on_off      $ASIC_SETTINGS    1   "ASIC Synopsys translate"                   "Change synthesis translate on/off to synopsys translate on/off"
proc_set_display_group      setting_removeRAMinit                       $ASIC_SETTINGS    1   "Remove RAM Initialization"                 "Set all INIT_FILE parameter of the altsyncrams to \"UNUSED\""
proc_set_display_group      setting_tmr_output_disable                  $ASIC_SETTINGS    1   "Create a signal to disable TMR outputs"    "This is used to disable TMR outputs during reset (active low)"
proc_set_display_group      register_file_por                           $ASIC_SETTINGS    1   "Register File POR"                         "Adds Register File Cold Reset synchronous to CPU clock when this parameter is enabled. Only used for register type register file"

proc_set_display_format     resetOffset             "hexadecimal"
proc_set_display_format     resetAbsoluteAddr       "hexadecimal"
proc_set_display_format     exceptionOffset         "hexadecimal"
proc_set_display_format     exceptionAbsoluteAddr   "hexadecimal"
proc_set_display_format     mmu_TLBMissExcOffset    "hexadecimal"
proc_set_display_format     mmu_TLBMissExcAbsAddr   "hexadecimal"
proc_set_display_format     breakOffset             "hexadecimal"
proc_set_display_format     breakAbsoluteAddr       "hexadecimal"
proc_set_display_format     cpuID                   "hexadecimal"
proc_set_display_format     impl                    "radio"
# proc_set_display_format     debug_enable             "radio"
proc_set_display_format     io_regionbase           "hexadecimal"

proc_set_display_format     cpuArchRev              "radio"
set_parameter_property      shifterType       "VISIBLE" "false"
set_parameter_property      multiplierType    "VISIBLE" "false"

#------------------------------
# [4.3] SYSTEM_INFO Parameter
#------------------------------
proc_add_system_info_parameter          instAddrWidth                                       INTEGER         "1"                     "ADDRESS_WIDTH $I_MASTER_INTF"
proc_add_system_info_parameter          faAddrWidth                                         INTEGER         "1"                     "ADDRESS_WIDTH $FA_MASTER_INTF"
proc_add_system_info_parameter          dataAddrWidth                                       INTEGER         "1"                     "ADDRESS_WIDTH $D_MASTER_INTF"
proc_add_system_info_parameter          tightlyCoupledDataMaster0AddrWidth                  INTEGER         "1"             		"ADDRESS_WIDTH tightly_coupled_data_master_0"
proc_add_system_info_parameter          tightlyCoupledDataMaster1AddrWidth                  INTEGER         "1"             		"ADDRESS_WIDTH tightly_coupled_data_master_1"
proc_add_system_info_parameter          tightlyCoupledDataMaster2AddrWidth                  INTEGER         "1"             		"ADDRESS_WIDTH tightly_coupled_data_master_2"
proc_add_system_info_parameter          tightlyCoupledDataMaster3AddrWidth                  INTEGER         "1"             		"ADDRESS_WIDTH tightly_coupled_data_master_3"
proc_add_system_info_parameter          tightlyCoupledInstructionMaster0AddrWidth           INTEGER         "1"             		"ADDRESS_WIDTH tightly_coupled_instruction_master_0"
proc_add_system_info_parameter          tightlyCoupledInstructionMaster1AddrWidth           INTEGER         "1"             		"ADDRESS_WIDTH tightly_coupled_instruction_master_1"
proc_add_system_info_parameter          tightlyCoupledInstructionMaster2AddrWidth           INTEGER         "1"             		"ADDRESS_WIDTH tightly_coupled_instruction_master_2"
proc_add_system_info_parameter          tightlyCoupledInstructionMaster3AddrWidth           INTEGER         "1"             		"ADDRESS_WIDTH tightly_coupled_instruction_master_3"
proc_add_system_info_parameter          dataMasterHighPerformanceAddrWidth                  INTEGER         "1"             		"ADDRESS_WIDTH data_master_high_performance"
proc_add_system_info_parameter          instructionMasterHighPerformanceAddrWidth           INTEGER         "1"             		"ADDRESS_WIDTH instruction_master_high_performance"

proc_add_system_info_parameter          instSlaveMapParam                                   STRING          ""                      "ADDRESS_MAP $I_MASTER_INTF"
proc_add_system_info_parameter          faSlaveMapParam                                     STRING          ""                      "ADDRESS_MAP $FA_MASTER_INTF"
proc_add_system_info_parameter          dataSlaveMapParam                                   STRING          ""                      "ADDRESS_MAP $D_MASTER_INTF"
proc_add_system_info_parameter          tightlyCoupledDataMaster0MapParam                   STRING          ""          		     "ADDRESS_MAP tightly_coupled_data_master_0"
proc_add_system_info_parameter          tightlyCoupledDataMaster1MapParam                   STRING          ""          		     "ADDRESS_MAP tightly_coupled_data_master_1"
proc_add_system_info_parameter          tightlyCoupledDataMaster2MapParam                   STRING          ""          		     "ADDRESS_MAP tightly_coupled_data_master_2"
proc_add_system_info_parameter          tightlyCoupledDataMaster3MapParam                   STRING          ""          		     "ADDRESS_MAP tightly_coupled_data_master_3"
proc_add_system_info_parameter          tightlyCoupledInstructionMaster0MapParam            STRING          ""          		     "ADDRESS_MAP tightly_coupled_instruction_master_0"
proc_add_system_info_parameter          tightlyCoupledInstructionMaster1MapParam            STRING          ""          		     "ADDRESS_MAP tightly_coupled_instruction_master_1"
proc_add_system_info_parameter          tightlyCoupledInstructionMaster2MapParam            STRING          ""          		     "ADDRESS_MAP tightly_coupled_instruction_master_2"
proc_add_system_info_parameter          tightlyCoupledInstructionMaster3MapParam            STRING          ""          		     "ADDRESS_MAP tightly_coupled_instruction_master_3"
proc_add_system_info_parameter          dataMasterHighPerformanceMapParam                   STRING          ""          		     "ADDRESS_MAP data_master_high_performance"
proc_add_system_info_parameter          instructionMasterHighPerformanceMapParam            STRING          ""          		     "ADDRESS_MAP instruction_master_high_performance"

proc_add_system_info_parameter          clockFrequency                                      LONG            "50000000"              "CLOCK_RATE $CLOCK_INTF"
proc_add_system_info_parameter          deviceFamilyName                                    STRING          "STRATIXIV"             "DEVICE_FAMILY"
proc_add_system_info_parameter          internalIrqMaskSystemInfo                           LONG            "0x0"                   "INTERRUPTS_USED $IRQ_INTF"

proc_add_system_info_parameter          customInstSlavesSystemInfo                           STRING          ""                      "CUSTOM_INSTRUCTION_SLAVES $CI_MASTER_INTF"
proc_add_system_info_parameter          customInstSlavesSystemInfo_nios_a                    STRING          ""                      "CUSTOM_INSTRUCTION_SLAVES ${CI_MASTER_INTF}_a"
proc_add_system_info_parameter          customInstSlavesSystemInfo_nios_b                    STRING          ""                      "CUSTOM_INSTRUCTION_SLAVES ${CI_MASTER_INTF}_b"
proc_add_system_info_parameter          customInstSlavesSystemInfo_nios_c                    STRING          ""                      "CUSTOM_INSTRUCTION_SLAVES ${CI_MASTER_INTF}_c"

proc_add_system_info_parameter          deviceFeaturesSystemInfo                             STRING          ""                      "DEVICE_FEATURES"

#-------------------------------------------------------------------------------
# [5] INTERFACE
#-------------------------------------------------------------------------------

    
#------------------------------
# [5.1] Clock Interface
#------------------------------
add_interface           $CLOCK_INTF     "clock"     "sink"
set_interface_property  $CLOCK_INTF EXPORT_OF clock_bridge.in_clk
set_interface_property  $CLOCK_INTF PORT_NAME_MAP "$CLOCK_INTF in_clk"

#------------------------------
# [5.2] Reset Interface
#------------------------------
add_interface           reset     "reset"     "sink"     
set_interface_property  reset EXPORT_OF reset_bridge.in_reset
set_interface_property  reset PORT_NAME_MAP "reset_n in_reset_n reset_req in_reset_req"

#------------------------------
# In elaborate callback:-
# [6.1] Data Master Interface
# [6.2] Instruction Master Interface 
# [6.3] Tightly Couple Data Master 
# [6.4] Tightly Couple Instruction Master
# [6.5] Interrupt Interface
# [6.6] Jtag Debug Slave Interface
# [6.7] Avalon Debug Port Interface
# [6.8] Custom Instruction Interface 
# [6.9]Processor Instruction and Data Master
# [6.10] Conduit Interface
# [6.11] Avalon Hardware Break Interrupt Controller
#------------------------------

#------------------------------------------------------------------------------
# [6] ELABORATION Callback
#------------------------------------------------------------------------------

#------------------------------
# [6.3] T.C.Data.Master Interface
#------------------------------
proc sub_elaborate_tcdm_interface {instance} {
    global TCD_INTF_PREFIX
    global TCD_PREFIX
    
    set tcdm_num    [ get_parameter_value dcache_numTCDM ]
    set impl        [ get_parameter_value impl ]
    set data_width  32

    if { "${impl}" != "Tiny" } {
        foreach i {0 1 2 3} {
            set INTF_NAME "${TCD_INTF_PREFIX}${i}"
            set TCD_NAME  "${TCD_PREFIX}${i}"
            if { $i < $tcdm_num } {               
                set local_daddr_width [ get_parameter_value ${TCD_NAME}AddrWidth ]
                add_interface           $INTF_NAME      "avalon"                    "master"
                set_interface_property  $INTF_NAME EXPORT_OF $instance.$INTF_NAME
                
                set_interface_property  $INTF_NAME PORT_NAME_MAP "dtcm${i}_readdata      dtcm${i}_readdata
                                                                  dtcm${i}_response      dtcm${i}_response
                                                                  dtcm${i}_address       dtcm${i}_address
                                                                  dtcm${i}_read          dtcm${i}_read
                                                                  dtcm${i}_clken         dtcm${i}_clken
                                                                  dtcm${i}_write         dtcm${i}_write
                                                                  dtcm${i}_writedata     dtcm${i}_writedata
                                                                  dtcm${i}_byteenable    dtcm${i}_byteenable"    
            }
        }
    }
}

#------------------------------
# [6.3] H.P.Data.Master Interface
#------------------------------
proc sub_elaborate_dhpm_interface {instance} {
    global DHP_INTF_PREFIX
    global DHP_PREFIX
    
    set impl        [ get_parameter_value impl ]

    if { "${impl}" == "Small" } {
        set local_daddr_width [ get_parameter_value ${DHP_PREFIX}AddrWidth ]
        add_interface           $DHP_INTF_PREFIX      "avalon"                    "master"
        set_interface_property  $DHP_INTF_PREFIX EXPORT_OF $instance.$DHP_INTF_PREFIX
        set_interface_property  $DHP_INTF_PREFIX PORT_NAME_MAP "dhp_readdata      dhp_readdata
                                                                dhp_waitrequest   dhp_waitrequest
                                                                dhp_response      dhp_response
                                                                dhp_readdatavalid dhp_readdatavalid
                                                                dhp_address       dhp_address
                                                                dhp_read          dhp_read
                                                                dhp_write         dhp_write
                                                                dhp_writedata     dhp_writedata
                                                                dhp_byteenable    dhp_byteenable"
    }
}

#------------------------------
# [6.4] T.C.Inst.Master Interface
#------------------------------
proc sub_elaborate_tcim_interface {instance} {
    global TCI_INTF_PREFIX
    global TCI_PREFIX
    set tcim_num    [ get_parameter_value icache_numTCIM ]
    set impl        [ get_parameter_value impl ]

    if { "${impl}" != "Tiny" } {
        foreach i {0 1 2 3} {
            set INTF_NAME "${TCI_INTF_PREFIX}${i}"
            set TCI_NAME  "${TCI_PREFIX}${i}"
            
            if { $i < $tcim_num } {
                set local_iaddr_width [ get_parameter_value ${TCI_NAME}AddrWidth ]
                add_interface           $INTF_NAME      "avalon"                    "master"
                set_interface_property  $INTF_NAME EXPORT_OF $instance.$INTF_NAME
                set_interface_property  $INTF_NAME PORT_NAME_MAP "itcm${i}_readdata      itcm${i}_readdata
                                                                  itcm${i}_response      itcm${i}_response
                                                                  itcm${i}_address       itcm${i}_address
                                                                  itcm${i}_read          itcm${i}_read
                                                                  itcm${i}_clken         itcm${i}_clken
                                                                  itcm${i}_writedata     itcm${i}_writedata
                                                                  itcm${i}_write         itcm${i}_write"       
            }
        }
    }
}

#------------------------------
# Instruction High Performance Interface
#------------------------------
proc sub_elaborate_ihpm_interface {instance} {
    global IHP_INTF_PREFIX
    global IHP_PREFIX
    set impl        [ get_parameter_value impl ]

    if { "${impl}" == "Small" } {       
        set local_iaddr_width [ get_parameter_value ${IHP_PREFIX}AddrWidth ]
        add_interface           $IHP_INTF_PREFIX      "avalon"                    "master"
        set_interface_property  $IHP_INTF_PREFIX EXPORT_OF $instance.$IHP_INTF_PREFIX
        set_interface_property  $IHP_INTF_PREFIX PORT_NAME_MAP "ihp_readdata       ihp_readdata
                                                                ihp_waitrequest    ihp_waitrequest
                                                                ihp_response       ihp_response
                                                                ihp_readdatavalid  ihp_readdatavalid
                                                                ihp_address        ihp_address
                                                                ihp_read           ihp_read"        
    }
}

#------------------------------
# [6.5] Interrupt Interfaces - irq receiver / eic st port
#------------------------------
proc sub_elaborate_interrupt_controller_ports {instance} {
    global IRQ_INTF
    global EXT_IRQ_INTF
    global D_MASTER_INTF
    
    set tmr_enabled [ get_parameter_value tmr_enabled ]
    
    if { [ proc_get_eic_present ] } {
        # External IRQ Controller
        add_interface           $EXT_IRQ_INTF   "avalon_streaming"                  "end"
        set_interface_property  $EXT_IRQ_INTF EXPORT_OF $instance.$EXT_IRQ_INTF
        set_interface_property  $EXT_IRQ_INTF PORT_NAME_MAP "eic_port_valid eic_port_valid
                                                         eic_port_data  eic_port_data"
        proc_set_interface_embeddedsw_configuration_assignment $EXT_IRQ_INTF "isInterruptControllerReceiver" 1
    } else {
      if { $tmr_enabled } {
        # Internal IRQ Controller
        add_interface           $IRQ_INTF     "interrupt"                         "receiver"
        set_interface_property  $IRQ_INTF EXPORT_OF nios_irq_bridge.receiver_irq
        set_interface_property  $IRQ_INTF PORT_NAME_MAP "irq receiver_irq"
      } else {
        # Internal IRQ Controller
        add_interface           $IRQ_INTF     "interrupt"                         "receiver"
        set_interface_property  $IRQ_INTF EXPORT_OF $instance.$IRQ_INTF
        set_interface_property  $IRQ_INTF PORT_NAME_MAP "irq irq"
      }
    }
}

#------------------------------
# [6.11] hbreak Interrupt Interfaces - irq receiver
#------------------------------
proc sub_elaborate_hbreak_interrupt_controller_ports {} {
	global HBREAK_IRQ_INTF
	global I_MASTER_INTF
	
	set local_impl [ get_parameter_value impl ]
	set tmr_enabled [ get_parameter_value tmr_enabled ]

	if { [ proc_get_boolean_parameter setting_HBreakTest ] } {
	  if { $tmr_enabled } {
	    add_interface           $HBREAK_IRQ_INTF     "interrupt"                         "receiver"
	    set_interface_property  $HBREAK_IRQ_INTF EXPORT_OF nios_hbreak_irq_bridge.receiver_irq
	    set_interface_property  $HBREAK_IRQ_INTF PORT_NAME_MAP "test_hbreak_req receiver_irq"
	  } else {
	    add_interface           $HBREAK_IRQ_INTF     "interrupt"                         "receiver"
	    set_interface_property  $HBREAK_IRQ_INTF EXPORT_OF cpu.$HBREAK_IRQ_INTF
	    set_interface_property  $HBREAK_IRQ_INTF PORT_NAME_MAP "test_hbreak_req test_hbreak_req"
		}
	}
}

#------------------------------
# [6.12] TMR Only Interface
#------------------------------
proc sub_elaborate_tmr_mode {} {
    add_interface           tmr_interrupt     "interrupt"                         "sender"
    set_interface_property  tmr_interrupt EXPORT_OF nios_tmr_comparator.tmr_interrupt
	set_interface_property  tmr_interrupt PORT_NAME_MAP "tmr_interrupt tmr_interrupt"
		
	add_interface           tmr_reset_request     "reset"                "output"
    set_interface_property  tmr_reset_request PORT_NAME_MAP    "tmr_reset_request        tmr_reset_request"
    set_interface_property  tmr_reset_request EXPORT_OF nios_tmr_comparator.tmr_reset_request
    
    set setting_disable_tmr_inj [ get_parameter_value setting_disable_tmr_inj ]
    if { !$setting_disable_tmr_inj } {
        add_interface           tmr_err_inj   "avalon_streaming"                  "end"
        set_interface_property  tmr_err_inj EXPORT_OF nios_tmr_comparator.tmr_err_inj
        set_interface_property  tmr_err_inj PORT_NAME_MAP "tmr_err_inj tmr_err_inj"
    }
}
#------------------------------
# [6.6] Jtag Debug Slave interface
#------------------------------                    
proc sub_elaborate_jtag_debug_slave_interface {instance} {
    global DEBUG_INTF
    global I_MASTER_INTF
    global D_MASTER_INTF
    global DEBUG_HOST_INTF

    set local_debug_level [ proc_get_boolean_parameter debug_enabled ]
    set oci_version            [ get_parameter_value setting_oci_version ]
    set EXPORT_HOST_DEBUG_PORT [ get_parameter_value setting_exportHostDebugPort ]
    set onchip_trace_support [ proc_get_boolean_parameter debug_onchiptrace ]

    if { ${local_debug_level}  } {
        
        add_interface           debug_reset_request     "reset"                "output"
        set_interface_property  debug_reset_request PORT_NAME_MAP    "debug_reset_request        debug_reset_request"
        set_interface_property  debug_reset_request EXPORT_OF $instance.debug_reset_request
   
        if { $oci_version == 2 } {
            if { $EXPORT_HOST_DEBUG_PORT  } {
            add_interface           $DEBUG_HOST_INTF "avalon"                          "slave"
            set_interface_property  $DEBUG_HOST_INTF EXPORT_OF $instance.$DEBUG_HOST_INTF
            set_interface_property  $DEBUG_HOST_INTF PORT_NAME_MAP    "debug_host_slave_address      debug_host_slave_address
                                                                       debug_host_slave_read         debug_host_slave_read
                                                                       debug_host_slave_readdata     debug_host_slave_readdata
                                                                       debug_host_slave_write        debug_host_slave_write
                                                                       debug_host_slave_writedata    debug_host_slave_writedata
                                                                       debug_host_slave_waitrequest  debug_host_slave_waitrequest"
            add_interface           debug_extra   "avalon_streaming"                  "end"
            set_interface_property  debug_extra EXPORT_OF $instance.debug_extra
            set_interface_property  debug_extra PORT_NAME_MAP "debug_extra debug_extra"
            
                if { $onchip_trace_support } {
                    add_interface           debug_trace_slave "avalon"                          "slave"
                    set_interface_property  debug_trace_slave EXPORT_OF $instance.debug_trace_slave
                    set_interface_property  debug_trace_slave PORT_NAME_MAP    "debug_trace_slave_address      debug_host_slave_address
                                                                                debug_trace_slave_readdata     debug_trace_slave_readdata
                                                                                debug_trace_slave_read         debug_trace_slave_read"
                }
            }
        } else {            
            add_interface           $DEBUG_INTF     "avalon"                            "slave"
            set_interface_property  $DEBUG_INTF EXPORT_OF $instance.$DEBUG_INTF
            set_interface_property  $DEBUG_INTF PORT_NAME_MAP    "debug_mem_slave_address        debug_mem_slave_address
                                                                  debug_mem_slave_byteenable     debug_mem_slave_byteenable
                                                                  debug_mem_slave_debugaccess    debug_mem_slave_debugaccess
                                                                  debug_mem_slave_read           debug_mem_slave_read
                                                                  debug_mem_slave_readdata       debug_mem_slave_readdata
                                                                  debug_mem_slave_waitrequest    debug_mem_slave_waitrequest
                                                                  debug_mem_slave_write          debug_mem_slave_write
                                                                  debug_mem_slave_writedata      debug_mem_slave_writedata"
            set_interface_assignment $DEBUG_INTF    "qsys.ui.connect"                   "${I_MASTER_INTF},${D_MASTER_INTF}"
            
            proc_set_interface_embeddedsw_configuration_assignment $DEBUG_INTF     "hideDevice" 1
            # We support two IDs for Nios II, need to register both so SystemConsole can bind
            set_module_assignment debug.hostConnection {type jtag id 70:34|110:135}    
        }
    }
}

#------------------------------
# [6.7] Avalon debug port
#------------------------------
proc sub_elaborate_avalon_debug_port_interface {instance} {
    global AV_DEBUG_PORT
    
    set local_debug_level [ proc_get_boolean_parameter debug_enabled ]
    set setting_oci_version [ get_parameter_value setting_oci_version ]

    if { ${local_debug_level} } {
	    set AVALON_DEBUG_PORT_PRESENT [ get_parameter_value setting_avalonDebugPortPresent ]
	    if { $AVALON_DEBUG_PORT_PRESENT && $setting_oci_version == 1 } {
		add_interface           $AV_DEBUG_PORT "avalon"                          "slave"
		set_interface_property  $AV_DEBUG_PORT EXPORT_OF $instance.$AV_DEBUG_PORT
		set_interface_property  $AV_DEBUG_PORT PORT_NAME_MAP    "avalon_debug_port_address      avalon_debug_port_address
		                                                         avalon_debug_port_readdata     avalon_debug_port_readdata
		                                                         avalon_debug_port_write        avalon_debug_port_write
		                                                         avalon_debug_port_writedata     avalon_debug_port_writedata"
	    }
    }
}

#------------------------------
# [6.1] D-Master Interface
#------------------------------
proc sub_elaborate_datam_interface {instance} {
    global D_MASTER_INTF
    
    add_interface           $D_MASTER_INTF   "avalon"            "master"
    set_interface_property  $D_MASTER_INTF EXPORT_OF $instance.$D_MASTER_INTF
    set_interface_property  $D_MASTER_INTF PORT_NAME_MAP    "d_address      d_address
                                                             d_byteenable   d_byteenable
                                                             d_read         d_read
                                                             d_readdata     d_readdata
                                                             d_waitrequest  d_waitrequest
                                                             d_response     d_response
                                                             d_write        d_write
                                                             d_writedata    d_writedata
                                                             d_readdatavalid d_readdatavalid
                                                             d_burstcount d_burstcount
                                                             debug_mem_slave_debugaccess_to_roms debug_mem_slave_debugaccess_to_roms"
    set_interface_assignment $D_MASTER_INTF  "debug.providesServices" "master"
  
    # Create a dummy input and tied off to 0
    # To be supported by Qsys
    #add_interface         "response"   "conduit"              "end"
    #add_interface_port    "response"   "d_response"    "export"          "input"     2
    #add_interface_port    "response"   "d_writeresponsevalid"    "export"          "input"     1
    #add_interface_port    "response"   "d_writeresponserequest"    "export"          "output"     1
}

#------------------------------
# [6.2] I-Master Interface
#------------------------------
proc sub_elaborate_instructionm_interface {instance} {
    global I_MASTER_INTF

    set tmr_enabled [ get_parameter_value tmr_enabled ]
    add_interface           $I_MASTER_INTF   "avalon"            "master"
    if { $tmr_enabled } {
      set_interface_property  $I_MASTER_INTF EXPORT_OF nios_tmr_comparator.$I_MASTER_INTF
    } else {
      set_interface_property  $I_MASTER_INTF EXPORT_OF $instance.$I_MASTER_INTF
    }
    
    set_interface_property  $I_MASTER_INTF PORT_NAME_MAP    "i_address i_address i_read i_read i_readdata i_readdata i_waitrequest i_waitrequest i_response i_response i_readdatavalid i_readdatavalid i_burstcount i_burstcount"
}

proc sub_elaborate_flashm_interface {instance} {
    global FA_MASTER_INTF

    set tmr_enabled [ get_parameter_value tmr_enabled ]
    set fa_cache_linesize [ get_parameter_value fa_cache_linesize ]
    set impl [ get_parameter_value impl ]
    set mmu_enabled [ proc_get_mmu_present ]

    if { $fa_cache_linesize > 0 && $impl == "Fast" && !$mmu_enabled } {
        add_interface           $FA_MASTER_INTF   "avalon"            "master"
        if { $tmr_enabled } {
          set_interface_property  $FA_MASTER_INTF EXPORT_OF nios_tmr_comparator.$FA_MASTER_INTF
        } else {
          set_interface_property  $FA_MASTER_INTF EXPORT_OF $instance.$FA_MASTER_INTF
        }
        set_interface_property  $FA_MASTER_INTF PORT_NAME_MAP    "fa_address fa_address fa_read fa_read fa_readdata fa_readdata fa_waitrequest fa_waitrequest fa_response fa_response fa_readdatavalid fa_readdatavalid fa_burstcount fa_burstcount"
    }    
}

#------------------------------
# [6.8] Custom Instruction
#------------------------------
proc sub_elaborate_custom_instruction {instance} {
        
    global  CI_MASTER_INTF
    
    if { $instance == "nios_a" } {
        set custom_system_info          "customInstSlavesSystemInfo_nios_a"
    } elseif  { $instance == "nios_b" } {
        set custom_system_info          "customInstSlavesSystemInfo_nios_b"
    } elseif  { $instance == "nios_c" } {
        set custom_system_info          "customInstSlavesSystemInfo_nios_c"
    } else {
        set custom_system_info          "customInstSlavesSystemInfo"
    }
    
    set has_any_ci     [ proc_has_any_ci_slave $custom_system_info ]
    set local_impl     [ get_parameter_value impl ]
    
    
   
    if { "$instance" == "nios_a" } {
      set suffix "_a"
    } elseif { "$instance" == "nios_b" } {
      set suffix "_b"
    } elseif { "$instance" == "nios_c" } {
      set suffix "_c"
    } else {
      set suffix ""
    }
    add_interface       $CI_MASTER_INTF${suffix}     "nios_custom_instruction"       "master"
    if { $has_any_ci } {
        if { "$local_impl" == "Fast" } {
          set_interface_property  $CI_MASTER_INTF${suffix} PORT_NAME_MAP "A_ci_multi_done${suffix}       A_ci_multi_done
                                                                          A_ci_multi_result${suffix}     A_ci_multi_result
                                                                          A_ci_multi_a${suffix}          A_ci_multi_a
                                                                          A_ci_multi_b${suffix}          A_ci_multi_b
                                                                          A_ci_multi_c${suffix}          A_ci_multi_c
                                                                          A_ci_multi_clk_en${suffix}     A_ci_multi_clk_en
                                                                          A_ci_multi_clock${suffix}      A_ci_multi_clock
                                                                          A_ci_multi_reset${suffix}      A_ci_multi_reset
                                                                          A_ci_multi_reset_req${suffix}  A_ci_multi_reset_req
                                                                          A_ci_multi_dataa${suffix}      A_ci_multi_dataa
                                                                          A_ci_multi_datab${suffix}      A_ci_multi_datab
                                                                          A_ci_multi_n${suffix}          A_ci_multi_n
                                                                          A_ci_multi_readra${suffix}     A_ci_multi_readra
                                                                          A_ci_multi_readrb${suffix}     A_ci_multi_readrb
                                                                          A_ci_multi_start${suffix}      A_ci_multi_start
                                                                          A_ci_multi_writerc${suffix}    A_ci_multi_writerc
                                                                          E_ci_combo_result${suffix}     E_ci_combo_result
                                                                          E_ci_combo_a${suffix}          E_ci_combo_a
                                                                          E_ci_combo_b${suffix}          E_ci_combo_b
                                                                          E_ci_combo_c${suffix}          E_ci_combo_c
                                                                          E_ci_combo_dataa${suffix}      E_ci_combo_dataa
                                                                          E_ci_combo_datab${suffix}      E_ci_combo_datab
                                                                          E_ci_combo_n${suffix}          E_ci_combo_n
                                                                          E_ci_combo_readra${suffix}     E_ci_combo_readra
                                                                          E_ci_combo_readrb${suffix}     E_ci_combo_readrb
                                                                          E_ci_combo_writerc${suffix}    E_ci_combo_writerc
                                                                          E_ci_combo_estatus${suffix}    E_ci_combo_estatus
                                                                          E_ci_combo_ipending${suffix}   E_ci_combo_ipending"  
            set_interface_property  $CI_MASTER_INTF${suffix} EXPORT_OF $instance.$CI_MASTER_INTF
        } elseif { "$local_impl" == "Small" } {
            set_interface_property  $CI_MASTER_INTF${suffix} PORT_NAME_MAP "M_ci_multi_done${suffix}      M_ci_multi_done
                                                                            M_ci_multi_result${suffix}    M_ci_multi_result
                                                                            M_ci_multi_a${suffix}         M_ci_multi_a
                                                                            M_ci_multi_b${suffix}         M_ci_multi_b
                                                                            M_ci_multi_c${suffix}         M_ci_multi_c
                                                                            M_ci_multi_clk_en${suffix}    M_ci_multi_clk_en
                                                                            M_ci_multi_clock${suffix}     M_ci_multi_clock
                                                                            M_ci_multi_reset${suffix}     M_ci_multi_reset
                                                                            M_ci_multi_reset_req${suffix} M_ci_multi_reset_req
                                                                            M_ci_multi_dataa${suffix}     M_ci_multi_dataa
                                                                            M_ci_multi_datab${suffix}     M_ci_multi_datab
                                                                            M_ci_multi_n${suffix}         M_ci_multi_n
                                                                            M_ci_multi_readra${suffix}    M_ci_multi_readra
                                                                            M_ci_multi_readrb${suffix}    M_ci_multi_readrb
                                                                            M_ci_multi_start${suffix}     M_ci_multi_start
                                                                            M_ci_multi_writerc${suffix}   M_ci_multi_writerc
                                                                            E_ci_combo_result${suffix}  E_ci_combo_result
                                                                            E_ci_combo_a${suffix}       E_ci_combo_a
                                                                            E_ci_combo_b${suffix}       E_ci_combo_b
                                                                            E_ci_combo_c${suffix}       E_ci_combo_c
                                                                            E_ci_combo_dataa${suffix}   E_ci_combo_dataa
                                                                            E_ci_combo_datab${suffix}   E_ci_combo_datab
                                                                            E_ci_combo_n${suffix}       E_ci_combo_n
                                                                            E_ci_combo_readra${suffix}  E_ci_combo_readra
                                                                            E_ci_combo_readrb${suffix}  E_ci_combo_readrb
                                                                            E_ci_combo_writerc${suffix} E_ci_combo_writerc
                                                                            E_ci_combo_estatus${suffix}    E_ci_combo_estatus
                                                                            E_ci_combo_ipending${suffix}   E_ci_combo_ipending"
            set_interface_property  $CI_MASTER_INTF${suffix} EXPORT_OF $instance.$CI_MASTER_INTF
        } elseif { "$local_impl" == "Tiny" } {
            set_interface_property  $CI_MASTER_INTF${suffix} PORT_NAME_MAP "E_ci_multi_done${suffix}      E_ci_multi_done
                                                                            E_ci_multi_clk_en${suffix}    E_ci_multi_clk_en               
                                                                            E_ci_multi_start${suffix}     E_ci_multi_start
                                                                            E_ci_result${suffix}          E_ci_result
                                                                            D_ci_a${suffix}               D_ci_a
                                                                            D_ci_b${suffix}               D_ci_b
                                                                            D_ci_c${suffix}               D_ci_c
                                                                            D_ci_n${suffix}               D_ci_n
                                                                            D_ci_readra${suffix}          D_ci_readra
                                                                            D_ci_readrb${suffix}          D_ci_readrb
                                                                            D_ci_writerc${suffix}         D_ci_writerc
                                                                            E_ci_dataa${suffix}           E_ci_dataa
                                                                            E_ci_datab${suffix}           E_ci_datab
                                                                            E_ci_multi_clock${suffix}     E_ci_multi_clock
                                                                            E_ci_multi_reset${suffix}     E_ci_multi_reset
                                                                            E_ci_multi_reset_req${suffix} E_ci_multi_reset_req
                                                                            W_ci_estatus${suffix}         W_ci_estatus
                                                                            W_ci_ipending${suffix}        W_ci_ipending"
            set_interface_property  $CI_MASTER_INTF${suffix} EXPORT_OF $instance.$CI_MASTER_INTF
        }
    } else {
        # No CI Slave, just put any thing here for termination
        set_interface_property  $CI_MASTER_INTF${suffix} EXPORT_OF $instance.$CI_MASTER_INTF
        set_interface_property  $CI_MASTER_INTF${suffix} PORT_NAME_MAP "dummy_ci_port${suffix} dummy_ci_port"
    }
}

#------------------------------
# [6.10] Conduite Interfaces :-
#           3 : Hidden Option : pc & pc_valid
#           4 : Hidden Option : oci_hbreak_req & test_hbreak_req, test_hbreak_req does not pop up to top level
#           5 : Hidden Option : export large rams (icache, dcache, mmu, oci_ram, trace_ram)
#           6 : Hidden Option : asic enabled
#           7 : Hidden Option : oci export jtag signals
#------------------------------
proc sub_elaborate_conduit_interfaces {} {
    global DEBUG_INTF
    global CPU_RESET
    global PROGRAM_COUNTER
    global HW_BREAKTEST
    global ECC_EVENT

    set impl [ get_parameter_value impl ]
    set tmr_enabled [ get_parameter_value tmr_enabled ]
    set include_debug_debugReqSignals   [ get_parameter_value debug_debugReqSignals ]
    set local_debug_level               [ proc_get_boolean_parameter debug_enabled ]
    set local_cpuresetrequest           [ proc_get_boolean_parameter cpuReset ]
    set local_setting_exportdebuginfo   [ proc_get_boolean_parameter setting_exportdebuginfo ]
    set local_exportvectors             [ proc_get_boolean_parameter setting_exportvectors     ]
    set local_export_large_RAMs         [ proc_get_boolean_parameter setting_export_large_RAMs ]
    set local_asic_enabled              [ proc_get_boolean_parameter setting_asic_enabled ]
    set local_oci_export_jtag_signals   [ proc_get_boolean_parameter setting_oci_export_jtag_signals ]
    set local_HBreakTest                [ proc_get_boolean_parameter setting_HBreakTest ]
    set local_instaddrwidth             [ get_parameter_value instAddrWidth ]
    set local_mmu_enable                [ proc_get_boolean_parameter mmu_enabled ]
    set local_avalon_debug_present      [ proc_get_boolean_parameter setting_avalonDebugPortPresent ]
    set local_debug_offchiptrace        [ get_parameter_value debug_offchiptrace ]

    set local_debug_hwbreakpoint        [ get_parameter_value debug_hwbreakpoint ]
    set local_debug_datatrigger         [ get_parameter_value debug_datatrigger ]
    # Europa always default to 36. (oci_tm_width), where oci_tm_width=dmaster_data_width+4
    set local_oci_tr_width              36

    # single_nios_only - Export output signals from nios_a only
    # instance - can be either nios_tmr_comparator before fanning out to other Nios inputs
    if { $tmr_enabled } {
      set nios_list "nios_a nios_b nios_c"
      set single_nios_only "nios_a"
      set instance "nios_tmr_comparator"
    } else {
      set nios_list "cpu"
      set single_nios_only "cpu"
      set instance "cpu"
    }
    
    set is_tiny [ string match "Tiny" "$impl" ]
    set is_debug_points [ expr { $local_debug_hwbreakpoint > 0 || $local_debug_datatrigger > 0 } ]
    
    if { ${local_debug_level} } {
      if { $include_debug_debugReqSignals || ( $local_debug_offchiptrace && !$is_tiny && $is_debug_points ) } {
          add_interface           debug_conduit   "conduit"                   "end"
          set_interface_property  debug_conduit EXPORT_OF $instance.debug_conduit
          set_interface_property  debug_conduit PORT_NAME_MAP "debug_ack     debug_ack
                                                               debug_req     debug_req
                                                               debug_trigout debug_trigout"
      }
      
      if { $local_debug_offchiptrace && !("$impl" == "Tiny") } {
          add_interface           debug_offchip_trace   "avalon_streaming"    "start"
          set_interface_property  debug_offchip_trace EXPORT_OF $instance.debug_offchip_trace
          set_interface_property  debug_offchip_trace PORT_NAME_MAP "debug_offchip_trace_data debug_offchip_trace_data"
      }
      
      
      
      if { $local_HBreakTest } {
          add_interface       ${HW_BREAKTEST}_conduit        "conduit"                "end"
          set_interface_property  ${HW_BREAKTEST}_conduit EXPORT_OF $single_nios_only.${HW_BREAKTEST}_conduit
          set_interface_property  ${HW_BREAKTEST}_conduit PORT_NAME_MAP "oci_async_hbreak_req oci_async_hbreak_req oci_sync_hbreak_req oci_sync_hbreak_req"
      }
    } 
    
    if { $local_cpuresetrequest } {
        add_interface       ${CPU_RESET}_conduit        "conduit"                   "end"
        set_interface_property  ${CPU_RESET}_conduit EXPORT_OF $instance.${CPU_RESET}_conduit
        set_interface_property  ${CPU_RESET}_conduit PORT_NAME_MAP "cpu_resetrequest cpu_resetrequest cpu_resettaken cpu_resettaken"
    }

    if { $local_setting_exportdebuginfo } {
      foreach nios_i $nios_list {
        if { "$nios_i" == "nios_a" } {
            set suffix "_a"
        } elseif { "$nios_i" == "nios_b" } {
          set suffix "_b"
        } elseif { "$nios_i" == "nios_c" } {
          set suffix "_c"
        } else {
          set suffix ""
        }
        add_interface           ${PROGRAM_COUNTER}${suffix}   "avalon_streaming"    "start"
        set_interface_property  ${PROGRAM_COUNTER}${suffix} EXPORT_OF $nios_i.${PROGRAM_COUNTER}
        set_interface_property  ${PROGRAM_COUNTER}${suffix} PORT_NAME_MAP "pc${suffix}  pc${suffix} pc_valid${suffix} pc_valid${suffix}"
      }
      
      foreach nios_i $nios_list {
        if { "$nios_i" == "nios_a" } {
            set suffix "_a"
        } elseif { "$nios_i" == "nios_b" } {
          set suffix "_b"
        } elseif { "$nios_i" == "nios_c" } {
          set suffix "_c"
        } else {
          set suffix ""
        }
        add_interface           instruction_word${suffix}   "avalon_streaming"    "start"
        set_interface_property  instruction_word${suffix} EXPORT_OF $nios_i.instruction_word
        set_interface_property  instruction_word${suffix} PORT_NAME_MAP "iw${suffix} iw${suffix} iw_valid${suffix} iw_valid${suffix}"
        
        add_interface           exception_bit${suffix}   "avalon_streaming"    "start"
        set_interface_property  exception_bit${suffix} EXPORT_OF $nios_i.exception_bit
        set_interface_property  exception_bit${suffix} PORT_NAME_MAP "exc${suffix} exc${suffix} exc_valid${suffix} exc_valid${suffix}"
      }
    }
    
# fb45389: export large rams parameter
    if { $local_export_large_RAMs } {
        # Export all large RAMs for all the nios in TMR
        foreach nios_i $nios_list {
          sub_elaborate_export_large_rams $nios_i
        }
    }

# Adding support for ASIC flow: adding reset and sld_jtag conduit ports
    set setting_exportHostDebugPort [ get_parameter_value setting_exportHostDebugPort ]
    set setting_oci_version [ get_parameter_value setting_oci_version ]
    
    if { [ expr { $setting_oci_version == 1 && $local_asic_enabled } ] || [ expr { $setting_oci_version == 2 && ${setting_exportHostDebugPort} } ] } {
        if { ${local_debug_level} } {
            add_interface debug_reset reset end
            set_interface_property  debug_reset EXPORT_OF $instance.debug_reset
            set_interface_property  debug_reset PORT_NAME_MAP "debug_reset debug_reset"
        }
    }
    
    if { $local_oci_export_jtag_signals == "1" && $local_avalon_debug_present == "0" && $impl != "Small" } {
        if { ${local_debug_level} } {
            add_interface       sld_jtag      "conduit"      "end"
            set_interface_property  sld_jtag EXPORT_OF $instance.sld_jtag
            set_interface_property  sld_jtag PORT_NAME_MAP "vji_ir_out vji_ir_out
                                                            vji_tdo    vji_tdo
                                                            vji_cdr    vji_cdr
                                                            vji_ir_in  vji_ir_in
                                                            vji_rti    vji_rti
                                                            vji_sdr    vji_sdr
                                                            vji_tck    vji_tck
                                                            vji_tdi    vji_tdi
                                                            vji_udr    vji_udr
                                                            vji_uir    vji_uir"  
        }
    }

    # Adding conduit signals to reset/exception/break vectors
    if { $local_exportvectors } {
        add_interface           reset_vector_conduit        "conduit"                     "end"
        set_interface_property  reset_vector_conduit EXPORT_OF $instance.reset_vector_conduit
        set_interface_property  reset_vector_conduit PORT_NAME_MAP "reset_vector_word_addr reset_vector_word_addr"
        add_interface           exception_vector_conduit    "conduit"                     "end"
        set_interface_property  exception_vector_conduit EXPORT_OF $instance.exception_vector_conduit
        set_interface_property  exception_vector_conduit PORT_NAME_MAP "exception_vector_word_addr exception_vector_word_addr"
        if {$local_mmu_enable} {
            add_interface           fast_tlb_miss_vector_conduit        "conduit"                             "end"
            set_interface_property  fast_tlb_miss_vector_conduit EXPORT_OF $instance.fast_tlb_miss_vector_conduit
            set_interface_property  fast_tlb_miss_vector_conduit PORT_NAME_MAP "fast_tlb_miss_vector_word_addr fast_tlb_miss_vector_word_addr"
        }
    }
    
    set setting_tmr_output_disable [ get_parameter_value setting_tmr_output_disable ]  
    if { $setting_tmr_output_disable } {
        add_interface tmr_output_disable_n reset end
        set_interface_property  tmr_output_disable_n EXPORT_OF $instance.tmr_output_disable_n
        set_interface_property  tmr_output_disable_n PORT_NAME_MAP "tmr_output_disable_n tmr_output_disable_n"
    }
        
    # Adding an ST streaming interface for the ECC event bus
    set local_ecc_present [ proc_get_boolean_parameter setting_ecc_present ]
    set local_impl [ get_parameter_value impl ]
    set ecc_sim_test_ports [ proc_get_boolean_parameter setting_ecc_sim_test_ports ]
    
    if { "$local_impl" == "Fast" } {
        set ecc_sim_test_interface "ic_tag ic_data dc_tag dc_data dc_wb rf dtcm0 dtcm1 dtcm2 dtcm3 tlb"
    } else {
        set ecc_sim_test_interface "rf"
    }
    if { "$local_impl" != "Small" && $local_ecc_present } {
        foreach nios_i $nios_list {
          if { "$nios_i" == "nios_a" } {
            set suffix "_a"
          } elseif { "$nios_i" == "nios_b" } {
            set suffix "_b"
          } elseif { "$nios_i" == "nios_c" } {
            set suffix "_c"
          } else {
            set suffix ""
          }
          add_interface           ${ECC_EVENT}${suffix}   "avalon_streaming"    "start"
          set_interface_property  ${ECC_EVENT}${suffix} EXPORT_OF $nios_i.${ECC_EVENT}
          set_interface_property  ${ECC_EVENT}${suffix} PORT_NAME_MAP "ecc_event_bus ecc_event_bus"
          
          # All ports are always available and are 72 bits for data + parity access
          if { $ecc_sim_test_ports } {
              foreach i $ecc_sim_test_interface {
                  set INTF_NAME "ecc_test_${i}"
                  
                  add_interface           $INTF_NAME${suffix}   "avalon_streaming"          "end"
                  set_interface_property  $INTF_NAME${suffix} EXPORT_OF $nios_i.$INTF_NAME
                  set_interface_property  $INTF_NAME${suffix} PORT_NAME_MAP "ecc_test_${i}${suffix}       ecc_test_${i}${suffix}
                                                                             ecc_test_${i}_valid${suffix} ecc_test_${i}_valid${suffix}
                                                                             ecc_test_${i}_ready${suffix} ecc_test_${i}_ready${suffix}"
              }
          }
        }
    }

}

#------------------------------
# [6.10-5] elaborate conduit interfaces for export large rams
#------------------------------
proc sub_elaborate_export_large_rams {instance} {
    set local_icache_present         [ proc_get_icache_present ]
    set local_mmu_enabled            [ proc_get_mmu_present ]
    set local_instaddrwidth          [ get_parameter_value instAddrWidth ]
    set local_dataaddrwidth          [ get_parameter_value dataAddrWidth ]
    set local_debug_level            [ proc_get_boolean_parameter debug_enabled ]
    set impl                         [ get_parameter_value impl ]
    set local_icache_size            [ get_parameter_value icache_size ]
    set local_dcache_size_derived    [ get_parameter_value dcache_size_derived ]
    set setting_oci_version          [ get_parameter_value setting_oci_version ]
    if { "$instance" == "nios_a" } {
      set suffix "_a"
    } elseif { "$instance" == "nios_b" } {
      set suffix "_b"
    } elseif { "$instance" == "nios_c" } {
      set suffix "_c"
    } else {
      set suffix ""
    }

    if { [expr { $local_icache_present == "1" } && { $impl == "Fast" }] } {
        add_interface       icache_conduit${suffix}        "conduit"                "end"
        set_interface_property  icache_conduit${suffix} EXPORT_OF $instance.icache_conduit
        set_interface_property  icache_conduit${suffix} PORT_NAME_MAP "icache_tag_ram_write_data     icache_tag_ram_write_data
                                                              icache_tag_ram_write_enable   icache_tag_ram_write_enable
                                                              icache_tag_ram_write_address  icache_tag_ram_write_address
                                                              icache_tag_ram_read_clk_en    icache_tag_ram_read_clk_en
                                                              icache_tag_ram_read_address   icache_tag_ram_read_address
                                                              icache_tag_ram_read_data      icache_tag_ram_read_data
                                                              icache_data_ram_write_data    icache_data_ram_write_data
                                                              icache_data_ram_write_enable  icache_data_ram_write_enable
                                                              icache_data_ram_write_address icache_data_ram_write_address
                                                              icache_data_ram_read_clk_en   icache_data_ram_read_clk_en
                                                              icache_data_ram_read_address  icache_data_ram_read_address
                                                              icache_data_ram_read_data     icache_data_ram_read_data"
    }

    if { [expr { $local_dcache_size_derived != "0" } && { $impl == "Fast" }] } {
        add_interface       dcache_conduit${suffix}        "conduit"                "end"
        set_interface_property  dcache_conduit${suffix} EXPORT_OF $instance.dcache_conduit
        set_interface_property  dcache_conduit${suffix} PORT_NAME_MAP "dcache_g4b_tag_ram_write_data     dcache_g4b_tag_ram_write_data
                                                              dcache_g4b_tag_ram_write_enable   dcache_g4b_tag_ram_write_enable
                                                              dcache_g4b_tag_ram_write_address  dcache_g4b_tag_ram_write_address
                                                              dcache_g4b_tag_ram_read_clk_en    dcache_g4b_tag_ram_read_clk_en
                                                              dcache_g4b_tag_ram_read_address   dcache_g4b_tag_ram_read_address
                                                              dcache_g4b_tag_ram_read_data      dcache_g4b_tag_ram_read_data
                                                              dcache_g4b_data_ram_byte_enable   dcache_g4b_data_ram_byte_enable
                                                              dcache_g4b_data_ram_write_data    dcache_g4b_data_ram_write_data
                                                              dcache_g4b_data_ram_write_enable  dcache_g4b_data_ram_write_enable
                                                              dcache_g4b_data_ram_write_address dcache_g4b_data_ram_write_address
                                                              dcache_g4b_data_ram_read_clk_en   dcache_g4b_data_ram_read_clk_en
                                                              dcache_g4b_data_ram_read_address  dcache_g4b_data_ram_read_address
                                                              dcache_g4b_data_ram_read_data     dcache_g4b_data_ram_read_data"
    }                                                                                           
  
    if { $local_debug_level } {
        
        if { $setting_oci_version == 1 } {
            add_interface       oci_ram_conduit${suffix}        "conduit"                "end"
            set_interface_property  oci_ram_conduit${suffix} EXPORT_OF $instance.oci_ram_conduit
            set_interface_property  oci_ram_conduit${suffix} PORT_NAME_MAP "cpu_lpm_oci_ram_sp_address      cpu_lpm_oci_ram_sp_address
                                                                   cpu_lpm_oci_ram_sp_byte_enable  cpu_lpm_oci_ram_sp_byte_enable
                                                                   cpu_lpm_oci_ram_sp_write_data   cpu_lpm_oci_ram_sp_write_data
                                                                   cpu_lpm_oci_ram_sp_write_enable cpu_lpm_oci_ram_sp_write_enable
                                                                   cpu_lpm_oci_ram_sp_read_data    cpu_lpm_oci_ram_sp_read_data"   
        }
        # Disable OCI onchip trace interface if not supported by debug level
        # Only export trace ram when debug level > 2 and not tiny core

        set onchip_trace_support [ proc_get_boolean_parameter debug_onchiptrace ]
        set tiny_or_no_onchip_trace_support [ expr { "$impl" == "Tiny" } || { "$onchip_trace_support" == "0" } ]

        if { !$tiny_or_no_onchip_trace_support } {
            add_interface       trace_ram_conduit${suffix}      "conduit"                "end"
            set_interface_property  trace_ram_conduit${suffix} EXPORT_OF $instance.trace_ram_conduit
            set_interface_property  trace_ram_conduit${suffix} PORT_NAME_MAP "cpu_lpm_trace_ram_sdp_wraddress    cpu_lpm_trace_ram_sdp_wraddress
                                                                     cpu_lpm_trace_ram_sdp_write_data   cpu_lpm_trace_ram_sdp_write_data
                                                                     cpu_lpm_trace_ram_sdp_write_enable cpu_lpm_trace_ram_sdp_write_enable
                                                                     cpu_lpm_trace_ram_sdp_rdaddress    cpu_lpm_trace_ram_sdp_rdaddress
                                                                     cpu_lpm_trace_ram_sdp_read_data    cpu_lpm_trace_ram_sdp_read_data" 
        }
    }
  
    if { [expr { $local_mmu_enabled }] } {
        add_interface       mmu_conduit${suffix}        "conduit"                "end"
        set_interface_property  mmu_conduit${suffix} EXPORT_OF $instance.mmu_conduit
        set_interface_property  mmu_conduit${suffix} PORT_NAME_MAP "tlb_ram_write_enable  tlb_ram_write_enable
                                                           tlb_ram_read_address  tlb_ram_read_address
                                                           tlb_ram_write_address tlb_ram_write_address
                                                           tlb_ram_write_data    tlb_ram_write_data
                                                           tlb_ram_read_data     tlb_ram_read_data"
     }
}

#------------------------------
# [6.0] elaborate callback main routine
#------------------------------
proc elaborate { } {
  
    # safest way is to pass in the correct instance name here so that we do not need to keep calling the tmr function
    set tmr_enabled [ get_parameter_value tmr_enabled ]
    
    if { $tmr_enabled } {
      # set local_instance "nios_tmr_comparator"
      set local_tmr "nios_tmr_comparator"
      # just a short hand for now
    } else {
      set local_tmr "cpu"
    }
    # [6.1]
    sub_elaborate_datam_interface $local_tmr
    # [6.2]
    sub_elaborate_instructionm_interface $local_tmr
    sub_elaborate_flashm_interface $local_tmr
    
    # [6.3]
    sub_elaborate_tcdm_interface $local_tmr
    # [6.4]
    sub_elaborate_tcim_interface $local_tmr
    # Data High Performance Master For Nios II /M
    sub_elaborate_dhpm_interface $local_tmr
    # Instruction High Performance Master For Nios II /M
    sub_elaborate_ihpm_interface $local_tmr
    # [6.5]
    sub_elaborate_interrupt_controller_ports $local_tmr
    # [6.6]
    sub_elaborate_jtag_debug_slave_interface $local_tmr
    # [6.7]
    sub_elaborate_avalon_debug_port_interface $local_tmr
    # [6.8]
    if { $tmr_enabled } {
      foreach i { nios_a nios_b nios_c } {
        sub_elaborate_custom_instruction $i
      }
    } else {
      sub_elaborate_custom_instruction $local_tmr
    }
    # [6.10]
    sub_elaborate_conduit_interfaces
    # [6.11]
    sub_elaborate_hbreak_interrupt_controller_ports
    # [6.12]
    set tmr_enabled [ get_parameter_value tmr_enabled ]
    if { $tmr_enabled } {
      sub_elaborate_tmr_mode
    }
}

#------------------------------------------------------------------------------
# [7] VALIDATION Callback
#------------------------------------------------------------------------------
# Used for searching through the list of slave
proc proc_not_matched_valid { current_slave slave_list} {
    set matched [ expr [ lsearch -regexp $slave_list $current_slave ] == -1 ]
    return $matched
}

#------------------------------
# [7.1] Update parameter Allow Range
#------------------------------
proc sub_validate_update_parameters {} {

    global TCD_PREFIX
    global TCI_PREFIX
    global DHP_PREFIX
    global IHP_PREFIX
        
    set fa_cache_linesize [ get_parameter_value fa_cache_linesize ]
   
    # Slaves.
    # [SH] - validate that it is connected to Data Master
    set reset_slaves                    [ proc_get_address_map_slaves_name instSlaveMapParam ]
    set tcim_num                        [ get_parameter_value icache_numTCIM ]  
    
    foreach i {0 1 2 3} {
        set INTF_TCI_NAME "${TCI_PREFIX}${i}"
        if { $i < $tcim_num } {                
            foreach tcim_name [ proc_get_address_map_slaves_name ${INTF_TCI_NAME}MapParam ] {
                lappend reset_slaves $tcim_name    
            }
        }
    }   

    foreach ihp_name [ proc_get_address_map_slaves_name ${IHP_PREFIX}MapParam ] {
        lappend reset_slaves $ihp_name
    }
    
    if { $fa_cache_linesize > 0 } { 
        foreach fa_slave [ proc_get_address_map_slaves_name faSlaveMapParam ] {
            lappend reset_slaves $fa_slave
        }
    }

    # SPR:348488
    lappend reset_slaves "Absolute"
    lappend reset_slaves "None"

    # Assign to the base reset_slaves
    set exception_slaves $reset_slaves
    set break_slaves $reset_slaves
    set mmu_slaves $reset_slaves
   
    # This is to include the current slave as sudden removal will cause invalid range
    set current_resetSlave                  [ get_parameter_value resetSlave ]
    if { [ proc_not_matched_valid "$current_resetSlave" "$reset_slaves" ] } {
        lappend reset_slaves "$current_resetSlave"
    }

    set current_exceptionSlave              [ get_parameter_value exceptionSlave ]
    if { [ proc_not_matched_valid "$current_exceptionSlave" "$exception_slaves" ] } {
        lappend exception_slaves "$current_exceptionSlave"
    }

    set current_breakSlave                  [ get_parameter_value breakSlave ]
    if { [ proc_not_matched_valid "$current_breakSlave" "$break_slaves" ] } {
        lappend break_slaves "$current_breakSlave"
    }
    
    set current_mmu_TLBMissExcSlave         [ get_parameter_value mmu_TLBMissExcSlave ]
    if { [ proc_not_matched_valid "$current_mmu_TLBMissExcSlave" "$mmu_slaves" ] } {
        lappend mmu_slaves "$current_mmu_TLBMissExcSlave"
    }
    # This is for backward compatible, in previous designs "" is allowed
    # Only allow if this is selected previously. In future design, this will not be allowed
    if { "$current_mmu_TLBMissExcSlave" == "" } {
        lappend mmu_slaves "$current_mmu_TLBMissExcSlave"
    }

    set_parameter_property  resetSlave              "ALLOWED_RANGES" $reset_slaves
    set_parameter_property  exceptionSlave          "ALLOWED_RANGES" $exception_slaves
    set_parameter_property  breakSlave              "ALLOWED_RANGES" $break_slaves
    set_parameter_property  mmu_TLBMissExcSlave     "ALLOWED_RANGES" $mmu_slaves
    
    # RAM Block type
    # For cache tag ram type need to pass in "cache_tag_ram" as argument
    # Else it can be anything
    set supported_ram_type    [proc_get_supported_ram_type others]
    set supported_tagram_type [proc_get_supported_ram_type cache_tag_ram]
    set_parameter_property  dcache_tagramBlockType  "ALLOWED_RANGES" $supported_tagram_type
    set_parameter_property  icache_tagramBlockType  "ALLOWED_RANGES" $supported_tagram_type
    set_parameter_property  dcache_ramBlockType     "ALLOWED_RANGES" $supported_ram_type
    set_parameter_property  icache_ramBlockType     "ALLOWED_RANGES" $supported_ram_type
    set_parameter_property  regfile_ramBlockType    "ALLOWED_RANGES" $supported_ram_type
    set_parameter_property  ocimem_ramBlockType     "ALLOWED_RANGES" $supported_ram_type
    set_parameter_property  mmu_ramBlockType        "ALLOWED_RANGES" $supported_ram_type
    set_parameter_property  bht_ramBlockType        "ALLOWED_RANGES" $supported_ram_type

    set show_unpublished_settings   [ proc_get_boolean_parameter setting_showUnpublishedSettings ]
    # Setting the allowed range for impl
    if { $show_unpublished_settings } {
        set_parameter_property  impl        "ALLOWED_RANGES" { "Tiny:Nios II/e" "Small:Nios II/m"  "Fast:Nios II/f" }       
    } else {
        set_parameter_property  impl        "ALLOWED_RANGES" { "Tiny:Nios II/e" "Fast:Nios II/f" }
    }
    #[SH] Multiply Type
    
    # allowed range for the hwbreakpoint and data trigger support only for OCI version 2
    set setting_oci_version [ get_parameter_value setting_oci_version ]
    if { $setting_oci_version == 2 } {
        set_parameter_property  debug_hwbreakpoint "ALLOWED_RANGES" { "0:0"  "2:2"  "4:4"  "6:6"  "8:8" }
        set_parameter_property  debug_datatrigger  "ALLOWED_RANGES" { "0:0"  "2:2"  "4:4"  "6:6"  "8:8" }
    } else {
        set_parameter_property  debug_hwbreakpoint "ALLOWED_RANGES" { "0:0"  "2:2"  "4:4" }
        set_parameter_property  debug_datatrigger  "ALLOWED_RANGES" { "0:0"  "2:2"  "4:4" }
        
    }
   
    proc_set_enable_visible_parameter mul_32_impl "enable"
    proc_set_enable_visible_parameter mul_64_impl "enable"
    proc_set_enable_visible_parameter shift_rot_impl "enable"
    proc_set_enable_visible_parameter dividerType "enable"
    proc_set_enable_visible_parameter mul_shift_choice "enable"

    set impl [ get_parameter_value impl ]
    # Hardware multiply and divider can't be used for Tiny
    # Selectable for Fast core only
    if { "$impl" != "Fast" } {
        proc_set_enable_visible_parameter mul_32_impl "disable"
        proc_set_enable_visible_parameter mul_64_impl "disable"
        proc_set_enable_visible_parameter shift_rot_impl "disable"
        proc_set_enable_visible_parameter dividerType "disable"
        proc_set_enable_visible_parameter mul_shift_choice "disable"
    }
    
    set mul_shift_choice [ get_parameter_value mul_shift_choice ]
    set dividerType      [ get_parameter_value dividerType ]
    if { "$impl" != "Fast" } {
            set div_perf "Low"
            set div_res  "None (Software Implementation)" 
            if { "$impl" == "Small" } {
                set shift_rot_perf "1 cycle"
                set shift_rot_res  "Logic elements (pipelined)"
                set_parameter_value shifterType  "fast_le_shift"
            } else {
                set shift_rot_perf "7-38 cycles"
                set shift_rot_res  "Logic elements"
                set_parameter_value shifterType  "medium_le_shift"
            }
            set mul_32_perf "Low"
            set mul_32_res  "None (Software Implementation)"
            set mul_64_perf "Low"
            set mul_64_res  "None (Software Implementation)"
            set_parameter_value multiplierType  "no_mul"
            set_parameter_value stratix_dspblock_shift_mul 0
            
    } else {
    if { $mul_shift_choice == 0 } {
        
        proc_set_enable_visible_parameter mul_32_impl "disable"
        proc_set_enable_visible_parameter mul_64_impl "disable"
        proc_set_enable_visible_parameter shift_rot_impl "disable"
        
        if { [ proc_mul_support_32_bit_multiplication ] } {
            set mul_32_perf "1 cycle"
            set mul_32_res  "1 32-bit multiplier"
            set mul_32_inst "All Multiply"
            set mul_64_perf "1 cycle"
            set mul_64_res  "No extra (re-uses 32-bit multiplier)"
            set mul_64_inst "All Multiply Extended"
            set shift_rot_perf "1 cycle"
            set shift_rot_res "No extra (re-uses 32-bit multiplier)"
            set_parameter_value multiplierType  "mul_fast64"
            set_parameter_value shifterType     "fast_le_shift"
            set_parameter_value stratix_dspblock_shift_mul 1
        } else {
            set mul_32_perf "1 cycle"
            set mul_32_res  "3 16-bit multipliers"
            set mul_64_perf "Low"
            set mul_64_res  "None (Software Implementation)"
            set shift_rot_perf "1 cycle"
            set shift_rot_res "Logic elements (pipelined)"
            set_parameter_value multiplierType  "mul_fast32"
            set_parameter_value shifterType     "fast_le_shift"
            set_parameter_value stratix_dspblock_shift_mul 0
        }
    } else {
        # Manual Case: tricky
        set mul_32_impl    [ get_parameter_value mul_32_impl    ]
        set mul_64_impl    [ get_parameter_value mul_64_impl    ]
        set shift_rot_impl [ get_parameter_value shift_rot_impl ]
        
        if { $mul_32_impl == 0 } {
            set mul_32_perf "Low"
            set mul_32_res  "None (Software Implementation)"
            set mul_64_perf "Low"
            set mul_64_res  "None (Software Implementation)"
            set_parameter_value multiplierType  "no_mul"
            set_parameter_value stratix_dspblock_shift_mul 0
        } elseif { $mul_32_impl == 1 } {
            set mul_32_perf "11 cycles"
            set mul_32_res  "Logic elements"
            set mul_64_perf "Low"
            set mul_64_res  "None (Software Implementation)"
            set_parameter_value multiplierType  "mul_slow32"
            set_parameter_value stratix_dspblock_shift_mul 0
        } elseif { $mul_32_impl == 2 } {
            set mul_32_perf "1 cycle"
            set mul_32_res  "3 16-bit multipliers"
            set mul_64_perf "Low"
            set mul_64_res  "None (Software Implementation)"
            set_parameter_value multiplierType  "mul_fast32"
            set_parameter_value stratix_dspblock_shift_mul 0
        } else {
            set mul_32_perf "1 cycle"
            set mul_32_res  "1 32-bit multiplier"
            set mul_64_perf "1 cycle"
            set mul_64_res  "No extra (re-uses 32-bit multiplier)"
            set shift_rot_perf "1 cycle"
            set shift_rot_res  "No extra (re-uses 32-bit multiplier)"
            set_parameter_value multiplierType  "mul_fast64"
            set_parameter_value shifterType  "fast_le_shift"
            set_parameter_value stratix_dspblock_shift_mul 1
            proc_set_enable_visible_parameter mul_64_impl "disable"
            proc_set_enable_visible_parameter shift_rot_impl "disable"
            
            if { ![ proc_mul_support_32_bit_multiplication ] } {
                send_message warning "Current device family selected does not support 32-bit hard multiplier. This may reduce system Fmax"
            }
        }

        # consider 64-bit options and shift/rotate only if it is not using the 1 32-bit multiplier        
        if { $mul_32_impl != 3 } {
            if { $mul_64_impl == 1 && $mul_32_impl == 2 } {
                set mul_64_perf "2 cycles"
                set mul_64_res  "1 extra 16-bit multiplier"
                set_parameter_value multiplierType  "mul_fast64"
            } elseif { $mul_64_impl == 1 } { 
                send_message error "Multiply instruction implementation needs to be configured to be 3 16-bit multipliers"
            }
        
            if { $shift_rot_impl == 0 } {
                set shift_rot_perf "2-11 cycles"
                set shift_rot_res  "Logic elements (non-pipelined)"
                set_parameter_value shifterType  "medium_le_shift"
            } else {
                set shift_rot_perf "1 cycle"
                set shift_rot_res  "Logic elements (pipelined)"
                set_parameter_value shifterType  "fast_le_shift"
            }
        
        }
        
        
    }
    
    if { $dividerType == "no_div" } {
        set div_perf "Low"
        set div_res  "None (Software Implementation)"
    } else {
        set div_perf "35 cycles"
        set div_res  "Logic elements"
    }
    }

  set NIOSII_TABLE "<html><table border=\"1\" width=\"100%\">
  <tr bgcolor=\"#C9DBF3\">
    <td>
      Operation
    </td>
    <td>
      Performance
    </font></td>
    <td>
      Resources
    </font></td>
    <td>
      Instructions
    </font></td>
  </tr>
  <tr bgcolor=\"#FFFFFF\">
    <td valign=\"top\">
      Multiply
    </td>
    <td valign=\"top\" width=\"70\">
      ${mul_32_perf}
    </td>
    <td valign=\"top\" width=\"220\">
      ${mul_32_res}
    </td>
    <td valign=\"top\" width=\"170\">
      MUL, MULI
    </td>
  </tr>
  <tr bgcolor=\"#FFFFFF\">
    <td valign=\"top\">
      Multiply Extended
    </td>
    <td valign=\"top\" width=\"70\">
      ${mul_64_perf}
    </td>
    <td valign=\"top\" width=\"220\">
      ${mul_64_res}
    </td>
    <td valign=\"top\" width=\"170\">
      MULXSS, MULXSU, MULXUU
    </td>
  </tr>
  <tr bgcolor=\"#FFFFFF\">
    <td valign=\"top\">
      Shift/rotate
    </td>
    <td valign=\"top\" width=\"70\">
      ${shift_rot_perf}
    </td>
    <td valign=\"top\" width=\"220\">
      ${shift_rot_res}
    </td>
    <td valign=\"top\" width=\"170\">
      ROL, ROLI, ROR, SLL, SLLI, SRA, SRAI, SRL, SRLI
    </td>
  </tr>
  <tr bgcolor=\"#FFFFFF\">
    <td valign=\"top\">
      Divide
    </td>
    <td valign=\"top\" width=\"70\">
      ${div_perf}
    </td>
    <td valign=\"top\" width=\"220\">
      ${div_res}
    </td>
    <td valign=\"top\" width=\"170\">
      DIV, DIVU
    </td>
  </tr>
       </table></html>"
    set_display_item_property arithmetictable TEXT $NIOSII_TABLE 
}

#------------------------------
# [7.2] To disable invalid Parameter
#------------------------------
proc sub_validate_update_parameterization_gui {} {
    set impl                                        [ get_parameter_value impl ]
    set device_family_name                          [ get_parameter_value deviceFamilyName ]
    set mmu_enabled                                 [ proc_get_mmu_present ]
    set mpu_enabled                                 [ proc_get_mpu_present ]
    set mmu_autoAssignTlbPtrSz                      [ proc_get_boolean_parameter mmu_autoAssignTlbPtrSz ]

    set icache_size                                 [ get_parameter_value icache_size ]
    set dcache_size                                 [ get_parameter_value dcache_size ]

    set setting_preciseIllegalMemAccessException    [ proc_get_boolean_parameter setting_preciseIllegalMemAccessException ]

    set debug_assignJtagInstanceID                  [ proc_get_boolean_parameter debug_assignJtagInstanceID ]
    set debug_level                                 [ proc_get_boolean_parameter debug_enabled ]
    set branch_prediction_type                      [ get_parameter_value setting_branchpredictiontype ]
    set local_exportvectors                         [ proc_get_boolean_parameter setting_exportvectors ]

    # Set all parameters to visible initially and disable accordingly
    proc_set_enable_visible_parameter mmu_enabled "enable"
    proc_set_enable_visible_parameter mmu_TLBMissExcSlave "enable"
    proc_set_enable_visible_parameter mmu_TLBMissExcOffset "enable"
    proc_set_enable_visible_parameter mmu_tlbNumWays "enable"
    proc_set_enable_visible_parameter mmu_tlbPtrSz "enable"
    proc_set_enable_visible_parameter mmu_processIDNumBits "enable"
    proc_set_enable_visible_parameter mmu_udtlbNumEntries "enable"
    proc_set_enable_visible_parameter mmu_uitlbNumEntries "enable"
    proc_set_enable_visible_parameter mmu_autoAssignTlbPtrSz "enable"
    proc_set_enable_visible_parameter mmu_ramBlockType "enable"

    proc_set_enable_visible_parameter mpu_enabled "enable"
    proc_set_enable_visible_parameter mpu_numOfDataRegion "enable"
    proc_set_enable_visible_parameter mpu_numOfInstRegion "enable"
    proc_set_enable_visible_parameter mpu_minDataRegionSize "enable"
    proc_set_enable_visible_parameter mpu_minInstRegionSize "enable"
    proc_set_enable_visible_parameter mpu_useLimit "enable"

    proc_set_enable_visible_parameter cpuArchRev "enable"
    proc_set_enable_visible_parameter cdx_enabled "enable"

    proc_set_enable_visible_parameter icache_size "enable"
    proc_set_enable_visible_parameter icache_tagramBlockType "enable"
    proc_set_enable_visible_parameter icache_ramBlockType "enable"
    proc_set_enable_visible_parameter icache_burstType "enable"
    proc_set_enable_visible_parameter icache_numTCIM "enable"
    proc_set_enable_visible_parameter fa_cache_line "enable"
    proc_set_enable_visible_parameter fa_cache_linesize "enable"
        
    proc_set_enable_visible_parameter dcache_size "enable"
    proc_set_enable_visible_parameter dcache_tagramBlockType "enable"
    proc_set_enable_visible_parameter dcache_ramBlockType "enable"
    proc_set_enable_visible_parameter dcache_bursts "enable"
    proc_set_enable_visible_parameter dcache_numTCDM "enable"
    proc_set_enable_visible_parameter dcache_victim_buf_impl "enable"  

    proc_set_enable_visible_parameter setting_ecc_present "enable"
    proc_set_enable_visible_parameter setting_ic_ecc_present "enable"
    proc_set_enable_visible_parameter setting_rf_ecc_present "enable"
    proc_set_enable_visible_parameter setting_mmu_ecc_present "enable"
    proc_set_enable_visible_parameter setting_dc_ecc_present "enable"
    proc_set_enable_visible_parameter setting_itcm_ecc_present "enable"
    proc_set_enable_visible_parameter setting_dtcm_ecc_present "enable"
    proc_set_enable_visible_parameter setting_ecc_sim_test_ports "disable"

    proc_set_enable_visible_parameter setting_interruptControllerType "enable"
    proc_set_enable_visible_parameter setting_shadowRegisterSets "enable"
    proc_set_enable_visible_parameter setting_preciseIllegalMemAccessException "enable"
    proc_set_enable_visible_parameter setting_exportHostDebugPort "disable"
    proc_set_enable_visible_parameter setting_fast_register_read "disable"
    proc_set_enable_visible_parameter setting_avalonDebugPortPresent "enable"
    proc_set_enable_visible_parameter setting_oci_export_jtag_signals "enable"
    proc_set_enable_visible_parameter setting_allow_break_inst "disable"
    
    proc_set_enable_visible_parameter cpuID "enable"

    proc_set_enable_visible_parameter cdx_enabled "disable"
    proc_set_enable_visible_parameter mpx_enabled "disable"

    proc_set_enable_visible_parameter setting_branchpredictiontype "enable"
    proc_set_enable_visible_parameter setting_bhtPtrSz "enable"
    proc_set_enable_visible_parameter bht_ramBlockType "enable"
    
    # trace file name
    proc_set_enable_visible_parameter tracefilename "disable"   
    set setting_activateTrace [ get_parameter_value setting_activateTrace ]
    if {$setting_activateTrace} {
        proc_set_enable_visible_parameter tracefilename "enable"
    }

    proc_set_enable_visible_parameter setting_exportdebuginfo "enable"     
    # Set to always not visible and only visible when
    # Nodebug and allowBreakinstr is enabled
    set_parameter_property  breakSlave   "VISIBLE" 0
    set_parameter_property  breakOffset   "VISIBLE" 0
    set_parameter_property  breakAbsoluteAddr   "VISIBLE" 0

    proc_set_enable_visible_parameter exceptionSlave "enable"
    proc_set_enable_visible_parameter resetSlave "enable"
    proc_set_enable_visible_parameter exceptionOffset "enable"
    proc_set_enable_visible_parameter resetOffset "enable"

    proc_set_enable_visible_parameter debug_OCIOnchipTrace "enable"
    proc_set_enable_visible_parameter debug_debugReqSignals "enable"
    proc_set_enable_visible_parameter debug_enabled "enable"
    proc_set_enable_visible_parameter debug_assignJtagInstanceID "enable"
    proc_set_enable_visible_parameter debug_jtagInstanceID "enable"
    proc_set_enable_visible_parameter debug_hwbreakpoint "enable"
    proc_set_enable_visible_parameter debug_datatrigger "enable"
    proc_set_enable_visible_parameter debug_traceType "enable"
    proc_set_enable_visible_parameter debug_traceStorage "enable"
    proc_set_enable_visible_parameter ocimem_ramBlockType "enable"
    proc_set_enable_visible_parameter ocimem_ramInit "enable"

    proc_set_enable_visible_parameter io_regionbase "enable"
    proc_set_enable_visible_parameter io_regionsize "enable"
    proc_set_enable_visible_parameter setting_support31bitdcachebypass "enable"

    proc_set_enable_visible_parameter setting_asic_third_party_synthesis "disable"
    proc_set_enable_visible_parameter setting_asic_add_scan_mode_input "disable"
    proc_set_enable_visible_parameter setting_asic_synopsys_translate_on_off "disable"

    proc_set_enable_visible_parameter setting_disable_tmr_inj "disable"
    
    set tmr_enabled [ get_parameter_value tmr_enabled ]
    if { $tmr_enabled } {
        proc_set_enable_visible_parameter setting_disable_tmr_inj "enable"
    }
    
    # MMU and MPU can only be used if Fast core is selected
    if { "$impl" != "Fast" } {
        proc_set_enable_visible_parameter mmu_enabled "disable"
    }
    
    if { "$impl" == "Tiny" } {
        proc_set_enable_visible_parameter mpu_enabled "disable"
    }

    # Disable MMU if MPU is enabled
    if { "$mpu_enabled" == "1" } {
        proc_set_enable_visible_parameter mmu_enabled "disable"
    }

    # Update tlb ptr sz if needed
    if { "$mmu_autoAssignTlbPtrSz" == "1" } {
        proc_set_enable_visible_parameter mmu_tlbPtrSz "disable"
    }

    # Disable TLB parameters unless MMU is enabled
    if { [ expr { "$impl" != "Fast" } || { "$mmu_enabled" != "1" } ] } {
        proc_set_enable_visible_parameter mmu_TLBMissExcSlave "disable"
        proc_set_enable_visible_parameter mmu_TLBMissExcOffset "disable"

        # If MMU is not enabled, all related parameters are disable
        proc_set_enable_visible_parameter mmu_tlbNumWays "disable"
        proc_set_enable_visible_parameter mmu_tlbPtrSz "disable"
        proc_set_enable_visible_parameter mmu_processIDNumBits "disable"
        proc_set_enable_visible_parameter mmu_udtlbNumEntries "disable"
        proc_set_enable_visible_parameter mmu_uitlbNumEntries "disable"
        proc_set_enable_visible_parameter mmu_autoAssignTlbPtrSz "disable"
        proc_set_enable_visible_parameter mmu_ramBlockType "disable"
    }

    # Disable MPU if MMU is enabled
    if { "$mmu_enabled" == "1" } {
        proc_set_enable_visible_parameter mpu_enabled "disable"
    }

    # If MPU is not enabled, all related parameters are disable
    if { "$mpu_enabled" == "0" || "[ get_parameter_property mpu_enabled "ENABLED" ]" == "0" } {
        proc_set_enable_visible_parameter mpu_numOfDataRegion "disable"
        proc_set_enable_visible_parameter mpu_numOfInstRegion "disable"
        proc_set_enable_visible_parameter mpu_minDataRegionSize "disable"
        proc_set_enable_visible_parameter mpu_minInstRegionSize "disable"
        proc_set_enable_visible_parameter mpu_useLimit "disable"
    }

    # Enhanced Interrupt Features can only be used with f core
    if { "$impl" == "Tiny" } {
        proc_set_enable_visible_parameter setting_interruptControllerType "disable"
        proc_set_enable_visible_parameter setting_shadowRegisterSets "disable"
    }

    # Precise exceptions can only be used if Fast core is selected
    if { "$impl" == "Tiny" } {
        proc_set_enable_visible_parameter setting_preciseIllegalMemAccessException "disable"
    }

    # Disable illegal memory access and the imprecise version if MMU is enabled
    if { "$mmu_enabled" == "1" } {
        proc_set_enable_visible_parameter setting_preciseIllegalMemAccessException "disable"
    }

    # Disable illegal memory access and the imprecise version if MPU is enabled
    if { "$mpu_enabled" == "1" } {
        proc_set_enable_visible_parameter setting_preciseIllegalMemAccessException "disable"
    }

    if { "$mmu_enabled" == "1" || "$impl" != "Fast"} {
        proc_set_enable_visible_parameter io_regionbase "disable"
        proc_set_enable_visible_parameter io_regionsize "disable"
        proc_set_enable_visible_parameter setting_support31bitdcachebypass "disable"
    }

    set io_regionsize [ get_parameter_value io_regionsize ]
    if {  $io_regionsize == 0 } {
        proc_set_enable_visible_parameter io_regionbase "disable"
    }

    # Branch Prediction only works with Fast cores
    if { "$impl" != "Fast" } {
        proc_set_enable_visible_parameter setting_branchpredictiontype "disable"
        proc_set_enable_visible_parameter setting_bhtPtrSz "disable"
        proc_set_enable_visible_parameter bht_ramBlockType "disable"
    }

    # Enable Export host debug port when in M-core
    # disable avalon debug port and jtag signals for M-core
    set setting_oci_version [ get_parameter_value setting_oci_version ]
    if { $setting_oci_version == 2 } {
        proc_set_enable_visible_parameter setting_exportHostDebugPort "enable"
        if { "$impl" == "Small" } {
        	# when small disable fast_register_read option because it is always on
        	proc_set_enable_visible_parameter setting_fast_register_read "disable"
        } else {
        	proc_set_enable_visible_parameter setting_fast_register_read "enable"
        }
        proc_set_enable_visible_parameter setting_avalonDebugPortPresent "disable"
        proc_set_enable_visible_parameter setting_oci_export_jtag_signals "disable"
        proc_set_enable_visible_parameter debug_assignJtagInstanceID "disable"
        proc_set_enable_visible_parameter setting_avalonDebugPortPresent "disable"
        proc_set_enable_visible_parameter ocimem_ramBlockType "disable"
        proc_set_enable_visible_parameter ocimem_ramInit "disable"
    }
            
    # Gray out BHT prediction entries when Static is chosen
    if { "$branch_prediction_type" == "Static" } {
        proc_set_enable_visible_parameter setting_bhtPtrSz "disable"
        proc_set_enable_visible_parameter bht_ramBlockType "disable"
    }

    # Don't allow user to assign jtag instance id if no debug core present
    # Avalon Debug Port present only available when debug level is at least 1
    # Only allow RAM Block modification for when debugger at least 1
    # allow break inst only when Nodebug
    if { !$debug_level || "$impl" == "Tiny" } {
        proc_set_enable_visible_parameter debug_assignJtagInstanceID "disable"
        proc_set_enable_visible_parameter setting_avalonDebugPortPresent "disable"
        proc_set_enable_visible_parameter debug_hwbreakpoint "disable"
        proc_set_enable_visible_parameter debug_datatrigger "disable"
        proc_set_enable_visible_parameter debug_traceType "disable"
        proc_set_enable_visible_parameter debug_traceStorage "disable"
        proc_set_enable_visible_parameter debug_OCIOnchipTrace "disable"
        proc_set_enable_visible_parameter ocimem_ramBlockType "disable"
        proc_set_enable_visible_parameter ocimem_ramInit "disable"
        proc_set_enable_visible_parameter debug_debugReqSignals "disable"
    }

    # Jtag instance ID value is only valid if user want to assign it and they are allowed to assign it
    set debug_assignJtagInstanceID_enabled [ expr { "$debug_assignJtagInstanceID" == "1" } && { "[ get_parameter_property debug_assignJtagInstanceID "ENABLED" ]" == "1" } ]
    if { "$debug_assignJtagInstanceID_enabled" == "0" } {
        proc_set_enable_visible_parameter debug_jtagInstanceID "disable"
    }

    set setting_breakslaveoveride [ proc_get_boolean_parameter setting_breakslaveoveride ]
    set cpuArchRev [ get_parameter_value cpuArchRev ]
    # visible when:
    # OCI version 1 (breakslave always required)
    # no debug or breakslave override set
    if { ((!$debug_level && $cpuArchRev == 1) || $setting_breakslaveoveride) && ($setting_oci_version == 1) } {
        set_parameter_property  breakSlave          "VISIBLE" 1
        set_parameter_property  breakOffset         "VISIBLE" 1
        set_parameter_property  breakAbsoluteAddr   "VISIBLE" 1
    }

    if { !$debug_level } {
        proc_set_enable_visible_parameter setting_allow_break_inst "enable"
    }
    
    # Only make the break vectors to be visible for internal testing
    set allow_break_inst [proc_get_boolean_parameter setting_allow_break_inst]
    if { !$debug_level && $allow_break_inst && ($setting_oci_version == 1) } {
        set_parameter_property  breakSlave          "VISIBLE" 1
        set_parameter_property  breakOffset         "VISIBLE" 1
        set_parameter_property  breakAbsoluteAddr   "VISIBLE" 1
    }

    # If the implementation type is Tiny, we don't have an I-Cache
    if { "$impl" != "Fast" } {
        proc_set_enable_visible_parameter icache_size "disable"
        proc_set_enable_visible_parameter icache_tagramBlockType "disable"
        proc_set_enable_visible_parameter icache_ramBlockType "disable"
        proc_set_enable_visible_parameter icache_burstType "disable"
        proc_set_enable_visible_parameter fa_cache_line "disable"
        proc_set_enable_visible_parameter fa_cache_linesize "disable"
    }
    
    set fa_cache_linesize [ get_parameter_value fa_cache_linesize ]
    if { $fa_cache_linesize == 0 } {
        proc_set_enable_visible_parameter fa_cache_line "disable"
    }

    # Disable Fa_cache when it is MMU enabled
    if { "$mmu_enabled" == "1" } {
        proc_set_enable_visible_parameter fa_cache_line "disable"
        proc_set_enable_visible_parameter fa_cache_linesize "disable"
    }

    # If the I-cache size is set to 0, only TCIM can be set (and must be set)
    if { "$icache_size" == "0" } {
        proc_set_enable_visible_parameter icache_tagramBlockType "disable"
        proc_set_enable_visible_parameter icache_ramBlockType "disable"
        proc_set_enable_visible_parameter icache_burstType "disable"
    }

    # If the D-cache size is set to 0, only TCIM can be set
    # D-cache victim is enabled when line size is not 4 and cache is present
    if { "$dcache_size" == "0" } {
        proc_set_enable_visible_parameter dcache_tagramBlockType "disable"
        proc_set_enable_visible_parameter dcache_ramBlockType "disable"
        proc_set_enable_visible_parameter dcache_bursts "disable"
        proc_set_enable_visible_parameter dcache_victim_buf_impl "disable"
        proc_set_enable_visible_parameter setting_support31bitdcachebypass "disable"
        proc_set_enable_visible_parameter io_regionbase "disable"
        proc_set_enable_visible_parameter io_regionsize "disable"
    }

    # Support TCIM/DTCM for Fast/Small Nios
    if { "$impl" == "Tiny" } {
        proc_set_enable_visible_parameter icache_numTCIM "disable"
        proc_set_enable_visible_parameter dcache_numTCDM "disable"
    }
        
    # Lastly, if the implementation is not Fast, none of these settings are valid
    # since data caches are only used for Nios2/F cores.
    if { "$impl" != "Fast" } {
        proc_set_enable_visible_parameter dcache_bursts "disable"
        proc_set_enable_visible_parameter dcache_tagramBlockType "disable"
        proc_set_enable_visible_parameter dcache_ramBlockType "disable"
        proc_set_enable_visible_parameter dcache_size "disable"
        proc_set_enable_visible_parameter dcache_victim_buf_impl "disable"
        proc_set_enable_visible_parameter setting_support31bitdcachebypass "disable"
        proc_set_enable_visible_parameter io_regionbase "disable"
        proc_set_enable_visible_parameter io_regionsize "disable"
    }

    # When debugTrace is none, disable all the traceStrorage, Onchip Trace
    set debug_traceType [ get_parameter_value debug_traceType ]
    set debug_traceStorage [ get_parameter_value debug_traceStorage ]
    if { $debug_traceType == "none" } {
        proc_set_enable_visible_parameter debug_traceStorage   "disable"
        proc_set_enable_visible_parameter debug_OCIOnchipTrace "disable"
    }

    # ECC is only for Fast Core
    if { "$impl" != "Fast" } {
        proc_set_enable_visible_parameter setting_ic_ecc_present "disable"
        proc_set_enable_visible_parameter setting_mmu_ecc_present "disable"
        proc_set_enable_visible_parameter setting_dc_ecc_present "disable"
        proc_set_enable_visible_parameter setting_itcm_ecc_present "disable"
        proc_set_enable_visible_parameter setting_dtcm_ecc_present "disable"
    }
    
    set ecc_present [ proc_get_boolean_parameter setting_ecc_present ]

    # Only when ECC is present and Fast core, this is sim reg is enabled
    if { "$impl" != "Small" && $ecc_present } {
        proc_set_enable_visible_parameter setting_ecc_sim_test_ports "enable"
    }    
    
    if { $local_exportvectors } {       
        proc_set_enable_visible_parameter exceptionOffset "disable"
        proc_set_enable_visible_parameter resetOffset "disable"
        proc_set_enable_visible_parameter exceptionSlave "disable"
        proc_set_enable_visible_parameter resetSlave "disable"
    }
    
    # Features available to R2 architecture only
    set cpuArchRev [ get_parameter_value cpuArchRev ]
    if { $cpuArchRev == 2 && "$impl" == "Small"  } {
        proc_set_enable_visible_parameter cdx_enabled "enable"
        proc_set_enable_visible_parameter mpx_enabled "enable"
    }
 
    proc_set_enable_visible_parameter regfile_ramBlockType "enable"

    set local_asic_enabled [ proc_get_boolean_parameter setting_asic_enabled ]
    if { "$impl" == "Small" && $local_asic_enabled } {
        proc_set_enable_visible_parameter regfile_ramBlockType "disable"
    }
    
    # Disable asic enabled parameters
    if { $local_asic_enabled } {
        proc_set_enable_visible_parameter setting_asic_third_party_synthesis "enable"
        proc_set_enable_visible_parameter setting_asic_add_scan_mode_input "enable"
        proc_set_enable_visible_parameter setting_asic_synopsys_translate_on_off "enable"
    }
    
    # Enable setting for Address Map
    set master_addr_map [ get_parameter_value master_addr_map ]
    
    proc_set_enable_visible_parameter  instruction_master_paddr_base                     "disable"         
    proc_set_enable_visible_parameter  instruction_master_paddr_size                     "disable"
    proc_set_enable_visible_parameter  flash_instruction_master_paddr_base               "disable"
    proc_set_enable_visible_parameter  flash_instruction_master_paddr_size               "disable"
    proc_set_enable_visible_parameter  data_master_paddr_base                            "disable"
    proc_set_enable_visible_parameter  data_master_paddr_size                            "disable"
    proc_set_enable_visible_parameter  tightly_coupled_instruction_master_0_paddr_base   "disable"
    proc_set_enable_visible_parameter  tightly_coupled_instruction_master_0_paddr_size   "disable"
    proc_set_enable_visible_parameter  tightly_coupled_instruction_master_1_paddr_base   "disable"
    proc_set_enable_visible_parameter  tightly_coupled_instruction_master_1_paddr_size   "disable"
    proc_set_enable_visible_parameter  tightly_coupled_instruction_master_2_paddr_base   "disable"
    proc_set_enable_visible_parameter  tightly_coupled_instruction_master_2_paddr_size   "disable"
    proc_set_enable_visible_parameter  tightly_coupled_instruction_master_3_paddr_base   "disable"
    proc_set_enable_visible_parameter  tightly_coupled_instruction_master_3_paddr_size   "disable"
    proc_set_enable_visible_parameter  tightly_coupled_data_master_0_paddr_base          "disable"
    proc_set_enable_visible_parameter  tightly_coupled_data_master_0_paddr_size          "disable"
    proc_set_enable_visible_parameter  tightly_coupled_data_master_1_paddr_base          "disable"
    proc_set_enable_visible_parameter  tightly_coupled_data_master_1_paddr_size          "disable"
    proc_set_enable_visible_parameter  tightly_coupled_data_master_2_paddr_base          "disable"
    proc_set_enable_visible_parameter  tightly_coupled_data_master_2_paddr_size          "disable"
    proc_set_enable_visible_parameter  tightly_coupled_data_master_3_paddr_base          "disable"
    proc_set_enable_visible_parameter  tightly_coupled_data_master_3_paddr_size          "disable"
    proc_set_enable_visible_parameter  instruction_master_high_performance_paddr_base    "disable"
    proc_set_enable_visible_parameter  instruction_master_high_performance_paddr_size    "disable"
    proc_set_enable_visible_parameter  data_master_high_performance_paddr_base           "disable"
    proc_set_enable_visible_parameter  data_master_high_performance_paddr_size           "disable" 
        
    if { $master_addr_map } {
        proc_set_enable_visible_parameter instruction_master_paddr_base       "enable"         
        proc_set_enable_visible_parameter instruction_master_paddr_size       "enable"
        proc_set_enable_visible_parameter data_master_paddr_base              "enable"
        proc_set_enable_visible_parameter data_master_paddr_size              "enable"  
        if { $impl == "Small" } {
            proc_set_enable_visible_parameter instruction_master_high_performance_paddr_base       "enable"
            proc_set_enable_visible_parameter instruction_master_high_performance_paddr_size       "enable"
            proc_set_enable_visible_parameter data_master_high_performance_paddr_base              "enable"
            proc_set_enable_visible_parameter data_master_high_performance_paddr_size              "enable" 
        }
        
        if { $impl == "Fast" && $fa_cache_linesize > 0 } {
            proc_set_enable_visible_parameter flash_instruction_master_paddr_base       "enable"
            proc_set_enable_visible_parameter flash_instruction_master_paddr_size       "enable" 
        }
        
        set icache_numTCIM [ get_parameter_value icache_numTCIM ]
        set dcache_numTCDM [ get_parameter_value dcache_numTCDM ]
        
        global TCI_INTF_PREFIX
        if { "${impl}" != "Tiny" } {
            foreach i {0 1 2 3} {
                set INTF_NAME "${TCI_INTF_PREFIX}${i}"               
                if { $i < $icache_numTCIM } {
                    proc_set_enable_visible_parameter ${INTF_NAME}_paddr_base       "enable"
                    proc_set_enable_visible_parameter ${INTF_NAME}_paddr_size       "enable"
                }
            }
        }
        
        global TCD_INTF_PREFIX
        if { "${impl}" != "Tiny" } {
            foreach i {0 1 2 3} {
                set INTF_NAME "${TCD_INTF_PREFIX}${i}"               
                if { $i < $dcache_numTCDM } {
                    proc_set_enable_visible_parameter ${INTF_NAME}_paddr_base       "enable"
                    proc_set_enable_visible_parameter ${INTF_NAME}_paddr_size       "enable"
                }
            }
        }
    }
}

proc sub_validate_check_module {} {
    global I_MASTER_INTF
    global FA_MASTER_INTF
    global D_MASTER_INTF
    global TCI_INTF_PREFIX
    global TCI_PREFIX
    global TCD_INTF_PREFIX
    global TCD_PREFIX
    global IHP_INTF_PREFIX
    global IHP_PREFIX
    global DHP_INTF_PREFIX
    global DHP_PREFIX
    global DEBUG_INTF
    global MUL_NONE
    global MUL_SLOW32
    global MUL_FAST32
    global MUL_FAST64

    global inst_slave_names
    global data_slave_names

    set inst_master_paddr_base          [ proc_num2hex [ proc_get_lowest_start_address instSlaveMapParam ] ]
    set inst_master_paddr_top           [ proc_num2hex [ proc_get_higest_end_address instSlaveMapParam ] ]
    
    set fa_master_paddr_base            [ proc_num2hex [ proc_get_lowest_start_address faSlaveMapParam ] ]
    set fa_master_paddr_top             [ proc_num2hex [ proc_get_higest_end_address faSlaveMapParam ] ]
    
    set data_master_paddr_base          [ proc_num2hex [ proc_get_lowest_start_address dataSlaveMapParam ] ]
    set data_master_paddr_top           [ proc_num2hex [ proc_get_higest_end_address dataSlaveMapParam ] ]
    set inst_master_hp_paddr_base       [ proc_num2hex [ proc_get_lowest_start_address ${IHP_PREFIX}MapParam ] ]
    set inst_master_hp_paddr_top        [ proc_num2hex [ proc_get_higest_end_address ${IHP_PREFIX}MapParam ] ]
    set data_master_hp_paddr_base       [ proc_num2hex [ proc_get_lowest_start_address ${DHP_PREFIX}MapParam ] ]
    set data_master_hp_paddr_top        [ proc_num2hex [ proc_get_higest_end_address ${DHP_PREFIX}MapParam ] ]
    
    set resetSlave                      [ get_parameter_value resetSlave ]
    set exceptionSlave                  [ get_parameter_value exceptionSlave ]
    set mmu_TLBMissExcSlave             [ get_parameter_value mmu_TLBMissExcSlave ]
                                        
    set reset_addr                      [ proc_get_reset_addr ]

    set general_exception_addr          [ proc_get_general_exception_addr ]
    set fast_tlb_miss_exception_addr    [proc_get_fast_tlb_miss_exception_addr ]

    set resetOffset                     [ get_parameter_value resetOffset ]
    set exceptionOffset                 [ get_parameter_value exceptionOffset ]
                                        
    set tcim_num                        [ get_parameter_value icache_numTCIM ]
    set tcdm_num                        [ get_parameter_value dcache_numTCDM ]
    set icache_size                     [ get_parameter_value icache_size ]
    set dcache_size_derived             [ get_parameter_value dcache_size_derived ]
    set dcache_bursts_derived           [ get_parameter_value dcache_bursts_derived ]
                                        
    set impl                            [ get_parameter_value impl ]
    set device_family_name              [ get_parameter_value deviceFamilyName ]
    set multiplierType                  [ get_parameter_value multiplierType ]
    set cpu_freq                        [ get_parameter_value clockFrequency ]
    set debug_level                     [ proc_get_boolean_parameter debug_enabled ]
    set mmu_enabled                     [ proc_get_mmu_present ]
    set mpu_enabled                     [ proc_get_mpu_present ]
    set setting_interruptControllerType [ get_parameter_value setting_interruptControllerType ]
    set setting_shadowRegisterSets      [ get_parameter_value setting_shadowRegisterSets ]
             
    set avail_break_slaves              [ proc_get_address_map_slaves_name instSlaveMapParam ]
    set export_vectors                  [ proc_get_boolean_parameter setting_exportvectors ]
    set ecc_present                     [ proc_get_boolean_parameter setting_ecc_present ]

    set instAddrWidth                   [ get_parameter_value instAddrWidth ]
    # Constant
    set maximum_32bits_boundary      "0x100000000"
    set maximum_31bits_boundary      "0x80000000"
    set upper_4bits_address_mask     "0xf0000000"
    set upper_3bits_address_mask     "0xe0000000"
    set word_alignment_mask          "0x0000001f"

    set ic_line_size [ proc_calculate_ic_tag_addr_size ]
    set instAddrWidth [ get_parameter_value instAddrWidth ]
    set dc_line_size [ proc_calculate_dc_tag_addr_size ]
    set dataAddrWidth [ get_parameter_value dataAddrWidth ]

    set master_addr_map                                    [ get_parameter_value master_addr_map ]
    set instruction_master_paddr_base                      [ proc_num2hex [ get_parameter_value instruction_master_paddr_base ]]
    set instruction_master_paddr_size                      [ expr abs([get_parameter_value instruction_master_paddr_size ])]
    set data_master_addr_map_paddr_base                    [ proc_num2hex [ get_parameter_value data_master_paddr_base ]]
    set data_master_addr_map_paddr_size                    [ expr abs([ get_parameter_value data_master_paddr_size ])]
    set instruction_master_paddr_top_map                   [ proc_num2hex [ expr $instruction_master_paddr_base + $instruction_master_paddr_size - 1 ]]
    set data_master_paddr_top_map                          [ proc_num2hex [ expr $data_master_addr_map_paddr_base + $data_master_addr_map_paddr_size - 1 ]]
    set instruction_master_addrwidth                       [ proc_num2sz $instruction_master_paddr_top_map ]
    set data_master_addrwidth                              [ proc_num2sz $data_master_paddr_top_map ]

    if { $master_addr_map } {
        set instAddrWidth $instruction_master_addrwidth
        set dataAddrWidth $data_master_addrwidth
    }
    # both the I-cache and D-cache has over head of 5bits = 3 bits (offset - 8 word per line) + 2 bits (byte access)
    set cache_overhead 5

    if { $icache_size > 0 && $impl == "Fast" } {
        set ic_tag_size [ expr $instAddrWidth - $ic_line_size - $cache_overhead ]
        if { $ic_tag_size <= 0 } {
            send_message error "Instruction Cache is larger than the Instruction Address. Please reduce the Instruction Cache Size. Current Tag Size is $ic_tag_size"
        }
    }

    set dcache_size [ get_parameter_value dcache_size ]
    if { $dcache_size > 0 && $impl == "Fast"  } {
        set dc_tag_size [ expr $dataAddrWidth - $dc_line_size - $cache_overhead ]
        if { $dc_tag_size <= 0 } {
            send_message error "Data Cache is larger than the Data Address. Please reduce the Data Cache Size. Current Tag Size is $dc_tag_size"
        }
    }
    
    # We are going to reassign this to individual derived parameter for easier use
    set debug_traceStorage [ get_parameter_value debug_traceStorage ]
    set debug_traceType [ get_parameter_value debug_traceType ]
    
    if { $debug_level } {
        if { "$debug_traceType" == "none" } {
            set_parameter_value  debug_insttrace   false
            set_parameter_value  debug_datatrace   false
            set_parameter_value  debug_onchiptrace   false
            set_parameter_value  debug_offchiptrace   false
        } else { 
            if { "$debug_traceType" == "instruction_trace" } { 
                set_parameter_value  debug_insttrace   true
                set_parameter_value  debug_datatrace   false
            } elseif { "$debug_traceType" == "instruction_and_data_trace" } {
                set_parameter_value  debug_insttrace   true
                set_parameter_value  debug_datatrace   true                
            }
            
            if { "$debug_traceStorage" == "onchip_trace" } { 
                set_parameter_value  debug_onchiptrace   true
                set_parameter_value  debug_offchiptrace   false
            } elseif { "$debug_traceStorage" == "offchip_trace" } {
                set_parameter_value  debug_onchiptrace   false
                set_parameter_value  debug_offchiptrace   true
            } else {
                set_parameter_value  debug_onchiptrace   true
                set_parameter_value  debug_offchiptrace   true
            }
                
        }
    } else {
        set_parameter_value  debug_onchiptrace   false
        set_parameter_value  debug_offchiptrace   false
        set_parameter_value  debug_insttrace   false
        set_parameter_value  debug_datatrace   false
    }

    set onchip_trace_support    [ proc_get_boolean_parameter debug_onchiptrace ]
    
    set address_validity "address valid"
    # Do not check for the vectors when export_vectors are chosen
    if { !$export_vectors } {
        # validate that reset slave must be selected
        if { [ expr { "$resetSlave" == "None" } || { "RS_$resetSlave" == "RS_" } ] } {
            send_message error "Reset slave is not specified. Please select the reset slave"
            set address_validity "address not valid"
        } else {
                # return the reset offset address
                set abs_reset_inst_slaves [ proc_get_reset_addr ]
                set_parameter_value resetAbsoluteAddr $abs_reset_inst_slaves
                
                # validate that reset slave is connected to the instruction master
                # proc_get_address_map_1_slave_start_address will return -1 if no match
                set inst_reset_slave        [ proc_is_slave_exist instSlaveMapParam $resetSlave ]
                set fa_reset_slave          [ proc_is_slave_exist faSlaveMapParam   $resetSlave ]
                set tcim0resetSlave         [ proc_is_slave_exist ${TCI_PREFIX}0MapParam $resetSlave ]
                set tcim1resetSlave         [ proc_is_slave_exist ${TCI_PREFIX}1MapParam $resetSlave ]
                set tcim2resetSlave         [ proc_is_slave_exist ${TCI_PREFIX}2MapParam $resetSlave ]
                set tcim3resetSlave         [ proc_is_slave_exist ${TCI_PREFIX}3MapParam $resetSlave ]
                set ihpresetSlave           [ proc_is_slave_exist ${IHP_PREFIX}MapParam $resetSlave ]
                set data_reset_slave        [ expr { $inst_reset_slave } || { $tcim0resetSlave } || { $tcim1resetSlave } || { $tcim2resetSlave } || { $tcim3resetSlave } || { $ihpresetSlave }]
                
                #if { [ expr { "[ proc_get_address_map_1_slave_start_address instSlaveMapParam $resetSlave ]" == "-1" } && { "$resetSlave" != "Absolute" } ] } {
                #    send_message error "Reset slave $resetSlave not connected to $I_MASTER_INTF."
                #}
                
                if { [ expr { "$inst_reset_slave" == "0" } && { "$tcim0resetSlave" == "0" } && { "$tcim1resetSlave" == "0" } && { "$tcim2resetSlave" == "0" } && { "$tcim3resetSlave" == "0" } && { "$ihpresetSlave" == "0" } && { "$fa_reset_slave" == "0" } && { "$resetSlave" != "Absolute" } ] } {
                    send_message error "Reset slave $resetSlave not connected to $I_MASTER_INTF."
                    set address_validity "address not valid"
                }
        
                # validate that reset slave is connected to the data master
                # Java model dont check this, do we want check?
                #if { [ expr { "[ proc_get_address_map_1_slave_start_address dataSlaveMapParam $resetSlave ]" == "-1" } && { "$resetSlave" != "Absolute" } ] } {
                #    send_message error "Reset slave $resetSlave not connected to $D_MASTER_INTF."
                #}
                #if { "$data_reset_slave" == "0" } {
                #    if { [ expr { "[ proc_is_slave_exist dataSlaveMapParam $resetSlave ]" == "0" } && { "$resetSlave" != "Absolute" } ] } {
                #        send_message error "Reset slave $resetSlave not connected to $D_MASTER_INTF."
                #    }
                #}
                # validate that reset slave offset must be multiple of 0x20 (from Nios2 validation)
                proc_validate_address_alignment $resetOffset \
                  $word_alignment_mask "Reset offset must be word aligned"
                  
                # validate that user's base + offset address does not exceed the slave end address
                if { [ expr { "[ proc_validate_offset $resetSlave $abs_reset_inst_slaves]" == "1" } && { "$resetSlave" != "Absolute" } ] } {
                    send_message error "Reset offset is too large for the selected memory"
                }
        
                # Vector must be cache aligned to 0x20, check when reset slave is valid
                if { [ expr { $reset_addr % 0x20 } && { $reset_addr != -1 } ] } {
                    send_message error "Reset vector must be a multiple of 0x20"
                }
            }
        
        # validate that exception slave must be selected
        if { [ expr { "$exceptionSlave" == "None" } || { "RS_$exceptionSlave" == "RS_" } ] } {
            send_message error "Exception slave is not specified. Please select the exception slave"
            set address_validity "address not valid"
        } else {
            # return the exception offset address
            set abs_exp_inst_slaves [ proc_get_general_exception_addr ]
            set_parameter_value exceptionAbsoluteAddr $abs_exp_inst_slaves
            
            # validate that Exception slave is connected to the instruction master
            #if { [ expr { "[ proc_get_address_map_1_slave_start_address instSlaveMapParam $exceptionSlave ]" == "-1" } && { "$exceptionSlave" != "Absolute" } ] } {
            #    send_message error "Exception slave $exceptionSlave not connected to $I_MASTER_INTF."
            #}
            set inst_exc_slave [ proc_is_slave_exist instSlaveMapParam $exceptionSlave ]
            set fa_exc_slave  [ proc_is_slave_exist faSlaveMapParam $exceptionSlave ]
            set tcim0excSlave [ proc_is_slave_exist ${TCI_PREFIX}0MapParam $exceptionSlave ]
            set tcim1excSlave [ proc_is_slave_exist ${TCI_PREFIX}1MapParam $exceptionSlave ]
            set tcim2excSlave [ proc_is_slave_exist ${TCI_PREFIX}2MapParam $exceptionSlave ]
            set tcim3excSlave [ proc_is_slave_exist ${TCI_PREFIX}3MapParam $exceptionSlave ]
            set ihpexcSlave   [ proc_is_slave_exist ${IHP_PREFIX}MapParam $exceptionSlave ]
            set data_exc_slave      [ expr { $inst_exc_slave } || { $tcim0excSlave } || { $tcim1excSlave } || { $tcim2excSlave } || { $tcim3excSlave } || { $ihpexcSlave } ]
            if { [ expr { "$inst_exc_slave" == "0" } && { "$fa_exc_slave" == "0" } && { "$tcim0excSlave" == "0" } && { "$tcim1excSlave" == "0" } && { "$tcim2excSlave" == "0" } && { "$tcim3excSlave" == "0" } && { "$ihpexcSlave" == "0" } && { "$exceptionSlave" != "Absolute" } ] } {
                    send_message error "Exception slave $exceptionSlave not connected to $I_MASTER_INTF."
                    set address_validity "address not valid"
            }
        
            # validate that Exception slave is connected to the data master
            #if { [ expr { "[ proc_get_address_map_1_slave_start_address dataSlaveMapParam $exceptionSlave ]" == "-1" } && { "$exceptionSlave" != "Absolute" } ] } {
            #    send_message error "Exception slave $exceptionSlave not connected to $D_MASTER_INTF."
            #}
            #if { "$data_exc_slave" == "0" } {
            #    if { [ expr { "[ proc_is_slave_exist dataSlaveMapParam $exceptionSlave ]" == "0" } && { "$exceptionSlave" != "Absolute" } ] } {
            #            send_message error "Exception slave $exceptionSlave not connected to $D_MASTER_INTF."
            #    }
            #}
            # validate that Exception slave offset must be 0x20 (from Nios2 validation)
            proc_validate_address_alignment $exceptionOffset \
              $word_alignment_mask "Exception offset must be word aligned"
              
            # validate that user's base + offset address does not exceed the slave end address
            if { [ expr { "[ proc_validate_offset $exceptionSlave $abs_exp_inst_slaves]" == "1" } && { "$exceptionSlave" != "Absolute" } ] } {
                    send_message error "Exception offset is too large for the selected memory"
            }
        
            # check when the exception slave is valid
            if { [ expr { $general_exception_addr % 0x20 } && { $general_exception_addr != -1 } ] } {
                send_message error "Exception vector must be a multiple of 0x20"
            } 
        }
    }

    if { "$resetSlave" != "None" && "$reset_addr" == "$general_exception_addr" && "$address_validity" == "address valid" } {
        send_message error "Exception and Reset vectors are pointing to the same address"
    }

    if { "$mmu_enabled" == "1" && "$reset_addr" == "$fast_tlb_miss_exception_addr" && "$resetSlave" != "None" && "$address_validity" == "address valid" } {
        send_message error "Fast TLB miss and Reset vectors are pointing to the same address"
    }
    
    # return the Fast TLB Miss Exception offset address
    set mmu_TLBMissExcSlaveAbs [ proc_get_fast_tlb_miss_exception_addr ]
    set_parameter_value mmu_TLBMissExcAbsAddr $mmu_TLBMissExcSlaveAbs
    
    # validate that user's base + offset address does not exceed the slave end address
    if { [ expr { "[ proc_validate_offset $mmu_TLBMissExcSlave $mmu_TLBMissExcSlaveAbs]" == "1" } && { "$mmu_TLBMissExcSlave" != "Absolute" } ] } {
        send_message error "TLB Miss Exception offset is too large for the selected memory"
    }

    # Automatically select the JTAG debug slave if debugger is enabled
    set allow_break_inst                [proc_get_boolean_parameter setting_allow_break_inst]
    set setting_breakslaveoveride       [ proc_get_boolean_parameter setting_breakslaveoveride ]
    set cpu_arch_rev [ get_parameter_value cpuArchRev ]

    if { (!$debug_level && ($allow_break_inst || $cpu_arch_rev == 1)) || ($debug_level && $setting_breakslaveoveride) } {
        # When break inst is allowed, take the breakSlave value from user parameter
        set_parameter_value breakSlave_derived [ get_parameter_value breakSlave ]
        
        set breakSlave                         [ get_parameter_value breakSlave_derived ]
        set current_breakslave                 [ get_parameter_value breakSlave_derived ]
    } else {
        set current_breakslave [ get_parameter_value breakSlave_derived ]
        set break_slave_is_debug_intf 0

        # If the current break match debug interface 
        # and if it is part of the instruction master slave, set break_slave_is_debug_intf to 1 and break
        # Else set break_slave_is_debug_intf to 0 to continue with auto select
        if { [ string match "*${DEBUG_INTF}" "$current_breakslave" ] } {
            foreach default_slave $avail_break_slaves {
                if { [ string match "$current_breakslave" "$default_slave" ] } {
                    set break_slave_is_debug_intf 1
                    break
                } else {
                    set break_slave_is_debug_intf 0
                }
            }
        } else {
            set break_slave_is_debug_intf 0
        }
        
        if { $debug_level && !$break_slave_is_debug_intf } {
            foreach default_slave $avail_break_slaves {
                if { [ string match "*${DEBUG_INTF}" "$default_slave" ] } {
                    set_parameter_value breakSlave_derived $default_slave
                }                
            }
        }
        
        set breakSlave                  [ get_parameter_value breakSlave_derived ]
    }
    
    # Obtain the break_addr once the breakslave has been set
    set break_addr                      [ proc_get_break_addr ]

    set setting_oci_version [ get_parameter_value setting_oci_version ]
    # validate that debug must be specified if debug port is enabled

    # TODO: figure out some way to assign the debug slave
    # to the debug_mem_slave. probably a syntactical thing
    # However this validation code can stay
    # Do not check for the vectors when export_vectors are chosen
    if { ( $debug_level || $allow_break_inst || $cpu_arch_rev == 1 ) && ( $setting_oci_version == 1) } { 
        if { [ expr { "$breakSlave" == "None" } || { "RS_$breakSlave" == "RS_" } ] } {
            if { $debug_level } {
                send_message error "Debug port is enabled. Please connect the instruction_master and data_master to debug_mem_slave"
            } else {
                send_message error "No break vector has been specified for this processor. Please choose an appropriate memory for the Break Vector in the Vectors tab"
                set address_validity "address not valid"
            }
        } else {
            # return the offset address
            set abs_break_inst_slaves [ proc_get_break_addr ]
            set_parameter_value breakAbsoluteAddr $abs_break_inst_slaves
            
            # validate that break slave is connected to the instruction master
            set inst_break_slave [ proc_is_slave_exist instSlaveMapParam $breakSlave ]
            set fa_break_slave   [ proc_is_slave_exist faSlaveMapParam $breakSlave ]
            set tcim0breakSlave [ proc_is_slave_exist ${TCI_PREFIX}0MapParam $breakSlave ]
            set tcim1breakSlave [ proc_is_slave_exist ${TCI_PREFIX}1MapParam $breakSlave ]
            set tcim2breakSlave [ proc_is_slave_exist ${TCI_PREFIX}2MapParam $breakSlave ]
            set tcim3breakSlave [ proc_is_slave_exist ${TCI_PREFIX}3MapParam $breakSlave ] 
            set ihpbreakSlave   [ proc_is_slave_exist ${IHP_PREFIX}MapParam $breakSlave ]
            if { $debug_level } {
                if { [ expr { "$inst_break_slave" == "0" } && { "$fa_break_slave" == "0" } && { "$tcim0breakSlave" == "0" } && { "$tcim1breakSlave" == "0" } && { "$tcim2breakSlave" == "0" } && { "$tcim3breakSlave" == "0" } && { "$ihpbreakSlave" == "0" } && { "$breakSlave" != "Absolute" } ] } {
                    send_message error "Debug slave $breakSlave not connected to $I_MASTER_INTF."
                    set address_validity "address not valid"
                }
            } else {
                if { [ expr { "$inst_break_slave" == "0" } && { "$fa_break_slave" == "0" } && { "$tcim0breakSlave" == "0" } && { "$tcim1breakSlave" == "0" } && { "$tcim2breakSlave" == "0" } && { "$tcim3breakSlave" == "0" } && { "$ihpbreakSlave" == "0" } && { "$breakSlave" != "Absolute" } ] } {
                    send_message error "Please choose an appropriate slave for the Break vector memory"
                    set address_validity "address not valid"
                }
            }
        
            # validate that debug slave is connected to the data master
            set data_break_slave [ proc_is_slave_exist dataSlaveMapParam $breakSlave ]
            set tcdm0breakSlave [ proc_is_slave_exist ${TCD_PREFIX}0MapParam $breakSlave ]
            set tcdm1breakSlave [ proc_is_slave_exist ${TCD_PREFIX}1MapParam $breakSlave ]
            set tcdm2breakSlave [ proc_is_slave_exist ${TCD_PREFIX}2MapParam $breakSlave ]
            set tcdm3breakSlave [ proc_is_slave_exist ${TCD_PREFIX}3MapParam $breakSlave ] 
            set dhpbreakSlave  [ proc_is_slave_exist ${DHP_PREFIX}MapParam $breakSlave ] 
            set data_break_slave_connect      [ expr { $data_break_slave } || { $tcdm0breakSlave } || { $tcdm1breakSlave } || { $tcdm2breakSlave } || { $tcdm3breakSlave } || { $dhpbreakSlave } ]
            
            #if { "$data_break_slave_connect" == "0" } {
            #    if { [ expr { "[ proc_is_slave_exist dataSlaveMapParam $breakSlave ]" == "0" } && { "$breakSlave" != "Absolute" } ] } {
            #        send_message error "Debug slave $breakSlave not connected to $D_MASTER_INTF."
            #    }
            #}
            
            # validate that user's base + offset address does not exceed the slave end address
            if { [ expr { "[ proc_validate_offset $breakSlave $abs_break_inst_slaves]" == "1" } && { "$breakSlave" != "Absolute" } ] } {
                send_message error "Break offset is too large for the selected memory"
            }
            
            # check when break slave is valid
            if { [ expr { $break_addr % 0x20 } && { $break_addr != -1 } ] } {
                send_message error "Break vector must be a multiple of 0x20"
            }
        }
    }
    
    set setting_oci_version [ get_parameter_value setting_oci_version ]

    # Get the clock frequency must be greater than 20MHz if jtag_debug_slave is to work correctly
    # Only for OCI version 1
    if { [ expr { $cpu_freq != 0 } && { $cpu_freq < 20000000 } && { $debug_level } && { $setting_oci_version == 1} ] } {
        send_message error "Nios II debug module requires a clock frequency of at least 20 MHz"
    }

    # Validate instruction and data master against 2^32 boundary
    set avail_inst_slaves    [ proc_get_address_map_slaves_name instSlaveMapParam ]
    set any_inst_slaves [ expr ( [ llength $avail_inst_slaves ] ) > 0 ]

    if { [ expr { $inst_master_paddr_top >= $maximum_32bits_boundary } && $any_inst_slaves ] } {       
        send_message error "Nios II Instruction Master cannot address memories over 2^32"
    }

    set avail_data_slaves    [ proc_get_address_map_slaves_name dataSlaveMapParam ]
    set any_data_slaves [ expr ( [ llength $avail_data_slaves ] ) > 0 ]
    
    if { [ expr { $data_master_paddr_top >= $maximum_32bits_boundary } && $any_data_slaves ] } {
        send_message error "Nios II Data Master cannot address memories over 2^32"
    }

    # Validate that the support31bitdcachebypass is turned off to support full 32 bit data address
    set setting_support31bitdcachebypass [ proc_get_boolean_parameter setting_support31bitdcachebypass ]
    if { [ expr { $data_master_paddr_top >= $maximum_31bits_boundary } && $setting_support31bitdcachebypass && { "$impl" == "Fast" } && $any_data_slaves && { "$mmu_enabled" != "1" } ] } {
        send_message error "Please uncheck the \"Use most-significant address bit in processor to bypass data cache\" option to support full 32 bit address"
    }
    
    set fa_cache_linesize [ get_parameter_value fa_cache_linesize ]

    if { [ expr { "$mmu_enabled" == "1" } ] } {
        
        if { "$icache_size" == "0" } {
            send_message error "Instruction cache must be turned on when MMU is enabled"
        }

        # If mmu is enabled check for available mmu slaves first
        # Nios II/M does not support MMU and MPU
        if {[ expr { "$mmu_TLBMissExcSlave" == "None" } || { "RS_$mmu_TLBMissExcSlave" == "RS_" } ]} {
            send_message error "Fast TLB miss exception vector memory is not specified. Please select the fast TLB miss exception slave"
        } else {
            # check that the MMU Fast TLB is connected to any instruction master slave
            set inst_mmu_slave [ proc_is_slave_exist instSlaveMapParam $mmu_TLBMissExcSlave ]
            set fa_mmu_slave   [ proc_is_slave_exist faSlaveMapParam $mmu_TLBMissExcSlave ]
            set tcim0mmuSlave [ proc_is_slave_exist ${TCI_PREFIX}0MapParam $mmu_TLBMissExcSlave ]
            set tcim1mmuSlave [ proc_is_slave_exist ${TCI_PREFIX}1MapParam $mmu_TLBMissExcSlave ]
            set tcim2mmuSlave [ proc_is_slave_exist ${TCI_PREFIX}2MapParam $mmu_TLBMissExcSlave ]
            set tcim3mmuSlave [ proc_is_slave_exist ${TCI_PREFIX}3MapParam $mmu_TLBMissExcSlave ]
            if { [ expr { "$inst_mmu_slave" == "0" } && { "$fa_mmu_slave" == "0" } && { "$tcim0mmuSlave" == "0" } && { "$tcim1mmuSlave" == "0" } && { "$tcim2mmuSlave" == "0" } && { "$tcim3mmuSlave" == "0" } && { "$mmu_TLBMissExcSlave" != "Absolute" } ] } {
                send_message error "MMU Fast TLB slave $mmu_TLBMissExcSlave not connected to $I_MASTER_INTF."
                set address_validity "address not valid"
            }
        
            # Evaluate only when address is valid
            if { "$address_validity" == "address valid" } {
                # The tightly-coupled instruction and data masters can only connect to slaves with a base
                # address with bits 29-31 set to 0. This effectively restricts TCMs to having a 29-bit
                # address.  This is required because the TCMs are mapped into the KERNEL address region
                # which only supports a 29-bit physical address.
                foreach i {0 1 2 3} {
                    set INTF_TCI_NAME "${TCI_PREFIX}${i}"
                    if { $i < $tcim_num } {
                        set tcim_base_addr_top_3_bit [ expr [ proc_get_lowest_start_address ${INTF_TCI_NAME}MapParam ] & $upper_3bits_address_mask ]
                        if { [ expr { $tcim_base_addr_top_3_bit != 0 } ] } {
                            send_message error "In a MMU enabled system, Tightly Coupled Memory ${INTF_TCI_NAME} must be mapped into the KERNEL address region (address bits 31-29 set to 0)"
                        }
                    }
                }
                
                foreach i {0 1 2 3} {
                    set INTF_TCD_NAME "${TCD_PREFIX}${i}"
                    if { $i < $tcdm_num } {
                        set tcdm_base_addr_top_3_bit [ expr [ proc_get_lowest_start_address ${INTF_TCD_NAME}MapParam ] & $upper_3bits_address_mask ]
                        if { [ expr { $tcdm_base_addr_top_3_bit != 0 } ] } {
                            send_message error "In a MMU enabled system, Tightly Coupled Memory ${INTF_TCD_NAME} must be mapped into the KERNEL address region (address bits 31-29 set to 0)"
                        }
                    }
                }
                
                # Check Reset, Exception, Break, and Fast TLB Miss Exception slave addresses
                # to make sure they're mapped into the KERNEL region
                set reset_addr_top_3_bit [ expr { $reset_addr & $upper_3bits_address_mask } ]
                if { [ expr { $reset_addr_top_3_bit != 0 } ] } {
                    send_message error "In a MMU enabled system, reset vector must be mapped into the KERNEL address region (address bits 31-29 set to 0)"
                }
                
                set general_exceptopn_addr [ expr { $general_exception_addr & $upper_3bits_address_mask } ]
                if { [ expr { $general_exceptopn_addr != 0} ] } {
                    send_message error "In a MMU enabled system, exception vector must be mapped into the KERNEL address region (address bits 31-29 set to 0)"
                }
                
                set break_addr_top_3_bit [ expr { $break_addr & $upper_3bits_address_mask } ]
                if { [ expr { $break_addr_top_3_bit != 0 } ]  } {
                    send_message error "In a MMU enabled system, break vector must be mapped into the KERNEL address region (address bits 31-29 set to 0)"
                }
                
                set fast_tlb_addr_top_3_bit [ expr { $fast_tlb_miss_exception_addr & $upper_3bits_address_mask } ]
                if { [ expr { $fast_tlb_addr_top_3_bit != 0 } ] } {
                    send_message error "In a MMU enabled system, fast TLB miss vector must be mapped into the KERNEL address region (address bits 31-29 set to 0)"
                }
            }
            
            if { [ expr $fast_tlb_miss_exception_addr % 0x20 && { $fast_tlb_miss_exception_addr != -1 } ] } {
                send_message error "Fast TLB miss exception vector must be a multiple of 0x20"
            }
        }
    } else {
        #
        # No MMU. Might be an MPU.
        #
        ## Provide a warning message if TCM memory map and IM/DM memory map overlaps
        ## Provide warning if IM/DM overlaps with IM/DM High performance
        
        set ihp_address_width [ get_parameter_value ${IHP_PREFIX}AddrWidth ]
        set dhp_address_width [ get_parameter_value ${DHP_PREFIX}AddrWidth ]

        # Only check when this is non Tiny
        if { "$impl" != "Tiny" } {
        	foreach i {0 1 2 3} {
        	    set INTF_TCI_NAME "${TCI_PREFIX}${i}"
        	    if { $i < $tcim_num } {
        	        set tcim_paddr_top_hex [ proc_num2hex [ proc_get_higest_end_address ${INTF_TCI_NAME}MapParam ]]
        	        set tcim_paddr_base_hex [ proc_num2hex [ proc_get_lowest_start_address ${INTF_TCI_NAME}MapParam ]]
        	        set inst_master_paddr_base_overlap_tcim [ expr { $inst_master_paddr_base >= $tcim_paddr_base_hex } && { $inst_master_paddr_base <= $tcim_paddr_top_hex } ]
        	        set inst_master_paddr_top_overlap_tcim [ expr { $inst_master_paddr_top >= $tcim_paddr_base_hex } && { $inst_master_paddr_top <= $tcim_paddr_top_hex } ]
        	        if { [ expr { $inst_master_paddr_base_overlap_tcim || $inst_master_paddr_top_overlap_tcim } ] } {
        	            send_message warning "Generating non-optimal logic for ${INTF_TCI_NAME} due to memory map overlap with instruction master ($inst_master_paddr_base - $inst_master_paddr_top)"
        	        }
        	        
        	        
        	        if { "$impl" == "Fast" && $fa_cache_linesize > 0 } {
        	            set fa_master_paddr_base_overlap_tcim [ expr { $fa_master_paddr_base >= $tcim_paddr_base_hex } && { $fa_master_paddr_base <= $tcim_paddr_top_hex } ]
        	            set fa_master_paddr_top_overlap_tcim [ expr { $fa_master_paddr_top >= $tcim_paddr_base_hex } && { $fa_master_paddr_top <= $tcim_paddr_top_hex } ]
        	            if { [ expr { $fa_master_paddr_base_overlap_tcim || $fa_master_paddr_top_overlap_tcim } ] } {
        	                send_message warning "Generating non-optimal logic for ${INTF_TCI_NAME} due to memory map overlap with flash master ($fa_master_paddr_base - $fa_master_paddr_top)"
        	            }
        	        }
        	        
        	        if { "$impl" == "Small" && $ihp_address_width > 1 } {
        	            set inst_master_hp_paddr_base_overlap_tcim [ expr { $inst_master_hp_paddr_base >= $tcim_paddr_base_hex } && { $inst_master_hp_paddr_base <= $tcim_paddr_top_hex } ]
        	            set inst_master_hp_paddr_top_overlap_tcim [ expr { $inst_master_hp_paddr_top >= $tcim_paddr_base_hex } && { $inst_master_hp_paddr_top <= $tcim_paddr_top_hex } ]
        	            if { [ expr { $inst_master_hp_paddr_base_overlap_tcim || $inst_master_hp_paddr_top_overlap_tcim } ] } {
        	                send_message warning "Generating non-optimal logic for ${INTF_TCI_NAME} due to memory map overlap with instruction master high performance ($inst_master_paddr_base - $inst_master_paddr_top)"
        	            }
        	        }
        	    }
        	}

        	foreach i {0 1 2 3} {
        	    set INTF_TCD_NAME "${TCD_PREFIX}${i}"
        	    if { $i < $tcdm_num } {
        	        set tcdm_paddr_top_hex [ proc_num2hex [ proc_get_higest_end_address ${INTF_TCD_NAME}MapParam ]]
        	        set tcdm_paddr_base_hex [ proc_num2hex [ proc_get_lowest_start_address ${INTF_TCD_NAME}MapParam ]]
        	        set data_master_paddr_base_overlap_tcdm [ expr { $data_master_paddr_base >= $tcdm_paddr_base_hex } && { $data_master_paddr_base <= $tcdm_paddr_top_hex } ]
        	        set data_master_paddr_top_overlap_tcdm [ expr { $data_master_paddr_top >= $tcdm_paddr_base_hex } && { $data_master_paddr_top <= $tcdm_paddr_top_hex  } ]
        	        if { [ expr {$data_master_paddr_base_overlap_tcdm || $data_master_paddr_top_overlap_tcdm } ] } {
        	            send_message warning "Generating non-optimal logic for ${INTF_TCD_NAME} due to memory map overlap with data master ($data_master_paddr_base - $data_master_paddr_top)"
        	        }
        	        
        	        if { "$impl" == "Small" && $dhp_address_width > 1 } {
        	            set data_master_hp_paddr_base_overlap_tcdm [ expr { $data_master_hp_paddr_base >= $tcdm_paddr_base_hex } && { $data_master_hp_paddr_base <= $tcdm_paddr_top_hex } ]
        	            set data_master_hp_paddr_top_overlap_tcdm [ expr { $data_master_hp_paddr_top >= $tcdm_paddr_base_hex } && { $data_master_hp_paddr_top <= $tcdm_paddr_top_hex  } ]
        	            if { [ expr {$data_master_hp_paddr_base_overlap_tcdm || $data_master_hp_paddr_top_overlap_tcdm } ] } {
        	                send_message warning "Generating non-optimal logic for ${INTF_TCD_NAME} due to memory map overlap with data master high performance ($data_master_paddr_base - $data_master_paddr_top)"
        	            }
        	        }
        	    }
        	}
        }
        
        # Detect that MPU region size is within the instruction /data address space
        if { "$impl" == "Fast" && $mpu_enabled == 1 } {  

        	set mpu_minDataRegionSize   [ get_parameter_value mpu_minDataRegionSize ]
        	set mpu_minInstRegionSize   [ get_parameter_value mpu_minInstRegionSize ]
        	
        	set inst_highest_addr_width [ proc_get_cmacro_inst_addr_width ]
        	set data_highest_addr_width [ proc_get_cmacro_data_addr_width ]
        	
        	if { $mpu_minInstRegionSize >= $inst_highest_addr_width } {
        		send_message error "MPU Minimum instruction region size is larger than the instruction address space"
        	}
        	
        	if { $mpu_minDataRegionSize >= $data_highest_addr_width} {
        		send_message error "MPU Minimum data region size is larger than the data address space"
        	}

        }

        if { "$impl" == "Fast" && $fa_cache_linesize > 0 } {       	
            # Flash accelerator memory map can be located in between instruction master slaves as long as there is no overlap between each slave and the Flash Accelerator region
            set inst_overlap_base 0
            set inst_overlap_top 0
            set inst_index 0

            set address_map_dec [ proc_decode_address_map instSlaveMapParam]
            foreach inst_slave $address_map_dec {
            	array set slave_info_array $inst_slave
                set inst_slave_start $slave_info_array(start)
                set inst_slave_end [ expr $slave_info_array(end) - 1 ]
                set inst_slave_violate $slave_info_array(name)
              	set inst_overlap_base [ expr { $inst_slave_start >= $fa_master_paddr_base } && { $inst_slave_start <= $fa_master_paddr_top } ]
                set inst_overlap_top [ expr { $inst_slave_end >= $fa_master_paddr_base } && { $inst_slave_end <= $fa_master_paddr_top } ]
                	
                if { [ expr { $inst_overlap_base || $inst_overlap_top } ] } {
                    break;
                }
                incr inst_index
            }

            if { [ expr { $inst_overlap_base || $inst_overlap_top } ] } {
                send_message error "Memory map overlap detected between flash accelerator master and instruction master at $inst_slave_violate"
            }
        }

        if { "$impl" == "Small" } {
            # HP interface can be located in between instruction/data master slave as long as there is no overlap between each slave and the HP region
            set inst_overlap_base 0
            set inst_overlap_top 0
            set data_overlap_base 0
            set data_overlap_top 0
            set inst_index 0
            set data_index 0
           
            set address_map_dec [ proc_decode_address_map instSlaveMapParam]
            foreach inst_slave $address_map_dec {
            	array set slave_info_array $inst_slave
                set inst_slave_start $slave_info_array(start)
                set inst_slave_end [ expr $slave_info_array(end) - 1 ]
                set inst_slave_violate $slave_info_array(name)
                set inst_overlap_base [ expr { $inst_slave_start >= $inst_master_hp_paddr_base } && { $inst_slave_start <= $inst_master_hp_paddr_top } ]
                set inst_overlap_top [ expr { $inst_slave_end >= $inst_master_hp_paddr_base } && { $inst_slave_end <= $inst_master_hp_paddr_top } ]
                
                if { [ expr { $inst_overlap_base || $inst_overlap_top } ] } {
                    break;
                }
                incr inst_index
            }
            
            set address_map_dec [ proc_decode_address_map dataSlaveMapParam]
            foreach data_slave $address_map_dec {
            	array set slave_info_array $data_slave
                set data_slave_start $slave_info_array(start)
                set data_slave_end [ expr $slave_info_array(end) - 1 ]
                set data_slave_violate $slave_info_array(name)
                set data_overlap_base [ expr { $data_slave_start >= $data_master_hp_paddr_base } && { $data_slave_start <= $data_master_hp_paddr_top } ]
                set data_overlap_top [ expr { $data_slave_end >= $data_master_hp_paddr_base } && { $data_slave_end <= $data_master_hp_paddr_top } ]
                
                if { [ expr { $data_overlap_base || $data_overlap_top } ] } {
                    break;
                }
                incr data_index
            }

            if { [ expr { $inst_overlap_base || $inst_overlap_top } ] } {
                send_message error "Memory map overlap detected between instruction master high performance and instruction master at $inst_slave_violate"
            }
            
            if { [ expr { $data_overlap_base || $data_overlap_top } ] } {
                send_message error "Memory map overlap detected between data master high performance and data master at $data_slave_violate"
            }
        }

    }

    # If the MPU is enabled, MPU "limit" mode is limited to systems
    # where both the instruction and data address width is 31 bits or 
    # less. This is part of a fix to SPR:389283 to suport 4GB addressing
    # with the MPU. 
    if { [ expr { "$mpu_enabled" == "1" } ] } {
      if { [proc_get_boolean_parameter mpu_useLimit] } {
        if { [ expr { $data_master_paddr_top >= $maximum_31bits_boundary } || { $inst_master_paddr_top >= $maximum_31bits_boundary } ] } {
          send_message error "MPU region 'Limit' mode cannot be used with instruction or data width greater than 31 bits."
        }
      }
    }
    
    if { "$impl" == "Fast" } {
        # MPU and MMU are mutually exclusive
        if { "$mmu_enabled" == "1" && "$mpu_enabled" == "1" } {
            send_message error "An MPU and an MMU are mutually exclusive"
        }

        # Setting the derived values
        set dcache_size_gui_value [ get_parameter_value dcache_size ]
        set dcache_bursts_gui_value [ get_parameter_value dcache_bursts ]
        set_parameter_value dcache_size_derived $dcache_size_gui_value
        set_parameter_value dcache_bursts_derived $dcache_bursts_gui_value

        set setting_dc_ecc_present [ proc_get_boolean_parameter setting_dc_ecc_present ]
        set dcache_victim_buf_impl [ get_parameter_value dcache_victim_buf_impl ]
    }  else {
            set dcache_size_gui_value [ get_parameter_value dcache_size ]
            set dcache_bursts_gui_value [ get_parameter_value dcache_bursts ]
            set_parameter_value dcache_size_derived $dcache_size_gui_value
            set_parameter_value dcache_bursts_derived $dcache_bursts_gui_value
    }
    
    # TODO: Ensure TCM slave didnt connect with inst/data master
    # TODO? how to ensure TCM slave has slave latency of 1
    # TODO? how to ensure TCM slave has same clock domain as the cpu
    # TODO? how to ensure jtag_debug_model only connect to own master

    # Check device setting
    if { "$device_family_name" == "" } {
        send_message error "Device Type is not set"
    }

    if { !$debug_level } {
        send_message warning "No Debugger.  You will not be able to download or debug programs"
    }
    
    # Pending SPR:347223 (Auto connection of debug_mem_slave)
    if { [ expr { $debug_level } && { ! [ string match -nocase "*debug_mem_slave" "$breakSlave" ] } && { $break_addr != -1 } && {!$setting_breakslaveoveride} && { $setting_oci_version == 1 }] } {
        send_message error "The instruction_master must be connected to the debug_mem_slave."
    }

    # Warn user if choosing enhanced interrupt without shadow register sets
    if { "$impl" != "Tiny" && "$setting_interruptControllerType" == "External" && "$setting_shadowRegisterSets" == "0" } {
        send_message warning "Altera HAL does not support an external interrupt controller and 0 shadow register sets."
    }

    # Warn user if not choosing optimal value of shadow register sets for the chosen device family
    # only validate if shadow register sets setting is enabled
    # TODO: optimal 7 for M9K and 3 for M4K

    # Update tlb ptr sz if needed
    # TODO: 8 for M9K and 7 fo else
   
    if { [ string match -nocase "HardCopy*" "$device_family_name" ] && [ expr {"$multiplierType" == "mul_slow32"} ] } {
        send_message error "Multiplier selected is not compatible with selected device and design type"
    }
    
    # Error case exists if avalonDebugPortPresent selected when NoDebug
    #if { !$debug_level } {
    #	    send_message error "No Debugger available. Enable Debugger or disable Avalon Debug Port"
    #}
    
    # Special case for dcache_bursts string type    
    if { ! [ expr { "$dcache_bursts_derived" == "true" } || { "$dcache_bursts_derived" == "false" } ] } {
        set small_db [string tolower $dcache_bursts_derived]
        if { [ expr { "$small_db" == "none" } || { "$small_db" == "0" } || { "$small_db" == "false" } || { "$small_db" == "" } || { "$small_db" == "disable" }] } {
            set_parameter_value dcache_bursts_derived false
        } else {
            set_parameter_value dcache_bursts_derived true
        }        
    }

    # ASIC support for translate on/off
    set local_asic_enabled [ proc_get_boolean_parameter setting_asic_enabled ]
    set local_asic_synopsys_translate [ proc_get_boolean_parameter setting_asic_synopsys_translate_on_off ]

    if {$local_asic_enabled && $local_asic_synopsys_translate} {
        set_parameter_value  translate_on  { "synopsys translate_on"  }
        set_parameter_value  translate_off { "synopsys translate_off" }
    }
    
    if { $export_vectors } {
        send_message info "Please ensure that reset/exception vector conduits are driven"
    }
    
    # Setting derived parameter here for the bypass dcache
    # Exclusively true for I/O region
    set address_width [ get_parameter_value dataAddrWidth ]
    set ioregionbase [ get_parameter_value io_regionbase ]
    set ioregionsize [ get_parameter_value io_regionsize ]
    set dcache_size_derived [ get_parameter_value dcache_size_derived ]
    set setting_support31bitdcachebypass [ proc_get_boolean_parameter setting_support31bitdcachebypass ]

    set avail_data_slaves    [ proc_get_address_map_slaves_name dataSlaveMapParam ]
    set number_of_data_slaves [ llength $avail_data_slaves ]   
    # we assume there is only one debug slave interface per Nios instance
    set only_debug_slaves [ expr ($number_of_data_slaves == 1) && [ string match "*debug_mem_slave" $avail_data_slaves ] ]
    set any_data_slaves [ expr ( $number_of_data_slaves > 0 ) && (!$only_debug_slaves) ]

    if { $mmu_enabled || "$impl" != "Fast"} {
        set_parameter_value  setting_ioregionBypassDCache   false
        set_parameter_value  setting_bit31BypassDCache      false
    } else {
     
        if { "$ioregionsize" == "0" } {
            set_parameter_value  setting_ioregionBypassDCache  false        
        } else {
            set_parameter_value  setting_ioregionBypassDCache  true
            # check to ensure that the total I/O offset + size does not overflow above 2>32 - 1
            set io_regionhex [ proc_num2hex [expr {$ioregionsize - 1} ] ]
            set io_region_width [ proc_num2sz $ioregionsize ]
        
            # Only allow I/O region to be half of address width. Otherwise, the data cache
            # would always be bypassed so what's the point of having it in the first place.
            if { (($io_region_width >= $address_width ) || (($io_region_width == 0) && ($address_width != 32))) && $any_data_slaves } {
                send_message error "Peripheral region size too large (exceeds 1/2 the address size of slaves connected to the data_master)"
            }
            # Make sure that the I/O address region is aligned
            proc_validate_address_alignment $ioregionbase $io_regionhex "I/O address region base address is not aligned to its size"
        }

        if { ($dcache_size_derived > 0) && $setting_support31bitdcachebypass } {
            set_parameter_value  setting_bit31BypassDCache  true
        }
    }
    
    # check to make sure that the base address aligned base on the size
    set master_addr_map                                         [ get_parameter_value master_addr_map                                 ]
    set instruction_master_paddr_base                           [ proc_num2hex [ get_parameter_value instruction_master_paddr_base                   ]]
    set instruction_master_paddr_sizehex                        [ proc_num2hex [expr [get_parameter_value instruction_master_paddr_size] - 1 ] ]
    set flash_instruction_master_paddr_base                     [ proc_num2hex [ get_parameter_value flash_instruction_master_paddr_base             ]]
    set flash_instruction_master_paddr_sizehex                  [ proc_num2hex [expr [get_parameter_value flash_instruction_master_paddr_size             ] - 1 ] ]
    set data_master_paddr_base                                  [ proc_num2hex [ get_parameter_value data_master_paddr_base                          ]]
    set data_master_paddr_size                                  [ proc_num2hex [expr [get_parameter_value data_master_paddr_size                         ] - 1 ] ]
    set tightly_coupled_instruction_master_0_paddr_base         [ proc_num2hex [ get_parameter_value tightly_coupled_instruction_master_0_paddr_base ]]
    set tightly_coupled_instruction_master_0_paddr_sizehex      [ proc_num2hex [expr [get_parameter_value tightly_coupled_instruction_master_0_paddr_size ] - 1 ] ]
    set tightly_coupled_instruction_master_1_paddr_base         [ proc_num2hex [ get_parameter_value tightly_coupled_instruction_master_1_paddr_base ]]
    set tightly_coupled_instruction_master_1_paddr_sizehex      [ proc_num2hex [expr [get_parameter_value tightly_coupled_instruction_master_1_paddr_size ] - 1 ] ]
    set tightly_coupled_instruction_master_2_paddr_base         [ proc_num2hex [ get_parameter_value tightly_coupled_instruction_master_2_paddr_base ]]
    set tightly_coupled_instruction_master_2_paddr_sizehex      [ proc_num2hex [expr [get_parameter_value tightly_coupled_instruction_master_2_paddr_size ] - 1 ] ]
    set tightly_coupled_instruction_master_3_paddr_base         [ proc_num2hex [ get_parameter_value tightly_coupled_instruction_master_3_paddr_base ]]
    set tightly_coupled_instruction_master_3_paddr_sizehex      [ proc_num2hex [expr [get_parameter_value tightly_coupled_instruction_master_3_paddr_size ] - 1 ] ]
    set tightly_coupled_data_master_0_paddr_base                [ proc_num2hex [ get_parameter_value tightly_coupled_data_master_0_paddr_base        ]]
    set tightly_coupled_data_master_0_paddr_sizehex             [ proc_num2hex [expr [get_parameter_value tightly_coupled_data_master_0_paddr_size        ] - 1 ] ]
    set tightly_coupled_data_master_1_paddr_base                [ proc_num2hex [ get_parameter_value tightly_coupled_data_master_1_paddr_base        ]]
    set tightly_coupled_data_master_1_paddr_sizehex             [ proc_num2hex [expr [get_parameter_value tightly_coupled_data_master_1_paddr_size        ] - 1 ] ]
    set tightly_coupled_data_master_2_paddr_base                [ proc_num2hex [ get_parameter_value tightly_coupled_data_master_2_paddr_base        ]]
    set tightly_coupled_data_master_2_paddr_sizehex             [ proc_num2hex [expr [get_parameter_value tightly_coupled_data_master_2_paddr_size        ] - 1 ] ]
    set tightly_coupled_data_master_3_paddr_base                [ proc_num2hex [ get_parameter_value tightly_coupled_data_master_3_paddr_base        ]]
    set tightly_coupled_data_master_3_paddr_sizehex             [ proc_num2hex [expr [get_parameter_value tightly_coupled_data_master_3_paddr_size        ] - 1 ] ]
    set instruction_master_high_performance_paddr_base          [ proc_num2hex [ expr [ get_parameter_value instruction_master_high_performance_paddr_base  ] & 0xffffffff ] ]
    set instruction_master_high_performance_paddr_sizehex       [ proc_num2hex [expr [get_parameter_value instruction_master_high_performance_paddr_size  ] - 1 ] ]
    set data_master_high_performance_paddr_base                 [ proc_num2hex [ expr [ get_parameter_value data_master_high_performance_paddr_base         ] & 0xffffffff ] ]
    set data_master_high_performance_paddr_sizehex              [ proc_num2hex [expr [get_parameter_value data_master_high_performance_paddr_size         ] - 1 ] ]
    
    set tcim_num    [ get_parameter_value icache_numTCIM ]
    set tcdm_num    [ get_parameter_value dcache_numTCDM ]

    if { $master_addr_map } {
        if { [get_parameter_value instruction_master_paddr_size ] > 0} {
            proc_validate_address_alignment $instruction_master_paddr_base $instruction_master_paddr_sizehex "Instruction Master address region base address is not aligned to its size"
        }
        if { [get_parameter_value flash_instruction_master_paddr_size ] > 0 && $impl == "Fast" } {
            proc_validate_address_alignment $flash_instruction_master_paddr_base $flash_instruction_master_paddr_sizehex " Flash Instruction Master address region base address is not aligned to its size"
        }
        if { [get_parameter_value data_master_paddr_size ] > 0} {
            proc_validate_address_alignment $data_master_paddr_base $data_master_paddr_size " Data Master address region base address is not aligned to its size"
        }
        if { [get_parameter_value tightly_coupled_instruction_master_0_paddr_size ] > 0 && $tcim_num > 0 && $impl != "Tiny" } {
            proc_validate_address_alignment $tightly_coupled_instruction_master_0_paddr_base $tightly_coupled_instruction_master_0_paddr_sizehex "Tightly Coupled Instruction Master 0 address region base address is not aligned to its size"
        }
        if { [get_parameter_value tightly_coupled_instruction_master_1_paddr_size ] > 0 && $tcim_num > 1 && $impl != "Tiny" } {
            proc_validate_address_alignment $tightly_coupled_instruction_master_1_paddr_base $tightly_coupled_instruction_master_1_paddr_sizehex "Tightly Coupled Instruction Master 1 address region base address is not aligned to its size"
        }
        if { [get_parameter_value tightly_coupled_instruction_master_2_paddr_size ] > 0 && $tcim_num > 2 && $impl != "Tiny" } {
            proc_validate_address_alignment $tightly_coupled_instruction_master_2_paddr_base $tightly_coupled_instruction_master_2_paddr_sizehex "Tightly Coupled Instruction Master 2 address region base address is not aligned to its size"
        }
        if { [get_parameter_value tightly_coupled_instruction_master_3_paddr_size ] > 0 && $tcim_num > 3 && $impl != "Tiny" } {
            proc_validate_address_alignment $tightly_coupled_instruction_master_3_paddr_base $tightly_coupled_instruction_master_3_paddr_sizehex "Tightly Coupled Instruction Master 3 address region base address is not aligned to its size"
        }
        if { [get_parameter_value tightly_coupled_data_master_0_paddr_size ] > 0 && $tcdm_num > 0 && $impl != "Tiny" } {
        proc_validate_address_alignment $tightly_coupled_data_master_0_paddr_base $tightly_coupled_data_master_0_paddr_sizehex "Tightly Coupled Data Master 0 address region base address is not aligned to its size"
        }
        if { [get_parameter_value tightly_coupled_data_master_1_paddr_size ] > 0 && $tcdm_num > 1 && $impl != "Tiny" } {
        proc_validate_address_alignment $tightly_coupled_data_master_1_paddr_base $tightly_coupled_data_master_1_paddr_sizehex "Tightly Coupled Data Master 1 address region base address is not aligned to its size"
        }
        if { [get_parameter_value tightly_coupled_data_master_2_paddr_size ] > 0 && $tcdm_num > 2 && $impl != "Tiny" } {
        proc_validate_address_alignment $tightly_coupled_data_master_2_paddr_base $tightly_coupled_data_master_2_paddr_sizehex "Tightly Coupled Data Master 2 address region base address is not aligned to its size"
        }
        if { [get_parameter_value tightly_coupled_data_master_3_paddr_size ] > 0 && $tcdm_num > 3 && $impl != "Tiny" } {
        proc_validate_address_alignment $tightly_coupled_data_master_3_paddr_base $tightly_coupled_data_master_3_paddr_sizehex "Tightly Coupled Data Master 3 address region base address is not aligned to its size"
        }
        if { [get_parameter_value data_master_paddr_size ] > 0 && $impl == "Small" } {
            proc_validate_address_alignment $instruction_master_high_performance_paddr_base $instruction_master_high_performance_paddr_sizehex "High Performance Instruction Master address region base address is not aligned to its size"
        }
        if { [get_parameter_value data_master_paddr_size ] > 0 && $impl == "Small" } {
            proc_validate_address_alignment $data_master_high_performance_paddr_base $data_master_high_performance_paddr_sizehex "High Performance Data Master address region base address is not aligned to its size"
        }
    }
    
    # Add validation that the system information provided for each master is not connected directly to any slave / bridge
    # Reason: This will break Nios II RTL generation due to dependency on the Master interface "Address Map"
    # also prevents user from using TCMs/flash accelerators without mapping it to any slaves
    set instAddrWidth                               [ get_parameter_value instAddrWidth                             ]
    set faAddrWidth                                 [ get_parameter_value faAddrWidth                               ]
    set dataAddrWidth                               [ get_parameter_value dataAddrWidth                             ]
    set tightlyCoupledDataMaster0AddrWidth          [ get_parameter_value tightlyCoupledDataMaster0AddrWidth        ]
    set tightlyCoupledDataMaster1AddrWidth          [ get_parameter_value tightlyCoupledDataMaster1AddrWidth        ]
    set tightlyCoupledDataMaster2AddrWidth          [ get_parameter_value tightlyCoupledDataMaster2AddrWidth        ]
    set tightlyCoupledDataMaster3AddrWidth          [ get_parameter_value tightlyCoupledDataMaster3AddrWidth        ]
    set tightlyCoupledInstructionMaster0AddrWidth   [ get_parameter_value tightlyCoupledInstructionMaster0AddrWidth ]
    set tightlyCoupledInstructionMaster1AddrWidth   [ get_parameter_value tightlyCoupledInstructionMaster1AddrWidth ]
    set tightlyCoupledInstructionMaster2AddrWidth   [ get_parameter_value tightlyCoupledInstructionMaster2AddrWidth ]
    set tightlyCoupledInstructionMaster3AddrWidth   [ get_parameter_value tightlyCoupledInstructionMaster3AddrWidth ]
    set dataMasterHighPerformanceAddrWidth          [ get_parameter_value dataMasterHighPerformanceAddrWidth        ]
    set instructionMasterHighPerformanceAddrWidth   [ get_parameter_value instructionMasterHighPerformanceAddrWidth ]
    set instSlave                           [ proc_get_address_map_slaves_name instSlaveMapParam                        ]
    set faSlave                             [ proc_get_address_map_slaves_name faSlaveMapParam                          ]
    set dataSlave                           [ proc_get_address_map_slaves_name dataSlaveMapParam                        ]
    set tightlyCoupledDataMaster0           [ proc_get_address_map_slaves_name tightlyCoupledDataMaster0MapParam        ]
    set tightlyCoupledDataMaster1           [ proc_get_address_map_slaves_name tightlyCoupledDataMaster1MapParam        ]
    set tightlyCoupledDataMaster2           [ proc_get_address_map_slaves_name tightlyCoupledDataMaster2MapParam        ]
    set tightlyCoupledDataMaster3           [ proc_get_address_map_slaves_name tightlyCoupledDataMaster3MapParam        ]
    set tightlyCoupledInstructionMaster0    [ proc_get_address_map_slaves_name tightlyCoupledInstructionMaster0MapParam ]
    set tightlyCoupledInstructionMaster1    [ proc_get_address_map_slaves_name tightlyCoupledInstructionMaster1MapParam ]
    set tightlyCoupledInstructionMaster2    [ proc_get_address_map_slaves_name tightlyCoupledInstructionMaster2MapParam ]
    set tightlyCoupledInstructionMaster3    [ proc_get_address_map_slaves_name tightlyCoupledInstructionMaster3MapParam ]
    set dataMasterHighPerformance           [ proc_get_address_map_slaves_name dataMasterHighPerformanceMapParam        ]
    set instructionMasterHighPerformance    [ proc_get_address_map_slaves_name instructionMasterHighPerformanceMapParam ]

    # if set master base/size is selected, ignore the slave checking for each master
    # 1 is the default width for unconnected masters.
    if { !$master_addr_map } {
    	# checks to make sure that Nios is connected to a valid memory for running software codes
    	if { $instAddrWidth == 1 } {
    		# if tiny give error directly, no other instruction master support
    		if { $impl == "Tiny" } {
    			send_message error "Nios is not connected to any instruction memory. Please connect the Instruction Master to a memory."
    		# if fast give error if tcim not enable
    		} elseif { $impl == "Fast" && $tcim_num == 0 && $fa_cache_linesize == 0 } {
    			send_message error "Nios is not connected to any instruction memory. Please connect the Instruction Master to a memory or enable Tightly Coupled Instruction Master/Flash Accelerator."
    		# if small give error if tcim/high performance not enable
    		} elseif { $impl == "Small" && $tcim_num == 0 && $instructionMasterHighPerformanceAddrWidth == 1 } {
    			send_message error "Nios is not connected to any instruction memory. Please connect the Instruction Master/High Performance Instruction Master to a memory or enable Tightly Coupled Instruction Master."
    		}
        }
        if { $instAddrWidth > 1 && $instSlave == "" } {
            send_message error "Instruction Master has no valid slave or is connected to a bridge"
        }
        if { $dataAddrWidth > 1 && $dataSlave == "" } {
            send_message error "Data Master has no valid slave or is connected to a bridge"
        }
        if { ( $faAddrWidth > 1 || $fa_cache_linesize > 0 ) && $faSlave == "" && $impl == "Fast" } {
            send_message error "Flash Instruction Master has no valid slave or is connected to a bridge"
        }
        if { $instructionMasterHighPerformanceAddrWidth > 1 && $instructionMasterHighPerformance == "" && $impl == "Small" } {
            send_message error "High Performance Instruction Master has no valid slave or is connected to a bridge"
        }
        if { $dataMasterHighPerformanceAddrWidth > 1 && $dataMasterHighPerformance == "" && $impl == "Small" } {
            send_message error "High Performance Data Master has no valid slave or is connected to a bridge"
        }
        if { ($tightlyCoupledDataMaster0AddrWidth > 1 || $tcdm_num > 0) && $tightlyCoupledDataMaster0 == "" && $impl != "Tiny" } {
            send_message error "Tightly Coupled Data Master 0 has no valid slave or is connected to a bridge"                 
        }                                                                                                                     
        if { ($tightlyCoupledDataMaster1AddrWidth > 1 || $tcdm_num > 1) && $tightlyCoupledDataMaster1 == "" && $impl != "Tiny" } {
            send_message error "Tightly Coupled Data Master 1 has no valid slave or is connected to a bridge"                 
        }                                                                                                                     
        if { ($tightlyCoupledDataMaster2AddrWidth > 1 || $tcdm_num > 2) && $tightlyCoupledDataMaster2 == "" && $impl != "Tiny" } {
            send_message error "Tightly Coupled Data Master 2 has no valid slave or is connected to a bridge"
        }
        if { ($tightlyCoupledDataMaster3AddrWidth > 1 || $tcdm_num > 3) && $tightlyCoupledDataMaster3 == "" && $impl != "Tiny" } {
            send_message error "Tightly Coupled Data Master 3 has no valid slave or is connected to a bridge"
        }
        if { ($tightlyCoupledInstructionMaster0AddrWidth > 1 || $tcim_num > 0) && $tightlyCoupledInstructionMaster0 == "" && $impl != "Tiny" } {
            send_message error "Tightly Coupled Instruction Master 0 has no valid slave or is connected to a bridge"
        }
        if { ($tightlyCoupledInstructionMaster1AddrWidth > 1 || $tcim_num > 1) && $tightlyCoupledInstructionMaster1 == "" && $impl != "Tiny" } {
            send_message error "Tightly Coupled Instruction Master 1 has no valid slave or is connected to a bridge"
        }
        if { ($tightlyCoupledInstructionMaster2AddrWidth > 1 || $tcim_num > 2) && $tightlyCoupledInstructionMaster2 == "" && $impl != "Tiny" } {
            send_message error "Tightly Coupled Instruction Master 2 has no valid slave or is connected to a bridge"                        
        }                                                                                                                                   
        if { ($tightlyCoupledInstructionMaster3AddrWidth > 1 || $tcim_num > 3) && $tightlyCoupledInstructionMaster3 == "" && $impl != "Tiny" } {
            send_message error "Tightly Coupled Instruction Master 3 has no valid slave or is connected to a bridge"
        }
    }
}

proc func_address_width_to_io_region_max_size {address_width} {
    switch $address_width {
        13 { return "4 KBytes" }
        14 { return "8 KBytes" }
        15 { return "16 KBytes" }
        16 { return "32 KBytes" }
        17 { return "64 KBytes" }
        18 { return "128 KBytes" }
        19 { return "256 KBytes" }
        20 { return "512 KBytes" }
        21 { return "1 MByte" }
        22 { return "2 MBytes" }
        23 { return "4 MBytes" }
        24 { return "8 MBytes" }
        25 { return "16 MBytes" }
        26 { return "32 MBytes" }
        27 { return "64 MBytes" }
        28 { return "128 MBytes" }
        29 { return "256 MBytes" }
        30 { return "512 MBytes" }
        31 { return "1 GBytes" }
        32 { return "2 GBytes" }
        default { return "Unsupported" }
    }
}

# Some smart logic to auto select break slave.
#proc updateDebugSlave {} {
#    # Automatically select the JTAG debug slave if debugger is enabled
#    if { "$debug_level" == "NoDebug" } {
#        set_parameter debug_port_present "0"
#    } else {
#        set_parameter debug_port_present "1"
#        foreach inst_slave $inst_slave_address_map_dec {
#            array set inst_slave_info $inst_slave
#            set inst_slave_name "$inst_slave_info(name)"
#            if { [ string match "$break_slave_interface" "$inst_slave_name" ] } {
#                foreach data_slave $data_slave_address_map_dec {
#                    array set data_slave_info $data_slave
#                    if { [ string match "$inst_slave_name" "$data_slave_info(name)" ] } {
#                        set found_break_slave   "1"
#                        set break_slave_value   "$inst_slave_name"
#                        set break_addr_value    "[ proc_num2unsigned [ expr $data_slave_info(start) + $break_slave_offset ]]"
#                        break
#                    }
#                }
#                if { "$found_break_slave" == "1" } {
#                    break
#                }
#            }
#        }
#    }
#}

proc proc_get_final_tlb_ptr_size {} {
    # Update tlb ptr sz if needed
    if { [ proc_get_boolean_parameter mmu_autoAssignTlbPtrSz ] } {
        if { [ is_device_feature_exist "M9K_MEMORY" ] } {
            return 8
        } else {
            return 7
        }
    } else {
        return [ get_parameter_value mmu_tlbPtrSz ]
    }
}


proc sub_validate_update_module_embeddedsw_cmacros {} {
    set impl                        [ get_parameter_value impl ]
    set shiftype                    [ get_parameter_value shifterType ]
    set icache_size                 [ get_parameter_value icache_size ]
    set dcache_size_derived         [ get_parameter_value dcache_size_derived ]
    set dcache_lineSize_derived     [ get_parameter_value dcache_lineSize_derived ]
    set mmu_enabled                 [ proc_get_mmu_present ]
    set resetAddress                [ proc_num2hex [ proc_get_reset_addr ] ]
    set excAddress                  [ proc_num2hex [ proc_get_general_exception_addr ] ]
    set breakAddress                [ proc_num2hex [ proc_get_break_addr ] ]
    set tlb_miss_addr               [ proc_num2hex [ proc_get_fast_tlb_miss_exception_addr ] ]
    set finalTlbPtrSz               [ proc_get_final_tlb_ptr_size ]
    set debug_enabled               [ proc_get_boolean_parameter debug_enabled ]
    set setting_allow_break_inst    [ proc_get_boolean_parameter setting_allow_break_inst ]

    # Start adding C Macro

    if { [ get_parameter_value cpuArchRev ] == 2 } {
        proc_set_module_embeddedsw_cmacro_assignment "CPU_ARCH_NIOS2_R2" ""
    } else {
        proc_set_module_embeddedsw_cmacro_assignment "CPU_ARCH_NIOS2_R1" ""
    }

    proc_set_module_embeddedsw_cmacro_assignment "CPU_IMPLEMENTATION"           "\"[ string tolower $impl ]\""
    proc_set_module_embeddedsw_cmacro_assignment "BIG_ENDIAN"                   "[ proc_get_boolean_parameter setting_bigEndian ]"
    proc_set_module_embeddedsw_cmacro_assignment "CPU_FREQ"                     "[ proc_num2unsigned [ get_parameter_value clockFrequency ]]u"

    # icache line size defaults to 32 / 2^5
    # these values should be set to 0 if icache is not enabled
    if { "$icache_size" == "0" || "$impl" != "Fast" } {
        proc_set_module_embeddedsw_cmacro_assignment "ICACHE_LINE_SIZE"             0
        proc_set_module_embeddedsw_cmacro_assignment "ICACHE_LINE_SIZE_LOG2"        0
        proc_set_module_embeddedsw_cmacro_assignment "ICACHE_SIZE"                  0
    } else {
        proc_set_module_embeddedsw_cmacro_assignment "ICACHE_LINE_SIZE"             32
        proc_set_module_embeddedsw_cmacro_assignment "ICACHE_LINE_SIZE_LOG2"        5
        proc_set_module_embeddedsw_cmacro_assignment "ICACHE_SIZE"                  $icache_size

    }

    set fa_cache_line [ get_parameter_value fa_cache_line ]
    set fa_cache_linesize [ get_parameter_value fa_cache_linesize ]
    if { "$fa_cache_linesize" == "0" || "$impl" != "Fast" || $mmu_enabled } {
        proc_set_module_embeddedsw_cmacro_assignment "FLASH_ACCELERATOR_LINE_SIZE"             0
        proc_set_module_embeddedsw_cmacro_assignment "FLASH_ACCELERATOR_LINES"                 0
    } else {
        proc_set_module_embeddedsw_cmacro_assignment "FLASH_ACCELERATOR_LINE_SIZE"             $fa_cache_linesize
        proc_set_module_embeddedsw_cmacro_assignment "FLASH_ACCELERATOR_LINES"                 $fa_cache_line

    }

    # this seems ugly somehow...
    if { "$dcache_size_derived" == "0" || "$impl" != "Fast" } {
        proc_set_module_embeddedsw_cmacro_assignment "DCACHE_LINE_SIZE"             0
        proc_set_module_embeddedsw_cmacro_assignment "DCACHE_LINE_SIZE_LOG2"        0
        proc_set_module_embeddedsw_cmacro_assignment "DCACHE_SIZE"                  0
    } else {
        proc_set_module_embeddedsw_cmacro_assignment "DCACHE_LINE_SIZE"             $dcache_lineSize_derived
        proc_set_module_embeddedsw_cmacro_assignment "DCACHE_LINE_SIZE_LOG2"        [ proc_num2sz $dcache_lineSize_derived ]
        proc_set_module_embeddedsw_cmacro_assignment "DCACHE_SIZE"                  $dcache_size_derived
        proc_set_module_embeddedsw_cmacro_assignment "INITDA_SUPPORTED"  ""
        set_module_assignment {embeddedsw.dts.params.altr,has-initda} 1
    }

    proc_set_module_embeddedsw_cmacro_assignment "FLUSHDA_SUPPORTED"            ""
    proc_set_module_embeddedsw_cmacro_assignment "HAS_JMPI_INSTRUCTION"         ""

    if { [ proc_get_bmx_present ] } {
        proc_set_module_embeddedsw_cmacro_assignment    "BMX_PRESENT"      ""
    }

    if { [ proc_get_cdx_present ] } {
        proc_set_module_embeddedsw_cmacro_assignment    "CDX_PRESENT"      ""
    }
    
    if { [ proc_get_mpx_present ] } {
        proc_set_module_embeddedsw_cmacro_assignment    "MPX_PRESENT"      ""
    }

    set cpu_arch_rev [ get_parameter_value cpuArchRev ]

    # mmu enabled?
    if { $mmu_enabled } {

        # Add the entries into system.h
        proc_set_module_embeddedsw_cmacro_assignment    "KERNEL_REGION_BASE"      "0xc0000000"
        proc_set_module_embeddedsw_cmacro_assignment    "IO_REGION_BASE"          "0xe0000000"
        proc_set_module_embeddedsw_cmacro_assignment    "KERNEL_MMU_REGION_BASE"  "0x80000000"
        proc_set_module_embeddedsw_cmacro_assignment    "USER_REGION_BASE"        "0x00000000"


        # Few other MMU parameter to send to system.h for reference
        proc_set_module_embeddedsw_cmacro_assignment    "MMU_PRESENT" ""
        proc_set_module_embeddedsw_cmacro_assignment    "PROCESS_ID_NUM_BITS"     [ get_parameter_value mmu_processIDNumBits ]
        proc_set_module_embeddedsw_cmacro_assignment    "TLB_NUM_WAYS"            [ get_parameter_value mmu_tlbNumWays ]
        proc_set_module_embeddedsw_cmacro_assignment    "TLB_NUM_WAYS_LOG2"       [ proc_num2sz [ get_parameter_value mmu_tlbNumWays ] ]
        proc_set_module_embeddedsw_cmacro_assignment    "TLB_PTR_SZ"              $finalTlbPtrSz
        proc_set_module_embeddedsw_cmacro_assignment    "TLB_NUM_ENTRIES"         [ expr { 1 << $finalTlbPtrSz } ]

        # If we have MMU, get the their kernel address
        proc_set_module_embeddedsw_cmacro_assignment    "FAST_TLB_MISS_EXCEPTION_ADDR"              "[ proc_num2hex [ expr { $tlb_miss_addr | 0xc0000000 } ] ]"
        proc_set_module_embeddedsw_cmacro_assignment    "EXCEPTION_ADDR"                            "[ proc_num2hex [ expr { $excAddress    | 0xc0000000 } ] ]"
        proc_set_module_embeddedsw_cmacro_assignment    "RESET_ADDR"                                "[ proc_num2hex [ expr { $resetAddress  | 0xc0000000 } ] ]"
        if { $debug_enabled || $setting_allow_break_inst || $cpu_arch_rev == 1 } {
            proc_set_module_embeddedsw_cmacro_assignment    "BREAK_ADDR"                            "[ proc_num2hex [ expr { $breakAddress  | 0xc0000000 } ] ]"
        }
    } else {
        # If we don't have MMU, simply use the addresses
        proc_set_module_embeddedsw_cmacro_assignment    "EXCEPTION_ADDR"                            "$excAddress"
        proc_set_module_embeddedsw_cmacro_assignment    "RESET_ADDR"                                "$resetAddress"
        if { $debug_enabled || $setting_allow_break_inst || $cpu_arch_rev == 1 } {
            proc_set_module_embeddedsw_cmacro_assignment    "BREAK_ADDR"                            "$breakAddress"
        }
    }

    set mpu_enable [proc_get_mpu_present]
    # mpu enabled?
    if { $mpu_enable } {
        proc_set_module_embeddedsw_cmacro_assignment "MPU_PRESENT" ""

        if { [ proc_get_boolean_parameter mpu_useLimit ] } {
            proc_set_module_embeddedsw_cmacro_assignment  "MPU_REGION_USES_LIMIT" ""
        }
        set mpu_min_inst_region_size_log2 [ get_parameter_value mpu_minInstRegionSize]
        set mpu_min_data_region_size_log2 [ get_parameter_value mpu_minDataRegionSize]

        proc_set_module_embeddedsw_cmacro_assignment   "MPU_MIN_DATA_REGION_SIZE_LOG2"     $mpu_min_data_region_size_log2
        proc_set_module_embeddedsw_cmacro_assignment   "MPU_MIN_DATA_REGION_SIZE"          [ expr { 1 << $mpu_min_data_region_size_log2 } ]
        proc_set_module_embeddedsw_cmacro_assignment   "MPU_MIN_INST_REGION_SIZE_LOG2"     $mpu_min_inst_region_size_log2
        proc_set_module_embeddedsw_cmacro_assignment   "MPU_MIN_INST_REGION_SIZE"          [ expr { 1 << $mpu_min_inst_region_size_log2 } ]
        proc_set_module_embeddedsw_cmacro_assignment   "MPU_NUM_DATA_REGIONS"              [ proc_num2unsigned [ get_parameter_value mpu_numOfDataRegion ]]
        proc_set_module_embeddedsw_cmacro_assignment   "MPU_NUM_INST_REGIONS"              [ proc_num2unsigned [ get_parameter_value mpu_numOfInstRegion ]]
    }

    # If break address and reset addresses are not same, then has_debug_stub
    if { [ expr { $breakAddress != $resetAddress } ] } {
        proc_set_module_embeddedsw_cmacro_assignment  "HAS_DEBUG_STUB"  ""
    }

    set debug_level    [ proc_get_boolean_parameter debug_enabled ]
    set oci_version    [ get_parameter_value setting_oci_version ]
    # If debug level not NoDebug, then oci core is included
    proc_set_module_embeddedsw_cmacro_assignment "HAS_DEBUG_CORE" $debug_level
    proc_set_module_embeddedsw_cmacro_assignment "OCI_VERSION" $oci_version

    # Always turned on regardless of Core type
    proc_set_module_embeddedsw_cmacro_assignment  "HAS_ILLEGAL_INSTRUCTION_EXCEPTION" ""

    # We're looking for Precise Illegal Mem Access Exception
    if { [ proc_get_europa_illegal_mem_exc ] } {
        proc_set_module_embeddedsw_cmacro_assignment  "HAS_ILLEGAL_MEMORY_ACCESS_EXCEPTION" ""
    }

    # Division error is enabled when the divider hardware is available
    if { [ proc_get_hardware_divide_present ] } {
        proc_set_module_embeddedsw_cmacro_assignment  "HAS_DIVISION_ERROR_EXCEPTION" ""
    }

    # Extra exception info is always present except for Nios II/e.
    if { [ proc_not_tiny_core_info ] } {
        proc_set_module_embeddedsw_cmacro_assignment  "HAS_EXTRA_EXCEPTION_INFO" ""
    }

    # As of yet, we don't know how to deal with CPU ID
    set cpu_id [ get_parameter_value cpuID ]
    proc_set_module_embeddedsw_cmacro_assignment   "CPU_ID_SIZE" [ proc_num2sz $cpu_id ]
    proc_set_module_embeddedsw_cmacro_assignment   "CPU_ID_VALUE" [ proc_num2hex $cpu_id ]

    # Adding System.h content for hardware multiplier and divider
    # If the core not fast, they're all disabled
    if { [ expr { "$impl" != "Fast" } ] } {
        proc_set_module_embeddedsw_cmacro_assignment "HARDWARE_MULTIPLY_PRESENT"    0
        proc_set_module_embeddedsw_cmacro_assignment "HARDWARE_MULX_PRESENT"        0
        proc_set_module_embeddedsw_cmacro_assignment "HARDWARE_DIVIDE_PRESENT"      0
    } else {
        # Check the multiplier
        if { [ proc_get_hardware_multiply_present ] } {
            set mul_type [ get_parameter_value multiplierType ]
            
            proc_set_module_embeddedsw_cmacro_assignment "HARDWARE_MULTIPLY_PRESENT" 1

            # Need to check the mulx, which is a derived setting from the multiplier type
            # RULES: mul_fast64 means MULX support
            if { "$mul_type" == "mul_fast64" } {
                proc_set_module_embeddedsw_cmacro_assignment "HARDWARE_MULX_PRESENT" 1
            } else {
                proc_set_module_embeddedsw_cmacro_assignment "HARDWARE_MULX_PRESENT" 0
            }
        } else {
            proc_set_module_embeddedsw_cmacro_assignment "HARDWARE_MULTIPLY_PRESENT"    0
            proc_set_module_embeddedsw_cmacro_assignment "HARDWARE_MULX_PRESENT"        0
        }

        # Check the divider
        if { [ proc_get_hardware_divide_present ] } {
            proc_set_module_embeddedsw_cmacro_assignment  "HARDWARE_DIVIDE_PRESENT" 1
        } else {
            proc_set_module_embeddedsw_cmacro_assignment  "HARDWARE_DIVIDE_PRESENT" 0
        }

    }

    # Add information about instruction and data address width
    proc_set_module_embeddedsw_cmacro_assignment   "INST_ADDR_WIDTH" [ proc_get_cmacro_inst_addr_width ]
    proc_set_module_embeddedsw_cmacro_assignment   "DATA_ADDR_WIDTH" [ proc_get_cmacro_data_addr_width ]

    # Adding System.h content for eic and shadow register sets support
    # If the core is not fast, they're all disabled
    set setting_interruptControllerType             [ get_parameter_value setting_interruptControllerType ]
    set ecc_present                                 [ proc_get_boolean_parameter setting_ecc_present ]
    set ecc_sim_test_ports                          [ proc_get_boolean_parameter setting_ecc_sim_test_ports ]

    if { [ expr { "$impl" != "Tiny" } ] } {
        if { [ expr { "$setting_interruptControllerType" == "External" } ] } {
            proc_set_module_embeddedsw_cmacro_assignment  "EIC_PRESENT" ""
        }
        proc_set_module_embeddedsw_cmacro_assignment   "NUM_OF_SHADOW_REG_SETS" [ get_parameter_value setting_shadowRegisterSets ]
        
        # Adding a embeddedsw cmacro for ECC present
        if { $ecc_present } {
            proc_set_module_embeddedsw_cmacro_assignment  "ECC_PRESENT" ""

            if { $ecc_sim_test_ports } {
                proc_set_module_embeddedsw_cmacro_assignment  "ECC_RF_SIZE" "39"
                proc_set_module_embeddedsw_cmacro_assignment  "ECC_DCACHE_DATA_SIZE" "39"
                proc_set_module_embeddedsw_cmacro_assignment  "ECC_ICACHE_DATA_SIZE" "39"
                
                # Only define when TCMs are present
                set tcdm_num                 [ get_parameter_value dcache_numTCDM ]
                foreach i {0 1 2 3} {
                    if { $i < $tcdm_num } {
                        proc_set_module_embeddedsw_cmacro_assignment  "ECC_DTCM${i}_SIZE" "39"
                    }
                }
                # TLB, Data/Inst Cache Tag RAM
                set ic_tag_data_sz           [ proc_calculate_ic_tag_data_size ]
                set ic_tag_ecc_bits          [ proc_calculate_ecc_bits $ic_tag_data_sz ]
                set ic_tag_ecc_sz            [ expr { $ic_tag_ecc_bits + $ic_tag_data_sz } ]
                proc_set_module_embeddedsw_cmacro_assignment  "ECC_ICACHE_TAG_SIZE" $ic_tag_ecc_sz
                
                set dc_tag_data_sz           [ proc_calculate_dc_tag_data_size ]
                set dc_tag_ecc_bits          [ proc_calculate_ecc_bits $dc_tag_data_sz ]
                set dc_tag_ecc_sz            [ expr { $dc_tag_ecc_bits + $dc_tag_data_sz } ]
                proc_set_module_embeddedsw_cmacro_assignment  "ECC_DCACHE_TAG_SIZE" $dc_tag_ecc_sz
                
                set tlb_data_size         [ proc_calculate_tlb_data_size ]
                set tlb_ecc_bits          [ proc_calculate_ecc_bits $tlb_data_size ]
                set tlb_ecc_sz            [ expr { $tlb_ecc_bits + $tlb_data_size } ]
                proc_set_module_embeddedsw_cmacro_assignment  "ECC_TLB_SIZE" $tlb_ecc_sz
            }
        }
    }
    
    if { [ expr { "$impl" != "Tiny" } ] } {
        if { [ expr { "$setting_interruptControllerType" == "External" } ] } {
            proc_set_module_embeddedsw_cmacro_assignment  "EIC_PRESENT" ""
        }
        proc_set_module_embeddedsw_cmacro_assignment   "NUM_OF_SHADOW_REG_SETS" [ get_parameter_value setting_shadowRegisterSets ]
        
        # Adding a embeddedsw cmacro for ECC present
        if { $ecc_present } {
            proc_set_module_embeddedsw_cmacro_assignment  "ECC_PRESENT" ""

            if { $ecc_sim_test_ports } {
                proc_set_module_embeddedsw_cmacro_assignment  "ECC_RF_SIZE" "39"
                proc_set_module_embeddedsw_cmacro_assignment  "ECC_DCACHE_DATA_SIZE" "39"
                proc_set_module_embeddedsw_cmacro_assignment  "ECC_ICACHE_DATA_SIZE" "39"
                
                # Only define when TCMs are present
                set tcdm_num                 [ get_parameter_value dcache_numTCDM ]
                foreach i {0 1 2 3} {
                    if { $i < $tcdm_num } {
                        proc_set_module_embeddedsw_cmacro_assignment  "ECC_DTCM${i}_SIZE" "39"
                    }
                }
                # TLB, Data/Inst Cache Tag RAM
                set ic_tag_data_sz           [ proc_calculate_ic_tag_data_size ]
                set ic_tag_ecc_bits          [ proc_calculate_ecc_bits $ic_tag_data_sz ]
                set ic_tag_ecc_sz            [ expr { $ic_tag_ecc_bits + $ic_tag_data_sz } ]
                proc_set_module_embeddedsw_cmacro_assignment  "ECC_ICACHE_TAG_SIZE" $ic_tag_ecc_sz
                
                set dc_tag_data_sz           [ proc_calculate_dc_tag_data_size ]
                set dc_tag_ecc_bits          [ proc_calculate_ecc_bits $dc_tag_data_sz ]
                set dc_tag_ecc_sz            [ expr { $dc_tag_ecc_bits + $dc_tag_data_sz } ]
                proc_set_module_embeddedsw_cmacro_assignment  "ECC_DCACHE_TAG_SIZE" $dc_tag_ecc_sz
                
                set tlb_data_size         [ proc_calculate_tlb_data_size ]
                set tlb_ecc_bits          [ proc_calculate_ecc_bits $tlb_data_size ]
                set tlb_ecc_sz            [ expr { $tlb_ecc_bits + $tlb_data_size } ]
                proc_set_module_embeddedsw_cmacro_assignment  "ECC_TLB_SIZE" $tlb_ecc_sz
            }
        }
    } else {
        # Adding a embeddedsw cmacro for ECC present
        if { $ecc_present } {
            proc_set_module_embeddedsw_cmacro_assignment  "ECC_PRESENT" ""

            if { $ecc_sim_test_ports } {
                # Only support RF ECC
                proc_set_module_embeddedsw_cmacro_assignment  "ECC_RF_SIZE" "39"
            }
        }
    }

    # Add information regarding the Dcache bypass settings
    set setting_ioregionBypassDCache [proc_get_boolean_parameter setting_ioregionBypassDCache]
    set setting_bit31BypassDCache [proc_get_boolean_parameter setting_bit31BypassDCache]
    set io_regionbase                [ proc_num2hex [ get_parameter_value io_regionbase ] ]
    set io_regionsize                [ proc_num2hex [ get_parameter_value io_regionsize ] ]

    if { $mmu_enabled } {
        # Convert KERNEL region address to I/O region address to bypass data cache by setting bit 29.
        proc_set_module_embeddedsw_cmacro_assignment   "DCACHE_BYPASS_MASK" 0x20000000
    } else {
            if {$setting_ioregionBypassDCache} {
                proc_set_module_embeddedsw_cmacro_assignment   "PERIPHERAL_REGION_PRESENT" ""
                proc_set_module_embeddedsw_cmacro_assignment   "PERIPHERAL_REGION_BASE" "$io_regionbase"
                proc_set_module_embeddedsw_cmacro_assignment   "PERIPHERAL_REGION_SIZE" "$io_regionsize"
            }
            if { $setting_bit31BypassDCache } {
                proc_set_module_embeddedsw_cmacro_assignment   "DCACHE_BYPASS_MASK" 0x80000000
            }
    }

        # Device tree parameters
    set_module_assignment embeddedsw.dts.vendor "altr"
    set_module_assignment embeddedsw.dts.group "cpu"
    set_module_assignment embeddedsw.dts.name "nios2"
    set_module_assignment embeddedsw.dts.compatible "altr,nios2-1.1"
    set_module_assignment {embeddedsw.dts.params.clock-frequency} [ get_module_assignment embeddedsw.CMacro.CPU_FREQ ]
    set_module_assignment {embeddedsw.dts.params.dcache-line-size} [ get_module_assignment embeddedsw.CMacro.DCACHE_LINE_SIZE ]
    set_module_assignment {embeddedsw.dts.params.icache-line-size} [ get_module_assignment embeddedsw.CMacro.ICACHE_LINE_SIZE ]
    set_module_assignment {embeddedsw.dts.params.dcache-size} [ get_module_assignment embeddedsw.CMacro.DCACHE_SIZE ]
    set_module_assignment {embeddedsw.dts.params.icache-size} [ get_module_assignment embeddedsw.CMacro.ICACHE_SIZE ]
    set_module_assignment {embeddedsw.dts.params.altr,implementation} "[ get_module_assignment embeddedsw.CMacro.CPU_IMPLEMENTATION ]"
    set_module_assignment {embeddedsw.dts.params.altr,reset-addr} [ get_module_assignment embeddedsw.CMacro.RESET_ADDR ]
    set_module_assignment {embeddedsw.dts.params.altr,exception-addr} [ get_module_assignment embeddedsw.CMacro.EXCEPTION_ADDR ]

    if { $mmu_enabled } {
        set_module_assignment {embeddedsw.dts.params.altr,pid-num-bits} [ get_module_assignment embeddedsw.CMacro.PROCESS_ID_NUM_BITS ]
        set_module_assignment {embeddedsw.dts.params.altr,tlb-num-ways} [ get_module_assignment embeddedsw.CMacro.TLB_NUM_WAYS ]
        set_module_assignment {embeddedsw.dts.params.altr,tlb-num-entries} [ get_module_assignment embeddedsw.CMacro.TLB_NUM_ENTRIES ]
        set_module_assignment {embeddedsw.dts.params.altr,tlb-ptr-sz} [ get_module_assignment embeddedsw.CMacro.TLB_PTR_SZ ]
        set_module_assignment {embeddedsw.dts.params.altr,has-mmu} $mmu_enabled
        set_module_assignment {embeddedsw.dts.params.altr,fast-tlb-miss-addr} [ get_module_assignment embeddedsw.CMacro.FAST_TLB_MISS_EXCEPTION_ADDR ]
    }

    # Boolean
    if { [ get_module_assignment embeddedsw.CMacro.HARDWARE_DIVIDE_PRESENT ] } {
        set_module_assignment {embeddedsw.dts.params.altr,has-div} 1
    }

    if { [ get_module_assignment embeddedsw.CMacro.HARDWARE_MULTIPLY_PRESENT ] } {
        set_module_assignment {embeddedsw.dts.params.altr,has-mul} 1
    }

    if { [ get_module_assignment embeddedsw.CMacro.HARDWARE_MULX_PRESENT ] } {
        set_module_assignment {embeddedsw.dts.params.altr,has-mulx} 1
    }
}

proc sub_validate_update_module_embeddedsw_configurations {} {
    # Required for embeddedsw tools to recognize this module as a Nios II CPU.
    proc_set_module_embeddedsw_configuration_assignment "cpuArchitecture"       "Nios II"
    set cpuArchRev [ get_parameter_value cpuArchRev ]

    if { $cpuArchRev == 2 } {
        proc_set_module_embeddedsw_configuration_assignment "cpuArchitectureRevision" $cpuArchRev
    }

    proc_set_module_embeddedsw_configuration_assignment "HDLSimCachesCleared"   [ proc_get_boolean_parameter setting_HDLSimCachesCleared]
    proc_set_module_embeddedsw_configuration_assignment "resetSlave"            [ get_parameter_value resetSlave ]
    proc_set_module_embeddedsw_configuration_assignment "resetOffset"           [ get_parameter_value resetOffset ]
    proc_set_module_embeddedsw_configuration_assignment "exceptionSlave"        [ get_parameter_value exceptionSlave ]
    proc_set_module_embeddedsw_configuration_assignment "exceptionOffset"       [ get_parameter_value exceptionOffset ]
    proc_set_module_embeddedsw_configuration_assignment "breakSlave"            [ get_parameter_value breakSlave_derived ]
    proc_set_module_embeddedsw_configuration_assignment "breakOffset"           [ get_parameter_value breakOffset ]
    proc_set_module_embeddedsw_configuration_assignment "DataCacheVictimBufImpl" [ get_parameter_value dcache_victim_buf_impl ]

    # mmu enabled?
    set mmu_enabled    [ proc_get_mmu_present ]
    if { $mmu_enabled } {
        proc_set_module_embeddedsw_configuration_assignment "mmu_TLBMissExcSlave"            [ get_parameter_value mmu_TLBMissExcSlave ]
        proc_set_module_embeddedsw_configuration_assignment "mmu_TLBMissExcOffset"           [ get_parameter_value mmu_TLBMissExcOffset ]
    }
}
proc sub_show_hidden {} {
    set show_unpublished_settings   [ proc_get_boolean_parameter setting_showUnpublishedSettings ]
    set show_internal_settings      [ proc_get_boolean_parameter setting_showInternalSettings    ]
    set local_asic_enabled          [ proc_get_boolean_parameter setting_asic_enabled            ]

    set parameters [get_parameters]
    foreach param $parameters {
      if { [ expr { $param != "setting_showUnpublishedSettings" } && { $param != "setting_showInternalSettings" } ] } {
        set param_status [get_parameter_property $param "STATUS" ]

        if { "$param_status" == "EXPERIMENTAL" } {
            
            set param_description [get_parameter_property $param "DESCRIPTION" ]

            if { "$param_description" == "INTERNAL" } {
                set_parameter_property  $param   "VISIBLE" $show_internal_settings
            } else {
                set_parameter_property  $param   "VISIBLE" $show_unpublished_settings
            }
        }
      }
    }
}

proc validate_process {} { 
    sub_validate_update_parameters
    sub_validate_update_parameterization_gui
    sub_validate_check_module
    sub_validate_update_module_embeddedsw_cmacros
    sub_validate_update_module_embeddedsw_configurations
    sub_show_hidden
}

proc validate {} {
    set local_instaddrwidth          [ get_parameter_value instAddrWidth ]
    set local_faaddrwidth          [ get_parameter_value faAddrWidth ]
    set local_dataaddrwidth          [ get_parameter_value dataAddrWidth ]
    
    if { "$local_instaddrwidth" > "32" || "$local_faaddrwidth" > "32" || "$local_dataaddrwidth" > "32" } {
        send_message error "Address width above 32 bits are not supported for Nios II"
    } else {
        validate_process
    }
}

proc add_cpu_instance {cpu} {
      # Set instance parameter on CPU user parameters/system info
    # System info
    
    set_instance_property $cpu SUPPRESS_ALL_WARNINGS true
    set_instance_property $cpu SUPPRESS_ALL_INFO_MESSAGES true

    set_instance_parameter $cpu cpu_name  $cpu
    set impl                        [ get_parameter_value impl                        ]
    set fa_cache_linesize                [ get_parameter_value fa_cache_linesize                ]
    set icache_numTCIM                   [ get_parameter_value icache_numTCIM                   ]
    set dcache_numTCDM                   [ get_parameter_value dcache_numTCDM                   ] 
    
    set instAddrWidth                               [ get_parameter_value instAddrWidth                             ]
    set faAddrWidth                                 [ get_parameter_value faAddrWidth                             ]
    set dataAddrWidth                               [ get_parameter_value dataAddrWidth                             ]
    set tightlyCoupledDataMaster0AddrWidth          [ get_parameter_value tightlyCoupledDataMaster0AddrWidth        ]
    set tightlyCoupledDataMaster1AddrWidth          [ get_parameter_value tightlyCoupledDataMaster1AddrWidth        ]
    set tightlyCoupledDataMaster2AddrWidth          [ get_parameter_value tightlyCoupledDataMaster2AddrWidth        ]
    set tightlyCoupledDataMaster3AddrWidth          [ get_parameter_value tightlyCoupledDataMaster3AddrWidth        ]
    set tightlyCoupledInstructionMaster0AddrWidth   [ get_parameter_value tightlyCoupledInstructionMaster0AddrWidth ]
    set tightlyCoupledInstructionMaster1AddrWidth   [ get_parameter_value tightlyCoupledInstructionMaster1AddrWidth ]
    set tightlyCoupledInstructionMaster2AddrWidth   [ get_parameter_value tightlyCoupledInstructionMaster2AddrWidth ]
    set tightlyCoupledInstructionMaster3AddrWidth   [ get_parameter_value tightlyCoupledInstructionMaster3AddrWidth ]
    set dataMasterHighPerformanceAddrWidth          [ get_parameter_value dataMasterHighPerformanceAddrWidth        ]
    set instructionMasterHighPerformanceAddrWidth   [ get_parameter_value instructionMasterHighPerformanceAddrWidth ]

    set instSlaveMapParam                           [ get_parameter_value instSlaveMapParam                         ]
    set faSlaveMapParam                             [ get_parameter_value faSlaveMapParam                         ]
    set dataSlaveMapParam                           [ get_parameter_value dataSlaveMapParam                         ] 

    set clockFrequency                              [ get_parameter_value clockFrequency                            ]
    set deviceFamilyName                            [ get_parameter_value deviceFamilyName                          ]
    set internalIrqMaskSystemInfo                   [ get_parameter_value internalIrqMaskSystemInfo                 ]


    if { $cpu == "nios_a" } {
        set customInstSlavesSystemInfo                  [ get_parameter_value customInstSlavesSystemInfo_nios_a     ]
    } elseif  { $cpu == "nios_b" } {
        set customInstSlavesSystemInfo                  [ get_parameter_value customInstSlavesSystemInfo_nios_b     ]
    } elseif  { $cpu == "nios_c" } {
        set customInstSlavesSystemInfo                  [ get_parameter_value customInstSlavesSystemInfo_nios_c     ]
    } else {
        set customInstSlavesSystemInfo                  [ get_parameter_value customInstSlavesSystemInfo            ]
    }
    
    set deviceFeaturesSystemInfo                    [ get_parameter_value deviceFeaturesSystemInfo                  ] 

    set tightlyCoupledDataMaster0MapParam           [ get_parameter_value tightlyCoupledDataMaster0MapParam         ]
    set tightlyCoupledDataMaster1MapParam           [ get_parameter_value tightlyCoupledDataMaster1MapParam         ]
    set tightlyCoupledDataMaster2MapParam           [ get_parameter_value tightlyCoupledDataMaster2MapParam         ] 
    set tightlyCoupledDataMaster3MapParam           [ get_parameter_value tightlyCoupledDataMaster3MapParam         ]
    set tightlyCoupledInstructionMaster0MapParam    [ get_parameter_value tightlyCoupledInstructionMaster0MapParam  ]
    set tightlyCoupledInstructionMaster1MapParam    [ get_parameter_value tightlyCoupledInstructionMaster1MapParam  ]
    set tightlyCoupledInstructionMaster2MapParam    [ get_parameter_value tightlyCoupledInstructionMaster2MapParam  ]
    set tightlyCoupledInstructionMaster3MapParam    [ get_parameter_value tightlyCoupledInstructionMaster3MapParam  ]
    set dataMasterHighPerformanceMapParam           [ get_parameter_value dataMasterHighPerformanceMapParam         ]
    set instructionMasterHighPerformanceMapParam    [ get_parameter_value instructionMasterHighPerformanceMapParam  ]

    set master_addr_map                                         [ get_parameter_value master_addr_map                                 ]
    set instruction_master_paddr_base                           [ proc_num2hex [ get_parameter_value instruction_master_paddr_base                   ]]
    set instruction_master_paddr_size                           [ expr abs([get_parameter_value instruction_master_paddr_size                        ])]
    set flash_instruction_master_paddr_base                     [ proc_num2hex [ get_parameter_value flash_instruction_master_paddr_base             ]]
    set flash_instruction_master_paddr_size                     [ expr abs([get_parameter_value flash_instruction_master_paddr_size                 ])]
    set data_master_paddr_base                                  [ proc_num2hex [ get_parameter_value data_master_paddr_base                          ]]
    set data_master_paddr_size                                  [ expr abs([ get_parameter_value data_master_paddr_size                             ])]
    set tightly_coupled_instruction_master_0_paddr_base         [ proc_num2hex [ get_parameter_value tightly_coupled_instruction_master_0_paddr_base ]]
    set tightly_coupled_instruction_master_0_paddr_size         [ expr abs([get_parameter_value tightly_coupled_instruction_master_0_paddr_size     ])]
    set tightly_coupled_instruction_master_1_paddr_base         [ proc_num2hex [ get_parameter_value tightly_coupled_instruction_master_1_paddr_base ]]
    set tightly_coupled_instruction_master_1_paddr_size         [ expr abs([get_parameter_value tightly_coupled_instruction_master_1_paddr_size     ])]
    set tightly_coupled_instruction_master_2_paddr_base         [ proc_num2hex [ get_parameter_value tightly_coupled_instruction_master_2_paddr_base ]]
    set tightly_coupled_instruction_master_2_paddr_size         [ expr abs([get_parameter_value tightly_coupled_instruction_master_2_paddr_size     ])]
    set tightly_coupled_instruction_master_3_paddr_base         [ proc_num2hex [ get_parameter_value tightly_coupled_instruction_master_3_paddr_base ]]
    set tightly_coupled_instruction_master_3_paddr_size         [ expr abs([get_parameter_value tightly_coupled_instruction_master_3_paddr_size     ])]
    set tightly_coupled_data_master_0_paddr_base                [ proc_num2hex [ get_parameter_value tightly_coupled_data_master_0_paddr_base        ]]
    set tightly_coupled_data_master_0_paddr_size                [ expr abs([get_parameter_value tightly_coupled_data_master_0_paddr_size            ])]
    set tightly_coupled_data_master_1_paddr_base                [ proc_num2hex [ get_parameter_value tightly_coupled_data_master_1_paddr_base        ]]
    set tightly_coupled_data_master_1_paddr_size                [ expr abs([get_parameter_value tightly_coupled_data_master_1_paddr_size            ])]
    set tightly_coupled_data_master_2_paddr_base                [ proc_num2hex [ get_parameter_value tightly_coupled_data_master_2_paddr_base        ]]
    set tightly_coupled_data_master_2_paddr_size                [ expr abs([get_parameter_value tightly_coupled_data_master_2_paddr_size            ])]
    set tightly_coupled_data_master_3_paddr_base                [ proc_num2hex [ get_parameter_value tightly_coupled_data_master_3_paddr_base        ]]
    set tightly_coupled_data_master_3_paddr_size                [ expr abs([get_parameter_value tightly_coupled_data_master_3_paddr_size            ])]
    set instruction_master_high_performance_paddr_base          [ proc_num2hex [ expr [ get_parameter_value instruction_master_high_performance_paddr_base  ] & 0xffffffff ] ]
    set instruction_master_high_performance_paddr_size          [ expr abs([get_parameter_value instruction_master_high_performance_paddr_size      ])]
    set data_master_high_performance_paddr_base                 [ proc_num2hex [ expr [ get_parameter_value data_master_high_performance_paddr_base         ] & 0xffffffff ] ]
    set data_master_high_performance_paddr_size                 [ expr abs([get_parameter_value data_master_high_performance_paddr_size             ])]

    # top address = base + size - 1
    set instruction_master_paddr_top                       [ proc_num2hex [ expr ($instruction_master_paddr_base                    + $instruction_master_paddr_size                   - 1) & 0xffffffff ]]
    set flash_instruction_master_paddr_top                 [ proc_num2hex [ expr ($flash_instruction_master_paddr_base              + $flash_instruction_master_paddr_size             - 1) & 0xffffffff ]]      
    set data_master_paddr_top                              [ proc_num2hex [ expr ($data_master_paddr_base                           + $data_master_paddr_size                          - 1) & 0xffffffff ]]
    set tightly_coupled_instruction_master_0_paddr_top     [ proc_num2hex [ expr ($tightly_coupled_instruction_master_0_paddr_base  + $tightly_coupled_instruction_master_0_paddr_size - 1) & 0xffffffff ]]
    set tightly_coupled_instruction_master_1_paddr_top     [ proc_num2hex [ expr ($tightly_coupled_instruction_master_1_paddr_base  + $tightly_coupled_instruction_master_1_paddr_size - 1) & 0xffffffff ]]
    set tightly_coupled_instruction_master_2_paddr_top     [ proc_num2hex [ expr ($tightly_coupled_instruction_master_2_paddr_base  + $tightly_coupled_instruction_master_2_paddr_size - 1) & 0xffffffff ]]
    set tightly_coupled_instruction_master_3_paddr_top     [ proc_num2hex [ expr ($tightly_coupled_instruction_master_3_paddr_base  + $tightly_coupled_instruction_master_3_paddr_size - 1) & 0xffffffff ]]
    set tightly_coupled_data_master_0_paddr_top            [ proc_num2hex [ expr ($tightly_coupled_data_master_0_paddr_base         + $tightly_coupled_data_master_0_paddr_size        - 1) & 0xffffffff ]]
    set tightly_coupled_data_master_1_paddr_top            [ proc_num2hex [ expr ($tightly_coupled_data_master_1_paddr_base         + $tightly_coupled_data_master_1_paddr_size        - 1) & 0xffffffff ]]
    set tightly_coupled_data_master_2_paddr_top            [ proc_num2hex [ expr ($tightly_coupled_data_master_2_paddr_base         + $tightly_coupled_data_master_2_paddr_size        - 1) & 0xffffffff ]]
    set tightly_coupled_data_master_3_paddr_top            [ proc_num2hex [ expr ($tightly_coupled_data_master_3_paddr_base         + $tightly_coupled_data_master_3_paddr_size        - 1) & 0xffffffff ]]
    set instruction_master_high_performance_paddr_top      [ proc_num2hex [ expr ($instruction_master_high_performance_paddr_base   + $instruction_master_high_performance_paddr_size  - 1) & 0xffffffff ] ]
    set data_master_high_performance_paddr_top             [ proc_num2hex [ expr ($data_master_high_performance_paddr_base          + $data_master_high_performance_paddr_size         - 1) & 0xffffffff ] ]
    
    # reassign top address to 0 in case the size is 0
	if { $instruction_master_paddr_size == 0 } { 
		set instruction_master_paddr_top                  		0
	}
	if { $flash_instruction_master_paddr_size == 0 } {
		set flash_instruction_master_paddr_top                  0
	}
	if { $data_master_paddr_size == 0 } {
		set data_master_paddr_top                               0
	}
	if { $tightly_coupled_instruction_master_0_paddr_size == 0 } {
		set tightly_coupled_instruction_master_0_paddr_top      0
	}
	if { $tightly_coupled_instruction_master_1_paddr_size == 0 } {
		set tightly_coupled_instruction_master_1_paddr_top      0
	}
	if { $tightly_coupled_instruction_master_2_paddr_size == 0 } {
		set tightly_coupled_instruction_master_2_paddr_top      0
	}
	if { $tightly_coupled_instruction_master_3_paddr_size == 0 } {
		set tightly_coupled_instruction_master_3_paddr_top      0
	}
	if { $tightly_coupled_data_master_0_paddr_size == 0 } {
		set tightly_coupled_data_master_0_paddr_top             0
	}
	if { $tightly_coupled_data_master_1_paddr_size == 0 } {
		set tightly_coupled_data_master_1_paddr_top             0
	}
	if { $tightly_coupled_data_master_2_paddr_size == 0 } {
		set tightly_coupled_data_master_2_paddr_top             0
	}
	if { $tightly_coupled_data_master_3_paddr_size == 0 } {
		set tightly_coupled_data_master_3_paddr_top             0
	}
	if { $instruction_master_high_performance_paddr_size == 0 } {
		set instruction_master_high_performance_paddr_top       0
	}
	if { $data_master_high_performance_paddr_size == 0 } {
		set data_master_high_performance_paddr_top              0
	}

    # if it is set derived the width from the size log(size)/log(2)    
    set instruction_master_addrwidth                       [ proc_num2sz $instruction_master_paddr_top                   ]
    set flash_instruction_master_addrwidth                 [ proc_num2sz $flash_instruction_master_paddr_top             ]      
    set data_master_addrwidth                              [ proc_num2sz $data_master_paddr_top                          ]
    set tightly_coupled_instruction_master_0_addrwidth     [ proc_num2sz $tightly_coupled_instruction_master_0_paddr_top ]
    set tightly_coupled_instruction_master_1_addrwidth     [ proc_num2sz $tightly_coupled_instruction_master_1_paddr_top ]
    set tightly_coupled_instruction_master_2_addrwidth     [ proc_num2sz $tightly_coupled_instruction_master_2_paddr_top ]
    set tightly_coupled_instruction_master_3_addrwidth     [ proc_num2sz $tightly_coupled_instruction_master_3_paddr_top ]
    set tightly_coupled_data_master_0_addrwidth            [ proc_num2sz $tightly_coupled_data_master_0_paddr_top        ]
    set tightly_coupled_data_master_1_addrwidth            [ proc_num2sz $tightly_coupled_data_master_1_paddr_top        ]
    set tightly_coupled_data_master_2_addrwidth            [ proc_num2sz $tightly_coupled_data_master_2_paddr_top        ]
    set tightly_coupled_data_master_3_addrwidth            [ proc_num2sz $tightly_coupled_data_master_3_paddr_top        ]
    set instruction_master_high_performance_addrwidth      [ proc_num2sz $instruction_master_high_performance_paddr_top  ]
    set data_master_high_performance_addrwidth             [ proc_num2sz $data_master_high_performance_paddr_top         ]
    
    if { $master_addr_map } {
        send_message warning "Set Master Base Address and Size is enabled.\n
        There is no validation for memory overlap. Please make sure that the base address and size are properly set."
        
        send_message info "Please make sure that the Memories and Peripherals are connected according to the valid base and top address for each Master as listed below"
        if { $instruction_master_paddr_size > 0 } {
            send_message info "Instruction Master Base : $instruction_master_paddr_base"
            send_message info "Instruction Master Top  : $instruction_master_paddr_top"
        }
        if { $data_master_paddr_size > 0 } {
            send_message info "Data Master Base : $data_master_paddr_base"
            send_message info "Data Master Top  : $data_master_paddr_top"
        }
        
        if { $impl == "Fast" && $flash_instruction_master_paddr_size > 0 && $fa_cache_linesize > 0 } {
            send_message info "Flash Instruction Master Base : $flash_instruction_master_paddr_base"
            send_message info "Flash Instruction Master Top  : $flash_instruction_master_paddr_top"
        }
        
        if { $impl == "Small" && $instruction_master_high_performance_paddr_size > 0 } {
            send_message info "High Performance Instruction Master Base : $instruction_master_high_performance_paddr_base"
            send_message info "High Performance Instruction Master Top  : $instruction_master_high_performance_paddr_top"
        }
        if { $impl == "Small" && $data_master_high_performance_paddr_size > 0 } {       
            send_message info "High Performance Data Master Base : $data_master_high_performance_paddr_base"
            send_message info "High Performance Data Master Top  : $data_master_high_performance_paddr_top"
        }
        
       if { $tightly_coupled_instruction_master_0_paddr_size > 0 && $icache_numTCIM > 0 && $impl != "Tiny" } {
            send_message info "Tightly Coupled Instruction Master 0 Base : $tightly_coupled_instruction_master_0_paddr_base"
            send_message info "Tightly Coupled Instruction Master 0 Top  : $tightly_coupled_instruction_master_0_paddr_top"
       }
       if { $tightly_coupled_instruction_master_1_paddr_size > 0 && $icache_numTCIM > 1 && $impl != "Tiny" } {
            send_message info "Tightly Coupled Instruction Master 1 Base : $tightly_coupled_instruction_master_1_paddr_base"
            send_message info "Tightly Coupled Instruction Master 1 Top  : $tightly_coupled_instruction_master_1_paddr_top"
       }
       if { $tightly_coupled_instruction_master_2_paddr_size > 0 && $icache_numTCIM > 2 && $impl != "Tiny" } {
            send_message info "Tightly Coupled Instruction Master 2 Base : $tightly_coupled_instruction_master_2_paddr_base"
            send_message info "Tightly Coupled Instruction Master 2 Top  : $tightly_coupled_instruction_master_2_paddr_top"
       }
       if { $tightly_coupled_instruction_master_3_paddr_size > 0 && $icache_numTCIM > 3 && $impl != "Tiny" } {
            send_message info "Tightly Coupled Instruction Master 3 Base : $tightly_coupled_instruction_master_3_paddr_base"
            send_message info "Tightly Coupled Instruction Master 3 Top  : $tightly_coupled_instruction_master_3_paddr_top"
       }
       if { $tightly_coupled_data_master_0_paddr_size > 0 && $dcache_numTCDM > 0 && $impl != "Tiny" } {
            send_message info "Tightly Coupled Data Master 0 Base : $tightly_coupled_data_master_0_paddr_base"
            send_message info "Tightly Coupled Data Master 0 Top  : $tightly_coupled_data_master_0_paddr_top"
       }
       if { $tightly_coupled_data_master_1_paddr_size > 0 && $dcache_numTCDM > 1 && $impl != "Tiny" } {
            send_message info "Tightly Coupled Data Master 1 Base : $tightly_coupled_data_master_1_paddr_base"
            send_message info "Tightly Coupled Data Master 1 Top  : $tightly_coupled_data_master_1_paddr_top"
       }
       if { $tightly_coupled_data_master_2_paddr_size > 0 && $dcache_numTCDM > 2 && $impl != "Tiny" } {
            send_message info "Tightly Coupled Data Master 2 Base : $tightly_coupled_data_master_2_paddr_base"
            send_message info "Tightly Coupled Data Master 2 Top  : $tightly_coupled_data_master_2_paddr_top"
       }
       if { $tightly_coupled_data_master_3_paddr_size > 0 && $dcache_numTCDM > 3 && $impl != "Tiny" } {
            send_message info "Tightly Coupled Data Master 3 Base : $tightly_coupled_data_master_3_paddr_base"
            send_message info "Tightly Coupled Data Master 3 Top  : $tightly_coupled_data_master_3_paddr_top"
       }

    }
    
    if { $master_addr_map } {
        set_instance_parameter $cpu instAddrWidth                             $instruction_master_addrwidth
        set_instance_parameter $cpu dataAddrWidth                             $data_master_addrwidth
        if { $impl == "Fast" && $flash_instruction_master_paddr_size > 0 && $fa_cache_linesize > 0  } {
            set_instance_parameter $cpu faAddrWidth                               $flash_instruction_master_addrwidth
        } else {
            set_instance_parameter $cpu faAddrWidth 0  
        }       
        if { $impl != "Tiny" } {
            set_instance_parameter $cpu tightlyCoupledInstructionMaster0AddrWidth $tightly_coupled_instruction_master_0_addrwidth
            set_instance_parameter $cpu tightlyCoupledInstructionMaster1AddrWidth $tightly_coupled_instruction_master_1_addrwidth
            set_instance_parameter $cpu tightlyCoupledInstructionMaster2AddrWidth $tightly_coupled_instruction_master_2_addrwidth
            set_instance_parameter $cpu tightlyCoupledInstructionMaster3AddrWidth $tightly_coupled_instruction_master_3_addrwidth
            set_instance_parameter $cpu tightlyCoupledDataMaster0AddrWidth        $tightly_coupled_data_master_0_addrwidth       
            set_instance_parameter $cpu tightlyCoupledDataMaster1AddrWidth        $tightly_coupled_data_master_1_addrwidth       
            set_instance_parameter $cpu tightlyCoupledDataMaster2AddrWidth        $tightly_coupled_data_master_2_addrwidth       
            set_instance_parameter $cpu tightlyCoupledDataMaster3AddrWidth        $tightly_coupled_data_master_3_addrwidth
        } else {
            set_instance_parameter $cpu tightlyCoupledInstructionMaster0AddrWidth 0
            set_instance_parameter $cpu tightlyCoupledInstructionMaster1AddrWidth 0
            set_instance_parameter $cpu tightlyCoupledInstructionMaster2AddrWidth 0
            set_instance_parameter $cpu tightlyCoupledInstructionMaster3AddrWidth 0
            set_instance_parameter $cpu tightlyCoupledDataMaster0AddrWidth 0
            set_instance_parameter $cpu tightlyCoupledDataMaster1AddrWidth 0
            set_instance_parameter $cpu tightlyCoupledDataMaster2AddrWidth 0
            set_instance_parameter $cpu tightlyCoupledDataMaster3AddrWidth 0
        }
        if { $impl == "Small" } {
            set_instance_parameter $cpu instructionMasterHighPerformanceAddrWidth $instruction_master_high_performance_addrwidth
            set_instance_parameter $cpu dataMasterHighPerformanceAddrWidth        $data_master_high_performance_addrwidth
        } else {
            set_instance_parameter $cpu instructionMasterHighPerformanceAddrWidth 0  
            set_instance_parameter $cpu dataMasterHighPerformanceAddrWidth        0
        }
    } else {
        set_instance_parameter $cpu instAddrWidth                             $instAddrWidth
        set_instance_parameter $cpu faAddrWidth                               $faAddrWidth
        set_instance_parameter $cpu dataAddrWidth                             $dataAddrWidth                            
        set_instance_parameter $cpu tightlyCoupledDataMaster0AddrWidth        $tightlyCoupledDataMaster0AddrWidth       
        set_instance_parameter $cpu tightlyCoupledDataMaster1AddrWidth        $tightlyCoupledDataMaster1AddrWidth       
        set_instance_parameter $cpu tightlyCoupledDataMaster2AddrWidth        $tightlyCoupledDataMaster2AddrWidth       
        set_instance_parameter $cpu tightlyCoupledDataMaster3AddrWidth        $tightlyCoupledDataMaster3AddrWidth       
        set_instance_parameter $cpu tightlyCoupledInstructionMaster0AddrWidth $tightlyCoupledInstructionMaster0AddrWidth
        set_instance_parameter $cpu tightlyCoupledInstructionMaster1AddrWidth $tightlyCoupledInstructionMaster1AddrWidth
        set_instance_parameter $cpu tightlyCoupledInstructionMaster2AddrWidth $tightlyCoupledInstructionMaster2AddrWidth
        set_instance_parameter $cpu tightlyCoupledInstructionMaster3AddrWidth $tightlyCoupledInstructionMaster3AddrWidth
        set_instance_parameter $cpu dataMasterHighPerformanceAddrWidth        $dataMasterHighPerformanceAddrWidth       
        set_instance_parameter $cpu instructionMasterHighPerformanceAddrWidth $instructionMasterHighPerformanceAddrWidth
    }
    
    set_instance_parameter $cpu instSlaveMapParam                         $instSlaveMapParam
    set_instance_parameter $cpu faSlaveMapParam                           $faSlaveMapParam                        
    set_instance_parameter $cpu dataSlaveMapParam                         $dataSlaveMapParam                        
    set_instance_parameter $cpu clockFrequency                            $clockFrequency                           
    set_instance_parameter $cpu deviceFamilyName                          $deviceFamilyName                         
    set_instance_parameter $cpu internalIrqMaskSystemInfo                 $internalIrqMaskSystemInfo                
    set_instance_parameter $cpu customInstSlavesSystemInfo                $customInstSlavesSystemInfo               
    set_instance_parameter $cpu deviceFeaturesSystemInfo                  $deviceFeaturesSystemInfo                 
    set_instance_parameter $cpu tightlyCoupledDataMaster0MapParam         $tightlyCoupledDataMaster0MapParam        
    set_instance_parameter $cpu tightlyCoupledDataMaster1MapParam         $tightlyCoupledDataMaster1MapParam        
    set_instance_parameter $cpu tightlyCoupledDataMaster2MapParam         $tightlyCoupledDataMaster2MapParam        
    set_instance_parameter $cpu tightlyCoupledDataMaster3MapParam         $tightlyCoupledDataMaster3MapParam        
    set_instance_parameter $cpu tightlyCoupledInstructionMaster0MapParam  $tightlyCoupledInstructionMaster0MapParam 
    set_instance_parameter $cpu tightlyCoupledInstructionMaster1MapParam  $tightlyCoupledInstructionMaster1MapParam 
    set_instance_parameter $cpu tightlyCoupledInstructionMaster2MapParam  $tightlyCoupledInstructionMaster2MapParam 
    set_instance_parameter $cpu tightlyCoupledInstructionMaster3MapParam  $tightlyCoupledInstructionMaster3MapParam 
    set_instance_parameter $cpu dataMasterHighPerformanceMapParam         $dataMasterHighPerformanceMapParam        
    set_instance_parameter $cpu instructionMasterHighPerformanceMapParam  $instructionMasterHighPerformanceMapParam  

    # Main
    set cpuArchRev                 [ get_parameter_value cpuArchRev                 ]      
    set stratix_dspblock_shift_mul [ get_parameter_value stratix_dspblock_shift_mul ]
    set shifterType                [ get_parameter_value shifterType                ]
    set multiplierType             [ get_parameter_value multiplierType             ]
    set dividerType                [ get_parameter_value dividerType                ]

    set_instance_parameter $cpu cpuArchRev                 $cpuArchRev
    set_instance_parameter $cpu impl                       $impl
    set_instance_parameter $cpu stratix_dspblock_shift_mul $stratix_dspblock_shift_mul
    set_instance_parameter $cpu shifterType                $shifterType
    set_instance_parameter $cpu multiplierType             $multiplierType
    set_instance_parameter $cpu dividerType                $dividerType

    # Vectors
    set resetSlave              [ get_parameter_value resetSlave             ]
    set resetOffset             [ get_parameter_value resetOffset            ]
    set resetAbsoluteAddr       [ get_parameter_value resetAbsoluteAddr      ]
    set exceptionSlave          [ get_parameter_value exceptionSlave         ]
    set exceptionOffset         [ get_parameter_value exceptionOffset        ]
    set exceptionAbsoluteAddr   [ get_parameter_value exceptionAbsoluteAddr  ]
    set mmu_TLBMissExcSlave     [ get_parameter_value mmu_TLBMissExcSlave    ]
    set mmu_TLBMissExcOffset    [ get_parameter_value mmu_TLBMissExcOffset   ]
    set mmu_TLBMissExcAbsAddr   [ get_parameter_value mmu_TLBMissExcAbsAddr  ]
    set breakSlave              [ get_parameter_value breakSlave             ]
    set breakOffset             [ get_parameter_value breakOffset            ]
    set breakAbsoluteAddr       [ get_parameter_value breakAbsoluteAddr      ]
    set setting_exportvectors   [ get_parameter_value setting_exportvectors  ]
        
    set_instance_parameter $cpu resetSlave            $resetSlave            
    set_instance_parameter $cpu resetOffset           $resetOffset               
    set_instance_parameter $cpu exceptionSlave        $exceptionSlave        
    set_instance_parameter $cpu exceptionOffset       $exceptionOffset       
    set_instance_parameter $cpu mmu_TLBMissExcSlave   $mmu_TLBMissExcSlave   
    set_instance_parameter $cpu mmu_TLBMissExcOffset  $mmu_TLBMissExcOffset  
    set_instance_parameter $cpu breakSlave            $breakSlave            
    set_instance_parameter $cpu breakOffset           $breakOffset                
    set_instance_parameter $cpu setting_exportvectors $setting_exportvectors  

    # base and top here. The unit CPU takes in paddr base and top
    set_instance_parameter $cpu master_addr_map                                 $master_addr_map
    set_instance_parameter $cpu instruction_master_paddr_base                   $instruction_master_paddr_base
    set_instance_parameter $cpu instruction_master_paddr_top                    $instruction_master_paddr_top 
    set_instance_parameter $cpu data_master_paddr_base                          $data_master_paddr_base        
    set_instance_parameter $cpu data_master_paddr_top                           $data_master_paddr_top
    if { $impl == "Fast" && $flash_instruction_master_paddr_size > 0 && $fa_cache_linesize > 0 } {
        set_instance_parameter $cpu flash_instruction_master_paddr_base             $flash_instruction_master_paddr_base            
        set_instance_parameter $cpu flash_instruction_master_paddr_top              $flash_instruction_master_paddr_top
    }
    if { $impl != "Tiny" } {
        set_instance_parameter $cpu tightly_coupled_instruction_master_0_paddr_base $tightly_coupled_instruction_master_0_paddr_base
        set_instance_parameter $cpu tightly_coupled_instruction_master_0_paddr_top  $tightly_coupled_instruction_master_0_paddr_top
        set_instance_parameter $cpu tightly_coupled_instruction_master_1_paddr_base $tightly_coupled_instruction_master_1_paddr_base
        set_instance_parameter $cpu tightly_coupled_instruction_master_1_paddr_top  $tightly_coupled_instruction_master_1_paddr_top
        set_instance_parameter $cpu tightly_coupled_instruction_master_2_paddr_base $tightly_coupled_instruction_master_2_paddr_base
        set_instance_parameter $cpu tightly_coupled_instruction_master_2_paddr_top  $tightly_coupled_instruction_master_2_paddr_top
        set_instance_parameter $cpu tightly_coupled_instruction_master_3_paddr_base $tightly_coupled_instruction_master_3_paddr_base
        set_instance_parameter $cpu tightly_coupled_instruction_master_3_paddr_top  $tightly_coupled_instruction_master_3_paddr_top
        set_instance_parameter $cpu tightly_coupled_data_master_0_paddr_base        $tightly_coupled_data_master_0_paddr_base  
        set_instance_parameter $cpu tightly_coupled_data_master_0_paddr_top         $tightly_coupled_data_master_0_paddr_top
        set_instance_parameter $cpu tightly_coupled_data_master_1_paddr_base        $tightly_coupled_data_master_1_paddr_base   
        set_instance_parameter $cpu tightly_coupled_data_master_1_paddr_top         $tightly_coupled_data_master_1_paddr_top    
        set_instance_parameter $cpu tightly_coupled_data_master_2_paddr_base        $tightly_coupled_data_master_2_paddr_base     
        set_instance_parameter $cpu tightly_coupled_data_master_2_paddr_top         $tightly_coupled_data_master_2_paddr_top
        set_instance_parameter $cpu tightly_coupled_data_master_3_paddr_base        $tightly_coupled_data_master_3_paddr_base
        set_instance_parameter $cpu tightly_coupled_data_master_3_paddr_top         $tightly_coupled_data_master_3_paddr_top
    }
    if { $impl == "Small" } {
        if { $instruction_master_high_performance_paddr_size > 0 } {
            set_instance_parameter $cpu instruction_master_high_performance_paddr_base  $instruction_master_high_performance_paddr_base 
            set_instance_parameter $cpu instruction_master_high_performance_paddr_top   $instruction_master_high_performance_paddr_top
        }
        if { $data_master_high_performance_paddr_size > 0 } {
            set_instance_parameter $cpu data_master_high_performance_paddr_base         $data_master_high_performance_paddr_base   
            set_instance_parameter $cpu data_master_high_performance_paddr_top          $data_master_high_performance_paddr_top
        }
    }

    # Cache and memories interface
    # Instruction Master parameters

    set icache_burstType [ get_parameter_value icache_burstType ]
    
    set_instance_parameter $cpu icache_burstType $icache_burstType
    
    # Data Master parameters
    set dcache_bursts [ get_parameter_value dcache_bursts ]
    
    set_instance_parameter $cpu dcache_bursts $dcache_bursts
    
    set io_regionsize                    [ get_parameter_value io_regionsize                    ]
    set io_regionbase                    [ get_parameter_value io_regionbase                    ]
    set icache_size                      [ get_parameter_value icache_size                      ]
    set icache_tagramBlockType           [ get_parameter_value icache_tagramBlockType           ]
    set icache_ramBlockType              [ get_parameter_value icache_ramBlockType              ]
    set icache_burstType                 [ get_parameter_value icache_burstType                 ]
    set fa_cache_line                    [ get_parameter_value fa_cache_line                    ]
    set fa_cache_linesize                [ get_parameter_value fa_cache_linesize                ]
    set dcache_size                      [ get_parameter_value dcache_size                      ]
    set dcache_tagramBlockType           [ get_parameter_value dcache_tagramBlockType           ]
    set dcache_ramBlockType              [ get_parameter_value dcache_ramBlockType              ]
    set dcache_victim_buf_impl           [ get_parameter_value dcache_victim_buf_impl           ]
    set dcache_bursts                    [ get_parameter_value dcache_bursts                    ]
    set setting_support31bitdcachebypass [ get_parameter_value setting_support31bitdcachebypass ]

    if { $impl != "Fast" } {
    	set fa_cache_linesize 0
    }
    
    if { $impl == "Tiny" } {
    	set icache_numTCIM 0
    	set dcache_numTCDM 0
    }

    set_instance_parameter $cpu io_regionsize                    $io_regionsize
    set_instance_parameter $cpu io_regionbase                    $io_regionbase
    set_instance_parameter $cpu icache_size                      $icache_size
    set_instance_parameter $cpu icache_tagramBlockType           $icache_tagramBlockType
    set_instance_parameter $cpu icache_ramBlockType              $icache_ramBlockType
    set_instance_parameter $cpu icache_burstType                 $icache_burstType
    set_instance_parameter $cpu fa_cache_line                    $fa_cache_line
    set_instance_parameter $cpu fa_cache_linesize                $fa_cache_linesize
    set_instance_parameter $cpu dcache_size                      $dcache_size
    set_instance_parameter $cpu dcache_tagramBlockType           $dcache_tagramBlockType
    set_instance_parameter $cpu dcache_ramBlockType              $dcache_ramBlockType
    set_instance_parameter $cpu dcache_victim_buf_impl           $dcache_victim_buf_impl
    set_instance_parameter $cpu dcache_bursts                    $dcache_bursts
    set_instance_parameter $cpu setting_support31bitdcachebypass $setting_support31bitdcachebypass
    set_instance_parameter $cpu icache_numTCIM                   $icache_numTCIM
    set_instance_parameter $cpu dcache_numTCDM                   $dcache_numTCDM

    # MMU/MPU
    set mmu_enabled            [ get_parameter_value mmu_enabled            ]
    set mmu_processIDNumBits   [ get_parameter_value mmu_processIDNumBits   ]
    set mmu_autoAssignTlbPtrSz [ get_parameter_value mmu_autoAssignTlbPtrSz ]
    set mmu_tlbPtrSz           [ get_parameter_value mmu_tlbPtrSz           ]
    set mmu_tlbNumWays         [ get_parameter_value mmu_tlbNumWays         ]
    set mmu_udtlbNumEntries    [ get_parameter_value mmu_udtlbNumEntries    ]
    set mmu_uitlbNumEntries    [ get_parameter_value mmu_uitlbNumEntries    ]
    set mmu_ramBlockType       [ get_parameter_value mmu_ramBlockType       ]
    set mpu_enabled            [ get_parameter_value mpu_enabled            ]
    set mpu_useLimit           [ get_parameter_value mpu_useLimit           ]
    set mpu_numOfDataRegion    [ get_parameter_value mpu_numOfDataRegion    ]
    set mpu_minDataRegionSize  [ get_parameter_value mpu_minDataRegionSize  ]
    set mpu_numOfInstRegion    [ get_parameter_value mpu_numOfInstRegion    ]
    set mpu_minInstRegionSize  [ get_parameter_value mpu_minInstRegionSize  ]
    
    set_instance_parameter $cpu mmu_enabled            $mmu_enabled
    set_instance_parameter $cpu mmu_processIDNumBits   $mmu_processIDNumBits
    set_instance_parameter $cpu mmu_autoAssignTlbPtrSz $mmu_autoAssignTlbPtrSz
    set_instance_parameter $cpu mmu_tlbPtrSz           $mmu_tlbPtrSz
    set_instance_parameter $cpu mmu_tlbNumWays         $mmu_tlbNumWays
    set_instance_parameter $cpu mmu_udtlbNumEntries    $mmu_udtlbNumEntries
    set_instance_parameter $cpu mmu_uitlbNumEntries    $mmu_uitlbNumEntries
    set_instance_parameter $cpu mmu_ramBlockType       $mmu_ramBlockType
    set_instance_parameter $cpu mpu_enabled            $mpu_enabled
    set_instance_parameter $cpu mpu_useLimit           $mpu_useLimit
    set_instance_parameter $cpu mpu_numOfDataRegion    $mpu_numOfDataRegion
    set_instance_parameter $cpu mpu_minDataRegionSize  $mpu_minDataRegionSize
    set_instance_parameter $cpu mpu_numOfInstRegion    $mpu_numOfInstRegion
    set_instance_parameter $cpu mpu_minInstRegionSize  $mpu_minInstRegionSize
    
    # Debug
    set debug_enabled              [ get_parameter_value debug_enabled              ]                     
    set debug_hwbreakpoint         [ get_parameter_value debug_hwbreakpoint         ]
    set debug_datatrigger          [ get_parameter_value debug_datatrigger          ]
    set debug_traceType            [ get_parameter_value debug_traceType            ]
    set debug_traceStorage         [ get_parameter_value debug_traceStorage         ]
    set debug_OCIOnchipTrace       [ get_parameter_value debug_OCIOnchipTrace       ]
    set debug_debugReqSignals      [ get_parameter_value debug_debugReqSignals      ]                
    set debug_assignJtagInstanceID [ get_parameter_value debug_assignJtagInstanceID ]
    set debug_jtagInstanceID       [ get_parameter_value debug_jtagInstanceID       ]
    set ocimem_ramBlockType        [ get_parameter_value ocimem_ramBlockType        ]
    set setting_oci_version        [ get_parameter_value setting_oci_version        ]
    set setting_fast_register_read        [ get_parameter_value setting_fast_register_read        ]
    if { $impl == "Small" } {
    	# enable for M-core
    	set setting_fast_register_read 1
    }

    set_instance_parameter $cpu debug_enabled              $debug_enabled
    set_instance_parameter $cpu debug_hwbreakpoint         $debug_hwbreakpoint
    set_instance_parameter $cpu debug_datatrigger          $debug_datatrigger
    set_instance_parameter $cpu debug_traceType            $debug_traceType
    set_instance_parameter $cpu debug_traceStorage         $debug_traceStorage
    set_instance_parameter $cpu debug_OCIOnchipTrace       $debug_OCIOnchipTrace
    set_instance_parameter $cpu debug_debugReqSignals      $debug_debugReqSignals
    set_instance_parameter $cpu debug_assignJtagInstanceID $debug_assignJtagInstanceID
    set_instance_parameter $cpu debug_jtagInstanceID       $debug_jtagInstanceID
    set_instance_parameter $cpu ocimem_ramBlockType        $ocimem_ramBlockType
    set_instance_parameter $cpu setting_oci_version        $setting_oci_version
    set_instance_parameter $cpu setting_fast_register_read        $setting_fast_register_read
                                                        
    # Advanced Feature
    set cdx_enabled                              [ get_parameter_value cdx_enabled                              ]
    set mpx_enabled                              [ get_parameter_value mpx_enabled                              ]
    set tmr_enabled                              [ get_parameter_value tmr_enabled                              ]
    set setting_bigEndian                        [ get_parameter_value setting_bigEndian                        ]
    set setting_ecc_present                      [ get_parameter_value setting_ecc_present                      ]
    set setting_interruptControllerType          [ get_parameter_value setting_interruptControllerType          ]
    set setting_shadowRegisterSets               [ get_parameter_value setting_shadowRegisterSets               ]
    set cpuReset                                 [ get_parameter_value cpuReset                                 ]                                           
    set cpuID                                    [ get_parameter_value cpuID                                    ]                                     
    set setting_activateTrace                    [ get_parameter_value setting_activateTrace                    ]
    set tracefilename                            [ get_parameter_value tracefilename                            ]
    set setting_showUnpublishedSettings          [ get_parameter_value setting_showUnpublishedSettings          ]
    set setting_showInternalSettings             [ get_parameter_value setting_showInternalSettings             ]
    set setting_exportPCB                        [ get_parameter_value setting_exportPCB                        ]
    set setting_exportdebuginfo                  [ get_parameter_value setting_exportdebuginfo                  ]
    set setting_preciseIllegalMemAccessException [ get_parameter_value setting_preciseIllegalMemAccessException ]
    set setting_branchpredictiontype             [ get_parameter_value setting_branchpredictiontype             ]
    set setting_bhtPtrSz                         [ get_parameter_value setting_bhtPtrSz                         ]
    set bht_ramBlockType                         [ get_parameter_value bht_ramBlockType                         ]
    set regfile_ramBlockType                     [ get_parameter_value regfile_ramBlockType                     ]
    set setting_ic_ecc_present                   [ get_parameter_value setting_ic_ecc_present                   ]
    set setting_rf_ecc_present                   [ get_parameter_value setting_rf_ecc_present                   ]
    set setting_dc_ecc_present                   [ get_parameter_value setting_dc_ecc_present                   ]
    set setting_itcm_ecc_present                 [ get_parameter_value setting_itcm_ecc_present                 ]
    set setting_dtcm_ecc_present                 [ get_parameter_value setting_dtcm_ecc_present                 ]  
    set setting_mmu_ecc_present                  [ get_parameter_value setting_mmu_ecc_present                  ] 
    set resetrequest_enabled                     [ get_parameter_value resetrequest_enabled                     ]
    
    set_instance_parameter $cpu cdx_enabled                              $cdx_enabled
    set_instance_parameter $cpu mpx_enabled                              $mpx_enabled
    set_instance_parameter $cpu tmr_enabled                              $tmr_enabled
    set_instance_parameter $cpu setting_bigEndian                        $setting_bigEndian
    set_instance_parameter $cpu setting_ecc_present                      $setting_ecc_present
    set_instance_parameter $cpu setting_interruptControllerType          $setting_interruptControllerType
    set_instance_parameter $cpu setting_shadowRegisterSets               $setting_shadowRegisterSets
    set_instance_parameter $cpu cpuReset                                 $cpuReset
    set_instance_parameter $cpu cpuID                                    $cpuID
    set_instance_parameter $cpu setting_activateTrace                    $setting_activateTrace
    set_instance_parameter $cpu tracefilename                            $tracefilename
    set_instance_parameter $cpu setting_showUnpublishedSettings          $setting_showUnpublishedSettings
    set_instance_parameter $cpu setting_showInternalSettings             $setting_showInternalSettings
    set_instance_parameter $cpu setting_exportPCB                        $setting_exportPCB
    set_instance_parameter $cpu setting_exportdebuginfo                  $setting_exportdebuginfo
    set_instance_parameter $cpu setting_preciseIllegalMemAccessException $setting_preciseIllegalMemAccessException
    set_instance_parameter $cpu setting_branchPredictionType             $setting_branchpredictiontype
    set_instance_parameter $cpu setting_bhtPtrSz                         $setting_bhtPtrSz
    set_instance_parameter $cpu bht_ramBlockType                         $bht_ramBlockType
    set_instance_parameter $cpu regfile_ramBlockType                     $regfile_ramBlockType
    set_instance_parameter $cpu setting_ic_ecc_present                   $setting_ic_ecc_present
    set_instance_parameter $cpu setting_rf_ecc_present                   $setting_rf_ecc_present
    set_instance_parameter $cpu setting_dc_ecc_present                   $setting_dc_ecc_present
    set_instance_parameter $cpu setting_itcm_ecc_present                 $setting_itcm_ecc_present
    set_instance_parameter $cpu setting_dtcm_ecc_present                 $setting_dtcm_ecc_present
    set_instance_parameter $cpu setting_mmu_ecc_present                  $setting_mmu_ecc_present
    set_instance_parameter $cpu resetrequest_enabled                     $resetrequest_enabled

    # TEST/ASIC
    set setting_disableocitrace                [ get_parameter_value setting_disableocitrace                ]
    set setting_activateMonitors               [ get_parameter_value setting_activateMonitors               ]
    set setting_clearXBitsLDNonBypass          [ get_parameter_value setting_clearXBitsLDNonBypass          ]
    set setting_HDLSimCachesCleared            [ get_parameter_value setting_HDLSimCachesCleared            ]
    set setting_activateTestEndChecker         [ get_parameter_value setting_activateTestEndChecker         ]
    set setting_ecc_sim_test_ports             [ get_parameter_value setting_ecc_sim_test_ports             ]
    set setting_alwaysEncrypt                  [ get_parameter_value setting_alwaysEncrypt                  ]
    set setting_HBreakTest                     [ get_parameter_value setting_HBreakTest                     ]
    set setting_breakslaveoveride              [ get_parameter_value setting_breakslaveoveride              ]
    set setting_avalonDebugPortPresent         [ get_parameter_value setting_avalonDebugPortPresent         ]
    set debug_triggerArming                    [ get_parameter_value debug_triggerArming                    ]
    set setting_allow_break_inst               [ get_parameter_value setting_allow_break_inst               ]
    set ocimem_ramInit                         [ get_parameter_value ocimem_ramInit                         ]
    set userDefinedSettings                    [ get_parameter_value userDefinedSettings                    ]
    set setting_asic_enabled                   [ get_parameter_value setting_asic_enabled                   ]
    set setting_usedesignware                  [ get_parameter_value setting_usedesignware                  ]
    set setting_export_large_RAMs              [ get_parameter_value setting_export_large_RAMs              ]
    set setting_oci_export_jtag_signals        [ get_parameter_value setting_oci_export_jtag_signals        ]
    set setting_asic_third_party_synthesis     [ get_parameter_value setting_asic_third_party_synthesis     ]
    set setting_asic_add_scan_mode_input       [ get_parameter_value setting_asic_add_scan_mode_input       ]
    set setting_asic_synopsys_translate_on_off [ get_parameter_value setting_asic_synopsys_translate_on_off ]
    set register_file_por					   [ get_parameter_value register_file_por						]
    set setting_removeRAMinit                  [ get_parameter_value setting_removeRAMinit                  ]
    
    # special parameter overriders
    if { $setting_oci_version == 2 } {
        set setting_avalonDebugPortPresent False
        set setting_oci_export_jtag_signals False
    }

    set_instance_parameter $cpu setting_disableocitrace                $setting_disableocitrace
    set_instance_parameter $cpu setting_activateMonitors               $setting_activateMonitors
    set_instance_parameter $cpu setting_clearXBitsLDNonBypass          $setting_clearXBitsLDNonBypass
    set_instance_parameter $cpu setting_HDLSimCachesCleared            $setting_HDLSimCachesCleared
    set_instance_parameter $cpu setting_activateTestEndChecker         $setting_activateTestEndChecker
    set_instance_parameter $cpu setting_ecc_sim_test_ports             $setting_ecc_sim_test_ports
    set_instance_parameter $cpu setting_alwaysEncrypt                  $setting_alwaysEncrypt
    set_instance_parameter $cpu setting_HBreakTest                     $setting_HBreakTest
    set_instance_parameter $cpu setting_breakslaveoveride              $setting_breakslaveoveride
    set_instance_parameter $cpu setting_avalonDebugPortPresent         $setting_avalonDebugPortPresent
    set_instance_parameter $cpu debug_triggerArming                    $debug_triggerArming
    set_instance_parameter $cpu setting_allow_break_inst               $setting_allow_break_inst
    set_instance_parameter $cpu ocimem_ramInit                         $ocimem_ramInit
    set_instance_parameter $cpu userDefinedSettings                    $userDefinedSettings
    set_instance_parameter $cpu setting_asic_enabled                   $setting_asic_enabled
    set_instance_parameter $cpu setting_usedesignware                  $setting_usedesignware
    set_instance_parameter $cpu setting_export_large_RAMs              $setting_export_large_RAMs
    set_instance_parameter $cpu setting_oci_export_jtag_signals        $setting_oci_export_jtag_signals
    set_instance_parameter $cpu setting_asic_third_party_synthesis     $setting_asic_third_party_synthesis
    set_instance_parameter $cpu setting_asic_add_scan_mode_input       $setting_asic_add_scan_mode_input
    set_instance_parameter $cpu setting_asic_synopsys_translate_on_off $setting_asic_synopsys_translate_on_off
    set_instance_parameter $cpu setting_removeRAMinit                  $setting_removeRAMinit
    set_instance_parameter $cpu setting_oci_version                    $setting_oci_version
    set_instance_parameter $cpu register_file_por                      $register_file_por

    # Derived parameter
    set resetAbsoluteAddr              [ get_parameter_value resetAbsoluteAddr            ]
    set exceptionAbsoluteAddr          [ get_parameter_value exceptionAbsoluteAddr        ]
    set breakAbsoluteAddr              [ get_parameter_value breakAbsoluteAddr            ]
    set mmu_TLBMissExcAbsAddr          [ get_parameter_value mmu_TLBMissExcAbsAddr        ]
    set dcache_bursts_derived          [ get_parameter_value dcache_bursts_derived        ]
    set dcache_size_derived            [ get_parameter_value dcache_size_derived          ]
    set breakSlave_derived             [ get_parameter_value breakSlave_derived           ]
    set dcache_lineSize_derived        [ get_parameter_value dcache_lineSize_derived      ]
    set dcache_bursts_derived          [ get_parameter_value dcache_bursts_derived        ]
    set dcache_size_derived            [ get_parameter_value dcache_size_derived          ]
    set dcache_lineSize_derived        [ get_parameter_value dcache_lineSize_derived      ]
    set breakSlave_derived             [ get_parameter_value breakSlave_derived           ]
    set setting_ioregionBypassDCache   [ get_parameter_value setting_ioregionBypassDCache ]
    set setting_ioregionBypassDCache   [ get_parameter_value setting_ioregionBypassDCache ]
    set setting_bit31BypassDCache      [ get_parameter_value setting_bit31BypassDCache    ]
    set setting_bit31BypassDCache      [ get_parameter_value setting_bit31BypassDCache    ]
    set translate_on                   [ get_parameter_value translate_on                 ]
    set translate_off                  [ get_parameter_value translate_off                ]
    set debug_onchiptrace              [ get_parameter_value debug_onchiptrace            ]
    set debug_offchiptrace             [ get_parameter_value debug_offchiptrace           ]
    set debug_insttrace                [ get_parameter_value debug_insttrace              ]
    set debug_datatrace                [ get_parameter_value debug_datatrace              ]
    
    set_instance_parameter $cpu resetAbsoluteAddr            $resetAbsoluteAddr
    set_instance_parameter $cpu exceptionAbsoluteAddr        $exceptionAbsoluteAddr
    set_instance_parameter $cpu breakAbsoluteAddr            $breakAbsoluteAddr
    set_instance_parameter $cpu mmu_TLBMissExcAbsAddr        $mmu_TLBMissExcAbsAddr
    set_instance_parameter $cpu dcache_bursts_derived        $dcache_bursts_derived
    set_instance_parameter $cpu dcache_size_derived          $dcache_size_derived
    set_instance_parameter $cpu breakSlave_derived           $breakSlave_derived
    set_instance_parameter $cpu dcache_lineSize_derived      $dcache_lineSize_derived
    set_instance_parameter $cpu dcache_bursts_derived        $dcache_bursts_derived
    set_instance_parameter $cpu dcache_size_derived          $dcache_size_derived
    set_instance_parameter $cpu dcache_lineSize_derived      $dcache_lineSize_derived
    set_instance_parameter $cpu breakSlave_derived           $breakSlave_derived
    set_instance_parameter $cpu setting_ioregionBypassDCache $setting_ioregionBypassDCache
    set_instance_parameter $cpu setting_ioregionBypassDCache $setting_ioregionBypassDCache
    set_instance_parameter $cpu setting_bit31BypassDCache    $setting_bit31BypassDCache
    set_instance_parameter $cpu setting_bit31BypassDCache    $setting_bit31BypassDCache
    set_instance_parameter $cpu translate_on                 $translate_on
    set_instance_parameter $cpu translate_off                $translate_off
    set_instance_parameter $cpu debug_onchiptrace            $debug_onchiptrace
    set_instance_parameter $cpu debug_offchiptrace           $debug_offchiptrace
    set_instance_parameter $cpu debug_insttrace              $debug_insttrace
    set_instance_parameter $cpu debug_datatrace              $debug_datatrace
}

proc compose {} {
    global DEBUG_HOST_INTF
    global HBREAK_IRQ_INTF
    global IHP_PREFIX
    global DHP_PREFIX
    global TCI_PREFIX
    global TCD_PREFIX
    global TCI_INTF_PREFIX
    global TCD_INTF_PREFIX

    # OCI parameter
    set local_debug_level           [ get_parameter_value debug_enabled ]
    set setting_exportHostDebugPort [ get_parameter_value setting_exportHostDebugPort ]
    set impl                        [ get_parameter_value impl                        ]  
    set setting_oci_version         [ get_parameter_value setting_oci_version         ]
    set debug_assignJtagInstanceID [ get_parameter_value debug_assignJtagInstanceID ]
    set debug_jtagInstanceID       [ get_parameter_value debug_jtagInstanceID       ]
    set onchip_trace_support [ proc_get_boolean_parameter debug_onchiptrace ]
    set oci_trace_addr_width [ proc_get_oci_trace_addr_width ]
        
    # TMR Parameter
    set tmr_enabled [ get_parameter_value tmr_enabled ]
    set instAddrWidth               [ get_parameter_value instAddrWidth               ]
    set dataAddrWidth               [ get_parameter_value dataAddrWidth               ]

    # Reset bridge may be removed in the future
    add_instance clock_bridge altera_clock_bridge
    add_instance reset_bridge altera_reset_bridge
    
    set register_file_por [ get_parameter_value register_file_por]
    
    if { ${register_file_por} && $impl == "Small" } {
    	add_instance 		   por_rf_bridge altera_reset_bridge	
		set_instance_parameter por_rf_bridge NUM_RESET_OUTPUTS 1
		set_instance_parameter por_rf_bridge ACTIVE_LOW_RESET true
		set_instance_parameter por_rf_bridge USE_RESET_REQUEST false
		
		add_connection clock_bridge.out_clk por_rf_bridge.clk
		
		add_interface           por_rf     "reset"     "sink"
    	set_interface_property  por_rf EXPORT_OF por_rf_bridge.in_reset
		set_interface_property  por_rf PORT_NAME_MAP "por_rf_n in_reset_n"
	}

    if { $tmr_enabled } {
        add_instance nios_tmr_comparator altera_nios2_tmr_comparator
        
        add_instance nios_a altera_nios2_gen2_unit
        add_cpu_instance nios_a
        add_instance nios_b altera_nios2_gen2_unit
        add_cpu_instance nios_b
        add_instance nios_c altera_nios2_gen2_unit
        add_cpu_instance nios_c
        set cpu_multi "customInstSlavesSystemInfo_nios_a"
    } else {
        add_instance cpu altera_nios2_gen2_unit
        add_cpu_instance cpu
        set cpu_multi "customInstSlavesSystemInfo"
    }

    elaborate

    set_instance_parameter clock_bridge NUM_CLOCK_OUTPUTS 1
    set_instance_parameter reset_bridge NUM_RESET_OUTPUTS 1
    set_instance_parameter reset_bridge ACTIVE_LOW_RESET true
    
    set has_multi [ proc_has_multi_ci_slave $cpu_multi ]
    set setting_export_large_RAMs [ proc_get_boolean_parameter setting_export_large_RAMs ]
    set resetrequest_enabled [ proc_get_boolean_parameter resetrequest_enabled ]
    set oci_ram_present [ expr { $local_debug_level && !$setting_export_large_RAMs } ]
    
    if { (($oci_ram_present && $setting_oci_version == 1) || $has_multi) && $resetrequest_enabled} {
        set_instance_parameter reset_bridge USE_RESET_REQUEST true
    } else {
        set_instance_parameter reset_bridge USE_RESET_REQUEST false
    }
   
    add_connection clock_bridge.out_clk reset_bridge.clk
       
    # derived value for address widths
    set master_addr_map                                         [ get_parameter_value master_addr_map                                 ]
    set instruction_master_paddr_base                           [ proc_num2hex [ get_parameter_value instruction_master_paddr_base                   ]]
    set instruction_master_paddr_size                           [ expr abs([get_parameter_value instruction_master_paddr_size                        ])]
    set flash_instruction_master_paddr_base                     [ proc_num2hex [ get_parameter_value flash_instruction_master_paddr_base             ]]
    set flash_instruction_master_paddr_size                     [ expr abs([get_parameter_value flash_instruction_master_paddr_size                 ])]
    set data_master_paddr_base                                  [ proc_num2hex [ get_parameter_value data_master_paddr_base                          ]]
    set data_master_paddr_size                                  [ expr abs([ get_parameter_value data_master_paddr_size                             ])]
    set tightly_coupled_instruction_master_0_paddr_base         [ proc_num2hex [ get_parameter_value tightly_coupled_instruction_master_0_paddr_base ]]
    set tightly_coupled_instruction_master_0_paddr_size         [ expr abs([get_parameter_value tightly_coupled_instruction_master_0_paddr_size     ])]
    set tightly_coupled_instruction_master_1_paddr_base         [ proc_num2hex [ get_parameter_value tightly_coupled_instruction_master_1_paddr_base ]]
    set tightly_coupled_instruction_master_1_paddr_size         [ expr abs([get_parameter_value tightly_coupled_instruction_master_1_paddr_size     ])]
    set tightly_coupled_instruction_master_2_paddr_base         [ proc_num2hex [ get_parameter_value tightly_coupled_instruction_master_2_paddr_base ]]
    set tightly_coupled_instruction_master_2_paddr_size         [ expr abs([get_parameter_value tightly_coupled_instruction_master_2_paddr_size     ])]
    set tightly_coupled_instruction_master_3_paddr_base         [ proc_num2hex [ get_parameter_value tightly_coupled_instruction_master_3_paddr_base ]]
    set tightly_coupled_instruction_master_3_paddr_size         [ expr abs([get_parameter_value tightly_coupled_instruction_master_3_paddr_size     ])]
    set tightly_coupled_data_master_0_paddr_base                [ proc_num2hex [ get_parameter_value tightly_coupled_data_master_0_paddr_base        ]]
    set tightly_coupled_data_master_0_paddr_size                [ expr abs([get_parameter_value tightly_coupled_data_master_0_paddr_size            ])]
    set tightly_coupled_data_master_1_paddr_base                [ proc_num2hex [ get_parameter_value tightly_coupled_data_master_1_paddr_base        ]]
    set tightly_coupled_data_master_1_paddr_size                [ expr abs([get_parameter_value tightly_coupled_data_master_1_paddr_size            ])]
    set tightly_coupled_data_master_2_paddr_base                [ proc_num2hex [ get_parameter_value tightly_coupled_data_master_2_paddr_base        ]]
    set tightly_coupled_data_master_2_paddr_size                [ expr abs([get_parameter_value tightly_coupled_data_master_2_paddr_size            ])]
    set tightly_coupled_data_master_3_paddr_base                [ proc_num2hex [ get_parameter_value tightly_coupled_data_master_3_paddr_base        ]]
    set tightly_coupled_data_master_3_paddr_size                [ expr abs([get_parameter_value tightly_coupled_data_master_3_paddr_size            ])]
    set instruction_master_high_performance_paddr_base          [ proc_num2hex [ expr [ get_parameter_value instruction_master_high_performance_paddr_base  ] & 0xffffffff ] ]
    set instruction_master_high_performance_paddr_size          [ expr abs([get_parameter_value instruction_master_high_performance_paddr_size      ])]
    set data_master_high_performance_paddr_base                 [ proc_num2hex [ expr [ get_parameter_value data_master_high_performance_paddr_base         ] & 0xffffffff ] ]
    set data_master_high_performance_paddr_size                 [ expr abs([get_parameter_value data_master_high_performance_paddr_size             ])]

    # top address = base + size - 1
    set instruction_master_paddr_top                       [ proc_num2hex [ expr ($instruction_master_paddr_base                    + $instruction_master_paddr_size                   - 1) & 0xffffffff ]]
    set flash_instruction_master_paddr_top                 [ proc_num2hex [ expr ($flash_instruction_master_paddr_base              + $flash_instruction_master_paddr_size             - 1) & 0xffffffff ]]      
    set data_master_paddr_top                              [ proc_num2hex [ expr ($data_master_paddr_base                           + $data_master_paddr_size                          - 1) & 0xffffffff ]]
    set tightly_coupled_instruction_master_0_paddr_top     [ proc_num2hex [ expr ($tightly_coupled_instruction_master_0_paddr_base  + $tightly_coupled_instruction_master_0_paddr_size - 1) & 0xffffffff ]]
    set tightly_coupled_instruction_master_1_paddr_top     [ proc_num2hex [ expr ($tightly_coupled_instruction_master_1_paddr_base  + $tightly_coupled_instruction_master_1_paddr_size - 1) & 0xffffffff ]]
    set tightly_coupled_instruction_master_2_paddr_top     [ proc_num2hex [ expr ($tightly_coupled_instruction_master_2_paddr_base  + $tightly_coupled_instruction_master_2_paddr_size - 1) & 0xffffffff ]]
    set tightly_coupled_instruction_master_3_paddr_top     [ proc_num2hex [ expr ($tightly_coupled_instruction_master_3_paddr_base  + $tightly_coupled_instruction_master_3_paddr_size - 1) & 0xffffffff ]]
    set tightly_coupled_data_master_0_paddr_top            [ proc_num2hex [ expr ($tightly_coupled_data_master_0_paddr_base         + $tightly_coupled_data_master_0_paddr_size        - 1) & 0xffffffff ]]
    set tightly_coupled_data_master_1_paddr_top            [ proc_num2hex [ expr ($tightly_coupled_data_master_1_paddr_base         + $tightly_coupled_data_master_1_paddr_size        - 1) & 0xffffffff ]]
    set tightly_coupled_data_master_2_paddr_top            [ proc_num2hex [ expr ($tightly_coupled_data_master_2_paddr_base         + $tightly_coupled_data_master_2_paddr_size        - 1) & 0xffffffff ]]
    set tightly_coupled_data_master_3_paddr_top            [ proc_num2hex [ expr ($tightly_coupled_data_master_3_paddr_base         + $tightly_coupled_data_master_3_paddr_size        - 1) & 0xffffffff ]]
    set instruction_master_high_performance_paddr_top      [ proc_num2hex [ expr ($instruction_master_high_performance_paddr_base   + $instruction_master_high_performance_paddr_size  - 1) & 0xffffffff ] ]
    set data_master_high_performance_paddr_top             [ proc_num2hex [ expr ($data_master_high_performance_paddr_base          + $data_master_high_performance_paddr_size         - 1) & 0xffffffff ] ]

    # reassign top address to 0 in case the size is 0
	if { $instruction_master_paddr_size == 0 } { 
		set instruction_master_paddr_top                        0
	}
	if { $flash_instruction_master_paddr_size == 0 } {
		set flash_instruction_master_paddr_top                  0
	}
	if { $data_master_paddr_size == 0 } {
		set data_master_paddr_top                               0
	}
	if { $tightly_coupled_instruction_master_0_paddr_size == 0 } {
		set tightly_coupled_instruction_master_0_paddr_top      0
	}
	if { $tightly_coupled_instruction_master_1_paddr_size == 0 } {
		set tightly_coupled_instruction_master_1_paddr_top      0
	}
	if { $tightly_coupled_instruction_master_2_paddr_size == 0 } {
		set tightly_coupled_instruction_master_2_paddr_top      0
	}
	if { $tightly_coupled_instruction_master_3_paddr_size == 0 } {
		set tightly_coupled_instruction_master_3_paddr_top      0
	}
	if { $tightly_coupled_data_master_0_paddr_size == 0 } {
		set tightly_coupled_data_master_0_paddr_top             0
	}
	if { $tightly_coupled_data_master_1_paddr_size == 0 } {
		set tightly_coupled_data_master_1_paddr_top             0
	}
	if { $tightly_coupled_data_master_2_paddr_size == 0 } {
		set tightly_coupled_data_master_2_paddr_top             0
	}
	if { $tightly_coupled_data_master_3_paddr_size == 0 } {
		set tightly_coupled_data_master_3_paddr_top             0
	}
	if { $instruction_master_high_performance_paddr_size == 0 } {
		set instruction_master_high_performance_paddr_top       0
	}
	if { $data_master_high_performance_paddr_size == 0 } {
		set data_master_high_performance_paddr_top              0
	}
    # if it is set derived the width from the size log(size)/log(2)    
    set instruction_master_addrwidth                       [ proc_num2sz $instruction_master_paddr_top                   ]
    set flash_instruction_master_addrwidth                 [ proc_num2sz $flash_instruction_master_paddr_top             ]      
    set data_master_addrwidth                              [ proc_num2sz $data_master_paddr_top                          ]
    set tightly_coupled_instruction_master_0_addrwidth     [ proc_num2sz $tightly_coupled_instruction_master_0_paddr_top ]
    set tightly_coupled_instruction_master_1_addrwidth     [ proc_num2sz $tightly_coupled_instruction_master_1_paddr_top ]
    set tightly_coupled_instruction_master_2_addrwidth     [ proc_num2sz $tightly_coupled_instruction_master_2_paddr_top ]
    set tightly_coupled_instruction_master_3_addrwidth     [ proc_num2sz $tightly_coupled_instruction_master_3_paddr_top ]
    set tightly_coupled_data_master_0_addrwidth            [ proc_num2sz $tightly_coupled_data_master_0_paddr_top        ]
    set tightly_coupled_data_master_1_addrwidth            [ proc_num2sz $tightly_coupled_data_master_1_paddr_top        ]
    set tightly_coupled_data_master_2_addrwidth            [ proc_num2sz $tightly_coupled_data_master_2_paddr_top        ]
    set tightly_coupled_data_master_3_addrwidth            [ proc_num2sz $tightly_coupled_data_master_3_paddr_top        ]
    set instruction_master_high_performance_addrwidth      [ proc_num2sz $instruction_master_high_performance_paddr_top  ]
    set data_master_high_performance_addrwidth             [ proc_num2sz $data_master_high_performance_paddr_top         ]
    
    if { $tmr_enabled } {
      
        set_instance_property nios_tmr_comparator SUPPRESS_ALL_WARNINGS true
        set_instance_property nios_tmr_comparator SUPPRESS_ALL_INFO_MESSAGES true
    
        add_connection clock_bridge.out_clk nios_tmr_comparator.clock
        add_connection reset_bridge.out_reset nios_tmr_comparator.reset
        add_connection clock_bridge.out_clk nios_a.clk
        add_connection reset_bridge.out_reset nios_a.reset
        add_connection clock_bridge.out_clk nios_b.clk
        add_connection reset_bridge.out_reset nios_b.reset
        add_connection clock_bridge.out_clk nios_c.clk
        add_connection reset_bridge.out_reset nios_c.reset
        
        if { ${register_file_por} && $impl == "Small" } {
        	add_connection por_rf_bridge.out_reset nios_a.por_rf
        	add_connection por_rf_bridge.out_reset nios_b.por_rf
        	add_connection por_rf_bridge.out_reset nios_c.por_rf
        }
        
        set response_present [ string match "Small" "$impl" ]
        set_instance_parameter_value nios_tmr_comparator response_present $response_present
        
        # Disable error injection
        set setting_disable_tmr_inj     [ get_parameter_value setting_disable_tmr_inj ]
        set_instance_parameter_value nios_tmr_comparator disable_tmr_err_inj $setting_disable_tmr_inj

        set local_icache_bursttype      [ get_parameter_value icache_burstType ]
        set icache_size [get_parameter_value icache_size]
        set has_i_burstcount [ expr { "$icache_size" != "0" } && { "$impl" == "Fast" } && { "$local_icache_bursttype" != "None" } ]
        set has_i_readdatavalid [ expr { "$impl" == "Fast" } && { "$icache_size" != "0" } ]
        
        set local_dcache_burst_derived       [ proc_get_boolean_parameter dcache_bursts_derived ]
        set local_dcache_size_derived        [get_parameter_value dcache_size_derived]
        set has_d_burstcount [ expr { "$impl" == "Fast" } && { "$local_dcache_size_derived" != "0" } && { $local_dcache_burst_derived } ]
        set d_readdatavalid_exist [ expr  { "$impl" == "Fast" } && { "$local_dcache_size_derived" != "0" } ]

        if { $master_addr_map } {
        	set_instance_parameter_value nios_tmr_comparator I_MASTER_ADDRESS_WIDTH $instruction_master_addrwidth
        	set_instance_parameter_value nios_tmr_comparator D_MASTER_ADDRESS_WIDTH $data_master_addrwidth 
        } else {
        	set_instance_parameter_value nios_tmr_comparator I_MASTER_ADDRESS_WIDTH $instAddrWidth
        	set_instance_parameter_value nios_tmr_comparator D_MASTER_ADDRESS_WIDTH $dataAddrWidth 
        }
        set_instance_parameter_value nios_tmr_comparator i_burstcount_present $has_i_burstcount
        set_instance_parameter_value nios_tmr_comparator i_readdatavalid_present $has_i_readdatavalid
        
        set_instance_parameter_value nios_tmr_comparator d_burstcount_present $has_d_burstcount
        set_instance_parameter_value nios_tmr_comparator d_readdatavalid_present $d_readdatavalid_exist
        
        set has_dcache [ expr { "$impl" == "Fast" } && { "$local_dcache_size_derived" != "0" } ]
    
        if { "$has_dcache" == "1" } {
            set_instance_parameter_value nios_tmr_comparator d_registerIncomingSignals false
        } elseif { "$impl" != "Tiny" } {
            set_instance_parameter_value nios_tmr_comparator d_registerIncomingSignals false
        } else {
            set_instance_parameter_value nios_tmr_comparator d_registerIncomingSignals true
        }
    
        add_connection nios_a.instruction_master nios_tmr_comparator.instruction_master_a avalon
        add_connection nios_b.instruction_master nios_tmr_comparator.instruction_master_b avalon
        add_connection nios_c.instruction_master nios_tmr_comparator.instruction_master_c avalon
        add_connection nios_a.data_master nios_tmr_comparator.data_master_a avalon
        add_connection nios_b.data_master nios_tmr_comparator.data_master_b avalon
        add_connection nios_c.data_master nios_tmr_comparator.data_master_c avalon
        
        # flash instruction master
        set fa_cache_line 		[ proc_get_boolean_parameter fa_cache_line  ]
        set fa_cache_linesize 	[ get_parameter_value fa_cache_linesize 	]
        set mmu_enabled       	[ get_parameter_value mmu_enabled       	]
        set faAddrWidth         [ get_parameter_value faAddrWidth           ]
        
        set fa_present [ expr $fa_cache_linesize > 0 && { "$impl" == "Fast" } && !$mmu_enabled ]
        if { $fa_cache_linesize == 8 } {
        	set fa_burstcount_size 2
        } else {
        	set fa_burstcount_size 3
        }
    
        set_instance_parameter_value nios_tmr_comparator FA_PRESENT $fa_present
        if { $master_addr_map } {
        	set_instance_parameter_value nios_tmr_comparator FA_MASTER_ADDRESS_WIDTH $flash_instruction_master_addrwidth
        } else {
        	set_instance_parameter_value nios_tmr_comparator FA_MASTER_ADDRESS_WIDTH $faAddrWidth
        }
        set_instance_parameter_value nios_tmr_comparator FA_MASTER_BURST_WIDTH $fa_burstcount_size
        if { $fa_present } {
        	add_connection nios_a.flash_instruction_master nios_tmr_comparator.flash_instruction_master_a avalon
        	add_connection nios_b.flash_instruction_master nios_tmr_comparator.flash_instruction_master_b avalon
        	add_connection nios_c.flash_instruction_master nios_tmr_comparator.flash_instruction_master_c avalon
        }
        
        set tcim_num    [ get_parameter_value icache_numTCIM ]
        set tcdm_num    [ get_parameter_value dcache_numTCDM ]
        set ecc_present [ get_parameter_value setting_ecc_present ]
        set setting_itcm_ecc_present [ get_parameter_value setting_itcm_ecc_present ]
        set setting_dtcm_ecc_present [ get_parameter_value setting_dtcm_ecc_present ]
    
        if { "${impl}" != "Tiny" } {
          set itcm_ecc_present [ expr $ecc_present && { "$impl" == "Fast" } && $setting_itcm_ecc_present ] 

          set_instance_parameter_value nios_tmr_comparator itcm_num $tcim_num
          set_instance_parameter_value nios_tmr_comparator itcm_ecc_present $itcm_ecc_present
          if { $master_addr_map } {
          	set_instance_parameter_value nios_tmr_comparator TCIM_MASTER_ADDRESS_WIDTH0 $tightly_coupled_instruction_master_0_addrwidth
          	set_instance_parameter_value nios_tmr_comparator TCIM_MASTER_ADDRESS_WIDTH1 $tightly_coupled_instruction_master_1_addrwidth
          	set_instance_parameter_value nios_tmr_comparator TCIM_MASTER_ADDRESS_WIDTH2 $tightly_coupled_instruction_master_2_addrwidth
          	set_instance_parameter_value nios_tmr_comparator TCIM_MASTER_ADDRESS_WIDTH3 $tightly_coupled_instruction_master_3_addrwidth
          } else {
            set_instance_parameter_value nios_tmr_comparator TCIM_MASTER_ADDRESS_WIDTH0 [ get_parameter_value ${TCI_PREFIX}0AddrWidth ]
          	set_instance_parameter_value nios_tmr_comparator TCIM_MASTER_ADDRESS_WIDTH1 [ get_parameter_value ${TCI_PREFIX}1AddrWidth ]
          	set_instance_parameter_value nios_tmr_comparator TCIM_MASTER_ADDRESS_WIDTH2 [ get_parameter_value ${TCI_PREFIX}2AddrWidth ]
          	set_instance_parameter_value nios_tmr_comparator TCIM_MASTER_ADDRESS_WIDTH3 [ get_parameter_value ${TCI_PREFIX}3AddrWidth ]
          }
          
          foreach i {0 1 2 3} {
            if { $i < $tcim_num } {
              add_connection nios_a.$TCI_INTF_PREFIX${i} nios_tmr_comparator.$TCI_INTF_PREFIX${i}_a avalon
              add_connection nios_b.$TCI_INTF_PREFIX${i} nios_tmr_comparator.$TCI_INTF_PREFIX${i}_b avalon
              add_connection nios_c.$TCI_INTF_PREFIX${i} nios_tmr_comparator.$TCI_INTF_PREFIX${i}_c avalon
            }
          }
          
          set dtcm_ecc_present [ expr $ecc_present && { "$impl" == "Fast" } && $setting_dtcm_ecc_present ] 

          set_instance_parameter_value nios_tmr_comparator dtcm_num $tcdm_num
          set_instance_parameter_value nios_tmr_comparator dtcm_ecc_present $dtcm_ecc_present
          if { $master_addr_map } {
          	set_instance_parameter_value nios_tmr_comparator TCDM_MASTER_ADDRESS_WIDTH0 $tightly_coupled_data_master_0_addrwidth
          	set_instance_parameter_value nios_tmr_comparator TCDM_MASTER_ADDRESS_WIDTH1 $tightly_coupled_data_master_1_addrwidth
          	set_instance_parameter_value nios_tmr_comparator TCDM_MASTER_ADDRESS_WIDTH2 $tightly_coupled_data_master_2_addrwidth
          	set_instance_parameter_value nios_tmr_comparator TCDM_MASTER_ADDRESS_WIDTH3 $tightly_coupled_data_master_3_addrwidth
          } else {
            set_instance_parameter_value nios_tmr_comparator TCDM_MASTER_ADDRESS_WIDTH0 [ get_parameter_value ${TCD_PREFIX}0AddrWidth ]
          	set_instance_parameter_value nios_tmr_comparator TCDM_MASTER_ADDRESS_WIDTH1 [ get_parameter_value ${TCD_PREFIX}1AddrWidth ]
          	set_instance_parameter_value nios_tmr_comparator TCDM_MASTER_ADDRESS_WIDTH2 [ get_parameter_value ${TCD_PREFIX}2AddrWidth ]
          	set_instance_parameter_value nios_tmr_comparator TCDM_MASTER_ADDRESS_WIDTH3 [ get_parameter_value ${TCD_PREFIX}3AddrWidth ]
          }
          
          foreach i {0 1 2 3} {
            if { $i < $tcdm_num } {
              add_connection nios_a.$TCD_INTF_PREFIX${i} nios_tmr_comparator.$TCD_INTF_PREFIX${i}_a avalon
              add_connection nios_b.$TCD_INTF_PREFIX${i} nios_tmr_comparator.$TCD_INTF_PREFIX${i}_b avalon
              add_connection nios_c.$TCD_INTF_PREFIX${i} nios_tmr_comparator.$TCD_INTF_PREFIX${i}_c avalon
            }
          }
        }
        
        # High performance Data/Instruction Master
        # only for M-core
        if { "$impl" == "Small" } {
          set local_iaddr_width [ get_parameter_value ${IHP_PREFIX}AddrWidth ]
          set local_daddr_width [ get_parameter_value ${DHP_PREFIX}AddrWidth ]
          
          set_instance_parameter_value nios_tmr_comparator high_performance_present true
          if { $master_addr_map } {
          	  set_instance_parameter_value nios_tmr_comparator IHP_MASTER_ADDRESS_WIDTH $instruction_master_high_performance_addrwidth
          	  set_instance_parameter_value nios_tmr_comparator DHP_MASTER_ADDRESS_WIDTH $data_master_high_performance_addrwidth
          } else {
          	  set_instance_parameter_value nios_tmr_comparator IHP_MASTER_ADDRESS_WIDTH $local_iaddr_width
          	  set_instance_parameter_value nios_tmr_comparator DHP_MASTER_ADDRESS_WIDTH $local_daddr_width
          }
          add_connection nios_a.instruction_master_high_performance nios_tmr_comparator.instruction_master_high_performance_a avalon
          add_connection nios_b.instruction_master_high_performance nios_tmr_comparator.instruction_master_high_performance_b avalon
          add_connection nios_c.instruction_master_high_performance nios_tmr_comparator.instruction_master_high_performance_c avalon
          add_connection nios_a.data_master_high_performance nios_tmr_comparator.data_master_high_performance_a avalon
          add_connection nios_b.data_master_high_performance nios_tmr_comparator.data_master_high_performance_b avalon
          add_connection nios_c.data_master_high_performance nios_tmr_comparator.data_master_high_performance_c avalon
        }
        
        set is_oci_version_1 [ expr $local_debug_level && { $setting_oci_version == 1 } ]
        set is_oci_version_2 [ expr $local_debug_level && { $setting_oci_version == 2 } ]

        if { $is_oci_version_2 } {
          set_instance_parameter_value nios_tmr_comparator debug_host_slave_present true
          add_connection nios_tmr_comparator.debug_host_slave_a nios_a.debug_host_slave avalon
          add_connection nios_tmr_comparator.debug_host_slave_b nios_b.debug_host_slave avalon
          add_connection nios_tmr_comparator.debug_host_slave_c nios_c.debug_host_slave avalon
          
          add_connection nios_tmr_comparator.debug_extra_a nios_a.debug_extra avalon
          add_connection nios_tmr_comparator.debug_extra_b nios_b.debug_extra avalon
          add_connection nios_tmr_comparator.debug_extra_c nios_c.debug_extra avalon
          
          if { $onchip_trace_support } {
            set_instance_parameter_value nios_tmr_comparator debug_trace_slave_present true
            set_instance_parameter_value nios_tmr_comparator DEBUG_TRACE_ADDRESS_WIDTH [ expr {$oci_trace_addr_width + 1 } ]
            add_connection nios_tmr_comparator.debug_trace_slave_a nios_a.debug_trace_slave avalon
            add_connection nios_tmr_comparator.debug_trace_slave_b nios_b.debug_trace_slave avalon
            add_connection nios_tmr_comparator.debug_trace_slave_c nios_c.debug_trace_slave avalon
          }
        }
        
        if { $is_oci_version_1 } {
          set_instance_parameter_value nios_tmr_comparator debug_mem_slave_present true
          add_connection nios_tmr_comparator.debug_mem_slave_a nios_a.debug_mem_slave avalon
          add_connection nios_tmr_comparator.debug_mem_slave_b nios_b.debug_mem_slave avalon
          add_connection nios_tmr_comparator.debug_mem_slave_c nios_c.debug_mem_slave avalon
        }

        if { $local_debug_level } {
          set_instance_parameter_value nios_tmr_comparator debug_present true
          add_connection nios_a.debug_reset_request  nios_tmr_comparator.debug_reset_request_a
        }
        
        # interrupt
        set eic_present [ proc_get_eic_present ]
        if { $eic_present } {
          set_instance_parameter_value nios_tmr_comparator eic_present true
          
          add_connection nios_tmr_comparator.interrupt_controller_in_a nios_a.interrupt_controller_in avalon
          add_connection nios_tmr_comparator.interrupt_controller_in_b nios_b.interrupt_controller_in avalon
          add_connection nios_tmr_comparator.interrupt_controller_in_c nios_c.interrupt_controller_in avalon
        } else {
          set_instance_parameter_value nios_tmr_comparator eic_present false

          add_instance nios_irq_bridge altera_irq_bridge
          set_instance_parameter_value nios_irq_bridge {IRQ_WIDTH} {32}
          set_instance_parameter_value nios_irq_bridge {IRQ_N} {0}

          add_connection clock_bridge.out_clk nios_irq_bridge.clk clock
          add_connection reset_bridge.out_reset nios_irq_bridge.clk_reset reset
        
          for {set i 0} {$i < 32} {incr i} {
            add_connection nios_a.irq nios_irq_bridge.sender${i}_irq interrupt
            set_connection_parameter_value nios_a.irq/nios_irq_bridge.sender${i}_irq irqNumber $i
            add_connection nios_b.irq nios_irq_bridge.sender${i}_irq interrupt
            set_connection_parameter_value nios_b.irq/nios_irq_bridge.sender${i}_irq irqNumber $i
            add_connection nios_c.irq nios_irq_bridge.sender${i}_irq interrupt
            set_connection_parameter_value nios_c.irq/nios_irq_bridge.sender${i}_irq irqNumber $i
          }
          
        }
        
        # Hbreak IRQ
        set setting_HBreakTest [ proc_get_boolean_parameter setting_HBreakTest ]
        
        if { $setting_HBreakTest } {
          add_instance nios_hbreak_irq_bridge altera_irq_bridge
          if { "$impl" == "Tiny" } {
		      	set HBREAK_IRQ_WIDTH 1
		      } else {
		      	set HBREAK_IRQ_WIDTH 32
		      }
	      
          set_instance_parameter_value nios_hbreak_irq_bridge {IRQ_WIDTH} $HBREAK_IRQ_WIDTH
          set_instance_parameter_value nios_hbreak_irq_bridge {IRQ_N} {0}
          
          add_connection clock_bridge.out_clk nios_hbreak_irq_bridge.clk clock
          add_connection reset_bridge.out_reset nios_hbreak_irq_bridge.clk_reset reset
          
          for {set i 0} {$i < $HBREAK_IRQ_WIDTH} {incr i} {
            add_connection nios_a.$HBREAK_IRQ_INTF nios_hbreak_irq_bridge.sender${i}_irq interrupt
            set_connection_parameter_value nios_a.$HBREAK_IRQ_INTF/nios_hbreak_irq_bridge.sender${i}_irq irqNumber $i
            add_connection nios_b.$HBREAK_IRQ_INTF nios_hbreak_irq_bridge.sender${i}_irq interrupt
            set_connection_parameter_value nios_b.$HBREAK_IRQ_INTF/nios_hbreak_irq_bridge.sender${i}_irq irqNumber $i
            add_connection nios_c.$HBREAK_IRQ_INTF nios_hbreak_irq_bridge.sender${i}_irq interrupt
            set_connection_parameter_value nios_c.$HBREAK_IRQ_INTF/nios_hbreak_irq_bridge.sender${i}_irq irqNumber $i
          }
        }
        
        
        # special parameter overriders
        set AVALON_DEBUG_PORT_PRESENT [ get_parameter_value setting_avalonDebugPortPresent ]
        if { $is_oci_version_1 && $AVALON_DEBUG_PORT_PRESENT } {
          set_instance_parameter_value nios_tmr_comparator avalon_debug_port_present true
          add_connection nios_tmr_comparator.avalon_debug_port_a nios_a.avalon_debug_port avalon
          add_connection nios_tmr_comparator.avalon_debug_port_b nios_b.avalon_debug_port avalon
          add_connection nios_tmr_comparator.avalon_debug_port_c nios_c.avalon_debug_port avalon
        }
    
        # Conduits
        set include_debug_debugReqSignals   [ get_parameter_value debug_debugReqSignals ]
        set local_debug_offchiptrace        [ get_parameter_value debug_offchiptrace ]
        set local_debug_hwbreakpoint        [ get_parameter_value debug_hwbreakpoint ]
        set local_debug_datatrigger         [ get_parameter_value debug_datatrigger ]
    
        set debug_offchip_trace_trigout_present [ expr $local_debug_offchiptrace && { "$impl" != "Tiny" } && ( $local_debug_hwbreakpoint > 0 || $local_debug_datatrigger > 0 ) ]

        if {  ${local_debug_level} } {
          
          # Debug Conduits
          set_instance_parameter_value nios_tmr_comparator debugreqsignal_present $include_debug_debugReqSignals
          set_instance_parameter_value nios_tmr_comparator debug_offchiptrace_trigout_present $debug_offchip_trace_trigout_present
          if { $include_debug_debugReqSignals || $debug_offchip_trace_trigout_present } {
            add_connection nios_tmr_comparator.debug_conduit_a nios_a.debug_conduit conduit
            add_connection nios_tmr_comparator.debug_conduit_b nios_b.debug_conduit conduit
            add_connection nios_tmr_comparator.debug_conduit_c nios_c.debug_conduit conduit
          }
          
          if { $local_debug_offchiptrace && !("$impl" == "Tiny") } {
            set_instance_parameter_value nios_tmr_comparator debug_offchiptrace_present true
            add_connection nios_a.debug_offchip_trace  nios_tmr_comparator.debug_offchip_trace_a avalon
            add_connection nios_b.debug_offchip_trace  nios_tmr_comparator.debug_offchip_trace_b avalon
            add_connection nios_c.debug_offchip_trace  nios_tmr_comparator.debug_offchip_trace_c avalon 
          }
          
          set local_oci_export_jtag_signals   [ get_parameter_value setting_oci_export_jtag_signals ]
          # SLD JTAG signals
          if { $local_oci_export_jtag_signals && !$AVALON_DEBUG_PORT_PRESENT && $is_oci_version_1 } {
            set_instance_parameter_value nios_tmr_comparator sld_jtag_present true
            add_connection nios_tmr_comparator.sld_jtag_a nios_a.sld_jtag conduit
            add_connection nios_tmr_comparator.sld_jtag_b nios_b.sld_jtag conduit
            add_connection nios_tmr_comparator.sld_jtag_c nios_c.sld_jtag conduit
          }
          
          # debug_reset
          set local_asic_enabled              [ proc_get_boolean_parameter setting_asic_enabled ]
          if { [ expr { $setting_oci_version == 1 && $local_asic_enabled } ] || [ expr { $setting_oci_version == 2 && ${setting_exportHostDebugPort} } ] } {
            set_instance_parameter_value nios_tmr_comparator debug_reset_present true
            add_connection nios_tmr_comparator.debug_reset_a nios_a.debug_reset reset
            add_connection nios_tmr_comparator.debug_reset_b nios_b.debug_reset reset
            add_connection nios_tmr_comparator.debug_reset_c nios_c.debug_reset reset
          }
          
        }
        
        set setting_tmr_output_disable [ get_parameter_value setting_tmr_output_disable ]
        set_instance_parameter_value nios_tmr_comparator tmr_output_disable_present $setting_tmr_output_disable
        
        set local_instaddrwidth             [ get_parameter_value instAddrWidth ]
        set local_mmu_enable                [ proc_get_boolean_parameter mmu_enabled ]
        set local_exportvectors             [ proc_get_boolean_parameter setting_exportvectors     ]

        if { $local_mmu_enable } {
          set local_vector_width 30
        } else {
            set local_vector_width [ expr {$local_instaddrwidth - 2} ]
        }
    
        if { $local_exportvectors } {
          set_instance_parameter_value nios_tmr_comparator vector_width $local_vector_width
          set_instance_parameter_value nios_tmr_comparator export_vectors true
          set_instance_parameter_value nios_tmr_comparator export_mmu_vectors $local_mmu_enable

          add_connection nios_tmr_comparator.reset_vector_conduit_a     nios_a.reset_vector_conduit conduit
          add_connection nios_tmr_comparator.exception_vector_conduit_a nios_a.exception_vector_conduit  conduit
          add_connection nios_tmr_comparator.reset_vector_conduit_b     nios_b.reset_vector_conduit conduit
          add_connection nios_tmr_comparator.exception_vector_conduit_b nios_b.exception_vector_conduit  conduit
          add_connection nios_tmr_comparator.reset_vector_conduit_c     nios_c.reset_vector_conduit conduit
          add_connection nios_tmr_comparator.exception_vector_conduit_c nios_c.exception_vector_conduit  conduit
          if { $local_mmu_enable } {
            add_connection nios_tmr_comparator.fast_tlb_miss_vector_conduit_a  nios_a.fast_tlb_miss_vector_conduit  conduit
            add_connection nios_tmr_comparator.fast_tlb_miss_vector_conduit_b  nios_b.fast_tlb_miss_vector_conduit  conduit
            add_connection nios_tmr_comparator.fast_tlb_miss_vector_conduit_c  nios_c.fast_tlb_miss_vector_conduit  conduit
          }
        }
        
        # CPU reset
        set local_cpuresetrequest           [ proc_get_boolean_parameter cpuReset ]
        if { $local_cpuresetrequest } {
          set_instance_parameter_value nios_tmr_comparator cpuresetrequest_present true
          add_connection nios_tmr_comparator.cpu_resetrequest_conduit_a nios_a.cpu_resetrequest_conduit conduit
          add_connection nios_tmr_comparator.cpu_resetrequest_conduit_b nios_b.cpu_resetrequest_conduit conduit
          add_connection nios_tmr_comparator.cpu_resetrequest_conduit_c nios_c.cpu_resetrequest_conduit conduit
          
          set_connection_parameter_value nios_tmr_comparator.cpu_resetrequest_conduit_a/nios_a.cpu_resetrequest_conduit endPort {}
          set_connection_parameter_value nios_tmr_comparator.cpu_resetrequest_conduit_a/nios_a.cpu_resetrequest_conduit endPortLSB {0}
          set_connection_parameter_value nios_tmr_comparator.cpu_resetrequest_conduit_a/nios_a.cpu_resetrequest_conduit startPort {}
          set_connection_parameter_value nios_tmr_comparator.cpu_resetrequest_conduit_a/nios_a.cpu_resetrequest_conduit startPortLSB {0}
          set_connection_parameter_value nios_tmr_comparator.cpu_resetrequest_conduit_a/nios_a.cpu_resetrequest_conduit width {0}

          set_connection_parameter_value nios_tmr_comparator.cpu_resetrequest_conduit_b/nios_b.cpu_resetrequest_conduit endPort {}
          set_connection_parameter_value nios_tmr_comparator.cpu_resetrequest_conduit_b/nios_b.cpu_resetrequest_conduit endPortLSB {0}
          set_connection_parameter_value nios_tmr_comparator.cpu_resetrequest_conduit_b/nios_b.cpu_resetrequest_conduit startPort {}
          set_connection_parameter_value nios_tmr_comparator.cpu_resetrequest_conduit_b/nios_b.cpu_resetrequest_conduit startPortLSB {0}
          set_connection_parameter_value nios_tmr_comparator.cpu_resetrequest_conduit_b/nios_b.cpu_resetrequest_conduit width {0}
          
          set_connection_parameter_value nios_tmr_comparator.cpu_resetrequest_conduit_c/nios_c.cpu_resetrequest_conduit endPort {}
          set_connection_parameter_value nios_tmr_comparator.cpu_resetrequest_conduit_c/nios_c.cpu_resetrequest_conduit endPortLSB {0}
          set_connection_parameter_value nios_tmr_comparator.cpu_resetrequest_conduit_c/nios_c.cpu_resetrequest_conduit startPort {}
          set_connection_parameter_value nios_tmr_comparator.cpu_resetrequest_conduit_c/nios_c.cpu_resetrequest_conduit startPortLSB {0}
          set_connection_parameter_value nios_tmr_comparator.cpu_resetrequest_conduit_c/nios_c.cpu_resetrequest_conduit width {0}
        }
        
    } else {
        add_connection clock_bridge.out_clk cpu.clk
        add_connection reset_bridge.out_reset cpu.reset
        
        if { ${register_file_por} && $impl == "Small" } {
        add_connection por_rf_bridge.out_reset cpu.por_rf
        }
    }
    
    if { [ expr { $setting_oci_version == 2 } && !$setting_exportHostDebugPort && $local_debug_level ] } {
        add_instance sld2mm       altera_avalon_sld2mm
        add_instance sld_node     altera_avalon_sld2mm_sld_node
       
        set_instance_parameter sld_node NIOS_DEBUG true
        set_instance_parameter sld_node MANUAL_INSTANCE_INDEX $debug_assignJtagInstanceID
        set_instance_parameter sld_node SLD_INSTANCE_INDEX $debug_jtagInstanceID

        add_connection sld_node.reset sld2mm.reset
        add_connection clock_bridge.out_clk sld2mm.clk
        add_connection clock_bridge.out_clk sld_node.clk
        
        if { $tmr_enabled } {
          add_connection sld2mm.debug_reset nios_a.debug_reset
          add_connection sld2mm.debug_reset nios_b.debug_reset
          add_connection sld2mm.debug_reset nios_c.debug_reset
          
          # May need to split out these signals in TMR
          add_connection sld2mm.debug_extra   nios_tmr_comparator.debug_extra
          add_connection sld2mm.avalon_master nios_tmr_comparator.$DEBUG_HOST_INTF avalon
          set_connection_parameter_value sld2mm.avalon_master/nios_tmr_comparator.$DEBUG_HOST_INTF baseAddress "0x00000000" 
        } else {
          add_connection sld2mm.debug_reset cpu.debug_reset
          add_connection sld2mm.debug_extra cpu.debug_extra
          add_connection sld2mm.avalon_master cpu.$DEBUG_HOST_INTF avalon
          set_connection_parameter_value sld2mm.avalon_master/cpu.$DEBUG_HOST_INTF baseAddress "0x00000000" 
        }
        
        add_connection sld2mm.sld_slave sld_node.sld_master
        
        if { $onchip_trace_support } {

            if { $oci_trace_addr_width == 7 } {
                # currently the debug host slave is not updated will overlap into this region
                set trace_base_address "0x400"
                # set trace_base_address "0x800"
            } elseif { $oci_trace_addr_width == 8 } {
                set trace_base_address "0x800"
            } elseif { $oci_trace_addr_width == 9 } {
                set trace_base_address "0x1000"
            } elseif { $oci_trace_addr_width == 10 } {
                set trace_base_address "0x2000"
            } elseif { $oci_trace_addr_width == 11 } {
                set trace_base_address "0x4000"
            } elseif { $oci_trace_addr_width == 12 } {
                set trace_base_address "0x8000"
            } elseif { $trace_addr_width == 13 } {
                set trace_base_address "0x10000"
            } else {
                set trace_base_address "0x20000"
            }
                        
            if { $tmr_enabled } {
              add_connection sld2mm.avalon_master nios_tmr_comparator.debug_trace_slave avalon
              set_connection_parameter_value sld2mm.avalon_master/nios_tmr_comparator.debug_trace_slave baseAddress "$trace_base_address"
            } else {
              add_connection sld2mm.avalon_master cpu.debug_trace_slave avalon
              set_connection_parameter_value sld2mm.avalon_master/cpu.debug_trace_slave baseAddress "$trace_base_address" 
            }
        }
    }
}

## Add documentation links for user guide and/or release notes
add_documentation_link "User Guide" https://documentation.altera.com/#/link/iga1420498949526/iga1409257893438
add_documentation_link "Release Notes" https://documentation.altera.com/#/link/hco1421698042087/hco1421697867298
