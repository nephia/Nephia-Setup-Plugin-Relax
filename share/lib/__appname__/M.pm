package {{ $self->appname }}::M;
use strict;
use warnings;
use Nephia::Incognito;

sub c {
    my $class = shift;
    Nephia::Incognito->unmask('{{ $self->appname }}');
}

sub config {
    my $class = shift;
    $class->c->{config};
}

1;
