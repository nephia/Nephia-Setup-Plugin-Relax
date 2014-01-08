requires 'perl', '5.008001';
requires 'Nephia', 0.87;
requires 'Nephia::Setup::Plugin::Assets::JQuery', 0.02;
requires 'Nephia::Setup::Plugin::Assets::Bootstrap', 0.02;
requires 'File::ShareDir';
requires 'File::Copy';
requires 'File::Find';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::File::ShareDir::Module';
};

