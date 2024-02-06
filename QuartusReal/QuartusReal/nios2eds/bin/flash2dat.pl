#!perl
use sh_launch;
use convert2lanes;
use strict;

# GLOBALS
our $PN= "flash2dat";
our $memWidthInBits = 0;    # Width of memory in bits
our $memWidthInBytes = 0;   # Width of memory in bytes
our $memEccWidthInBits = 0; # Width of ECC memory in bits
our $memEccWidthInBytes = 0; # Width of ECC memory in bytes
our $memNumWords = 0;       # Number of memory-width words in memory
our $memAddrNibbles = 0;    # Number of nibbles in memory address
our $byteAddrAlignMask = 0; # Determines if byte address is mem width aligned
our $infile   = "";         # Name of input SREC file
our $outfile  = "";         # Name of output DAT file
our $baseByteAddr = '';     # Lowest byte address of interest
our $endByteAddr = '';      # Highest byte address of interest
our $zeroPadding = 0;       # Should the DAT file be padded with '0' (boolean)
our $createLanes = 0;       # Should laned DAT files also be created (boolean)
our $relocateByteOffset = 0;# Added to all SREC byte addresses
our $bigEndian = 0;         # Big-endian memory (boolean)
our $s0_seen = 0;
our $lineNum = 0;           # Current line number of SREC file
our $debug = 0;             # Hidden command-line option for debugging
our $firstDatEntry = 1;     # Is this the first DAT entry being written?
our $latestDatAddr;         # DAT address of most-recently written DAT entry.
our $zeroPadWord;           # String of enough zeros to match memory width

# CONSTANTS
our $FullDatEntriesOnly = 0;        # No padding allowed
our $PartialDatEntriesAllowed = 1;  # Padding allowed 

#main()
{
    parseArgs(@ARGV);

    # Holds byte entries from SREC file that are waiting to be converted
    # into DAT entries.  These byte entries always have contigous addresses.
    my @pendingByteEntries;
    
    # Process SREC input file one line at a time.
    while (<INFILE>) {
        $lineNum++;

        # Parse the SREC line.
        my @byteEntries = parseSrecLine($_);

        # Skip to next line if there isn't any data to process.
        if (scalar(@byteEntries) == 0) {
            next;
        }

        # Handle pending byte entries from previous SREC lines (if any).
        if (scalar(@pendingByteEntries) != 0) {
            # If the byte entries of this SREC line aren't contiguous with the 
            # pending byte entries, the pending byte entries need to be flushed
            # out by creating a partial DAT entry for them.
            if (!byteEntryArraysAreContiguous(\@pendingByteEntries,
              \@byteEntries)) {
                if ($debug) {
                    print "$PN: Flushing pendingByteEntries due to new" .
                     " non-contigous SREC line\n";
                }

                writeDatEntries(\@pendingByteEntries, 
                  $PartialDatEntriesAllowed);
            }
        }

        # Add SREC data from this line to the pending array.
        push(@pendingByteEntries, @byteEntries);

        # Scan through the pending byte entries and convert them to
        # one or more full DAT entries if possible.
        # All byte entries used to create a DAT entry are removed
        # from the pendingByteEntries array.
        writeDatEntries(\@pendingByteEntries, $FullDatEntriesOnly);

        if ($debug && scalar(@pendingByteEntries) != 0) {
            print "$PN: Got a bunch of pending byte entries left over:\n";
            displayByteEntryArray(\@pendingByteEntries);
        }
    }

    # Flush out any remaining byte entries (partial entries are okay).
    if (scalar(@pendingByteEntries) > 0) {
        if ($debug) {
            print "$PN: Flushing remaining pendingByteEntries before closing" .
              " DAT file\n";
        }

        writeDatEntries(\@pendingByteEntries, $PartialDatEntriesAllowed);
    }
    
    # If zero padding, fill with zero to the end of the memory, if required.
    if ($zeroPadding) {
        performZeroPadding($memNumWords); 
    }

    close OUTFILE;
    
    # If lanes were requested, provide them.
    # They're made from the just-created output file.
    if ($createLanes) {
        my $output_template = $outfile;

        $output_template =~ s/([^\.]+)\.([^\.]+)$/$1_laneX.$2/;
      
        my $ret = convert2lanes::dat2lanes({
            infile => $outfile,
            output_template => $output_template,
            width_in_bits => $memWidthInBits,
        });
      
        if ($ret) {
            $ret = "\ninternal error:\n" . $ret;
            convert2lanes::usage($ret);
        }
    }

    exit(0);
}

