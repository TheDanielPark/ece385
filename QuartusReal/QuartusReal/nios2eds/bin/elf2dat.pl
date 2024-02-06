use sh_launch;
use strict;

# -------------------------------
# nios-convert

sub main
{
  my $infile;
  my $outfile;
  my $tmpfile;

  my $base;
  my $end;
  my $width_in_bits;
  my $pad = 0;
  my $create_lanes = 0;
  my $endian = "--little-endian-mem";

  foreach my $arg (@_)
  {
    if ($arg =~ /^--little-endian-mem$/ || $arg =~ /^--big-endian-mem$/)
    {
      $endian = $arg;
    }
    else
    {
      usage("malformed argument '$arg'\n") unless $arg =~ /^--(\S+)=(\S+)/;
      my $arg = $1;
      my $value = $2;

      $arg =~ /^infile$/i        && do {$infile        = $value; next};
      $arg =~ /^outfile$/i       && do {$outfile       = $value; next};
      $arg =~ /^base$/i          && do {$base          = $value; next};
      $arg =~ /^end$/i           && do {$end           = $value; next};
      $arg =~ /^pad$/i           && do {$pad           = $value; next};
      $arg =~ /^create-lanes$/i  && do {$create_lanes  = $value; next};
      $arg =~ /^width$/i         && do {$width_in_bits = $value; next};
      print STDERR "elf2dat: ignoring unknown option '$arg'\n";
    }
  }
  usage ("missing argument: --infile\n") if ($infile eq ''); 
  usage ("missing argument: --outfile\n") if ($outfile eq '');
  usage ("missing argument: --width\n") if (!$width_in_bits);
  usage ("missing argument: --base\n") if ($base eq '');
  usage ("missing argument: --end\n") if  (!$end);

  # If $tmpfile already exists, use a different filename.
  $tmpfile = $outfile . '_elf2dat_tmp0';
  while (-e $tmpfile)
  {
    $tmpfile =~ s/([0-9]+)$/$1 + 1/e;
  }
  
  # Make an srec
  my $command = "nios2-elf-objcopy --output-target=srec $infile $tmpfile";
  system($command);
  
  # Now call flash2dat.
  $pad =~ s/[^0-9]//g;
  $command = "flash2dat --infile=$tmpfile --outfile=$outfile --width=$width_in_bits --base=$base --end=$end --pad=$pad --create-lanes=$create_lanes $endian";
  system($command);
  unlink $tmpfile;
}

sub usage
{
    my $message  = join ("\n", @_);
    
    $message .=  <<'EOM';
Usage: elf2dat --infile=file --outfile=file --width=width --base=address
               --end=address [--pad=number] [--create-lanes=number]
               [--little-endian-mem] [--big-endian-mem]

Options may be specified in any order.

    --infile=<elf-input-filename>
    --outfile=<dat-output-filename>
    --base=<base address>
    --end=<end address>
    --pad=[0 | 1] (default 1)
    --create-lanes=[0 | 1] (default 0)
    --width=[ 8 | 16 | 32 | 64 | 128]
    --little-endian-mem
    --big-endian-mem

Transforms the data within an elf file in the address range [base, end] into
  the corresponding dat file.
Lane files are optionally created (--create-lanes=1, default is 0).
Lane file names are generated based on the output file by inserting
  "_lane0", "_lane1", etc. before the ".dat" extension of the output
  filename.
If "--pad=1" is specified, any unspecified locations in memory will be
  filled with zeros.
If "--little-endian-mem" is specified, the memory is assumed to be little-endian.
If "--big-endian-mem" is specified, the memory is assumed to be big-endian.
If neither --little-endian-mem or --big-endian-mem is specified, the memory is assumed
  to be little-endian.  Note that the endianness of the elf file never effects
  the result.


example: 

    elf2dat --infile=foo.elf --outfile=bar.dat --width=32 --create-lanes=1
            --base=0 --end=0x1000

 will create DAT files bar.dat, bar_lane0.dat, bar_lane1.dat,
    bar_lane2.dat, bar_lane3.dat
EOM
    ;

    die $message;
}

usage() if !@ARGV;
main(@ARGV);

# end of file
