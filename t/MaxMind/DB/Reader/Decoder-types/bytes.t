# PP only
use strict;
use warnings;
use autodie;

use lib 't/lib';

use MaxMind::DB::Reader::Decoder;
use Test::MaxMind::DB::Common::Data qw( test_cases_for );
use Test::MaxMind::DB::Reader::Decoder qw( test_decoding_of_type );
use Test::More;

use lib 't/lib';
use Test::MaxMind::DB::Reader;

use Encode ();

test_decoding_of_type( bytes => test_cases_for('bytes') );

{
    my $buffer = pack(
        'C4' => 0b10000011,
        0b11100100, 0b10111010, 0b10111010
    );

    open my $fh, '<', \$buffer;

    my $decoder = MaxMind::DB::Reader::Decoder->new(
        data_source       => $fh,
        _data_source_size => length $buffer,
    );

    my $string = $decoder->decode(0);

    ok(
        !Encode::is_utf8($string),
        'utf8 flag is off for bytes returned by decoder'
    );
}

done_testing();
