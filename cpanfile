requires 'perl', 'v5.18.2';

requires 'Getopt::EX', '2.2.1';
requires 'Term::ANSIColor::Concise', '2.08';
requires 'List::Util', '1.45';
requires 'Hash::Util';
requires 'List::BinarySearch';

on 'test' => sub {
    requires 'Test::More', '0.98';
};
