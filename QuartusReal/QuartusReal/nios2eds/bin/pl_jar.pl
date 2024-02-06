#!perl
use sh_launch;
my $tool = shift @ARGV;
exit system($nios2sh_JRE, "-Xmx512m", "-jar", "$tool.jar", @ARGV)>>8;
