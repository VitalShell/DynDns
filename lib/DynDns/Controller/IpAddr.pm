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
package DynDns::Controller::IpAddr;
use Mojo::Base 'Mojolicious::Controller';
use DBI;
use Data::Validate::IP qw(is_ipv4);

sub update_a {
    my $self  = shift;
    my $name  = lc($self->stash('name'));
    my $token = $self->stash('token');
    my $ip    = $self->stash('ip');
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
        # Domain not found!
        $self->render(json => {
            code => 1,
            data => 'The requested name "'.$name.'" not found.'
        });
        return;
    }

    if ($record_ref->{token} ne $token) {
        # Token mismatch
        $self->render(json => {
            code => 1,
            data => 'Token mismatch!'
        });
        return;
    }

    if (not is_ipv4($ip)) {
        # Bad IP
        $self->render(json => {
            code => 1,
            data => 'Bad IP specified!'
        });
        return;
    }

    if ($record_ref->{data} ne $ip) {
        # Update contains a real update
        # Update A record
        my $sth_update_record = $dbh->prepare('UPDATE records SET updated=datetime(\'now\'), data=? WHERE id=?');
        my $sth_update_domain = $dbh->prepare('UPDATE domains SET updated=datetime(\'now\'), sn=sn+1 WHERE id=?');

        $dbh->begin_work;
        $sth_update_record->execute($ip, $record_ref->{id});
        $sth_update_record->finish();
        $sth_update_domain->execute($record_ref->{domain_id});
        $sth_update_domain->finish();
        $dbh->commit() or die $DBI::errstr;
        $sth_update_record = undef;
        $sth_update_domain = undef;

        # Retreive stored data
        $sth = $dbh->prepare('SELECT * FROM records WHERE id=?');
        $sth->execute($record_ref->{id});
        $record_ref = $sth->fetchrow_hashref();
        $sth->finish();
    }

    $self->render(json => {
        code => 0,
        name => $name,
        type => $record_ref->{type},
        data => $record_ref->{data},
        updated => $record_ref->{updated},
        status => $record_ref->{status},
    });
}

sub update_a_by_remote {
    my $self   = shift;
    $self->stash(ip => $self->tx->remote_address);
    $self->update_a();
}

sub client_addr {
    my $self   = shift;
    $self->render(json => $self->tx->remote_address);
}

1;
