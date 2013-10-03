use strict;
use warnings;
use utf8;

use Test::More;
use lib 't/lib';
use Test::MaxMind::DB::Reader;
use Math::Int128 qw( uint128 );
use MaxMind::DB::Reader;

{
    my $filename = 'MaxMind-DB-test-decoder.mmdb';
    my $reader   = MaxMind::DB::Reader->new(
        file => "maxmind-db/test-data/$filename" );

    my $record = $reader->record_for_address('::1.1.1.0');

    is( $record->{utf8_string}, 'unicode! ☯ - ♫', 'decode utf8_string' );
    is( $record->{double}, 42.123456, 'decode double' );
    is( $record->{bytes}, pack( 'N', 42 ), 'decode bytes' );
    is( $record->{uint16}, 100, 'decode uint16' );
    is( $record->{uint32}, 2**28, 'decode uint32' );
    is( $record->{int32}, -1 * ( 2**28 ), 'decode int32' );
    is( $record->{uint64}, uint128(1) << 60, 'decode uint64' );
    is( $record->{uint128}, uint128(1) << 120, 'decode uint128' );
    is_deeply( $record->{array}, [ 1, 2, 3 ], 'decode array' );

    is_deeply(
         $record->{map},
         {
            mapX => {
                utf8_stringX => 'hello',
                arrayX       => [ 7, 8, 9 ],
            },
        },
        'decode map',
    );

   ok( $record->{boolean}, 'decode true bool' );
   ok( abs($record->{float} - 1.1) < 0.00001, 'decode float' );

}

done_testing();
