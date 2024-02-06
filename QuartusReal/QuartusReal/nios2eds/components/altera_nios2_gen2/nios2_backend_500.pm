#Copyright (C) 2016 Intel Corporation. All rights reserved. 
#Any megafunction design, and related net list (encrypted or decrypted),
#support information, device programming or simulation file, and any other
#associated documentation or information provided by Intel or a partner
#under Intel's Megafunction Partnership Program may be used only to
#program PLD devices (but not masked PLD devices) from Intel.  Any other
#use of such megafunction design, net list, support information, device
#programming or simulation file, or any other related documentation or
#information is prohibited for any other purpose, including, but not
#limited to modification, reverse engineering, de-compiling, or use with
#any other silicon devices, unless such use is explicitly licensed under
#a separate agreement with Intel or a megafunction partner.  Title to
#the intellectual property, including patents, copyrights, trademarks,
#trade secrets, or maskworks, embodied in any such megafunction design,
#net list, support information, device programming or simulation file, or
#any other related documentation or information provided by Intel or a
#megafunction partner, remains with Intel, the megafunction partner, or
#their respective licensors.  No other licenses, including any licenses
#needed under any third party's intellectual property, are provided herein.
#Copying or modifying any file, or portion thereof, to which this notice
#is attached violates this copyright.






















package nios2_backend_500;
use Exporter;
@ISA = Exporter;
@EXPORT = qw(
    &nios2_be500_make_backend
    &nios2_be500_make_testbench
);

use e_custom_instruction_master;
use cpu_utils;
use cpu_wave_signals;
use cpu_control_reg;
use cpu_control_reg_gen;
use cpu_file_utils;
use cpu_gen;
use cpu_inst_gen;
use cpu_exception_gen;
use europa_all;
use europa_utils;
use e_atlantic_slave;
use nios_utils;
use nios_europa;
use nios_addr_utils;
use nios_testbench_utils;
use nios_sdp_ram;
use nios_avalon_masters;
use nios_brpred;
use nios_common;
use nios_isa;
use nios_icache;
use nios_dcache;
use nios_mul;
use nios_div;
use nios2_mmu;
use nios2_mpu;
use nios_shift_rotate;
use nios2_isa;
use nios2_insts;
use nios2_control_regs;
use nios2_exceptions;
use nios2_common;
use nios2_backend;
use nios2_custom_insts;
use nios_ecc_encoder;
use nios_ecc_decoder;

use strict;










































sub 
nios2_be500_make_backend
{
    my $Opt = shift;

    &$progress("    Pipeline backend");



    nios_brpred::gen_backend($Opt);

    make_base_pipeline($Opt);
    make_register_file($Opt);
    be_make_alu($Opt);
    be_make_stdata($Opt);
    be_make_hbreak($Opt);
    if ($cpu_reset) {
        be_make_cpu_reset($Opt);
    }
    make_reg_cmp($Opt);
    make_src_operands($Opt);
    make_alu_controls($Opt);
    if ($eic_present) {
        make_external_interrupt_controller($Opt);
    } else {
        make_internal_interrupt_controller($Opt);
    }

    if (!$hw_mul_uses_dsp_block) {
        nios_shift_rotate::gen_shift_rotate($Opt);
    }

    if ($hw_mul) {
        nios_mul::gen_mul($Opt);
    }

    if ($hw_div) {
        nios_div::gen_div($Opt);
    }

    my $dcache_stall_info;
    if ($dcache_present) {
        $dcache_stall_info = nios_dcache::gen_dcache($Opt);
    }

    if ($dtcm_present) {
        gen_dtcm_masters($Opt);
    }

    gen_data_master($Opt, $dcache_stall_info);
    gen_slow_ld_aligner($Opt);

    if ($dcache_present || $dtcm_present) {
        gen_data_ram_ld_aligner($Opt);
    } else {


        e_assign->adds(
          [["A_inst_result_aligned", $datapath_sz], "A_inst_result"],
        );
    }

    if ($mmu_present) {
        &$progress("      Micro-DTLB");
        make_tlb_data($Opt);
    } 
    
    if ($mpu_present) {
        &$progress("      DMPU");
        make_dmpu($Opt);
    }

    if (nios2_custom_insts::has_insts($Opt->{custom_instructions})) {
        make_custom_instruction_master($Opt);
    } else {
        my $is_hw_tcl_core = optional_bool($Opt, "hw_tcl_core");
        if ( $is_hw_tcl_core ) {
           
            my $ci_ports = { dummy_ci_port    => "combo_readra", };
            e_custom_instruction_master->add ({
                name     => "custom_instruction_master",
                type_map => $ci_ports,
            });
            
            e_assign->adds([["dummy_ci_port", 1], "1'b0"]);
        }
    }

    if (!manditory_bool($Opt, "simgen")) {
        make_potential_tb_logic($Opt);
    }

    be_make_control_regs($Opt);
}







sub 
nios2_be500_make_testbench
{
    my $Opt = shift;

    &$progress("    Testbench");

    my $whoami = "backend 500 testbench";

    my $submodule_name = $Opt->{name}."_test_bench";

    my $submodule = e_module->new({
      name        => $submodule_name,
      output_file => $submodule_name,
    });

    my $testbench_instance_name = "the_$submodule_name";
    my $testbench_instance = e_instance->add({
      module      => $submodule,
      name        => $testbench_instance_name,
    });

    my $marker = e_default_module_marker->new($submodule);

    my $gen_info = manditory_hash($Opt, "gen_info");

    my $cpu_arch_rev = manditory_int($Opt, "cpu_arch_rev");

    my $r1 = ($cpu_arch_rev == 1);
    my $r2 = ($cpu_arch_rev == 2);





    cpu_inst_gen::gen_inst_decodes($gen_info, $Opt->{inst_desc_info},
      ["W"]);





    e_register->adds(
      {out => ["A_target_pcb", $pcb_sz, 0, $force_never_export],
       in => "M_target_pcb",            enable => "A_en"},
      {out => ["A_mem_baddr", $mem_baddr_sz, 0, $force_never_export],
       in => "M_mem_baddr",             enable => "A_en"},
      {out => ["W_wr_data_filtered", $datapath_sz, 0, $force_never_export], 
       in => "A_wr_data_filtered",  enable => "1'b1"},
      {out => ["W_st_data", $datapath_sz, 0, $force_never_export],
       in => "A_st_data",           enable => "1'b1"},
      {out => ["W_cmp_result", 1, 0, $force_never_export],
       in => "A_cmp_result",        enable => "1'b1"},
      {out => ["W_target_pcb", $pcb_sz, 0, $force_never_export],
       in => "A_target_pcb",        enable => "1'b1"},
      );

    if ($rf_ecc_present) {
        e_register->adds(
          {out => ["W_rf_injected_wr_data", $datapath_sz, 0, 
           $force_never_export], 
           in => "A_rf_injected_wr_data",  enable => "1'b1"},
        );
    }

    my $A_hbreak_exc = $hbreak_present ? 
      get_exc_signal_name($hbreak_exc, "A") : "0";
    my $A_cpu_reset_exc = $cpu_reset ?
          get_exc_signal_name($cpu_reset_exc, "A") : "0";
    my $A_intr_exc = get_exc_signal_name(
      ($eic_present ? $ext_intr_exc : $norm_intr_exc), "A");


    e_register->adds(

      {out => ["W_valid_hbreak", 1, 0, $force_never_export],
       in => "A_exc_allowed & $A_hbreak_exc", 
       enable => "1'b1"},

      {out => ["W_valid_crst", 1, 0, $force_never_export],
           in => "A_exc_allowed & $A_cpu_reset_exc", 
           enable => "1'b1"},

      {out => ["W_valid_intr", 1, 0, $force_never_export],
       in => "A_exc_allowed & $A_intr_exc", 
       enable => "1'b1"},

      {out => ["W_exc_any_active", 1, 0, $force_never_export],
       in => "A_exc_any_active", 
       enable => "1'b1"},
    );

    e_register->adds(
      {out => ["W_exc_highest_pri_exc_id", 32, 0, $force_never_export],
       in => "A_exc_highest_pri_exc_id", 
       enable => "1'b1"},
    );

    if ($mmu_present) {

        my $inst_baddr_width = manditory_int($Opt, "i_Address_Width");
        my $data_addr_phy_sz  = manditory_int($Opt, "d_Address_Width");


        e_register->adds(
          {out => ["E_pcb_phy", $inst_baddr_width, 0, $force_never_export], 
           in => "D_pcb_phy", enable => "E_en", ip_debug_visible => 1},
          {out => ["M_pcb_phy", $inst_baddr_width, 0, $force_never_export], 
           in => "E_pcb_phy", enable => "M_en"},
          {out => ["A_pcb_phy", $inst_baddr_width, 0, $force_never_export], 
           in => "M_pcb_phy", enable => "A_en"},
          {out => ["W_pcb_phy", $inst_baddr_width, 0, $force_never_export], 
           in => "A_pcb_phy", enable => "1'b1"},
          {out => ["W_exc_fast_tlb_miss", 1, 0, $force_never_export], 
           in => "A_exc_fast_tlb_miss", enable => "1'b1"},
        );
    }

    if ($eic_present) {

        e_register->adds(
          {out => ["M_tb_eic_port_data", $eic_port_sz], 
           in => "eic_port_data", 
           enable => "M_en"},
          {out => ["A_tb_eic_port_data", $eic_port_sz], 
           in => "M_tb_eic_port_data", 
           enable => "A_en"},
          {out => ["W_tb_eic_port_data", $eic_port_sz], 
           in => "A_tb_eic_port_data", 
           enable => "W_en"},
        );


        e_assign->adds(
           [["W_tb_eic_ril", $eic_port_ril_sz], 
             "W_tb_eic_port_data[$eic_port_ril_msb:$eic_port_ril_lsb]"],
           [["W_tb_eic_rnmi", $eic_port_rnmi_sz],
             "W_tb_eic_port_data[$eic_port_rnmi_lsb]"],
           [["W_tb_eic_rrs", $eic_port_rrs_sz],
             "W_tb_eic_port_data[$eic_port_rrs_msb:$eic_port_rrs_lsb]"],
           [["W_tb_eic_rha", $eic_port_rha_sz],
             "W_tb_eic_port_data[$eic_port_rha_msb:$eic_port_rha_lsb]"],
        );
    }

    if ($eic_and_shadow) {
        e_register->adds(
          {out => ["W_tb_sstatus_reg", 32], 
           in => "W_sstatus_reg_nxt", 
           enable => "W_en"},
        );
    }








    if (manditory_bool($Opt, "simgen")) {
        make_potential_tb_logic($Opt);
    }

    my @x_signals = (
      { sig => "W_wr_dst_reg",                             },
      { sig => "W_dst_regnum", qual => "W_wr_dst_reg",     },
      { sig => "W_valid",                                  },
      { sig => "W_pcb",        qual => "W_valid",          },
      { sig => "W_iw",         qual => "W_valid",          },
      { sig => "A_en",                                     },
    );

    if ($shadow_present) {
        push(@x_signals,
          { sig => "W_dst_regset", qual => "W_wr_dst_reg", },
        );
    }

    if ($eic_present) {
        push(@x_signals,
          { sig => "eic_port_valid", },
          { sig => "eic_port_data_ril", 
            qual => "eic_port_valid" },
          { sig => "eic_port_data_rnmi", 
            qual => "eic_port_valid & (eic_port_data_ril != 0)" },
          { sig => "eic_port_data_rha", 
            qual => "eic_port_valid & (eic_port_data_ril != 0)" },
        );

        if ($shadow_present) {
            push(@x_signals,
              { sig => "eic_port_data_rrs", 
                qual => "eic_port_valid & (eic_port_data_ril != 0)" },
            );
        }
    }

    push(@x_signals,
      { sig => "M_valid",                                   },
      { sig => "A_valid",                                   },
      { sig => "A_wr_data_unfiltered",    
        qual => "A_valid & A_en & A_wr_dst_reg",
        warn => 1,                                          },
        { sig => "W_status_reg",                        },
      { sig => "W_estatus_reg",                         },
      { sig => "W_bstatus_reg",                         },
    );

    if ($exception_reg) {
        push(@x_signals,
          { sig => "W_exception_reg",                   },
        );
    }

    push(@x_signals,
      { sig => "W_badaddr_reg",                     },
    );

    if ($mmu_present) {
        push(@x_signals,
          { sig => "W_ienable_reg",                 },
          { sig => "W_pteaddr_reg",                 },
          { sig => "W_tlbacc_reg",                  },
          { sig => "W_tlbmisc_reg",                 },
        );
    } elsif ($mpu_present) {
        push(@x_signals,
          { sig => "W_config_reg",                  },
          { sig => "W_mpubase_reg",                 },
          { sig => "W_mpuacc_reg",                  },
        );
    }
    
    push(@x_signals,
      { sig => "A_exc_any_active",                      },
      { sig => "i_read",                                },
      { sig => "i_address",    qual => "i_read",        },
      { sig => "d_write",                                   },
      { sig => "d_byteenable", qual => "d_write",           },
      { sig => "d_address",    qual => "d_write | d_read",  },
      { sig => "d_read",                                    },
    );

    if ($icache_present) {
        push(@x_signals,
          { sig => "i_readdatavalid",                       },
        );
    }

    if ($dcache_present) {
        push(@x_signals,
          { sig => "d_readdatavalid",                       },
        );
    }

    for (my $cmi = 0; 
      $cmi < manditory_int($Opt, "num_tightly_coupled_data_masters"); $cmi++) {
        push(@x_signals,
          { sig => "dtcm${cmi}_write",                                },
          { sig => "dtcm${cmi}_address",    qual => "dtcm${cmi}_write", },
        );

        if (!$dtcm_ecc_present) {
            push(@x_signals,
              { sig => "dtcm${cmi}_byteenable", qual => "dtcm${cmi}_write", },
            );     
        }
    }

    if ($ecc_present) {
        push(@x_signals,
          { sig => "ecc_event_bus", },
        );
    }

    e_signal->adds(

      {name => "A_target_pcb", width => $pcb_sz},



      {name => "A_wr_data_filtered", width => $datapath_sz, 
       export => $force_export},
    );

    my $x_filter_qual = $dcache_present ? "A_ctrl_ld_non_bypass" : "A_ctrl_ld_non_io";

    if (manditory_bool($Opt, "clear_x_bits_ld_non_bypass") && 
      !manditory_bool($Opt, "asic_enabled")) {





        create_x_filter({
          lhs       => "A_wr_data_filtered",
          rhs       => "A_wr_data_unfiltered",
          sz        => $datapath_sz, 
          qual_expr => $x_filter_qual,
        });
    } else {

        e_assign->adds({
          lhs => "A_wr_data_filtered",
          rhs => "A_wr_data_unfiltered",
          comment => "Propagating 'X' data bits",
        });
    }

    if (not_empty_scalar($Opt, "branch_prediction_type") eq "Dynamic") {
        e_signal->adds(


            {name => "E_add_br_to_taken_history_filtered", width => 1, 
             export => $force_export},
        );

        e_signal->adds(


            {name => "M_bht_wr_en_filtered", width => 1, 
             export => $force_export},
            {name => "M_bht_wr_data_filtered", width => $bht_data_sz, 
             export => $force_export},
            {name => "M_bht_ptr_filtered", width => $bht_ptr_sz, 
             export => $force_export},
        );

        if (!manditory_bool($Opt, "asic_enabled")) {





            create_x_filter({
              lhs       => "E_add_br_to_taken_history_filtered",
              rhs       => "E_add_br_to_taken_history_unfiltered",
              sz        => 1,
            });
            create_x_filter({
              lhs       => "M_bht_wr_en_filtered",
              rhs       => "M_bht_wr_en_unfiltered", 
              sz        => 1,
            });
            create_x_filter({
              lhs       => "M_bht_wr_data_filtered",
              rhs       => "M_bht_wr_data_unfiltered",
              sz        => $bht_data_sz,
            });
            create_x_filter({
              lhs       => "M_bht_ptr_filtered",
              rhs       => "M_bht_ptr_unfiltered",
              sz        => $bht_ptr_sz,
            });
        } else {

            e_assign->adds({
              comment => "Propagating 'X' data bits",
              lhs => "E_add_br_to_taken_history_filtered",
              rhs => "E_add_br_to_taken_history_unfiltered",
            });
            e_assign->adds({
              comment => "Propagating 'X' data bits",
              lhs => "M_bht_wr_en_filtered",
              rhs => "M_bht_wr_en_unfiltered",
            });
            e_assign->adds({
              comment => "Propagating 'X' data bits",
              lhs => "M_bht_wr_data_filtered",
              rhs => "M_bht_wr_data_unfiltered",
            });
            e_assign->adds({
              comment => "Propagating 'X' data bits",
              lhs => "M_bht_ptr_filtered",
              rhs => "M_bht_ptr_unfiltered",
            });
        }
    }

    my $display = $NIOS_DISPLAY_INST_TRACE | $NIOS_DISPLAY_MEM_TRAFFIC;
    my $use_reg_names = "1";

    my $test_end_expr;

    if (manditory_bool($Opt, "activate_monitors")) {
        create_x_checkers(\@x_signals);
    }

    if (manditory_bool($Opt, "activate_test_end_checker")) {
        my $inst_done_expr = "W_valid";






        $test_end_expr = 
          "$inst_done_expr & (
            W_sim_reg_stop |
            (W_op_cmpltui & (W_iw_a == 0) & (W_iw_b == 0) &
              ((W_iw_imm16 == 16'habc1) | (W_iw_imm16 == 16'habc2))))";
    }

    my $pc = "W_pcb";
    my $dstRegVal = $rf_ecc_present ? 
        "W_rf_injected_wr_data" : 
        "W_wr_data_filtered";

    my $crst_active = "W_valid_crst"; 

    my $reset_entry = {
        hard_reset_expr => "~reset_n",
        cpu_only_reset_expr => $cpu_reset ? $crst_active : undef,
    };

    my $crst_active = "W_valid_crst";
    my $intr_active = "W_valid_intr";
    my $hbreak_active = "W_valid_hbreak";

    my $iw_valid_expr;
    my $stages = manditory_array($gen_info, "stages");
    my $d_stage_or_later = 0;
    
    foreach my $stage (@$stages) {
        if ($stage eq "D") {
            $d_stage_or_later = 1;
        }
    
        if ($d_stage_or_later) {








            new_exc_combo_signal({
                name                => "${stage}_exc_inst_fetch",
                stage               => $stage,
                invalidates_inst_value => 1,
            });
        }
    }
    



    e_assign->adds(
      ["A_iw_invalid", "A_exc_inst_fetch & A_exc_active_no_break_no_crst"],
    );
    
    e_register->adds(
      {out => ["W_iw_invalid", 1, 0, $force_never_export], 
       in => "A_iw_invalid",  enable => "1'b1"},
    );
    
    $iw_valid_expr = "~W_iw_invalid";

    my $dstRegEccTestPort_expr = undef;
    
    if ($rf_ecc_present && $ecc_test_ports_present) {
        e_register->adds(
          {out => ["W_ecc_test_rf", $datapath_sz, 0, $force_never_export], 
           in => "ecc_test_rf[$datapath_sz-1:0]",  enable => "1'b1"},
        );
        $dstRegEccTestPort_expr = "W_ecc_test_rf";
    }

    my $hbreak_entry = {
        condition   => "W_valid_hbreak",
        pc          => $pc,
        dstRegWr    => "W_wr_dst_reg",
        dstRegNum   => "W_dst_regnum",
        dstRegVal   => $dstRegVal,
        dstRegSet   => $shadow_present ? "W_dst_regset" : undef,
        dstRegEccTestPort => $dstRegEccTestPort_expr,
    };

    my $intr_entry = {
        condition   => "W_valid_intr",
        pc          => $pc,
        dstRegWr    => "W_wr_dst_reg",
        dstRegNum   => "W_dst_regnum",
        dstRegVal   => $dstRegVal,
        dstRegSet   => $shadow_present ? "W_dst_regset" : undef,
        dstRegEccTestPort => $dstRegEccTestPort_expr,
        wrSstatus   => $eic_and_shadow ? "W_exc_wr_sstatus" : undef,
        sstatus     => $eic_and_shadow ? "W_tb_sstatus_reg" : undef,
        ril         => $eic_present ? "W_tb_eic_ril" : undef,
        rnmi        => $eic_present ? "W_tb_eic_rnmi" : undef,
        rrs         => $eic_present ? "W_tb_eic_rrs" : undef,
        rha         => $eic_present ? "W_tb_eic_rha" : undef,
    };
    
    my $inst_entry = {
        condition   => "W_valid || W_exc_any_active",
        exc         => "W_exc_any_active ? W_exc_highest_pri_exc_id : 0",
        excHandler  => $mmu_present ? 
                         "W_exc_fast_tlb_miss ? 
                           $exc_handler_fast_tlb_miss :
                           $exc_handler_general" :
                         undef,
        pc          => $pc,
        pcPhy       => $mmu_present ? "W_pcb_phy" : undef,
        ivValid     => $iw_valid_expr,
        iv          => "W_iw",
        dstRegWr    => "W_wr_dst_reg",
        dstRegNum   => "W_dst_regnum",
        dstRegVal   => $dstRegVal,
        dstRegSet   => $shadow_present ? "W_dst_regset" : undef,
        dstRegEccTestPort => $dstRegEccTestPort_expr,
        memAddr     => "W_mem_baddr",
        memAddrPhy  => $mmu_present ? "W_mem_baddr_phy" : undef,
        stData      => "W_st_data",
        stByteEn    => "W_mem_byte_en",
        pass        => "W_cmp_result",
        targetPC    => "W_target_pcb",
    };





    if ($pteaddr_reg) {
        set_control_reg_need_testbench_version($pteaddr_reg, 1);
    }
    if ($tlbacc_reg) {
        set_control_reg_need_testbench_version($tlbacc_reg, 1);
    }
    if ($tlbmisc_reg) {
        set_control_reg_need_testbench_version($tlbmisc_reg, 1);
    }
    if ($mpubase_reg) {
        set_control_reg_need_testbench_version($mpubase_reg, 1);
    }
    if ($mpuacc_reg) {
        set_control_reg_need_testbench_version($mpuacc_reg, 1);
    }

    my $cpu_info = {
        CpuCoreName     => "NiosII/f2",
        CpuInstanceName => not_empty_scalar($Opt, "name"),
        CpuArchName     => "Nios2",
        CpuArchRev      => $r2 ? "R2" : "R1",
    };

    my $trace_file_name = optional_scalar($Opt, "trace_file_name");
    my $filename_base = ($trace_file_name eq "") ? not_empty_scalar($Opt, "name") : $trace_file_name;

    create_rtl_trace_and_testend({
      activate_trace    => manditory_bool($Opt, "activate_trace"),
      filename_base     => "$filename_base",
      reset_entry       => $reset_entry,
      intr_entry        => $intr_entry,
      hbreak_entry      => $hbreak_entry,
      inst_entry        => $inst_entry,
      control_regs      => manditory_array($Opt, "control_regs"),
      control_reg_stage => not_empty_scalar($Opt, "control_reg_stage"),
      extra_exc_info    => $extra_exc_info,
      cpu_info          => $cpu_info,
      test_end_expr     => $test_end_expr,
    });




    $submodule->sink_signals(
      "W_pcb",
      "W_vinst",
      "W_valid",
      "W_iw",
    );

    push(@simgen_wave_signals,
        { radix => "x", signal => "$testbench_instance_name/W_pcb" },
        { radix => "a", signal => "$testbench_instance_name/W_vinst" },
        { radix => "x", signal => "$testbench_instance_name/W_valid" },
        { radix => "x", signal => "$testbench_instance_name/W_iw" },
    );

    return $submodule;
}





