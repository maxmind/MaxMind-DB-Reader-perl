package MaxMind::DB::Reader;

use strict;
use warnings;

use 5.010000;

use Module::Implementation;
use Role::Tiny 1.003000 ();

my $Implementation;

{
    my $loader = Module::Implementation::build_loader_sub(
        implementations => [ 'XS', 'PP' ],
    );

    $Implementation = $loader->();
}

sub new {
    shift;
    return $Implementation->new(@_);
}

1;

# ABSTRACT: Read MaxMind DB files

__END__

=head1 DESCRIPTION

This module requires Perl 5.10+.

This first release is being done for the sake of the L<GeoIP2> package. Real
documentation for this distro is forthcoming.
