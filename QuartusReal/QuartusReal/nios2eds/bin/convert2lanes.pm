use strict;
# Sadly, I can't use indirect filehandles under strict 'refs'.
# Just say no!
no strict 'refs';

package convert2lanes;

sub newopen
{
  my $path = shift;
  local *FH;
  open (FH, $path) || return undef;
  return \*FH;
}

sub translate_to_native_address
{
  my ($byteaddr, $base, $wordSize) = @_;
  return ($byteaddr - $base) / $wordSize;
}
  
# Input hash:
# 
# infile => <input filename>
# output_template => <output template filename>
# width_in_bits => <width in bits>
# 
sub dat2lanes
{
  my $options = shift;

  my $wordSize = $options->{width_in_bits} / 8;

  return "missing argument"
    if ($options->{infile} eq '') || ($options->{output_template} eq '') || !$wordSize;

  return "Couldn't open input-file ($options->{infile}): $!"
    unless  open (INFILE, "<$options->{infile}");

  # Figger the output file names.
  $options->{output_template} =~ s/X([^X]*)$/%d$1/;

  my @output_files = map {sprintf($options->{output_template}, $_)} (0 .. $wordSize - 1);
  my @output_file_handles;
  
  my $file_number = 0;
  for (@output_files)
  {
    my $fh = "FILE$file_number";
    if (!open($fh, ">$_"))
    {
      return "Failed to open output file '$_' ($!)";
    }

    push @output_file_handles, $fh;

    $file_number++;
  }

  my $native_addr = 0;
  while (<INFILE>)
  {
    my @words = split;

    for (@words)
    {
      my $data = '';

      # Each word is address (starts with '@') or data.
      if (/^(\@*)([A-Fa-f0-9]+)/)
      {
        if ($1 eq '@')
        {
          $native_addr = hex($2);
          next;
        }
        else
        {
         # Convert string to an array of characters.
         my @datChars = split (//, $2);
         # Funnel $data at address '$native_addr' out to the lane files.
         for (@output_file_handles)
          { 
         	my $nibble2 = pop(@datChars);
   		my $nibble1 = pop(@datChars);
  		my $byteString = $nibble1.$nibble2;
  		printf $_ "@%08X %s\n", $native_addr, $byteString;

          }
          # Either the next item is data, in which case we need
          # this auto-increment, or it's address, and will override
          # the auto-incremented value.
          $native_addr++;
        }      
      }
    }
  }

  for (@output_file_handles)
  {
    close $_;
  }
}

# Input hash:
# 
# infile => <input filename>
# output_template => <output template filename>
# width_in_bits => <width in bits>
# 
sub hex2lanes
{
  my $options = shift;

  my $wordSize = $options->{width_in_bits} / 8;

  return "missing argument"
    if ($options->{infile} eq '') || ($options->{output_template} eq '') || !$wordSize;

  return "Couldn't open input-file ($options->{infile}): $!"
    unless  open (INFILE, "<$options->{infile}");

  # Figger the output file names.
  $options->{output_template} =~ s/X([^X]*)$/%d$1/;
  
  my @output_files = map {sprintf($options->{output_template}, $_)} (0 .. $wordSize - 1);
  my @output_file_handles;
  
  my $file_number = 0;
  for (@output_files)
  {
    my $fh = "FILE$file_number";
    if (!open($fh, ">$_"))
    {
      return "Failed to open output file '$_' ($!)";
    }

    push @output_file_handles, $fh;

    $file_number++;
  }

  my $native_addr = 0;
  my $base_address = 0;
  while (<INFILE>)
  {
    chomp;
    if (!/^:([A-Fa-f0-9]{2})([A-Fa-f0-9]{4})([A-Fa-f0-9]{2})([A-Fa-f0-9]*)([A-Fa-f0-9]{2})$/)
    {
      print STDERR "hex2lanes::hex2lanes(): Skipping unrecognized hex file line\n\t'$_'\n\n";
      next;
    }
    
    my $length = hex($1);
    my $address = hex($2);
    my $type = $3;
    my $data = $4;
    my $checksum = $5;

    # Echo any address or EOF records.
    if ($type eq '01' || $type eq '02' || $type eq '04')
    {
      # Echo the same segment record to the output files.
      for my $fh (@output_file_handles)
      {
        print $fh "$_\n";
      }
    }

    next if $type eq '01';  # end of file?
    
    # Segment address
    if ($type eq '02')
    {
      $base_address = hex($data) << 4;
      next;
    }

    # Linear address
    if ($type eq '04')
    {
      $base_address = hex($data) << 16;
      next;
    }
    
    # Data
    if ($type eq '00')
    {
      my $nibbles = $wordSize * 2;
      my @native_words = ($data =~ /([A-Fa-f0-9]{$nibbles})/g);
      map {$_ = hex} @native_words;

      for my $native_word (@native_words)
      {
        for my $fh (@output_file_handles)
        {
          # Write a complete hex record for this byte.
          my $record_byte_count = 1;
          my $record_address = $address;
          my $record_type = 0;
          my $record_data = $native_word & 0xFF;
          my $record_sum = 
            $record_byte_count + ($record_address & 0xFF) + (($record_address >> 8) & 0xFF) + $record_data;
          $record_sum ^= 0xFFFFFFFF;
          $record_sum++;
          $record_sum &= 0xFF;
          
          printf $fh ":%02X%04X%02X%02X%02X\n", $record_byte_count, $record_address, $record_type, $record_data, $record_sum;
          $native_word >>= 8;
        }
      }
      next;
    }

    # It looked parseable, but it wasn't.
    return "Can't parse hexfile record '$_'";

  }
  close INFILE;

  for (@output_file_handles)
  {
    close $_;
  }
  
  return ''; # Success!
}

sub usage
{
  my $err = shift;
  die qq[

$err

Usage:

  convert2lanes::{hex|dat}2lanes(<hash-ref>)
  
  hash-ref is:
  {
    infile => <input filename>,
    output_template => <output template filename>, \# e.g. foo_laneX.{hex|dat}
    width_in_bits => <width in bits>,
  }
  
];
}

1;
