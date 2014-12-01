use strict;
use warnings;

use MaxMind::DB::Reader;

use Test::More;

ok( !exists $INC{'Moose.pm'}, 'Moose.pm is not in %INC' );

done_testing();
