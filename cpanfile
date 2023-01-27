requires 'perl', 'v5.14';

requires 'Getopt::EX', '2.1.2';
requires 'List::Util', '1.45';
requires 'Hash::Util';
requires 'List::BinarySearch';

on 'test' => sub {
    requires 'Test::More', '0.98';
};
