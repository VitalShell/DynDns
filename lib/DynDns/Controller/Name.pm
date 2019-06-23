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
package DynDns::Controller::Name;
use Mojo::Base 'Mojolicious::Controller';
use Digest::MD5 qw(md5_hex);
use DBI;
use Data::Validate::IP;

sub search_by_name {
    my $self  = shift;
    my $name  = lc($self->stash('name'));
    my $dbh   = $self->app->dbh;

    my ($sth, $record_ref);

    # Remove space symbols
    $name =~ s/\s+//g;

    # Sarch target record
    $sth = $dbh->prepare('SELECT * FROM records WHERE name=? AND type=?');
    $sth->execute($name, 'A');
    $record_ref = $sth->fetchrow_hashref();
    $sth->finish();

    if (!defined($record_ref)) {
        $self->render(json => {
            code => 1,
            data => 'The requested name "'.$name.'" not found.'
        });
        return;
    }

    $self->render(json => {
        code => 0,
        name => $name,
        type => $record_ref->{type},
        data => $record_ref->{data},
        updated => $record_ref->{updated},
        status => $record_ref->{status}
    });
}


sub register {
    my $self  = shift;
    my $name  = lc($self->stash('name'));
    my $ip    = $self->tx->remote_address;
    if (defined($self->stash('ip'))) {
        $ip = $self->stash('ip');
    }
    my $dbh   = $self->app->dbh;

    # Remove space symbols
    $name =~ s/\s+//g;

    # Check the length of name
    if (length($name) > 253) {
        $self->render(json => {
            code => 1,
            data => 'A wrong name specified! The name length has to be less or equal to 253 symbols!',
        });
        return;
    }

    # CHeck the length of labels
    foreach my $sub (split(/\./, $name)) {
        if (length($sub) > 63) {
            $self->render(json => {
                code => 1,
                data => 'A wrong name specified! The label length has to be less or equal to 63 symbols!',
            });
            return;
        }
    }

    if ($name !~ /^.+\.anondns\.net$/) {
        $self->render(json => {
            code => 1,
            data => 'A wrong name specified! Your name has to have <b>.anondns.net</b> suffix!',
        });
        return;
    }

    if ($name !~ /^(([a-z]|[a-z][a-z0-9\-]*[a-z0-9])\.)*([a-z]|[a-z][a-z0-9\-]*[a-z0-9])$/) {
        $self->render(json => {
            code => 1,
            data => 'A wrong name specified! Your name has to match the domain name syntax!',
        });
        return;
    }

    if (not is_ipv4($ip)) {
        # Bad IP
        $self->render(json => {
            code => 1,
            data => 'A bad IP specified!'
        });
        return;
    }

    my ($sth, $record_ref);

    # Sarch target record
    $sth = $dbh->prepare('SELECT * FROM records WHERE name=? AND type=?');
    $sth->execute($name, 'A');
    $record_ref = $sth->fetchrow_hashref();
    $sth->finish();

    if (defined($record_ref)) {
        # Domain already exists!
        $self->render(json => {
            code => 1,
            data => 'The requested name "'.$name.'" already exists!'
        });
        return;
    }

    # Domain not found, we can to continue
    my $localtime = localtime();
    my $token = md5_hex($name.'/'.$ip.'/'.$localtime);

    # Add new record
    my $sth_insert_record = $dbh->prepare('INSERT INTO records (domain_id, name, data, token, status) VALUES (1, ?, ?, ?, 1)');
    my $sth_update_domain = $dbh->prepare('UPDATE domains SET updated=datetime(\'now\'), sn=sn+1 WHERE id=?');
    $dbh->begin_work();
    $sth_insert_record->execute($name, $ip, $token);
    $sth_insert_record->finish();
    $sth_update_domain->execute(1);
    $sth_update_domain->finish();
    $dbh->commit() or die $DBI::errstr;

    # Check if exists
    $sth = $dbh->prepare('SELECT * FROM records WHERE name=? AND type=?');
    $sth->execute($name, 'A');
    $record_ref = $sth->fetchrow_hashref();
    $sth->finish();

    if (!defined($record_ref)) {
        $self->render(json => { code => 1, data => 'Oops!' });
        return;
    }

    $self->render(json => {
        code => 0,
        name => $name,
        type => $record_ref->{type},
        data => $record_ref->{data},
        updated => $record_ref->{updated},
        status => $record_ref->{status},
        token => $record_ref->{token},
    });
}

1;
