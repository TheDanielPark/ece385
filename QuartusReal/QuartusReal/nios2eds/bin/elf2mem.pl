use strict;
use europa_all;
use e_project;

our $PN = "elf2mem";
our $PB = $PN; $PB =~ s/./ /g;

our $Makefile = "elf2mem.mk";

sub main
{
    my $infile;
    my $ptf;
    my @cpus;
    my @mem_include;
    my @mem_exclude;
    my $sim_optimize = 1;
    my $list_cpus = 0;
    my $list_mems = 0;

    foreach my $arg (@_) {
        if ($arg =~ /^-+help$/i || $arg =~ /^-+h$/i) {
            help();
            exit(0);
        }

        if (!($arg =~ /^--(\S+)=(\S+)/)) {
            usage("$PN: ERROR: Malformed argument '$arg'\n");
            exit(1);
        }

        my $arg = $1;
        my $value = $2;

        {
            $arg =~ /^infile$/i       && do {$infile        = $value; next};
            $arg =~ /^ptf$/i          && do {$ptf           = $value; next};
            $arg =~ /^cpu$/i          && do {push(@cpus,      $value); next};
            $arg =~ /^mem-include$/i  && do {push(@mem_include, $value); next};
            $arg =~ /^mem-exclude$/i  && do {push(@mem_exclude, $value); next};
            $arg =~ /^sim-optimize$/i && do {$sim_optimize  = $value; next};
            $arg =~ /^list-cpus$/i    && do {$list_cpus     = $value; next};
            $arg =~ /^list-mems$/i    && do {$list_mems     = $value; next};
            usage("$PN: ERROR: Unknown option '$arg'\n");
            exit(1);
        }
    }

    if ($ptf eq '') {
        usage("$PN: ERROR: Missing argument: --ptf\n");
        exit(1);
    }

    if (! -f $ptf) {
        print("$PN: ERROR: Can't read --ptf \"$ptf\"\n");
        exit(1);
    }

    if (defined(@mem_include) && defined(@mem_exclude)) {
        usage("$PN: ERROR: Can't specify --mem-include and" .
          " --mem-exclude together\n");
        exit(1);
    }

    my $project = e_project->new({ptf_file => $ptf});

    my @candidate_cpus = get_all_cpu_module_names($project);

    if ($list_cpus) {
        display_candidate_cpus(@candidate_cpus);

        if (!$list_mems) {
            exit(0);
        }
    }

    if (scalar(@candidate_cpus) == 0) {
        print "$PN: ERROR: List of candidate CPUs is empty\n";
        display_candidate_cpus(@candidate_cpus);
        exit(1);
    }

    if (defined(@cpus)) {
        # Make sure each specified CPU module name exists.
        foreach my $cpu (@cpus) {
            if (!grep(/^$cpu$/, @candidate_cpus)) {
                print("$PN: ERROR: CPU $cpu doesn't exist in PTF $ptf\n");
                display_candidate_cpus(@candidate_cpus);
                exit(1);
            }
        }
    } else {
        # Default to all CPUs.
        @cpus = @candidate_cpus;
    }

    if (scalar(@cpus) == 0) {
        print "$PN: ERROR: List of CPUs empty\n";
        display_candidate_cpus(@candidate_cpus);
        exit(1);
    }

    # Find all memories supported by this script and that are mastered
    # by one of the specified CPUs.
    my @candidate_mems = get_candidate_mems($project, \@cpus);

    if ($list_mems) {
        display_candidate_mems(@candidate_mems);
        exit(0);
    }

    if (scalar(@candidate_mems) == 0) {
        print "$PN: List of candidate memories empty." .
          " No contents generation required.\n";

        # Don't consider this an error to support systems that
        # might only have legacy memories present.
        exit(0);
    }

    my @mems;

    if (defined(@mem_include)) {
        # Add all specified memories and make sure they are candidates.
        foreach my $mem (@mem_include) {
            if (!grep(/^$mem$/, @candidate_mems)) {
                print("$PN: ERROR: $mem specified by --mem-include" .
                  " is not a candidate\n");
                display_candidate_mems(
                  @candidate_mems);
                exit(1);
            }
            push(@mems, $mem);
        }
    } elsif (defined(@mem_exclude)) {
        # Make sure all specified memories are candidates.
        foreach my $mem (@mem_exclude) {
            if (!grep(/^$mem$/, @candidate_mems)) {
                print(
                  "$PN: ERROR: $mem specified by --mem-exclude" .
                    " is not a candidate\n");
                display_candidate_mems(
                  @candidate_mems);
                exit(1);
            }
        }

        # Add all supported PTF memories except for those specified.
        foreach my $mem (@candidate_mems) {
            if (!grep(/^$mem$/, @mem_exclude)) {
                push(@mems, $mem);
            }
        }
    } else {
        # Default to all candidate memories.
        @mems = @candidate_mems;
    }

    if (scalar(@mems) == 0) {
        print "$PN: List of memories empty." .
          " No contents generation required.\n";

        # Don't consider this an error to support systems that
        # might only have legacy memories present.
        exit(0);
    }

    if ($infile eq '') {
        usage("$PN: ERROR: Missing argument: --infile\n");
        exit(1);
    }

    if (! -f $infile) {
        print("$PN: ERROR: Can't read --infile \"$infile\"\n");
        exit(1);
    }

    my ($system_name) = keys(%{$project->spaceless_ptf_hash()->{SYSTEM}});

    my ($quartus_project_dir, $ptf_basename) = split_path($ptf);

    my $simdir = $quartus_project_dir . "/" . $system_name . "_sim";

    if (! -d $simdir) {
        print "$PN: ERROR: Can't find HDL simulation directory\n";
        print "$PN    Using '$system_name' for system name\n";
        print "$PN    Using '$quartus_project_dir' for Quartus project dir\n";
        exit(1);
    }

    foreach my $cpu (@cpus) {
        generate_memory_contents($project, $ptf, $simdir, $cpu, 
          $infile, $sim_optimize, \@mems);
    }

    return 0;
}

