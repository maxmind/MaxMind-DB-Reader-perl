package MaxMind::DB::Reader::PP;

use strict;
use warnings;
use namespace::autoclean;

use Data::Validate::Domain qw( is_hostname );
use Data::Validate::IP qw( is_ipv4 is_ipv6 is_private_ipv4 );
use MaxMind::DB::Metadata;
use MaxMind::DB::Types qw( Str );
use Socket qw( inet_ntoa );

use Moo;
use MooX::StrictConstructor;

with 'MaxMind::DB::Reader::Role::Reader';

has file => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

sub BUILD {
    my $self = shift;

    my $file = $self->file();

    die "The file you specified ($file) does not exist"
        unless -e $file;

    die "The file you specified ($file) cannot be read"
        unless -r _;

    return;
}

sub record_for_address {
    my $self = shift;
    my $addr = shift;

    die 'You must provide an IP address to look up'
        unless defined $addr and length $addr;

    die
        "The IP address you provided ($addr) is not a valid IPv4 or IPv6 adress"
        unless is_ipv4($addr) || is_ipv6($addr);

    die "The IP address you provided ($addr) is not a public IP address"
        if is_private_ipv4($addr) || _is_private_ipv6($addr);

    return $self->_data_for_address($addr);
}

sub record_for_hostname {
    my $self     = shift;
    my $hostname = shift;

    die 'You must provide a hostname to look up'
        unless defined $hostname and length $hostname;

    die "The name you provided ($hostname) is not a valid hostname"
        unless is_hostname($hostname);

    return $self->record_for_address( $self->_resolve_hostname($hostname) );
}

sub _resolve_hostname {
    my $self     = shift;
    my $hostname = shift;

    my $packed_ip = gethostbyname($hostname);
    if ( defined $packed_ip ) {
        return inet_ntoa($packed_ip);
    }

    return;
}

# XXX - this needs an implementation - couldn't find anything on CPAN which
# seemed to handle IPv6 netmasks or know which IPv6 networks are private.
sub _is_private_ipv6 {
    return 0;
}

sub _build_data_source {
    my $self = shift;

    open my $fh, '<:raw', $self->file();

    return $fh;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Read MaxMind DB files
