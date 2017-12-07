use strict;
package diffixAttackUtilities::getCombs;
use base 'Exporter';
our @EXPORT_OK = qw(
                     getBaseAndNonBaseFromMask
                     numBits
                     getNextMask
                     getBitMask
                   );


sub getBaseAndNonBaseFromMask {
my($mask, @cols) = @_;
  my @base = ();
  my @nonbase = ();
  my $i = 0;
  for (0..$#cols) {
    if ($mask & 1) {
      push @base, $i;
    }
    else {
      push @nonbase, $i;
    }
    $mask >>= 1;
    $i++;
  }
  return (\@base, \@nonbase);
}

sub numBits {
my($mask, $max) = @_;
  my $num = 0;
  for (0..$max) {
    if ($mask & 1) {
      $num++;
    }
    $mask >>= 1;
  }
  return $num;
}

sub getNextMask {
my ($bgs, $mask, $maxBits) = @_;
  my $max = 1 << $maxBits;
  for (0..10000) {
    $mask++;
    if ($mask >= $max) {
      return undef;
    }
    if (numBits($mask, $max) == $bgs) {
      return $mask;
    }
  }
  die "getNextMask failed ($bgs, $mask, $maxBits)";
}

sub getBitMask {
my ($bgs) = @_;
  my $mask = 0;
  for (my $bp = 0; $bp < $bgs; $bp++) {
    $mask |= 1 << $bp;
  }
  return $mask;
}

1;
