package    # hide from PAUSE
    Test::MaxMind::DB::Reader;

use strict;
use warnings;

use MaxMind::DB::Reader::PP;

$ENV{MAXMIND_DB_READER_IMPLEMENTATION} = 'PP';

require MaxMind::DB::Reader;

1;
