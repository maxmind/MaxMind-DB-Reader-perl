package MaxMind::DB::Reader::Role::Reader;

use strict;
use warnings;
use namespace::autoclean;
use autodie;

use Data::Validate::IP 0.16
    qw( is_ipv4 is_ipv6 is_private_ipv4 is_private_ipv6 );
use Math::Int128 qw( uint128 );
use Net::Works::Address 0.12;

use Moo::Role;

requires qw(
    _build_metadata
    _data_for_address
    _read_node
    _resolve_data_pointer
);

use constant DEBUG => $ENV{MAXMIND_DB_READER_DEBUG};

sub record_for_address {
    my $self = shift;
    my $addr = shift;

    die 'You must provide an IP address to look up'
        unless defined $addr and length $addr;

    die
        "The IP address you provided ($addr) is not a valid IPv4 or IPv6 address"
        unless is_ipv4($addr) || is_ipv6($addr);

    die "The IP address you provided ($addr) is not a public IP address"
        if is_private_ipv4($addr) || is_private_ipv6($addr);

    return $self->_data_for_address($addr);
}

sub iterate_search_tree {
    my $self     = shift;
    my $callback = shift;

    my $node_num  = 0;
    my $ipnum     = $self->ip_version() == 4 ? 0 : uint128(0);
    my $depth     = 1;
    my $max_depth = $self->ip_version() == 4 ? 32 : 128;

    $self->_iterate_search_tree( $callback, $node_num, $ipnum, $depth, $max_depth );
}

sub _iterate_search_tree {
    my $self     = shift;
    my $callback = shift;
    my $node_num = shift;
    my $ipnum    = shift;
    my $depth    = shift;
    my $max_depth = shift;

    no warnings 'recursion';

    my ( $left, $right ) = $self->_read_node($node_num);
    for my $value ( $left, $right ) {

        # We ignore empty branches of the search tree
        next if $value == $self->node_count();

        my $one = $self->ip_version() == 4 ? 1 : uint128(1);

        $ipnum |= ( $one << ( $max_depth - $depth ) ) if $value == $right;

        if ( $value <= $self->node_count() ) {
            $self->_iterate_search_tree(
                $callback, $value, $ipnum,
                $depth + 1, $max_depth,
            );
        }
        else {
            $callback->(
                $ipnum, $depth,
                $self->_resolve_data_pointer($value)
            );
        }
    }
}

around _build_metadata => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig(@_) unless DEBUG;

    my $metadata = $self->$orig(@_);

    $metadata->debug_dump();

    return $metadata;
};

1;
