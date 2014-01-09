package Nephia::Setup::Plugin::Relax;
use 5.008005;
use strict;
use warnings;
use parent 'Nephia::Setup::Plugin';
use File::Spec;
use File::Basename qw/fileparse dirname/;
use File::ShareDir 'dist_dir';
use File::Find;

our $VERSION = "0.01";

sub bundle {
    qw/Assets::Bootstrap Assets::JQuery/;
}

sub fix_setup {
    my $self  = shift;

    my $chain = $self->setup->action_chain;
    $chain->{chain} = [];
    $chain->append('CreateApproot'     => $self->can('create_approot'));
    $chain->append('CreateCPANFile'    => $self->can('create_cpanfile'));
    $chain->append('CreateEachFile'    => $self->can('create_eachfile'));

    push @{$self->setup->deps->{requires}}, (
        'Plack::Middleware::Static'           => '0',
        'Plack::Middleware::Session'          => '0',
        'Plack::Middleware::CSRFBlock'        => '0',
        'Cache::Memcached::Fast'              => '0',
        'DBI'                                 => '0',
        'DBD::SQLite'                         => '0',
        'Otogiri'                             => '0',
        'Nephia'                              => '0.87',
        'Nephia::Plugin::Dispatch'            => '0.03',
        'Nephia::Plugin::FillInForm'          => '0',
        'Nephia::Plugin::JSON'                => '0.03',
        'Nephia::Plugin::ResponseHandler'     => '0',
        'Nephia::Plugin::View::Xslate'        => '0',
        'Nephia::Plugin::ErrorPage'           => '0',
    );
}

sub create_approot {
    my ($setup, $context) = @_;
    $setup->stop(sprintf('%s is Already exists', $setup->approot)) if -d $setup->approot;
    $setup->makepath('.');
}

sub create_cpanfile {
    my ($setup, $context) = @_;
    $setup->spew('cpanfile', $setup->cpanfile);
}

sub create_eachfile {
    my ($setup, $context) = @_;
    my $srcdir = dist_dir('Nephia-Setup-Plugin-Relax');
    my $dstdir = $setup->approot;
    my @classfile = $setup->classfile;
    shift @classfile;
    my $appname = File::Spec->catfile(@classfile);
    $appname =~ s[\.pm][];
    find(sub {
        my $entry = $File::Find::name;
        unless ($entry eq $srcdir) {
            my $dst = $entry;
            $dst =~ s[$srcdir][$dstdir];
            $dst =~ s[__appname__][$appname];
            if (-f $entry) {
                my ($basename, $dir) = fileparse($dst);
                $dir =~ s[$dstdir][];
                my $file = $dst;
                $file =~ s[$dstdir][];
$file =~ s[^(\\|\/)][];
                if (! -z $dir) {
                    $setup->makepath($dir);
                    open my $fh, '<', $entry or die $!;
                    my $data = do {local $/; <$fh>};
                    close $fh;
                    $setup->spew($file, $setup->process_template($data));
                }
            }
            elsif (-d $entry) {
                my $dir = $dst;
                $dir =~ s[$dstdir][];
                $setup->makepath($dir);
            }
        }
    }, $srcdir);
    $setup->makepath('var');
}

1;
__END__

=encoding utf-8

=head1 NAME

Nephia::Setup::Plugin::Relax - Xslate(TTerse) + Otogiri + alpha

=head1 SYNOPSIS

    $ nephia-setup Your::App --plugins Relax

=head1 DESCRIPTION

Relax style setup

=head1 BUNDLE SETUP-PLUGINS

L<Nephia::Setup::Plugin::Assets::Bootstrap>

L<Nephia::Setup::Plugin::Assets::JQuery>

=head1 ENABLED PLUGINS

L<Nephia::Plugin::JSON>

L<Nephia::Plugin::View::Xslate>

L<Nephia::Plugin::ResponseHandler>

L<Nephia::Plugin::Dispatch>

L<Nephia::Plugin::FillInForm>

L<Nephia::Plugin::ErrorPage>

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

