package {{ $self->appname }}::M::DB;
use strict;
use warnings;
use parent '{{ $self->appname }}::M';
use Otogiri;

my $db;

sub db {
    my $class = shift;
    my $config = $class->config->{DBI};
    $db ||= Otogiri->new(%$config);
    unless ($db->dbh->ping) {
        $db = Otogiri->new(%$config);
    }
    $db;
}

1;