sub 
usage
{
   my $message  = join ("\n", @_);
      $message .=  <<EOM

Converts a .flash-file (which is really a .srec-file) into a Verilog 
.dat-file.  Please specify base and end address as hex (preceded by 0x).


Usage: flash2dat --infile=<flash-input-filename>
                 --outfile=<dat-output-filename>
                 --width=[ 8 | 16 | 32 | 39 | 64 | 128]
                 --base=<base byte-address of range of interest>
                 --end=<last byte-address of range of interest>
                 --pad=<1 if all locations should be represented in output>
                 --create-lanes=<1 if lane files should be created>
                 --relocate-input=<input-data relocation offset (usually=base)>
                 [--little-endian-mem] [--big-endian-mem]

Example:

  flash2dat --infile=foo.flash --outfile=foo.dat --width=32 --base=0x1000000 \\
    --end=0x1000FFF --pad=1 --create-lanes=1 --relocate=0x1000000

  creates files foo.dat, foo_lane0.dat, foo_lane1.dat, foo_lane2.dat and
  foo_lane3.dat. foo.dat contains 4K bytes of data, padded with 0 where
  data was not present in the .flash file. foo_lane[0123].dat each contain
  1K bytes of data from their respective byte lanes. the input .flash file
  data should be relocated by 0x1000000 to correspond to the specified
  --base address.

EOM
    ;

    die $message;
}

sub
parseArgs
{
    my @args = @_;

    # Did someone ask for help?  This overrides everything else.
    usage() if grep {/^--help$/i} @args;
    
    foreach my $arg (@args) {
        if ($arg =~ /^--little-endian-mem$/) {
            $bigEndian = 0;
        } elsif ($arg =~ /^--big-endian-mem$/) {
            $bigEndian = 1;
        } elsif ($arg =~ /^--debug$/) {
            $debug = 1;
        } else {
            usage("malformed argument") unless $arg =~ /^--(\S+)=(\S+)/;
            my $argname = $1;
            my $value = $2;
            if ($argname =~ /^width$/i) {
                if (($value!=8) && ($value!=16) && ($value!=32) && 
                  ($value!=39) && ($value!=64) && ($value!=128)) {
                    usage("Bad data-width");
                }

		# Given that the width parameter now describes
		# the width of ECC/non-ECC memory, for non-ECC
		# memory width is always power of 2 while ECC
		# memory are not, hence we'll first assume the
		# width might be ECC memory.
		$memEccWidthInBits = $value;

		# Number of bytes to fit a code & data word.
		# For non-ECC memories, these values are always
		# the same. memEccBits is the number of extra bits. 
		# Assumes memEccBits is less then eight.
		my $memEccBits = $value % 8;
		
		#number of bytes to hold word without memEccBits
		$memWidthInBytes = (($value - $memEccBits) / 8);
		
		#number of bytes to hold word with memEccBits 
		$memEccWidthInBytes = ($memEccBits == 0) ? $memWidthInBytes : $memWidthInBytes + 1;

		# Number of bits for a data word, the value is
		# always power of 2.
		#
		# For non-ECC memories, we'll always get
		# ($memEccWidthInBits == $memWidthInBits)
		# meaning we don't need to generate ECC code word
		# 
		# When ($memEccWidthInBits > $memWidthInBits), we
		# can determine the parity scheme by calculating  
		# ($memEccWidthInBits - $memWidthInBits) to see
		# how many parity bits need to be added
		$memWidthInBits = $memWidthInBytes * 8;

                $byteAddrAlignMask = $memWidthInBytes - 1;
                $zeroPadWord = "0" x ($memWidthInBytes * 2);
            } elsif ($argname =~ /^infile$/i) {
                $infile = $value;
            } elsif ($argname =~ /^outfile$/i) {
                $outfile = $value;
            } elsif ($argname =~ /^base$/i) {
                $value = oct($value) if $value =~ /^0/;
                $baseByteAddr = $value;
            } elsif ($argname =~ /^end$/i) {
                $value = oct($value) if $value =~ /^0/;
                $endByteAddr = $value;
            } elsif ($argname =~ /^pad$/i) {
                $zeroPadding = $value;
            } elsif ($argname =~ /^create-lanes$/i) {
                $createLanes = $value;
            } elsif ($argname =~ /^relocate-input$/i) {
                $value = oct($value) if $value =~ /^0/;
                $relocateByteOffset = $value;
            }
        }
    }

    usage ("missing argument") if ($infile eq '') || ($outfile eq '') ||
      !$memWidthInBytes || ($baseByteAddr eq '') || ($endByteAddr eq '');
    
    usage ("Couldn't open input-file ($infile): $!") unless 
        open (INFILE, "<$infile");
    
    usage ("Couldn't open output-file ($outfile): $!") unless 
        open (OUTFILE, ">$outfile");

    usage("Base address isn't less than the end address: $!") if
      ($baseByteAddr > $endByteAddr);

    # Compute number of words in memory.
    my $memNumBytes = $endByteAddr - $baseByteAddr + 1;
    $memNumWords = $memNumBytes / $memWidthInBytes;

    # Compute number of nibbles in memory address.
    my $memAddrBits = bitsToEncode($memNumWords-1);
    $memAddrNibbles = int(($memAddrBits + 3) / 4);

    if ($debug) {
        printf("$PN: base=0x%x end=0x%x numBytes=%d numWords=%d" .
          " memAddrBits=%d memAddrNibles=%d\n",
          $baseByteAddr, $endByteAddr, $memNumBytes, $memNumWords,  
          $memAddrBits, $memAddrNibbles);
    }
}
    
