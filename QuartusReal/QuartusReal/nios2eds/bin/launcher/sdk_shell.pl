# open_sdk_shell.pl
#
# called by sopc_builder to launch an SDK shell
#

$| = 1;         # set flushing on STDOUT

# commands are passed in via a single argument, comma-delimited.
my $in_cmd = shift;
my ($quartus_dir, $sopc_kit_dir, $system_dir, $system_name) = split ',',$in_cmd;

# SPR:224948 - If sopc_kit_dir isn't being passed from calling
# shell correctly, replace it with the SOPC_KIT_NIOS2 as found
# from the environment shell
if ($sopc_kit_dir eq "")
{
    $sopc_kit_dir = $ENV{'SOPC_KIT_NIOS2'};
}

if ($^O =~ /win/i) # Windows:
{
my $cmd = $ENV{COMSPEC};
my $bat = "$sopc_kit_dir/Nios II Command Shell.bat";
$bat =~ s/\//\\/g;

$ENV{'WIN32_SDK_SHELL_PROJECT_PATH'} = "$system_dir";
chdir $sopc_kit_dir;

my $result = exec ($cmd, "/C", "start", "\"Launching Nios II Command Shell\"", "\"$bat\"");
}
else # Linux:
{
  exec("xterm -rv -e $sopc_kit_dir/sdk_shell");
}
return 1; # success

# end of file
