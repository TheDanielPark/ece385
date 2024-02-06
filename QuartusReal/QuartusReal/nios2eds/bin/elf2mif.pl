
use sh_launch;
use strict;  #(now available)
use format_conversion_utils;

# -------------------------------
# nios-convert

sub main
	{
	my $result = 0;
	my @argv = @_;

  # "create-lanes" parameter handled upfront here, without perturbing
  # scary order-dependent code beow.
  my $create_hex_lanes = 0;
  my $index_of_create_hex_lanes = -1;
  for my $index (0 .. -1 + @argv)
  {
    if ($argv[$index] =~ /--create-lanes=(.*)/)
    {
      $create_hex_lanes = $1;
      splice @argv, $index, 1;
      last;
    }
  }

	my $progSuffix;

	my $debug = 0;

	my $inFileName;
	my $inFileBase;
	my $interFileName;
	my $lowAddr;
	my $highAddr = 0;
	my $memoryWidth = 0;
	my $outFileName;

	my @objCopyArgs = ('--output-target=srec');

	my @convertArgs = ('--iformat=srec');
	my $convertOutFormat = ('--oformat=');
	my $convertInPrefix = ('--infile=');
	my $convertOutPrefix = ('--outfile=');
	my $convertLowPrefix = ('--address_low=');
	my $convertHighPrefix = ('--address_high=');

	#get the progam suffix
	$progSuffix	= substr( @argv[0], -3);
	shift @argv;

	# Handle the debug flag
	if (( @argv > 0 ) && (( @argv[0] eq "-d" ) || ( @argv[0] eq "--debug" )))
	{
		$debug = 1;
		shift @argv;
	}

	if ($debug)
	{
		print "Number of args: ", scalar(@argv), "\n";
		print "And they are: ". join("\n",@argv) ."\n";
	}

	# draconian - force a very limited set of arguments (rewrite this in Java later)
	#	one arg, and it's the ELF file
	#	two args, the ELF and the output file
	#	four args, the ELF, start address, length, and the output file
	#		or, the ELF, the start address, the length, and the memory width
	#	five args, the ELF, start address, length, memory width, and the output file

	# first, catch the help cases (anything but width)
	foreach ( @argv )
	{
		if (( $_ =~ /^-/ ) && !( $_ =~ /^--width/ ))
		{
			usage( $progSuffix );
		}
	}

	# need one to five args
	if (( @argv < 1 ) || ( @argv > 5 ))
	{
		usage( $progSuffix );
	}

	# handle the input file name
	$inFileName = @argv[0];
	shift @argv;

	if ($debug)
	{
		print "Input file name: ", $inFileName, "\n";
	}
	
	# generate the intermediate file name
	$inFileBase = $inFileName;
	$inFileBase =~ s/\.+.*$//;					# kill a dot and anything after it
	$interFileName = $inFileBase . ".srec";		# tack on an SREC
		
	if ($debug)
	{
		print "Input file base: ", $inFileBase, "\n";
		print "Intermediate file name: ", $interFileName, "\n";
	}
	
	# handle the base address and the length, if we have them
	if (( @argv > 1 ) && ( @argv[0] =~ /^[0-9]+/ ))
	{
		# scrape off the low and high addresses
		$lowAddr = @argv[0];
		shift @argv;
		
		$highAddr = @argv[0];
		shift @argv;

		if ($debug)
		{
			print "Memory low address: ", $lowAddr, "\n";
			print "Memory high address: ", $highAddr, "\n";
		}
	}		

	# handle the width if we have one
	if (( @argv > 0 ) && ( @argv[0] =~ /^--width=/ ))
	{
		$memoryWidth = @argv[0];
		shift @argv;

		if ($debug)
		{
			print "Memory width switch: ", $memoryWidth, "\n";
		}
	}
	
	# finally, handle the output file, if specified
	if ( @argv == 1 )
	{
		$outFileName = @argv[0];
	}
	else
	{
		$outFileName = $inFileBase . "." . $progSuffix;		
	}

	if ($debug)
	{
		print "Output file name: ", $outFileName, "\n";
	}

	# TODO: check for the existance of the input file!
	
	# first append the input file name to the ObjCopy command array
	@objCopyArgs = (@objCopyArgs, $inFileName);

	# then the intermediate file name
	@objCopyArgs = (@objCopyArgs, $interFileName);

	# then the conversion target type
	@convertArgs = (@convertArgs, $convertOutFormat . $progSuffix);

	# and the conversion input file name
	@convertArgs = (@convertArgs, $convertInPrefix . $interFileName);
	
	# finally, the output file name
	@convertArgs = (@convertArgs, $convertOutPrefix . $outFileName);

	# if we have an address range, append that
	if ( $highAddr )
	{
		@convertArgs = (@convertArgs, $convertLowPrefix . $lowAddr);
		@convertArgs = (@convertArgs, $convertHighPrefix . $highAddr);
	}
	
	# if we have a width, append that
	if ( $memoryWidth )
	{
		@convertArgs = (@convertArgs, $memoryWidth);
	}
	
	if ($debug)
	{
		print "ObjCopy args: @objCopyArgs\n";
		print "conversion args: @convertArgs\n";
	}
	else
	{
		$result = objCopy( @objCopyArgs );

		if ( $result == 0 )
		{
			# ObjCopy succeeded, run the conversion
			$result = convert( @convertArgs );
			
			if ( $result < 0 )
			{
				print "Convert failed with the exit code: ", $result, "\n"; 
			}
		}
		else
		{
			print "ObjCopy failed with the exit code: ", $result, "\n"; 
		}
	}

  # Delete the intermediate file.
  unlink $interFileName;
  
  if ($create_hex_lanes)
  {
    require 'convert2lanes.pm';
    my $output_template = $outFileName;
    $output_template =~ s/([^\.]+)\.([^\.]+)$/$1_laneX.$2/;

    my $width_in_bits = $memoryWidth;
    $width_in_bits =~ s/^\D*(\d+)$/$1/;
    my $ret = convert2lanes::hex2lanes({
      infile => $outFileName,
      output_template => $output_template,
      width_in_bits => $width_in_bits,
    });

    if ($ret)
    {
      $ret = "\ninternal error:\n" . $ret;
      convert2lanes::usage($ret);
    }
  }
}

