package require -exact qsys 16.1
#-------------------------------------------------------------------------------
# [1] CORE MODULE ATTRIBUTES
#-------------------------------------------------------------------------------
set_module_property NAME "altera_nios2_gen2_unit"
set_module_property DISPLAY_NAME "Nios II Processor Unit"
set_module_property DESCRIPTION "Altera Nios II Unit Processor"
set_module_property AUTHOR "Altera Corporation"
set_module_property DATASHEET_URL "http://www.altera.com/literature/hb/nios2/n2cpu_nii5v1.pdf"
set_module_property GROUP "Embedded Processors"

set_module_property VERSION "18.1"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property INTERNAL true
set_module_property HIDE_FROM_SOPC true
set_module_property HIDE_FROM_QUARTUS true

set_module_property EDITABLE true
# set_module_property VALIDATION_CALLBACK validate
set_module_property ELABORATION_CALLBACK elaborate

# Define file set
add_fileset quartus_synth   QUARTUS_SYNTH   sub_quartus_synth
add_fileset sim_verilog     SIM_VERILOG     sub_sim_verilog
add_fileset sim_vhdl        SIM_VHDL        sub_sim_vhdl

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

proc proc_dspblock_shift_mul_valid {} {
    set impl [ get_parameter_value impl ]
    set dspblock_present [ proc_validate_device_features "DSPBlock" ]
    set stratix_dspblock_shift_mul [ proc_get_boolean_parameter stratix_dspblock_shift_mul ]

    # this is only valid if it is DSP block is supported and it is a fast core
    if { $stratix_dspblock_shift_mul && "$impl" == "Fast" } {
        return 1
    }

    return 0
}

