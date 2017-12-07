use strict;
package diffixAttackUtilities::databaseRoutines;
use base 'Exporter';
our @EXPORT_OK = qw(
                     svConnect
                     executeSqlCommand
                     printRows
                     oneCmd
                     queryDatabaseRaw
                     makeISOdate
                     svDisconnect
                   );
use DBI;
use Storable qw(dclone);
use Time::HiRes qw(gettimeofday tv_interval);
use DateTime;
use Date::Parse;
use Scalar::Util::Numeric qw(isint);

# various subroutines for making  calls to either the postgres
# installation at MPI, or the mysql installation on localhost
# This is just a prototype, so the setup is pretty fragile.


sub svDisconnect {
my ($dbh) = @_;
  $dbh->disconnect;
}

sub svConnect {
my ($db) = @_;

  my $dbh;
  if ($db->{server} eq "pg") {
    while (1) {
      $dbh = DBI->connect("dbi:Pg:dbname=$db->{dbname};
                        host=$db->{host};
                        port=$db->{listenport};
                        sslmode=prefer", 
                        "$db->{username}", 
                        "$db->{password}",
                        { RaiseError => 0 });
      last if defined $dbh;
      print "$DBI::errstr\n";
      sleep 5;
    }
  }
  elsif ($db->{server} eq "mysql") {
    $dbh = DBI->connect("dbi:mysql:host=$db->{host};", 
                        "$db->{username}", 
                        "$db->{password}",
                        { RaiseError => 1 });
  }
  elsif ($db->{server} eq "mssql") {
    $dbh = DBI->connect("dbi:ODBC:Driver={SQL Server};Server=$db->{host};UID=$db->{username};PWD=$db->{password}", 
                        { RaiseError => 1 });
  }
  else {
    die "svConnect(): unrecognized db type ".$db->{server};
  }
  
  if (!defined $dbh) {
    die "DBI: connect failed: ".$DBI::errstr;
  }
  if (($db->{server} eq "mysql") || ($db->{server} eq "mssql")) {
    my $cmd = "USE $db->{dbname}";
    eval { $dbh->do($cmd); };
    if ($@) {
      die "DBI: USE command failed ".$@;
    }
  }
  if ($db->{server} eq "mysql") {
    my $cmd = "SET sql_mode = 'ANSI,NO_BACKSLASH_ESCAPES'";
    eval { $dbh->do($cmd); };
    if ($@) {
      die "DBI: SET sql_mode command failed ".$@;
    }
  }

  return($dbh);
}

sub executeSqlCommand {
my($dbh, $sql) = @_;
  my $sth = undef;
  my $rv = undef;
  eval { $sth = $dbh->prepare($sql); };
  if ($@) {
    die "SQL prepare failed ('$sql'): ".$@;
  }

  print "Execute query $sql\n";
  eval { $rv = $sth->execute; };
  if (!defined $rv) {
    # ODBC isn't catching a 'die' with SQL Server, so check for error
    # this way.
    my $errMsg = $DBI::errstr;
    print "DBI::errstr = '$errMsg'\n";
    die "The following query was sent to the SQL database:\n$sql\n The database generated the following error message: '$errMsg'";
  }
  if ($@) {
    die "The following query was sent to the SQL database:\n$sql\n The database generated the following error message: '$@'";
  }
  return $sth;
}

sub printRows {
my ($sth) = @_;
  my @row;
  while (@row = $sth->fetchrow_array()) {
    print "@row\n";
  }
}

sub oneCmd {
my ($dbh, $cmd) = @_;

  my $sth = $dbh->prepare($cmd)
     or die "Couldn't prepare statement: $cmd\n" . $dbh->errstr;
  $sth->execute()
     or die "Couldn't execute statement: $cmd\n" . $sth->errstr;
  return $sth;
}

# queryDatabaseRaw generates a reference structure that has the same
# structure of that returned by the air (after convert from JSON)
sub queryDatabaseRaw {
my ($dbh, $sql) = @_;
  my $startTV = [ gettimeofday ];
  my $sth = undef;
  eval { $sth = $dbh->prepare($sql); };
  die "ERROR queryDatabase: SQL prepare failed: $@" if ($@);
  my $rv = undef;
  eval { $rv = $sth->execute; };
  die "ERROR queryDatabase: SQL execute failed: $@" if ($@);
  my $newTV = [ gettimeofday ];
  my $elapsed = tv_interval($startTV, $newTV);
  # let's build a structure similar to the one air produces
  # first the column names
  my $res = undef;
  my @colNames = @{ $sth->{NAME_lc} };
  for (my $i = 0; $i <= $#colNames; $i++) {
    $res->{query}->{columns}->[$i] = $colNames[$i];
  }
  # then the rows
  my $rowNum = 0;
  while (1) {
    my $row = undef;
    eval { $row = $sth->fetchrow_arrayref(); };
    die "ERROR queryDatabase: fetchrow_arrayref failed: $@" if ($@);
    last if (!defined $row);
    # we need to make a copy of the row
    my $clone = dclone($row);
    for (0..$#colNames) {
      $res->{query}->{rows}->[$rowNum]->{row}->[$_] = $clone->[$_];
      # if the value is a datetime, we need to convert it to the same
      # format that the cloak produces.
      my ($ss,$mm,$hh,$day,$month,$year,$zone) = 
                   strptime($res->{query}->{rows}->[$rowNum]->{row}->[$_]);
      if ((defined $year) && (defined $month) && (defined $day) &&
          (defined $hh) && (defined $mm) && (defined $ss)) {
        # assume this is a date, so format:
        $res->{query}->{rows}->[$rowNum]->{row}->[$_] =
               makeISOdate($ss,$mm,$hh,$day,$month,$year,
                           $res->{query}->{rows}->[$rowNum]->{row}->[$_]);
      }
    }
    $rowNum++;
  }
  $sth->finish;
  $res->{query}->{row_count} = $rowNum;
  return($res, $elapsed);
}

sub makeISOdate {
my ($ss,$mm,$hh,$day,$month,$year,$val) = @_;
  my $ns = 0;
  if (($year < 1900) || ($year > 2100)) {
    # this happens a lot with banking
    return $val;
  }
  if (defined $ss) {
    if (!isint $ss) {
      my $frac = $ss - int($ss);
      $frac = sprintf "%0.6f", $frac;
      $ns = int($frac * 1000000000);
    }
    $ss = int($ss);
  }
  my $dt;
  eval {
    $dt = DateTime->new(
      year       => $year + 1900,
      month      => $month + 1,
      day        => $day,
      hour       => $hh,
      minute     => $mm,
      second     => $ss,
      nanosecond => $ns
    );
  };
  if ($@) {
    # don't convert if something wrong with date params
    return $val;
  }
  else {
    return $dt->strftime("%Y-%m-%dT%H:%M:%S.%6N");
  }
}

1;
