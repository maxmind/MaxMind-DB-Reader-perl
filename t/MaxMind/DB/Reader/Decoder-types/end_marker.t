# PP only
use strict;
use warnings;

use lib 't/lib';

use Test::MaxMind::DB::Common::Data qw( test_cases_for );
use Test::MaxMind::DB::Reader::Decoder qw( test_decoding_of_type );
use Test::More;

use lib 't/lib';
use Test::MaxMind::DB::Reader;

{
    my $buffer = pack(
        C2 => 0b00000000, 0b00000110,
    );

    open my $fh, '<', \$buffer;

    my $decoder = MaxMind::DB::Reader::Decoder->new(
        data_source       => $fh,
        _data_source_size => length $buffer,
    );

    my $container = $decoder->decode(0);

    isa_ok( $container, 'MaxMind::DB::Reader::Data::EndMarker' );
}

done_testing();