proc proc_get_hardware_multiply_present {} {
    set mul_set "[ get_parameter_value multiplierType ]"
    set impl [ get_parameter_value impl ]
    set stratix_dspblock_shift_mul [ proc_dspblock_shift_mul_valid ]

    if { [ expr { "$impl" != "Fast" } || { "$mul_set" == "no_mul" && $stratix_dspblock_shift_mul == 0 } ] } {
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
    set stratix_dspblock_shift_mul [ proc_dspblock_shift_mul_valid ]

    # bmx is present when it is fast core and shifter type is fast
    # or it is Small. Both must be Cpu Rev 2
    if { "$impl" == "Small" && $cpuArchRev == 2 } {
        return 1
    }

    if { [ expr { "$impl" == "Fast" && $cpuArchRev == 2 } ] } {
        if { "$shiftype" == "fast_le_shift" || $stratix_dspblock_shift_mul == 1 } {
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

proc proc_has_any_ci_slave {} {

    set has_combo [ proc_has_combo_ci_slave ]
    set has_multi [ proc_has_multi_ci_slave ]
    
    set has_any_ci [ expr $has_combo || $has_multi  ]
    
    return $has_any_ci
    
}

proc proc_has_combo_ci_slave {} {

    set ci_ori [ proc_decode_address_map customInstSlavesSystemInfo ]
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

proc proc_has_multi_ci_slave {} {

    set ci_ori [ proc_decode_address_map customInstSlavesSystemInfo ]
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
    set fam   [ get_parameter_value faAddrWidth ]

    set sorted_inst_addr_width  [ lsort "$im $tcim0 $tcim1 $tcim2 $tcim3 $ihp $fam" ]
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
    set dcache_size_derived      [ get_parameter_value dcache_size_derived ];
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
# Using to differentiate between different CPUs
proc_add_parameter      cpu_name                                    STRING      "cpu"
proc_add_parameter      setting_showUnpublishedSettings             BOOLEAN     false
proc_add_parameter      setting_showInternalSettings                BOOLEAN     false
proc_add_parameter      setting_preciseIllegalMemAccessException    BOOLEAN     false
proc_add_parameter      setting_exportPCB                           BOOLEAN     false
proc_add_parameter      setting_exportdebuginfo                     BOOLEAN     false
proc_add_parameter      setting_clearXBitsLDNonBypass               BOOLEAN     true
proc_add_parameter      setting_bigEndian                           BOOLEAN     false
proc_add_parameter      setting_export_large_RAMs                   BOOLEAN     false
proc_add_parameter      setting_asic_enabled                        BOOLEAN     false
proc_add_parameter      setting_asic_synopsys_translate_on_off      BOOLEAN     false
proc_add_parameter      setting_asic_third_party_synthesis          BOOLEAN     false
proc_add_parameter      setting_asic_add_scan_mode_input            BOOLEAN     false
proc_add_parameter      setting_oci_export_jtag_signals             BOOLEAN     false
proc_add_parameter      setting_avalonDebugPortPresent              BOOLEAN     false
proc_add_parameter      setting_alwaysEncrypt                       BOOLEAN     true
proc_add_parameter      register_file_por                           BOOLEAN     false
proc_add_parameter      io_regionbase                               INTEGER     0
proc_add_parameter      io_regionsize                               INTEGER     0  "0:None"  "4096:4 Kbytes"  "8192:8 Kbytes"   "16384:16 Kbytes"   "32768:32 Kbytes"   "65536:64 Kbytes"   "131072:128 Kbytes"   "262144:256 Kbytes"   "524288:512 Kbytes"  "1048576:1 Mbyte" "2097152:2 Mbytes" "4194304:4 Mbytes" "8388608:8 Mbytes" "16777216:16 Mbytes" "33554432:32 Mbytes" "67108864:64 Mbytes" "134217728:128 Mbytes" "268435456:256 Mbytes" "536870912:512 Mbytes" "1073741824:1 Gbyte" "2147483648:2 Gbytes"
proc_add_parameter      setting_support31bitdcachebypass            BOOLEAN     true
proc_add_parameter      setting_activateTrace                       BOOLEAN     false
proc_add_parameter      tracefilename                               STRING      ""
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
proc_add_parameter      setting_shadowRegisterSets                  INTEGER     0       "0:63"
proc_add_parameter      mpu_numOfInstRegion                         INTEGER     8       "2"  "3"   "4"   "5"   "6"   "7"   "8"   "9"  "10"  "11"  "12"  "13"  "14"  "15"  "16"  "17"  "18"  "19"  "20"  "21"  "22"  "23"  "24"  "25"  "26"  "27"  "28"  "29"  "30"  "31"  "32"
proc_add_parameter      mpu_numOfDataRegion                         INTEGER     8       "2"  "3"   "4"   "5"   "6"   "7"   "8"   "9"  "10"  "11"  "12"  "13"  "14"  "15"  "16"  "17"  "18"  "19"  "20"  "21"  "22"  "23"  "24"  "25"  "26"  "27"  "28"  "29"  "30"  "31"  "32"
proc_add_parameter      mmu_TLBMissExcOffset                        INTEGER     0
proc_add_parameter      resetOffset                                 INTEGER     0
proc_add_parameter      exceptionOffset                             INTEGER     32
proc_add_parameter      cpuID                                       INTEGER     0
proc_add_parameter      breakOffset                                 INTEGER     32
proc_add_parameter      userDefinedSettings                         STRING      ""
proc_add_parameter      resetSlave                                  STRING      "None"
proc_add_parameter      mmu_TLBMissExcSlave                         STRING      "None"
proc_add_parameter      exceptionSlave                              STRING      "None"
proc_add_parameter      breakSlave                                  STRING      "None"
# [SH] Change all Integer type with "_8" back to string since "string:Display name" is allowed
proc_add_parameter      setting_interruptControllerType             STRING      "Internal"  "Internal"  "External"
proc_add_parameter      setting_branchPredictionType                STRING      "Dynamic"   "Static"  "Dynamic"
proc_add_parameter      setting_bhtPtrSz                            INTEGER     8           "8:256 Entries"  "12:4096 Entries"  "13:8192 Entries"
proc_add_parameter      cpuArchRev                                  INTEGER     "1"  "2: Revision 2 (R2)" "1: Revision 1 (R1)"
proc_add_parameter      stratix_dspblock_shift_mul                  BOOLEAN     false
proc_add_parameter      shifterType                                 STRING      "fast_le_shift"  "medium_le_shift:${MEDIUM_LE_SHIFT}" "fast_le_shift:${FAST_LE_SHIFT}" 
proc_add_parameter      multiplierType                              STRING      "no_mul"  "no_mul:${MUL_NONE}" "mul_slow32:${MUL_SLOW32}" "mul_fast32:${MUL_FAST32}"  "mul_fast64:${MUL_FAST64}" 
proc_add_parameter      dividerType                                 STRING      "no_div"  "no_div:${DIV_NONE}" "srt2:${DIV_SRT2}"
proc_add_parameter      mpu_minInstRegionSize                       INTEGER     12          "8:256 Bytes"  "9:512 Bytes"  "10:1 Kbyte"  "11:2 Kbytes"  "12:4 Kbytes"  "13:8 Kbytes"  "14:16 Kbytes"  "15:32 Kbytes"  "16:64 Kbytes"  "17:128 Kbytes"  "18:256 Kbytes"  "19:512 Kbytes"  "20:1 Mbyte"
proc_add_parameter      mpu_minDataRegionSize                       INTEGER     12          "8:256 Bytes"  "9:512 Bytes"  "10:1 Kbyte"  "11:2 Kbytes"  "12:4 Kbytes"  "13:8 Kbytes"  "14:16 Kbytes"  "15:32 Kbytes"  "16:64 Kbytes"  "17:128 Kbytes"  "18:256 Kbytes"  "19:512 Kbytes"  "20:1 Mbyte"
proc_add_parameter      mmu_uitlbNumEntries                         INTEGER     4           "2:2 Entries"  "4:4 Entries"  "6:6 Entries"  "8:8 Entries"
proc_add_parameter      mmu_udtlbNumEntries                         INTEGER     6           "2:2 Entries"  "4:4 Entries"  "6:6 Entries"  "8:8 Entries"
proc_add_parameter      mmu_tlbPtrSz                                INTEGER     7           "7:128 Entries"  "8:256 Entries"  "9:512 Entries"  "10:1024 Entries"
proc_add_parameter      mmu_tlbNumWays                              INTEGER     16          "8:8 Ways"  "16:16 Ways"
proc_add_parameter      mmu_processIDNumBits                        INTEGER     8           "8:8 Bits"  "9:9 Bits"  "10:10 Bits"  "11:11 Bits"  "12:12 Bits"  "13:13 Bits"  "14:14 Bits"
proc_add_parameter      impl                                        STRING      "Fast"      "Tiny:Nios II/e" "Small:Nios II/m" "Fast:Nios II/f"
proc_add_parameter      icache_size                                 INTEGER     4096        "0:None"  "512:512 Bytes"  "1024:1 Kbyte"  "2048:2 Kbytes"  "4096:4 Kbytes"  "8192:8 Kbytes"  "16384:16 Kbytes"  "32768:32 Kbytes"  "65536:64 Kbytes"
proc_add_parameter      fa_cache_line                               INTEGER     2           "2:2"  "4:4"  "8:8"  "16:16"  "32:32"
proc_add_parameter      fa_cache_linesize                           INTEGER     0           "0:None"  "8"  "16"

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
proc_add_parameter      tmr_enabled                                 BOOLEAN     false

# Debug parameters
proc_add_parameter      debug_enabled                               BOOLEAN     true
proc_add_parameter      debug_triggerArming                         BOOLEAN     true
proc_add_parameter      debug_debugReqSignals                       BOOLEAN     false
proc_add_parameter      debug_assignJtagInstanceID                  BOOLEAN     false
proc_add_parameter      debug_jtagInstanceID                        INTEGER     0       "0:255"
proc_add_parameter      debug_OCIOnchipTrace                        STRING      "_128"  "_128:128"  "_256:256"  "_512:512"  "_1k:1k"  "_2k:2k"  "_4k:4k"  "_8k:8k"  "_16k:16k"
proc_add_parameter      debug_hwbreakpoint                          INTEGER     "0"     "0:0"  "2:2"  "4:4"  "6:6"  "8:8"
proc_add_parameter      debug_datatrigger                           INTEGER     "0"     "0:0"  "2:2"  "4:4"  "6:6"  "8:8"
proc_add_parameter      debug_traceType                             STRING      "none"  "none:None"  "instruction_trace:Instruction Trace"  "instruction_and_data_trace:Instruction and Data Trace"
proc_add_parameter      debug_traceStorage                          STRING      "onchip_trace"  "onchip_trace:On-Chip Trace"  "offchip_trace:Off-Chip Trace"  "on_offchip_trace:On-Chip and Off-Chip Trace"
proc_add_parameter      setting_oci_version                         INTEGER     1  "1:Nios OCI Version 1" "2:Nios OCI Version 2"
proc_add_parameter      setting_fast_register_read                  BOOLEAN     false

proc_add_parameter      master_addr_map                                 BOOLEAN     false
proc_add_parameter      instruction_master_paddr_base                   INTEGER     0
proc_add_parameter      instruction_master_paddr_top                    INTEGER     0
proc_add_parameter      flash_instruction_master_paddr_base             INTEGER     0
proc_add_parameter      flash_instruction_master_paddr_top              INTEGER     0
proc_add_parameter      data_master_paddr_base                          INTEGER     0
proc_add_parameter      data_master_paddr_top                           INTEGER     0
proc_add_parameter      tightly_coupled_instruction_master_0_paddr_base INTEGER     0
proc_add_parameter      tightly_coupled_instruction_master_0_paddr_top  INTEGER     0
proc_add_parameter      tightly_coupled_instruction_master_1_paddr_base INTEGER     0
proc_add_parameter      tightly_coupled_instruction_master_1_paddr_top  INTEGER     0
proc_add_parameter      tightly_coupled_instruction_master_2_paddr_base INTEGER     0
proc_add_parameter      tightly_coupled_instruction_master_2_paddr_top  INTEGER     0
proc_add_parameter      tightly_coupled_instruction_master_3_paddr_base INTEGER     0
proc_add_parameter      tightly_coupled_instruction_master_3_paddr_top  INTEGER     0
proc_add_parameter      tightly_coupled_data_master_0_paddr_base        INTEGER     0
proc_add_parameter      tightly_coupled_data_master_0_paddr_top         INTEGER     0
proc_add_parameter      tightly_coupled_data_master_1_paddr_base        INTEGER     0
proc_add_parameter      tightly_coupled_data_master_1_paddr_top         INTEGER     0
proc_add_parameter      tightly_coupled_data_master_2_paddr_base        INTEGER     0
proc_add_parameter      tightly_coupled_data_master_2_paddr_top         INTEGER     0
proc_add_parameter      tightly_coupled_data_master_3_paddr_base        INTEGER     0
proc_add_parameter      tightly_coupled_data_master_3_paddr_top         INTEGER     0
proc_add_parameter      instruction_master_high_performance_paddr_base  INTEGER     0
proc_add_parameter      instruction_master_high_performance_paddr_top   INTEGER     0
proc_add_parameter      data_master_high_performance_paddr_base         INTEGER     0 
proc_add_parameter      data_master_high_performance_paddr_top          INTEGER     0 

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
      JTAG Debug
    </b></td>
    <td valign=\"top\">
      JTAG Debug<br><b>
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
proc_add_parameter  resetAbsoluteAddr       INTEGER     0
proc_add_parameter  exceptionAbsoluteAddr   INTEGER     0
proc_add_parameter  breakAbsoluteAddr       INTEGER     0
proc_add_parameter  mmu_TLBMissExcAbsAddr   INTEGER     0
proc_add_parameter  dcache_bursts_derived   STRING      "false"
proc_add_parameter  dcache_size_derived     INTEGER     2048
proc_add_parameter  breakSlave_derived      STRING      "None"

# Dcache lineSize is always 32 bytes
proc_add_parameter  dcache_lineSize_derived INTEGER     32
set_parameter_property      dcache_bursts_derived   "VISIBLE"   "false"
set_parameter_property      dcache_size_derived     "VISIBLE"   "false"
set_parameter_property      dcache_lineSize_derived "VISIBLE"   "false"
set_parameter_property      breakSlave_derived      "VISIBLE"   "false"

# Derived parameter for Dcache bypass type
proc_add_parameter  setting_ioregionBypassDCache     BOOLEAN     false
set_parameter_property      setting_ioregionBypassDCache     "VISIBLE"   "false"
proc_add_parameter  setting_bit31BypassDCache        BOOLEAN     false
set_parameter_property      setting_bit31BypassDCache        "VISIBLE"   "false"

# Additional derived parameter for translate_on_off (ASIC only)
# Overriding the Visible property
proc_add_parameter  translate_on            STRING     { "synthesis translate_on"  }
proc_add_parameter  translate_off           STRING     { "synthesis translate_off" }
set_parameter_property  translate_on  "VISIBLE" false
set_parameter_property  translate_off "VISIBLE" false

proc_add_parameter  debug_onchiptrace       BOOLEAN    false
set_parameter_property  debug_onchiptrace  "VISIBLE" false
proc_add_parameter  debug_offchiptrace       BOOLEAN    false
set_parameter_property  debug_offchiptrace  "VISIBLE" false
proc_add_parameter  debug_insttrace           BOOLEAN    false
set_parameter_property  debug_insttrace  "VISIBLE" false
proc_add_parameter  debug_datatrace           BOOLEAN    false
set_parameter_property  debug_datatrace  "VISIBLE" false

set stratix_dspblock_description {}
append stratix_dspblock_description "<table border=\"1\">"
append stratix_dspblock_description "<tr>"
append stratix_dspblock_description "<th>Name</th>"
append stratix_dspblock_description "<th>Performance</th>"
append stratix_dspblock_description "<th>Implementation</th>"
append stratix_dspblock_description "<th>Instructions</th>"
append stratix_dspblock_description "</tr>"
append stratix_dspblock_description "<tr>"
append stratix_dspblock_description "<td>DSP Block</td>"
append stratix_dspblock_description "<td>1 cycle</td>"
append stratix_dspblock_description "<td>Pipelined</td>"
append stratix_dspblock_description "<td>All shift/rotate/multiply</td>"
append stratix_dspblock_description "</tr>"
append stratix_dspblock_description "</table>"

set shift_description {}
append shift_description "<table border=\"1\">"
append shift_description "<tr>"
append shift_description "<th>Name</th>"
append shift_description "<th>Performance</th>"
append shift_description "<th>Implementation</th>"
append shift_description "<th>Instructions</th>"
append shift_description "</tr>"
append shift_description "<tr>"
append shift_description "<td>Resource-optimized</td>"
append shift_description "<td>2-11 cycles</td>"
append shift_description "<td>Iterative</td>"
append shift_description "<td>All shift/rotate</td>"
append shift_description "</tr>"
append shift_description "<tr>"
append shift_description "<td>High-performance</td>"
append shift_description "<td>1 cycle</td>"
append shift_description "<td>Pipelined</td>"
append shift_description "<td>All shift/rotate</td>"
append shift_description "</tr>"
append shift_description "</table>"

set mul_description {}
append mul_description "<table border=\"1\">"
append mul_description "<tr>"
append mul_description "<th>Name</th>"
append mul_description "<th>Performance</th>"
append mul_description "<th>Resources</th>"
append mul_description "<th>Instructions</th>"
append mul_description "</tr>"
append mul_description "<tr>"
append mul_description "<td>None</td>"
append mul_description "<td>-</td>"
append mul_description "<td>None</td>"
append mul_description "<td>None</td>"
append mul_description "</tr>"
append mul_description "<tr>"
append mul_description "<td>Resource-optimized 32-bit</td>"
append mul_description "<td>11 cycles</td>"
append mul_description "<td>Logic elements</td>"
append mul_description "<td>MUL/MULI</td>"
append mul_description "</tr>"
append mul_description "<tr>"
append mul_description "<td>High-performance 32-bit</td>"
append mul_description "<td>1 cycle</td>"
append mul_description "<td>6 9-bit multipliers</td>"
append mul_description "<td>MUL/MULI</td>"
append mul_description "</tr>"
append mul_description "<tr>"
append mul_description "<td>High-performance 64-bit</td>"
append mul_description "<td>32-bit => 1 cycle, 64-bit => 2 cycles</td>"
append mul_description "<td>8 9-bit multipliers</td>"
append mul_description "<td>All multiply</td>"
append mul_description "</tr>"
append mul_description "</table>"

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
proc_set_display_group      stratix_dspblock_shift_mul                  $CORE_0       0   "Use DSP Block for Shifter and Multiplier" $stratix_dspblock_description
proc_set_display_group      shifterType                                 $CORE_0       0   "Shifter" $shift_description
proc_set_display_group      multiplierType                              $CORE_0       0   "Multiplier" $mul_description
proc_set_display_group      dividerType                                 $CORE_0       0   "Divider" $div_description

add_display_item            ""                                          $SLAVE_VECTORS   GROUP tab
add_display_item            "$SLAVE_VECTORS"                            $CORE_2         GROUP
add_display_item            "$SLAVE_VECTORS"                            $CORE_3         GROUP
add_display_item            "$SLAVE_VECTORS"                            $CORE_4         GROUP
add_display_item            "$SLAVE_VECTORS"                            $DEBUG_2        GROUP
add_display_item            "$SLAVE_VECTORS"                            $EXPORT_VECTORS        GROUP
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
proc_set_display_group      fa_cache_line                               "Flash Accelerator"      0   "Number of Lines" "The Flash accelerator is a small fully-associative cache for real-time applications. Use this when executing directly from on-chip memories such as flash."
proc_set_display_group      fa_cache_linesize                           "Flash Accelerator"      0   "Line Size"

proc_set_display_group      dcache_size                                 $DCACHE      0   "Size"
proc_set_display_group      dcache_tagramBlockType                      $DCACHE      1   "Tag RAM block type"
proc_set_display_group      dcache_ramBlockType                         $DCACHE      1   "Data RAM block type"
proc_set_display_group      dcache_victim_buf_impl                      $DCACHE      0   "Victim buffer implementation"
proc_set_display_group      dcache_bursts                               $DCACHE      0   "Add burstcount signal to data_master"
proc_set_display_group      setting_support31bitdcachebypass            $DCACHE      0   "Use most-significant address bit in processor to bypass data cache" "When this option is enabled, the master interfaces only support up to a 31-bit byte address. Otherwise, they support up to a full 32-bit byte address."

proc_set_display_group      icache_numTCIM                              $MEMORY_INTERFACE      0   "Number of tightly coupled instruction master ports"
proc_set_display_group      dcache_numTCDM                              $MEMORY_INTERFACE      0   "Number of tightly coupled data master ports"

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
add_display_item            "$DEBUG"                                    $OCIMEM_BLOCK_TYPE      GROUP
proc_set_display_group      debug_enabled                               $DEBUG_1      0   "Include JTAG Debug"
add_text_message                                                        $DEBUG_1      "<html>${HTML_TAB}JTAG Target Connection.<br>${HTML_TAB}Enable Software Download and Software Breakpoint.<br>${HTML_TAB}Uses 1 M9K Memory.</html>"
proc_set_display_group      debug_hwbreakpoint                          $DEBUG_1      0   "Hardware Breakpoints" "Monitor Instruction Address"
proc_set_display_group      debug_datatrigger                           $DEBUG_1      0   "Data Triggers" "Monitor Data Address/Value"
proc_set_display_group      debug_traceType                             $DEBUG_1      0   "Trace Types"
proc_set_display_group      debug_traceStorage                          $DEBUG_1      0   "Trace Storage"
proc_set_display_group      debug_OCIOnchipTrace                        $DEBUG_1      0   "Onchip Trace Frame Size"
proc_set_display_group      debug_debugReqSignals                       $DEBUG_1      0   "Include debugreq and debugack Signals"
add_text_message                                                        $DEBUG_1      "<html>${HTML_TAB}These signals appear on the top-level Qsys system.<br>${HTML_TAB}You must manually connect these signals to logic external to the Qsys system.</html>"
proc_set_display_group      debug_assignJtagInstanceID                  $DEBUG_1      1   "Assign JTAG Instance ID for debug core manually"
proc_set_display_group      debug_jtagInstanceID                        $DEBUG_1      1   "JTAG Instance ID value"
proc_set_display_group      ocimem_ramBlockType                         $OCIMEM_BLOCK_TYPE    1   "RAM block type"

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
proc_set_display_group      cdx_enabled                                 $ADVANCED_1   1   "CDX (Code Density eXtension) Instructions" "Adds 16-bit and 32-bit instructions"
proc_set_display_group      mpx_enabled                                 $ADVANCED_1   1   "MPX (Multi-Processor eXtension) Instructions" "Supports LDSEX and STSEX instructions"
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
proc_set_display_group      tracefilename                               $ADVANCED_1   1   "Trace File Name" "Manually specify trace file name. It will be <Trace File Name>.tr"
proc_set_display_group      setting_showUnpublishedSettings             $ADVANCED_1       1   "Show Unpublished Settings"
proc_set_display_group      setting_showInternalSettings                $ADVANCED_1       1   "Show Internal Verification Settings"
set_parameter_property      setting_showUnpublishedSettings "VISIBLE" "true"
set_parameter_property      setting_showInternalSettings    "VISIBLE" "true"
proc_set_display_group      setting_exportdebuginfo                     $ADVANCED_1   1   "Export Instruction Execution States" "Exports Program Counter (PC), Instruction Word (IW) and Exception bit (EXC) as Avalon-ST signals"
proc_set_display_group      setting_preciseIllegalMemAccessException    $ADVANCED_2   0   "Misaligned memory access" "Always present with MMU and MPU"
proc_set_display_group      setting_branchPredictionType                $ADVANCED_3   0   "Branch prediction type"
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
proc_set_display_group      setting_disableocitrace                     $ADVANCED_5       1   "Disable comptr"                            "INTERNAL"
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
proc_set_display_group      userDefinedSettings                         $ADVANCED_5       1   "User Defined Settings"                     "INTERNAL"

proc_set_display_group      setting_asic_enabled                        $ASIC_SETTINGS    1   "ASIC enabled"                              "Adds JTAG Cold Reset synchronous to CPU clock when JTAG Debug is enabled, disables certain design-warning suppresion. Used to enable other ASIC switches"
proc_set_display_group      setting_usedesignware                       $ASIC_SETTINGS    1   "Use Designware Components"                 "Replace multiplier, altsyncrams and shift/rotate blocks with DWC_n2p_mult, DWC_n2p_bcm58 and DW_shifter block respectively"
proc_set_display_group      setting_export_large_RAMs                   $ASIC_SETTINGS    1   "Export Large RAMs"                         "Export RAM interfaces to the top, including Instruction/Data Cache RAMs, MMU TLB RAM and OCI trace/instruction RAMs"
proc_set_display_group      setting_oci_export_jtag_signals             $ASIC_SETTINGS    1   "Export JTAG signals"                       "Export JTAG signals to the top to be connected to an Altera sld_virtual_jtag_basic instance"
proc_set_display_group      setting_asic_third_party_synthesis          $ASIC_SETTINGS    1   "ASIC third party synthesis"                "Removes quartus read comments as HDL"
proc_set_display_group      setting_asic_add_scan_mode_input            $ASIC_SETTINGS    1   "ASIC add scan mode input"                  "Adds a new input, scan mode which is used to select whether the reset synchronizers is fed by reset or \"reset_sources\""
proc_set_display_group      setting_asic_synopsys_translate_on_off      $ASIC_SETTINGS    1   "ASIC Synopsys translate"                   "Change synthesis translate on/off to synopsys translate on/off"
proc_set_display_group      setting_removeRAMinit                       $ASIC_SETTINGS    1   "Remove RAM Initialization"                 "Set all INIT_FILE parameter of the altsyncrams to \"UNUSED\""
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
proc_set_display_format     shifterType             "radio"
proc_set_display_format     multiplierType          "radio"
proc_set_display_format     dividerType             "radio"

#------------------------------
# [4.3] SYSTEM_INFO Parameter
#------------------------------

proc_add_parameter          instAddrWidth                                       INTEGER         "31"
proc_add_parameter          faAddrWidth                                         INTEGER         "31"
proc_add_parameter          dataAddrWidth                                       INTEGER         "31"

proc_add_parameter          tightlyCoupledDataMaster0AddrWidth                  INTEGER         "31"
proc_add_parameter          tightlyCoupledDataMaster1AddrWidth                  INTEGER         "31"
proc_add_parameter          tightlyCoupledDataMaster2AddrWidth                  INTEGER         "31"
proc_add_parameter          tightlyCoupledDataMaster3AddrWidth                  INTEGER         "31"
proc_add_parameter          tightlyCoupledInstructionMaster0AddrWidth           INTEGER         "31"
proc_add_parameter          tightlyCoupledInstructionMaster1AddrWidth           INTEGER         "31"
proc_add_parameter          tightlyCoupledInstructionMaster2AddrWidth           INTEGER         "31"
proc_add_parameter          tightlyCoupledInstructionMaster3AddrWidth           INTEGER         "31"
proc_add_parameter          dataMasterHighPerformanceAddrWidth                  INTEGER         "31"
proc_add_parameter          instructionMasterHighPerformanceAddrWidth           INTEGER         "31"

proc_add_parameter          instSlaveMapParam                                   STRING          ""
proc_add_parameter          faSlaveMapParam                                     STRING          ""
proc_add_parameter          dataSlaveMapParam                                   STRING          ""

proc_add_parameter          clockFrequency                                      LONG            "50000000"
proc_add_parameter          deviceFamilyName                                    STRING          "STRATIXIV"
proc_add_parameter          internalIrqMaskSystemInfo                           LONG            "0x0"


proc_add_parameter          customInstSlavesSystemInfo                           STRING          ""
proc_add_parameter          deviceFeaturesSystemInfo                             STRING          ""

proc_add_parameter          tightlyCoupledDataMaster0MapParam                    STRING          ""
proc_add_parameter          tightlyCoupledDataMaster1MapParam                    STRING          ""
proc_add_parameter          tightlyCoupledDataMaster2MapParam                    STRING          ""
proc_add_parameter          tightlyCoupledDataMaster3MapParam                    STRING          ""
proc_add_parameter          tightlyCoupledInstructionMaster0MapParam             STRING          ""
proc_add_parameter          tightlyCoupledInstructionMaster1MapParam             STRING          ""
proc_add_parameter          tightlyCoupledInstructionMaster2MapParam             STRING          ""
proc_add_parameter          tightlyCoupledInstructionMaster3MapParam             STRING          ""
proc_add_parameter          dataMasterHighPerformanceMapParam                    STRING          ""
proc_add_parameter          instructionMasterHighPerformanceMapParam             STRING          ""

#-------------------------------------------------------------------------------
# [5] INTERFACE
#-------------------------------------------------------------------------------

#------------------------------
# [5.1] Clock Interface
#------------------------------
add_interface           $CLOCK_INTF     "clock"     "sink"
add_interface_port      $CLOCK_INTF     "clk"       "clk"       "input"     1

#------------------------------
# [5.2] Reset Interface
#------------------------------
add_interface           reset     "reset"     "sink"      $CLOCK_INTF      
add_interface_port      reset     "reset_n"   "reset_n"   "input"     1

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
proc sub_elaborate_tcdm_interface {} {
    global TCD_INTF_PREFIX
    global TCD_PREFIX
    global CLOCK_INTF
    
    set tcdm_num    [ get_parameter_value dcache_numTCDM ]
    set impl        [ get_parameter_value impl ]
    set data_width  32
    set tmr_enabled [ proc_get_boolean_parameter tmr_enabled ]

    if { "${impl}" != "Tiny" } {
        set ecc_present [ proc_get_boolean_parameter setting_ecc_present ]        
        set dtcm_ecc_present [ proc_get_boolean_parameter setting_dtcm_ecc_present ]
        if { $ecc_present & "${impl}" != "Tiny" & $dtcm_ecc_present } {
            set data_width 39
        }
        foreach i {0 1 2 3} {
            set INTF_NAME "${TCD_INTF_PREFIX}${i}"
            set TCD_NAME  "${TCD_PREFIX}${i}"
            if { $i < $tcdm_num } {               
                set local_daddr_width [ get_parameter_value ${TCD_NAME}AddrWidth ]
                add_interface           $INTF_NAME      "avalon"                    "master"            $CLOCK_INTF
                add_interface_port      $INTF_NAME      "dtcm${i}_readdata"          "readdata"          "input"     $data_width
                add_interface_port      $INTF_NAME      "dtcm${i}_address"           "address"           "output"    $local_daddr_width
                add_interface_port      $INTF_NAME      "dtcm${i}_read"              "read"              "output"    1
                add_interface_port      $INTF_NAME      "dtcm${i}_clken"             "clken"             "output"    1
                add_interface_port      $INTF_NAME      "dtcm${i}_write"             "write"             "output"    1
                add_interface_port      $INTF_NAME      "dtcm${i}_writedata"         "writedata"         "output"    $data_width
                if { $dtcm_ecc_present & $ecc_present } {
                    set_interface_property  $INTF_NAME      "bitsPerSymbol"     "39"
                    set_interface_property  $INTF_NAME      "addressUnits"     "WORDS"
                } else {
                    add_interface_port      $INTF_NAME      "dtcm${i}_byteenable"        "byteenable"        "output"    4
                }

                if { !$tmr_enabled } {
                    set_interface_property  $INTF_NAME      "addressGroup"              "1"
                }
                # Enable response signal for M core only
                if { "${impl}" == "Small" } {
                    add_interface_port      $INTF_NAME      "dtcm${i}_response"       "response"       "input"     2
                }
                set_interface_property  $INTF_NAME      "registerIncomingSignals"   "false"
                set_interface_property  $INTF_NAME      "ENABLED"                   "true"
                set_interface_property  $INTF_NAME      "associatedReset"           "reset"
                set_interface_property  $INTF_NAME      "readWaitTime"            0
                set_interface_property  $INTF_NAME      "readLatency"            1
                set_interface_property  $INTF_NAME      "writeWaitTime"           0
            }
        }
    }
}

#------------------------------
# [6.3] H.P.Data.Master Interface
#------------------------------
proc sub_elaborate_dhpm_interface {} {
    global DHP_INTF_PREFIX
    global DHP_PREFIX
    global CLOCK_INTF
    
    set impl        [ get_parameter_value impl ]
    set data_width  32
    set tmr_enabled [ proc_get_boolean_parameter tmr_enabled ]

    if { "${impl}" == "Small" } {
        set local_daddr_width [ get_parameter_value ${DHP_PREFIX}AddrWidth ]
        add_interface           $DHP_INTF_PREFIX      "avalon"                    "master"            $CLOCK_INTF
        add_interface_port      $DHP_INTF_PREFIX      "dhp_readdata"          "readdata"          "input"     $data_width
        add_interface_port      $DHP_INTF_PREFIX      "dhp_waitrequest"       "waitrequest"       "input"     1
        add_interface_port      $DHP_INTF_PREFIX      "dhp_response"          "response"          "input"     2
        add_interface_port      $DHP_INTF_PREFIX      "dhp_readdatavalid"     "readdatavalid"     "input"     1
        add_interface_port      $DHP_INTF_PREFIX      "dhp_address"           "address"           "output"    $local_daddr_width
        add_interface_port      $DHP_INTF_PREFIX      "dhp_read"              "read"              "output"    1
        add_interface_port      $DHP_INTF_PREFIX      "dhp_write"             "write"             "output"    1
        add_interface_port      $DHP_INTF_PREFIX      "dhp_writedata"         "writedata"         "output"    $data_width
        add_interface_port      $DHP_INTF_PREFIX      "dhp_byteenable"        "byteenable"        "output"    4
        if { !$tmr_enabled } {
            set_interface_property  $DHP_INTF_PREFIX      "addressGroup"              "1"
        }
        set_interface_property  $DHP_INTF_PREFIX      "registerIncomingSignals"   "false"
        set_interface_property  $DHP_INTF_PREFIX      "ENABLED"                   "true"
        set_interface_property  $DHP_INTF_PREFIX      "associatedReset"           "reset"
        if {$local_daddr_width == 1} {
            set_port_property dhp_response TERMINATION TRUE
            set_port_property dhp_response TERMINATION_VALUE 0
            set_port_property dhp_waitrequest TERMINATION TRUE
            set_port_property dhp_waitrequest TERMINATION_VALUE 0
            set_port_property dhp_readdatavalid TERMINATION TRUE
            set_port_property dhp_readdatavalid TERMINATION_VALUE 0
        }
    }
}

#------------------------------
# [6.4] T.C.Inst.Master Interface
#------------------------------
proc sub_elaborate_tcim_interface {} {
    global TCI_INTF_PREFIX
    global TCI_PREFIX
    global CLOCK_INTF
    set tcim_num    [ get_parameter_value icache_numTCIM ]
    set impl        [ get_parameter_value impl ]
    set ecc_present [ proc_get_boolean_parameter setting_ecc_present ]
    set itcm_ecc_present [ proc_get_boolean_parameter setting_itcm_ecc_present ]
    set data_width  32
    set tmr_enabled [ proc_get_boolean_parameter tmr_enabled ]
    
    if { $ecc_present & "${impl}" == "Fast" & $itcm_ecc_present } {
        set data_width 39
    }

    if { "${impl}" != "Tiny" } {
        foreach i {0 1 2 3} {
            set INTF_NAME "${TCI_INTF_PREFIX}${i}"
            set TCI_NAME  "${TCI_PREFIX}${i}"
            
            if { $i < $tcim_num } {
                set local_iaddr_width [ get_parameter_value ${TCI_NAME}AddrWidth ]
                add_interface           $INTF_NAME      "avalon"                    "master"            $CLOCK_INTF
                add_interface_port      $INTF_NAME      "itcm${i}_readdata"          "readdata"          "input"     $data_width
                add_interface_port      $INTF_NAME      "itcm${i}_address"           "address"           "output"    $local_iaddr_width
                add_interface_port      $INTF_NAME      "itcm${i}_read"              "read"              "output"    1
                add_interface_port      $INTF_NAME      "itcm${i}_clken"             "clken"             "output"    1
                if { !$tmr_enabled } {
                    set_interface_property  $INTF_NAME      "addressGroup"              "1"
                }
                set_interface_property  $INTF_NAME      "registerIncomingSignals"   "false"
                set_interface_property  $INTF_NAME      "ENABLED"                   "true"
                set_interface_property  $INTF_NAME      "associatedReset"           "reset"
                
                # When ECC enabled, allow write ports for recoverable ECC error
                if { $ecc_present & "${impl}" != "Tiny" & $itcm_ecc_present } {
                    add_interface_port      $INTF_NAME      "itcm${i}_writedata"     "writedata"         "output"    $data_width
                    add_interface_port      $INTF_NAME      "itcm${i}_write"         "write"             "output"    1
                    set_interface_property  $INTF_NAME      "bitsPerSymbol"     "39"
                    set_interface_property  $INTF_NAME      "addressUnits"     "WORDS"
                }
                
                # Enable response signal for M core only
                if { "${impl}" == "Small" } {
                    add_interface_port      $INTF_NAME      "itcm${i}_response"       "response"       "input"     2
                }
                set_interface_property  $INTF_NAME      "readWaitTime"            0
                set_interface_property  $INTF_NAME      "readLatency"            1
                set_interface_property  $INTF_NAME      "writeWaitTime"           0
            }
        }
    }
}

#------------------------------
# Instruction High Performance Interface
#------------------------------
proc sub_elaborate_ihpm_interface {} {
    global IHP_INTF_PREFIX
    global IHP_PREFIX
    global CLOCK_INTF
    set impl        [ get_parameter_value impl ]
    set data_width  32
    set tmr_enabled [ proc_get_boolean_parameter tmr_enabled ]

    if { "${impl}" == "Small" } {       
        set local_iaddr_width [ get_parameter_value ${IHP_PREFIX}AddrWidth ]
        add_interface           $IHP_INTF_PREFIX      "avalon"                    "master"            $CLOCK_INTF
        add_interface_port      $IHP_INTF_PREFIX      "ihp_readdata"          "readdata"          "input"     $data_width
        add_interface_port      $IHP_INTF_PREFIX      "ihp_waitrequest"       "waitrequest"       "input"     1
        add_interface_port      $IHP_INTF_PREFIX      "ihp_response"          "response"          "input"     2
        add_interface_port      $IHP_INTF_PREFIX      "ihp_readdatavalid"     "readdatavalid"     "input"     1
        add_interface_port      $IHP_INTF_PREFIX      "ihp_address"           "address"           "output"    $local_iaddr_width
        add_interface_port      $IHP_INTF_PREFIX      "ihp_read"              "read"              "output"    1
        if { !$tmr_enabled } {
            set_interface_property  $IHP_INTF_PREFIX      "addressGroup"              "1"
        }
        set_interface_property  $IHP_INTF_PREFIX      "registerIncomingSignals"   "false"
        set_interface_property  $IHP_INTF_PREFIX      "ENABLED"                   "true"
        set_interface_property  $IHP_INTF_PREFIX      "associatedReset"           "reset"
        # when it is not connected to anything, the address width is always 1
        if {$local_iaddr_width == 1} {
            set_port_property ihp_response TERMINATION TRUE
            set_port_property ihp_response TERMINATION_VALUE 0
            set_port_property ihp_waitrequest TERMINATION TRUE
            set_port_property ihp_waitrequest TERMINATION_VALUE 0
            set_port_property ihp_readdatavalid TERMINATION TRUE
            set_port_property ihp_readdatavalid TERMINATION_VALUE 0
        }
    }
}

#------------------------------
# [6.5] Interrupt Interfaces - irq receiver / eic st port
#------------------------------
proc sub_elaborate_interrupt_controller_ports {} {
    global IRQ_INTF
    global EXT_IRQ_INTF
    global CLOCK_INTF
    global D_MASTER_INTF
    
    if { [ proc_get_eic_present ] } {
        # External IRQ Controller
        add_interface           $EXT_IRQ_INTF   "avalon_streaming"                  "end"                   $CLOCK_INTF
        add_interface_port      $EXT_IRQ_INTF   "eic_port_valid"                    "valid"                 "input"     1
        add_interface_port      $EXT_IRQ_INTF   "eic_port_data"                     "data"                  "input"     45
        set_interface_property  $EXT_IRQ_INTF   "symbolsPerBeat"                    "1"
        set_interface_property  $EXT_IRQ_INTF   "dataBitsPerSymbol"                 "45"
        set_interface_property  $EXT_IRQ_INTF   "ENABLED"                           "true"
        set_interface_property  $EXT_IRQ_INTF   "associatedReset"                   "reset"
        proc_set_interface_embeddedsw_configuration_assignment $EXT_IRQ_INTF "isInterruptControllerReceiver" 1
    } else {
        # Internal IRQ Controller
        add_interface           $IRQ_INTF     "interrupt"                         "receiver"              $CLOCK_INTF
        add_interface_port      $IRQ_INTF     "irq"                               "irq"                   "input"     32
        set_interface_property  $IRQ_INTF     "irqScheme"                         "individualRequests"
        set_interface_property  $IRQ_INTF     "associatedAddressablePoint"        $D_MASTER_INTF
        set_interface_property  $IRQ_INTF     "ENABLED"                           "true"
        set_interface_property  $IRQ_INTF     "associatedReset"                   "reset"
    }
}

#------------------------------
# [6.11] hbreak Interrupt Interfaces - irq receiver
#------------------------------
proc sub_elaborate_hbreak_interrupt_controller_ports {} {
	global HBREAK_IRQ_INTF
	global CLOCK_INTF
	global I_MASTER_INTF
	
	set local_impl [ get_parameter_value impl ]

	if { [ proc_get_boolean_parameter setting_HBreakTest ] } {
		add_interface           $HBREAK_IRQ_INTF     "interrupt"                         "receiver"              $CLOCK_INTF
		if { "$local_impl" == "Tiny" } {
			add_interface_port      $HBREAK_IRQ_INTF     "test_hbreak_req"               "irq"                   "input"     1
		} else {
			add_interface_port      $HBREAK_IRQ_INTF     "test_hbreak_req"               "irq"                   "input"     32
		}
		set_interface_property  $HBREAK_IRQ_INTF     "irqScheme"                         "individualRequests"
		set_interface_property  $HBREAK_IRQ_INTF     "associatedAddressablePoint"        $I_MASTER_INTF
		set_interface_property  $HBREAK_IRQ_INTF     "ENABLED"                           "true"
	}
}

#------------------------------
# [6.6] Jtag Debug Slave interface
#------------------------------                    
proc sub_elaborate_jtag_debug_slave_interface {} {
    global DEBUG_INTF
    global CLOCK_INTF
    global I_MASTER_INTF
    global D_MASTER_INTF
    global DEBUG_HOST_INTF

    set local_debug_level [ proc_get_boolean_parameter debug_enabled ]
    
    # We are going for byte addressing to match the sld2mm
    set debug_host_address_width 8
    set onchip_trace_support [ proc_get_boolean_parameter debug_onchiptrace ]
    set oci_trace_addr_width [ proc_get_oci_trace_addr_width ]
    set setting_oci_version [ get_parameter_value setting_oci_version ]
    set local_asic_enabled              [ proc_get_boolean_parameter setting_asic_enabled ]
    set local_debug_level               [ proc_get_boolean_parameter debug_enabled ]

    if { ${local_debug_level}  } {
        add_interface           debug_reset_request     "reset"                "output"        $CLOCK_INTF
        add_interface_port      debug_reset_request     "debug_reset_request"        "reset"     "output"        1
        # Gives warning when the debug_reset_request loops back into the debug_reset input, when debug_reset is enabled
        if { $local_asic_enabled || $setting_oci_version == 2 } {
        	if { ${local_debug_level} } {
        		set_interface_property  debug_reset_request     "associatedResetSinks"  "debug_reset"
        	}
        } else {
        	set_interface_property  debug_reset_request     "associatedResetSinks"  ""
        }
            
        if { $setting_oci_version == 2 } {
            if { $onchip_trace_support } { 
                # every 36 bit entry is taken as 2 32-bit entry
                set oci_trace_addr_width [ expr $oci_trace_addr_width + 1 ]
                add_interface          debug_trace_slave  "avalon"                         "slave"         $CLOCK_INTF
                add_interface_port     debug_trace_slave "debug_trace_slave_address"       "address"       "input"        $oci_trace_addr_width
                add_interface_port     debug_trace_slave "debug_trace_slave_read"          "read"          "input"    1
                add_interface_port     debug_trace_slave "debug_trace_slave_readdata"      "readdata"      "output"   32
                set_interface_property debug_trace_slave "maximumPendingReadTransactions"  "0"
                set_interface_property debug_trace_slave "isMemoryDevice"                  "false"
                set_interface_property debug_trace_slave "associatedReset"                 "debug_reset"
            }

            # Always enable tie off at compose level either to SLD2MM Adapter or export
            add_interface          $DEBUG_HOST_INTF "avalon"                          "slave"         $CLOCK_INTF
            add_interface_port     $DEBUG_HOST_INTF "debug_host_slave_address"       "address"       "input"        $debug_host_address_width
            add_interface_port     $DEBUG_HOST_INTF "debug_host_slave_read"          "read"          "input"        1
            add_interface_port     $DEBUG_HOST_INTF "debug_host_slave_readdata"      "readdata"      "output"       32
            add_interface_port     $DEBUG_HOST_INTF "debug_host_slave_write"         "write"         "input"        1
            add_interface_port     $DEBUG_HOST_INTF "debug_host_slave_writedata"     "writedata"     "input"        32
            add_interface_port     $DEBUG_HOST_INTF "debug_host_slave_waitrequest"   "waitrequest"   "output"       1
            
            set_interface_property $DEBUG_HOST_INTF "maximumPendingReadTransactions"  "0"
            set_interface_property $DEBUG_HOST_INTF "isMemoryDevice"                  "false"
            set_interface_property $DEBUG_HOST_INTF "associatedReset"                 "debug_reset"
            
            set_interface_property $DEBUG_HOST_INTF "addressUnits"                 "symbols"
            
            add_interface           debug_extra   "avalon_streaming"                  "end"                   $CLOCK_INTF
            add_interface_port      debug_extra   "debug_extra"                       "data"                  "input"     2
            set_interface_property  debug_extra   "symbolsPerBeat"                    "2"
            set_interface_property  debug_extra   "dataBitsPerSymbol"                 "2"
            set_interface_property  debug_extra   "ENABLED"                           "true"
            set_interface_property  debug_extra   "associatedReset"                   "debug_reset"
        } else {
           
            add_interface           $DEBUG_INTF     "avalon"                            "slave"                 $CLOCK_INTF
            
            add_interface_port      $DEBUG_INTF     "debug_mem_slave_address"         "address"               "input"        9
            add_interface_port      $DEBUG_INTF     "debug_mem_slave_byteenable"      "byteenable"            "input"        4
            add_interface_port      $DEBUG_INTF     "debug_mem_slave_debugaccess"     "debugaccess"           "input"        1
            add_interface_port      $DEBUG_INTF     "debug_mem_slave_read"            "read"                  "input"        1
            add_interface_port      $DEBUG_INTF     "debug_mem_slave_readdata"        "readdata"              "output"       32
            add_interface_port      $DEBUG_INTF     "debug_mem_slave_waitrequest"     "waitrequest"           "output"       1
            add_interface_port      $DEBUG_INTF     "debug_mem_slave_write"           "write"                 "input"        1
            add_interface_port      $DEBUG_INTF     "debug_mem_slave_writedata"       "writedata"             "input"        32
            set_interface_property  $DEBUG_INTF     "maximumPendingReadTransactions"    "0"
            set_interface_property  $DEBUG_INTF     "associatedClock"                   "$CLOCK_INTF"
            set_interface_property  $DEBUG_INTF     "alwaysBurstMaxBurst"               "false"
            set_interface_property  $DEBUG_INTF     "isMemoryDevice"                    "true"
            set_interface_property  $DEBUG_INTF     "registerIncomingSignals"           "true"
            set_interface_property  $DEBUG_INTF     "associatedReset"                   "reset"
            set_interface_property  $DEBUG_INTF     "ENABLED"                           "true"
            set_interface_assignment $DEBUG_INTF    "qsys.ui.connect"                   "${I_MASTER_INTF},${D_MASTER_INTF}"
            
            proc_set_interface_embeddedsw_configuration_assignment $DEBUG_INTF     "hideDevice" 1
            # We support two IDs for Nios II, need to register both so SystemConsole can bind
            set_module_assignment debug.hostConnection {type jtag id 70:34|110:135}
            
            # TODO: finish proper interface property settings
                #    Address_Alignment = "dynamic";
                #    Well_Behaved_Waitrequest = "0";
                #    Minimum_Uninterrupted_Run_Length = "1";
                #    Accepts_Internal_Connections = "1";
                #    Write_Latency = "0";
                #    Register_Incoming_Signals = "0";
                #    Register_Outgoing_Signals = "0";
                #    Always_Burst_Max_Burst = "0";
                #    Is_Big_Endian = "0";
                #    Is_Enabled = "1";
                #    Accepts_External_Connections = "1";
                #    Requires_Internal_Connections = "";
        }
    }
}

#------------------------------
# [6.7] Avalon debug port
#------------------------------
proc sub_elaborate_avalon_debug_port_interface {} {
    global AV_DEBUG_PORT
    global CLOCK_INTF
    
    set local_debug_level [ proc_get_boolean_parameter debug_enabled ]
    if { ${local_debug_level} } {
	    set AVALON_DEBUG_PORT_PRESENT [ get_parameter_value setting_avalonDebugPortPresent ]
	    if { $AVALON_DEBUG_PORT_PRESENT } {
		add_interface          $AV_DEBUG_PORT "avalon"                          "slave"         $CLOCK_INTF
		add_interface_port     $AV_DEBUG_PORT "avalon_debug_port_address"       "address"       "input"        9
		add_interface_port     $AV_DEBUG_PORT "avalon_debug_port_readdata"      "readdata"      "output"       32
		add_interface_port     $AV_DEBUG_PORT "avalon_debug_port_write"         "write"         "input"        1
		add_interface_port     $AV_DEBUG_PORT "avalon_debug_port_read"          "read"          "input"        1
		add_interface_port     $AV_DEBUG_PORT "avalon_debug_port_writedata"     "writedata"     "input"        32
		set_interface_property $AV_DEBUG_PORT "maximumPendingReadTransactions"  "0"
		set_interface_property $AV_DEBUG_PORT "isMemoryDevice"                  "false"
		set_interface_property $AV_DEBUG_PORT "associatedReset"                 "reset"
	    }
    }
}

#------------------------------
# [6.1] D-Master Interface
#------------------------------
proc sub_elaborate_datam_interface {} {
    global D_MASTER_INTF
    global CLOCK_INTF
    set tmr_enabled [ proc_get_boolean_parameter tmr_enabled ]
    set impl [ get_parameter_value impl ]
    
    add_interface           $D_MASTER_INTF   "avalon"            "master"            $CLOCK_INTF
    set_interface_property  $D_MASTER_INTF   "burstOnBurstBoundariesOnly"           "true"
    set_interface_property  $D_MASTER_INTF   "linewrapBursts"                       "false"
    set_interface_property  $D_MASTER_INTF   "alwaysBurstMaxBurst"                  "false"
    set_interface_property  $D_MASTER_INTF   "doStreamReads"                        "false"
    set_interface_property  $D_MASTER_INTF   "doStreamWrites"                       "false"
    if { !$tmr_enabled } {
        set_interface_property  $D_MASTER_INTF   "addressGroup"                         "1"
    }
    set_interface_property	$D_MASTER_INTF	 "registerIncomingSignals"		        "true"
    set_interface_property  $D_MASTER_INTF   "associatedReset"                      "reset"
    add_interface_port      $D_MASTER_INTF   "d_address"         "address"           "output"    [ get_parameter_value dataAddrWidth ]
    add_interface_port      $D_MASTER_INTF   "d_byteenable"      "byteenable"        "output"    4
    add_interface_port      $D_MASTER_INTF   "d_read"            "read"              "output"    1
    add_interface_port      $D_MASTER_INTF   "d_readdata"        "readdata"          "input"     32
    add_interface_port      $D_MASTER_INTF   "d_waitrequest"     "waitrequest"       "input"     1
    add_interface_port      $D_MASTER_INTF   "d_write"           "write"             "output"    1
    add_interface_port      $D_MASTER_INTF   "d_writedata"       "writedata"         "output"    32
    set_interface_assignment $D_MASTER_INTF  "debug.providesServices" "master"
            
    # Enable response signal for M core only
    if { "${impl}" == "Small" } {
        add_interface_port  $D_MASTER_INTF   "d_response"       "response"         "input"     2
    }
    #set_port_property d_address WIDTH [ get_parameter_value dataAddrWidth ]
    
    # Create a dummy input and tied off to 0
    # To be supported by Qsys
    #add_interface         "response"   "conduit"              "end"
    #add_interface_port    "response"   "d_response"    "export"          "input"     2
    #add_interface_port    "response"   "d_writeresponsevalid"    "export"          "input"     1
    #add_interface_port    "response"   "d_writeresponserequest"    "export"          "output"     1
    #set_port_property d_response TERMINATION true
    #set_port_property d_response TERMINATION_VALUE 0
    #set_port_property d_writeresponsevalid TERMINATION true
    #set_port_property d_writeresponsevalid TERMINATION_VALUE 0
    #set_port_property d_writeresponserequest TERMINATION true
}

#------------------------------
# [6.2] I-Master Interface
#------------------------------
proc sub_elaborate_instructionm_interface {} {
    global I_MASTER_INTF
    global CLOCK_INTF
    set tmr_enabled [ proc_get_boolean_parameter tmr_enabled ]
    set impl [ get_parameter_value impl ]

    add_interface           $I_MASTER_INTF   "avalon"            "master"            $CLOCK_INTF
    set_interface_property  $I_MASTER_INTF   "burstOnBurstBoundariesOnly"           "false"
    set_interface_property  $I_MASTER_INTF   "linewrapBursts"                       "true"
    set_interface_property  $I_MASTER_INTF   "alwaysBurstMaxBurst"                  "true"
    set_interface_property  $I_MASTER_INTF   "doStreamReads"                        "false"
    set_interface_property  $I_MASTER_INTF   "doStreamWrites"                       "false"
    if { !$tmr_enabled } {
        set_interface_property  $I_MASTER_INTF   "addressGroup"                         "1"
    }
    set_interface_property  $I_MASTER_INTF   "associatedReset"                      "reset"
    #set_interface_property	$I_MASTER_INTF	 "registerIncomingSignals"		"true"
    add_interface_port      $I_MASTER_INTF  "i_address"         "address"           "output"    [ get_parameter_value instAddrWidth ]
    add_interface_port      $I_MASTER_INTF  "i_read"            "read"              "output"    1
    add_interface_port      $I_MASTER_INTF  "i_readdata"        "readdata"          "input"     32
    add_interface_port      $I_MASTER_INTF  "i_waitrequest"     "waitrequest"       "input"     1
    # Enable response signal for M core only
    if { "${impl}" == "Small" } {
        add_interface_port  $I_MASTER_INTF   "i_response"       "response"         "input"     2
    }
    #add_interface_port      $I_MASTER_INTF  "i_readdatavalid"     "readdatavalid"       "input"     1
    
    #set_port_property i_address WIDTH [ get_parameter_value instAddrWidth ]
}

#------------------------------
# [6.2] FA-Master Interface
#------------------------------
proc sub_elaborate_flashm_interface {} {
    global FA_MASTER_INTF
    global CLOCK_INTF
    set fa_cache_line [ proc_get_boolean_parameter fa_cache_line ]
    set fa_cache_linesize [ get_parameter_value fa_cache_linesize ]
    set impl [ get_parameter_value impl ]
    if { $fa_cache_linesize == 8 } {
        set fa_burstcount_size 2
    } else {
        set fa_burstcount_size 3
    }
    
    set mmu_enabled [ proc_get_mmu_present ]
    set tmr_enabled [ proc_get_boolean_parameter tmr_enabled ]
    
    if { $fa_cache_linesize > 0 && $impl == "Fast" && !$mmu_enabled } {
        add_interface           $FA_MASTER_INTF   "avalon"            "master"            $CLOCK_INTF
        set_interface_property  $FA_MASTER_INTF   "burstOnBurstBoundariesOnly"           "false"
        set_interface_property  $FA_MASTER_INTF   "linewrapBursts"                       "true"
        set_interface_property  $FA_MASTER_INTF   "alwaysBurstMaxBurst"                  "true"
        set_interface_property  $FA_MASTER_INTF   "doStreamReads"                        "false"
        set_interface_property  $FA_MASTER_INTF   "doStreamWrites"                       "false"
        if { !$tmr_enabled } {
            set_interface_property  $FA_MASTER_INTF   "addressGroup"                         "1"
        }
        set_interface_property  $FA_MASTER_INTF   "associatedReset"                      "reset"
        add_interface_port      $FA_MASTER_INTF  "fa_address"         "address"           "output"    [ get_parameter_value faAddrWidth ]
        add_interface_port      $FA_MASTER_INTF  "fa_read"            "read"              "output"    1
        add_interface_port      $FA_MASTER_INTF  "fa_readdata"        "readdata"          "input"     32
        add_interface_port      $FA_MASTER_INTF  "fa_waitrequest"     "waitrequest"       "input"     1
        # Enable response signal for M core only
        if { "${impl}" == "Small" } {
            add_interface_port  $FA_MASTER_INTF   "fa_response"       "response"         "input"     2
        }
        add_interface_port      $FA_MASTER_INTF  "fa_readdatavalid"   "readdatavalid"    "input"     1
        add_interface_port      $FA_MASTER_INTF  "fa_burstcount"      "burstcount"       "output"     $fa_burstcount_size
    }
}

#------------------------------
# [6.8] Custom Instruction
#------------------------------
proc sub_elaborate_custom_instruction {} {
        
    global  CLOCK_INTF
    global  CI_MASTER_INTF
    
    set has_any_ci      [ proc_has_any_ci_slave ]
    set has_combo_ci    [ proc_has_combo_ci_slave ]
    set has_multi_ci    [ proc_has_multi_ci_slave ]
    set local_impl [ get_parameter_value impl ]
    
    add_interface       $CI_MASTER_INTF     "nios_custom_instruction"       "master"
    
    
    if { $has_any_ci } {
        if { "$local_impl" == "Fast" } {
            if { $has_multi_ci  } {
                #MULTI
                # inputs:
                add_interface_port $CI_MASTER_INTF   "A_ci_multi_done"       "done"             "input"     1
                add_interface_port $CI_MASTER_INTF   "A_ci_multi_result"     "multi_result"     "input"     32
                # outputs:
                add_interface_port $CI_MASTER_INTF   "A_ci_multi_a"          "multi_a"          "output"    5
                add_interface_port $CI_MASTER_INTF   "A_ci_multi_b"          "multi_b"          "output"    5
                add_interface_port $CI_MASTER_INTF   "A_ci_multi_c"          "multi_c"          "output"    5
                add_interface_port $CI_MASTER_INTF   "A_ci_multi_clk_en"     "clk_en"           "output"    1
                add_interface_port $CI_MASTER_INTF   "A_ci_multi_clock"      "clk"              "output"    1
                add_interface_port $CI_MASTER_INTF   "A_ci_multi_reset"      "reset"            "output"    1
                add_interface_port $CI_MASTER_INTF   "A_ci_multi_reset_req"  "reset_req"        "output"    1
                add_interface_port $CI_MASTER_INTF   "A_ci_multi_dataa"      "multi_dataa"      "output"    32
                add_interface_port $CI_MASTER_INTF   "A_ci_multi_datab"      "multi_datab"      "output"    32
                add_interface_port $CI_MASTER_INTF   "A_ci_multi_n"          "multi_n"          "output"    8
                add_interface_port $CI_MASTER_INTF   "A_ci_multi_readra"     "multi_readra"     "output"    1
                add_interface_port $CI_MASTER_INTF   "A_ci_multi_readrb"     "multi_readrb"     "output"    1
                add_interface_port $CI_MASTER_INTF   "A_ci_multi_start"      "start"            "output"    1
                add_interface_port $CI_MASTER_INTF   "A_ci_multi_writerc"    "multi_writerc"    "output"    1
            }
            if { $has_combo_ci } {
                #COMBI
                # inputs:
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_result"     "result"           "input"     32
                # outputs:
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_a"          "a"                "output"    5
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_b"          "b"                "output"    5
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_c"          "c"                "output"    5
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_dataa"      "dataa"            "output"    32
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_datab"      "datab"            "output"    32
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_estatus"    "estatus"          "output"    1
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_ipending"   "ipending"         "output"    32
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_n"          "n"                "output"    8
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_readra"     "readra"           "output"    1
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_readrb"     "readrb"           "output"    1
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_writerc"    "writerc"          "output"    1
            }
        } elseif { "$local_impl" == "Small" } {
            if { $has_multi_ci  } {
                #MULTI
                # inputs:
                add_interface_port $CI_MASTER_INTF   "M_ci_multi_done"       "done"             "input"     1
                add_interface_port $CI_MASTER_INTF   "M_ci_multi_result"     "multi_result"     "input"     32
                # outputs:
                add_interface_port $CI_MASTER_INTF   "M_ci_multi_a"          "multi_a"          "output"    5
                add_interface_port $CI_MASTER_INTF   "M_ci_multi_b"          "multi_b"          "output"    5
                add_interface_port $CI_MASTER_INTF   "M_ci_multi_c"          "multi_c"          "output"    5
                add_interface_port $CI_MASTER_INTF   "M_ci_multi_clk_en"     "clk_en"           "output"    1
                add_interface_port $CI_MASTER_INTF   "M_ci_multi_clock"      "clk"              "output"    1
                add_interface_port $CI_MASTER_INTF   "M_ci_multi_reset"      "reset"            "output"    1
                add_interface_port $CI_MASTER_INTF   "M_ci_multi_reset_req"  "reset_req"        "output"    1
                add_interface_port $CI_MASTER_INTF   "M_ci_multi_dataa"      "multi_dataa"      "output"    32
                add_interface_port $CI_MASTER_INTF   "M_ci_multi_datab"      "multi_datab"      "output"    32
                add_interface_port $CI_MASTER_INTF   "M_ci_multi_n"          "multi_n"          "output"    8
                add_interface_port $CI_MASTER_INTF   "M_ci_multi_readra"     "multi_readra"     "output"    1
                add_interface_port $CI_MASTER_INTF   "M_ci_multi_readrb"     "multi_readrb"     "output"    1
                add_interface_port $CI_MASTER_INTF   "M_ci_multi_start"      "start"            "output"    1
                add_interface_port $CI_MASTER_INTF   "M_ci_multi_writerc"    "multi_writerc"    "output"    1
            }
            if { $has_combo_ci } {
                #COMBI
                # inputs:
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_result"     "result"           "input"     32
                # outputs:
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_a"          "a"                "output"    5
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_b"          "b"                "output"    5
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_c"          "c"                "output"    5
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_dataa"      "dataa"            "output"    32
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_datab"      "datab"            "output"    32
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_estatus"    "estatus"          "output"    1
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_ipending"   "ipending"         "output"    32
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_n"          "n"                "output"    8
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_readra"     "readra"           "output"    1
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_readrb"     "readrb"           "output"    1
                add_interface_port $CI_MASTER_INTF   "E_ci_combo_writerc"    "writerc"          "output"    1
            }
        } elseif { "$local_impl" == "Tiny" } {
            if { $has_multi_ci  } {
                # inputs:
                add_interface_port $CI_MASTER_INTF     "E_ci_multi_done"     "done"          "input"         1
                # outputs:
                add_interface_port $CI_MASTER_INTF     "E_ci_multi_clk_en"   "clk_en"        "output"        1                
                add_interface_port $CI_MASTER_INTF     "E_ci_multi_start"    "start"         "output"        1
                }
                # inputs:
                add_interface_port $CI_MASTER_INTF     "E_ci_result"         "result"        "input"         32
                # outputs:
                add_interface_port $CI_MASTER_INTF     "D_ci_a"              "a"             "output"        5
                add_interface_port $CI_MASTER_INTF     "D_ci_b"              "b"             "output"        5
                add_interface_port $CI_MASTER_INTF     "D_ci_c"              "c"             "output"        5
                add_interface_port $CI_MASTER_INTF     "D_ci_n"              "n"             "output"        8
                add_interface_port $CI_MASTER_INTF     "D_ci_readra"         "readra"        "output"        1
                add_interface_port $CI_MASTER_INTF     "D_ci_readrb"         "readrb"        "output"        1
                add_interface_port $CI_MASTER_INTF     "D_ci_writerc"        "writerc"       "output"        1
                add_interface_port $CI_MASTER_INTF     "E_ci_dataa"          "dataa"         "output"        32
                add_interface_port $CI_MASTER_INTF     "E_ci_datab"          "datab"         "output"        32
                add_interface_port $CI_MASTER_INTF     "E_ci_multi_clock"    "clk"           "output"        1
                add_interface_port $CI_MASTER_INTF     "E_ci_multi_reset"    "reset"         "output"        1
                add_interface_port $CI_MASTER_INTF     "E_ci_multi_reset_req"   "reset_req"  "output"        1
                add_interface_port $CI_MASTER_INTF     "W_ci_estatus"        "estatus"       "output"        1
                add_interface_port $CI_MASTER_INTF     "W_ci_ipending"       "ipending"      "output"        32
            
            # Special requirement for e core
            set_interface_property $CI_MASTER_INTF  "sharedCombinationalAndMulticycle"  "true"
        }
    } else {
        # No CI Slave, just put any thing here for termination
        add_interface_port $CI_MASTER_INTF   "dummy_ci_port"         "readra"        "output"        1
    }
}

#------------------------------
# [6.9] Update Instruction Master & Data Master Interface
#------------------------------
proc sub_elaborate_update_processor_inst_and_data_master {} {


    # Width
    #set_port_property i_address WIDTH [ get_parameter_value instAddrWidth ]
    #set_port_property d_address WIDTH [ get_parameter_value dataAddrWidth ]

    # Burst
    global I_MASTER_INTF
    global D_MASTER_INTF

    set impl                            [ get_parameter_value impl ]
    set tcdm_num                        [ get_parameter_value dcache_numTCDM ]

    # i_burstcount
    # if I-cache burst is turn on, i_burstcount width is always 4 bit wide
    set local_icache_bursttype      [ get_parameter_value icache_burstType ]
    set icache_size [get_parameter_value icache_size]
    # only F-core has burstcount on the Instruction master
    set has_i_burstcount [ expr { "$icache_size" != "0" } && { "$impl" == "Fast" } && { "$local_icache_bursttype" != "None" } ]

    if { $has_i_burstcount } {
        add_interface_port      $I_MASTER_INTF  "i_burstcount"         "burstcount"           "output"    4
    }

    # d_burstcount
    # if D-cache burst is turn on, d_burstcount width is
    #   4 bit wide for 32 bit cache line size
    set local_dcache_burst_derived       [ proc_get_boolean_parameter dcache_bursts_derived ]
    set local_dcache_size_derived        [get_parameter_value dcache_size_derived]
    set has_d_burstcount [ expr { "$impl" == "Fast" } && { "$local_dcache_size_derived" != "0" } && { $local_dcache_burst_derived } ]
    if { $has_d_burstcount } {
        add_interface_port      $D_MASTER_INTF  "d_burstcount"         "burstcount"           "output"    4
    }

    # d_readdatavalid
    # only present in "Fast" core
    set impl [get_parameter_value impl]
    set d_readdatavalid_exist [ expr  { "$impl" == "Fast" } && { "$local_dcache_size_derived" != "0" } ]
    if { $d_readdatavalid_exist } {
        add_interface_port      $D_MASTER_INTF  "d_readdatavalid"   "readdatavalid"     "input"     1

    }
    
    # d_master registerIncomingSignals
    set has_dcache [ expr { "$impl" == "Fast" } && { "$local_dcache_size_derived" != "0" } ]
    
    if { "$has_dcache" == "1" } {
        set_interface_property  $D_MASTER_INTF     "registerIncomingSignals"           "false"
    } elseif { "$impl" != "Tiny" } {
        set_interface_property  $D_MASTER_INTF     "registerIncomingSignals"           "false"
    } else {
        set_interface_property  $D_MASTER_INTF     "registerIncomingSignals"           "true"
    }

    # i_readdatavalid
    set has_i_readdatavalid [ expr { "$impl" == "Fast" } && { "$icache_size" != "0" } ]
    if { $has_i_readdatavalid } {
        add_interface_port      $I_MASTER_INTF  "i_readdatavalid"   "readdatavalid"     "input"     1

    }

    # jtag_debug_slave_debugaccess_to_roms only exist when debug there is jtag debug slave
    set debug_level [ proc_get_boolean_parameter debug_enabled ]
    set setting_oci_version [ get_parameter_value setting_oci_version ]
    if { $debug_level && $setting_oci_version == 1 } {
        add_interface_port      $D_MASTER_INTF  "debug_mem_slave_debugaccess_to_roms"   "debugaccess"   "output"        1
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
    global CLOCK_INTF
    global ECC_EVENT

    set impl [ get_parameter_value impl ]
    set include_debug_debugReqSignals   [ proc_get_boolean_parameter debug_debugReqSignals ]
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
    set local_debug_offchiptrace        [ proc_get_boolean_parameter debug_offchiptrace ]

    set local_debug_hwbreakpoint        [ get_parameter_value debug_hwbreakpoint ]
    set local_debug_datatrigger         [ get_parameter_value debug_datatrigger ]
    # Europa always default to 36. (oci_tm_width), where oci_tm_width=dmaster_data_width+4
    set local_oci_tr_width              36

    if { ${local_debug_level} } {
      if { $include_debug_debugReqSignals } {
          add_interface         debug_conduit   "conduit"                   "end"
          add_interface_port    debug_conduit   "debug_ack"       "debug_ack"               "output"         1
          add_interface_port    debug_conduit   "debug_req"       "debug_req"               "input"          1
      }
      
      if { $local_debug_offchiptrace && !("$impl" == "Tiny") } {
          add_interface           debug_offchip_trace   "avalon_streaming"    "start"          $CLOCK_INTF
          add_interface_port      debug_offchip_trace   "debug_offchip_trace_data"       "data"        "output"        $local_oci_tr_width
          set_interface_property  debug_offchip_trace   "associatedReset"     "reset"
          set_interface_property  debug_offchip_trace   "symbolsPerBeat"      "1"
          set_interface_property  debug_offchip_trace   "dataBitsPerSymbol"   $local_oci_tr_width
          set_interface_property  debug_offchip_trace   "ENABLED"             "true"
      
          # Redefinition of jtag_debug_conduit so need to add the signals here
          if { $include_debug_debugReqSignals } {
              add_interface_port    debug_conduit   "debug_ack"       "debug_ack"               "output"         1
              add_interface_port    debug_conduit   "debug_req"       "debug_req"               "input"          1
          }
          
          if { $local_debug_hwbreakpoint > 0 || $local_debug_datatrigger > 0 } {
            add_interface           debug_conduit "conduit"                  "end"
            add_interface_port      debug_conduit "debug_trigout"            "debug_trigout"            "output"        1    
            
            # Redefinition of jtag_debug_conduit so need to add the signals here
            if { $include_debug_debugReqSignals } {
                add_interface_port    debug_conduit   "debug_ack"       "debug_ack"               "output"         1
                add_interface_port    debug_conduit   "debug_req"       "debug_req"               "input"          1
            }
          }
      }
      
      
      
      if { $local_HBreakTest } {
          add_interface       ${HW_BREAKTEST}_conduit        "conduit"                "end"
          add_interface_port  ${HW_BREAKTEST}_conduit        "oci_async_hbreak_req"        "oci_async_hbreak_req"                "output"        1
          add_interface_port  ${HW_BREAKTEST}_conduit        "oci_sync_hbreak_req"         "oci_sync_hbreak_req"                "output"        1
      }
    } 
    
    if { $local_cpuresetrequest } {
        add_interface       ${CPU_RESET}_conduit        "conduit"                   "end"
        add_interface_port  ${CPU_RESET}_conduit        "cpu_resetrequest"          "cpu_resetrequest"                "input"         1
        add_interface_port  ${CPU_RESET}_conduit        "cpu_resettaken"            "cpu_resettaken"                "output"        1
    }

    if { $local_setting_exportdebuginfo } {
        add_interface           ${PROGRAM_COUNTER}   "avalon_streaming"    "start"       $CLOCK_INTF
        add_interface_port      ${PROGRAM_COUNTER}   "pc"                  "data"        "output"        32
        add_interface_port      ${PROGRAM_COUNTER}   "pc_valid"            "valid"       "output"        1
        set_interface_property  ${PROGRAM_COUNTER}   "associatedReset"     "reset"
        set_interface_property  ${PROGRAM_COUNTER}   "symbolsPerBeat"      "1"
        set_interface_property  ${PROGRAM_COUNTER}   "dataBitsPerSymbol"   32
        set_interface_property  ${PROGRAM_COUNTER}   "ENABLED"             "true"

        add_interface           instruction_word   "avalon_streaming"    "start"       $CLOCK_INTF
        add_interface_port      instruction_word   "iw"                  "data"        "output"        32
        add_interface_port      instruction_word   "iw_valid"            "valid"       "output"        1
        set_interface_property  instruction_word   "associatedReset"     "reset"
        set_interface_property  instruction_word   "symbolsPerBeat"      "1"
        set_interface_property  instruction_word   "dataBitsPerSymbol"   32
        set_interface_property  instruction_word   "ENABLED"             "true"
        
        add_interface           exception_bit   "avalon_streaming"    "start"       $CLOCK_INTF
        add_interface_port      exception_bit   "exc"                 "data"        "output"        1
        add_interface_port      exception_bit   "exc_valid"           "valid"       "output"        1
        set_interface_property  exception_bit   "associatedReset"     "reset"
        set_interface_property  exception_bit   "symbolsPerBeat"      "1"
        set_interface_property  exception_bit   "dataBitsPerSymbol"    1
        set_interface_property  exception_bit   "ENABLED"             "true"
    }
    
# fb45389: export large rams parameter
    if { $local_export_large_RAMs } {
        sub_elaborate_export_large_rams
    }

# Adding support for ASIC flow: adding reset and sld_jtag conduit ports
# if this is M-core always export the debug reset
    
    set setting_oci_version [ get_parameter_value setting_oci_version ]
    if { $local_asic_enabled || $setting_oci_version == 2 } {
        if { ${local_debug_level} } {
            add_interface debug_reset reset end $CLOCK_INTF
            add_interface_port debug_reset debug_reset     reset      Input 1
        }
    }
    
    if { $local_oci_export_jtag_signals == "1" && $local_avalon_debug_present == "0" && $setting_oci_version == "1" } {
        if { ${local_debug_level} } {
            add_interface       sld_jtag      "conduit"      "end"
            add_interface_port  sld_jtag      "vji_ir_out"   "vji_ir_out"                "output"       2
            add_interface_port  sld_jtag      "vji_tdo"      "vji_tdo"                "output"       1
            add_interface_port  sld_jtag      "vji_cdr"      "vji_cdr"                "input"        1
            add_interface_port  sld_jtag      "vji_ir_in"    "vji_ir_in"                "input"        2
            add_interface_port  sld_jtag      "vji_rti"      "vji_rti"                "input"        1
            add_interface_port  sld_jtag      "vji_sdr"      "vji_sdr"                "input"        1
            add_interface_port  sld_jtag      "vji_tck"      "vji_tck"                "input"        1
            add_interface_port  sld_jtag      "vji_tdi"      "vji_tdi"                "input"        1
            add_interface_port  sld_jtag      "vji_udr"      "vji_udr"                "input"        1
            add_interface_port  sld_jtag      "vji_uir"      "vji_uir"                "input"        1
        }
    }

    # Set the vector width to always 30 bits for MMU system, else follow the instruction address width
    if {$local_mmu_enable} {
        set local_vector_width 30
    } else {
        set local_vector_width [ expr {$local_instaddrwidth - 2} ]
    }

    # Adding conduit signals to reset/exception/break vectors
    if { $local_exportvectors } {
        add_interface           reset_vector_conduit        "conduit"                     "end"
        add_interface_port      reset_vector_conduit        "reset_vector_word_addr"      "export"                "input"        $local_vector_width
        add_interface           exception_vector_conduit    "conduit"                     "end"
        add_interface_port      exception_vector_conduit    "exception_vector_word_addr"  "export"                "input"        $local_vector_width
        if {$local_mmu_enable} {
            add_interface           fast_tlb_miss_vector_conduit        "conduit"                             "end"
            add_interface_port      fast_tlb_miss_vector_conduit        "fast_tlb_miss_vector_word_addr"      "export"                "input"        $local_vector_width
        }
    }
    
    # Adding an ST streaming interface for the ECC event bus
    set local_ecc_present [ proc_get_boolean_parameter setting_ecc_present ]
    set local_impl [ get_parameter_value impl ]
    set ecc_sim_test_ports [ proc_get_boolean_parameter setting_ecc_sim_test_ports ]
    set event_bus_width 30
    if { "$local_impl" == "Fast" } {
        set ecc_sim_test_interface "ic_tag ic_data dc_tag dc_data dc_wb rf dtcm0 dtcm1 dtcm2 dtcm3 tlb"
    } else {
        set ecc_sim_test_interface "rf"
    }
    
    if { "$local_impl" != "Small" && $local_ecc_present } {
        add_interface           ${ECC_EVENT}   "avalon_streaming"    "start"       $CLOCK_INTF
        add_interface_port      ${ECC_EVENT}   "ecc_event_bus"       "data"        "output"        $event_bus_width
        set_interface_property  ${ECC_EVENT}   "associatedReset"     "reset"
        set_interface_property  ${ECC_EVENT}   "symbolsPerBeat"      "1"
        set_interface_property  ${ECC_EVENT}   "dataBitsPerSymbol"   $event_bus_width
        set_interface_property  ${ECC_EVENT}   "ENABLED"             "true"
        
        # All ports are always available and are 72 bits for data + parity access
        if { $ecc_sim_test_ports } {
            foreach i $ecc_sim_test_interface {
                set INTF_NAME "ecc_test_${i}"
                
                add_interface           $INTF_NAME   "avalon_streaming"          "end"       $CLOCK_INTF
                add_interface_port      $INTF_NAME   "ecc_test_${i}"       "data"        "input"        72
                add_interface_port      $INTF_NAME   "ecc_test_${i}_valid" "valid"       "input"        1
                add_interface_port      $INTF_NAME   "ecc_test_${i}_ready" "ready"       "output"       1
                set_interface_property  $INTF_NAME   "associatedReset"           "reset"
                set_interface_property  $INTF_NAME   "symbolsPerBeat"            "1"
                set_interface_property  $INTF_NAME   "dataBitsPerSymbol"         "72"
                set_interface_property  $INTF_NAME   "ENABLED"                   "true"
            }
        }
    }
    
    # Create register POR only for Nios/M
    set register_file_por [ get_parameter_value register_file_por]

    if { ${register_file_por} && $impl == "Small" } {
    	add_interface           por_rf     "reset"     "sink"      $CLOCK_INTF      
    	add_interface_port      por_rf     "por_rf_n"   "reset_n"   "input"     1
    }
}

#------------------------------
# [6.10-5] elaborate conduit interfaces for export large rams
#------------------------------
proc sub_elaborate_export_large_rams {} {
    set local_icache_present         [ proc_get_icache_present ]
    set local_mmu_enabled            [ proc_get_mmu_present ]
    set local_instaddrwidth          [ get_parameter_value instAddrWidth ]
    set local_dataaddrwidth          [ get_parameter_value dataAddrWidth ]
    set local_debug_level            [ proc_get_boolean_parameter debug_enabled ]
    set impl                         [ get_parameter_value impl ]
    set local_icache_size            [ get_parameter_value icache_size ]
    set local_dcache_size_derived    [ get_parameter_value dcache_size_derived ]
    set local_oci_version            [ get_parameter_value setting_oci_version ]
    if { [expr { $local_icache_present == "1" } && { $impl == "Fast" }] } {
        set ic_data_addr_sz          [ proc_calculate_ic_data_addr_size ]
        set ic_data_data_sz          32
        set ic_tag_addr_sz           [ proc_calculate_ic_tag_addr_size ]
        set ic_tag_data_sz           [ proc_calculate_ic_tag_data_size ]

        add_interface       icache_conduit        "conduit"                "end"
        add_interface_port  icache_conduit        "icache_tag_ram_write_data"        "icache_tag_ram_write_data"               "output"        $ic_tag_data_sz
        add_interface_port  icache_conduit        "icache_tag_ram_write_enable"      "icache_tag_ram_write_enable"             "output"        1
        add_interface_port  icache_conduit        "icache_tag_ram_write_address"     "icache_tag_ram_write_address"            "output"        $ic_tag_addr_sz
        add_interface_port  icache_conduit        "icache_tag_ram_read_clk_en"       "icache_tag_ram_read_clk_en"              "output"        1
        add_interface_port  icache_conduit        "icache_tag_ram_read_address"      "icache_tag_ram_read_address"             "output"        $ic_tag_addr_sz
        add_interface_port  icache_conduit        "icache_tag_ram_read_data"         "icache_tag_ram_read_data"                "input"         $ic_tag_data_sz
        add_interface_port  icache_conduit        "icache_data_ram_write_data"       "icache_data_ram_write_data"              "output"        $ic_data_data_sz
        add_interface_port  icache_conduit        "icache_data_ram_write_enable"     "icache_data_ram_write_enable"            "output"        1
        add_interface_port  icache_conduit        "icache_data_ram_write_address"    "icache_data_ram_write_address"           "output"        $ic_data_addr_sz
        add_interface_port  icache_conduit        "icache_data_ram_read_clk_en"      "icache_data_ram_read_clk_en"             "output"        1
        add_interface_port  icache_conduit        "icache_data_ram_read_address"     "icache_data_ram_read_address"            "output"        $ic_data_addr_sz
        add_interface_port  icache_conduit        "icache_data_ram_read_data"        "icache_data_ram_read_data"               "input"         $ic_data_data_sz
    }

    if { [expr { $local_dcache_size_derived != "0" } && { $impl == "Fast" }] } {
        set dc_data_addr_sz          [ proc_calculate_dc_data_addr_size ]
        set dc_data_data_sz          32
        set dc_byte_en_sz            4
        set dc_tag_addr_sz           [ proc_calculate_dc_tag_addr_size ]
        set dc_tag_data_sz           [ proc_calculate_dc_tag_data_size ]
       
        set dc_bytes_per_line        [ get_parameter_value dcache_lineSize_derived ]
        set dc_cache_wide            [ expr { $dc_bytes_per_line > 4 } ]

        add_interface       dcache_conduit        "conduit"                "end"
        add_interface_port  dcache_conduit        "dcache_g4b_tag_ram_write_data"        "dcache_g4b_tag_ram_write_data"                "output"        $dc_tag_data_sz
        add_interface_port  dcache_conduit        "dcache_g4b_tag_ram_write_enable"      "dcache_g4b_tag_ram_write_enable"              "output"        1
        add_interface_port  dcache_conduit        "dcache_g4b_tag_ram_write_address"     "dcache_g4b_tag_ram_write_address"             "output"        $dc_tag_addr_sz
        add_interface_port  dcache_conduit        "dcache_g4b_tag_ram_read_clk_en"       "dcache_g4b_tag_ram_read_clk_en"               "output"        1
        add_interface_port  dcache_conduit        "dcache_g4b_tag_ram_read_address"      "dcache_g4b_tag_ram_read_address"              "output"        $dc_tag_addr_sz
        add_interface_port  dcache_conduit        "dcache_g4b_tag_ram_read_data"         "dcache_g4b_tag_ram_read_data"                 "input"         $dc_tag_data_sz
        add_interface_port  dcache_conduit        "dcache_g4b_data_ram_byte_enable"      "dcache_g4b_data_ram_byte_enable"              "output"        $dc_byte_en_sz
        add_interface_port  dcache_conduit        "dcache_g4b_data_ram_write_data"       "dcache_g4b_data_ram_write_data"               "output"        $dc_data_data_sz
        add_interface_port  dcache_conduit        "dcache_g4b_data_ram_write_enable"     "dcache_g4b_data_ram_write_enable"             "output"        1
        add_interface_port  dcache_conduit        "dcache_g4b_data_ram_write_address"    "dcache_g4b_data_ram_write_address"            "output"        $dc_data_addr_sz
        add_interface_port  dcache_conduit        "dcache_g4b_data_ram_read_clk_en"      "dcache_g4b_data_ram_read_clk_en"              "output"        1
        add_interface_port  dcache_conduit        "dcache_g4b_data_ram_read_address"     "dcache_g4b_data_ram_read_address"             "output"        $dc_data_addr_sz
        add_interface_port  dcache_conduit        "dcache_g4b_data_ram_read_data"        "dcache_g4b_data_ram_read_data"                "input"         $dc_data_data_sz    
    }
  
    if { $local_debug_level } {
        set local_oci_trace_addr_width             [ proc_get_oci_trace_addr_width ]
        
        # OCI RAM exist only for ociversion 1
        if { $local_oci_version == 1 } {
            add_interface       oci_ram_conduit        "conduit"                "end"
            add_interface_port  oci_ram_conduit        "cpu_lpm_oci_ram_sp_address"          "cpu_lpm_oci_ram_sp_address"           "output"       8
            add_interface_port  oci_ram_conduit        "cpu_lpm_oci_ram_sp_byte_enable"      "cpu_lpm_oci_ram_sp_byte_enable"       "output"       4
            add_interface_port  oci_ram_conduit        "cpu_lpm_oci_ram_sp_write_data"       "cpu_lpm_oci_ram_sp_write_data"        "output"       32
            add_interface_port  oci_ram_conduit        "cpu_lpm_oci_ram_sp_write_enable"     "cpu_lpm_oci_ram_sp_write_enable"      "output"       1
            add_interface_port  oci_ram_conduit        "cpu_lpm_oci_ram_sp_read_data"        "cpu_lpm_oci_ram_sp_read_data"         "input"        32
        }

        # Disable OCI onchip trace interface if not supported by debug level
        # Only export trace ram when debug level > 2 and not tiny core

        set onchip_trace_support [ proc_get_boolean_parameter debug_onchiptrace ]
        set tiny_or_no_onchip_trace_support [ expr { "$impl" == "Tiny" } || { "$onchip_trace_support" == "0" } ]

        if { !$tiny_or_no_onchip_trace_support } {
            add_interface       trace_ram_conduit      "conduit"                "end"
            add_interface_port  trace_ram_conduit      "cpu_lpm_trace_ram_sdp_wraddress"        "cpu_lpm_trace_ram_sdp_wraddress"         "output"       $local_oci_trace_addr_width
            add_interface_port  trace_ram_conduit      "cpu_lpm_trace_ram_sdp_write_data"       "cpu_lpm_trace_ram_sdp_write_data"        "output"       36
            add_interface_port  trace_ram_conduit      "cpu_lpm_trace_ram_sdp_write_enable"     "cpu_lpm_trace_ram_sdp_write_enable"      "output"       1
            add_interface_port  trace_ram_conduit      "cpu_lpm_trace_ram_sdp_rdaddress"        "cpu_lpm_trace_ram_sdp_rdaddress"         "output"       $local_oci_trace_addr_width
            add_interface_port  trace_ram_conduit      "cpu_lpm_trace_ram_sdp_read_data"        "cpu_lpm_trace_ram_sdp_read_data"         "input"        36
        }
    }
  
    if { [expr { $local_mmu_enabled }] } {
        set local_finalTlbPtrSz      [ proc_get_final_tlb_ptr_size ]
        set tlb_data_size            [ proc_calculate_tlb_data_size ]

        add_interface       mmu_conduit        "conduit"                "end"
        add_interface_port  mmu_conduit        "tlb_ram_write_enable"          "tlb_ram_write_enable"           "output"       1
        add_interface_port  mmu_conduit        "tlb_ram_read_address"          "tlb_ram_read_address"           "output"       ${local_finalTlbPtrSz}
        add_interface_port  mmu_conduit        "tlb_ram_write_address"         "tlb_ram_write_address"          "output"       ${local_finalTlbPtrSz}
        add_interface_port  mmu_conduit        "tlb_ram_write_data"            "tlb_ram_write_data"             "output"       ${tlb_data_size}
        add_interface_port  mmu_conduit        "tlb_ram_read_data"             "tlb_ram_read_data"              "input"        ${tlb_data_size}
     }
}

proc sub_elaborate_reset_req {} {
    set has_multi [ proc_has_multi_ci_slave ]
    set local_debug_level [ proc_get_boolean_parameter debug_enabled ]
    set setting_export_large_RAMs [ proc_get_boolean_parameter setting_export_large_RAMs ]
    set resetrequest_enabled [ proc_get_boolean_parameter resetrequest_enabled ]
    set setting_oci_version [ get_parameter_value setting_oci_version ]

    # Elaborate reset_req under 2 conditions
    # When there is a multi cycle custom instruction
    # When debug is enabled
    set oci_ram_present [ expr { $local_debug_level && !$setting_export_large_RAMs } ]
    if { ($oci_ram_present && $setting_oci_version == 1) || $has_multi } {
        add_interface_port reset reset_req reset_req Input 1
        if { !$resetrequest_enabled } {
            set_port_property reset_req TERMINATION TRUE
            set_port_property reset_req TERMINATION_VALUE 0
        }
    }
}

#------------------------------
# [6.0] elaborate callback main routine
#------------------------------
proc elaborate {} {
    # [6.1]
    sub_elaborate_datam_interface
    # [6.2]
    sub_elaborate_instructionm_interface
    sub_elaborate_flashm_interface
    # [6.3]
    sub_elaborate_tcdm_interface
    # [6.4]
    sub_elaborate_tcim_interface
    # Data High Performance Master For Nios II /M
    sub_elaborate_dhpm_interface
    # Instruction High Performance Master For Nios II /M
    sub_elaborate_ihpm_interface
    # [6.5]
    sub_elaborate_interrupt_controller_ports
    # [6.6]
    sub_elaborate_jtag_debug_slave_interface
    # [6.7]
    sub_elaborate_avalon_debug_port_interface
    # [6.8]
    sub_elaborate_custom_instruction
    # [6.9]
    sub_elaborate_update_processor_inst_and_data_master
    # [6.10]
    sub_elaborate_conduit_interfaces
    # [6.11]
    sub_elaborate_hbreak_interrupt_controller_ports
    # Reset req for OCI RAM/multi CI
    sub_elaborate_reset_req
}

#------------------------------------------------------------------------------
#                              G E N E R A T I O N
#------------------------------------------------------------------------------

proc proc_get_avalon_master_string {AVALON_MASTER} {
    array set avalon_master $AVALON_MASTER
    set indent "$avalon_master(indent)"
    set return_string {}
    append return_string "${indent}$avalon_master(name) => {\n"
        append return_string "${indent}\ttype => $avalon_master(type),\n"
        append return_string "${indent}\taccess_type => $avalon_master(access_type),\n"
        append return_string "${indent}\tpaddr_base => $avalon_master(paddr_base),\n"
        append return_string "${indent}\tpaddr_top => $avalon_master(paddr_top),\n"
    append return_string "${indent}},\n"
    return "$return_string"
}

# validation is needed for TCM (only 1 slave plus info in validate_tightly_coupled_slave())
proc proc_get_avalon_master_info_string {} {
    global I_MASTER_INTF
    global FA_MASTER_INTF
    global D_MASTER_INTF
    global TCD_INTF_PREFIX
    global TCD_PREFIX
    global TCI_INTF_PREFIX
    global TCI_PREFIX
    global IHP_INTF_PREFIX
    global IHP_PREFIX
    global DHP_INTF_PREFIX
    global DHP_PREFIX
    
    set impl                            [ get_parameter_value impl ]
    set icache_size                     [ get_parameter_value icache_size ]
    set dcache_size_derived             [ get_parameter_value dcache_size_derived ]
    set tcdm_num                        [ get_parameter_value dcache_numTCDM ]
    set tcim_num                        [ get_parameter_value icache_numTCIM ]
    
    set master_addr_map                                     [ get_parameter_value master_addr_map                                 ]         
    set instruction_master_paddr_base                       [ get_parameter_value instruction_master_paddr_base                   ]
    set instruction_master_paddr_top                        [ get_parameter_value instruction_master_paddr_top                    ]
    set flash_instruction_master_paddr_base                 [ get_parameter_value flash_instruction_master_paddr_base             ]
    set flash_instruction_master_paddr_top                  [ get_parameter_value flash_instruction_master_paddr_top              ]
    set data_master_paddr_base                              [ get_parameter_value data_master_paddr_base                          ]
    set data_master_paddr_top                               [ get_parameter_value data_master_paddr_top                           ]
    set tightly_coupled_instruction_master_0_paddr_base     [ get_parameter_value tightly_coupled_instruction_master_0_paddr_base ]
    set tightly_coupled_instruction_master_0_paddr_top      [ get_parameter_value tightly_coupled_instruction_master_0_paddr_top  ]
    set tightly_coupled_instruction_master_1_paddr_base     [ get_parameter_value tightly_coupled_instruction_master_1_paddr_base ]
    set tightly_coupled_instruction_master_1_paddr_top      [ get_parameter_value tightly_coupled_instruction_master_1_paddr_top  ]
    set tightly_coupled_instruction_master_2_paddr_base     [ get_parameter_value tightly_coupled_instruction_master_2_paddr_base ]
    set tightly_coupled_instruction_master_2_paddr_top      [ get_parameter_value tightly_coupled_instruction_master_2_paddr_top  ]
    set tightly_coupled_instruction_master_3_paddr_base     [ get_parameter_value tightly_coupled_instruction_master_3_paddr_base ]
    set tightly_coupled_instruction_master_3_paddr_top      [ get_parameter_value tightly_coupled_instruction_master_3_paddr_top  ]
    set tightly_coupled_data_master_0_paddr_base            [ get_parameter_value tightly_coupled_data_master_0_paddr_base        ]
    set tightly_coupled_data_master_0_paddr_top             [ get_parameter_value tightly_coupled_data_master_0_paddr_top         ]
    set tightly_coupled_data_master_1_paddr_base            [ get_parameter_value tightly_coupled_data_master_1_paddr_base        ]
    set tightly_coupled_data_master_1_paddr_top             [ get_parameter_value tightly_coupled_data_master_1_paddr_top         ]
    set tightly_coupled_data_master_2_paddr_base            [ get_parameter_value tightly_coupled_data_master_2_paddr_base        ]
    set tightly_coupled_data_master_2_paddr_top             [ get_parameter_value tightly_coupled_data_master_2_paddr_top         ]
    set tightly_coupled_data_master_3_paddr_base            [ get_parameter_value tightly_coupled_data_master_3_paddr_base        ]
    set tightly_coupled_data_master_3_paddr_top             [ get_parameter_value tightly_coupled_data_master_3_paddr_top         ]
    set instruction_master_high_performance_paddr_base      [ get_parameter_value instruction_master_high_performance_paddr_base  ]
    set instruction_master_high_performance_paddr_top       [ get_parameter_value instruction_master_high_performance_paddr_top   ]
    set data_master_high_performance_paddr_base             [ get_parameter_value data_master_high_performance_paddr_base         ]
    set data_master_high_performance_paddr_top              [ get_parameter_value data_master_high_performance_paddr_top          ] 

    set inst_width [ get_parameter_value instAddrWidth ]
    set data_width [ get_parameter_value dataAddrWidth ]
    
    set instruction_master(name)        $I_MASTER_INTF
    set instruction_master(type)        "instruction"
    set instruction_master(access_type) "normal"
    if { $master_addr_map } {
        set instruction_master(paddr_base)  [ proc_num2hex $instruction_master_paddr_base ]
        set instruction_master(paddr_top)   [ proc_num2hex $instruction_master_paddr_top ]
    } else {
        if { $inst_width == 1 } {
            set instruction_master(paddr_base)  0
            set instruction_master(paddr_top)   1    
        } else { 
            set instruction_master(paddr_base)  [ proc_num2hex [ proc_get_lowest_start_address instSlaveMapParam ] ]
            set instruction_master(paddr_top)   [ proc_width2maxaddr [ get_parameter_value instAddrWidth ] ]
        }
    }
    set instruction_master(indent)      "\t\t\t"
    
    set fa_cache_linesize [ get_parameter_value fa_cache_linesize ]
   
    set fa_master(name)        $FA_MASTER_INTF
    set fa_master(type)        "instruction"
    set fa_master(access_type) "flash"
    if { $master_addr_map } {
        set fa_master(paddr_base)  [ proc_num2hex $flash_instruction_master_paddr_base ]
        set fa_master(paddr_top)   [ proc_num2hex $flash_instruction_master_paddr_top ]
    } else {
        if { $fa_cache_linesize == 0 } {
            set fa_master(paddr_base)  0
            set fa_master(paddr_top)   0    
        } else { 
            set fa_master(paddr_base)  [ proc_num2hex [ proc_get_lowest_start_address faSlaveMapParam ] ]
            set fa_master(paddr_top)   [ proc_width2maxaddr [ get_parameter_value faAddrWidth ] ]
        }
    }
    set fa_master(indent)      "\t\t\t"

    set data_master(name)               $D_MASTER_INTF
    set data_master(type)               "data"
    set data_master(access_type)        "normal"
    if { $master_addr_map } {
        set data_master(paddr_base)  [ proc_num2hex $data_master_paddr_base ]
        set data_master(paddr_top)   [ proc_num2hex $data_master_paddr_top ]
    } else {
    	if { $data_width == 1 } {
            set data_master(paddr_base)  0
            set data_master(paddr_top)   1
        } else {
            set data_master(paddr_base)         [ proc_num2hex [ proc_get_lowest_start_address dataSlaveMapParam ] ]
            set data_master(paddr_top)          [ proc_width2maxaddr [ get_parameter_value dataAddrWidth ] ]
        }
    }
    set data_master(indent)             "\t\t\t"

    set tcdm_num    [ get_parameter_value dcache_numTCDM ]
    set tcim_num    [ get_parameter_value icache_numTCIM ]

    set return_string ""
    append return_string "\tavalon_master_info => {\n"
        append return_string "\t\tavalon_masters => {\n"
        append return_string "[ proc_get_avalon_master_string [ array get instruction_master ]]"
        append return_string "[ proc_get_avalon_master_string [ array get fa_master ]]"
        append return_string "[ proc_get_avalon_master_string [ array get data_master ]]"

    foreach i {0 1 2 3} {
        set TCD_INTF_NAME "${TCD_INTF_PREFIX}${i}"
        set TCD_NAME "${TCD_PREFIX}${i}"
        set tcdm_address_base [ proc_num2hex [ proc_get_lowest_start_address ${TCD_NAME}MapParam ] ]
        if { [ expr { $tcdm_address_base != "[ proc_num2hex "-1" ]" } ] || $master_addr_map } {
            if { $i < $tcdm_num } {
                set tcd_master(name)               $TCD_INTF_NAME
                set tcd_master(type)               "data"
                set tcd_master(access_type)        "tcm"
                if { $master_addr_map } {
                   if { $i == 0 } {
                       set tcdm_paddr_base $tightly_coupled_data_master_0_paddr_base
                       set tcdm_paddr_top $tightly_coupled_data_master_0_paddr_top
                   } elseif { $i == 1 } {
                       set tcdm_paddr_base $tightly_coupled_data_master_1_paddr_base
                       set tcdm_paddr_top $tightly_coupled_data_master_1_paddr_top
                   } elseif { $i == 2 } {
                       set tcdm_paddr_base $tightly_coupled_data_master_2_paddr_base
                       set tcdm_paddr_top $tightly_coupled_data_master_2_paddr_top
                   } else {
                       set tcdm_paddr_base $tightly_coupled_data_master_3_paddr_base
                       set tcdm_paddr_top $tightly_coupled_data_master_3_paddr_top
                   }
                   set tcd_master(paddr_base)  $tcdm_paddr_base
                   set tcd_master(paddr_top)   $tcdm_paddr_top
                } else {
                   set tcd_master(paddr_base)         [ proc_num2hex [ proc_get_lowest_start_address ${TCD_NAME}MapParam ] ]
                   set tcd_master(paddr_top)          [ proc_num2hex [ proc_get_higest_end_address ${TCD_NAME}MapParam ] ]
                }
                set tcd_master(indent)             "\t\t\t"
                append return_string "[ proc_get_avalon_master_string [ array get tcd_master ]]"
            }
        }
    }

    foreach i {0 1 2 3} {
        set TCI_INTF_NAME "${TCI_INTF_PREFIX}${i}"
        set TCI_NAME "${TCI_PREFIX}${i}"
        set tcim_address_base [ proc_num2hex [ proc_get_lowest_start_address ${TCI_NAME}MapParam ] ]
        if { [ expr { $tcim_address_base != "[ proc_num2hex "-1" ]" } ] || $master_addr_map } {
            if { $i < $tcim_num } {
                set tci_master(name)               $TCI_INTF_NAME
                set tci_master(type)               "instruction"
                set tci_master(access_type)        "tcm"
                if { $master_addr_map } {
                   if { $i == 0 } {
                       set tcim_paddr_base $tightly_coupled_instruction_master_0_paddr_base
                       set tcim_paddr_top $tightly_coupled_instruction_master_0_paddr_top
                   } elseif { $i == 1 } {
                       set tcim_paddr_base $tightly_coupled_instruction_master_1_paddr_base
                       set tcim_paddr_top $tightly_coupled_instruction_master_1_paddr_top
                   } elseif { $i == 2 } {
                       set tcim_paddr_base $tightly_coupled_instruction_master_2_paddr_base
                       set tcim_paddr_top $tightly_coupled_instruction_master_2_paddr_top
                   } else {
                       set tcim_paddr_base $tightly_coupled_instruction_master_3_paddr_base
                       set tcim_paddr_top $tightly_coupled_instruction_master_3_paddr_top
                   }
                   set tci_master(paddr_base)  $tcim_paddr_base
                   set tci_master(paddr_top)   $tcim_paddr_top
                } else {
                   set tci_master(paddr_base)         [ proc_num2hex [ proc_get_lowest_start_address ${TCI_NAME}MapParam ] ]
                   set tci_master(paddr_top)          [ proc_num2hex [ proc_get_higest_end_address ${TCI_NAME}MapParam ] ]
                }
                set tci_master(indent)             "\t\t\t"
                append return_string "[ proc_get_avalon_master_string [ array get tci_master ]]"
            }
        }
    }
    
    set ihp_width [ get_parameter_value ${IHP_PREFIX}AddrWidth ]
    if { $ihp_width > 1 } {
        set ihp_master(name)               $IHP_INTF_PREFIX
        set ihp_master(type)               "instruction"
        set ihp_master(access_type)        "highperformance"
        if { $master_addr_map } {
            set ihp_master(paddr_base)         [ proc_num2hex $instruction_master_high_performance_paddr_base ]
            set ihp_master(paddr_top)          [ proc_num2hex $instruction_master_high_performance_paddr_top  ]
        } else {
            set ihp_master(paddr_base)         [ proc_num2hex [ proc_get_lowest_start_address ${IHP_PREFIX}MapParam ] ]
            set ihp_master(paddr_top)          [ proc_num2hex [ proc_get_higest_end_address ${IHP_PREFIX}MapParam ] ]
        }
        set ihp_master(indent)             "\t\t\t"
        append return_string "[ proc_get_avalon_master_string [ array get ihp_master ]]"
    }

    set dhp_width [ get_parameter_value ${DHP_PREFIX}AddrWidth ]
    if { $dhp_width > 1 } {
        set dhp_master(name)               $DHP_INTF_PREFIX
        set dhp_master(type)               "data"
        set dhp_master(access_type)        "highperformance"
        if { $master_addr_map } {
            set dhp_master(paddr_base)         [ proc_num2hex $data_master_high_performance_paddr_base ]
            set dhp_master(paddr_top)          [ proc_num2hex $data_master_high_performance_paddr_top  ]
        } else {
            set dhp_master(paddr_base)         [ proc_num2hex [ proc_get_lowest_start_address ${DHP_PREFIX}MapParam ] ]
            set dhp_master(paddr_top)          [ proc_num2hex [ proc_get_higest_end_address ${DHP_PREFIX}MapParam ] ]
        }
        set dhp_master(indent)             "\t\t\t"
        append return_string "[ proc_get_avalon_master_string [ array get dhp_master ]]"
    }

        append return_string "\t\t},\n"
    append return_string "\t},\n"
    return "$return_string"
}

proc proc_get_avalon_slaves_string {AVALON_SLAVE} {
    array set avalon_slave $AVALON_SLAVE
    set indent "$avalon_slave(indent)"
    set avalon_slave_start  [ proc_num2hex $avalon_slave(start) ]
    set avalon_slave_end    [ proc_num2hex [ expr { $avalon_slave(end) - 1 } ] ]
    
    # Replace "." with "/". Eg. cpu_0.debug_mem_slave to cpu_0/debug_mem_slave to conform with system ptf
    # else quartus/sopc_builder/bin/europa/e_signal.pm will complaint "is no good for a signal"
    set avalon_slave_name [string map {. /} "$avalon_slave(name)"]
    
    set return_string {}
    
    append return_string "${indent}\"$avalon_slave_name\" => {\n"
    append return_string "${indent}\tbase => $avalon_slave_start,\n"
    append return_string "${indent}\tend => $avalon_slave_end,\n"

    # TODO: solve readonly according to nios2_ptf_utils.pm sub is_slave_readonly
    append return_string "${indent}\treadonly => 0,\n"
    append return_string "${indent}},\n"
    return "$return_string"
}

proc proc_get_custom_inst_slaves_string {CUSTOM_SLAVE} {
    array set custom_slave $CUSTOM_SLAVE
    set indent "$custom_slave(indent)"
    set custom_slave_name   $custom_slave(name)
    set custom_slave_type  $custom_slave(clockCycleType)
    set custom_slave_start  [ proc_num2hex $custom_slave(baseAddress) ]
    set custom_slave_span  $custom_slave(addressSpan)
    set custom_slave_width [ proc_span2width $custom_slave_span ]
    
    if { "$custom_slave_type" == "COMBINATORIAL" } {
        set custom_slave_type_europa "combo"
    } elseif { [ expr { "$custom_slave_type" == "VARIABLE" } || { "$custom_slave_type" == "MULTICYCLE" } ] } {
        set custom_slave_type_europa "multi"
    } else {
        set custom_slave_type_europa "$custom_slave_type"
    }
    
    set return_string {}
    
    append return_string "${indent}\"$custom_slave_name\" => {\n"
    append return_string "${indent}\ttype => $custom_slave_type_europa,\n"
    append return_string "${indent}\taddr_base => $custom_slave_start,\n"
    append return_string "${indent}\taddr_width => $custom_slave_width,\n"
    append return_string "${indent}},\n"
    return "$return_string"
}

proc proc_get_custom_inst_info_string {} {
    
    set ci_info_string ""
    set ci_ori [ proc_decode_address_map customInstSlavesSystemInfo ]
    set custom_inst_slave [ proc_decode_ci_slave $ci_ori ]
    
    #TODO: Remove this when hack get fixed
    if {[string match *name* $custom_inst_slave]} {
        foreach custom_slave $custom_inst_slave {
            array set custom_slave_info $custom_slave
            set custom_slave_info(indent)      "\t\t\t"
            append ci_info_string  [ proc_get_custom_inst_slaves_string [ array get custom_slave_info ] ]
        }
    
        set return_string ""
        append return_string "\tcustom_inst_info => {\n"
            append return_string "\t\tcustom_instructions => {\n"
            append return_string "$ci_info_string"
            append return_string "\t\t},\n"
        append return_string "\t},\n"
        return "$return_string"   
    }
}

proc proc_get_shift_rot_impl {} {
    set hardware_shift [ get_parameter_value shifterType ]
    set impl [ get_parameter_value impl ]
    if { "$impl" == "Tiny" } {
        return "small_le_shift"
    } elseif { "$impl" == "Small" } {
        return "fast_le_shift"
    }

    return $hardware_shift
}

proc proc_get_hardware_multiply_impl {} {
    set mul_set "[ get_parameter_value multiplierType ]"
    set stratix_dspblock_shift_mul [ proc_dspblock_shift_mul_valid ]
    set impl [ get_parameter_value impl ]
    if { "$impl" != "Fast" } {
        return "no_mul"
    }
    
    if { $stratix_dspblock_shift_mul } {
        return "mul_fast64_dsp"   
    }
    return $mul_set
}

proc proc_get_hardware_divide_impl {} {
    set div_set "[ get_parameter_value dividerType ]"
    set impl [ get_parameter_value impl ]
    if { "$impl" != "Fast" } {
        return "no_div"
    }
    return $div_set
}

proc proc_get_setting_shadowRegisterSets {} {
    set num_shadow_reg_sets [get_parameter_value setting_shadowRegisterSets]
    set impl [get_parameter_value impl]
    if { "$impl" != "Tiny" } {
        return $num_shadow_reg_sets
    } else {
        return 0
    }
}

proc proc_get_misc_info_string {} {
    set return_string ""
    set user_defined_settings ""
    set impl [ string tolower [ get_parameter_value impl ]]
    set userDefinedSettings [ get_parameter_value userDefinedSettings ]

    foreach each_user_setting [ split $userDefinedSettings ";" ] {
        regsub -all " " "$each_user_setting" "" each_user_setting
        regsub -all "=" "$each_user_setting" " => " each_user_setting
        if { "$each_user_setting" != "" } {
            append user_defined_settings "\t\t${each_user_setting},\n"
        }
    }

    append return_string "\tmisc_info => {\n"
        append return_string "\t\tbig_endian => [ proc_get_boolean_parameter setting_bigEndian ],\n"
        # Support the export PCB via a single option/parameter, drive this to 0
        append return_string "\t\texport_pcb => 0,\n"
        append return_string "\t\texport_pcbdebuginfo => [ proc_get_boolean_parameter setting_exportdebuginfo ],\n"
        append return_string "\t\tshift_rot_impl => [ proc_get_shift_rot_impl ],\n"
        append return_string "\t\tbmx_present => [ proc_get_bmx_present ],\n"
        append return_string "\t\tcdx_present => [ proc_get_cdx_present ],\n"
        append return_string "\t\tmpx_present => [ proc_get_mpx_present ],\n"
        append return_string "\t\tnum_shadow_reg_sets => [ proc_get_setting_shadowRegisterSets],\n"
        append return_string "\t\texport_large_RAMs => [ proc_get_boolean_parameter setting_export_large_RAMs ],\n"
        append return_string "\t\texport_vectors => [ proc_get_boolean_parameter setting_exportvectors ],\n"
        append return_string "\t\tuse_designware => [ proc_get_boolean_parameter setting_usedesignware ],\n"
        append return_string "\t\tcore_type => $impl,\n"
        append return_string "\t\tcpu_arch_rev => [ get_parameter_value cpuArchRev ],\n"
        append return_string "\t\tCPU_Implementation =>$impl ,\n"
        append return_string "\t\tcpuid_value => [ proc_num2unsigned [ get_parameter_value cpuID ]],\n"
        append return_string "\t\tdont_overwrite_cpuid => 1,\n"
        append return_string "\t\tcpu_reset => [ proc_get_boolean_parameter cpuReset],\n"
        append return_string "\t\tregister_file_ram_type => [proc_get_europa_ram_block_type_param regfile_ramBlockType],\n"
        append return_string "\t\tregister_file_por => [ proc_get_boolean_parameter register_file_por],\n"
        append return_string "$user_defined_settings"
        append return_string ""
    append return_string "\t},\n"
    return "$return_string"
}

#checked generatePTF
proc proc_get_ecc_info_string {} {
    set return_string ""
    set impl [ string tolower [ get_parameter_value impl ]]

    if {$impl != "small"} {
        set ecc_present [ proc_get_boolean_parameter setting_ecc_present ]
        set rf_ecc_present [ proc_get_boolean_parameter setting_rf_ecc_present ]
        if {$impl == "fast"} {    
            set ic_ecc_present [ expr {[proc_get_boolean_parameter setting_ic_ecc_present]} && {[get_parameter_value icache_size] > 0} ]
            set dc_ecc_present [ expr {[proc_get_boolean_parameter setting_dc_ecc_present]} && {[get_parameter_value dcache_size] > 0} ]
            set itcm_ecc_present [ expr {[proc_get_boolean_parameter setting_itcm_ecc_present]} && {[get_parameter_value icache_numTCIM] > 0} ]
            set dtcm_ecc_present [ expr {[proc_get_boolean_parameter setting_dtcm_ecc_present]} && {[get_parameter_value dcache_numTCDM] > 0} ]
            set mmu_ecc_present [ expr {[proc_get_boolean_parameter setting_mmu_ecc_present]} && [proc_get_mmu_present] ]
        } else {
            set ic_ecc_present 0
            set dc_ecc_present 0
            set itcm_ecc_present 0
            set dtcm_ecc_present 0
            set mmu_ecc_present 0
        }
    } else {
        set ecc_present 0
        set rf_ecc_present 0
        set ic_ecc_present 0
        set dc_ecc_present 0
        set itcm_ecc_present 0
        set dtcm_ecc_present 0
        set mmu_ecc_present 0
    }
    
    append return_string "\tecc_info => {\n"
        append return_string "\t\tecc_present => $ecc_present,\n"
        append return_string "\t\trf_ecc_present   => $rf_ecc_present,\n"
        append return_string "\t\tic_ecc_present   => $ic_ecc_present,\n"
        append return_string "\t\tdc_ecc_present   => $dc_ecc_present,\n"
        append return_string "\t\titcm_ecc_present => $itcm_ecc_present,\n"
        append return_string "\t\tdtcm_ecc_present => $dtcm_ecc_present,\n"
        append return_string "\t\tmmu_ecc_present  => $mmu_ecc_present,\n"
    append return_string "\t},\n"
    return "$return_string"
}

#checked generatePTF
proc proc_get_mpu_info_string {} {
    set return_string ""
    set mpu_present [ proc_get_mpu_present ]
    if { $mpu_present } {
        set mpu_num_inst_regions [ proc_num2unsigned [ get_parameter_value mpu_numOfInstRegion]]
        set mpu_num_data_regions [ proc_num2unsigned [ get_parameter_value mpu_numOfDataRegion]]
        set mpu_min_inst_region_size_log2 [ get_parameter_value mpu_minInstRegionSize]
        set mpu_min_data_region_size_log2 [ get_parameter_value mpu_minDataRegionSize]
        set mpu_use_limit [proc_get_boolean_parameter mpu_useLimit]
    } else {
        set mpu_num_inst_regions 8
        set mpu_num_data_regions 8
        set mpu_min_inst_region_size_log2 12
        set mpu_min_data_region_size_log2 12
        set mpu_use_limit 0
    }
    append return_string "\tmpu_info => {\n"
        append return_string "\t\tmpu_present => $mpu_present,\n"
        append return_string "\t\tmpu_num_inst_regions => $mpu_num_inst_regions,\n"
        append return_string "\t\tmpu_num_data_regions => $mpu_num_data_regions,\n"
        append return_string "\t\tmpu_min_inst_region_size_log2 => $mpu_min_inst_region_size_log2,\n"
        append return_string "\t\tmpu_min_data_region_size_log2 => $mpu_min_data_region_size_log2,\n"
        append return_string "\t\tmpu_use_limit => $mpu_use_limit,\n"
    append return_string "\t},\n"
    return "$return_string"
}

#checked generatePTF
proc proc_get_mmu_info_string {} {
    set return_string ""
    set mmu_present [ proc_get_mmu_present ]

    if { $mmu_present } {
        set process_id_num_bits [get_parameter_value mmu_processIDNumBits]
        set tlb_ptr_sz [ proc_get_final_tlb_ptr_size ]
        set tlb_num_ways [get_parameter_value mmu_tlbNumWays]
        set udtlb_num_entries [get_parameter_value mmu_udtlbNumEntries]
        set uitlb_num_entries [get_parameter_value mmu_uitlbNumEntries]
    } else {
        set process_id_num_bits 0
        set tlb_ptr_sz 7
        set tlb_num_ways 16
        set udtlb_num_entries 6
        set uitlb_num_entries 4
    }

    append return_string "\tmmu_info => {\n"
        append return_string "\t\tmmu_present => $mmu_present,\n"
        append return_string "\t\tprocess_id_num_bits => $process_id_num_bits,\n"
        append return_string "\t\ttlb_ptr_sz => $tlb_ptr_sz,\n"
        append return_string "\t\ttlb_num_ways => $tlb_num_ways,\n"
        append return_string "\t\tudtlb_num_entries => $udtlb_num_entries,\n"
        append return_string "\t\tuitlb_num_entries => $uitlb_num_entries,\n"
        append return_string "\t\tmmu_ram_type => [proc_get_europa_ram_block_type_param mmu_ramBlockType],\n"
    append return_string "\t},\n"
    return "$return_string"
}

#checked generatePTF
proc proc_get_interrupt_info_string {} {
    set return_string ""
    append return_string "\tinterrupt_info => {\n"
        append return_string "\t\teic_present => [ proc_get_eic_present ],\n"
        append return_string "\t\tinternal_irq_mask => [ get_parameter_value internalIrqMaskSystemInfo ],\n"
    append return_string "\t},\n"
    return "$return_string"
}

#checked generatePTF
proc proc_get_vector_info_string {} {
    set return_string ""

    append return_string "\tvector_info => {\n"
        append return_string "\t\treset_addr => [ proc_num2hex [ proc_get_reset_addr ] ],\n"
        append return_string "\t\tgeneral_exception_addr => [ proc_num2hex [ proc_get_general_exception_addr ] ],\n"
        append return_string "\t\tfast_tlb_miss_exception_addr => [ proc_num2hex [ proc_get_fast_tlb_miss_exception_addr ] ],\n"
        append return_string "\t\tbreak_addr => [ proc_num2hex [ proc_get_break_addr ] ],\n"
    append return_string "\t},\n"
    return "$return_string"
}

proc proc_get_project_info_string {} {
    set return_string ""

    set device_family_string [ string toupper "[ get_parameter_value deviceFamilyName ]" ]
    regsub -all " " "$device_family_string" "" device_family_string

    set local_asic_enabled  [ proc_get_boolean_parameter setting_asic_enabled ]
    set local_translate_on  [ get_parameter_value translate_on ]
    set local_translate_off [ get_parameter_value translate_off ]

    append return_string "\tproject_info => {\n"
        append return_string "\t\tclock_frequency        => [ get_parameter_value clockFrequency ],\n"
        append return_string "\t\tdevice_family          => $device_family_string,\n"
        append return_string "\t\thw_tcl_core            => 1,\n"
        append return_string "\t\tis_hardcopy_compatible => [ proc_bool2int [ proc_get_boolean_parameter setting_removeRAMinit ] ],\n"
        append return_string "\t\tasic_enabled           => $local_asic_enabled,\n"
        append return_string "\t\tasic_third_party_synthesis           => [ proc_get_boolean_parameter setting_asic_third_party_synthesis ],\n"
        append return_string "\t\ttranslate_off          => $local_translate_off,\n"
        append return_string "\t\ttranslate_on           => $local_translate_on,\n"
        append return_string "\t\tasic_add_scan_mode_input   => [ proc_get_boolean_parameter setting_asic_add_scan_mode_input ],\n"
    append return_string "\t},\n"
    return "$return_string"
}

proc proc_get_hardware_multiply_omits_msw {} {
    set hardware_multiplier "[ proc_get_hardware_multiply_impl ]"
    if { "$hardware_multiplier" == "mul_fast64" || "$hardware_multiplier" == "mul_fast64_dsp" } {
        return 0
    } else {
        return 1
    }
}

proc proc_get_multiply_info_string {} {
    set return_string ""
    append return_string "\tmultiply_info => {\n"
        append return_string "\t\thardware_multiply_present => [ proc_get_hardware_multiply_present ],\n"
        append return_string "\t\thardware_multiply_omits_msw => [proc_get_hardware_multiply_omits_msw],\n"
        append return_string "\t\thardware_multiply_impl => [ proc_get_hardware_multiply_impl ],\n"
    append return_string "\t},\n"
    return "$return_string"
}

proc proc_get_divide_info_string {} {
    set return_string ""
    append return_string "\tdivide_info => {\n"
        append return_string "\t\thardware_divide_present => [proc_get_hardware_divide_present],\n"
        append return_string "\t\thardware_divide_impl => [ proc_get_hardware_divide_impl ],\n"
    append return_string "\t},\n"
    return "$return_string"
}

proc proc_get_test_info_string {} {
    set ecc_present [ proc_get_boolean_parameter setting_ecc_present ]
    set impl [ string tolower [ get_parameter_value impl ]]
    if { "$impl" != "small" && $ecc_present } {
        set ecc_sim_test_ports [proc_get_boolean_parameter setting_ecc_sim_test_ports]
    } else {
        set ecc_sim_test_ports 0
    }

    set return_string ""
    set local_allow_break_inst [proc_get_boolean_parameter setting_allow_break_inst]
    set debug_level [ proc_get_boolean_parameter debug_enabled ]
    # Only allow break instruction when it is Nodebug, else should be always 0
    if { $debug_level } {
        set local_allow_break_inst 0
    }
    
    set tracefilename [get_parameter_value tracefilename]
    if { "X_$tracefilename" == "X_" } {
        set tracefilename ""
    }

    append return_string "\ttest_info => {\n"
        append return_string "\t\tdisableocitrace => [proc_get_boolean_parameter setting_disableocitrace],\n"
        append return_string "\t\tactivate_monitors => [proc_get_boolean_parameter setting_activateMonitors],\n"
        append return_string "\t\tactivate_trace_gui => [proc_get_boolean_parameter setting_activateTrace],\n"
        append return_string "\t\tactivate_test_end_checker_gui => [proc_get_boolean_parameter setting_activateTestEndChecker],\n"
        append return_string "\t\tactivate_ecc_sim_test_ports => $ecc_sim_test_ports,\n"
        append return_string "\t\talways_encrypt => [proc_get_boolean_parameter setting_alwaysEncrypt],\n"
        append return_string "\t\tbit_31_bypass_dcache => [proc_get_boolean_parameter setting_bit31BypassDCache],\n"
        append return_string "\t\tclear_x_bits_ld_non_bypass => [proc_get_boolean_parameter setting_clearXBitsLDNonBypass],\n"
        append return_string "\t\tdebug_simgen => 0,\n"
        append return_string "\t\thbreak_test => [proc_get_boolean_parameter setting_HBreakTest],\n"
        append return_string "\t\thdl_sim_caches_cleared => [proc_get_boolean_parameter setting_HDLSimCachesCleared],\n"
        append return_string "\t\tperformance_counters_present => 0,\n"
        append return_string "\t\tperformance_counters_width => 0,\n"
        append return_string "\t\tallow_break_inst => $local_allow_break_inst,\n"
        append return_string "\t\ttrace_file_name => \"$tracefilename\",\n"
    append return_string "\t},\n"
    return "$return_string"
}

proc proc_get_brpred_info_string {} {
    set return_string ""
    set impl [ get_parameter_value impl ]

    set setting_branchPredictionType    [ get_parameter_value setting_branchPredictionType ]
    set setting_bhtPtrSz                [ get_parameter_value setting_bhtPtrSz ]

    # For tiny/small it is always static branch prediction - deterministic
    # Branch prediction is only for fast core
    if { [ expr { "$impl" != "Fast" } ] } {
        set brpred_type "Static"
        set brpred_size 8
        set brpred_pc_only 0
    } else {
        set brpred_type     $setting_branchPredictionType
        set brpred_size     $setting_bhtPtrSz
    }


    append return_string "\tbrpred_info => {\n"
        append return_string "\t\tbranch_prediction_type => $brpred_type,\n"
        append return_string "\t\tbht_ptr_sz => $brpred_size,\n"
        append return_string "\t\tbht_index_pc_only => 0,\n"
        append return_string "\t\tbht_ram_type => [proc_get_europa_ram_block_type_param bht_ramBlockType],\n"
    append return_string "\t},\n"
    return "$return_string"
}

proc proc_get_exception_info_string {} {
    # Extra exception info is not available for Tiny core, always on for others
    set return_string ""
    append return_string "\texception_info => {\n"
        append return_string "\t\tillegal_mem_exc => [ proc_get_europa_illegal_mem_exc ],\n"
        append return_string "\t\textra_exc_info => [ proc_not_tiny_core_info ],\n"
    append return_string "\t},\n"
    return "$return_string"
}

proc proc_get_device_info_string {} {
    set ecc_present [ proc_get_boolean_parameter setting_ecc_present ]
    set impl [ string tolower [ get_parameter_value impl ]]
    if { "$impl" != "tiny" && $ecc_present } {
        set mrams_present 0
    } else {
        set mrams_present [is_device_feature_exist MRAM_MEMORY]
    }
    set return_string ""
    append return_string "\tdevice_info => {\n"
        append return_string "\t\taddress_stall_present => [is_device_feature_exist ADDRESS_STALL],\n"
        append return_string "\t\tmrams_present => $mrams_present,\n"
    append return_string "\t},\n"
    return "$return_string"
}

proc proc_get_europa_ram_block_type_param {param} {
    set model_ram_type [get_parameter_value $param]
    if { "$model_ram_type" == "Automatic" } {
        return "AUTO"
    } elseif { "$model_ram_type" == "MRam" } {
        return "M-RAM"
    } else {
        return $model_ram_type
    }
}


proc proc_get_dcache_info_string {} {
    set return_string ""
    set dcache_size_derived [get_parameter_value dcache_size_derived]
    set impl [get_parameter_value impl]
    append return_string "\tdcache_info => {\n"
    if { "$dcache_size_derived" == "0" || "$impl" != "Fast" } {
        append return_string "\t\tcache_has_dcache => 0,\n"
        append return_string "\t\tcache_dcache_size => 0,\n"
        append return_string "\t\tcache_dcache_line_size => 0,\n"
        append return_string "\t\tcache_dcache_bursts => 0,\n"
        append return_string "\t\tcache_dcache_tag_ram_block_type => AUTO,\n"
        append return_string "\t\tcache_dcache_ram_block_type => AUTO,\n"
        append return_string "\t\tcache_dcache_victim_buf_impl => Registers,\n"
        append return_string "\t\tioregion_dcache => 0,\n"
        append return_string "\t\tioregion_base_dcache => 4096,\n"
        append return_string "\t\tioregion_size_dcache => 4096,\n"
    } else {
        append return_string "\t\tcache_has_dcache => 1,\n"
        append return_string "\t\tcache_dcache_size => [get_parameter_value dcache_size_derived],\n"
        append return_string "\t\tcache_dcache_line_size => [get_parameter_value dcache_lineSize_derived],\n"
        append return_string "\t\tcache_dcache_bursts => [proc_get_boolean_parameter dcache_bursts_derived],\n"
        append return_string "\t\tcache_dcache_tag_ram_block_type => [proc_get_europa_ram_block_type_param dcache_tagramBlockType],\n"
        append return_string "\t\tcache_dcache_ram_block_type => [proc_get_europa_ram_block_type_param dcache_ramBlockType],\n"
        append return_string "\t\tcache_dcache_victim_buf_impl => [get_parameter_value dcache_victim_buf_impl],\n"
        append return_string "\t\tioregion_dcache => [proc_get_boolean_parameter setting_ioregionBypassDCache],\n"
        append return_string "\t\tioregion_base_dcache => [proc_num2unsigned [get_parameter_value io_regionbase]],\n"
        append return_string "\t\tioregion_size_dcache => [proc_num2unsigned [get_parameter_value io_regionsize]],\n"
    }
    append return_string "\t},\n"
    return "$return_string"
}


proc proc_get_icache_info_string {} {
    set return_string ""
    set icache_size [get_parameter_value icache_size]
    set impl [get_parameter_value impl]
    set burst_type [ get_parameter_value icache_burstType ]
    set icache_burst [ expr {"$burst_type" != "None"} ]

    append return_string "\ticache_info => {\n"
    if { "$icache_size" == "0" || "$impl" != "Fast" } {
        append return_string "\t\tcache_has_icache => 0,\n"
        append return_string "\t\tcache_icache_size => 0,\n"
        append return_string "\t\tcache_icache_line_size => 0,\n"
        append return_string "\t\tcache_icache_burst_type => none,\n"
        append return_string "\t\tcache_icache_bursts => 0,\n"
        append return_string "\t\tcache_icache_tag_ram_block_type => AUTO,\n"
        append return_string "\t\tcache_icache_ram_block_type => AUTO,\n"
    } else {
        append return_string "\t\tcache_has_icache => 1,\n"
        append return_string "\t\tcache_icache_size => $icache_size,\n"
        append return_string "\t\tcache_icache_line_size => 32,\n"
        append return_string "\t\tcache_icache_burst_type => [ string tolower $burst_type ],\n"
        append return_string "\t\tcache_icache_bursts => $icache_burst,\n"
        append return_string "\t\tcache_icache_tag_ram_block_type => [proc_get_europa_ram_block_type_param icache_tagramBlockType],\n"
        append return_string "\t\tcache_icache_ram_block_type => [proc_get_europa_ram_block_type_param icache_ramBlockType],\n"
    }
    append return_string "\t},\n"
    return "$return_string"
}

proc proc_get_fa_info_string {} {
    set return_string ""
    set fa_cache_line [get_parameter_value fa_cache_line]
    set fa_cache_linesize [get_parameter_value fa_cache_linesize]
    set impl [get_parameter_value impl]
    set mmu_enabled [ proc_get_mmu_present ]

    append return_string "\tfa_info => {\n"
    if { "$fa_cache_linesize" == "0" || "$impl" != "Fast" || $mmu_enabled } {
        append return_string "\t\tfa_present => 0,\n"
        append return_string "\t\tfa_cache_line => 0,\n"
        append return_string "\t\tfa_cache_line_size => 0,\n"
    } else {
        append return_string "\t\tfa_present => 1,\n"
        append return_string "\t\tfa_cache_line => $fa_cache_line,\n"
        append return_string "\t\tfa_cache_line_size => $fa_cache_linesize,\n"
    }
    append return_string "\t},\n"
    return "$return_string"
}

proc proc_get_debug_info_string {} {
    set return_string ""
    append return_string "\tdebug_info => {\n"

    set debug_level "[ proc_get_boolean_parameter debug_enabled ]"
    set impl         [ get_parameter_value impl ]
    set oci_trace_addr_width [ proc_get_oci_trace_addr_width ]
    set oci_export_jtag_signals [ proc_get_boolean_parameter setting_oci_export_jtag_signals ]
    set debug_onchiptrace [ proc_get_boolean_parameter debug_onchiptrace ]
    set debug_offchiptrace [ proc_get_boolean_parameter debug_offchiptrace ]
    set debug_insttrace [ proc_get_boolean_parameter debug_insttrace ]
    set debug_datatrace [ proc_get_boolean_parameter debug_datatrace ]
    set debug_hwbreakpoint [ get_parameter_value debug_hwbreakpoint ]
    set debug_datatrigger [ get_parameter_value debug_datatrigger ]
    
    set dbrk_pairs [ expr { $debug_datatrigger > 0 }  ]
    if { $debug_level } {
        # Tiny Core always have debug level 1
        if { "$impl" == "Tiny" } {
            append return_string "\t\tinclude_oci => 1,\n"
            append return_string "\t\toci_num_xbrk => 0,\n"
            append return_string "\t\toci_num_dbrk => 0,\n"
            append return_string "\t\toci_data_trace => 0,\n"
            append return_string "\t\toci_dbrk_trace => 0,\n"
            append return_string "\t\toci_onchip_trace => 0,\n"
            append return_string "\t\toci_offchip_trace => 0,\n"
            append return_string "\t\toci_dbrk_pairs => 0,\n"
            
            append return_string "\t\tinclude_third_party_debug_port => 0,\n"
            append return_string "\t\toci_trace_addr_width => 7,\n"
            append return_string "\t\toci_export_jtag_signals => $oci_export_jtag_signals,\n"
            append return_string "\t\toci_mem_ram_type => [proc_get_europa_ram_block_type_param ocimem_ramBlockType],\n"
            append return_string "\t\toci_mem_ram_init => [proc_get_boolean_parameter ocimem_ramInit],\n"
        } else {
            append return_string "\t\tinclude_oci => 1,\n"
            # Hardware breakpoints
            # data triggers
            # Same options 0,2,4
            append return_string "\t\toci_num_xbrk => $debug_hwbreakpoint,\n"
            append return_string "\t\toci_num_dbrk => $debug_datatrigger,\n"
            # trace type - instruction trace or data trace           
            append return_string "\t\toci_dbrk_trace => $debug_insttrace,\n"
            append return_string "\t\toci_data_trace => $debug_datatrace,\n"
            # trace storage
            append return_string "\t\toci_onchip_trace => $debug_onchiptrace,\n"
            append return_string "\t\toci_offchip_trace => $debug_offchiptrace,\n"           
            # no of num_xbrk and dbrk > 0
            append return_string "\t\toci_dbrk_pairs => $dbrk_pairs,\n"
            append return_string "\t\tinclude_third_party_debug_port => 0,\n"
            append return_string "\t\toci_trace_addr_width => $oci_trace_addr_width,\n"
            append return_string "\t\toci_export_jtag_signals => $oci_export_jtag_signals,\n"
            append return_string "\t\toci_mem_ram_type => [proc_get_europa_ram_block_type_param ocimem_ramBlockType],\n"
            append return_string "\t\toci_mem_ram_init => [proc_get_boolean_parameter ocimem_ramInit],\n"
        }
    } else {
       append return_string "\t\tinclude_oci => 0,\n"
       append return_string "\t\toci_num_xbrk => 0,\n"
       append return_string "\t\toci_num_dbrk => 0,\n"
       append return_string "\t\toci_dbrk_trace => 0,\n"
       append return_string "\t\toci_dbrk_pairs => 0,\n"
       append return_string "\t\toci_onchip_trace => 0,\n"
       append return_string "\t\toci_offchip_trace => 0,\n"
       append return_string "\t\toci_data_trace => 0,\n"
       append return_string "\t\tinclude_third_party_debug_port => 0,\n"
       append return_string "\t\toci_trace_addr_width => 7,\n"
       append return_string "\t\toci_export_jtag_signals => 0,\n"
       append return_string "\t\toci_mem_ram_type => AUTO,\n"   
       append return_string "\t\toci_mem_ram_init => 0,\n"
    }

        set auto_assign [proc_get_boolean_parameter debug_assignJtagInstanceID]
        set user_jtag_inst_id [get_parameter_value debug_jtagInstanceID]
        if { !$auto_assign } {
            # sld_virtual_jtag Megafunction documentation tell me that this will be ignored if enable auto assign
            set virtual_jtag_instance_id  0
        } else {
            set virtual_jtag_instance_id $user_jtag_inst_id
        }
        
        # Avalon Debug Port present only available when debug level is at least 1 but java models allows it (bug).
        if { $debug_level } {
            set avalonDebugPortPresent [proc_get_boolean_parameter setting_avalonDebugPortPresent]
        } else {
            set avalonDebugPortPresent 0
        }
 	
        
        append return_string "\t\tavalon_debug_port_present => $avalonDebugPortPresent,\n"
        append return_string "\t\toci_sync_depth => 2,\n"
        append return_string "\t\toci_num_pm => 0,\n"
        append return_string "\t\toci_pm_width => 32,\n"
        append return_string "\t\toci_debugreq_signals => [proc_get_boolean_parameter debug_debugReqSignals],\n"
        append return_string "\t\toci_trigger_arming => [proc_get_boolean_parameter debug_triggerArming],\n"
        append return_string "\t\toci_virtual_jtag_instance_id => $virtual_jtag_instance_id,\n"
        append return_string "\t\toci_jtag_instance_id => $virtual_jtag_instance_id,\n"
        append return_string "\t\toci_assign_jtag_instance_id => $auto_assign,\n"
        append return_string "\t\toci_version => [ get_parameter_value setting_oci_version],\n"
        append return_string "\t\toci_fast_reg_rd => [ proc_get_boolean_parameter setting_fast_register_read],\n"
    append return_string "\t},\n"
    return "$return_string"
}

proc sub_generate_create_processor_config_file {output_name output_directory} {
    set processor_config_file "$output_directory/${output_name}_processor_configuration.pl"
    set processor_config      [open $processor_config_file "w"]

    puts $processor_config "# ${output_name} Processor Configuration File"
    puts $processor_config "return {"

    #checked generatePTF
    puts $processor_config "[ proc_get_avalon_master_info_string ]"
    puts $processor_config "[ proc_get_custom_inst_info_string ]"
    puts $processor_config "[ proc_get_misc_info_string ]"
    puts $processor_config "[ proc_get_ecc_info_string ]"
    puts $processor_config "[ proc_get_mpu_info_string ]"
    puts $processor_config "[ proc_get_mmu_info_string ]"
    puts $processor_config "[ proc_get_interrupt_info_string ]"
    puts $processor_config "[ proc_get_vector_info_string ]"
    puts $processor_config "[ proc_get_project_info_string ]"
    puts $processor_config "[ proc_get_debug_info_string ]"
    puts $processor_config "[ proc_get_icache_info_string ]"
    puts $processor_config "[ proc_get_fa_info_string ]"
    puts $processor_config "[ proc_get_dcache_info_string ]"
    puts $processor_config "[ proc_get_device_info_string ]"
    puts $processor_config "[ proc_get_multiply_info_string ]"
    puts $processor_config "[ proc_get_divide_info_string ]"
    puts $processor_config "[ proc_get_exception_info_string ]"
    puts $processor_config "[ proc_get_brpred_info_string ]"
    puts $processor_config "[ proc_get_test_info_string ]"

    puts $processor_config "};"

    close $processor_config
}

proc sub_generate_create_processor_rtl {output_name output_directory rtl_ext simgen} {
    global env
    # Directory
    set simulation_dir          "$output_directory"
    set processor_config_file   "$output_directory/${output_name}_processor_configuration.pl"
    set QUARTUS_ROOTDIR         "$env(QUARTUS_ROOTDIR)"
    set COMPONENT_DIR           "$QUARTUS_ROOTDIR/../ip/altera/nios2_ip/altera_nios2_gen2"
    set SOPC_BUILDER_BIN_DIR    "$QUARTUS_ROOTDIR/sopc_builder/bin"
    set CPU_LIB_DIR             "$COMPONENT_DIR/cpu_lib"
    set NIOS_LIB_DIR            "$COMPONENT_DIR/nios_lib"
    set EUROPA_DIR              "$SOPC_BUILDER_BIN_DIR/europa"
    set PERLLIB_DIR             "$SOPC_BUILDER_BIN_DIR/perl_lib"
    set NIOSII_GEN_MODULE_DIR   "$QUARTUS_ROOTDIR/../ip/altera/nios2_ip/altera_nios2_gen2"
    
    # Paths to normal and encypted perl scripts.
    set normal_perl_script "$COMPONENT_DIR/generate_rtl.pl"
    set eperl_script "$COMPONENT_DIR/generate_rtl.epl"
    
    # Initialize gen_output for message display
    set gen_output              ""
    set cpu_freq                [ get_parameter_value clockFrequency ]

    # Initialize plaintext to be always encrypted "0"
    set plainTEXTfound 0

    if { $rtl_ext == "vhd" } {
        set language "vhdl"
    } else {
        set language "verilog"
    }

    set PLATFORM $::tcl_platform(platform)
    if { $PLATFORM == "java" } {
        set PLATFORM $::tcl_platform(host_platform)
    }

    # Case:136864 Use quartus(binpath) if its set
    if { [catch {set QUARTUS_BINDIR $::quartus(binpath)} errmsg] } {
        if { $PLATFORM == "windows" } {
            set BINDIRNAME "bin"
        } else {
            set BINDIRNAME "linux"
        }

        # Only the native tcl interpreter has 'tcl_platform(wordSize)'
        # In Jacl however 'tcl_platform(machine)' is set to the JVM bitness, not the OS bitness
        if { [catch {set WORDSIZE $::tcl_platform(wordSize)} errmsg] } {
            if {[string match "*64" $::tcl_platform(machine)]} {
                set WORDSIZE 8
            } else {
                set WORDSIZE 4
            }
        }
        if { $WORDSIZE == 8 } {
            set BINDIRNAME "${BINDIRNAME}64"
        }

        set QUARTUS_BINDIR "$QUARTUS_ROOTDIR/$BINDIRNAME"
    }

    # Determine which perl executable and perl script to use.
    if { [ file isfile $normal_perl_script ] } {
        set perl_script $normal_perl_script
        set perl_bin "$QUARTUS_BINDIR/perl/bin/perl"

    } elseif { [ file isfile $eperl_script ] } {
        set perl_script $eperl_script
        set perl_bin "$QUARTUS_BINDIR/eperlcmd"

    } else {
        send_message error "Can't find Perl script $eperl_script used to generate RTL"
        return
    }

    if { $PLATFORM == "windows" } {
        set perl_bin "$perl_bin.exe"
    }
    if { ! [ file executable $perl_bin ] } {
        send_message error "Can't find path executable $perl_bin shipped with Quartus"
        return
    }

    # Unfortunately perl doesn't know about the path to the standard Perl include directories.
    set perl_std_libs $QUARTUS_BINDIR/perl/lib
    if { ! [ file isdirectory $perl_std_libs ] } {
        send_message error "Can't find Perl standard libraries $perl_std_libs shipped with Quartus"
        return
    }

    # Prepare command-line used to generate CPU.
    # eperl requires '--' to separate perl args from script args
    set exec_list [ list \
        exec $perl_bin \
            -I $perl_std_libs \
            -I $EUROPA_DIR \
            -I $PERLLIB_DIR \
            -I $SOPC_BUILDER_BIN_DIR \
            -I $CPU_LIB_DIR \
            -I $NIOS_LIB_DIR \
            -I $COMPONENT_DIR \
            -I $NIOSII_GEN_MODULE_DIR \
            "--" \
            $perl_script \
            --name=$output_name \
            --dir=$output_directory \
            --quartus_bindir=$QUARTUS_BINDIR \
            --$language \
            --config=$processor_config_file
    ]

    if { "$simgen" == "0" } {
        append exec_list     "  --do_build_sim=0  "
    } else {
        append exec_list     "  --do_build_sim=1  "
        append exec_list     "  --sim_dir=$output_directory  "
    }

    if ([is_software_edition QUARTUS_PRIME_PRO]) {
        append exec_list "  --pro_version=1  "
    }

    send_message Info "Starting RTL generation for module '$output_name'"
    send_message Info "  Generation command is \[$exec_list\]"
    
    if { [ catch { set gen_output [ eval $exec_list ] } errmsg ] } {
       foreach errmsg_string [ split $errmsg "\n" ] {
           send_message Info "$errmsg_string"
       }
       send_message error "Failed to generate module $output_name"
    }

    if { $gen_output != "" } {
        foreach output_string [ split $gen_output "\n" ] {
            send_message Info $output_string
        }
        set find_plaintext ""
        regexp {Creating plain-text RTL} $gen_output find_plaintext
        if { $find_plaintext == "Creating plain-text RTL" } {
            set plainTEXTfound 1
        }
    }
    send_message Info "Done RTL generation for module '$output_name'"
    return $plainTEXTfound
}

proc generate_with_plaintext {NAME rtl_ext simgen} {
    set output_directory [ create_temp_file "" ]
    
    # generate
    set plainTEXTfound [generate                "$NAME" "$output_directory" "$rtl_ext" "$simgen"]
    sub_add_generated_files "$NAME" "$output_directory" "$rtl_ext" "$simgen" "$plainTEXTfound"
}

proc sub_sim_verilog {NAME} {
    set rtl_ext "v"
    set simgen  1
    
    generate_with_plaintext "$NAME" "$rtl_ext" "$simgen"

}

proc sub_sim_vhdl {NAME} {
    set rtl_ext "vhd"
    set simgen  1
    
    generate_with_plaintext "$NAME" "$rtl_ext" "$simgen"
}

proc sub_quartus_synth {NAME} {
    set rtl_ext "v"
    set simgen  0
    
    generate_with_plaintext "$NAME" "$rtl_ext" "$simgen"
}

proc generate {output_name output_directory rtl_ext simgen} {
    sub_generate_create_processor_config_file   "$output_name" "$output_directory"
    set plainTEXTfound [sub_generate_create_processor_rtl           "$output_name" "$output_directory" "$rtl_ext" "$simgen"]
    return $plainTEXTfound
}

proc sub_add_generated_files {NAME output_directory rtl_ext simgen plainTEXTfound} {
    # add files
    set gen_files [ glob -directory ${output_directory} * ]
    set always_encrypt [ get_parameter_value setting_alwaysEncrypt ]
    set impl           [ get_parameter_value impl ]
    # For Plaintext purpose
    set plaintextfound $plainTEXTfound 
    set is_encrypt     [ expr { $always_encrypt } && { $impl != "Tiny" } && { !$plaintextfound }]

    if { "$rtl_ext" == "vhd" } {
        set language "VHDL"
        set rtl_sim_ext "vho"
    } else {
        set language "VERILOG"
        set rtl_sim_ext "vo"
    }
    
    foreach my_file $gen_files {
        # get filename
        set file_name [ file tail $my_file ]
        # add files
        if { [ string match "*.mif" "$file_name" ] } {
            add_fileset_file "$file_name" MIF PATH $my_file
        } elseif { [ string match "*.dat" "$file_name" ] } {
            add_fileset_file "$file_name" DAT PATH $my_file
        } elseif { [ string match "*.hex" "$file_name" ] } {
            add_fileset_file "$file_name" HEX PATH $my_file
        } elseif { [ string match "*.do" "$file_name" ] } {
            add_fileset_file "$file_name" OTHER PATH "$my_file"
        } elseif { [ string match "*.ocp" "$file_name" ] } {
            add_fileset_file "$file_name" OTHER PATH "$my_file"
        } elseif { [ string match "*.sdc" "$file_name" ] } {
            add_fileset_file "$file_name" SDC PATH "$my_file"
        } elseif { [ string match "*.pl" "$file_name" ] } {
            # do nothing
        } elseif { [ string match "*.${rtl_sim_ext}" "$file_name" ] } {
            if { $simgen } {
                add_fileset_file "$file_name" $language PATH "$my_file"
            }
        } elseif { [ string match "*.${rtl_ext}" "$file_name" ] } {
            # checking for encryption
            if { $is_encrypt && [ string match "${NAME}.${rtl_ext}" "$file_name" ] } {
                # only Verilog files are used for synthesis
                if { [ expr { ! $simgen } || { "$language" == "VHDL" } ] } {
                    add_fileset_file "$file_name" ${language}_ENCRYPT PATH "$my_file"
                }
            } else {
                add_fileset_file "$file_name" $language PATH "$my_file"
            }
        } else {
            add_fileset_file "$file_name" OTHER PATH "$my_file"
        }
    }
}
