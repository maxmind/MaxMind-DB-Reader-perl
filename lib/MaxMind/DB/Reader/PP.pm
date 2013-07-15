package MaxMind::DB::Reader::PP;

use strict;
use warnings;
use namespace::autoclean;

use MaxMind::DB::Types qw( Str );

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

sub _build_data_source {
    my $self = shift;

    open my $fh, '<:raw', $self->file();

    return $fh;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Read MaxMind DB files
