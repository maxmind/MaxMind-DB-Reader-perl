use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More;

use lib 't/lib';
use Test::MaxMind::DB::Reader;

use MaxMind::DB::Reader;

my $reader = MaxMind::DB::Reader->new(
    file => 'maxmind-db/test-data/MaxMind-DB-no-ipv4-search-tree.mmdb' );

is(
    $reader->record_for_address('1.1.1.1'), '::0/64',
    'IPv4 lookup in tree without ::/96 subtree worked (first bit is 0)'
);

is(
    $reader->record_for_address('192.1.1.1'), '::0/64',
    'IPv4 lookup in tree without ::/96 subtree worked (first bit is 1)'
);

done_testing();