sub 
make_base_pipeline
{
    my $Opt = shift;

    my $whoami = "backend 500 base pipeline";


    e_signal->adds({name => "D_pcb", never_export => 1, width => $pcb_sz});
    e_signal->adds({name => "E_pcb", never_export => 1, width => $pcb_sz});
    e_signal->adds({name => "M_pcb", never_export => 1, width => $pcb_sz});
    e_signal->adds({name => "A_pcb", never_export => 1, width => $pcb_sz});
    e_signal->adds({name => "W_pcb", never_export => 1, width => $pcb_sz});

    e_assign->adds(["D_pcb", "{D_pc, 2'b00}"]);
    e_register->adds(
      {out => "E_pcb",             in => "D_pcb",         enable => "E_en"},
      {out => "M_pcb",             in => "E_pcb",         enable => "M_en"},
      {out => "A_pcb",             in => "M_pcb",         enable => "A_en", ip_debug_visible => 1},
      {out => "W_pcb",             in => "A_pcb",         enable => "1'b1", ip_debug_visible => 1},
      );

    if (manditory_bool($Opt, "export_pcbdebuginfo")) {


        e_signal->adds(
          {name => "pc", width => 32, export => $force_export },
          {name => "pc_valid", width => 1, export => $force_export },
        );

        push(@{$Opt->{port_list}},
          ["pc"         => 32,     "out" ],
          ["pc_valid"   => 1,      "out" ],
        );

        my $pcb_remainder_bits = 32 - $pcb_sz;

        e_assign->adds(
          ["pc", ($pcb_remainder_bits > 0) ? "{{${pcb_remainder_bits} {1'b0}},W_pcb}" : "W_pcb" ],
          ["pc_valid", "W_valid|W_exc_any"],
        );
        

        push(@{$Opt->{port_list}},
          ["iw"         => 32, "out" ],
          ["iw_valid"   => 1,      "out" ],
          ["exc"        => 1, "out" ],
          ["exc_valid"  => 1,      "out" ],
        );
        
        e_register->adds(
           {out => "W_exc_any",    in => "A_exc_any",         enable => "1'b1", ip_debug_visible => 1},
        );
    

        e_assign->adds(
          ["iw", "W_iw"],
          ["iw_valid", "W_valid|W_exc_any"],
          ["exc", "W_exc_any"],
          ["exc_valid", "W_valid|W_exc_any"],
        );
    }

    my @exc_wave_signals;

    make_D_stage($Opt);
    make_E_stage($Opt, \@exc_wave_signals);
    my ($M_ram_rd_data_present) = make_M_stage($Opt, \@exc_wave_signals);
    make_A_stage($Opt, \@exc_wave_signals);
    make_W_stage($Opt);





    if (scalar(@exc_wave_signals) > 0) {
        push(@plaintext_wave_signals, { divider => "exceptions" });
        push(@plaintext_wave_signals, @exc_wave_signals);
    }

    my @mem_load_store_wave_signals = (
        { divider => "mem" },
        { radix => "x", signal => "E_mem_baddr" },
        { radix => "x", signal => "M_mem_baddr" },
        { divider => "load" },
        { radix => "x", signal => "M_ctrl_ld_dcache_management" },
        { radix => "x", signal => "M_ctrl_ld8" },
        { radix => "x", signal => "M_ctrl_ld16" },
        { radix => "x", signal => "M_ctrl_ld_signed" },
        $M_ram_rd_data_present ? {radix =>"x", signal => "M_ram_rd_data"} : "",
        { radix => "x", signal => "M_inst_result" },
        { radix => "x", signal => "A_inst_result" },
        { radix => "x", signal => "A_inst_result_aligned" },
        { radix => "x", signal => "A_wr_data_unfiltered" },
        { radix => "x", signal => "A_wr_data_filtered" },
        { radix => "x", signal => "A_ld_align_sh16" },
        { radix => "x", signal => "A_ld_align_sh8" },
        { radix => "x", signal => "A_ld_align_byte1_fill" },
        { radix => "x", signal => "A_ld_align_byte2_byte3_fill" },
        { divider => "store" },
        { radix => "x", signal => "E_ctrl_st" },
        { radix => "x", signal => "E_ctrl_st8" },
        { radix => "x", signal => "E_ctrl_st16" },
        { radix => "x", signal => "E_valid" },
        { radix => "x", signal => "E_st_data" },
        { radix => "x", signal => "E_mem_byte_en" },
        { radix => "x", signal => "M_st_data" },
        { radix => "x", signal => "M_mem_byte_en" },
        { radix => "x", signal => "A_st_data" },
        { radix => "x", signal => "A_mem_byte_en" },
    );

    push(@plaintext_wave_signals, @mem_load_store_wave_signals);
}




