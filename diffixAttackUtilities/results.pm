use strict;
package diffixAttackUtilities::results;
use base 'Exporter';
our @EXPORT_OK = qw(
                     openRes
                     closeRes
                   );

use POSIX qw(strftime);

sub openRes {
my($run) = @_;
  open(my $resFh, ">>", $run->{resultsFile})
    or die "ERROR: openRes: Can't open $run->{resultsFile}";
  print $resFh "---------------------------------------\nStart: ";
  if ($run->{print}) { print "---------------------------------------\nStart: "; }
  print $resFh strftime('%Y-%m-%d %H:%M:%S',localtime);
  if ($run->{print}) { print strftime('%Y-%m-%d %H:%M:%S',localtime); }
  print $resFh "\nTest: $run->{testName}\n";
  if ($run->{db}) { print $resFh "DB: $run->{db}\n"; }
  if ($run->{table}) { print $resFh "table: $run->{table}\n"; }
  if ($run->{sql}) { print $resFh "SQL: $run->{sql}\n"; }

  if ($run->{print}) {
    print "\nTest: $run->{testName}\n";
    if ($run->{db}) { print "DB: $run->{db}\n"; }
    if ($run->{table}) { print "table: $run->{table}\n"; }
    if ($run->{sql}) { print "SQL: $run->{sql}\n"; }
  }
  close $resFh;
}

sub closeRes {
my($res) = @_;
  open(my $resFh, ">>", $res->{resultsFile})
    or die "ERROR: closeRes: Can't open $res->{resultsFile}";
  $res->{outcome} = "PASS";
  my $failReport;
  my $report = '';
  if (exists $res->{closeRoutine}) {
    ($failReport, $report) = &{$res->{closeRoutine}}($res);
  }
  else {
    die "ERROR: closeRes: No closeRoutine";
  }
  $report .= "End: ";
  $report .= strftime('%Y-%m-%d %H:%M:%S',localtime);
  $report .= "\n";
  if ($res->{print}) { print $report; }
  print $resFh $report;
  print $report;
  close $resFh;
  if ($failReport eq "FAIL") {
    # Here is where we report fail if this is an automated test
  }
  else {
    # Here is where we report pass if this is an automated test
  }
}

1;
