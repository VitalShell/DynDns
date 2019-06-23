#!/usr/bin/env perl
#
#    Copyright (C) 2014  Vitaly Druzhinin
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

use DBI;
use strict;
use warnings;

my $zone_list = '/etc/bind/zones/zones.conf';
my $zone_dir  = '/etc/bind/zones/';
my $data_file = '/home/dyndns/dyn_dns/domains.db';
my $rc        = 0;

my $dsn = 'DBI:SQLite:dbname='.$data_file;
my $user = '';
my $pass = '';
my $dbh = DBI->connect($dsn, $user, $pass,
    {
        RaiseError => 1,
        AutoCommit => 1,
    }
) or die $DBI::errstr;


#
# Prepare statements
#
my $sth_config = $dbh->prepare('SELECT id, key, value, datetime("now") AS current FROM config WHERE key=?');
my $sth_domain = $dbh->prepare('SELECT * FROM domains WHERE status=1 AND updated BETWEEN ? AND ?');
my $sth_record = $dbh->prepare('SELECT * FROM records WHERE status=1 AND domain_id=?');
my $sth_update_config = $dbh->prepare('UPDATE config SET value=? WHERE id=?');

#
# Retrieve config info
#
$dbh->begin_work();
$sth_config->execute('zone_updater::last_seen');
my $config_href = $sth_config->fetchrow_hashref();
$sth_config->finish();
$dbh->commit();

#
# Check updated domains
#
$dbh->begin_work();
my $datetime1 = $config_href->{value};           # begin of time interval
my $datetime2 = $config_href->{current};         # end of time interval
$sth_domain->execute($datetime1, $datetime2);
while (my $domain_href = $sth_domain->fetchrow_hashref()) {

    # make a new zone database
    my $zone_file = 'db.'.$domain_href->{name};
    open(my $zf, '>', $zone_dir.'/'.$zone_file)
        or die "can't open zone file $zone_dir/$zone_file: $!";

    print $zf <<EOT1
;
; This file was automatically generated by zone_updater.pl $datetime2
; Don't edit it directly!
;
\$ORIGIN .
\$TTL $domain_href->{ttl}
$domain_href->{name}. IN SOA $domain_href->{name_server}. $domain_href->{email_addr}. ( $domain_href->{sn} $domain_href->{refresh} $domain_href->{retry} $domain_href->{expiry} $domain_href->{nx} ) ; zone_id=$domain_href->{id} ($domain_href->{name})
$domain_href->{name}. IN NS $domain_href->{name_server}.

EOT1
;

    $sth_record->execute($domain_href->{id});
    while (my $record_href = $sth_record->fetchrow_hashref()) {
        # Out one record
        print($zf $record_href->{name},
            '. ', $record_href->{ttl},
            ' ', $record_href->{class},
            ' ', $record_href->{type},
            ' ', $record_href->{data}, ($record_href->{type} eq 'NS') ? '.' : '',
            ' ; record_id=' ,$record_href->{id},
         "\n");
    }
    $sth_record->finish();

    print $zf "; end of file\n";
    close($zf);
    $rc++;
}
$sth_domain->finish();
$dbh->commit();
exit($rc);


END {
    $dbh->begin_work();
    $sth_update_config->execute($config_href->{current}, $config_href->{id});
    $sth_update_config->finish();
    $dbh->commit() or die $DBI::errstr;
    $dbh->disconnect();
}

# end of file