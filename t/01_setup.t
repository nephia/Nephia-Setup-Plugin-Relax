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

ok 1;

done_testing;
