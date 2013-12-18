package Nephia::Setup::Plugin::Relax;
use 5.008005;
use strict;
use warnings;
use parent 'Nephia::Setup::Plugin';
use Data::Section::Simple 'get_data_section';
use File::Spec;
use File::Basename 'dirname';

our $VERSION = "0.01";

sub bundle {
    qw/Assets::Bootstrap Assets::JQuery/;
}

sub fix_setup {
    my $self  = shift;

    my $chain = $self->setup->action_chain;
    $chain->{chain} = [];
    $chain->append('CreateApproot'     => $self->can('create_approot'));
    $chain->append('CreatePSGI'        => $self->can('create_psgi'));
    $chain->append('CreateConfig'      => $self->can('create_config'));
    $chain->append('CreateAppClass'    => $self->can('create_app_class'));
    $chain->append('CreateControllers' => $self->can('create_controllers'));
    $chain->append('CreateDBDir'       => $self->can('create_db_dir'));
    $chain->append('CreateTemplates'   => $self->can('create_templates'));
    $chain->append('CreateCPANFile'    => $self->can('create_cpanfile'));

    push @{$self->setup->deps->{requires}}, (
        'Plack::Middleware::Static'           => '0',
        'Plack::Middleware::Session'          => '0',
        'Plack::Middleware::CSRFBlock'        => '0',
        'Cache::Memcached::Fast'              => '0',
        'DBI'                                 => '0',
        'DBD::SQLite'                         => '0',
        'Otogiri'                             => '0',
        'Nephia::Plugin::Dispatch'            => '0.03',
        'Nephia::Plugin::FillInForm'          => '0',
        'Nephia::Plugin::JSON'                => '0.03',
        'Nephia::Plugin::ResponseHandler'     => '0',
        'Nephia::Plugin::View::Xslate'        => '0',
        'Nephia::Plugin::ErrorPage'           => '0',
    );
}

sub load_data {
    my ($class, $setup, @path) = @_;
    my $str = get_data_section(@path);
    $setup->process_template($str);
}

sub create_approot {
    my ($setup, $context) = @_;
    $setup->stop(sprintf('%s is Already exists', $setup->approot)) if -d $setup->approot;
    $setup->makepath('.');
}

sub create_psgi {
    my ($setup, $context) = @_;
    my $data = __PACKAGE__->load_data($setup, 'app.psgi');
    $setup->spew('app.psgi', $data);
}

sub create_config {
    my ($setup, $context) = @_;

    my $common = __PACKAGE__->load_data($setup, 'common.pl');
    $setup->spew('config', 'common.pl', $common);

    $setup->{dbfile} = File::Spec->catfile('var', 'db.sqlite3');
    my $data = __PACKAGE__->load_data($setup, 'config.pl');
    for my $env (qw/local dev real/) {
        $setup->spew('config', "$env.pl", $data);
    }
}

sub create_db_dir {
    my ($setup, $context) = @_;
    $setup->makepath('var');
}

sub create_app_class {
    my ($setup, $context) = @_;
    my $data = __PACKAGE__->load_data($setup, 'MyClass.pm');
    $setup->spew($setup->classfile, $data);
}

sub create_controllers {
    my ($setup, $context) = @_; 
    for my $subclass ( qw/C::Root C::API::Root/ ) {
        $setup->{tmpclass} = join('::', $setup->appname, $subclass);
        my $data = __PACKAGE__->load_data($setup, $subclass);
        $setup->spew('lib', split('::', $setup->{tmpclass}.'.pm'), $data);
    }
}

sub create_templates {
    my ($setup, $context) = @_;
    for my $template ( qw/index include::layout include::navbar error/ ) {
        my $file = File::Spec->catfile( split('::', $template) ). '.tt';
        my $data = __PACKAGE__->load_data($setup, $file);
        $setup->makepath('view', dirname($file));
        $setup->spew('view', $file, $data);
    }
}

