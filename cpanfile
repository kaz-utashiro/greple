requires 'perl', 'v5.24';

requires 'Getopt::EX', '3.02';
requires 'Term::ANSIColor::Concise', '3.01';
requires 'List::Util', '1.45';
requires 'Hash::Util';
requires 'List::BinarySearch';
requires 'Clone';

on 'test' => sub {
    requires 'Test::More', '0.98';
};
