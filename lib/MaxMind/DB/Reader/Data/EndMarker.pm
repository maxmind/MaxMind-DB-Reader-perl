package MaxMind::DB::Reader::Data::EndMarker;

use strict;
use warnings;

our $VERSION = '1.000015';

sub new {
    my $str = 'end marker';
    return bless \$str, __PACKAGE__;
}

1;
