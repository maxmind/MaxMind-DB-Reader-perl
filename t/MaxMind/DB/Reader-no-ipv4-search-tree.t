use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More;

use MaxMind::DB::Reader;

my $reader = MaxMind::DB::Reader->new(
    file => 'maxmind-db/test-data/MaxMind-DB-no-ipv4-search-tree.mmdb' );

is(
    $reader->record_for_address('1.1.1.1'), '::/64',
    'IPv4 lookup in tree without ::/96 subtree worked'
);

done_testing();
