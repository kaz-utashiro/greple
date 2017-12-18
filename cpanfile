requires 'perl', '5.014';

requires 'Getopt::EX', 'v1.4.2';
requires 'List::Util', '1.45';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

