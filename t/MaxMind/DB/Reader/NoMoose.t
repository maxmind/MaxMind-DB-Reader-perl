use strict;
use warnings;

use lib 't/lib';

# This must come before `use MaxMind::DB::Reader;` as otherwise the wrong
# reader may be loaded
use Test::MaxMind::DB::Reader;

use MaxMind::DB::Reader;
use Test::More;

ok( !exists $INC{'Moose.pm'}, 'Moose.pm is not in %INC' );

done_testing();
