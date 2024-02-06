# run_eclipse.pl

$| = 1;         # set flushing on STDOUT

# commands are passed in via a single argument, comma-delimited.
my $in_cmd = shift;
my ($quartus_dir, $qbin, $sopc_kit_dir, $system_dir, $system_name) = split ',',$in_cmd;

# SPR:224948 - If sopc_kit_dir isn't being passed from calling
# shell correctly, replace it with the SOPC_KIT_NIOS2 as found
# from the environment shell
if ($sopc_kit_dir eq "")
{
    $sopc_kit_dir = $ENV{'SOPC_KIT_NIOS2'};
}

# run the nios2-ide script in the kit bin
if ($^O =~ /win/i)
{
	$nios2_ide = "$sopc_kit_dir" . "\\bin\\eclipse\\nios2-ide.exe";
} 
else
{
	$nios2_ide = "$sopc_kit_dir" . "/bin/nios2-ide";
}

# SPR 176093, 187367: force qenv.csh to be run and set PATH properly
# for quartus/bin wrapper scripts
delete $ENV{QUARTUS_QENV};

# run
chdir "$sopc_kit_dir" . "\\bin\\eclipse";
my $result = system
	$nios2_ide,
	"-vmargs",
	"-Dcom.altera.ide.systemdir=$system_dir",
	"-Dcom.altera.ide.systemname=$system_name",
	"-Xmx256m"
	;

1;
