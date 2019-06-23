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
package DynDns;
use Mojo::Base 'Mojolicious';
use DBI;

has dbh => sub {
    my $self = shift;

    FindBin->again();
    my $dsn = 'DBI:SQLite:dbname=/home/dyndns/dyn_dns/domains.db';
    my $user = '';
    my $pass = '';
    my $dbh = DBI->connect($dsn, $user, $pass,
        {
            RaiseError => 1,
            AutoCommit => 1,
        }
    ) or die $DBI::errstr;

    return $dbh;
};

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->secrets(['SomeSecretWord']);

    # Documentation browser under "/perldoc"
    #$self->plugin('PODRenderer');

    # Router
    my $r = $self->routes;

    # Search
    $r->get('/api/search/name/#name')->to('name#search_by_name');

    # Register
    $r->get('/api/register/#name')->to('name#register');
    $r->get('/api/register/#name/a/#ip')->to('name#register');

    # Update
    $r->get('/api/set/#name/#token')->to('ip_addr#update_a_by_remote');
    $r->get('/api/set/#name/#token/a')->to('ip_addr#update_a_by_remote');
    $r->get('/api/set/#name/#token/a/#ip')->to('ip_addr#update_a');

    # Return
    $r->get('/api/get/client_addr')->to('ip_addr#client_addr');

    # Others
    $r->get('/*url')->to('common#unknown');
}

1;
