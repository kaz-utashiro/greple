requires 'perl', 'v5.14';

requires 'Getopt::EX', 'v1.23.0';
requires 'List::Util', '1.45';
requires 'List::BinarySearch';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