sub usage
{
    my $message  = join ("\n", @_);

    $message .=  <<EOM
Usage: $PN --infile=<elf-input-filename>
       $PB --ptf=<ptf-filename>
       $PB --cpu=<module>         (optional - default is all CPUs)
       $PB --mem-include=<module> (optional - default is all included)
       $PB --mem-exclude=<module> (optional - default is all included)
       $PB --sim-optimize=<0/1>   (optional - default is 1)
       $PB --list-cpus=<0/1>      (optional - default is 0)
       $PB --list-mems=<0/1>      (optional - default is 0)
       $PB --help                 (prints detailed usage)
EOM
    ;

    print $message;
}

sub help
{
    usage(@_);

    my $help = <<EOM

Creates memory contents files given an ELF file and a PTF file.  These
memory contents files are used by supported HDL simulation memory models 
to provide initial memory contents.  They are also used by Quartus 
compilation to provide initial memory contents for the Altera On-chip
Memory component if its RAMs/ROMs are initialized from the SOF file.

The supported memories are the non-legacy memories that have MAKE sections 
in their WIZARD_SCRIPT_ARGUMENTS section of the specified PTF file.

$PN creates some files in the Quartus project directory associated with
the specified PTF file and others are in the HDL simulation directory located
directly under the Quartus project directory.  Its name is of the form:
    <SOPC_builder_system_name>_sim

$PN creates a DAT and SYM file for each supported memory in the HDL 
simulation directory.  The SYM file is a sorted symbol table produced
from the ELF file.  

$PN creates a HEX file for each Altera On-chip Memory component
in the Quartus project directory.

If no --cpu options are specified, all memories accessible to any
CPU in the PTF file are candidates for creating memory contents files.
If one or more --cpu options are specified, only memories accessible
to the specified CPUs are candidates for creating memory contents files.

If no --mem-include or --mem-exclude options are specified,
memory contents files will be created for all candidate memories.
If one or more --mem-include options are specified, only 
memory contents files will be created for the specified memories.
If one or more --mem-exclude options are specified, 
memory contents files will be created for all candidate memories except
for the specified memories.
It is an error to specify --mem-include and --mem-exclude options
at the same time.

The --sim-optimize option allows the ALT_SIM_OPTIMIZE flag passed to
elf2flash to be specified.  The default is to perform optimizations
to speed up HDL simulation that aren't possible on real hardware.

The --list-cpus option displays all candidate CPUs in the PTF file and exits.
The --list-mems option displays all candidate memories in the PTF file for
the specified CPUs (or all candidate CPUs if no --cpu options are specified)
and then exits.

EOM
    ;

    print $help;
}

