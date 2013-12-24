use strict;
use warnings;
use utf8;

use lib 't/lib';
use Math::Int128 qw( uint128 );
use MaxMind::DB::Reader;
use Test::MaxMind::DB::Reader;
use Test::More;
use Test::Number::Delta;

my $filename = 'MaxMind-DB-test-decoder.mmdb';
my $reader
    = MaxMind::DB::Reader->new( file => "maxmind-db/test-data/$filename" );

{
    my $record = $reader->record_for_address('::1.1.1.0');
    ok( $record, 'found record for ::1.1.1.0' );

    is(
        $record->{utf8_string}, 'unicode! ☯ - ♫',
        'decoded utf8_string has expected value'
    );
    delta_ok( $record->{double}, 42.123456, 'decoded double has expected value' );
    is(
        $record->{bytes}, pack( 'N', 42 ),
        'decoded bytes has expected value'
    );
    is( $record->{uint16}, 100,   'decoded uint16 has expected value' );
    is( $record->{uint32}, 2**28, 'decoded uint32 has expected value' );
    is(
        $record->{int32}, -1 * ( 2**28 ),
        'decoded int32 has expected value'
    );
    is(
        $record->{uint64}, uint128(1) << 60,
        'decoded uint64 has expected value'
    );
    is(
        $record->{uint128}, uint128(1) << 120,
        'decoded uint128 has expected value'
    );
    is_deeply(
        $record->{array}, [ 1, 2, 3 ],
        'decoded array has expected value'
    );

    is_deeply(
        $record->{map},
        {
            mapX => {
                utf8_stringX => 'hello',
                arrayX       => [ 7, 8, 9 ],
            },
        },
        'decoded map has expected value'
    );

    ok( $record->{boolean}, 'decoded bool is true' );
    delta_ok( $record->{float}, 1.1,
        'decoded float has expected value'
    );
}

{
    my $record = $reader->record_for_address('::0.0.0.0');
    ok( $record, 'found record for ::0.0.0.0' );

    is( $record->{utf8_string}, q{}, 'decoded utf8_string is empty string' );
    is( $record->{double},      0,   'decoded double is 0' );
    is( $record->{bytes},       q{}, 'decoded bytes is empty' );
    is( $record->{uint16},      0,   'decoded uint16 is 0' );
    is( $record->{uint32},      0,   'decoded uint32 is 0' );
    is( $record->{int32},       0,   'decoded int32 is 0' );
    is( $record->{uint64},  uint128(0), 'decoded uint64 is 0' );
    is( $record->{uint128}, uint128(0), 'decoded uint128 is 0' );
    is_deeply( $record->{array}, [], 'decoded array is empty' );
    is_deeply( $record->{map}, {}, 'decoded map is empty' );
    ok( !$record->{boolean}, 'decoded false bool' );
    is( $record->{float}, 0, 'decoded float is 0' );
}

done_testing();
