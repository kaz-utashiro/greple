requires 'perl', 'v5.14';

requires 'Getopt::EX', 'v1.21.1';
requires 'List::Util', '1.45';
requires 'List::BinarySearch';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