sub get_all_cpu_module_names
{
    my $project = shift;

    my $cpu_hash = $project->get_module_hash("SYSTEM_BUILDER_INFO/Is_CPU");

    my @cpus = grep {$cpu_hash->{$_}} keys(%$cpu_hash);

    return @cpus;
}

sub
display_candidate_cpus
{
    my @cpus = @_;

    print "$PB  Candidate CPUs in PTF file:\n";

    if (scalar(@cpus) == 0) {
        print "$PB    none\n";
    } else {
        foreach my $name (@cpus) {
            print "$PB    $name\n";
        }
    }
}

# Find all memory devices that are supported by this script
# and are mastered by one of the specified CPUs.
sub get_candidate_mems
{
    my $project = shift;
    my $cpus_ref = shift;

    my $memory_device_hash = 
      $project->get_module_slave_hash("SYSTEM_BUILDER_INFO/Is_Memory_Device");

    my @memory_slave_ids = 
      grep {$memory_device_hash->{$_}} keys(%$memory_device_hash);

    my @memory_devices;

    foreach my $memory_slave_id (@memory_slave_ids) {
        my ($module_name, $slave_name) = split(/\//, $memory_slave_id);

        my $make_section = $project->spaceless_system_ptf()->{MODULE}
          {$module_name}{WIZARD_SCRIPT_ARGUMENTS}{MAKE};

        # Skip module if it doesn't have a MAKE section in its WSA.
        if (!$make_section) {
            next;
        }

        # Skip module if it doesn't have a dat or hex target.
        if (!$make_section->{TARGET}{dat} && !$make_section->{TARGET}{hex}) {
            next;
        }

        # Skip module if it isn't mastered by one of the specified CPUs.
        if (!is_mastered_by_cpu($project, $cpus_ref, $module_name)) {
            next;
        }

        # Module is supported so add to list.
        push(@memory_devices, $module_name);
    }
    
    return @memory_devices;
}

# Return 1 if the specified module is mastered by one of the specified CPUs.
# Otherwise, return 0.
sub is_mastered_by_cpu
{  
    my $project = shift;
    my $cpus_ref = shift;
    my $module_name = shift;

    foreach my $cpu_name (@$cpus_ref) {
        # The master list contains all masters provided by the CPU.  
        # This includes custom instruction masters if present as well.
        my @master_names = $project->get_masters_by_module_name($cpu_name);

        #print "master_names = @master_names\n";

        # Now find all slaves accessible to each Avalon master interface.
        foreach my $master_name (@master_names) {
            my $master_bus_type = $project->spaceless_system_ptf()->{MODULE}
              {$cpu_name}{MASTER}{$master_name}{SYSTEM_BUILDER_INFO}{Bus_Type};

            if ($master_bus_type =~ /^avalon$/i) {
                my @slave_ids =
                  $project->get_slaves_by_master_name($cpu_name, $master_name);
                
                foreach my $slave_id (@slave_ids) {
                    my ($slave_module_name, $slave_interface_name) = 
                      split(/\//, $slave_id);

                    #print "slave_id = $slave_id\n";

                    if ($module_name eq $slave_module_name) {
                        return 1;
                    }
                }
            }
        }
    }

    return 0;
}

sub
display_candidate_mems
{
    my @devices = @_;

    print "$PB  Candidate memories in PTF:\n";

    if (scalar(@devices) == 0) {
        print "$PB    none\n";
    } else {
        foreach my $name (@devices) {
            print "$PB    $name\n";
        }
    }
}

sub generate_memory_contents
{
    my $project = shift;
    my $ptf_fname = shift;
    my $simdir = shift;
    my $cpu_name = shift;
    my $elf_fname = shift;
    my $sim_optimize = shift;
    my $mems_ref = shift;

    # Get path to HDL simulation directory.
    my $stf_filename = "$simdir/$cpu_name.stf";

    create_stf_file($project, $ptf_fname, $cpu_name, $stf_filename);

    create_makefile($project, $simdir, $stf_filename);

    invoke_makefile($project, $cpu_name, $simdir, $elf_fname, $sim_optimize,
      $mems_ref);
}

sub create_stf_file
{
    my $project = shift;
    my $ptf_fname = shift;
    my $cpu_name = shift;
    my $stf_filename = shift;

    my $buffer = <<EOP;
<stf>
    <project
        ptf="$ptf_fname" target="Nios II System Library"/>
    <cpu name="$cpu_name"/>
</stf>
EOP

    # Write out buffer to file.
    if (!open(STF, "> $stf_filename")) {
        print("$PN: ERROR: Can't open $stf_filename for writing\n");
        exit(1);
    }
    print STF $buffer;
    close(STF);
}

sub create_makefile
{
    my $project = shift;
    my $simdir = shift;
    my $stf_filename = shift;

    my $sopc_kit_nios2 = $ENV{SOPC_KIT_NIOS2};

    if (!$sopc_kit_nios2) {
        print "$PN: Error: SOPC_KIT_NIOS2 environment variable isn't defined\n";
        print "$PB: It should point to the location of the Altera Nios II Kit\n";
        exit(1);
    }

    my @gtf_generate_cmd = (
      "gtf-generate",
      "--output-directory=$simdir",
      "--gtf=$sopc_kit_nios2/bin/gtf/$Makefile.gtf",
      "--stf=$stf_filename");

    #print "$PN: @gtf_generate_cmd\n";
    system(@gtf_generate_cmd);
    my $exit_status = ($? >> 8);
    if ($exit_status) {
        print "$PN: ERROR: @gtf_generate_cmd returned $exit_status\n";
        exit($exit_status);
    }
}

sub invoke_makefile
{
    my $project = shift;
    my $cpu_name = shift;
    my $simdir = shift;
    my $elf_fname = shift;
    my $sim_optimize = shift;
    my $mems_ref = shift;

    my @make_cmd = (
      "make",
      "ELF=$elf_fname",
      "ALT_SIM_OPTIMIZE=$sim_optimize",
      "-f",
      "$simdir/$Makefile",
      @$mems_ref);

    #print "$PN: @make_cmd\n";
    system(@make_cmd);
    my $exit_status = ($? >> 8);
    if ($exit_status) {
        print "$PN: ERROR: @make_cmd returned $exit_status\n";
        exit($exit_status);
    }
}

# Takes a full file path and splits it into the directory name and 
# base filename.
# Handles Unix or DOS paths.
# The trailing slash at the end of a directory name is removed.
#
# The original full file path can be recovered by concatenating the
# dirname, a slash, and the basename.  To accomplish this, if the directory name
# is the root, it is returned as undef.
# If the full file path ends with a slash, the basename is returned undef.
#
# Examples:
#   fullpath=/abc dirname= basename=abc
#   fullpath=/c/ dirname=/c basename=
#   fullpath=/c/foo dirname=/c basename=foo
#   fullpath=/c/foo/bar dirname=/c/foo basename=bar
#   fullpath=c/foo/bar dirname=c/foo basename=bar
#   fullpath=c:/foo/bar dirname=c:/foo basename=bar
#   fullpath=/c/foo/bar/ dirname=/c/foo/bar basename=
#   fullpath=foo dirname=. basename=foo
#   fullpath=./foo dirname=. basename=foo
#   fullpath=\\machine\c\dir\foo\bar dirname=\\machine\c\dir\foo basename=bar
#   fullpath=\abc dirname= basename=abc
#   fullpath=\c\ dirname=\c basename=
#   fullpath=\c\foo dirname=\c basename=foo
#   fullpath=\c\foo\bar dirname=\c\foo basename=bar
#   fullpath=c\foo\bar dirname=c\foo basename=bar
#   fullpath=c:\foo\bar dirname=c:\foo basename=bar
#   fullpath=\c\foo\bar\ dirname=\c\foo\bar basename=
#   fullpath=foo dirname=. basename=foo
#   fullpath=.\foo dirname=. basename=foo
sub split_path
{
    my $fullpath = shift;

    my ($dirname,$basename) = ($fullpath =~ /^((?:.*[:\\\/])?)(.*)/s);
    $dirname =~ s/([^:])[\\\/]*\z/$1/;
    if (!$dirname) {
        $dirname = '.';
    } elsif ($dirname eq '/' || $dirname eq '\\') {
        undef $dirname;
    }

    return ($dirname, $basename);
}

if (scalar(@ARGV) == 0) {
    usage();
    exit(1);
}

exit(main(@ARGV));
