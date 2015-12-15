package MaxMind::DB::Reader::Data::Container;

use strict;
use warnings;

our $VERSION = '1.000009';

sub new {
    my $str = 'container';
    return bless \$str, __PACKAGE__;
}

1;
