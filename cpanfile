requires 'perl', 'v5.14';

requires 'Getopt::EX', 'v1.25.0';
requires 'List::Util', '1.45';
requires 'Hash::Util';
requires 'List::BinarySearch';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

