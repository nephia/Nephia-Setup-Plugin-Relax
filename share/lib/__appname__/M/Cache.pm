package {{ $self->approot }}::M::Cache;
use strict;
use warnings;
use parent '{{ $self->approot }}::M';
use Cache::Memcached::Fast;

my $cache;

sub cache {
    my $class = shift;
    unless ($cache) { 
        my $config = $class->config->{Cache};
        $cache = Cache::Memcached::Fast->new($config);
    }
    $cache;
}

sub get {
    my ($class, @args) = @_;
    $class->cache->get(@args);
}

sub set {
    my ($class, @args) = @_;
    $class->cache->set(@args);
}

sub delete {
    my ($class, @args) = @_;
    $class->cache->delete(@args);
}

1;
