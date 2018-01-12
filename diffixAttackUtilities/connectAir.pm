use strict;
package diffixAttackUtilities::connectAir;
use base 'Exporter';
our @EXPORT_OK = qw(
                    openAirLog
                    logAirEvent
                    getGetCmd
                    getPostCmd
                    getAirDataSources
                    getQueryResult
                    getAirDataSourceIdFromName
                    fixSqlForWindows
                    getSyncAirQuery
                    queryDatabaseAir
                    queryDatabaseAirQ
                    getColumnsFromAir
                    getQueryResult
                    pollForQuery
                   );
use JSON;
use File::Slurp;
use Test::JSON;
use Data::Dumper;
use Time::HiRes qw(usleep gettimeofday tv_interval);
use IO::Async::Timer::Periodic;
use IO::Async::Loop;
use lib '../../diffixAttackModules';
use diffixAttackConfig::genConfig qw( getAirToken getAirUrl );
use diffixAttackUtilities::processAnswers qw( getColumnsFromRes );

$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 0;
$Data::Dumper::Sparseseen = 0;

my $alfh = undef;

sub openAirLog {
my($fileName) = @_;
  open($alfh, ">>", $fileName)
    or die "ERROR: openRes: Can't open $fileName";
}

sub logAirEvent {
my($str) = @_;
  return if (!defined $alfh);
  print $alfh strftime('%Y-%m-%d %H:%M:%S',localtime);
  print $alfh "\n$str\n";
}

sub getGetCmd {
  my $url = getAirUrl();
  my $token = getAirToken();
  my $getCmd = "curl -k -X GET -H \"auth-token:$token\" $url";
}

sub getPostCmd {
  my $token = getAirToken();
  my $postCmd = "curl -k -X POST -H \"auth-token:$token\" -H \"Content-type:application/json\"";
  return $postCmd;
}

sub getAirDataSources {
  my $getCmd = getGetCmd();
  my $cmd = "$getCmd/api/data_sources";
  my $jsonStr = '';
  while (1) {
    `$cmd > ignore.txt`;
    logAirEvent($cmd);
    $jsonStr = read_file("ignore.txt");
    if (length($jsonStr) < 1000) {
      logAirEvent($jsonStr);
    }
    else {
      logAirEvent("Result too large to print");
    }
    last if (is_valid_json $jsonStr);
    #sleep 5;
  }
  my $ref = decode_json $jsonStr;
  return $ref;
}

sub getQueryResult {
my($qid) = @_;
  my $getCmd = getGetCmd();
  my $cmd = "$getCmd/api/queries/$qid";
  my $jsonStr = '';
  while (1) {
    `$cmd > ignore.txt`;
    logAirEvent($cmd);
    $jsonStr = read_file("ignore.txt");
    if (length($jsonStr) < 1000) {
      logAirEvent($jsonStr);
    }
    last if (is_valid_json $jsonStr);
    #sleep 5;
  }
  my $ref = decode_json $jsonStr;
  die "ERROR getQueryResult: query returned error $ref->{query}->{error}"
    if $ref->{query}->{error};
  return $ref;
}

sub getAirDataSourceIdFromName {
my($name) = @_;
  my $ref = getAirDataSources();
  my @sources = @{ $ref };
  foreach (@sources) {
    if ($_->{name} eq $name) {
      return $_->{id};
    }
  }
  die "getAirDataSourceIdFromName: no source named $name\n";
}

sub fixSqlForWindows {
my($sql) = @_;
  if ($^O eq "MSWin32") {
    $sql =~ s/>/^>/g;
    $sql =~ s/</^</g;
  }
  return $sql;
}

sub getColumnsFromAir {
my($run) = @_;
  $run->{sql} = "SHOW columns FROM $run->{table}";
  my ($airRes, $elapsed) = queryDatabaseAir($run);
  my ($cols, $types) = getColumnsFromRes($airRes);
  return ($cols, $types);
}

sub getSyncAirQuery {
my($db_name, $sql, $p) = @_;
  my $url = getAirUrl();
  $sql = fixSqlForWindows($sql);
  my $postCmd = getPostCmd();
  my $thingy = "\"{\\\"query\\\": {\\\"statement\\\": \\\"$sql\\\", \\\"data_source_name\\\": \\\"$db_name\\\"}}\"";
  my $cmd = "$postCmd -d $thingy $url/api/queries";
  my $jsonStr = '';
  while (1) {
    `$cmd > ignore.txt`;
    logAirEvent($cmd);
    $jsonStr = read_file("ignore.txt");
    if (length($jsonStr) == 0) {
      logAirEvent("Received Empty String!\n");
      die "Received Empty String\n";
    }
    if (length($jsonStr) < 1000) {
      logAirEvent($jsonStr);
    }
    last if (is_valid_json $jsonStr);
    #sleep 5;
  }
  my $ref = decode_json $jsonStr;
  if ($p) { print "Received from Air:\n"; print Dumper $ref; }

  if ($ref->{success} == 1) {
    return $ref->{query_id};
  }
  else {
    return undef;
  }
}

sub pollForQuery {
my($qid, $p) = @_;
  foreach my $try (1..5000) {
    my $airRes = getQueryResult($qid);
    if ($airRes->{query}->{query_state} ne "completed") {
      if ($p) { print "query state = $airRes->{query}->{query_state}\n"; }
      my $sleepTime = 500000;
      if ($try <= 2) {
        $sleepTime = 50000;
      }
      if ($p) { print "sleep $sleepTime us\n"; }
      usleep $sleepTime;
    }
    else { 
      return $airRes;
    }
  }
  return undef;
}

# This is the blocking version
sub queryDatabaseAir {
my($run) = @_;
  my ($airRes, $elapsedAir) = queryDatabaseAirReal($run, 1);

  return($airRes, $elapsedAir);
}

# This is the non-blocking version
sub queryDatabaseAirQ{
my($run) = @_;
  my $qid = queryDatabaseAirReal($run, 0);
  return($qid);
}

sub queryDatabaseAirReal {
my($run, $block) = @_;
  my $p = $run->{print};
  my $startTV = [ gettimeofday ];
  my $qid = getSyncAirQuery($run->{db}, $run->{sql}, $run->{print});
  die "queryDatabaseAir: no Query ID returned" if (!defined $qid);
  my $airRes = ();
  if ($block) {
    $airRes = pollForQuery($qid, $p);
    die "queryDatabaseAir: Query timed out" unless defined $airRes;
    my $newTV = [ gettimeofday ];
    my $elapsedAir = tv_interval($startTV, $newTV);
    return($airRes, $elapsedAir);
  }
  else {
    return $qid;
  }
}


# use "2>" to get a dump of the stdout

# my $url = getAirUrl();
# my $token = getAirToken();
# my $curlf = WWW::Curl::Form->new;
# $curlf->setopt(CURLOPT_URL, $url);
# $curlf->setopt(CURLOPT_SSL_VERIFYPEER,false);   # -k
# $curlf->formadd("auth-token", $token);
# $curlf->formadd("Content-type", "application/json");

1;
