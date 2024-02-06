# open_nios2_command_shell.pl
#
# called by sopc_builder to launch an Nios II Command Shell
#

$| = 1;         # set flushing on STDOUT

# commands are passed in via a single argument, comma-delimited.
my $in_cmd = shift;
my ($quartus_dir, $sopc_kit_dir, $system_dir, $system_name) = split ',',$in_cmd;

if ($sopc_kit_dir eq "")
{
    $sopc_kit_dir = $ENV{'SOPC_KIT_NIOS2'};
}

$ENV{'_SOPC_PROJECT_PATH'} = "$system_dir";

if ($^O =~ /win/i) # Windows:
{
   my $cmd = $ENV{COMSPEC};
   my $bat = "$sopc_kit_dir/Nios II Command Shell.bat";
   $bat =~ s/\//\\/g;
   
   chdir $sopc_kit_dir;
   
   my $result = exec ($cmd, "/C", "start", "\"Launching Nios II Command Shell\"", "\"$bat\"");
}
else # Linux:
{
   exec("xterm -rv -e $sopc_kit_dir/nios2_command_shell.sh");
}
return 1; # success

# end of file
