requires 'perl', '>= v5.14, != v5.18.0, != v5.18.1';

requires 'Getopt::EX', 'v1.14.0';
requires 'List::Util', '1.45';
requires 'List::BinarySearch';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

