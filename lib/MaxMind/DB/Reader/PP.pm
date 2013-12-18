package MaxMind::DB::Reader::PP;

use strict;
use warnings;
use namespace::autoclean;

use Carp qw( confess );
use MaxMind::DB::Types qw( Str Int );

use Moo;
use MooX::StrictConstructor;

with 'MaxMind::DB::Reader::Role::Reader',
    'MaxMind::DB::Reader::Role::NodeReader',
    'MaxMind::DB::Reader::Role::HasDecoder',
    'MaxMind::DB::Role::Debugs';

has file => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _ipv4_start_node => (
    is       => 'ro',
    isa      => Int,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_ipv4_start_node',
);

use constant DEBUG => $ENV{MAXMIND_DB_READER_DEBUG};

sub BUILD {
    my $self = shift;

    my $file = $self->file();

    die qq{Error opening database file "$file": The file does not exist.}
        unless -e $file;

    die qq{Error opening database file "$file": The file cannot be read.}
        unless -r _;

    # Build the metadata right away to ensure file's validity
    $self->metadata;

    return;
}

sub _build_data_source {
    my $self = shift;

    open my $fh, '<:raw', $self->file();

    return $fh;
}

sub _data_for_address {
    my $self = shift;
    my $addr = shift;

    my $pointer = $self->_find_address_in_tree($addr);

    return undef unless $pointer;

    return $self->_get_entry_data($pointer);
}

sub _find_address_in_tree {
    my $self = shift;
    my $addr = shift;

    my $address = Net::Works::Address->new_from_string( string => $addr );

    my $integer = $address->as_integer();

    if (DEBUG) {
        $self->_debug_newline();
        $self->_debug_string( 'IP address',      $address );
        $self->_debug_string( 'IP address bits', $address->as_bit_string() );
        $self->_debug_newline();
    }

    # The first node of the tree is always node 0, at the beginning of the
    # value
    my $node = $self->ip_version == 6
        && $address->version == 4 ? $self->_ipv4_start_node() : 0;

    for my $bit_num ( reverse( 0 ... $address->bits - 1 ) ) {
        last if $node >= $self->node_count();

        $self->_debug_message('Record is a node number')
            if DEBUG;

        my $bit = 1 & ( $integer >> $bit_num );

        my ( $left, $right ) = $self->_read_node($node);

        $node = $bit ? $right : $left;

        if (DEBUG) {
            $self->_debug_string( 'Bit #',     $address->bits() - $bit_num );
            $self->_debug_string( 'Bit value', $bit );
            $self->_debug_string( 'Record',    $bit ? 'right' : 'left' );
            $self->_debug_string( 'Record value', $node );
        }

    }

    if ( $node == $self->node_count() ) {
        $self->_debug_message('Record is empty')
            if DEBUG;
        return;
    }

    if ( $node >= $self->node_count() ) {
        $self->_debug_message('Record is a data pointer')
            if DEBUG;
        return $node;
    }
}

sub _get_entry_data {
    my $self   = shift;
    my $offset = shift;

    my $resolved
        = ( $offset - $self->node_count() ) + $self->_search_tree_size();

            confess q{The MaxMind DB file's search tree is corrupt}
    if $resolved > $self->_data_source_size;

    if (DEBUG) {
        my $node_count = $self->node_count();
        my $tree_size  = $self->_search_tree_size();

        $self->_debug_string(
            'Resolved data pointer',
            "( $offset - $node_count ) + $tree_size = $resolved"
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
        ($node_num) = $self->_read_node($node_num);
        last if $node_num >= $self->node_count();
    }

    return $node_num;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Pure Perl implementation of the MaxMind DB reader code