sub objCopy
{
	my $result;

	# convert the ELF file to an SREC
	$result = system("nios2-elf-objcopy", @_);
	
	$result;
}

sub convert
{
	my %switches;
	my $result;
  
	# parse the arguments
	%switches = fcu_parse_args(@_);

	# convert the file
	$result = fcu_convert(\%switches);

	# let the caller know what happened
	print $result;
}

sub usage
{
    my $lf = shift;
    my $outfile = $lf . "_file";
    my $cf = uc $lf;

    my $message  =
"Usage: elf2$lf elf_file [low_address  high_address] [--width=width]\n" .
"                [--create-lanes=lanes] [$outfile]\n" .
"\n" .
"Options must be specified in the following order\n" .
"\n" .
"    elf_file               the elf input file\n" .
"    low address            beginning of the range to transform\n" .
"    high address           end of the range to transform\n" .
"    --width=width          [ 8 | 16 | 32 | 64 | 128]\n" .
"    --create-lanes=lanes   [0 | 1] (default 0)\n" .
"    $outfile               the $cf file to create\n" .
"\n" .
"elf2$lf transforms the data within an elf file in the address\n" .
"  range [low, high] into the corresponding $cf file.\n" .
"Lane files are optionally created (--create-lanes=1, default is 0).\n" .
"Lane file names are generated based on the output file by inserting\n" .
"  \"_lane0\", \"_lane1\", etc. before the \".$lf\" extension of the output\n" .
"  filename.\n" .
"\n" .
"example:\n" .
"\n" .
"   elf2$lf foo.elf 0 0x0FFF --width=32 --create_lanes=1 bar.$lf\n" .
"\n" .
" will create $cf files bar.$lf, bar_lane0.$lf, bar_lane1.$lf,\n" .
"    bar_lane2.$lf, and bar_lane3.$lf\n" ;

    die $message;
}

main(@ARGV);

# end of file
