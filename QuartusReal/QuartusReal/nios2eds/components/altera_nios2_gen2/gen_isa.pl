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
use cpu_utils;
use nios_isa;
use nios2_isa;
use nios2_exceptions;
use nios2_control_regs;
use nios2_insts;
use nios2_mmu;
use nios2_mpu;
use strict;

my $PN = "gen_isa.pl";

sub usage
{
    print "Usage: $PN <code-fname> <header-fname> <cpu-arch-rev>\n";
    print "\n";
    print "Creates two output files using isa.pm as reference:\n";
    print "   <code-fname>     C code file that contains static tables\n";  
    print "   <header-fname>   C header file that defines macros\n";
    print "   <cpu-arch-rev>   1 (R1) or 2 (R2)\n";
    exit 1;
}


{

    cpu_utils::init({
      error => \&cpu_utils::local_error,
      progress => \&print,
    });

    if (scalar(@ARGV) != 3) {
        usage();
    }
    
    my $code_fname = $ARGV[0];
    my $header_fname = $ARGV[1];
    my $cpu_arch_rev = $ARGV[2];

    if (!create_file($code_fname, $header_fname, $cpu_arch_rev)) {
        exit(1);
    }

    exit 0;
}

sub
create_file
{
    my $code_fname = shift;
    my $header_fname = shift;
    my $cpu_arch_rev = shift;

    if (!open(CFD, ">$code_fname")) {
        print "$PN: can't open $code_fname for writing\n";
        return 0;
    }

    if (!open(HFD, ">$header_fname")) {
        print "$PN: can't open $header_fname for writing\n";
        return 0;
    }

    add_c_header($header_fname);
    add_h_header($cpu_arch_rev);

    my $c_lines = [];
    my $h_lines = [];

    my $local_mmu_present = 1;
    my $local_mpu_present = 1;
    my $nios_isa_info = nios_isa::validate_and_elaborate($local_mmu_present, $local_mpu_present);
    nios_isa::convert_to_c($nios_isa_info, $c_lines, $h_lines);

    my $nios2_isa_info = nios2_isa::validate_and_elaborate();
    nios2_isa::convert_to_c($nios2_isa_info, $c_lines, $h_lines);

    my $control_reg_args = 
      nios2_control_regs::create_control_reg_args_max_configuration();
    my $control_reg_info = 
      nios2_control_regs::validate_and_elaborate($control_reg_args);
    nios2_control_regs::convert_to_c($control_reg_info, $c_lines, $h_lines);

    my $inst_args = nios2_insts::create_inst_args_gen_isa_configuration($nios2_isa_info, 
      $cpu_arch_rev);
    if (!defined($inst_args)) {
        print "$PN: nios2_insts::create_inst_args_gen_isa_configuration() returned with error\n";
        return 0;
    }
    my $inst_info = nios2_insts::validate_and_elaborate($inst_args);
    if (!defined($inst_info)) {
        print "$PN: nios2_insts::validate_and_elaborate() returned with error\n";
        return 0;
    }
    if (!defined(nios2_insts::convert_to_c($cpu_arch_rev, $inst_info, $c_lines, $h_lines))) {
        print "$PN: nios2_insts::convert_to_c() returned with error\n";
        return 0;
    }

    my $mmu_args = nios2_mmu::create_mmu_args_max_configuration();
    my $elaborated_mmu_info = nios2_mmu::validate_and_elaborate($mmu_args);
    nios2_mmu::convert_to_c($elaborated_mmu_info, $c_lines, $h_lines);

    my $mpu_args = nios2_mpu::create_mpu_args_max_configuration();
    my $elaborated_mpu_info = nios2_mpu::validate_and_elaborate($mpu_args);
    nios2_mpu::convert_to_c($elaborated_mpu_info, $c_lines, $h_lines);

    my $elaborated_exception_info = nios2_exceptions::validate_and_elaborate();
    nios2_exceptions::convert_to_c($elaborated_exception_info,
      $c_lines, $h_lines);

    foreach my $c_line (@$c_lines) {
        print CFD $c_line, "\n";
    }

    foreach my $h_line (@$h_lines) {
        print HFD $h_line, "\n";
    }

    add_h_footer($cpu_arch_rev);

    close(CFD);
    close(HFD);

    return 1;
}

sub
add_c_header
{
    my $header_fname = shift;

    print CFD 
      "/* This file is automatically generated by $PN - do not edit */\n";

    print CFD "\n";
    print CFD "#include \"$header_fname\"\n";
}

sub
add_h_header
{
    my $cpu_arch_rev = shift;
    print HFD "/*\n";
    print HFD " * This file defines Nios II R${cpu_arch_rev} instruction set constants.\n";
    print HFD " * To include it in assembly code (.S file), define ALT_ASM_SRC\n";
    print HFD " * before including this file.\n";
    print HFD " *\n";
    print HFD " * This file is automatically generated by $PN - do not edit\n";
    print HFD " */\n";

    print HFD "\n#ifndef _NIOS2_R${cpu_arch_rev}_ISA_H_\n";
    print HFD "#define _NIOS2_R${cpu_arch_rev}_ISA_H_\n";
    print HFD "\n";
    print HFD "/* Indicates that this file is for revision ${cpu_arch_rev} of Nios II. */\n";
    print HFD "\n#ifndef NIOS2_R${cpu_arch_rev}\n";
    print HFD "#define NIOS2_R${cpu_arch_rev}\n";
    print HFD "#endif /* NIOS2_R${cpu_arch_rev} */\n";
}

sub
add_h_footer
{
    my $cpu_arch_rev = shift;
    print HFD "\n#endif /* _NIOS2_R${cpu_arch_rev}_ISA_H_ */\n";
}