sub 
make_D_stage
{
    my $Opt = shift;

    my $ds = not_empty_scalar($Opt, "dispatch_stage");

    e_assign->adds(









      [["D_stall", 1], "(D_dep_stall | D_rdprs_stall | E_stall) & ~M_pipe_flush"],
      [["D_en", 1], "~D_stall"],        







      [["D_dep_stall", 1], "D_data_depend & D_issue"],






      [["D_valid", 1], "D_issue & ~D_data_depend & ~D_rdprs_stall & ~M_pipe_flush"],

      [["D_issue_rdprs", 1], $shadow_present ? "D_issue & D_ctrl_rdprs" : "0"],



      [["D_rdprs_stall_unfiltered", 1], "D_issue_rdprs & ~D_rdprs_stall_done"],





      [["D_rdprs_stall_done_nxt", 1], 
        "M_pipe_flush        ? 0 :
         D_rdprs_stall_done  ? E_stall :
                               D_issue_rdprs"],
    );




    new_exc_combo_signal({
        name                => "D_exc_invalidates_inst_value",
        stage               => "D",
        invalidates_inst_value          => 1,
    });




    create_x_filter({
      lhs       => "D_rdprs_stall",
      rhs       => "D_rdprs_stall_unfiltered",
      sz        => 1,
      qual_expr => "D_exc_invalidates_inst_value",
    });


    e_signal->adds({name => "D_pc_plus_one", never_export => 1, 
      width => $pc_sz});

    e_register->adds(
      {out => ["D_iw", $iw_sz],                 in => "${ds}_iw",     
       enable => "D_en"},
      {out => ["D_pc", $pc_sz],                 in => "${ds}_pc", 
       enable => "D_en"},
      {out => "D_pc_plus_one",                  in => "${ds}_pc_plus_one",
       enable => "D_en"},
      {out => ["D_rdprs_stall_done", 1],        in => "D_rdprs_stall_done_nxt",
       enable => "1"},
    );








    if ($pc_sz > $iw_imm26_sz) {
        e_assign->adds(
          [["D_jmp_direct_target_waddr", $pc_sz], 
            "{D_pc[$pc_sz-1:$iw_imm26_sz], D_iw[$iw_imm26_msb:$iw_imm26_lsb]}"],
        );
    } else {
        e_assign->adds(
          [["D_jmp_direct_target_waddr", $pc_sz], 
            "D_iw[$iw_imm26_msb:$iw_imm26_lsb]"],
        );
    }


    e_signal->adds({name => "D_jmp_direct_target_baddr", never_export => 1, 
      width => $pcb_sz});
    e_assign->adds(["D_jmp_direct_target_baddr", 
     "{D_jmp_direct_target_waddr, 2'b00}"]);





    e_assign->adds(




      [["D_extra_pc", $pc_sz], 
        "D_br_pred_not_taken ? D_br_taken_waddr : 
                               D_pc_plus_one"],
    );


    e_signal->adds({name => "D_extra_pcb", never_export => 1, 
      width => $pcb_sz});
    e_assign->adds(["D_extra_pcb", "{D_extra_pc, 2'b00}"]);
    
    








    
    my @D_iw_corrupt_inputs;
    if ($ic_ecc_present) {
        push(@D_iw_corrupt_inputs, "D_ic_ecc_err"); # All I$ ECC errors are recoverable
    }

    if ($itcm_ecc_present) {
        for (my $cmi = 0; 
          $cmi < manditory_int($Opt, "num_tightly_coupled_instruction_masters");
          $cmi++) {

            push(@D_iw_corrupt_inputs, "D_itcm${cmi}_one_bit_err");
        }
    }

    e_assign->adds(
      [["D_iw_corrupt", 1], scalar(@D_iw_corrupt_inputs) ? join('|', @D_iw_corrupt_inputs) : "0"],
    );
    e_register->adds(
      {out => ["E_iw_corrupt", 1, 0, $force_never_export],
       in => "D_iw_corrupt",     enable => "E_en"},
      {out => ["M_iw_corrupt", 1, 0, $force_never_export],
       in => "E_iw_corrupt",     enable => "M_en"},
      {out => ["A_iw_corrupt", 1, 0, $force_never_export],
       in => "M_iw_corrupt",     enable => "A_en"},
    );
}




sub 
make_E_stage
{
    my $Opt = shift;
    my $exc_wave_signals_ref = shift;



    e_assign->adds(
      [["E_stall", 1], "M_stall"],


      [["E_en", 1], "~E_stall"],        
    );


    e_register->adds(
      {out => ["E_valid_from_D", 1],        in => "D_valid",
       enable => "E_en"},
      {out => ["E_iw", $iw_sz],             in => "D_iw", 
       enable => "E_en"},
      {out => ["E_dst_regnum", $regnum_sz], in => "D_dst_regnum", 
       enable => "E_en" },
      {out => ["E_wr_dst_reg_from_D", 1],   in => "D_wr_dst_reg", 
       enable => "E_en"},
      {out => ["E_extra_pc", $pc_sz],       in => "D_extra_pc", 
       enable => "E_en"},
      {out => ["E_pc", $pc_sz],             in => "D_pc", 
       enable => "E_en"},
      {out => ["E_valid_jmp_indirect", 1],  in => "D_ctrl_jmp_indirect & D_valid",
       enable => "E_en"},
      );

    if ($mmu_present) {
        my $E_tlb_inst_miss_exc =
          get_exc_signal_name($tlb_inst_miss_exc, "E");

        e_assign->adds(
          [["E_mem_baddr_user_region", 1],
            "E_mem_baddr[$mmu_addr_user_region_msb:$mmu_addr_user_region_lsb]
              == $mmu_addr_user_region"],
          [["E_mem_baddr_supervisor_region", 1], "~E_mem_baddr_user_region"],




          [["E_valid_uitlb_lru_access", 1], 
            "E_valid_from_D & ~E_pc_bypass_tlb & ~$E_tlb_inst_miss_exc"],
        );

        e_register->adds(
          {out => ["E_pc_bypass_tlb", 1],
           in => "D_pc_bypass_tlb",     enable => "E_en"},
          {out => ["E_uitlb_index", $uitlb_index_sz],
           in => "D_uitlb_index",       enable => "E_en"},
        );
    }


    e_signal->adds({name => "E_extra_pcb", never_export => 1, 
      width => $pcb_sz});
    e_assign->adds(["E_extra_pcb", "{E_extra_pc, 2'b00}"]);






    new_exc_signal({
        exc             => $trap_inst_exc,
        initial_stage   => "E", 
        speedup_stage   => "E",
        rhs             => "E_ctrl_trap_inst & !E_iw_corrupt",
    });


    new_exc_signal({
        exc             => $unimp_inst_exc,
        initial_stage   => "E", 
        speedup_stage   => "E",
        rhs             => "E_ctrl_unimp_trap & !E_iw_corrupt",
    });


    my $software_break = "1'b0";
    my $cpu_arch_rev = manditory_int($Opt, "cpu_arch_rev");




    my $r1 = ($cpu_arch_rev == 1);
    my $allow_break_inst = manditory_bool($Opt, "allow_break_inst");
    if ( $oci_present || $allow_break_inst || $r1 ) {
        $software_break = "E_op_break & !E_iw_corrupt";
    }

    new_exc_signal({
        exc             => $break_inst_exc,
        initial_stage   => "E", 
        speedup_stage   => "E",
        rhs             => $software_break,
    });


    new_exc_signal({
        exc             => $illegal_inst_exc,
        initial_stage   => "E", 
        speedup_stage   => "E",
        rhs             => "E_ctrl_illegal & !E_iw_corrupt",
    });

    push(@$exc_wave_signals_ref,
      get_exc_signal_wave($trap_inst_exc, "E"),
      get_exc_signal_wave($unimp_inst_exc, "E"),
      get_exc_signal_wave($break_inst_exc, "E"),
      get_exc_signal_wave($illegal_inst_exc, "E"),
    );

    if ($mmu_present || $mpu_present) {


        new_exc_signal({
            exc             => $supervisor_inst_exc,
            initial_stage   => "E", 
            speedup_stage   => "E",
            rhs             => 
               "E_ctrl_supervisor_only & W_status_reg_u & !E_iw_corrupt",
        });

        push(@$exc_wave_signals_ref,
          get_exc_signal_wave($supervisor_inst_exc, "E"),
        );
    }

    if ($mmu_present) {


        new_exc_signal({
            exc             => $supervisor_data_addr_exc,
            initial_stage   => "E", 
            speedup_stage   => "E",
            rhs             => "E_ctrl_mem_data_access & !E_mem_baddr_corrupt &
              E_mem_baddr_supervisor_region & W_status_reg_u",
        });

        push(@$exc_wave_signals_ref,
          get_exc_signal_wave($tlb_inst_miss_exc, "E"),
          get_exc_signal_wave($tlb_x_perm_exc, "E"),
          get_exc_signal_wave($supervisor_inst_addr_exc, "E"),
          get_exc_signal_wave($supervisor_data_addr_exc, "E"),
        );
    }

    if ($illegal_mem_exc) {

        new_exc_signal({
            exc             => $misaligned_data_addr_exc,
            initial_stage   => "E", 
            speedup_stage   => "E",
            rhs             => 
              "!E_mem_baddr_corrupt & ((E_ctrl_mem32 & (E_mem_baddr[1:0] != 2'b00)) |
                                       (E_ctrl_mem16 & (E_mem_baddr[0]   != 1'b0)))",
        });


        new_exc_signal({
            exc             => $misaligned_target_pc_exc,
            initial_stage   => "E", 
            speedup_stage   => "E",
            rhs             => 
              "(E_ctrl_jmp_indirect & (E_src1[1:0] != 2'b00) & !E_src1_corrupt) |
               (E_ctrl_br & (E_iw_imm16[1:0] != 2'b00) & !E_iw_corrupt)",
        });

        push(@$exc_wave_signals_ref,
          get_exc_signal_wave($misaligned_data_addr_exc, "E"),
          get_exc_signal_wave($misaligned_target_pc_exc, "E"),
        );
    }

    if ($hw_div) {
        new_exc_signal({
            exc             => $div_error_exc,
            initial_stage   => "E", 
            speedup_stage   => "E",
            rhs             => 
              "(E_ctrl_div & (E_src2 == 0) & !E_src2_corrupt) |
               (E_op_div & (E_src1 == 32'h80000000) & !E_src1_corrupt &
                           (E_src2 == 32'hffffffff) & !E_src2_corrupt)",
        });

        push(@$exc_wave_signals_ref,
          get_exc_signal_wave($div_error_exc, "E"),
        );
    }





    e_assign->adds(


      [["E_valid", 1], "E_valid_from_D & ~E_cancel"],



      [["E_wr_dst_reg", 1], "E_wr_dst_reg_from_D & ~E_cancel"],
    );
    

    if (manditory_bool($Opt, "export_vectors")) {
        e_port->adds(["reset_vector_word_addr", $pc_sz, "in"]);
        e_port->adds(["exception_vector_word_addr", $pc_sz, "in"]);
        if ($mmu_present) {
            e_port->adds(["fast_tlb_miss_vector_word_addr", $pc_sz, "in"]);
        }
    }

    e_assign->adds(


      [["E_cancel", 1], "M_pipe_flush"],




      [["M_pipe_flush_nxt", 1], "E_br_mispredict | A_pipe_flush_nxt"],

      [["M_pipe_flush_waddr_nxt", $pc_sz], "E_extra_pc"],
    );


    e_signal->adds({name => "M_pipe_flush_baddr_nxt", never_export => 1, width => $pcb_sz});
    e_assign->adds(
      [["M_pipe_flush_baddr_nxt", 1], "{M_pipe_flush_waddr_nxt, 2'b00}"]
    );








    my $cmp_mem_baddr_sz = 
      $mmu_present ? 32 : manditory_int($Opt, "d_Address_Width");

    my $avalon_master_info = manditory_hash($Opt, "avalon_master_info");


    my @sel_signals = make_master_address_decoder({
      avalon_master_info    => $avalon_master_info,
      normal_master_name    => "data_master", 
      tightly_coupled_master_names => manditory_array($avalon_master_info,
        "avalon_tightly_coupled_data_master_list"), 
      high_performance_master_names => manditory_array($avalon_master_info,
        "avalon_data_master_high_performance_list"),
      flash_accelerator_master_names => manditory_array($avalon_master_info,
        "avalon_data_master_high_performance_list"),
      addr_signal           => "E_mem_baddr[$cmp_mem_baddr_sz-1:0]",
      addr_sz               => $cmp_mem_baddr_sz, 
      sel_prefix            => "E_sel_",
      mmu_present           => $mmu_present,
      fa_present            => 0,
      master_paddr_mapper_func => \&nios2_mmu::master_paddr_mapper,
    });

    if (scalar(@sel_signals) > 1) {
        push(@plaintext_wave_signals, 
            { divider => "data_master_sel" },
        );

        foreach my $sel_signal (@sel_signals) {
            push(@plaintext_wave_signals, 
              { radix => "x", signal => $sel_signal },
            );
        }
    }

    e_assign->adds(



      [["E_sel_dtcm", 1, 0, $force_never_export], "~E_sel_data_master"],

      [["E_dtcm_ld", 1, 0, $force_never_export], "E_ctrl_ld & E_sel_dtcm"],
      [["E_dtcm_st", 1, 0, $force_never_export], "E_ctrl_st & E_sel_dtcm & E_st_writes_mem"],
    );
    
    if ($dcache_present) {

        e_assign->adds(
          [["E_dtcm_ld_st", 1], "E_ctrl_ld_st & E_sel_dtcm & E_st_writes_mem"],
        );
        
        if ($mmu_present || $mpu_present) {

            e_register->adds(
               {out => ["M_dtcm_ld_st", 1],            
                in => "E_dtcm_ld_st", enable => "M_en"},
            );
        }
    }

}




sub 
make_M_stage
{
    my $Opt = shift;
    my $exc_wave_signals_ref = shift;

    my @data_ecc_event_bus_waves;
    my $cpu_arch_rev = manditory_int($Opt, "cpu_arch_rev");

    my $r1 = ($cpu_arch_rev == 1);
    my $r2 = ($cpu_arch_rev == 2);



    e_assign->adds(
      [["M_stall", 1], "A_stall"],


      [["M_en", 1], "~M_stall"],        
    );

    e_signal->adds(


      {name => "M_cmp_result", never_export => 1, width => 1},
      {name => "M_target_pcb", never_export => 1, width => $pcb_sz},
    );

    e_register->adds(
      {out => ["M_valid_from_E", 1],                in => "E_valid",
       enable => "M_en"},
      {out => ["M_iw",  $iw_sz],                    in => "E_iw",
       enable => "M_en"},
      {out => ["M_mem_byte_en", $byte_en_sz],       in => "E_mem_byte_en",
       enable => "M_en", },
      {out => ["M_alu_result", $datapath_sz],       in => "E_alu_result",
       enable => "M_en"},
      {out => ["M_st_data", $datapath_sz],          in => "E_st_data",
       enable => "M_en"},
      {out => ["M_dst_regnum", $regnum_sz],         in => "E_dst_regnum",
       enable => "M_en"},
      {out => "M_cmp_result",                       in => "E_cmp_result",
       enable => "M_en"},
      {out => ["M_wr_dst_reg_from_E", 1],           in => "E_wr_dst_reg",
       enable => "M_en"},
      {out => "M_target_pcb",                       in => "E_src1[$pcb_sz-1:0]",
       enable => "M_en"},


      {out => ["M_pipe_flush", 1],               in => "M_pipe_flush_nxt",
       enable => "M_en", 
       async_value => "1'b1"},
      {out => ["M_pipe_flush_waddr", $pc_sz],    in => "M_pipe_flush_waddr_nxt",
       enable => "M_en", 
       async_value => 
         manditory_bool($Opt, "export_vectors") ? "reset_vector_word_addr" : "$reset_pc"},
      );


    foreach my $master (@{$Opt->{avalon_data_master_list}}) {
        e_register->adds(
          {out => ["M_sel_${master}", 1, 0, $force_never_export],
           in => "E_sel_${master}", enable => "M_en"},
        );
    }

    e_assign->adds(



      [["M_sel_dtcm", 1, 0, $force_never_export], "~M_sel_data_master"],

      [["M_dtcm_ld", 1, 0, $force_never_export], "M_ctrl_ld & M_sel_dtcm"],
      [["M_dtcm_st", 1, 0, $force_never_export], "M_ctrl_st & M_sel_dtcm & M_st_writes_mem"],
      [["M_dtcm_st_non32", 1, 0, $force_never_export], 
        "M_ctrl_st_non32 & M_sel_dtcm & M_st_writes_mem"],
    );

    e_register->adds(
      {out => ["M_pc", $pc_sz], in => "E_pc", enable => "M_en"},

      {out => ["M_pc_plus_one", $pc_sz],     in => "E_pc + 1",
       enable => "M_en"},
    );

    if ($cpu_reset) {





        e_register->adds(
          {out => ["M_cpu_resetrequest", 1], 
           in => ($hbreak_present ? 
             "(cpu_resetrequest & hbreak_enabled)" : 
             "cpu_resetrequest"),
           enable => "M_en" },
        );
    
        push(@$exc_wave_signals_ref,
          get_exc_signal_wave($cpu_reset_exc, "M"));
    }

    push(@$exc_wave_signals_ref,
      get_exc_signal_wave(
        $eic_present ? $ext_intr_exc : $norm_intr_exc, "M"),
      get_exc_signal_wave($break_inst_exc, "M"),
    );


    if ($mmu_present || $mpu_present) {
        push(@$exc_wave_signals_ref,
          get_exc_signal_wave($supervisor_inst_exc, "M"),
        );
    }

    if ($mmu_present) {
        push(@$exc_wave_signals_ref,
          get_exc_signal_wave($supervisor_inst_addr_exc, "M"),
          get_exc_signal_wave($tlb_inst_miss_exc, "M"),
          get_exc_signal_wave($tlb_x_perm_exc, "M"),
          get_exc_signal_wave($break_inst_exc, "E"),
        );
    }


    e_signal->adds({name => "M_pipe_flush_baddr", never_export => 1, 
      width => $pcb_sz});
    e_assign->adds(["M_pipe_flush_baddr", "{M_pipe_flush_waddr, 2'b00}"]);

    e_register->adds(
      {out => ["M_mem_baddr", $mem_baddr_sz, 0, $force_never_export],
       in => "E_mem_baddr",             enable => "M_en"},
      );

    e_assign->adds(
       [["M_mem_waddr", $mem_baddr_sz-2, 0, $force_never_export], "M_mem_baddr[$mem_baddr_sz-1:2]"],
    );


    if ($mmu_present) {
      my $data_addr_phy_sz  = manditory_int($Opt, "d_Address_Width");
      e_assign->adds(
         [["M_mem_waddr_phy", $data_addr_phy_sz-2, 0, $force_never_export], 
           "M_mem_baddr_phy[$data_addr_phy_sz-1:2]"],
      );
    } else {
      e_assign->adds(
         [["M_mem_waddr_phy", $mem_baddr_sz-2, 0, $force_never_export], 
           "M_mem_baddr[$mem_baddr_sz-1:2]"],
      );
    }










    my @ram_rd_data_mux_table;
    my $M_ram_rd_data_present = 0;

    if ($dcache_present) {
        push(@ram_rd_data_mux_table, "M_sel_data_master" => "M_dc_rd_data");
        $M_ram_rd_data_present = 1;
    }

    for (my $cmi = 0; 
      $cmi < manditory_int($Opt, "num_tightly_coupled_data_masters"); $cmi++) {
        my $master_name = "tightly_coupled_data_master_${cmi}";
        my $sel_name = "M_sel_" . $master_name;

        my $data_name = $dtcm_ecc_present ? "dtcm${cmi}_rd_data" : "dtcm${cmi}_readdata";

        if ($cmi == 
          (manditory_int($Opt, "num_tightly_coupled_data_masters") - 1)) {
            push(@ram_rd_data_mux_table,
              "1'b1" => $data_name);
        } else {
            push(@ram_rd_data_mux_table,
              $sel_name => $data_name);
        }
        $M_ram_rd_data_present = 1;
    }

    if ($M_ram_rd_data_present) {
        e_mux->add ({
          lhs => ["M_ram_rd_data", $datapath_sz],
          type => "priority",
          table => \@ram_rd_data_mux_table,
          });
    }








    e_assign->adds(
      [["M_fwd_reg_data", $datapath_sz], "M_alu_result"],
    );









    if ($r2) {
        e_assign->adds(
          [["M_rdctl_data_0_latest", 1], 
             "(M_iw_control_regnum == 4'd0)? M_status_reg_pie_latest : M_rdctl_data[0]"],
        );
        
        if ($shadow_present & $eic_present) {
            e_assign->adds(
              [["M_rdctl_data_23_latest", 1], 
                 "(M_iw_control_regnum == 4'd0)? M_status_reg_rsie_latest : M_rdctl_data[23]"],
            );    
        }
    }

    e_assign->adds(
      [["M_rdctl_data_latest", $datapath_sz], 
         ($r2 && $shadow_present & $eic_present) ? "{M_rdctl_data[31:24],M_rdctl_data_23_latest,M_rdctl_data[22:1],M_rdctl_data_0_latest}" :
         ($r2) ? "{M_rdctl_data[31:1],M_rdctl_data_0_latest}" :
                                                   "M_rdctl_data"],
    );


    e_assign->adds(
      [["M_rdctl_data_inst_result", $datapath_sz], 
        "M_ctrl_intr_inst ? W_status_reg : M_rdctl_data_latest"],
    );

    my $M_inst_result_mux_table = [];

    push(@$M_inst_result_mux_table,
      "M_exc_any" => "{ M_pc_plus_one, 2'b00 }",
    );

    push(@$M_inst_result_mux_table,
      "M_ctrl_rd_ctl_reg" => "M_rdctl_data_inst_result"
    );

    if ($M_ram_rd_data_present) {
        push(@$M_inst_result_mux_table,
          "M_ctrl_ld" => "M_ram_rd_data"
        );
    }
 
    push(@$M_inst_result_mux_table,
      "1'b1"              => "M_alu_result",
    );

    e_mux->add ({
      lhs => ["M_inst_result", $datapath_sz],
      type => "priority",
      table => $M_inst_result_mux_table,
      });





















































    if (!$dcache_present) {
        e_assign->adds(
          [["A_dc_want_fill", 1], "1'b0"],
          [["A_dc_fill_done", 1], "1'b1"],
        );
    }

    e_register->adds(

      {out => ["W_up_ex_mon_state",1],
       in => "(A_ctrl_ld_ex & A_valid) ? 1'b1 :
              (((A_ctrl_st_ex & (~A_dc_want_fill | A_dc_fill_done)) | A_op_eret) & A_valid)? 1'b0 : 
              W_up_ex_mon_state",
       enable => "W_en"},
    );
    
    e_assign->adds(



      [["E_up_ex_mon_state_latest", 1], 
        "(M_ctrl_ld_st_ex & M_valid) ? M_ctrl_ld_ex :
         (A_ctrl_ld_st_ex & A_valid) ? A_ctrl_ld_ex :
         W_up_ex_mon_state"],



      [["E_st_writes_mem", 1, 0, $force_never_export], 
        "(~E_ctrl_st_ex | E_up_ex_mon_state_latest)"],




      [["M_up_ex_mon_state_latest", 1], 
        "(A_ctrl_ld_st_ex & A_valid) ? A_ctrl_ld_ex :
         W_up_ex_mon_state"],



      [["M_st_writes_mem", 1, 0, $force_never_export], 
        "(~M_ctrl_st_ex | M_up_ex_mon_state_latest)"],


      [["A_up_ex_mon_state_latest", 1], "W_up_ex_mon_state"],



      [["A_st_writes_mem", 1, 0, $force_never_export], 
        "(~A_ctrl_st_ex | A_up_ex_mon_state_latest)"],
    );
    
    if ($r2) {





        

        e_register->adds(
          {out => ["M_intr_inst_pie",1],
           in => "(E_op_wrpie & E_valid) ? E_src1[0] :
                  1'b1",
           enable => "M_en"},
        );

        e_register->adds(
          {out => ["A_intr_inst_pie",1],
           in => "M_intr_inst_pie",
           enable => "A_en"},
        );
           
        e_assign->adds(

           [["E_status_reg_pie_latest", 1], 
           "(M_ctrl_intr_inst & M_valid) ? M_intr_inst_pie :
            (A_ctrl_intr_inst & A_valid) ? A_intr_inst_pie :
            W_status_reg_pie"],

           [["M_status_reg_pie_latest", 1], 
           "(A_ctrl_intr_inst & A_valid) ? A_intr_inst_pie :
            W_status_reg_pie"],
        );
        

        e_register->adds(
           {out => ["A_status_reg_pie_alu_0",1],
           in => "M_alu_result[0]",
           enable => "A_en"},
        );
        
        if ($shadow_present & $eic_present) {

            e_register->adds(
              {out => ["M_intr_inst_rsie",1],
               in => "(W_status_reg_rsie | E_iw_rsie)",
               enable => "M_en"},
            );

            e_register->adds(
              {out => ["A_intr_inst_rsie",1],
               in => "M_intr_inst_rsie",
               enable => "A_en"},
            );   
             
            e_assign->adds(

               [["E_status_reg_rsie_latest", 1], 
               "(M_op_eni & M_valid) ? M_intr_inst_rsie :
                (A_op_eni & A_valid) ? A_intr_inst_rsie :
                W_status_reg_rsie"],

               [["M_status_reg_rsie_latest", 1], 
                "(A_op_eni & A_valid) ? A_intr_inst_rsie :
                W_status_reg_rsie"], 
            );
        }
    }






    e_assign->adds(



      [["M_ld_align_sh16", 1], 
        "(M_ctrl_ld8 | M_ctrl_ld16) & ${big_endian_tilde}M_mem_baddr[1] &
          ~M_exc_any"],





      [["M_ld_align_sh8", 1], 
        "M_ctrl_ld8 & ${big_endian_tilde}M_mem_baddr[0] &
         ~M_exc_any"],



      [["M_ld_align_byte1_fill", 1], "M_ctrl_ld8 & ~M_exc_any"],
      


      [["M_ld_align_byte2_byte3_fill", 1], 
         "M_ctrl_ld8_ld16 & ~M_exc_any"],
    );




 
    push(@$exc_wave_signals_ref,
      { radix => "x", signal => "M_ignore_exc" },
      { radix => "x", signal => "M_exc_any" },
      { radix => "x", signal => "M_exc_allowed" },
    );

    if ($hbreak_present) {


        new_exc_signal({
            exc             => $hbreak_exc,
            initial_stage   => "M", 
            rhs             => "M_hbreak_req",
        });
    }

    if ($cpu_reset) {



        new_exc_signal({
            exc             => $cpu_reset_exc,
            initial_stage   => "M", 
            rhs             => "M_cpu_resetrequest",
        });
    
        my $A_crst_exc_nxt =
          get_exc_nxt_signal_name($cpu_reset_exc, "A");
    





        e_assign->adds([["M_exc_crst", 1], "$A_crst_exc_nxt"]);
    
        push(@$exc_wave_signals_ref,
          { radix => "x", signal => "M_exc_crst" },
        );
    } else {
        e_assign->adds([["M_exc_crst", 1, 0, $force_never_export], "0"]);
    }

    if ($eic_present) {



        new_exc_signal({
            exc             => $ext_intr_exc,
            initial_stage   => "M", 
            rhs             => "M_ext_intr_req",
        });

        e_assign->adds(





          [["M_exc_ext_intr", 1], get_exc_nxt_signal_name($ext_intr_exc, "A")],
        );

        push(@$exc_wave_signals_ref,
          get_exc_signal_wave($ext_intr_exc, "M"),
          { radix => "x", signal => "M_exc_ext_intr" },
        );
    } else {



        new_exc_signal({
            exc             => $norm_intr_exc,
            initial_stage   => "M", 
            rhs             => "M_norm_intr_req",
        });

        e_assign->adds(

          [["M_exc_ext_intr", 1, 0, $force_never_export], "0"],
        );

        push(@$exc_wave_signals_ref,
          get_exc_signal_wave($norm_intr_exc, "M"),
        );
    }

    if ($ecc_present) {         
        if ($rf_ecc_present) {





            new_exc_signal({
                exc             => $ecc_rf_error_exc,
                initial_stage   => "M", 
                rhs             => "W_ecc_exc_enabled & M_rf_raw_unrecoverable_ecc_err & !M_iw_corrupt",
            });
    
            my $A_ecc_rf_error_exc = get_exc_signal_name($ecc_rf_error_exc, "A");
           
            e_assign->adds(



              [["A_exc_ecc_rf_error_active", 1], "A_exc_allowed & $A_ecc_rf_error_exc"],
            );
    


            new_exc_combo_signal({
              name                => "A_exc_higher_pri_than_ecc_rf_error",
              stage               => "A",
              higher_pri_than_excs => [$ecc_rf_error_exc],
            });
    
            push(@data_ecc_event_bus_waves,
              { radix => "x", signal => "A_exc_higher_pri_than_ecc_rf_error" },
            );
    




    
            e_assign->adds(



    






              [["rf_ecc_event_unrecoverable_err", 1],
                "A_exc_allowed & A_rf_raw_unrecoverable_ecc_err & 
                  ~A_exc_higher_pri_than_ecc_rf_error & A_en_d1"],
    


              [["rf_ecc_event_recoverable_err", 1], "A_rf_ecc_event_recoverable_err & A_en_d1"],
            );
    
            push(@data_ecc_event_bus_waves,
              { radix => "x", signal => "A_exc_allowed" },
              { radix => "x", signal => "A_dc_tag_raw_unrecoverable_ecc_err" },
              { radix => "x", signal => "dc_tag_ecc_event_unrecoverable_err" },
              { radix => "x", signal => "A_dc_data_raw_unrecoverable_ecc_err" },
              { radix => "x", signal => "dc_data_ecc_event_unrecoverable_err" },
            );
        }
    
        if ($dc_ecc_present || $dtcm_ecc_present) {
















            my @ecc_data_error_exc_signals;

            if ($dc_ecc_present) {
                push(@ecc_data_error_exc_signals, 
                  "(pending_dc_unrecoverable_ecc_err & W_ecc_exc_enabled)");
            }

            if ($dtcm_ecc_present) {
                my @ecc_dtcm_error_exc_signals;
                for (my $cmi = 0; 
                    $cmi < manditory_int($Opt, "num_tightly_coupled_data_masters"); $cmi++) {
                        push(@ecc_dtcm_error_exc_signals, "A_dtcm${cmi}_raw_unrecoverable_ecc_err");
                    }

                e_register->adds(
                    {out => ["W_dtcm_unrecoverable_ecc_err", 1],  
                     in => "(" . join('|', @ecc_dtcm_error_exc_signals) . ")", enable => "1'b1"},
                     
                     {out => ["pending_dtcm_unrecoverable_ecc_err", 1],  
                      in => "pending_dtcm_unrecoverable_ecc_err ?
                             ~(M_valid_from_E & ~A_pipe_flush) :
                             W_dtcm_unrecoverable_ecc_err",
                      enable => "1'b1"},
                );
                push(@ecc_data_error_exc_signals, 
                  "(pending_dtcm_unrecoverable_ecc_err & W_ecc_exc_enabled)");
            }

            new_exc_signal({
                exc             => $ecc_data_error_exc,
                initial_stage   => "M", 
                rhs             => join('|', @ecc_data_error_exc_signals),
            });
    
            my $A_ecc_data_error_exc = get_exc_signal_name($ecc_data_error_exc, "A");
           
            e_assign->adds(



              [["A_exc_ecc_data_error_active", 1], "A_exc_allowed & $A_ecc_data_error_exc"],
            );
    


            new_exc_combo_signal({
              name                => "A_exc_higher_pri_than_ecc_data_error",
              stage               => "A",
              higher_pri_than_excs => [$ecc_data_error_exc],
            });
    
            push(@data_ecc_event_bus_waves,
              { radix => "x", signal => "A_exc_higher_pri_than_ecc_data_error" },
            );
        }
    
        if ($dtcm_ecc_present) {
            for (my $cmi = 0; 
                $cmi < manditory_int($Opt, "num_tightly_coupled_data_masters"); $cmi++) {
                    e_assign->adds(
                    [["dtcm${cmi}_ecc_event_unrecoverable_err", 1],
                      "A_exc_allowed & A_dtcm${cmi}_raw_unrecoverable_ecc_err & 
                       ~A_exc_higher_pri_than_ecc_data_error & A_en_d1"],
                    [["dtcm${cmi}_ecc_event_recoverable_err", 1], "A_dtcm${cmi}_ecc_event_recoverable_err & A_en_d1"],
                  );
                }
        }

        if ($dc_ecc_present) {




    
            e_assign->adds(



    


              [["dc_wb_ecc_event_unrecoverable_err", 1], "A_dc_xfer_two_bit_err_detected"],
              [["dc_wb_ecc_event_recoverable_err", 1], "A_dc_xfer_one_bit_err_detected"],
    






              [["dc_tag_ecc_event_unrecoverable_err", 1],
                "A_exc_allowed & A_dc_tag_raw_unrecoverable_ecc_err & 
                  ~A_exc_higher_pri_than_ecc_data_error & A_en_d1"],
              [["dc_data_ecc_event_unrecoverable_err", 1],
                "A_exc_allowed & A_dc_data_raw_unrecoverable_ecc_err & 
                  ~A_exc_higher_pri_than_ecc_data_error & A_en_d1"],
    


              [["dc_tag_ecc_event_recoverable_err", 1], "A_dc_tag_ecc_event_recoverable_err & A_en_d1"],
              [["dc_data_ecc_event_recoverable_err", 1], "A_dc_data_ecc_event_recoverable_err & A_en_d1"],
            );
    
            push(@data_ecc_event_bus_waves,
              { radix => "x", signal => "A_exc_allowed" },
              { radix => "x", signal => "A_dc_tag_raw_unrecoverable_ecc_err" },
              { radix => "x", signal => "dc_tag_ecc_event_unrecoverable_err" },
              { radix => "x", signal => "A_dc_data_raw_unrecoverable_ecc_err" },
              { radix => "x", signal => "dc_data_ecc_event_unrecoverable_err" },
              { radix => "x", signal => "A_dc_tag_ecc_event_recoverable_err" },
              { radix => "x", signal => "dc_tag_ecc_event_recoverable_err" },
              { radix => "x", signal => "A_dc_data_ecc_event_recoverable_err" },
              { radix => "x", signal => "dc_data_ecc_event_recoverable_err" },
            );
    



    


            new_exc_signal({
                exc             => $ecc_dcache_async_error_exc,
                initial_stage   => "E", 
                rhs             => "dc_xfer_unrecoverable_ecc_err_pending & W_ecc_exc_enabled",
            });
    


            new_exc_combo_signal({
                name                => "A_higher_pri_than_ecc_dcache_async_error_exc",
                stage               => "A",
                higher_pri_than_excs => [$ecc_dcache_async_error_exc],
            });
    
            my $A_ecc_dcache_async_error_exc = get_exc_signal_name($ecc_dcache_async_error_exc, "A");
           
            my $victim_buf_ram_one_bit_ecc_err = "";
            my $victim_buf_ram_two_bit_ecc_err = "";
            if ($victim_buf_ram) {
                $victim_buf_ram_one_bit_ecc_err = " | (A_dc_wb_rd_data_active & dc_wb_port_one_bit_err)";
                $victim_buf_ram_two_bit_ecc_err = " | (A_dc_wb_rd_data_active & dc_wb_port_two_bit_err)";    
            }
            e_assign->adds(



              [["A_exc_ecc_dcache_async_error_active", 1], 
                "A_exc_allowed & $A_ecc_dcache_async_error_exc"],
    



              [["A_exc_ecc_dcache_async_error_or_higher_active", 1], 
                "A_exc_ecc_dcache_async_error_active |
                  (A_exc_allowed & A_higher_pri_than_ecc_dcache_async_error_exc)"],
    




              [["A_dc_xfer_one_bit_err_detected", 1], 
                "(A_dc_xfer_rd_data_active & dc_data_rd_port_one_bit_err)$victim_buf_ram_one_bit_ecc_err"], 
              [["A_dc_xfer_two_bit_err_detected", 1], 
                "(A_dc_xfer_rd_data_active & dc_data_rd_port_two_bit_err)$victim_buf_ram_two_bit_ecc_err"], 
            );
    
            e_register->adds(








              {out => ["dc_xfer_unrecoverable_ecc_err_pending", 1], 
               in => "dc_xfer_unrecoverable_ecc_err_pending ?
                        ~(A_exc_ecc_dcache_async_error_or_higher_active | ~W_ecc_exc_enabled) :
                        (A_dc_xfer_two_bit_err_detected & W_ecc_exc_enabled)",
               enable => "1'b1"},
            );
    
            push(@$exc_wave_signals_ref,
              { radix => "x", signal => "A_dc_xfer_one_bit_err_detected" }, 
              { radix => "x", signal => "A_dc_xfer_two_bit_err_detected" }, 
              { radix => "x", signal => "dc_xfer_unrecoverable_ecc_err_pending" },
              get_exc_signal_wave($ecc_dcache_async_error_exc, "A"),
              { radix => "x", signal => "A_exc_ecc_dcache_async_error_or_higher_active" },
              { radix => "x", signal => "A_dc_xfer_rd_data_active" },
              { radix => "x", signal => "dc_data_rd_port_two_bit_err" },
            );
        }
    
        if ($mmu_ecc_present) {
            new_exc_signal({
                exc             => $ecc_dtlb_error_exc,
                initial_stage   => "M", 
                rhs             => 
                    "M_ctrl_mem_data_access & !M_mem_baddr_corrupt &
                     (~M_mem_baddr_bypass_tlb & M_udtlb_hit & M_udtlb_two_bit_err)",
            });
            
            my $A_ecc_error_itlb_exc = get_exc_signal_name($ecc_itlb_error_exc, "A");
            my $A_ecc_error_dtlb_exc = get_exc_signal_name($ecc_dtlb_error_exc, "A");
           
            e_assign->adds(


              [["A_exc_ecc_error_itlb_active", 1], "A_exc_allowed & $A_ecc_error_itlb_exc"],
              [["A_exc_ecc_error_dtlb_active", 1], "A_exc_allowed & $A_ecc_error_dtlb_exc"],
            );
            
            push(@$exc_wave_signals_ref,
              get_exc_signal_wave($ecc_dtlb_error_exc, "M"),
              { radix => "x", signal => "$A_ecc_error_dtlb_exc" },
              { radix => "x", signal => "$A_ecc_error_dtlb_exc" },
              { radix => "x", signal => "A_exc_ecc_error_itlb_active" },
              { radix => "x", signal => "A_exc_ecc_error_dtlb_active" },
            );
        }
    }




 



    new_exc_combo_signal({
        name            => "M_exc_any",
        stage           => "M",
    });

    my $A_hbreak_exc_nxt = $hbreak_present ?  get_exc_nxt_signal_name($hbreak_exc, "A") : "0";
    my $A_break_inst_exc_nxt = get_exc_nxt_signal_name($break_inst_exc, "A");

    e_assign->adds(





      [["M_exc_break", 1], "$A_hbreak_exc_nxt | $A_break_inst_exc_nxt"],






      [["M_ignore_exc", 1], 
        "A_pipe_flush | A_refetch_required | (M_udtlb_refetch & ~M_exc_higher_priority_than_tlb_data)"],




      [["M_exc_allowed", 1], "M_valid_from_E & ~M_ignore_exc"],
    );

    push(@$exc_wave_signals_ref,
      { radix => "x", signal => "M_exc_break" },
    );

    if ($mmu_present) {
        my $M_tlb_inst_miss_exc =
          get_exc_signal_name($tlb_inst_miss_exc, "M");
        my $M_tlb_x_perm_exc =
          get_exc_signal_name($tlb_x_perm_exc, "M");
        my $A_tlb_inst_miss_exc_nxt =
          get_exc_nxt_signal_name($tlb_inst_miss_exc, "A");
        my $A_tlb_data_miss_exc_nxt =
          get_exc_nxt_signal_name($tlb_data_miss_exc, "A");

        e_assign->adds(






          [["M_exc_fast_tlb_miss", 1], 
            "~W_exc_handler_mode & 
               ($A_tlb_inst_miss_exc_nxt | $A_tlb_data_miss_exc_nxt)"],




          [["M_exc_vpn", $mmu_addr_vpn_sz], 
            "($M_tlb_inst_miss_exc | $M_tlb_x_perm_exc) ? 
              M_pc[$mmu_addr_vpn_msb-2:$mmu_addr_vpn_lsb-2] :
              M_mem_baddr[$mmu_addr_vpn_msb:$mmu_addr_vpn_lsb]"],




          [["M_udtlb_access", 1], 
            "M_ctrl_mem_data_access & ~M_mem_baddr_bypass_tlb"],
        );

        push(@$exc_wave_signals_ref,
          { radix => "x", signal => "M_exc_fast_tlb_miss" },
          { radix => "x", signal => "M_exc_vpn" },
          { radix => "x", signal => "M_udtlb_access" },
        );
    }






    push(@$exc_wave_signals_ref,
      { radix => "x", signal => "M_refetch" },
    );

    my @M_refetch_inputs;

    if ($dcache_present) {
        push(@M_refetch_inputs, "M_dc_raw_hazard");
    }

    if ($dtcm_present) {
        push(@M_refetch_inputs, "M_dtcm_raw_hazard");
    }

    if ($mmu_present) {


        new_exc_combo_signal({
            name                => "M_exc_higher_priority_than_tlb_data",
            stage               => "M",
            higher_pri_than_excs => 
              [$tlb_data_miss_exc, $tlb_r_perm_exc, $tlb_w_perm_exc],
        });
        
        e_assign->adds(











          [["M_udtlb_refetch", 1], "M_ctrl_mem_data_access & ~M_mem_baddr_phy_got_pfn"],
        );
        
        push(@M_refetch_inputs, "M_udtlb_refetch");
        
        push(@$exc_wave_signals_ref,
          { radix => "x", signal => "M_udtlb_refetch" },
        );
    } else {

        e_assign->adds(
          [["M_exc_higher_priority_than_tlb_data", 1, 0, $force_never_export], "0"],
          [["M_udtlb_refetch", 1], "0"],
        );
    }

    if ($ecc_present) {



    
        push(@$exc_wave_signals_ref,
          { radix => "x", signal => "W_config_reg_eccen" },
        );
    
        if ($rf_ecc_present) {
            push(@M_refetch_inputs, 
              "(M_rf_raw_recoverable_ecc_err & W_config_reg_eccen)");
    
            push(@$exc_wave_signals_ref,
              { radix => "x", signal => "M_rf_raw_recoverable_ecc_err" },
            );
        }
    
        if ($ic_ecc_present) {
            push(@M_refetch_inputs, "M_ic_ecc_err");
    
            push(@$exc_wave_signals_ref,
              { radix => "x", signal => "M_ic_ecc_err" },
            );
        }
    
        if ($itcm_ecc_present) {
            for (my $cmi = 0; 
              $cmi < manditory_int($Opt, "num_tightly_coupled_instruction_masters");
              $cmi++) {
                push(@M_refetch_inputs, "M_itcm${cmi}_one_bit_err");
    
                push(@$exc_wave_signals_ref,
                  { radix => "x", signal => "M_itcm${cmi}_one_bit_err" },
                );
            }
        }
        
        if ($dtcm_ecc_present) {
             my @dtcm_raw_any_ecc_err;
             for (my $cmi = 0; 
                  $cmi < manditory_int($Opt, "num_tightly_coupled_data_masters"); $cmi++) {
                    push(@dtcm_raw_any_ecc_err, "M_dtcm${cmi}_raw_any_ecc_err");
    
                    push(@$exc_wave_signals_ref,
                       { radix => "x", signal => "M_dtcm${cmi}_raw_any_ecc_err" },
                );
            }
            e_assign->adds(
               [["M_dtcm_ecc_A_refetch_required", 1], scalar(@dtcm_raw_any_ecc_err) ? "(" . join('|', @dtcm_raw_any_ecc_err) . ") & M_valid & W_config_reg_eccen  & ~pending_dtcm_unrecoverable_ecc_err" : "0"],
            );
            
            e_register->adds(
                {out => ["A_dtcm_ecc_A_refetch_required", 1], 
                 in => "M_dtcm_ecc_A_refetch_required",
                 enable => "A_en"},
            );
            
        }
    }
    
    e_assign->adds(



      [["M_refetch", 1, 0, $force_never_export], 
        scalar(@M_refetch_inputs) ? join('|', @M_refetch_inputs) : "0"],
    );





    push(@$exc_wave_signals_ref,
      { radix => "x", signal => "M_cancel" },
      { radix => "x", signal => "M_cancel_except_refetch" },
      { radix => "x", signal => "M_valid_ignoring_refetch" },
    );

    e_assign->adds(





      [["M_cancel", 1], "A_pipe_flush | M_refetch | M_exc_any | A_refetch_required"],


      [["M_cancel_except_refetch", 1], "A_pipe_flush | M_exc_any"],



      [["M_valid", 1], "M_valid_from_E & ~M_cancel"],


      [["M_valid_ignoring_refetch", 1, 0, $force_never_export], 
        "M_valid_from_E & ~M_cancel_except_refetch"],





      [["M_wr_dst_reg", 1], "M_wr_dst_reg_from_E & ~M_cancel"],
    );














    e_assign->adds(

      [["M_non_flushing_wrctl", 1], 
        $mpu_present ? 
          "M_ctrl_wrctl_inst & 
            ((M_iw_control_regnum == $mpubase_reg_regnum) |
             (M_iw_control_regnum == $mpuacc_reg_regnum))" :
          "0"],

      [["A_pipe_flush_nxt", 1], 
        "(((M_ctrl_flush_pipe_always & ~M_non_flushing_wrctl) | M_refetch | M_exc_any) & 
          M_valid_from_E & ~A_pipe_flush) | A_refetch_required"],
    );



    my $pipe_flush_waddr_mux_table = [];

    push(@$pipe_flush_waddr_mux_table, 

      "A_refetch_required" => "A_pc",


      "M_exc_break" => manditory_int($Opt, "break_word_addr"),
    );

    if ($cpu_reset) {
        push(@$pipe_flush_waddr_mux_table, 

          "M_exc_crst" => (manditory_bool($Opt, "export_vectors") ? 
            "reset_vector_word_addr" :
            manditory_int($Opt, "reset_word_addr")),
        );
    }

    if ($eic_present) {
         push(@$pipe_flush_waddr_mux_table, 

          "M_exc_ext_intr" => "M_eic_rha[$pcb_sz-1:2]",
        );
    }

    if ($mmu_present) {
        push(@$pipe_flush_waddr_mux_table, 

          "M_exc_fast_tlb_miss" => (manditory_bool($Opt, "export_vectors") ? 
            "fast_tlb_miss_vector_word_addr" :
            manditory_int($Opt, "fast_tlb_miss_exception_word_addr") ),
        );
    }

    push(@$pipe_flush_waddr_mux_table, 

      "M_exc_any" => (manditory_bool($Opt, "export_vectors") ?  
        "exception_vector_word_addr" :
        manditory_int($Opt, "general_exception_word_addr") ),


      "M_refetch" => "M_pc",


      "M_ctrl_jmp_indirect" => "M_target_pcb[$pcb_sz-1:2]",



      "1'b1" => "M_pc_plus_one",
    );

    e_mux->add ({
      lhs => ["A_pipe_flush_waddr_nxt", $pc_sz],
      type => "priority",
      table => $pipe_flush_waddr_mux_table,
    });


    e_signal->adds({name => "A_pipe_flush_baddr_nxt", never_export => 1, width => $pcb_sz});
    e_assign->adds(["A_pipe_flush_baddr_nxt", "{A_pipe_flush_waddr_nxt, 2'b00}"]);

    if (scalar(@data_ecc_event_bus_waves) > 0) {
        push(@plaintext_wave_signals, { divider => "data_ecc_event_bus" });
        push(@plaintext_wave_signals, @data_ecc_event_bus_waves);
    }

    return ($M_ram_rd_data_present);
}




sub
make_A_stage()
{
    my $Opt = shift;
    my $exc_wave_signals_ref = shift;

    my $whoami = "A-stage";

    my $bmx_s = not_empty_scalar($Opt, "bmx_s");

    my $cpu_arch_rev = manditory_int($Opt, "cpu_arch_rev");

    my $r1 = ($cpu_arch_rev == 1);
    my $r2 = ($cpu_arch_rev == 2);









    my @A_stall_inputs;

    push(@A_stall_inputs, "A_mem_stall");

    if ($hw_mul) {
        if ($hw_mul_uses_les || (!$hw_mul_omits_msw && $hw_mul_uses_embedded_mults) ) {


            push(@A_stall_inputs, "A_mul_stall");
        } else {

        }
    }

    if ($hw_div) {
        push(@A_stall_inputs, "A_div_stall");
    }

    if ($fast_shifter_uses_designware || $fast_shifter_uses_les) {


    } elsif ($small_shifter_uses_les || $medium_shifter_uses_les) {
        push(@A_stall_inputs, "A_shift_rot_stall");
    } else {
        &$error("make_base_pipeline: unsupported shifter implementation");
    }

    if (nios2_custom_insts::has_multi_insts($Opt->{custom_instructions})) {
        push(@A_stall_inputs, "A_ci_multi_stall");
    }
    
    e_assign->adds(
      [["A_stall", 1], 
        scalar(@A_stall_inputs) ? join('|', @A_stall_inputs) : "0"],


      [["A_en", 1], "~A_stall"],        
      );

    e_signal->adds(



      {name => "A_cmp_result", never_export => 1, width => 1},
      {name => "A_br_jmp_target_pcb", never_export => 1, width => $pcb_sz},
      {name => "A_mem_baddr", never_export => 1, width => $mem_baddr_sz},
      {name => "A_exc_fast_tlb_miss", never_export => 1, width => 1 },
    );

    e_register->adds(
      {out => ["A_pc", $pc_sz],                     in => "M_pc", 
       enable => "A_en"},
      {out => ["A_valid_from_M", 1],                in => "M_valid",
       enable => "A_en", ip_debug_visible => 1},
      {out => ["A_iw",  $iw_sz],                    in => "M_iw",
       enable => "A_en", ip_debug_visible => 1},
      {out => ["A_inst_result", $datapath_sz],      in => "M_inst_result",
       enable => "A_en"},
      {out => ["A_mem_byte_en", $byte_en_sz],       in => "M_mem_byte_en",
       enable => "A_en", },
      {out => ["A_st_data", $datapath_sz],          in => "M_st_data",
       enable => "A_en"},
      {out => ["A_dst_regnum_from_M", $regnum_sz],  in => "M_dst_regnum",
       enable => "A_en"},
      {out => ["A_ld_align_sh16", 1],               in => "M_ld_align_sh16",
       enable => "A_en"},
      {out => ["A_ld_align_sh8", 1],                in => "M_ld_align_sh8",
       enable => "A_en"},
      {out => ["A_ld_align_byte1_fill", 1],         
       in => "M_ld_align_byte1_fill",
       enable => "A_en"},
      {out => ["A_ld_align_byte2_byte3_fill", 1],   
       in => "M_ld_align_byte2_byte3_fill",
       enable => "A_en"},
      {out => "A_cmp_result",                       in => "M_cmp_result",  
       enable => "A_en"},
      {out => "A_mem_baddr",                        in => "M_mem_baddr",
       enable => "A_en"},




      {out => ["A_wr_dst_reg_from_M", 1],           in => "M_wr_dst_reg",
       enable => "A_en", async_value => "1'b1" },

      {out => ["A_en_d1", 1, 0, $force_never_export], in => "A_en",    
       enable => "1'b1"},
    );

    e_assign->adds(
       [["A_mem_waddr", $mem_baddr_sz-2, 0, $force_never_export], "A_mem_baddr[$mem_baddr_sz-1:2]"],
    );


    if ($mmu_present) {
      my $data_addr_phy_sz  = manditory_int($Opt, "d_Address_Width");
      e_assign->adds(
         [["A_mem_waddr_phy", $data_addr_phy_sz-2, 0, $force_never_export], 
           "A_mem_baddr_phy[$data_addr_phy_sz-1:2]"],
      );
    } else {
      e_assign->adds(
         [["A_mem_waddr_phy", $mem_baddr_sz-2, 0, $force_never_export], 
           "A_mem_baddr[$mem_baddr_sz-1:2]"],
      );
    }

    e_assign->adds(

      [["A_br_jmp_target_pcb_nxt", $pcb_sz], 
        "M_ctrl_br ? 
          ({M_pc_plus_one, 2'b00} + {{16 {M_iw_imm16[15]}}, M_iw_imm16}) :
          M_target_pcb"],
    );


    foreach my $master (@{$Opt->{avalon_data_master_list}}) {
        e_register->adds(
          {out => ["A_sel_${master}", 1, 0, $force_never_export],
           in => "M_sel_${master}", enable => "A_en"},
        );
    }

    e_assign->adds(



      [["A_sel_dtcm", 1, 0, $force_never_export], "~A_sel_data_master"],

      [["A_dtcm_ld", 1, 0, $force_never_export], "A_ctrl_ld & A_sel_dtcm"],
      [["A_dtcm_st", 1, 0, $force_never_export], "A_ctrl_st & A_sel_dtcm & A_st_writes_mem"],
    );

    e_register->adds(


      {out => ["A_pipe_flush", 1],           in => "A_pipe_flush_nxt",
       enable => "A_en | A_refetch_required" },
      {out => ["A_pipe_flush_waddr", $pc_sz],in => "A_pipe_flush_waddr_nxt",
       enable => "A_en | A_refetch_required" },


      {out => ["A_exc_break", 1],            in => "M_exc_break",
       enable => "A_en"},
      {out => ["A_exc_crst", 1],             in => "M_exc_crst",
       enable => "A_en"},
      {out => ["A_exc_ext_intr", 1],         in => "M_exc_ext_intr",
       enable => "A_en"},
      {out => ["A_exc_any", 1],              in => "M_exc_any",
       enable => "A_en"},
      {out => ["A_br_jmp_target_pcb", $pcb_sz, 0, $force_never_export],
       in => "A_br_jmp_target_pcb_nxt",
       enable => "A_en"},








      {out => ["A_exc_allowed", 1],          in => "M_exc_allowed", 
       enable => "1'b1"},
    );


    e_signal->adds({name => "A_pipe_flush_baddr", never_export => 1, 
      width => $pcb_sz});
    e_assign->adds(["A_pipe_flush_baddr", "{A_pipe_flush_waddr, 2'b00}"]);

    if ($mmu_present) {
        e_register->adds(
          {out => ["A_exc_vpn", $mmu_addr_vpn_sz],  in => "M_exc_vpn",
           enable => "A_en"},
          {out => ["A_udtlb_access", 1],            in => "M_udtlb_access",
           enable => "A_en"},
          {out => ["A_udtlb_index", $udtlb_index_sz],
           in => "M_udtlb_index",        enable => "A_en"},
          {out => ["A_exc_fast_tlb_miss", 1],
           in  => "M_exc_fast_tlb_miss", enable  => "A_en"},
        );
    
        e_assign->adds(






          [["A_valid_udtlb_lru_access", 1], "A_valid & A_udtlb_access"],
        );
    }

    if ($bmx_present) {



        e_signal->adds(
          {name => "A_bmx_result", never_export => 1, width => $datapath_sz},
          {name => "A_bmx_target", never_export => 1, width => $datapath_sz},            
          {name => "M_ext_mask", never_export => 1, width => $datapath_sz},
          {name => "M_ins_mask", never_export => 1, width => $datapath_sz},
          {name => "M_bmx_mask", never_export => 1, width => $datapath_sz},
        );
        
        e_assign->adds(
          ["M_bmx_mask", "M_op_extract ? M_ext_mask : M_ins_mask"],
          ["M_bmx_src", "M_op_extract ? 32'b0 : M_st_data"],
          [["M_ext_size",5], "M_iw_bmx_msb - M_iw_bmx_lsb"],
        );
        
        my $bit;
        
        for ($bit = 0; $bit < 32; $bit++) {
            e_assign->adds(
              ["M_ext_mask[$bit]",
                 "($bit <= M_ext_size) ? 1'b1 : 1'b0"],
        
              ["M_ins_mask[$bit]",
                 "($bit >= M_iw_bmx_lsb && ($bit <= M_iw_bmx_msb)) ? 1'b1 : 1'b0"],
        
          );
        }

        e_assign->adds(
          ["A_bmx_target", $hw_mul_uses_dsp_block ? "A_mul_shift_rot_result" : "A_shift_rot_result"],
          );
        
        for ($bit = 0; $bit < 32; $bit++) {
          e_assign->adds(
            ["A_bmx_result[$bit]",
                 "A_bmx_mask[$bit] ? A_bmx_target[$bit] : 
                                        A_bmx_src[$bit]"],
            );
        }



        
        e_register->adds(
          {out => ["A_bmx_src",32],
           in =>   "M_bmx_src", enable => "A_en"},
        
          {out => ["A_bmx_mask",32],
           in =>   "M_bmx_mask", enable => "A_en"},
        );
    }











    my $slow_inst_result_table = [];
    my @slow_inst_sel_list = ();
    my @slow_inst_en_list = ();
    my $hw_mul_embedded_mults_with_msw = $hw_mul && $hw_mul_uses_embedded_mults && !$hw_mul_omits_msw;

    my @slow_inst_result_mux_signals = (
        { divider => "A_slow_inst_result_mux" },
    );

    if ($eic_and_shadow) {
        push(@$slow_inst_result_table,
          "A_exc_wr_sstatus" => "W_sstatus_reg_nxt",
        );
        push(@slow_inst_sel_list, "A_exc_wr_sstatus");
        push(@slow_inst_en_list,  "A_exc_wr_sstatus");

        push(@slow_inst_result_mux_signals,
          { radix => "x", signal => "A_exc_wr_sstatus" },
          { radix => "x", signal => "W_sstatus_reg_nxt" },
        );
    }

    if ($hw_div) {
        push(@$slow_inst_result_table,
          "A_ctrl_div" => "A_div_quot",
        );
        push(@slow_inst_sel_list, "A_ctrl_div");
        push(@slow_inst_en_list,  "A_ctrl_div");



        e_register->adds(
          {out => ["A_div_done", 1],
           in => "A_div_quot_ready",
           enable => "1'b1"},
        );

        push(@slow_inst_result_mux_signals,
          { radix => "x", signal => "A_ctrl_div" },
          { radix => "x", signal => "A_div_quot" },
          { radix => "x", signal => "A_div_quot_ready" },
          { radix => "x", signal => "A_div_done" },
        );
    }

    if (nios2_custom_insts::has_multi_insts($Opt->{custom_instructions})) {
        push(@$slow_inst_result_table,
          "A_ctrl_custom_multi"         => "A_ci_multi_result",
        );
        push(@slow_inst_sel_list, "A_ctrl_custom_multi");
        push(@slow_inst_en_list,  "A_ctrl_custom_multi");

        push(@slow_inst_result_mux_signals,
          { radix => "x", signal => "A_ctrl_custom_multi" },
          { radix => "x", signal => "A_ci_multi_result" },
        );
    }

    if ($dcache_present) {





        push(@slow_inst_sel_list, "A_ctrl_ld_bypass", "A_dc_want_fill");








        push(@slow_inst_en_list,
          "((A_dc_fill_miss_offset_is_next | A_ctrl_ld_bypass) &
            d_readdatavalid_d1)");

        push(@slow_inst_result_mux_signals,
          { radix => "x", signal => "A_slow_inst_result_en" },
          { radix => "x", signal => "A_dc_fill_miss_offset_is_next" },
          { radix => "x", signal => "A_ctrl_ld_bypass" },
          { radix => "x", signal => "d_readdatavalid_d1" },
        );
        push(@slow_inst_result_mux_signals,
          { radix => "x", signal => "A_ctrl_ld_bypass" },
          { radix => "x", signal => "A_dc_want_fill" },
        );
    } else {


        push(@slow_inst_sel_list, $dtcm_present ? "(A_ctrl_ld & A_sel_data_master)" : "A_ctrl_ld");
        push(@slow_inst_en_list,  "A_ctrl_ld");

        push(@slow_inst_result_mux_signals,
          { radix => "x", signal => "A_ctrl_ld" },
          { radix => "x", signal => "A_ctrl_ld32" },
        );


        push(@$slow_inst_result_table,
          "A_ctrl_ld32"             => "d_readdata",
        );
    }
    
    push(@$slow_inst_result_table,
      "1'b1"                        => "A_slow_ld_data_aligned_nxt",
    );

    push(@slow_inst_result_mux_signals,
      { radix => "x", signal => "A_slow_ld_data_aligned_nxt" },
    );

    if (scalar(@$slow_inst_result_table) > 0) {

        e_assign->adds(
          [["A_slow_inst_result_en", 1], join('|', @slow_inst_en_list)],
        );
    
        e_mux->add({
          lhs => ["A_slow_inst_result_nxt", $datapath_sz],
          type => "priority",
          table => $slow_inst_result_table,
        });

        e_register->adds(
          {out => ["A_slow_inst_result", $datapath_sz], 
           in => "A_slow_inst_result_nxt",     
           enable => "A_slow_inst_result_en"},
        );

        push(@slow_inst_result_mux_signals,
          { radix => "x", signal => "A_slow_inst_result_en" },
          { radix => "x", signal => "A_slow_inst_result_nxt" },
          { radix => "x", signal => "A_slow_inst_result" },
        );
    }


    if (scalar(@slow_inst_sel_list) > 0) {





        e_assign->adds(
          [["A_slow_inst_sel_nxt", 1], 
             "A_en ? 0 : " . join('|', @slow_inst_sel_list)],
        );
     
        e_register->adds(
          {out => ["A_slow_inst_sel", 1],
           in => "A_slow_inst_sel_nxt",        
           enable => "1'b1"},
        );

        push(@slow_inst_result_mux_signals,
          { radix => "x", signal => "A_slow_inst_sel_nxt" },
          { radix => "x", signal => "A_slow_inst_sel" },
        );
    }

    push(@plaintext_wave_signals, @slow_inst_result_mux_signals);
  












    my $rf_wr_mux_table = [];
    my $ld_mux_table = [];

    if ($eic_and_shadow) {



        push(@$rf_wr_mux_table, 
          "W_exc_wr_sstatus"                    => "A_slow_inst_result",
        );
    }






    push(@$rf_wr_mux_table, 
      "A_exc_any"                           => "A_inst_result_aligned",
    );




    e_assign->adds(
      [["A_exc_addr", $datapath_sz, 0, $force_never_export], "A_inst_result"],
    );


    my $A_shift_rot_bmx_sel = $bmx_present ? "A_ctrl_shift_rot|A_op_merge" : "A_ctrl_shift_rot";
    if ($hw_mul_uses_dsp_block) {
        e_assign->adds(
            [["A_shift_rot_bmx_result",$datapath_sz], $bmx_present ? "A_ctrl_bmx ? A_bmx_result : A_mul_shift_rot_result" : "A_mul_shift_rot_result" ]
        );
        $A_shift_rot_bmx_sel = $bmx_present ? "A_ctrl_mul_shift_rot|A_op_merge" : "A_ctrl_mul_shift_rot";
    } else {
        e_assign->adds(
            [["A_shift_rot_bmx_result",$datapath_sz], $bmx_present ? "A_ctrl_bmx ? A_bmx_result : A_shift_rot_result" : "A_shift_rot_result" ]
        );    
    }

    if ($hw_mul) {
        if ($hw_mul_uses_dsp_block) {
            push(@$rf_wr_mux_table,
              ${A_shift_rot_bmx_sel}             => "A_shift_rot_bmx_result",
            );
        } elsif ($hw_mul_uses_embedded_mults || $hw_mul_uses_les ||
          $hw_mul_uses_designware) {
            if ( $hw_mul_embedded_mults_with_msw ) {
                push(@$rf_wr_mux_table, 
                  "A_ctrl_mulx"                      => "A_mul_result_msw",
                );
            }
            push(@$rf_wr_mux_table,
              "A_ctrl_mul_lsw"                   => "A_mul_result",
              ${A_shift_rot_bmx_sel}             => "A_shift_rot_bmx_result",
            );
        } else {
            &$error("$whoami: unsupported hardware multiplier implementation");
        }
    } else {
        push(@$rf_wr_mux_table,
          ${A_shift_rot_bmx_sel}                 => "A_shift_rot_bmx_result",
        );
    }

    if (scalar(@$slow_inst_result_table) > 0) {
        push(@$rf_wr_mux_table, 
          "~A_slow_inst_sel | A_ctrl_st_ex"                => "A_inst_result_aligned",
          "1'b1"                            => "A_slow_inst_result",
        );
        push(@$ld_mux_table, 
          "~A_slow_inst_sel | A_ctrl_st_ex"                => "A_inst_result_aligned",
          "1'b1"                            => "A_slow_inst_result",
        );
    } else {
        push(@$rf_wr_mux_table, 
          "1'b1"                            => "A_inst_result_aligned",
        );
        push(@$ld_mux_table, 
          "1'b1"                            => "A_inst_result_aligned",
        );
    }

    e_mux->add ({
      lhs => ["A_wr_data_unfiltered", $datapath_sz],
      type => "priority",
      table => $rf_wr_mux_table,
    });


    e_signal->adds(
      {name => "A_ld_data", width => $datapath_sz, 
       never_export => 1},
    );

    e_mux->add ({
      lhs => ["A_ld_data", $datapath_sz],
      type => "priority",
      table => $ld_mux_table,
    });


    e_assign->adds(
      [["A_fwd_reg_data", $datapath_sz], "A_wr_data_filtered"],
    );





    e_assign->adds(


      [["A_exc_any_active", 1], "A_exc_any & A_exc_allowed"],
      [["A_exc_break_active", 1], "A_exc_break & A_exc_allowed"],
      [["A_exc_crst_active", 1], "A_exc_crst & A_exc_allowed"],
      [["A_exc_ext_intr_active", 1, 0, $force_never_export], 
        "A_exc_ext_intr & A_exc_allowed"],
    


      [["A_exc_shadow", 1], 
        $eic_and_shadow ? "A_exc_ext_intr & A_eic_rrs_non_zero" : "0"],
      [["A_exc_shadow_active", 1], "A_exc_shadow & A_exc_allowed"],
    
      [["A_exc_active_no_break", 1], 
         "A_exc_any_active & ~A_exc_break"],
    
      [["A_exc_active_no_crst", 1, 0, $force_never_export], 
         "A_exc_any_active & ~A_exc_crst"],
      [["A_exc_active_no_break_no_crst", 1, 0, $force_never_export], 
         "A_exc_any_active & ~(A_exc_break | A_exc_crst)"],
    






      [["A_exc_wr_ea_ba", 1],
        $status_reg_eh ?
          "A_exc_break_active |
            (A_exc_active_no_break_no_crst & ~W_exc_handler_mode)" :
          "A_exc_active_no_crst"],
    




      [["A_exc_wr_sstatus", 1], 
        "A_exc_shadow_active & ~W_exc_handler_mode"],
    

      [["A_dst_regnum", $regnum_sz],
        "W_exc_wr_sstatus ? $sstatus_regnum :
         A_exc_break      ? $bretaddr_regnum :
         A_exc_any        ? $eretaddr_regnum :
                            A_dst_regnum_from_M"],
    






      [["A_wr_dst_reg", 1], 
        "~A_cancel & (A_wr_dst_reg_from_M | A_exc_wr_ea_ba | W_exc_wr_sstatus)"],
    



      [["W_debug_mode_nxt", 1],
        "A_exc_break_active            ? 1'b1 :
         (A_valid & A_op_bret)         ? 1'b0 : 
                                         W_debug_mode"],
    );
    
    if ($shadow_present) {
        e_assign->adds(





          [["A_dst_regset", $rf_set_sz], 
            "W_exc_wr_sstatus ? W_status_reg_crs : " .
            ($eic_present ?  "A_exc_ext_intr_active ? A_eic_rrs : " : "") .
            "A_exc_any ? 0 :
             (A_valid & A_op_wrprs) ? W_status_reg_prs : 
                          W_status_reg_crs"],
        );
    }
    
    e_register->adds(
      {out => ["W_exc_wr_sstatus", 1], in => "A_exc_wr_sstatus",
       enable => "W_en"},
    );
    
    push(@$exc_wave_signals_ref,
      { radix => "x", signal => "A_exc_allowed" },
      { radix => "x", signal => "A_exc_any " },
      { radix => "x", signal => "A_exc_break" },
      { radix => "x", signal => "A_exc_crst" },
      { radix => "x", signal => "A_exc_ext_intr" },
      { radix => "x", signal => "A_exc_any_active" },
      { radix => "x", signal => "A_exc_break_active" },
      { radix => "x", signal => "A_exc_active_no_break_no_crst" },
      { radix => "x", signal => "A_exc_active_no_break" },
      { radix => "x", signal => "A_exc_shadow_active" },
      { radix => "x", signal => "A_exc_wr_ea_ba" },
      { radix => "x", signal => "A_wr_dst_reg" },
      { radix => "x", signal => "W_debug_mode_nxt" },
    );
    
    if ($mmu_present) {
        my $A_supervisor_inst_addr_exc = 
          get_exc_signal_name($supervisor_inst_addr_exc, "A");
        my $A_tlb_inst_miss_exc = 
          get_exc_signal_name($tlb_inst_miss_exc, "A");
        my $A_tlb_x_perm_exc =
          get_exc_signal_name($tlb_x_perm_exc, "A");
        my $A_supervisor_data_addr_exc = 
          get_exc_signal_name($supervisor_data_addr_exc, "A");
        my $A_misaligned_data_addr_exc = 
          get_exc_signal_name($misaligned_data_addr_exc, "A");
        my $A_misaligned_target_pc_exc = 
          get_exc_signal_name($misaligned_target_pc_exc, "A");
        my $A_tlb_data_miss_exc =
          get_exc_signal_name($tlb_data_miss_exc, "A");
        my $A_tlb_r_perm_exc =
          get_exc_signal_name($tlb_r_perm_exc, "A");
        my $A_tlb_w_perm_exc =
          get_exc_signal_name($tlb_w_perm_exc, "A");
    
        my $ecc_exc_dtlb = "";
        if ($mmu_ecc_present) {
            $ecc_exc_dtlb = "A_exc_ecc_error_dtlb_active |";
        }

        e_assign->adds(


          [["A_exc_tlb_inst_miss_active", 1], 
            "A_exc_allowed & $A_tlb_inst_miss_exc"],
          [["A_exc_tlb_x_perm_active", 1], 
            "A_exc_allowed & $A_tlb_x_perm_exc"],
          [["A_exc_tlb_data_miss_active", 1], 
            "A_exc_allowed & $A_tlb_data_miss_exc"],
          [["A_exc_tlb_r_perm_active", 1], 
            "A_exc_allowed & $A_tlb_r_perm_exc"],
          [["A_exc_tlb_w_perm_active", 1], 
            "A_exc_allowed & $A_tlb_w_perm_exc"],
          [["A_exc_super_data_addr_active", 1], 
            "A_exc_allowed & $A_supervisor_data_addr_exc"],
          [["A_exc_misaligned_data_addr_active", 1], 
            "A_exc_allowed & $A_misaligned_data_addr_exc"],
    


          [["A_exc_bad_virtual_addr_active", 1],
            "A_exc_allowed & 
              ($A_supervisor_inst_addr_exc |
               $A_supervisor_data_addr_exc |
               $A_misaligned_data_addr_exc | 
               $A_misaligned_target_pc_exc)"],
    

          [["A_exc_tlb_active", 1], 
            "(A_exc_tlb_inst_miss_active | A_exc_tlb_data_miss_active |
              A_exc_tlb_x_perm_active | A_exc_tlb_r_perm_active |
              A_exc_tlb_w_perm_active)"],
    


          [["A_exc_data", 1], 
            "$ecc_exc_dtlb
             A_exc_tlb_data_miss_active |
             A_exc_tlb_r_perm_active |
             A_exc_tlb_w_perm_active |
             A_exc_super_data_addr_active |
             A_exc_misaligned_data_addr_active"],
        );
    
        if ($hbreak_present) {
            push(@$exc_wave_signals_ref,
              get_exc_signal_wave($hbreak_exc, "A"));
        }
    
        if ($cpu_reset) {
            push(@$exc_wave_signals_ref,
              get_exc_signal_wave($cpu_reset_exc, "A"));
        }

        push(@$exc_wave_signals_ref,
          get_exc_signal_wave(
            $eic_present ? $ext_intr_exc : $norm_intr_exc, "A"),
          get_exc_signal_wave($break_inst_exc, "A"),
          get_exc_signal_wave($supervisor_inst_addr_exc, "A"),
          get_exc_signal_wave($tlb_inst_miss_exc, "A"),
          get_exc_signal_wave($tlb_x_perm_exc, "A"),
          get_exc_signal_wave($supervisor_data_addr_exc, "A"),
          get_exc_signal_wave($tlb_data_miss_exc, "A"),
          get_exc_signal_wave($tlb_r_perm_exc, "A"),
          get_exc_signal_wave($tlb_w_perm_exc, "A"),
    
          { radix => "x", signal => "A_exc_bad_virtual_addr_active" },
          { radix => "x", signal => "A_exc_tlb_inst_miss_active" },
          { radix => "x", signal => "A_exc_tlb_data_miss_active" },
          { radix => "x", signal => "A_exc_tlb_x_perm_active" },
          { radix => "x", signal => "A_exc_tlb_r_perm_active" },
          { radix => "x", signal => "A_exc_tlb_w_perm_active" },
          { radix => "x", signal => "A_exc_data" },
          { radix => "x", signal => "A_exc_tlb_active" },
        );
    }
    
    if ($illegal_mem_exc) {
        push(@$exc_wave_signals_ref,
          get_exc_signal_wave($misaligned_data_addr_exc, "A"),
          get_exc_signal_wave($misaligned_target_pc_exc, "A"),
        );
    }





    push(@$exc_wave_signals_ref,
      { radix => "x", signal => "A_refetch_required" },
      { radix => "x", signal => "A_cancel" },
    );

    my @A_ecc_refetch_required;
    if ($dc_ecc_present) {
        push(@A_ecc_refetch_required, "A_dc_ecc_A_refetch_required")
    }
    if ($dtcm_ecc_present) {
        push(@A_ecc_refetch_required, "A_dtcm_ecc_A_refetch_required")
    }

    e_assign->adds(






      [["A_refetch_required", 1], scalar(@A_ecc_refetch_required) ? join('|', @A_ecc_refetch_required) : "0"],



      [["A_cancel", 1], "A_refetch_required"],


      [["A_valid", 1], "A_valid_from_M & ~A_cancel"],
    );
}




sub
make_W_stage()
{
    my $Opt = shift;


    e_assign->adds(
      [["W_en", 1, 0, $force_never_export], "1'b1"],
    );

    e_signal->adds(

      {name => "W_iw",          never_export => 1, width => $iw_sz},
      {name => "W_valid",       never_export => 1, width => 1},
      {name => "W_valid_from_M",       never_export => 1, width => 1},
      {name => "W_wr_dst_reg",  never_export => 1, width => 1},
      {name => "W_dst_regnum",  never_export => 1, width => $regnum_sz},
    );



    e_register->adds(
      {out => ["W_wr_data", $datapath_sz], in => "A_wr_data_filtered",
       enable => "1'b1"},
      




      {out => "W_iw",         in => "A_iw",           enable => "1'b1",
       ip_debug_visible => $mmu_present},
      {out => "W_valid",      in => "A_valid & A_en", enable => "1'b1"},
      {out => "W_valid_from_M",      in => "A_valid_from_M & A_en", enable => "1'b1"},	#non-cancellable valid for oci v2
      {out => "W_wr_dst_reg", in => "(A_wr_dst_reg & A_en) | A_exc_wr_ea_ba", enable => "1'b1"},
      {out => "W_dst_regnum", in => "A_dst_regnum",   enable => "1'b1"},

      {out => ["W_mem_baddr", $mem_baddr_sz, 0, $force_never_export],
       in => "A_mem_baddr",         enable => "1'b1"},
      {out => ["W_mem_byte_en", $byte_en_sz, 0, $force_never_export],
       in => "A_mem_byte_en",       enable => "1'b1"},
    );

    if ($shadow_present) {
        e_signal->adds(

          {name => "W_dst_regset",  never_export => 1, width => $rf_set_sz},
        );

        e_register->adds(
          {out => "W_dst_regset", in => "A_dst_regset",   enable => "1'b1"},
        );
    }

    e_register->adds(
      {out => ["W_debug_mode", 1],
       in => "W_debug_mode_nxt",                enable => "1'b1" },
 
      {out => ["W_exc_crst_active", 1, 0, $force_never_export],
       in => "A_exc_crst_active",               enable => "1'b1" },
    );
 
    e_assign->adds(
      [["W_exc_handler_mode", 1, 0, $force_never_export], 
        $status_reg_eh ? "W_status_reg_eh" : "0"],
    );


    if ($mmu_present) {
      my $data_addr_phy_sz  = manditory_int($Opt, "d_Address_Width");
      e_assign->adds(
         [["W_mem_waddr_phy", $data_addr_phy_sz-2, 0, $force_never_export], 
           "W_mem_baddr_phy[$data_addr_phy_sz-1:2]"],
      );
    } else {
      e_assign->adds(
         [["W_mem_waddr_phy", $mem_baddr_sz-2, 0, $force_never_export], 
           "W_mem_baddr[$mem_baddr_sz-1:2]"],
      );
    }
}


sub
gen_brpred
{
    my $Opt = shift;

    my $brpred_type = not_empty_scalar($Opt, "branch_prediction_type");



    if ($brpred_type eq $STATIC_BRPRED) {
        nios_brpred::backend_gen_static_brpred($Opt);
    } elsif ($brpred_type eq $DYNAMIC_BRPRED) {
        nios_brpred::backend_gen_dynamic_brpred($Opt);

        if (!manditory_bool($Opt, "bht_index_pc_only")) {
            e_assign->adds(
              [["E_add_br_to_taken_history_unfiltered", 1], 
                "(E_ctrl_br_cond & E_valid)"],
            );
        }
    } else {
        &$error("Unsupported branch_predition_type of '$brpred_type'");
    }
}


sub 
make_register_file
{
    my $Opt = shift;

    my $whoami = "register file";

    my $gen_info = manditory_hash($Opt, "gen_info");
    my $ds = not_empty_scalar($Opt, "dispatch_stage");


    my $fa = not_empty_scalar($Opt, "rf_a_field_name");
    my $fb = not_empty_scalar($Opt, "rf_b_field_name");

    my $crs = 
      $shadow_present ? not_empty_scalar($Opt, "current_register_set") : undef;
    my $prs = 
      $shadow_present ? not_empty_scalar($Opt, "previous_register_set") : undef;


    e_signal->adds(
      {name => "rf_a_rd_port_data", width => $datapath_sz },
      {name => "rf_b_rd_port_data", width => $datapath_sz },
    );
    if ($rf_ecc_present) {
        e_signal->adds(
         {name => "rf_a_rd_port_corrected_data", width => $datapath_sz },
         {name => "rf_a_rd_port_one_bit_err", width => 1 },
         {name => "rf_a_rd_port_two_bit_err", width => 1 },
         {name => "rf_a_rd_port_any_ecc_err", width => 1, never_export => 1 },

         {name => "rf_b_rd_port_corrected_data", width => $datapath_sz },
         {name => "rf_b_rd_port_one_bit_err", width => 1 },
         {name => "rf_b_rd_port_two_bit_err", width => 1 },
         {name => "rf_b_rd_port_any_ecc_err", width => 1, never_export => 1 },

         {name => "rf_wr_port_injected_data", width => $datapath_sz },
       );
    }

    my $rf_a_port_map = {
      clock     => "clk",


      rdaddress => "rf_a_rd_port_addr",
      q         => "rf_a_rd_port_data",


      wren      => "rf_wr_port_en",
      data      => "rf_wr_port_data",
      wraddress => "rf_wr_port_addr",
    };

    my $rf_b_port_map = {
      clock     => "clk",


      rdaddress => "rf_b_rd_port_addr",
      q         => "rf_b_rd_port_data",


      wren      => "rf_wr_port_en",
      data      => "rf_wr_port_data",
      wraddress => "rf_wr_port_addr",
    };

    my @ecc_waves;

    if ($rf_ecc_present) {
        my $ecc_datapath_msb = $datapath_sz + calc_num_ecc_bits($datapath_sz) - 1;

        $rf_a_port_map->{corrected_data_to_encoder} = "rf_wr_port_corrected_data";
        $rf_a_port_map->{injs} = "rf_wr_port_injs";
        $rf_a_port_map->{injd} = "rf_wr_port_injd";
        $rf_a_port_map->{wrsel} = "rf_wr_port_wrsel";
        $rf_a_port_map->{injected_data} = "rf_wr_port_injected_data";
        if ($ecc_test_ports_present) {
            $rf_a_port_map->{test_invert} = "ecc_test_rf[$ecc_datapath_msb:0]";
        }

        $rf_b_port_map->{corrected_data_to_encoder} = "rf_wr_port_corrected_data";
        $rf_b_port_map->{injs} = "rf_wr_port_injs";
        $rf_b_port_map->{injd} = "rf_wr_port_injd";
        $rf_b_port_map->{wrsel} = "rf_wr_port_wrsel";
        if ($ecc_test_ports_present) {
            $rf_b_port_map->{test_invert} = "ecc_test_rf[$ecc_datapath_msb:0]";
        }


        $rf_a_port_map->{corrected_data_from_decoder} = "rf_a_rd_port_corrected_data";
        $rf_a_port_map->{one_bit_err} = "rf_a_rd_port_one_bit_err";
        $rf_a_port_map->{two_bit_err} = "rf_a_rd_port_two_bit_err";
        $rf_a_port_map->{one_two_or_three_bit_err} = "rf_a_rd_port_any_ecc_err";

        $rf_b_port_map->{corrected_data_from_decoder} = "rf_b_rd_port_corrected_data";
        $rf_b_port_map->{one_bit_err} = "rf_b_rd_port_one_bit_err";
        $rf_b_port_map->{two_bit_err} = "rf_b_rd_port_two_bit_err";
        $rf_b_port_map->{one_two_or_three_bit_err} = "rf_b_rd_port_any_ecc_err";

        push(@ecc_waves,
          { radix => "x", signal => "rf_wr_port_corrected_data" },
          { radix => "x", signal => "rf_wr_port_injs" },
          { radix => "x", signal => "rf_wr_port_injd" },
          { radix => "x", signal => "rf_wr_port_wrsel" },
          { radix => "x", signal => "rf_a_rd_port_corrected_data" },
          { radix => "x", signal => "rf_a_rd_port_one_bit_err" },
          { radix => "x", signal => "rf_a_rd_port_two_bit_err" },
          { radix => "x", signal => "rf_a_rd_port_any_ecc_err" },
          { radix => "x", signal => "rf_b_rd_port_corrected_data" },
          { radix => "x", signal => "rf_b_rd_port_one_bit_err" },
          { radix => "x", signal => "rf_b_rd_port_two_bit_err" },
          { radix => "x", signal => "rf_b_rd_port_any_ecc_err" },
        );

        push(@ecc_waves,
            { radix => "x", signal => "W_rf_injs" },
            { radix => "x", signal => "W_rf_injd" },
        );

        e_assign->adds(

          [["rf_wr_port_injs", 1], "W_rf_injs"],
          [["rf_wr_port_injd", 1], "W_rf_injd"],






          [["E_rf_a_raw_recoverable_ecc_err", 1], 
            "E_rf_a_one_bit_err & E_ctrl_a_is_src & E_src1_from_rf & (E_iw_a != 0)"],
          [["E_rf_b_raw_recoverable_ecc_err", 1], 
            "E_rf_b_one_bit_err & E_ctrl_b_is_src & E_src2_from_rf & (E_iw_b != 0)"],






          [["E_rf_a_raw_unrecoverable_ecc_err", 1], 
            "E_rf_a_two_bit_err & E_ctrl_a_is_src & E_src1_from_rf & (E_iw_a != 0)"],
          [["E_rf_b_raw_unrecoverable_ecc_err", 1], 
            "E_rf_b_two_bit_err & E_ctrl_b_is_src & E_src2_from_rf & (E_iw_b != 0)"],



          [["rf_wr_port_wrsel", 1], "A_rf_valid_recoverable_ecc_err"],


          [["D_rf_a_corrected_data", $datapath_sz], "rf_a_rd_port_corrected_data"],
          [["D_rf_a_one_bit_err", 1], "rf_a_rd_port_one_bit_err"],
          [["D_rf_a_two_bit_err", 1], "rf_a_rd_port_two_bit_err"],
          [["D_rf_b_corrected_data", $datapath_sz], "rf_b_rd_port_corrected_data"],
          [["D_rf_b_one_bit_err", 1], "rf_b_rd_port_one_bit_err"],
          [["D_rf_b_two_bit_err", 1], "rf_b_rd_port_two_bit_err"],
          [["rf_wr_port_corrected_data", $datapath_sz], "A_rf_corrected_data"],
          [["A_rf_injected_wr_data", $datapath_sz, 0, $force_never_export], "rf_wr_port_injected_data"],
        );


        cpu_pipeline_signal($gen_info, 
          { name => "${ds}_rf_rd_addr_a", sz => $rf_total_addr_sz, never_export => 1,
            until_stage => "E"});
        cpu_pipeline_signal($gen_info, 
          { name => "${ds}_rf_rd_addr_b", sz => $rf_total_addr_sz, never_export => 1,
            until_stage => "E"});





        cpu_pipeline_signal($gen_info, 
          { name => "E_rf_rd_addr", sz => $rf_total_addr_sz, never_export => 1,
            rhs => "E_rf_a_raw_recoverable_ecc_err ? E_rf_rd_addr_a : E_rf_rd_addr_b"});

        e_register->adds(

          {out => ["E_rf_a_one_bit_err", 1], in => "D_rf_a_one_bit_err", enable => "E_en"},
          {out => ["E_rf_b_one_bit_err", 1], in => "D_rf_b_one_bit_err", enable => "E_en"},
          {out => ["E_rf_a_two_bit_err", 1], in => "D_rf_a_two_bit_err", enable => "E_en"},
          {out => ["E_rf_b_two_bit_err", 1], in => "D_rf_b_two_bit_err", enable => "E_en"},




          {out => ["M_rf_raw_recoverable_ecc_err", 1], 
           in => "E_rf_a_raw_recoverable_ecc_err | E_rf_b_raw_recoverable_ecc_err",
           enable => "M_en"},




          {out => ["M_rf_raw_unrecoverable_ecc_err", 1], 
           in => "E_rf_a_raw_unrecoverable_ecc_err | E_rf_b_raw_unrecoverable_ecc_err",
           enable => "M_en"},
          {out => ["A_rf_raw_unrecoverable_ecc_err", 1], 
           in => "M_rf_raw_unrecoverable_ecc_err", enable => "A_en"},


          {out => ["E_rf_a_corrected_data", $datapath_sz], 
           in => "D_rf_a_corrected_data", 
           enable => "E_en"},
          {out => ["E_rf_b_corrected_data", $datapath_sz], 
           in => "D_rf_b_corrected_data", 
           enable => "E_en"},
          {out => ["M_rf_corrected_data", $datapath_sz], 
           in => "E_rf_a_raw_recoverable_ecc_err ? E_rf_a_corrected_data : E_rf_b_corrected_data",
           enable => "M_en"},
          {out => ["A_rf_corrected_data", $datapath_sz], 
           in => "M_rf_corrected_data",
           enable => "A_en"},




          {out => ["A_rf_valid_recoverable_ecc_err", 1], 
           in => "M_rf_raw_recoverable_ecc_err & M_valid_ignoring_refetch & W_config_reg_eccen",
           enable => "A_en"},


          {out => ["A_rf_ecc_event_recoverable_err", 1], 
           in => "M_rf_raw_recoverable_ecc_err & M_valid_ignoring_refetch",
           enable => "A_en"},

        );

        if ($ecc_test_ports_present) {
            e_register->adds(
              {out => ["ecc_test_rf_valid_d1", 1],    in => "ecc_test_rf_valid & rf_wr_port_en",
               enable => "1'b1"},
            );
            e_assign->adds(
              [["ecc_test_rf_ready", 1], "~ecc_test_rf_valid | ecc_test_rf_valid_d1"],
            );
        }
    }




    e_assign->adds(
      [["${ds}_iw_${fa}_rf", $rf_addr_sz], "D_en ? ${ds}_iw_${fa} : D_iw_${fa}"],
      [["${ds}_iw_${fb}_rf", $rf_addr_sz], "D_en ? ${ds}_iw_${fb} : D_iw_${fb}"],
    );

    if ($shadow_present) {
        e_assign->adds(




          [["${ds}_regset_rf", $rf_set_sz], 
            "(D_ctrl_rdprs & D_stall) ? $prs : $crs"],
        );
    }

    e_assign->adds(
      [["${ds}_rf_rd_addr_a", $rf_total_addr_sz], 
        $shadow_present ?  "{ ${ds}_regset_rf, ${ds}_iw_${fa}_rf }" : "${ds}_iw_${fa}_rf"],
      [["${ds}_rf_rd_addr_b", $rf_total_addr_sz], 
        $shadow_present ?  "{ ${ds}_regset_rf, ${ds}_iw_${fb}_rf }" : "${ds}_iw_${fb}_rf"],



      [["E_src1_corrupt", 1], 
        $rf_ecc_present ? 
          "(E_rf_a_raw_recoverable_ecc_err & W_config_reg_eccen) | 
           (E_rf_a_raw_unrecoverable_ecc_err & W_ecc_exc_enabled) | 
           E_iw_corrupt" : 
        $ecc_present ? "E_iw_corrupt" : 
          "0"],
      [["E_src2_corrupt", 1], 
        $rf_ecc_present ? 
          "(E_rf_b_raw_recoverable_ecc_err & W_config_reg_eccen) | 
           (E_rf_b_raw_unrecoverable_ecc_err & W_ecc_exc_enabled) |
           E_iw_corrupt" : 
        $ecc_present ? "E_iw_corrupt" : 
          "0"],
    );

    e_register->adds(

      {out => ["M_src1_corrupt", 1, 0, $force_never_export], 
       in => "E_src1_corrupt",                      enable => "M_en"},
      {out => ["M_src2_corrupt", 1, 0, $force_never_export], 
       in => "E_src2_corrupt",                      enable => "M_en"},
    );

    my @rf_wr_port_en_inputs = "A_wr_dst_reg";
    my @rf_wr_port_addr_mux_table;

    if ($rf_ecc_present) {


      push(@rf_wr_port_addr_mux_table,
        "A_rf_valid_recoverable_ecc_err" => "A_rf_rd_addr"
      );



      push(@rf_wr_port_en_inputs, "A_rf_valid_recoverable_ecc_err");
    }
    
    push (@rf_wr_port_addr_mux_table,
      "1'b1" => ($shadow_present ? "{ A_dst_regset, A_dst_regnum }" : "A_dst_regnum")
    );

    e_mux->adds({
      lhs => ["rf_wr_port_addr", $rf_total_addr_sz],
      type => "priority",
      table => \@rf_wr_port_addr_mux_table,
    });

    e_assign->adds(

      [["rf_a_rd_port_addr", $rf_total_addr_sz], "${ds}_rf_rd_addr_a"],
      [["rf_b_rd_port_addr", $rf_total_addr_sz], "${ds}_rf_rd_addr_b"],
      [["rf_wr_port_data", $datapath_sz], "A_wr_data_filtered"],
      [["rf_wr_port_en", 1], join("|", @rf_wr_port_en_inputs)],




      [["D_rf_a", $datapath_sz], "rf_a_rd_port_data"],
      [["D_rf_b", $datapath_sz], "rf_b_rd_port_data"],
    );

    my $rf_ram_a_fname = $Opt->{name} . "_rf_ram_a";


    if (manditory_bool($Opt, "use_designware")) {
        e_comment->add({
          comment => 
            "BCM58 part used to replace register bank a\n",
        });

        e_blind_instance->add({
          name                     => $Opt->{name} . "_register_bank_a",
          module                   => "DWC_n2p_bcm58",
          use_sim_models           => 1,
          in_port_map              => {
            addr_r   => "${ds}_rf_rd_addr_a",
            addr_w   => "A_rf_wr_addr",
            clk_r    => "clk",
            clk_w    => "clk",
            data_w   => "A_wr_data_filtered",
            en_r_n   => qq(1'b0),
            en_w_n   => "~A_wr_dst_reg",
            init_r_n => qq(1'b1),
            init_w_n => qq(1'b1),
            rst_r_n  => "reset_n",
            rst_w_n  => "reset_n"
          },
          out_port_map             => {
            data_r       => "D_rf_a",
            data_r_a     => ""
          },
          parameter_map            => {
            ADDR_WIDTH => $rf_total_addr_sz,
            WIDTH      => $datapath_sz,
            DEPTH      => ($rf_num_reg * $rf_num_set),
            MEM_MODE   => 2,
            RST_MODE   => 0,
          },
        });
    } else {
        nios_sdp_ram->add({
          name => $Opt->{name} . "_register_bank_a",
          Opt                     => $Opt,
          data_width              => $datapath_sz,
          address_width           => $rf_total_addr_sz,
          num_words               => ($rf_num_reg * $rf_num_set),
          contents_file           => $rf_ram_a_fname,
          read_during_write_mode_mixed_ports => qq("OLD_DATA"),
          ram_block_type          => qq("$Opt->{register_file_ram_type}"),
          ecc_present             => $rf_ecc_present,
          provide_injected_data   => $rf_ecc_present,
          verification            => $ecc_test_ports_present,
          port_map                => $rf_a_port_map,
        });
    }

    my $do_build_sim = manditory_bool($Opt, "do_build_sim");
    my $simulation_directory = $do_build_sim ? 
        not_empty_scalar($Opt, "simulation_directory") : undef;

    my $reg_initial_value = "deadbeef";

    if ($rf_ecc_present) {
        $reg_initial_value = "7f" . $reg_initial_value;
    }

    make_contents_file_for_ram({
      filename_no_suffix        => $rf_ram_a_fname,
      data_sz                   => $datapath_sz,
      ecc_present               => $rf_ecc_present,
      num_entries               => ($rf_num_reg * $rf_num_set), 
      value_str                 => $reg_initial_value,
      clear_hdl_sim_contents    => 0,
      do_build_sim              => $do_build_sim,
      simulation_directory      => $simulation_directory,
      system_directory          => not_empty_scalar($Opt, "system_directory"),
    });

    my $rf_ram_b_fname = $Opt->{name} . "_rf_ram_b";


    if (manditory_bool($Opt, "use_designware")) {
        e_comment->add({
          comment => 
            "BCM58 part used to replace register bank b\n",
        });

        e_blind_instance->add({
          name                     => $Opt->{name} . "_register_bank_b",
          module                   => "DWC_n2p_bcm58",
          use_sim_models           => 1, 
          in_port_map              => {
            addr_r   => "${ds}_rf_rd_addr_b",
            addr_w   => "A_rf_wr_addr",
            clk_r    => "clk",
            clk_w    => "clk",
            data_w   => "A_wr_data_filtered",
            en_r_n   => qq(1'b0),
            en_w_n   => "~A_wr_dst_reg",
            init_r_n => qq(1'b1),
            init_w_n => qq(1'b1),
            rst_r_n  => "reset_n",
            rst_w_n  => "reset_n"
          },
          out_port_map             => {
            data_r       => "D_rf_b",
            data_r_a     => ""
          },
          parameter_map            => {
            ADDR_WIDTH => $rf_total_addr_sz,
            WIDTH      => $datapath_sz,
            DEPTH      => ($rf_num_reg * $rf_num_set),
            MEM_MODE   => 2,
            RST_MODE   => 0
          },
        });
    } else {
        nios_sdp_ram->add({
          name => $Opt->{name} . "_register_bank_b",
          Opt                     => $Opt,
          data_width              => $datapath_sz,
          address_width           => $rf_total_addr_sz,
          num_words               => ($rf_num_reg * $rf_num_set),
          contents_file           => $rf_ram_b_fname,
          read_during_write_mode_mixed_ports => qq("OLD_DATA"),
          ram_block_type          => qq("$Opt->{register_file_ram_type}"),
          ecc_present             => $rf_ecc_present,
          verification            => $ecc_test_ports_present,
          port_map                => $rf_b_port_map,
        });
    }

    make_contents_file_for_ram({
      filename_no_suffix        => $rf_ram_b_fname,
      data_sz                   => $datapath_sz,
      ecc_present               => $rf_ecc_present,
      num_entries               => ($rf_num_reg * $rf_num_set), 
      value_str                 => $reg_initial_value,
      clear_hdl_sim_contents    => 0,
      do_build_sim              => $do_build_sim,
      simulation_directory      => $simulation_directory,
      system_directory          => not_empty_scalar($Opt, "system_directory"),
    });

    my @src_operands = (
        { divider => "register_file" },
        { radix => "x", signal => "${ds}_iw_${fa}_rf" },
        { radix => "x", signal => "${ds}_iw_${fb}_rf" },
        $shadow_present ? { radix => "x", signal => "${ds}_regset_rf" } : "",
        $shadow_present ? { radix => "x", signal => "D_ctrl_rdprs" } : "",
        $shadow_present ? { radix => "x", signal => $crs } : "",
        $shadow_present ? { radix => "x", signal => $prs } : "",
        { radix => "x", signal => "D_rf_a" },
        { radix => "x", signal => "D_rf_b" },
        { radix => "x", signal => "A_wr_dst_reg" },
        { radix => "x", signal => "A_dst_regnum" },
        $shadow_present ? { radix => "x", signal => "A_dst_regset" } : "",
        { radix => "x", signal => "A_wr_data_unfiltered" },
        { radix => "x", signal => "A_wr_data_filtered" },
        { radix => "x", signal => "W_wr_data" },
        @ecc_waves,
    );

    push(@plaintext_wave_signals, @src_operands);
}




sub 
gen_dtcm_masters
{
    my $Opt = shift;

    my @dtcm_port_hazards;
    my @dtcm_port_hazard_wave_signals;

    for (my $cmi = 0; $cmi < manditory_int($Opt, "num_tightly_coupled_data_masters"); $cmi++) {
        gen_one_dtcm_master($Opt, $cmi);

        push(@dtcm_port_hazards, "E_dtcm${cmi}_port_hazard");
        push(@dtcm_port_hazard_wave_signals, 
          { radix => "x", signal => "E_dtcm${cmi}_port_hazard"} );
    }

    e_assign->adds(

      ["E_dtcm_port_hazard", join('|', @dtcm_port_hazards)],



















      [["M_dtcm_raw_hazard", 1],
        "M_valid_ignoring_refetch & 
         (
           A_dtcm_st & A_valid & (M_mem_waddr == A_mem_waddr) &
           (
             (M_dtcm_ld & ($dtcm_ecc_present | ((M_mem_byte_en & A_mem_byte_en) != 0))) |
             (M_dtcm_st_non32 & $dtcm_ecc_present)
           )
         )"],



      [["E_dtcm_port_hazard_start_stall", 1], "E_dtcm_port_hazard"],
    




      [["M_dtcm_port_hazard_stop_stall_unqualified", 1], "M_dtcm_port_hazard_pulse"],
    );





    e_register->adds(
      {out => ["M_dtcm_port_hazard_pulse", 1],        
       in => "E_dtcm_port_hazard & M_en",       enable => "1'b1"},
    );

    push(@plaintext_wave_signals, 
      { divider => "Data TCM Stall" },
      { radix => "x", signal => "E_dtcm_port_hazard"},
      { radix => "x", signal => "M_dtcm_port_hazard_pulse"},
      { radix => "x", signal => "M_dtcm_raw_hazard"},
      { radix => "x", signal => "A_mem_stall"},
      @dtcm_port_hazard_wave_signals
    );
}

sub 
gen_one_dtcm_master
{
    my $Opt = shift;
    my $cmi = shift;

    my $master_name = "tightly_coupled_data_master_${cmi}";
    my $slave_addr_width = $Opt->{$master_name}{Slave_Address_Width};
    my $master_addr_width = $Opt->{$master_name}{Address_Width};
    my $dtcm_data_sz = $dtcm_ecc_present ? 39 :32;

    my %port_map = (
      "dtcm${cmi}_readdata"       => "readdata",
      "dtcm${cmi}_address"        => "address",
      "dtcm${cmi}_read"           => "read",
      "dtcm${cmi}_write"          => "write",
      "dtcm${cmi}_clken"          => "clken",
      "dtcm${cmi}_writedata"      => "writedata",
    );
    
    my @port_list = (
      ["dtcm${cmi}_readdata"      => $dtcm_data_sz,           "in" ],
      ["dtcm${cmi}_address"       => $master_addr_width,      "out"],
      ["dtcm${cmi}_read"          => 1,                       "out"],
      ["dtcm${cmi}_write"         => 1,                       "out"],
      ["dtcm${cmi}_clken"         => 1,                       "out"],
      ["dtcm${cmi}_writedata"     => $dtcm_data_sz,           "out"],
    );

    if (!$dtcm_ecc_present) {
        $port_map{"dtcm${cmi}_byteenable"} = "byteenable";
        push(@port_list, 
          ["dtcm${cmi}_byteenable"    => $byte_en_sz,             "out"],
        );
    }

















    my $E_addr_expr;
    my $M_addr_expr;
    my $A_addr_expr;


    if ($slave_addr_width < $master_addr_width) {


        my $top_bits = not_empty_scalar($Opt->{$master_name}, "Paddr_Base_Top_Bits");

        $E_addr_expr = $dtcm_ecc_present ? "{ 2'b00, $top_bits, E_mem_baddr[$slave_addr_width-1:2] }" : "{ $top_bits, E_mem_baddr[$slave_addr_width-1:0] }";
        $M_addr_expr = $dtcm_ecc_present ? "{ 2'b00, $top_bits, M_mem_baddr[$slave_addr_width-1:2] }" : "{ $top_bits, M_mem_baddr[$slave_addr_width-1:0] }";
        $A_addr_expr = $dtcm_ecc_present ? "{ 2'b00, $top_bits, A_mem_baddr[$slave_addr_width-1:2] }" : "{ $top_bits, A_mem_baddr[$slave_addr_width-1:0] }";;
    } else {
        $E_addr_expr = $dtcm_ecc_present ? "{2'b00, E_mem_baddr[$master_addr_width-1:2]}" : "E_mem_baddr[$master_addr_width-1:0]";
        $M_addr_expr = $dtcm_ecc_present ? "{2'b00, M_mem_baddr[$master_addr_width-1:2]}" : "M_mem_baddr[$master_addr_width-1:0]";
        $A_addr_expr = $dtcm_ecc_present ? "{2'b00, A_mem_baddr[$master_addr_width-1:2]}" : "A_mem_baddr[$master_addr_width-1:0]";
    }


    my $read_expr = $dtcm_ecc_present ? "(E_ctrl_ld | E_ctrl_st_non32)" : "E_ctrl_ld";

    e_assign->adds(







      [["E_dtcm${cmi}_port_hazard", 1],
        "A_ctrl_st & A_st_writes_mem & A_valid & A_sel_${master_name} &
         $read_expr & E_valid & E_sel_${master_name}"],
    );




    my $dtcm_ecc_correct = "";
    my $dtcm_ecc_correct_write = "";
    if ($dtcm_ecc_present) {
        
        nios_ecc_decoder->add({
          name => $Opt->{name} . "_tightly_coupled_data_master_${cmi}_ecc_decoder",
          codeword_width          => 39,
          dataword_width          => 32,
          standalone_decoder      => 1,
          correct_parity          => 1,
          port_map => {
            data          => "dtcm${cmi}_readdata",
            q             => "dtcm${cmi}_rd_data",
            one_bit_err   => "dtcm${cmi}_rd_one_bit_err",
            two_bit_err   => "dtcm${cmi}_rd_two_bit_err",
            corrected_data => "dtcm${cmi}_rd_corrected_data",
            one_two_or_three_bit_err     => "dtcm${cmi}_rd_one_two_three_bit_err",
          },
        });
        

        nios_ecc_encoder->add({
          name => $Opt->{name} . "_tightly_coupled_data_master_${cmi}_ecc_encoder",
          codeword_width          => 39,
          dataword_width          => 32,
          port_map => {
            data          => "dtcm${cmi}_wr_data",
            q             => "dtcm${cmi}_writedata",
            injs          => "dtcm${cmi}_wr_injs",
            injd          => "dtcm${cmi}_wr_injd",
            wrsel         => "dtcm${cmi}_wr_wrsel",
            corrected_data => "dtcm${cmi}_wr_corrected_data",
            test_invert   => "dtcm${cmi}_wr_test_invert",
          },
        });

        e_assign->adds(

            [["dtcm${cmi}_wr_injs", 1], "W_dtcm${cmi}_injs"],
            [["dtcm${cmi}_wr_injd", 1], "W_dtcm${cmi}_injd"],
            

            [["M_dtcm${cmi}_raw_recoverable_correct_ecc_err", 1], 
             "(M_dtcm_ld | M_dtcm_st_non32) & dtcm${cmi}_rd_one_bit_err & M_valid & M_sel_tightly_coupled_data_master_${cmi}"],
            [["M_dtcm${cmi}_raw_unrecoverable_ecc_err", 1], 
             "(M_dtcm_ld | M_dtcm_st_non32) & dtcm${cmi}_rd_two_bit_err & M_valid & M_sel_tightly_coupled_data_master_${cmi} & ~pending_dtcm_unrecoverable_ecc_err "],
            [["M_dtcm${cmi}_raw_any_ecc_err", 1], 
             "(M_dtcm_ld | M_dtcm_st_non32) & dtcm${cmi}_rd_one_two_three_bit_err & M_sel_tightly_coupled_data_master_${cmi}"],

            [["M_dtcm${cmi}_ecc_correct_the_data", 1], 
            "W_config_reg_eccen & M_dtcm${cmi}_raw_recoverable_correct_ecc_err"],
            
            [["dtcm${cmi}_wr_wrsel", 1], "A_dtcm${cmi}_ecc_correct_the_data"],
             
            [["M_dtcm${cmi}_corrected_data", 32], "dtcm${cmi}_rd_corrected_data"],
            [["dtcm${cmi}_wr_corrected_data", 32], "A_dtcm${cmi}_corrected_data"],
        );

        e_register->adds(

          {out => ["A_dtcm${cmi}_ecc_event_recoverable_err", 1], 
           in => "M_dtcm${cmi}_raw_recoverable_correct_ecc_err",
           enable => "A_en"},
          {out => ["A_dtcm${cmi}_raw_unrecoverable_ecc_err", 1], 
           in => "M_dtcm${cmi}_raw_unrecoverable_ecc_err", 
           enable => "A_en"},


          {out => ["A_dtcm${cmi}_ecc_correct_the_data", 1], 
           in => "M_dtcm${cmi}_ecc_correct_the_data", enable => "A_en"},
          {out => ["A_dtcm${cmi}_corrected_data", 32], 
           in => "M_dtcm${cmi}_corrected_data", enable => "A_en"},
        );
        
        if ($ecc_test_ports_present) {
           e_register->adds(
              {out => ["ecc_test_dtcm${cmi}_valid_d1", 1], 
               in => "ecc_test_dtcm${cmi}_valid & dtcm${cmi}_write",
               enable => "1'b1"},
           );
           e_assign->adds(
               [["ecc_test_dtcm${cmi}_ready", 1], 
                 "~ecc_test_dtcm${cmi}_valid | ecc_test_dtcm${cmi}_valid_d1"],
               [["dtcm${cmi}_wr_test_invert", 39],
                 "ecc_test_dtcm${cmi}[38:0]"],
           );
        } else {
            e_assign->adds(
               [["dtcm${cmi}_wr_test_invert", 39],
                 "{39{1'b0}}"],
           );
        }

        e_register->adds(
          {out => ["A_dtcm${cmi}_readdata", $datapath_sz],        
           in => "dtcm${cmi}_rd_data",
           enable => "A_en"},
        );

        my $readdata = "A_dtcm${cmi}_readdata";

        e_assign->adds(



          [["dtcm${cmi}_wr_data", $datapath_sz], "{ 
             A_mem_byte_en[3] ? A_st_data[31:24] : ${readdata}\[31:24\],
             A_mem_byte_en[2] ? A_st_data[23:16] : ${readdata}\[23:16\],
             A_mem_byte_en[1] ? A_st_data[15:8]  : ${readdata}\[15:8\],
             A_mem_byte_en[0] ? A_st_data[7:0]   : ${readdata}\[7:0\]
            }"],
        );
        
        $dtcm_ecc_correct = "A_dtcm${cmi}_ecc_correct_the_data ? $A_addr_expr :";
        $dtcm_ecc_correct_write = "A_dtcm${cmi}_ecc_correct_the_data | ";
    } else {
        e_assign->adds(
          [["dtcm${cmi}_writedata", $datapath_sz], "A_st_data"],




          [["dtcm${cmi}_byteenable", $byte_en_sz], 
            "M_dtcm_port_hazard_pulse ? M_mem_byte_en : 
             A_dtcm${cmi}_want_wr     ? A_mem_byte_en :
                                        E_mem_byte_en"],
        );
    }

    e_assign->adds(


      [["A_dtcm${cmi}_want_wr", 1], "A_ctrl_st & A_st_writes_mem & A_valid & A_sel_${master_name}"],




      [["dtcm${cmi}_address", $master_addr_width],  $dtcm_ecc_correct . "M_dtcm_port_hazard_pulse ? $M_addr_expr : 
                                                    A_dtcm${cmi}_want_wr     ? $A_addr_expr : 
                                                                               $E_addr_expr"],





      [["dtcm${cmi}_write", 1], "(" . $dtcm_ecc_correct_write . "A_dtcm${cmi}_want_wr) & ~M_dtcm_port_hazard_pulse"],

      [["dtcm${cmi}_read", 1], "1'b1"],   # Always read to prevent bad timing from E_sel_* signal.



      [["dtcm${cmi}_clken", 1], "A_en | M_dtcm_port_hazard_pulse"],
    );

    $Opt->{$master_name}{port_map} = \%port_map;
    $Opt->{$master_name}{sideband_signals} = [ "clken" ];
    push(@{$Opt->{port_list}}, @port_list);
}






sub 
gen_data_master
{
    my $Opt = shift;
    my $dcache_stall_info = shift;

    my $data_master_interrupt_sz = manditory_int($Opt, "data_master_interrupt_sz");




    $Opt->{data_master}{port_map} = {
      clk             => "clk",
      reset_n         => "reset_n",
      d_readdata      => "readdata",
      d_waitrequest   => "waitrequest",
      d_writedata     => "writedata",
      d_address       => "address",
      d_byteenable    => "byteenable",
      d_read          => "read",
      d_write         => "write",

      debug_mem_slave_debugaccess_to_roms  => "debugaccess",
    };

    if ($dcache_present) {

        $Opt->{data_master}{port_map}{d_readdatavalid} = "readdatavalid";
    }

    if ($dmaster_bursts) {
        $Opt->{data_master}{port_map}{d_burstcount} = "burstcount";
    }

    if (!$eic_present) {
        $Opt->{data_master}{port_map}{irq} = "irq";
    }

    my $data_master_addr_sz = $Opt->{data_master}{Address_Width};

    push(@{$Opt->{port_list}},
      [clk              => 1,                           "in" ],
      [reset_n          => 1,                           "in" ],
      [d_readdata       => $datapath_sz,                "in" ],
      [d_waitrequest    => 1,                           "in" ],
      [d_address        => $data_master_addr_sz,        "out"],
      [d_byteenable     => $byte_en_sz,                 "out"],
      [d_read           => 1,                           "out"],
      [d_write          => 1,                           "out"],
      [d_writedata      => $datapath_sz,                "out"],
    );

    if ($dcache_present) {
        push(@{$Opt->{port_list}},
          [d_readdatavalid  => 1,                 "in" ],
        );
    }

    if ($dmaster_bursts) {
        push(@{$Opt->{port_list}},
          [d_burstcount     => $dmaster_burstcount_sz,  "out"],
        );
    }

    if (!$eic_present) {
        push(@{$Opt->{port_list}},
          [irq            => $data_master_interrupt_sz,   "in" ],
        );
    }


    e_register->adds(
      {out => ["d_read", 1],                        in => "d_read_nxt",    
       enable => "1'b1"},
      {out => ["d_write", 1],                       in => "d_write_nxt",    
       enable => "1'b1"},
      {out => ["d_readdata_d1", $datapath_sz],      in => "d_readdata",
       enable => "1'b1"},
    );


    my @stall_start;
    my @stall_stop;

    if ($dcache_present) {
        e_register->adds(

          {out => ["d_readdatavalid_d1", 1],            in => "d_readdatavalid",
           enable => "1'b1"},
        );


        push(@stall_start, @{manditory_array($dcache_stall_info, "stall_start")});
        push(@stall_stop, @{manditory_array($dcache_stall_info, "stall_stop")});
    } else {







        my $data_master_addr_msb = $data_master_addr_sz > 1 ? $data_master_addr_sz - 1 : $data_master_addr_sz;

        if ($mmu_present) {
            e_assign->adds(
              [["d_address", $data_master_addr_sz],
                "A_mem_baddr_phy[$data_master_addr_msb:0]"],
            );
        } else {
            e_assign->adds(
              [["d_address", $data_master_addr_sz],
                "A_mem_baddr[$data_master_addr_msb:0]"],
            );
        }

        e_assign->adds(

          [["av_start_rd", 1], "M_ctrl_ld & M_valid & M_sel_data_master & A_en"],
    


          [["d_read_nxt", 1], "av_start_rd | (d_read & d_waitrequest)"],
    

          [["av_start_wr", 1], "M_ctrl_st & M_st_writes_mem & M_valid & M_sel_data_master & A_en"],
    


          [["d_write_nxt", 1], "av_start_wr | (d_write & d_waitrequest)"],


          [["d_writedata", $datapath_sz], "A_st_data"],
          [["d_byteenable", $byte_en_sz], "A_mem_byte_en"],



          [["A_st_done", 1], "~d_waitrequest"],



          [["av_ld_data_transfer", 1], "d_read & ~d_waitrequest"],





          [["A_ld_done", 1], 
            "A_ctrl_ld32 ? av_ld_data_transfer : av_ld_aligning_data"],



          [["M_data_master_start_stall", 1], 
            "A_en & (M_ctrl_ld_st & M_valid & M_sel_data_master)"],


          [["A_data_master_stop_stall", 1], 
            "A_data_master_started_stall & (A_ctrl_st ? A_st_done : A_ld_done)"],
        );

        push(@stall_start, "M_data_master_start_stall");
        push(@stall_stop, "A_data_master_stop_stall");

        e_register->adds(
          {out => ["A_data_master_started_stall", 1],              
           in => "M_data_master_start_stall",       enable => "A_en"},



          {out => ["av_ld_aligning_data", 1], in => "av_ld_data_transfer",
           enable => "1'b1"},
        );



        $perf_cnt_inc_rd_stall = "(d_read & A_mem_stall)";
        $perf_cnt_inc_wr_stall = "(d_write & A_mem_stall)";
    }


    if ($dtcm_present) {

        e_register->adds(
          {out => ["A_mem_stall_start_everyone_but_dtcm_port_hazard", 1], 
           in => join('|', @stall_start),
           enable => "A_en"},
        );


        push(@stall_start, "E_dtcm_port_hazard_start_stall");






        push(@stall_stop, 
          "(M_dtcm_port_hazard_stop_stall_unqualified &
            ~A_mem_stall_start_everyone_but_dtcm_port_hazard)");
    }




    e_assign->adds(


      [["A_mem_stall_start_nxt", 1], "A_en & (" . join('|', @stall_start) . ")"],



      [["A_mem_stall_stop_nxt", 1], join('|', @stall_stop)],



      [["A_mem_stall_nxt", 1], "A_mem_stall ? ~A_mem_stall_stop_nxt : A_mem_stall_start_nxt"],
    );

    e_register->adds(
      {out => ["A_mem_stall", 1],              
       in => "A_mem_stall_nxt",                 enable => "1'b1"},
    );

    my @data_master = (
        { divider => "data_master" },
        { radix => "x", signal => "d_address" },
        { radix => "x", signal => "d_read_nxt" },
        { radix => "x", signal => "d_read" },
        { radix => "x", signal => "d_readdata_d1" },
        $dcache_present ? { radix => "x", signal => "d_readdatavalid_d1" } : "",
        { radix => "x", signal => "d_write_nxt" },
        { radix => "x", signal => "d_write" },
        { radix => "x", signal => "d_writedata" },
        { radix => "x", signal => "d_waitrequest" },
        { radix => "x", signal => "d_byteenable" },
        $dmaster_bursts ? { radix => "x", signal => "d_burstcount" } : "",
        { radix => "x", signal => "A_mem_stall_start_nxt" },
        { radix => "x", signal => "A_mem_stall_stop_nxt" },
        { radix => "x", signal => "A_mem_stall_nxt" },
        { radix => "x", signal => "A_mem_stall" },
    );

    push(@plaintext_wave_signals, @data_master);
}






sub 
gen_slow_ld_aligner
{
    my $Opt = shift;


      e_assign->adds(
        [["A_slow_ld_data_unaligned",32], "d_readdata_d1"],
      );


    e_assign->adds(



      [["A_slow_ld_data_sign_bit_16", 2], 
        "${big_endian_tilde}A_mem_baddr[1]  ? 
          {A_slow_ld_data_unaligned[31], A_slow_ld_data_unaligned[23]} : 
          {A_slow_ld_data_unaligned[15], A_slow_ld_data_unaligned[7]}"],


      [["A_slow_ld_data_fill_bit", 1], 
        "A_slow_ld_data_sign_bit & A_ctrl_ld_signed"],
    );







    if ($big_endian) {
      e_assign->adds(


        [["A_slow_ld_data_sign_bit", 1],
          "((~A_mem_baddr[0]) | A_ctrl_ld16) ? 
              A_slow_ld_data_sign_bit_16[0] : A_slow_ld_data_sign_bit_16[1]"],

        [["A_slow_ld16_data", 16], "(A_ld_align_sh16 | A_ctrl_ld32) ? 
          A_slow_ld_data_unaligned[31:16] :
          A_slow_ld_data_unaligned[15:0]"],
  
        [["A_slow_ld_byte0_data_aligned_nxt", 8], "(A_ctrl_ld8 & ~A_mem_baddr[0]) ? 
          A_slow_ld16_data[7:0] :
          A_slow_ld16_data[15:8]"],

        [["A_slow_ld_byte1_data_aligned_nxt", 8], "A_ld_align_byte1_fill ? 
          {8 {A_slow_ld_data_fill_bit}} : 
          A_slow_ld16_data[7:0]"],

        [["A_slow_ld_byte2_data_aligned_nxt", 8], "A_ld_align_byte2_byte3_fill ? 
          {8 {A_slow_ld_data_fill_bit}} : 
          A_slow_ld_data_unaligned[15:8]"],

        [["A_slow_ld_byte3_data_aligned_nxt", 8], "A_ld_align_byte2_byte3_fill ? 
          {8 {A_slow_ld_data_fill_bit}} : 
          A_slow_ld_data_unaligned[7:0]"],
      );
    } else {
      e_assign->adds(


        [["A_slow_ld_data_sign_bit", 1],
          "((${big_endian_tilde}A_mem_baddr[0]) | A_ctrl_ld16) ? 
              A_slow_ld_data_sign_bit_16[1] : A_slow_ld_data_sign_bit_16[0]"],

        [["A_slow_ld16_data", 16], "A_ld_align_sh16 ? 
          A_slow_ld_data_unaligned[31:16] :
          A_slow_ld_data_unaligned[15:0]"],

        [["A_slow_ld_byte0_data_aligned_nxt", 8], "A_ld_align_sh8 ? 
          A_slow_ld16_data[15:8] :
          A_slow_ld16_data[7:0]"],

        [["A_slow_ld_byte1_data_aligned_nxt", 8], "A_ld_align_byte1_fill ? 
          {8 {A_slow_ld_data_fill_bit}} : 
          A_slow_ld16_data[15:8]"],

        [["A_slow_ld_byte2_data_aligned_nxt", 8], "A_ld_align_byte2_byte3_fill ? 
          {8 {A_slow_ld_data_fill_bit}} : 
          A_slow_ld_data_unaligned[23:16]"],

        [["A_slow_ld_byte3_data_aligned_nxt", 8], "A_ld_align_byte2_byte3_fill ? 
          {8 {A_slow_ld_data_fill_bit}} : 
          A_slow_ld_data_unaligned[31:24]"],
      );
    }

    e_assign->adds(
      [["A_slow_ld_data_aligned_nxt", $datapath_sz],
        "{A_slow_ld_byte3_data_aligned_nxt, A_slow_ld_byte2_data_aligned_nxt, 
          A_slow_ld_byte1_data_aligned_nxt, A_slow_ld_byte0_data_aligned_nxt}"],
    );

    my @slow_ld_aligner = (
      { divider => "A_slow_ld_aligner" },
      { radix => "x", signal => "A_slow_ld_data_unaligned"},
      { radix => "x", signal => "A_slow_ld_data_sign_bit" },
      { radix => "x", signal => "A_slow_ld_data_fill_bit" },
      { radix => "x", signal => "A_slow_ld16_data" },
      { radix => "x", signal => "A_slow_ld_byte0_data_aligned_nxt" },
      { radix => "x", signal => "A_slow_ld_byte1_data_aligned_nxt" },
      { radix => "x", signal => "A_slow_ld_byte2_data_aligned_nxt" },
      { radix => "x", signal => "A_slow_ld_byte3_data_aligned_nxt" },
      { radix => "x", signal => "A_slow_ld_data_aligned_nxt" },
      { radix => "x", signal => "A_slow_inst_result" },
    );

    push(@plaintext_wave_signals, @slow_ld_aligner);
}






sub 
gen_data_ram_ld_aligner
{
    my $Opt = shift;



















    if ($big_endian) {
      e_register->adds(



        {out => ["M_data_ram_ld_align_sign_bit_16_hi", 1],        
        in => "(~E_mem_baddr[0]) | E_ctrl_ld16", 
        enable => "M_en"},
      );
    } else {
      e_register->adds(



        {out => ["M_data_ram_ld_align_sign_bit_16_hi", 1],
        in => "(${big_endian_tilde}E_mem_baddr[0]) | E_ctrl_ld16",
        enable => "M_en"},
      );
    }





    e_assign->adds(

      [["M_data_ram_ld_align_sign_bit_16", 2],
        "${big_endian_tilde}M_mem_baddr[1] ? 
          {M_ram_rd_data[31], M_ram_rd_data[23]} : 
          {M_ram_rd_data[15], M_ram_rd_data[7]}"],
    );

    if ($big_endian) {
      e_assign->adds(

        [["M_data_ram_ld_align_sign_bit", 1], 
          "M_data_ram_ld_align_sign_bit_16_hi ?
            M_data_ram_ld_align_sign_bit_16[0] : 
            M_data_ram_ld_align_sign_bit_16[1]"],
      );
    } else {
      e_assign->adds(

        [["M_data_ram_ld_align_sign_bit", 1], 
          "M_data_ram_ld_align_sign_bit_16_hi ?
            M_data_ram_ld_align_sign_bit_16[1] : 
            M_data_ram_ld_align_sign_bit_16[0]"],
      );
    }

    if ($dcache_present) {


        e_assign->adds(

          [["A_data_ram_ld_align_fill_bit", 1], 
            "A_data_ram_ld_align_sign_bit & A_ctrl_ld_signed"],
        );


        e_register->adds(
          {out => ["A_data_ram_ld_align_sign_bit", 1],        
           in => "M_data_ram_ld_align_sign_bit", enable => "A_en"},
        );
    } else {


        e_assign->adds(

          [["M_data_ram_ld_align_fill_bit", 1], 
            "M_data_ram_ld_align_sign_bit & M_ctrl_ld_signed"],
        );


        e_register->adds(
          {out => ["A_data_ram_ld_align_fill_bit", 1],        
           in => "M_data_ram_ld_align_fill_bit", enable => "A_en"},
        );
    }
















    if ($big_endian) {
      e_assign->adds(
        [["A_data_ram_ld16_data", 16], "(A_ld_align_sh16 | A_ctrl_ld32) ? 
          A_inst_result[31:16] :
          A_inst_result[15:0]"],

        [["A_data_ram_ld32_data", 16], " A_ctrl_ld32 ? 
          {A_inst_result[7:0],A_inst_result[15:8]} :
          A_inst_result[31:16]"],

        [["A_data_ram_ld_byte0_data", 8], "((A_ctrl_ld8 & ~A_mem_baddr[0]) | ~A_ctrl_ld) ? 
          A_data_ram_ld16_data[7:0] :
          A_data_ram_ld16_data[15:8]"],

        [["A_data_ram_ld_byte1_data", 8], "A_ld_align_byte1_fill ? 
          {8 {A_data_ram_ld_align_fill_bit}} : ~A_ctrl_ld ?
          A_data_ram_ld16_data[15:8] : A_data_ram_ld16_data[7:0]"],

        [["A_data_ram_ld_byte2_data", 8], "A_ld_align_byte2_byte3_fill ? 
          {8 {A_data_ram_ld_align_fill_bit}} : 
          A_data_ram_ld32_data[7:0]"],

        [["A_data_ram_ld_byte3_data", 8], "A_ld_align_byte2_byte3_fill ? 
          {8 {A_data_ram_ld_align_fill_bit}} : 
          A_data_ram_ld32_data[15:8]"],
      );
    } else {
      e_assign->adds(
        [["A_data_ram_ld16_data", 16], "A_ld_align_sh16 ? 
          A_inst_result[31:16] :
          A_inst_result[15:0]"],
        
        [["A_data_ram_ld_byte0_data", 8], "A_ld_align_sh8 ? 
          A_data_ram_ld16_data[15:8] :
          A_data_ram_ld16_data[7:0]"],

        [["A_data_ram_ld_byte1_data", 8], "A_ld_align_byte1_fill ? 
          {8 {A_data_ram_ld_align_fill_bit}} : 
          A_data_ram_ld16_data[15:8]"],

        [["A_data_ram_ld_byte2_data", 8], "A_ld_align_byte2_byte3_fill ? 
          {8 {A_data_ram_ld_align_fill_bit}} : 
          A_inst_result[23:16]"],

        [["A_data_ram_ld_byte3_data", 8], "A_ld_align_byte2_byte3_fill ? 
          {8 {A_data_ram_ld_align_fill_bit}} : 
          A_inst_result[31:24]"],
      );
    }



    e_assign->adds(
      [["A_inst_result_aligned", $datapath_sz], 
        "{A_data_ram_ld_byte3_data, A_data_ram_ld_byte2_data, 
          A_data_ram_ld_byte1_data, A_data_ram_ld_byte0_data}"],
      );

    my @wave_signals = (
      { divider => "data_ram_ld_aligner" },
      { radix => "x", signal => "M_ctrl_ld16" },
      { radix => "x", signal => "M_mem_baddr\\[1\\]" },
      { radix => "x", signal => "M_mem_baddr\\[0\\]" },
      { radix => "x", signal => "M_data_ram_ld_align_sign_bit" },
      { radix => "x", signal => "A_data_ram_ld_align_fill_bit" },
      { radix => "x", signal => "A_data_ram_ld_byte0_data" },
      { radix => "x", signal => "A_data_ram_ld_byte1_data" },
      { radix => "x", signal => "A_data_ram_ld_byte2_data" },
      { radix => "x", signal => "A_data_ram_ld_byte3_data" },
      { radix => "x", signal => "A_inst_result_aligned" },
    );

    push(@plaintext_wave_signals, @wave_signals);
}





sub 
make_custom_instruction_master
{
    my $Opt = shift;


    be_make_custom_instruction_master($Opt); 

    if (nios2_custom_insts::has_multi_insts($Opt->{custom_instructions})) {

        e_register->adds(

          {out => ["A_ci_multi_src1", $datapath_sz], in => "M_src1", 
           enable => "A_en"},
          {out => ["A_ci_multi_src2", $datapath_sz], in => "M_src2", 
           enable => "A_en"},




          {out => ["A_ci_multi_stall", 1], 
           in => "A_ci_multi_stall ? ~A_ci_multi_done : 
             (M_ctrl_custom_multi & M_valid & A_en)",
           enable => "1'b1"},



          {out => ["A_ci_multi_start", 1], 
           in => "A_ci_multi_start ? 1'b0 : 
             (M_ctrl_custom_multi & M_valid & A_en)",
           enable => "1'b1"},
        );




        e_assign->add([["A_ci_multi_clk_en", 1], "A_ci_multi_stall"]);
        e_assign->add([["A_ci_multi_clock", 1], "clk"]);
        e_assign->add([["A_ci_multi_reset", 1], "~reset_n"]);
        e_assign->add([["A_ci_multi_reset_req", 1], "reset_req"]);
    }
}





sub 
make_reg_cmp
{
    my $Opt = shift;

    my $ds = not_empty_scalar($Opt, "dispatch_stage");
    



    e_assign->adds(
      [["D_regnum_a_cmp_${ds}", 1], "(F_iw_a == D_dst_regnum) & D_wr_dst_reg"],
      [["E_regnum_a_cmp_${ds}", 1], "(F_iw_a == E_dst_regnum) & E_wr_dst_reg"],
      [["M_regnum_a_cmp_${ds}", 1], "(F_iw_a == M_dst_regnum) & M_wr_dst_reg"],
      [["A_regnum_a_cmp_${ds}", 1], "(F_iw_a == A_dst_regnum) & A_wr_dst_reg"],

      [["D_regnum_b_cmp_${ds}", 1], "(F_iw_b == D_dst_regnum) & D_wr_dst_reg"],
      [["E_regnum_b_cmp_${ds}", 1], "(F_iw_b == E_dst_regnum) & E_wr_dst_reg"],
      [["M_regnum_b_cmp_${ds}", 1], "(F_iw_b == M_dst_regnum) & M_wr_dst_reg"],
      [["A_regnum_b_cmp_${ds}", 1], "(F_iw_b == A_dst_regnum) & A_wr_dst_reg"],
      );






    e_register->adds(
      {out => ["E_regnum_a_cmp_D", 1],          
       in => "D_en ? D_regnum_a_cmp_${ds} : 1'b0",             
       enable => "E_en"},
      {out => ["M_regnum_a_cmp_D", 1],          
       in => "D_en ? E_regnum_a_cmp_${ds} : E_regnum_a_cmp_D", 
       enable => "M_en"},
      {out => ["A_regnum_a_cmp_D", 1],          
       in => "D_en ? M_regnum_a_cmp_${ds} : M_regnum_a_cmp_D", 
       enable => "A_en"},
      {out => ["W_regnum_a_cmp_D", 1],          
       in => "D_en ? A_regnum_a_cmp_${ds} : A_regnum_a_cmp_D", 
       enable => "1'b1"},
      {out => ["E_regnum_b_cmp_D", 1],          
       in => "D_en ? D_regnum_b_cmp_${ds} : 1'b0",             
       enable => "E_en"},
      {out => ["M_regnum_b_cmp_D", 1],          
       in => "D_en ? E_regnum_b_cmp_${ds} : E_regnum_b_cmp_D", 
       enable => "M_en"},
      {out => ["A_regnum_b_cmp_D", 1],          
       in => "D_en ? M_regnum_b_cmp_${ds} : M_regnum_b_cmp_D", 
       enable => "A_en"},
      {out => ["W_regnum_b_cmp_D", 1],          
       in => "D_en ? A_regnum_b_cmp_${ds} : A_regnum_b_cmp_D", 
       enable => "1'b1"},



      {out => ["E_src1_from_rf", 1, 0, $force_never_export],
       in => "~(D_src1_choose_E | D_src1_choose_M | D_src1_choose_A | D_src1_choose_W)",
       enable => "E_en"},
      {out => ["E_src2_from_rf", 1, 0, $force_never_export],
       in => "~(D_src2_choose_E | D_src2_choose_M | D_src2_choose_A | D_src2_choose_W)",
       enable => "E_en"},
      );





    e_assign->adds(

      [["D_ctrl_a_is_src", 1], "~D_ctrl_a_not_src"],
      [["D_ctrl_b_is_src", 1], "~D_ctrl_b_not_src"],
      [["E_ctrl_a_is_src", 1, 0, $force_never_export], "~E_ctrl_a_not_src"],
      [["E_ctrl_b_is_src", 1, 0, $force_never_export], "~E_ctrl_b_not_src"],





      [["D_src1_hazard_E", 1], "E_regnum_a_cmp_D & D_ctrl_a_is_src"],
      [["D_src1_hazard_M", 1], "M_regnum_a_cmp_D & D_ctrl_a_is_src"],
      [["D_src1_hazard_A", 1], "A_regnum_a_cmp_D & D_ctrl_a_is_src"],
      [["D_src1_hazard_W", 1], "W_regnum_a_cmp_D & D_ctrl_a_is_src"],
    
      [["D_src2_hazard_E", 1], "E_regnum_b_cmp_D & D_ctrl_b_is_src"],
      [["D_src2_hazard_M", 1], "M_regnum_b_cmp_D & D_ctrl_b_is_src"],
      [["D_src2_hazard_A", 1], "A_regnum_b_cmp_D & D_ctrl_b_is_src"],
      [["D_src2_hazard_W", 1], "W_regnum_b_cmp_D & D_ctrl_b_is_src"],



      [["D_src1_other_rs", 1], 
        $shadow_present ?
          "D_ctrl_rdprs & (W_status_reg_crs != W_status_reg_prs)" :
          "0"],








      [["D_src1_choose_E", 1], "D_src1_hazard_E & ~D_src1_other_rs"],
      [["D_src1_choose_M", 1], "D_src1_hazard_M & ~D_src1_other_rs"],
      [["D_src1_choose_A", 1], "D_src1_hazard_A & ~D_src1_other_rs"],
      [["D_src1_choose_W", 1], "D_src1_hazard_W & ~D_src1_other_rs"],
    

      [["D_src2_choose_E", 1], "D_src2_hazard_E"],
      [["D_src2_choose_M", 1], "D_src2_hazard_M"],
      [["D_src2_choose_A", 1], "D_src2_hazard_A"],
      [["D_src2_choose_W", 1], "D_src2_hazard_W"],






      [["D_data_depend", 1], 
        "((D_src1_hazard_E | D_src2_hazard_E) & E_ctrl_late_result) |
         ((D_src1_hazard_M | D_src2_hazard_M) & M_ctrl_late_result)"],










      [["D_dstfield_regnum", $regnum_sz], "D_ctrl_b_is_dst ? D_iw_b : D_iw_c"],

      [["D_dst_regnum", $regnum_sz], 
        "D_ctrl_implicit_dst_retaddr ? $retaddr_regnum : 
         D_ctrl_implicit_dst_eretaddr ? $eretaddr_regnum : 
         D_dstfield_regnum"],

      [["D_wr_dst_reg", 1], 
        "(D_dst_regnum != 0) & ~D_ctrl_ignore_dst & D_valid"],
    );

    my @reg_cmp = (
        { divider => "reg_cmp" },
        { radix => "x", signal => "E_regnum_a_cmp_D" },
        { radix => "x", signal => "M_regnum_a_cmp_D" },
        { radix => "x", signal => "A_regnum_a_cmp_D" },
        { radix => "x", signal => "W_regnum_a_cmp_D" },
        { radix => "x", signal => "E_regnum_b_cmp_D" },
        { radix => "x", signal => "M_regnum_b_cmp_D" },
        { radix => "x", signal => "A_regnum_b_cmp_D" },
        { radix => "x", signal => "W_regnum_b_cmp_D" },
        { radix => "x", signal => "D_ctrl_a_is_src" },
        { radix => "x", signal => "D_ctrl_b_is_src" },
        { radix => "x", signal => "D_ctrl_ignore_dst" },
        { radix => "x", signal => "D_ctrl_src2_choose_imm" },
        { radix => "x", signal => "D_src1_other_rs" },
        { radix => "x", signal => "D_data_depend" },
        { radix => "x", signal => "D_dstfield_regnum" },
        { radix => "x", signal => "D_dst_regnum" },
        { radix => "x", signal => "D_wr_dst_reg" },
        { radix => "x", signal => "E_ctrl_late_result" },
        { radix => "x", signal => "M_ctrl_late_result" },
      );

    push(@plaintext_wave_signals, @reg_cmp);
}




sub 
make_src_operands
{
    my $Opt = shift;

    my $cpu_arch_rev = manditory_int($Opt, "cpu_arch_rev");
    my $r1 = ($cpu_arch_rev == 1);
    my $r2 = ($cpu_arch_rev == 2);
    

    e_assign->adds(
      [["E_fwd_reg_data", $datapath_sz], "E_alu_result"],
    );




    e_mux->add ({
      lhs => ["D_src1_reg", $datapath_sz],
      type => "priority",
      table => [
        "D_iw_a == 0"       => "32'b0",
        "D_src1_choose_E"   => "E_fwd_reg_data",
        "D_src1_choose_M"   => "M_fwd_reg_data",
        "D_src1_choose_A"   => "A_fwd_reg_data",
        "D_src1_choose_W"   => "W_wr_data",
        "1'b1"              => "D_rf_a",
        ],
      });

    e_assign->adds(
      [["D_src1", $datapath_sz], "D_src1_reg"],
      );







    e_mux->add ({
      lhs => ["D_src2_reg", $datapath_sz],
      type => "priority",
      table => [
        "D_iw_b == 0"       => "32'b0",
        "D_src2_choose_E"   => "E_fwd_reg_data",
        "D_src2_choose_M"   => "M_fwd_reg_data",
        "D_src2_choose_A"   => "A_fwd_reg_data",
        "D_src2_choose_W"   => "W_wr_data",
        "1'b1"              => "D_rf_b",
        ],
      });



    e_assign->adds(
      [["D_src2_imm16_sel", 2], "{D_ctrl_hi_imm16,D_ctrl_unsigned_lo_imm16}"],
      );


    my $imm16_sex_datapath_sz = $datapath_sz - 16;    

    e_mux->add ({
      lhs => ["D_src2_imm16", $datapath_sz],
      selecto => "D_src2_imm16_sel",
      table => [
        "2'b00" => "{{$imm16_sex_datapath_sz {D_iw_imm16[15]}}         , D_iw_imm16                    }",
        "2'b01" => "{{$imm16_sex_datapath_sz {D_ctrl_set_src2_rem_imm}}, D_iw_imm16                    }",
        "2'b10" => "{D_iw_imm16                                        , {16 {D_ctrl_set_src2_rem_imm}}}",
        "2'b11" => "{{$imm16_sex_datapath_sz {1'b0}}                   , 16'b0                         }",
        ],
      });
    

    if ($r2) {


        e_assign->adds(
          [["D_src2_imm12_5_sel", 2], "{D_ctrl_signed_imm12,D_ctrl_src_imm5_shift_rot}"],
          );
        

        my $imm12_sex_datapath_sz = $datapath_sz - 12;
        my $imm5_datapath_sz = $datapath_sz - 5;
        
        e_mux->add ({
          lhs => ["D_src2_imm", $datapath_sz],
          selecto => "D_src2_imm12_5_sel",
          table => [
            "2'b01" => "{{$imm5_datapath_sz {1'b0}}, D_iw_imm5}",
            "2'b10" => "{{$imm12_sex_datapath_sz {D_iw_imm12[11]}}, D_iw_imm12}",
            "2'b11" => "D_src2_imm16",
            ],
          });
    } else {
        e_assign->adds(
          [["D_src2_imm5_sel", 1], "D_ctrl_src_imm5_shift_rot"],
          );
        
        my $imm5_datapath_sz = $datapath_sz - 5;
        
        e_mux->add ({
          lhs => ["D_src2_imm", $datapath_sz],
          selecto => "D_src2_imm5_sel",
          table => [
            "1'b1" => "{{$imm5_datapath_sz {1'b0}}, D_iw_imm5}",
            "1'b0" => "D_src2_imm16",
            ],
          });
    }


    e_assign->adds(
      [["D_src2", $datapath_sz],
        "D_ctrl_src2_choose_imm ? D_src2_imm : D_src2_reg"],
      );


    e_register->adds(
      {out => ["E_src1", $datapath_sz],     in => "D_src1", 
       enable => "E_en"},
      {out => ["E_src2", $datapath_sz],     in => "D_src2", 
       enable => "E_en"},
      {out => ["E_src2_reg", $datapath_sz], in => "D_src2_reg", 
       enable => "E_en"},
    );

    if (!$hw_div) {




        e_register->adds(
          {out => ["M_src1", $datapath_sz, 0, $force_never_export],
           in => "E_src1", enable => "M_en"},
          {out => ["M_src2", $datapath_sz, 0, $force_never_export], 
           in => "E_src2", enable => "M_en"},
        );
    }



    e_register->adds(
      {out => ["A_src2", $datapath_sz, 0, $force_never_export],
       in => "M_src2", enable => "A_en"},
    );

    my @src_operands = (
        { divider => "src_operands" },
        { radix => "x", signal => "D_src1_choose_E" },
        { radix => "x", signal => "D_src1_choose_M" },
        { radix => "x", signal => "D_src1_choose_A" },
        { radix => "x", signal => "D_src1_choose_W" },
        { radix => "x", signal => "D_src2_choose_E" },
        { radix => "x", signal => "D_src2_choose_M" },
        { radix => "x", signal => "D_src2_choose_A" },
        { radix => "x", signal => "D_src2_choose_W" },
        { radix => "x", signal => "D_src1_reg" },
        { radix => "x", signal => "D_src1" },
        { radix => "x", signal => "D_src2_imm" },
        { radix => "x", signal => "D_src2_reg" },
        { radix => "x", signal => "D_src2" },
        { radix => "x", signal => "E_src1" },
        { radix => "x", signal => "E_src2" },
        { radix => "x", signal => "M_src1" },
        { radix => "x", signal => "M_src2" },
        { radix => "x", signal => "A_src2" },
      );

    push(@plaintext_wave_signals, @src_operands);
}




sub 
make_alu_controls
{
    my $Opt = shift;






    e_assign->adds(
      [["D_logic_op_raw", $logic_op_sz],
        "(D_is_opx_inst ? D_iw_opx[$logic_op_msb:$logic_op_lsb] :
          D_iw_op[$logic_op_msb:$logic_op_lsb])"],

      [["D_logic_op", $logic_op_sz],
        "D_ctrl_alu_force_xor ? $logic_op_xor : 
         D_ctrl_alu_force_and ? $logic_op_and :
         D_logic_op_raw"],

      [["D_compare_op", $compare_op_sz],
        "(D_is_opx_inst ? D_iw_opx[$compare_op_msb:$compare_op_lsb] : 
          D_iw_op[$compare_op_msb:$compare_op_lsb])"],
      );


    e_register->adds(
      {out => ["E_logic_op", $logic_op_sz], in => "D_logic_op", 
       enable => "E_en"},
      {out => ["E_compare_op", $compare_op_sz], in => "D_compare_op", 
       enable => "E_en"},
    );
}




sub 
make_internal_interrupt_controller
{
    my $Opt = shift;
    my $cpu_arch_rev = manditory_int($Opt, "cpu_arch_rev");
    my $r2 = ($cpu_arch_rev == 2);






    e_assign->adds(
      [["norm_intr_req", 1], $r2 ? "E_status_reg_pie_latest & (W_ipending_reg != 0)" : "W_status_reg_pie & (W_ipending_reg != 0)"],
    );
    



    e_register->adds(
      {out => ["M_norm_intr_req", 1], 
       in => "norm_intr_req", enable => "M_en" },
    );
}

sub
make_external_interrupt_controller
{
    my $Opt = shift;



    my $eic_port_name = "interrupt_controller_in";
    my $eic_signal_prefix = "eic_port_";
    my @eic_port_signals = (["data" => $eic_port_sz],
                            ["valid" => 1]);
    
    e_signal->adds(map {[$eic_signal_prefix . $_->[0] => $_->[1]]} 
                       @eic_port_signals);
    
    my $eic_port_type_map = { map {$eic_signal_prefix . $_->[0] => $_->[0]}
                                  @eic_port_signals };
    my $cpu_arch_rev = manditory_int($Opt, "cpu_arch_rev");

    my $r2 = ($cpu_arch_rev == 2);

    e_atlantic_slave->add({
        name => $eic_port_name,
        type_map => $eic_port_type_map,
    });


    e_assign->adds(
      [["eic_port_data_ril", $eic_port_ril_sz], 
       "eic_port_data[$eic_port_ril_msb:$eic_port_ril_lsb]"],
      [["eic_port_data_rnmi", 1], 
       "eic_port_data[$eic_port_rnmi_lsb]"],
      [["eic_port_data_rha", $eic_port_rha_sz], 
       "eic_port_data[$eic_port_rha_msb:$eic_port_rha_lsb]"],
      [["eic_port_data_rrs", $eic_port_rrs_sz, 0, $force_never_export], 
       "eic_port_data[$eic_port_rrs_msb:$eic_port_rrs_lsb]"],
    );



    e_register->adds(
      {out => ["eic_ril", $status_reg_il_sz], 
       in => "eic_port_data_ril",
       enable => "eic_port_valid"},
      {out => ["eic_rnmi", 1], 
       in => "eic_port_data_rnmi",
       enable => "eic_port_valid"},
      {out => ["eic_rha", $pcb_sz], 
       in => "eic_port_data_rha",
       enable => "eic_port_valid"},
    );

    if ($shadow_present) {
        e_register->adds(
          {out => ["eic_rrs", $rf_set_sz], 
           in => "eic_port_data_rrs",
           enable => "eic_port_valid"},
        );
    }

    e_assign->adds(
      [["nmi_req", 1], 
        "eic_rnmi & (eic_ril != 0) & ~W_status_reg_nmi"],
      [["mi_req", 1], 
        $r2 ? "~eic_rnmi & (eic_ril > W_status_reg_il) & E_status_reg_pie_latest" .
        ($shadow_present ?
          " & ((eic_rrs != W_status_reg_crs) | E_status_reg_rsie_latest)" :
          "")
            : "~eic_rnmi & (eic_ril > W_status_reg_il) & W_status_reg_pie" .
        ($shadow_present ?
          " & ((eic_rrs != W_status_reg_crs) | W_status_reg_rsie)" :
          "")],




      [["ext_intr_req", 1], "(nmi_req | mi_req) & oci_ienable[0]"],
    );



    e_register->adds(
      {out => ["M_ext_intr_req", 1], 
       in => "ext_intr_req", 
       enable => "M_en" },

      {out => ["M_eic_ril", $status_reg_il_sz], 
       in => "eic_ril", 
       enable => "M_en" },
      {out => ["M_eic_rnmi", 1], 
       in => "eic_rnmi", 
       enable => "M_en" },
      {out => ["M_eic_rha", $pcb_sz], 
       in => "eic_rha", 
       enable => "M_en" },

      {out => ["A_eic_ril", $status_reg_il_sz], 
       in => "M_eic_ril", 
       enable => "A_en" },
      {out => ["A_eic_rnmi", 1], 
       in => "M_eic_rnmi", 
       enable => "A_en" },
      {out => ["A_eic_rha", $pcb_sz, 0, $force_never_export], 
       in => "M_eic_rha", 
       enable => "A_en" },
    );

    if ($shadow_present) {
        e_register->adds(
          {out => ["M_eic_rrs", $rf_set_sz], 
           in => "eic_rrs", 
           enable => "M_en" },
          {out => ["A_eic_rrs", $rf_set_sz], 
           in => "M_eic_rrs", 
           enable => "A_en" },
          {out => ["A_eic_rrs_non_zero", 1], 
           in => "M_eic_rrs != 0", 
           enable => "A_en" },
        );
    }

    my @mem_load_store_wave_signals = (
        { divider => "EIC Port" },
        { radix => "x", signal => "eic_port_valid" },
        { radix => "x", signal => "eic_port_data_ril" },
        { radix => "x", signal => "eic_port_data_rnmi" },
        { radix => "x", signal => "eic_port_data_rha" },
        { radix => "x", signal => "eic_port_data_rrs" },
        { radix => "x", signal => "eic_ril" },
        { radix => "x", signal => "eic_rnmi" },
        { radix => "x", signal => "eic_rha" },
        $shadow_present ? { radix => "x", signal => "eic_rrs" } : "",
        { radix => "x", signal => "nmi_req" },
        { radix => "x", signal => "mi_req" },
        { radix => "x", signal => "ext_intr_req" },
    );

    push(@plaintext_wave_signals, @mem_load_store_wave_signals);
}




sub 
make_tlb_data
{
    my $Opt = shift;

    my $data_addr_phy_sz  = manditory_int($Opt, "d_Address_Width");


    my $imm16_sex_datapath_sz = $datapath_sz - 16;    

    my $imm12_sex_datapath_sz = $datapath_sz - 12;
    my $cpu_arch_rev = manditory_int($Opt, "cpu_arch_rev");
    my $r2 = ($cpu_arch_rev == 2);

    e_assign->adds(

      [["E_src2_for_vpn", $datapath_sz], 
        $r2 ? "E_ctrl_ld_st_ex ? 0 : 
               E_ctrl_signed_imm12 ? {{$imm12_sex_datapath_sz {E_iw_imm12[11]}}, E_iw_imm12} : 
               {{$imm16_sex_datapath_sz {E_iw_imm16[15]}}, E_iw_imm16}"
            : "{{$imm16_sex_datapath_sz {E_iw_imm16[15]}}, E_iw_imm16}"],


      [["E_mem_baddr_for_vpn", $datapath_sz], 
        "E_src1 + E_src2_for_vpn"],


      [["E_mem_baddr_vpn", $mmu_addr_vpn_sz], 
        "E_mem_baddr_for_vpn[$mmu_addr_vpn_msb:$mmu_addr_vpn_lsb]"],
 

      [["A_mem_baddr_vpn", $mmu_addr_vpn_sz], 
        "A_mem_baddr[$mmu_addr_vpn_msb:$mmu_addr_vpn_lsb]"], 


      [["M_mem_baddr_page_offset", $mmu_addr_page_offset_sz], 
        "M_mem_baddr[$mmu_addr_page_offset_msb:$mmu_addr_page_offset_lsb]"], 


      [["M_mem_baddr_kernel_region", 1],
        "M_mem_baddr[$mmu_addr_kernel_region_msb:$mmu_addr_kernel_region_lsb]
          == $mmu_addr_kernel_region"],

      [["M_mem_baddr_io_region", 1],
        "M_mem_baddr[$mmu_addr_io_region_msb:$mmu_addr_io_region_lsb] 
          == $mmu_addr_io_region"],

      [["M_mem_baddr_user_region", 1],
        "M_mem_baddr[$mmu_addr_user_region_msb:$mmu_addr_user_region_lsb]
          == $mmu_addr_user_region"],
      [["M_mem_baddr_supervisor_region", 1], "~M_mem_baddr_user_region"],


      [["M_mem_baddr_bypass_tlb", 1], 
        "M_mem_baddr_kernel_region | M_mem_baddr_io_region"],
    );


    e_register->adds(
      {out => ["M_mem_baddr_vpn", $mmu_addr_vpn_sz], 
       in => "E_mem_baddr_vpn",                     enable => "M_en"},
    );





    new_exc_signal({
        exc             => $tlb_data_miss_exc,
        initial_stage   => "M", 
        speedup_stage   => "M",
        rhs             => 
          "M_ctrl_mem_data_access & !M_mem_baddr_corrupt &
           (~M_mem_baddr_bypass_tlb & M_udtlb_hit & M_udtlb_m)",
    });





    new_exc_signal({
        exc             => $tlb_r_perm_exc,
        initial_stage   => "M", 
        speedup_stage   => "M",
        rhs             => 
          "M_ctrl_ld & !M_mem_baddr_corrupt & (
            (~M_mem_baddr_bypass_tlb & M_udtlb_hit & ~M_udtlb_r) |
            (M_mem_baddr_supervisor_region & W_status_reg_u)
          )",
    });





    new_exc_signal({
        exc             => $tlb_w_perm_exc,
        initial_stage   => "M", 
        speedup_stage   => "M",
        rhs             => 
          "M_ctrl_st & !M_mem_baddr_corrupt & (
            (~M_mem_baddr_bypass_tlb & M_udtlb_hit & ~M_udtlb_w) |
            (M_mem_baddr_supervisor_region & W_status_reg_u)
          )",
    });


    my $udtlb_wave_signals = nios2_mmu::make_utlb($Opt, 1);


    e_register->adds(
      {out => ["A_mem_baddr_phy_got_pfn", 1], 
       in => "M_mem_baddr_phy_got_pfn",             enable => "A_en"},

      {out => ["A_mem_baddr_phy", $data_addr_phy_sz, 0, $force_never_export],
       in => "M_mem_baddr_phy",                     enable => "A_en"},
      {out => ["W_mem_baddr_phy", $data_addr_phy_sz, 0, $force_never_export],
       in => "A_mem_baddr_phy",                     enable => "W_en"},
    );

    push(@plaintext_wave_signals, 
      @$udtlb_wave_signals,
      { divider => "TLB Data Exceptions" },
      get_exc_signal_wave($tlb_data_miss_exc, "M"),
      get_exc_signal_wave($tlb_r_perm_exc, "M"),
      get_exc_signal_wave($tlb_w_perm_exc, "M"),
    );
}




sub 
make_dmpu
{
    my $Opt = shift;


    my $imm16_sex_datapath_sz = $datapath_sz - 16;    
    my $imm12_sex_datapath_sz = $datapath_sz - 12;
    my $cpu_arch_rev = manditory_int($Opt, "cpu_arch_rev");
    my $r2 = ($cpu_arch_rev == 2);

    e_assign->adds(
      [["E_mem_baddr_for_dmpu_src2", $datapath_sz], 
        $r2 ? "E_ctrl_ld_st_ex ? 0 : 
               E_ctrl_signed_imm12 ? {{$imm12_sex_datapath_sz {E_iw_imm12[11]}}, E_iw_imm12} : 
               {{$imm16_sex_datapath_sz {E_iw_imm16[15]}}, E_iw_imm16}"
            : "{{$imm16_sex_datapath_sz {E_iw_imm16[15]}}, E_iw_imm16}"],

      [["E_mem_baddr_for_dmpu", $datapath_sz], 
        "E_src1 + E_mem_baddr_for_dmpu_src2"],
    );


    e_mux->add ({
      lhs => ["M_dmpu_good_perm", 1],
      selecto => "M_dmpu_perm",
      table => [
        $mpu_data_perm_super_none_user_none => 
          "0",
        $mpu_data_perm_super_rd_user_none   => 
          "~W_status_reg_u & M_ctrl_ld",
        $mpu_data_perm_super_rd_user_rd     => 
          "M_ctrl_ld",
        $mpu_data_perm_super_rw_user_none   => 
          "~W_status_reg_u",
        $mpu_data_perm_super_rw_user_rd     =>
          "~W_status_reg_u | (W_status_reg_u & M_ctrl_ld)",
        $mpu_data_perm_super_rw_user_rw     =>
          "1",
        ],
      default => "0",
    });






    my @dmpu_exc_conds = ("~M_dmpu_hit", "~M_dmpu_good_perm");

    my $unused_mem_baddr_msb = manditory_bool($Opt, "bit_31_bypass_dcache") ? 30 : 31;
    my $unused_mem_baddr_lsb = manditory_int($Opt, "d_Address_Width");
    my $unused_mem_baddr_sz = $unused_mem_baddr_msb - $unused_mem_baddr_lsb + 1;

    if ($unused_mem_baddr_sz > 0) {
        push(@dmpu_exc_conds, 
          "(M_mem_baddr[$unused_mem_baddr_msb:$unused_mem_baddr_lsb] != 0)");
    }

    new_exc_signal({
        exc             => $mpu_data_region_violation_exc,
        initial_stage   => "M", 
        speedup_stage   => "M",
        rhs             => 
          "W_config_reg_pe & ~W_debug_mode & !M_mem_baddr_corrupt & " .
          "M_ctrl_mem_data_access & (" . join('|', @dmpu_exc_conds) . ")",
    });


    my $dmpu_region_wave_signals = nios2_mpu::make_mpu_regions($Opt, 1);

    push(@plaintext_wave_signals, 
      @$dmpu_region_wave_signals,
      { divider => "DMPU Exceptions" },
      get_exc_signal_wave($mpu_data_region_violation_exc, "M"),
    );
}




sub 
make_potential_tb_logic
{
    my $Opt = shift;

    e_assign->adds(
      [["E_src1_eq_src2", 1], "E_logic_result == 0"],
    );
}

1;
