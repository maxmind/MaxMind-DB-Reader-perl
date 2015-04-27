# PP only
use strict;
use warnings;

use Test::Bits;
use Test::More;

use lib 't/lib';
use Test::MaxMind::DB::Reader;

use MaxMind::DB::Reader::Decoder;

open my $fh, '<', 'maxmind-db/test-data/maps-with-pointers.raw'
    or die $!;

my $decoder = MaxMind::DB::Reader::Decoder->new( data_source => $fh );

my %tests = (
    0  => { long_key  => 'long_value1' },
    22 => { long_key  => 'long_value2' },
    37 => { long_key2 => 'long_value1' },
    50 => { long_key2 => 'long_value2' },
    55 => { long_key  => 'long_value1' },
    57 => { long_key2 => 'long_value2' },
);

for my $offset ( sort keys %tests ) {
    is_deeply(
        scalar $decoder->decode($offset),
        $tests{$offset},
        "decoded expected data structure at offset $offset"
    );
}

done_testing();
