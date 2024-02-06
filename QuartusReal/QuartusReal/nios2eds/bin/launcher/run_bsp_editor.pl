# run_bsp_editor.pl

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

# run the bsp_editor script in the kit bin
if ($^O =~ /win/i)
{
	$bsp_editor = "$sopc_kit_dir" . "\\sdk2\\bin\\nios2-bsp-editor.exe";
} 
else
{
	$bsp_editor = "$sopc_kit_dir" . "/sdk2/bin/nios2-bsp-editor";
}

# SPR 176093, 187367: force qenv.csh to be run and set PATH properly
# for quartus/bin wrapper scripts
delete $ENV{QUARTUS_QENV};

# run
chdir "$system_dir";
my $result = system
	$bsp_editor,
	;

1;