# Converts an absolute byte address into a DAT-file address.
# DAT file addresses are relative to the start of the memory
# (they always start at zero) and are in units of the memory width.
# For example, given an absolute byte address of 0x4040 for a 32-bit wide
# memory with a base byte address of 0x4000, the DAT address is
#   (0x4040-0x4000) / 4 = 0x40 / 4 = 0x10
sub 
byteAddr2DatAddr
{
    my $byteaddr = shift;

    return ($byteaddr - $baseByteAddr) / $memWidthInBytes;
}

# Takes an absolute byte address and returns its byte offset into the 
# DAT address.  If the byte address is aligned the the memory width,
# it returns an offset of zero.
sub 
byteAddr2DatByteOffset
{
    my $byteaddr = shift;

    return ($byteaddr - $baseByteAddr) & $byteAddrAlignMask;
}

# Returns a boolean indicating if the two arrays of byte entries are contiguous.
# They are not considered contigous if either array is empty.
# Each array is assumed to contain contiguous bytes.
sub
byteEntryArraysAreContiguous
{
    my $byteEntriesARef = shift;
    my $byteEntriesBRef = shift;

    my $numEntriesA = scalar(@$byteEntriesARef);
    my $numEntriesB = scalar(@$byteEntriesBRef);

    if (($numEntriesA == 0) || ($numEntriesB == 0)) {
        return 0;   # Not considered contiguous
    }

    # Get the address ranges of each array.
    my $minByteAddrA = ${$byteEntriesARef}[0]->{byteAddr};
    my $maxByteAddrA = ${$byteEntriesARef}[$numEntriesA-1]->{byteAddr};
    my $minByteAddrB = ${$byteEntriesBRef}[0]->{byteAddr};
    my $maxByteAddrB = ${$byteEntriesBRef}[$numEntriesB-1]->{byteAddr};

    # See if the ranges are contiguous.
    if ($minByteAddrA < $minByteAddrB) {
        return (($maxByteAddrA + 1) == $minByteAddrB);
    } elsif ($minByteAddrB < $minByteAddrA) {
        return (($maxByteAddrB + 1) == $minByteAddrA);
    } else {
        printf("$PN: Array A address range: 0x%x to 0x%x\n",
          $minByteAddrA, $maxByteAddrA);
        printf("$PN: Array B address range: 0x%x to 0x%x\n",
          $minByteAddrB, $maxByteAddrB);

        print "$PN: Array A:\n";
        displayByteEntryArray($byteEntriesARef);

        print "$PN: Array B:";
        displayByteEntryArray($byteEntriesBRef);

        die "$PN: $infile:$lineNum Min address ranges are the same\n";
    }
}

