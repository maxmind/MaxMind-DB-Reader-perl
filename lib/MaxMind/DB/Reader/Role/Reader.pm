package MaxMind::DB::Reader::Role::Reader;

use strict;
use warnings;
use namespace::autoclean;
use autodie;

use Data::Validate::IP 0.16
    qw( is_ipv4 is_ipv6 is_private_ipv4 is_private_ipv6 );
use MaxMind::DB::Types qw( Int );
use Net::Works::Address 0.12;

use Moo::Role;

use constant DEBUG => $ENV{MAXMIND_DB_READER_DEBUG};

with 'MaxMind::DB::Role::Debugs',
    'MaxMind::DB::Reader::Role::NodeReader',
    'MaxMind::DB::Reader::Role::HasDecoder';

has _ipv4_start_node => (
    is       => 'ro',
    isa      => Int,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_ipv4_start_node',
);

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

sub _data_for_address {
    my $self = shift;
    my $addr = shift;

    my $pointer = $self->_find_address_in_tree($addr);

    return undef unless $pointer;

    return $self->_resolve_data_pointer($pointer);
}

sub _find_address_in_tree {
    my $self = shift;
    my $addr = shift;

    my $address = Net::Works::Address->new_from_string(
        string => $addr,
    );

    my $integer = $address->as_integer();

    if (DEBUG) {
        $self->_debug_newline();
        $self->_debug_string( 'IP address',      $address );
        $self->_debug_string( 'IP address bits', $address->as_bit_string() );
        $self->_debug_newline();
    }

    # The first node of the tree is always node 0, at the beginning of the
    # value
    my $node_num = $self->ip_version == 6
        && $address->version == 4 ? $self->_ipv4_start_node : 0;

    for my $bit_num ( reverse( 0 ... $address->bits - 1 ) ) {
        my $bit = 1 & ( $integer >> $bit_num );

        my ( $left, $right ) = $self->_read_node($node_num);

        my $record = $bit ? $right : $left;

        if (DEBUG) {
            $self->_debug_string( 'Bit #',     $address->bits() - $bit_num );
            $self->_debug_string( 'Bit value', $bit );
            $self->_debug_string( 'Record',    $bit ? 'right' : 'left' );
            $self->_debug_string( 'Record value', $record );
        }

        if ( $record == $self->node_count() ) {
            $self->_debug_message('Record is empty')
                if DEBUG;
            return;
        }

        if ( $record >= $self->node_count() ) {
            $self->_debug_message('Record is a data pointer')
                if DEBUG;
            return $record;
        }

        $self->_debug_message('Record is a node number')
            if DEBUG;

        $node_num = $record;
    }
}

sub _resolve_data_pointer {
    my $self    = shift;
    my $pointer = shift;

    my $resolved
        = ( $pointer - $self->node_count() ) + $self->_search_tree_size();

    if (DEBUG) {
        my $node_count = $self->node_count();
        my $tree_size  = $self->_search_tree_size();

        $self->_debug_string(
            'Resolved data pointer',
            "( $pointer - $node_count ) + $tree_size = $resolved"
        );
    }

    # We only want the data from the decoder, not the offset where it was
    # found.
    return scalar $self->_decoder()->decode($resolved);
}

sub _build_ipv4_start_node {
    my $self = shift;

    return 0 unless $self->ip_version == 6;

    my $node_num = 0;

    for ( 1 ... 96 ) {
        my ($next_node_num) = $self->_read_node($node_num);

        # We stop early if the next node is a leaf node.
        last if $next_node_num >= $self->node_count();
        $node_num = $next_node_num;
    }

    return $node_num;
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
