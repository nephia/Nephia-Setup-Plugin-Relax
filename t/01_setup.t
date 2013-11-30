use strict;
use warnings;
use Test::More;
use Nephia::Setup;
use Nephia::Setup::Plugin::Relax;
use File::Temp 'tempdir';
use File::Spec;

my $approot = File::Spec->catdir(tempdir(CLEANUP => 1), 'approot');

my $setup = Nephia::Setup->new(
    appname => 'My::WebApp', 
    approot => $approot,
    plugins => [ 'Relax' ],
);

$setup->do_task;

my @files = (
    [qw/app.psgi/],
    [qw/config common.pl/],
    [qw/config local.pl/],
    [qw/config dev.pl/],
    [qw/config real.pl/],
    [qw/lib My WebApp.pm/],
    [qw/lib My WebApp C Root.pm/],
    [qw/lib My WebApp C API Root.pm/],
    [qw/view index.tt/],
    [qw/view include layout.tt/],
    [qw/view include navbar.tt/],
    [qw/cpanfile/]
);

my @dirs = (
    [qw/var/],
);

for my $entry ( @files ) {
    ok -f File::Spec->catfile($approot, @$entry);
}

for my $entry ( @dirs ) {
    ok -d File::Spec->catfile($approot, @$entry);
}

done_testing;
