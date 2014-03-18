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
    _get_entry_data
    _read_node
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
    my $self          = shift;
    my $data_callback = shift;
    my $node_callback = shift;

    my $node_num  = 0;
    my $ipnum     = $self->ip_version() == 4 ? 0 : uint128(0);
    my $depth     = 1;
    my $max_depth = $self->ip_version() == 4 ? 32 : 128;

    $self->_iterate_search_tree(
        $data_callback,
        $node_callback,
        $node_num,
        $ipnum,
        $depth,
        $max_depth,
    );
}

sub _iterate_search_tree {
    my $self          = shift;
    my $data_callback = shift;
    my $node_callback = shift;
    my $node_num      = shift;
    my $ipnum         = shift;
    my $depth         = shift;
    my $max_depth     = shift;

    no warnings 'recursion';

    my @records = $self->_read_node($node_num);
    $node_callback->( $node_num, @records ) if $node_callback;

    for my $idx ( 0..1 ) {
        my $value = $records[$idx];

        # We ignore empty branches of the search tree
        next if $value == $self->node_count();

        my $one = $self->ip_version() == 4 ? 1 : uint128(1);
        $ipnum = $ipnum | ( $one << ( $max_depth - $depth ) ) if $idx;

        if ( $value <= $self->node_count() ) {
            $self->_iterate_search_tree(
                $data_callback,
                $node_callback,
                $value,
                $ipnum,
                $depth + 1,
                $max_depth,
            );
        }
        elsif ($data_callback) {
            $data_callback->(
                $ipnum, $depth,
                $self->_get_entry_data($value)
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
