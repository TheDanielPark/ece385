# run_eclipse.pl

$| = 1;         # set flushing on STDOUT

# commands are passed in via a single argument, comma-delimited.
my $in_cmd = shift;
my ($quartus_dir, $qbin, $sopc_kit_dir, $system_dir, $system_name) = split ',',$in_cmd;

if ($sopc_kit_dir eq "")
{
    $sopc_kit_dir = $ENV{'SOPC_KIT_NIOS2'};
}

# run the eclipse-nios2 script in the kit bin
if ($^O =~ /win/i)
{
	$eclipse_nios2 = "$sopc_kit_dir" . "\\bin\\eclipse-nios2.exe";
} 
else
{
	$eclipse_nios2 = "$sopc_kit_dir" . "/bin/eclipse-nios2";
}

# SPR 176093, 187367: force qenv.csh to be run and set PATH properly
# for quartus/bin wrapper scripts
delete $ENV{QUARTUS_QENV};

# run
chdir "$sopc_kit_dir" . "\\bin";
my $result = system
	$eclipse_nios2
	;

1;
