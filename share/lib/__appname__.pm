package {{ $self->appname }};
use strict;
use warnings;
use Data::Dumper ();
use URI;
use Nephia::Incognito;
use Nephia plugins => [
    'FillInForm',
    'JSON' => {
        enable_api_status_header => 1,
    },
    'View::Xslate' => {
        syntax => 'TTerse',
        path   => [ qw/view/ ],
        function => {
            c    => \&c,
            config => \&config,
            dump => sub {
                local $Data::Dumper::Terse = 1;
                Data::Dumper::Dumper(shift);
            },
            uri_for => sub {
                my ($path, $query) = @_;
                my $env = c()->req->env;
                my $uri = URI->new(sprintf(
                    '%s://%s%s',
                    $env->{'psgi.url_scheme'},
                    $env->{'HTTP_HOST'},
                    $path
                ));
                if ($query) {
                    $uri->query_form($query);
                }
                $uri->as_string;
            },
        },
    },
    'ErrorPage',
    'ResponseHandler',
    'Dispatch',
];

sub c () { Nephia::Incognito->unmask(__PACKAGE__) }

sub config () { __PACKAGE__->c->{config} }

app {
    get '/'          => Nephia->call('C::Root#index');
    get '/api/hello' => Nephia->call('C::API::Root#hello');
};

1;

