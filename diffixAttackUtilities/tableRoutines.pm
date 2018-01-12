use strict;
package diffixAttackUtilities::tableRoutines;
use base 'Exporter';
our @EXPORT_OK = qw(
                     getRandomDb
                     getTablesFromDb
                     getRandomTable
                     getColumnsFromTable
                     getRandomColumn
                   );

use lib '../';
use Data::Dumper;
use Math::Random qw(random_uniform_integer);
use diffixAttackConfig::processAnswers qw(getRowsAsArray);
use diffixAttackConfig::connectAir qw(getSyncAirQuery pollForQuery);
use diffixAttackConfig::genConfig qw(getDbList);

$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 0;
$Data::Dumper::Sparseseen = 0;

sub getRandomDb {
  my $dbList = getDbList();
  my @dbList = @{ $dbList };
  my $index = random_uniform_integer(1, 0, $#dbList);
  return $dbList[$index];
}

sub getTablesFromDb {
my($db) = @_;
  my $sql = "SHOW TABLES";
  my $qid = getSyncAirQuery($db, $sql);
  die "getTablesFromDb: no Query ID returned" if (!defined $qid);
  my $res = pollForQuery($qid, 0);
  die "Query timed out" unless defined $res;
  my $tables = getRowsAsArray($res, 0);
  return $tables;
}

sub getRandomTable {
my($db) = @_;
  my $tables = getTablesFromDb($db);
  my @tables = @{ $tables };
  my $index = random_uniform_integer(1, 0, $#tables);
  return $tables[$index];
}

sub getColumnsFromTable {
my($db, $tab) = @_;

  my $sql = "SHOW COLUMNS FROM $tab";
  my $qid = getSyncAirQuery($db, $sql);
  die "getColumnsFromTable: no Query ID returned" if (!defined $qid);
  my $res = pollForQuery($qid, 0);
  die "Query timed out" unless defined $res;
 
  my $columns = getRowsAsArray($res, 0);
  return $columns;
}

sub getRandomColumn {
my($db, $tab) = @_;
  my $columns = getColumnsFromTable($db, $tab);
  my @columns = @{ $columns };
  my $index = random_uniform_integer(1, 0, $#columns);
  return $columns[$index];
}

# --------- The following for creating and changing tables ----------

my $tabConfig = [
  {
    tabName => "testtable",
    colNames => [
       "uid",
       "txt1", "txt2", "txt3", "txt4", "txt5",
       "int1", "int2", "int3", "int4", "int5",
       "real1", "real2", "real3", "real4", "real5",
       "date1", "date2", "date3", "date4", "date5"
     ],
    colTypes => [
       "int",
       "text", "text", "text", "text", "text",
       "integer", "integer", "integer", "integer", "integer",
       "real", "real", "real", "real", "real",
       "timestamp", "timestamp", "timestamp", "timestamp", "timestamp"
     ],
  },
];

1;
