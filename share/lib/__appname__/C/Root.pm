package {{ $self->appname }}::C::Root;
use strict;
use warnings;

sub index {
    my $c = shift;
    { template => 'index.tt' };
}

1;

