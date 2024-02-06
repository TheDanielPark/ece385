# sh_launch.pm - set up environment for launching from shell
# used originally by nios2 tools (hence the quirkily
# specific names for the JRE ha ha) but now 2005(5.1)
# available in sopc builder too.
sub BEGIN
{
    # de-dossify some of our favorite environment variables
	$ENV{QUARTUS_ROOTDIR} =~ s|\\|/|g;
	$ENV{SOPC_KIT_NIOS2} =~ s|\\|/|g;
	$ENV{SOPC_KIT_NIOS2} =~ s|/cygdrive/(.)/(.*)|$1:/$2|g;
	$ENV{SOPC_KIT_NIOS2} =~ s|/ecos-(.)/(.*)|$1:/$2|g;
	my $Q = $ENV{QUARTUS_ROOTDIR};
	$Q =~ s|(.):/(.*)|/cygdrive/$1/$2|;
	@INC = ("$Q/sopc_builder/bin", "$Q/sopc_builder/bin/perl_lib", @INC);
    # argument resemble a path? change it.
	for (my $argc=0; $argc < scalar(@ARGV); $argc++)
	{
		@ARGV[$argc] =~ s|^(.*)/cygdrive/(.)/(.*)|$1$2:/$3|;
		@ARGV[$argc] =~ s|^(.*)/ecos-(.)/(.*)|$1$2:/$3|;
	}
    
    # Case:126809 Use QUARTUS_BINDIR if its set,
    # otherwise use QUARTUS_ROOTDIR/$platbin
    
    my($qbindir);
    if ( $ENV{QUARTUS_BINDIR} )
    {
        $ENV{QUARTUS_BINDIR} =~ s|\\|/|g; # de-dossify
        $qbindir = $ENV{QUARTUS_BINDIR};
    }
    else
    {
        my($platbin32);
        if ($^O eq "MSWin32" or $^O eq "cygwin")
        {
            $platbin32 = "bin";
        }
        else
        {
            $platbin32 = $^O;
        }
        
        $qbindir = "$ENV{QUARTUS_ROOTDIR}/$platbin32";
    }
    
	$nios2sh_BIN = "$ENV{SOPC_KIT_NIOS2}/bin";
	$sopc_builder_BIN = "$ENV{QUARTUS_ROOTDIR}/sopc_builder/bin";
	$nios2sh_JRE = "$qbindir/jre/bin/java";
	$quartus_JRE = $nios2sh_JRE;
}
1; # success
