use strict;
use Math::Round qw(round);
package diffixAttackUtilities::bounties;
use base 'Exporter';
our @EXPORT_OK = qw(
                     getBounty
                     getScore
                     printScore
                   );

sub getBounty {
my ($alpha, $kappa) = @_;

my $alphaBounties = [
  [10, 5000],
  [1, 4500],
  [0.1, 4000],
  [0.01, 3500],
  [0.001, 3000],
  [0.0001, 2500],
  [0.00001, 2000],
  [0.000001, 1500],
  [0.0000001, 1000],
  [0.00000001, 900],
  [0.000000001, 800],
  [0.0000000001, 700],
  [0.00000000001, 600],
  [0, 500]
];

my $kappaFactors = [
  [95,1],
  [90,0.9],
  [80,0.6],
  [70,0.3],
  [50,0.1],
  [0,0]
];

  my $bounty = 0;
  my $factor = 0;
  foreach my $a (@{ $alphaBounties }) {
    if ($alpha >= $a->[0]) {
      $bounty = $a->[1];
      last;
    }
  }
  foreach my $k (@{ $kappaFactors }) {
    if ($kappa >= $k->[0]) {
      $factor = $k->[1];
      last;
    }
  }
  return($bounty * $factor);
}

# This routine can be used to compute alpha-kappa for some or
# all of the guesses. Either way, $totalTries includes all
# tries at a guess, whether or not the attacker decided not to
# make a guess.  Actual guesses is $right + $wrong
sub getScore {
my($score) = @_;

  my $guesses = $score->{right} + $score->{wrong};
  my $conf = 0;
  my $confImpv = 0;
  if ($guesses) {
    $conf = $score->{right} / $guesses;
    $score->{conf} = Math::Round::round($conf * 100);
    if ($score->{statProb} != 1) {
      $confImpv = ($conf - $score->{statProb}) / (1 - $score->{statProb});
    }
  }
  $score->{kappa} = Math::Round::round($confImpv * 100);
  $score->{alpha} = $guesses / ($score->{known} + 1);
  $score->{bounty} = getBounty($score->{alpha}, $score->{kappa});
  $score->{sig} = 1;
  
  return($score);
}

sub printScore {
my($fh, $s) = @_;
  my $gapStr = sprintf "%2d", $s->{gap};

  my $sbPr = sprintf "%.2f", $s->{statProb};
  my $rows = sprintf "%4d", $s->{rows};
  my $alpha = sprintf "%.6f", $s->{alpha};
  my $ci = $s->{kappa};
  if ($ci < 0) {$ci = -1};
  my $ciPr = sprintf "%3d", $ci;
  my $conf = sprintf "%3d", $s->{conf};
  my $sCat = sprintf "%3d", $s->{statCat};
  my $rCat = sprintf "%4d", $s->{rowCat};
  print $fh "C $conf K $alpha Ci $ciPr gap $gapStr sCat $sCat rCat $rCat avRows $rows right $s->{right} wrong $s->{wrong} cells $s->{known} stat $sbPr tag $s->{tag}\n";
}

1;
