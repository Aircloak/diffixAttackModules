use strict;
package diffixAttackConfig::dbConfig;
use base 'Exporter';
our @EXPORT_OK = qw(
                    getListenPort
                    printDatabases
                    getDatabaseConfig
                   );

# copy this file to dbConfig.pm, and fill in the blanks for the database

# ------------------

my $databasesConfig = {
  swsPostgresGames => {
    server => "pg",
    host => "psql-science.mpi-sws.org",
    password => "xyz",
    username => "francis",
    dbname => "newcloak",
    listenport => 32123
  },
  mysqlNewcloak => {
    server => "mysql",
    host => "acmysql.mpi-sws.org",
    password => "xyz",
    username => "newcloak",
    dbname => "newcloak",
    listenport => 32124
  },
};

sub getListenPort {
my($db) = @_;
  return $db->{listenport};
}

sub getDatabaseConfig {
my ($dbName) = @_;
  if (ref($databasesConfig->{$dbName}) eq "HASH") {
    return(1, $databasesConfig->{$dbName});
  }
  else {
    return(0, "database not found");
  }
}

sub printDatabases {
  my %dbTab = %{ $databasesConfig; };
  my $str = '';
  $str .= sprintf "%20s	database	server\n", "cmd line db name";
  $str .= sprintf "%20s	--------	------\n", "----------------";
  foreach my $dbName (keys %dbTab) {
    my $db = $dbTab{$dbName};
    my $server = $db->{host};
    my $database = $db->{dbname};
    $str .= sprintf "%20s	%s	%s\n", $dbName, $database, $server;
  }
  return($str);
}

1;
