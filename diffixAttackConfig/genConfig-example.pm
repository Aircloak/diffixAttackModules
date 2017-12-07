use strict;
use POSIX qw(strftime);
package diffixAttackConfig::genConfig;
use base 'Exporter';
our @EXPORT_OK = qw(
                    getAirToken
                    getAirUrl
                    getDbList
                    getUid
                   );

# Copy this file to getConfig.pm and edit as needed

# ------------------

my $token = "SFMyNTY.g3QAAAACPAAEZGF2YW0AAAAkMDU2NmY0NzQtOWEyNi00OWY0LTg3NzktZjFhZDYzMzc7NjRmZAAGc2lnbmVkbgBAu5h97l8B.YSm7gyrCCqbvpxOYVKPzj69LC-0nZc1EWV14clsKOJw";

sub getAirToken {
  return $token;
}

# ------------------

my $airUrl = "https://attack.aircloak.com";

sub getAirUrl {
  return $airUrl;
}

# ------------------

my @dbList = ("scihub", "banking", "census0", "census1", "taxi");

sub getDbList {
  return \@dbList;
};

# ------------------

my %uidList = (
	"scihub.sep2015", "uid",
	"banking.accounts_view", "client_id",
	"banking.clients", "client_id",
	"banking.cards_view", "client_id",
	"banking.disp", "client_id",
	"banking.loans_view", "client_id",
	"banking.orders_view", "client_id",
	"banking.transactions_view", "client_id",
	"census0.uidperhousehold", "UID",
	"census1.uidperperson", "UID",
	"taxi.jan08", "med"
              );

sub getUid {
my($db, $tab) = @_;
  my $key = $db.".".$tab;
  my $uid = $uidList{$key};
  die "Couldn't find uid using $key" if (length($uid) <= 1);
  return $uid;
}

1;
