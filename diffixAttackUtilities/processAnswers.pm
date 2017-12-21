use strict;
package diffixAttackUtilities::processAnswers;
use base 'Exporter';
our @EXPORT_OK = qw(
                     compareAnswerStructure
                     getHashesFromAnswers
                     getRowsAsArray
                     getColumnsFromRes
                     computeExpectedProb
                     getHashesFromAnswers1
                     getQuerySignature
                   );
use Scalar::Util qw(looks_like_number);
use Digest::MD4 qw(md4_base64);

$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 0;
$Data::Dumper::Sparseseen = 0;

sub compareAnswerStructure {
my($res, $resAir) = @_;
  my @cols = @{ $res->{query}->{columns} };
  my @colsAir = @{ $resAir->{query}->{columns} };
  die "ERROR: compareAnswerStructure $#cols != $#colsAir" if
    ($#cols != $#colsAir);
  for (0..$#cols) {
    die "ERROR: compareAnswerStructure $cols[$_] != $colsAir[$_]" if
      ($cols[$_] != $colsAir[$_]);
  }
}

sub makeKey {
my($row, $last) = @_;
  my $key = '';
  my $str = '';
  for (my $i = 0; $i <= ($last - 1); $i++) {
    my $val = $row->{row}->[$i];
    if (looks_like_number($val)) {
      if ($val - int($val)) {
        # This truncates reals to 3 digits, because postgres reals sometimes
        # keeps only that much (but in fact this is an unreliable way to
        # try to compare cloak output with postgres output for reals, so
        # be careful when trying to attack real columns).
        $str = sprintf "%0.3f", $val;
      }
      else {
        $str = sprintf "%d", $val;
      }
      # the raw database can return a fractional part with trailing
      # zeros, while the cloak may not, so we simply force a bunch of
      # zeros (even if the number is an 
      $key .= ":".$str;
    }
    else { $key .= ":".$val; }
  }
  return $key;
}

sub getHashesFromAnswers {
my($res, $resAir, $type) = @_;

# This routine assumes that the last column is the aggregate value
# (count, sum, or whatever), and all previous columns combined can
# be used as a key.
#
# This routine generates a string as a key in all cases, even when
# the raw data is a number.

  my %raw = ();
  my %air = ();

  my @rowsRaw = @{ $res->{query}->{rows} };
  my @rowsAir = @{ $resAir->{query}->{rows} };

  # figure out how many columns
  my @cols = @{ $res->{query}->{columns} };

  foreach my $row (@rowsRaw) {
    my $key = makeKey($row, $#cols);
    $raw{$key} = $row->{row}->[$#cols];
  }
  foreach my $row (@rowsAir) {
    if (($type eq "all") || ($row->{row}->[0] ne "*")) {
      my $key = makeKey($row, $#cols);
      $air{$key} = $row->{row}->[$#cols]; 
    }
  }
  return(\%raw, \%air);
}

sub getRowsAsArray {
my($res, $i) = @_;
  my @rows = ();
  foreach my $row ( @{ $res->{query}->{rows} }) {
    push @rows, $row->{row}->[$i];
  }
  return(\@rows);
}

sub getColumnsFromRes {
my($res) = @_;
  my @cols = ();
  my @types = ();
  foreach my $row ( @{ $res->{query}->{rows} }) {
    push @cols, $row->{row}->[0];
    push @types, $row->{row}->[1];
  }
  return(\@cols, \@types);
}

# This routine assumes that the first column is the thing to match,
# and the second column is the count of rows.  (Note that we don't
# assume distinct UIDs here.)
sub computeExpectedProb {
my($res, $match) = @_;
  my $totMatch = 0;
  my $total = 0;
  foreach my $row ( @{ $res->{query}->{rows} }) {
    $total += $row->{row}->[1];		# count
    if ($match eq $row->{row}->[0]) {
      $totMatch += $row->{row}->[1];
    }
  }
  die "ERROR: computeExpectedProg: No rows at all" if ($total == 0);
  return($totMatch / $total);
}

sub getHashesFromAnswers1 {
my($res) = @_;

  my %hash = ();
  my @rows = @{ $res->{query}->{rows} };

  foreach my $row (@rows) {
    if ($row->{row}->[0] ne "*") {
      $hash{$row->{row}->[0]} = $row->{row}->[1]; 
    }
  }
  return(\%hash);
}

sub getQuerySignature {
my($q) = @_;
  my $string = '';
  foreach (@{ $q->{baseVals} }) {
    $string .= $_;
  }
  foreach (@{ $q->{baseTypes} }) {
    $string .= $_;
  }
  foreach (@{ $q->{baseCols} }) {
    $string .= $_;
  }
  $string .= $q->{db};
  $string .= $q->{table};
  $string .= $q->{isolateVal};
  $string .= $q->{attack};
  $string .= $q->{isolateCol};
  $string .= $q->{unknownColType};
  $string .= $q->{isolateType};
  $string .= $q->{unknownCol};

  return md4_base64($string);
}

1;
