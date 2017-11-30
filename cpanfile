requires 'perl', '5.008001';

requires 'Getopt::EX', 'v1.2.1';
requires 'List::Util', '1.33';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

