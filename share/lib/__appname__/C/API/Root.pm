package {{ $self->approot }}::C::API::Root;
use strict;
use warnings;

sub hello {
    my $c = shift;
    my $id = $c->req->param('id');
    $id ? { id => $id } : { status => 403, message => 'id is required' } ;
}

1;