sub create_cpanfile {
    my ($setup, $context) = @_;
    $setup->spew('cpanfile', $setup->cpanfile);
}

1;
__DATA__

@@ app.psgi
use strict;
use warnings;
use File::Spec;
use File::Basename 'dirname';
use lib (
    File::Spec->catdir(dirname(__FILE__), 'lib'), 
);
use {{ $self->appname }};

use Plack::Builder;
use Plack::Session::Store::Cache;
use Cache::Memcached::Fast;

my $run_env       = $ENV{PLACK_ENV} eq 'development' ? 'local' : $ENV{PLACK_ENV};
my $basedir       = dirname(__FILE__);
my $config_file   = File::Spec->catfile($basedir, 'config', $run_env.'.pl');
my $config        = require($config_file);
my $cache         = Cache::Memcached::Fast->new($config->{'Cache'});
my $session_store = Plack::Session::Store::Cache->new(cache => $cache);
my $app           = {{ $self->appname }}->run(%$config);

builder {
    enable_if { $ENV{PLACK_ENV} =~ /^($:local|dev)$/ } 'StackTrace', force => 1;
    enable 'Static', (
        root => $basedir,
        path => qr{^/static/},
    );
    enable 'Session', (cache => $session_store);
    enable 'CSRFBlock';
    $app;
};

@@ common.pl
{
    appname => '{{ $self->appname }}',
    ErrorPage => {
        template => 'error.tt',
    },
};

@@ config.pl 
use File::Basename 'dirname';
use File::Spec;
my $common = require(File::Spec->catfile(dirname(__FILE__), 'common.pl'));
my $conf = {
    %$common,
    'Cache' => { 
        servers   => ['127.0.0.1:11211'],
        namespace => '{{ $self->appname }}',
    },
    'DBI' => {
        connect_info => [
            'dbi:SQLite:dbname={{ $self->{dbfile} }}', 
            '', 
            '',
        ],
    },
    
};
$conf;

@@ MyClass.pm
package {{ $self->appname }};
use strict;
use warnings;
use Nephia plugins => [
    'FillInForm',
    'JSON' => {
        enable_api_status_header => 1,
    },
    'View::Xslate' => {
        syntax => 'TTerse',
        path   => [ qw/view/ ],
    },
    'ErrorPage',
    'ResponseHandler',
    'Dispatch',
];

app {
    get '/'          => Nephia->call('C::Root#index');
    get '/api/hello' => Nephia->call('C::API::Root#hello');
};

1;

@@ C::Root
package {{ $self->{tmpclass} }};
use strict;
use warnings;

sub index {
    my $c = shift;
    { template => 'index.tt' };
}

1;

@@ C::API::Root
package {{ $self->{tmpclass} }};
use strict;
use warnings;

sub hello {
    my $c = shift;
    my $id = $c->req->param('id');
    $id ? { id => $id } : { status => 403, message => 'id is required' } ;
}

1;

@@ index.tt 
[% WRAPPER 'include/layout.tt' %]
<p>index</p>
[% END %]

@@ error.tt
[% WRAPPER 'include/layout.tt' WITH title = code _ ' ' _ message %]
  <div class="alert alert-block">
     <h2 class="alert-heading">[% code %]</h1>
     [% message %]
  </div>
[% END %]

@@ include/layout.tt
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>[% title || 'Top' %] | {{ $self->appname }}</title>
  <link rel="stylesheet" href="/static/bootstrap/css/bootstrap.min.css">
  <script src="/static/js/jquery.min.js"></script>
  <script src="/static/bootstrap/js/bootstrap.min.js"></script>
</head>
<body>
  <div class="navbar">
    <div class="navbar-inner">
      <div class="container">
      [% INCLUDE 'include/navbar.tt' %]
      </div>
    </div>
  </div>
  <div class="container">
  [% content %]
  </div>
</body>
</html>

@@ include/navbar.tt
<a class="brand" href="/">{{ $self->appname }}</a>
<ul class="nav">
  <li><a href="/">top</a></li>
</ul>

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