# Parses an SREC line of type 1, 2, or 3.  These correspond to a data entry
# with a 2-byte, 3-byte, or 4-byte address respectively.
# Returns an array of hashes.  
#
# Each hash contains the following fields:
#   byteAddr        The byte address (integer)
#   byteHexStr      The byte hexadecimal string
# The array is in order from lowest to highest byte address.  All bytes
# are for contiguous addresses.

sub 
parseSrecLine
{
    my $line = shift;

    my @byteEntries;    # Holds return value

    # Get rid of newline.
    chomp($line);

    if ($debug) {
        print "$PN: SREC Line '$line'\n";
    }
    
    # Blank lines are ignored.
    if ($line =~ /^\s*$/) {
        return ();
    }

    # Ignore these records.
    if ($line =~ /^S[05789]/) {
        return ();
    }

    # Ensure this is a recognized record type.  Also, as a side-effect,
    # set $1 to the record type.
    if (!($line =~ /^S([123])/)) {
        die "$PN: $infile:$lineNum Unrecognized S-record: '$line'\n";
    }

    my $recType = $1;
    my $numAddrBytes = $recType + 1;

    # Ensure this is a proper record entry.  Also, as a side-effect,
    # set $1, $2, etc. to the interesting fields in the entry.
    if (!($line =~ /^S[123]([\S]{2})([\S]{@{[2 * $numAddrBytes]}})(\S*)([\S]{2})\s*$/)) {
        die "$PN: $infile:$lineNum Malformed S[123] record: '$line'\n" 
    }

    my $recLen   = hex($1);
    my $recByteAddr = hex($2) + $relocateByteOffset;
    my $recData  = $3;
    my $sum      = $4;

    # $recType + 1 bytes for address, 1 for checksum, the rest for data.
    my $recBytes = $recLen - 1 - $numAddrBytes;
    if ($recBytes != (length($recData) / 2)) {
        my $gotBytes = length($recData) / 2;
        die("$PN: $infile:$lineNum Inconsistent length in record" .
          " ($recBytes vs. $gotBytes): $line");
    }

    if ($debug) {
        printf("$PN:   recLen=%d recByteAddr=0x%x recData='%s'\n",
          $recLen, $recByteAddr, $recData);
    }
   
    # Convert data string into an array of characters.
    my @datChars = split (//, $recData);

    # Now convert each byte of data into an array of hashes.
    # Each hash contains the byte address and the data byte.
    for (my $byteOffset = 0; $byteOffset < $recBytes; $byteOffset++) {
        # Compute the byte address of this byte.
        my $byteAddr = $recByteAddr + $byteOffset;

        # Skip this byte if it is out of the specified address range.
        if (($byteAddr < $baseByteAddr) || ($byteAddr > $endByteAddr)) {
            next;
        }

        # Get the 2 hex digits for this byte.
        my $byteHexStr = shift(@datChars) . shift(@datChars);

        # Now add this byte to the array.
        push(@byteEntries,
          { byteAddr => $byteAddr, byteHexStr => $byteHexStr }
        );

        if ($debug) {
            printf("$PN:  byteAddr=0x%x byteHexStr='%s'\n",
              $byteAddr, $byteHexStr);
        }
    }

    return @byteEntries;
}

# Writes out all the DAT entries possible from the byte entry array.
# Any byte entries that are used to create a DAT entry are removed
# from the byte entry array reference.
sub
writeDatEntries
{
    my $byteEntriesRef = shift;
    my $partialOrFull = shift;

    while (scalar(@$byteEntriesRef) > 0) {
        # See if there is a byte entry with a byte offset corresponding
        # to the last byte in a memory word.
        my $lastIndex = findByteEntryForLastMemoryByte($byteEntriesRef);

        if ($lastIndex == -1) {
            # There was no byte entry available that corresponds to the
            # last byte in a memory word so a full DAT entry can't be created.
            #
            # If only full entries are allowed, just return.
            # There will be some byte entries remaining in the input array.
            if ($partialOrFull == $FullDatEntriesOnly) {
                return;
            }

            # Just use what byte entries are available to create a DAT entry.
            # It will be padded as necessary to make a DAT entry 
            # corresponding to the full memory width.
            $lastIndex = (scalar(@$byteEntriesRef) - 1);

            if ($debug) {
                print "$PN: Writing out a partial DAT entry (padded)\n";
            }
        } else {
            if ($debug) {
                print "$PN: Writing out a full DAT entry\n";
            }
        }

        # Create an array of byte entries used to create one DAT entry.
        # Remove byte entries required to create a DAT entry from
        # the input array and add them to the datBytes array.
        my @datByteEntries;

        for (my $index = 0; $index <= $lastIndex; $index++) {
            push(@datByteEntries, shift(@$byteEntriesRef));
        }

        writeOneDatEntry(@datByteEntries);
    }
}

# Takes an array of byte entries (assumed to be contiguous) and
# writes out one DAT entry corresponding to the width of the memory.
#
# If there are aren't enough byte entries to match the width of the memory,
# 'x' bytes are used for padding.
sub
writeOneDatEntry
{
    my @byteEntries = @_;

    my $datDataStr;

    if (scalar(@byteEntries) == 0) {
        die "$PN: $infile:$lineNum Can't emit an empty DAT entry\n";
    }

    if ($debug) {
        print "$PN: Writing DAT entry for:\n";
        displayByteEntryArray(\@byteEntries);
    }

    # The DAT address is just the first byte address converted to a DAT address.
    my $entryDatAddr = byteAddr2DatAddr($byteEntries[0]->{byteAddr});

    # Create one DAT entry with a number of bytes equal to the memory width.
    # Fill in with 'x' bytes as required.
    # This loop consumes the byteEntries array.
    for (my $byteOffset = 0; $byteOffset < $memWidthInBytes; $byteOffset++) {
        # Default is that padding will be required.
        my $byteHexStr = $zeroPadding ? "00" : "xx";

        # See if first byte entry matches the required byte offset.
        if (scalar(@byteEntries) > 0) {
            my $entryByteAddr = $byteEntries[0]->{byteAddr};
            my $entryByteOffset = byteAddr2DatByteOffset($entryByteAddr);

            if ($byteOffset == $entryByteOffset) {
                # Byte entry matches the required byte offset so use it.
                $byteHexStr = $byteEntries[0]->{byteHexStr};
                shift(@byteEntries);
            }
        }

        if ($bigEndian) {
            $datDataStr = $datDataStr . $byteHexStr;
        } else {
            $datDataStr = $byteHexStr . $datDataStr;
        }
    }

    if (scalar(@byteEntries) != 0) {
        print "$PN: Remaining byte entries:\n";
        displayByteEntryArray(\@byteEntries);

        die "$PN: $infile:$lineNum Didn't consume byte entry array when" .
          " emiting DAT entry\n";
    }

    # Need to zero pad if there are gaps before this DAT entry.
    if ($zeroPadding) {
        performZeroPadding($entryDatAddr); 
    }

	# If code word (memory width) is larger
	# than data word with, let's append ECC
	# parity to the data word
	my $eccParityInBytes = $memEccWidthInBytes - $memWidthInBytes;

	if ($eccParityInBytes > 0) {
		my $eccParityHexChars = $eccParityInBytes * 2;
		printf(OUTFILE "@%0" . $memAddrNibbles . "X %0" . $eccParityHexChars . "X$datDataStr\n", $entryDatAddr, ecc(hex $datDataStr));
	} else {
		printf(OUTFILE "@%0" . $memAddrNibbles . "X $datDataStr\n", $entryDatAddr);
	}

    # Record the latest DAT address (used for zero padding).
    $latestDatAddr = $entryDatAddr;

    # No longer waiting for the first DAT entry to be written.
    $firstDatEntry = 0;
}

# Add zero padding as needed from the latest DAT entry written (if any)
# up to but not including the next DAT address.
sub
performZeroPadding
{
    my $nextDatAddr = shift; 

    my $nextSequentialDatAddr = $firstDatEntry ? 0 : ($latestDatAddr+1);

    if ($nextDatAddr != $nextSequentialDatAddr) {
        # Zero pad from the next sequential DAT address 
        for (my $datAddr = $nextSequentialDatAddr; $datAddr < $nextDatAddr; 
          $datAddr++) {
            printf(OUTFILE "@%0" . $memAddrNibbles . "X $zeroPadWord\n",
              $datAddr);
        }
    }
}

# Scan through all byte entries and find the first entry
# with a byte offset corresponding to the last byte in the DAT
# memory width (if any).
# Returns -1 if not found.
sub
findByteEntryForLastMemoryByte
{
    my $byteEntriesRef = shift;

    for (my $index = 0; $index < scalar(@$byteEntriesRef); $index++) {
        my $entryByteAddr = ${$byteEntriesRef}[$index]->{byteAddr};
        my $entryByteOffset = byteAddr2DatByteOffset($entryByteAddr);

        if ($entryByteOffset == ($memWidthInBytes-1)) {
            return $index; 
        }
    }

    return -1;  # Not found
}

# Given a NUMBER, return the number of bits it would take to represent it.
sub 
bitsToEncode
{
    my $x = shift;

    if ($x <= 0) {
        return 0;
    }

    return int(log2($x)) + 1;
}

sub 
log2
{
    my $number = shift;

    die "positive-number required for log2 not ($number)" if $number <= 0;
  
    my $log_base_e_of_2 = log 2;
  
    my $log_base_e_of_number = 
        ($number == 0) ? 0 :
        log $number;

    my $log_base_2_of_number = $log_base_e_of_number / $log_base_e_of_2;

    return $log_base_2_of_number;
}

sub
displayByteEntryArray
{
    my $byteEntryRef = shift;

    if (scalar(@$byteEntryRef) == 0) {
        print "$PN:   empty\n";
        return;
    }

    foreach my $byteEntry (@$byteEntryRef) {
        printf("$PN:   byteAddr=0x%x byteHexStr='%s'\n", 
          $byteEntry->{byteAddr}, $byteEntry->{byteHexStr});
    }
}

# A reduction XOR on 32-bit data, which is
# equivalent to calculating whether odd or
# even number of bits are set.
#
# CHA
#
sub reduction_xor {
	
	my $data = shift;
	
	# First, count the number of bits set,
	# i.e. the Hamming weight, using method
	# from http://en.wikipedia.org/wiki/Hamming_weight
	#
	# The alternative approach using Perl
	# is to pack/unpack string but that's
	# even less readable and maintainable
	# 
	my $b = 0x55555555 & $data;
	my $c = 0x55555555 & ($data >> 1);
	my $d = $b + $c;
	my $e = 0x33333333 & $d;
	my $f = 0x33333333 & ($d >> 2);
	my $g = $e + $f;
	my $h = 0x0f0f0f0f & $g;
	my $i = 0x0f0f0f0f & ($g >> 4);
	my $j = $h + $i;
	my $k = 0x00ff00ff & $j;
	my $l = 0x00ff00ff & ($j >> 8);
	my $m = $k + $l;
	my $n = 0x0000ffff & $m;
	my $o = 0x0000ffff & ($m >> 16);
	my $p = $n + $o;
	
	# We just need to know whether odd or
	# or even bits are set
	return $p & 1;
	
}

# Calculate ECC parity bits for an unsigned 
# 32-bit integer.
#
# This implementation is based on information
# available from:
#
# http://en.wikipedia.org/wiki/Hamming_code
#
# This implementation is also used for elf2hex.
#
# CHA
#
sub ecc {

	my $data = shift;

	# p5-0 are just matrix multiplication
	# the following Hamming (32,6) generator 
	# matrix can be calculated based on the 
	# formula from wikipedia.
	my $p0 = reduction_xor($data & 0x56AAAD5B);
	my $p1 = reduction_xor($data & 0x9B33366D);
	my $p2 = reduction_xor($data & 0xe3c3c78e);
	my $p3 = reduction_xor($data & 0x03fc07f0);
	my $p4 = reduction_xor($data & 0x03fff800);
	my $p5 = reduction_xor($data & 0xfc000000);
	my $p5to0 = ($p5 << 5) + ($p4 << 4) + ($p3 << 3) + ($p2 << 2) + ($p1 << 1) + ($p0 << 0);

	# p6 ensures the whole codeword (p5-0 + data)
	# has even parity.

	# First we'll determine parity of p5-0
	my $pp5to0 = reduction_xor($p5to0);
	# Then determine parity of data
	my $pdata = reduction_xor($data);

	# Lastly, another reduction xor on parity bits
	# of p5-0 and data.
	my $p6 = ($pp5to0 + $pdata) % 2;

	my $p = ($p6 << 6) + $p5to0;
	
	return $p;
}
