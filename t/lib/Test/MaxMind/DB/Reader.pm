package    # hide from PAUSE
    Test::MaxMind::DB::Reader;

use strict;
use warnings;

BEGIN {
    ## no critic (Variables::RequireLocalizedPunctuationVars)
    $ENV{MAXMIND_DB_READER_IMPLEMENTATION} = 'PP';
}

use MaxMind::DB::Reader::PP;

require MaxMind::DB::Reader;

1;
