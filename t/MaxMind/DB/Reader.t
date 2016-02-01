use strict;
use warnings;
use autodie;

use lib 't/lib';

# This must come before `use MaxMind::DB::Reader;` as otherwise the wrong
# reader may be loaded
use Test::MaxMind::DB::Reader;

use Path::Class qw( file );
use MaxMind::DB::Reader;
use Test::Fatal;
use Test::MaxMind::DB::Common::Util qw( standard_test_metadata );
use Test::More;

for my $record_size ( 24, 28, 32 ) {
    for my $file_type (qw( ipv4 mixed )) {
        _test_ipv4_lookups( $record_size, $file_type );
    }

    for my $file_type (qw( ipv6 mixed )) {
        _test_ipv6_lookups( $record_size, $file_type );
    }
}

{
    my $reader = MaxMind::DB::Reader->new(
        file => 'maxmind-db/test-data/MaxMind-DB-test-mixed-24.mmdb' );

    like(
        exception { $reader->record_for_address() },
        qr/You must provide an IP address to look up/,
        'exception when no IP address is passed to record_for_address()'
    );

    for my $bad (qw( foo 023.2.3.4 1.2.3 2003::abcd::24 -@@*>< )) {
        like(
            exception { $reader->record_for_address($bad) },
            qr/\QThe IP address you provided ($bad) is not a valid IPv4 or IPv6 address\E/,
            "exception when a bad IP address ($bad) is passed to record_for_address()"
        );
    }

    for my $private (
        qw( 10.44.51.212 10.0.0.3 172.16.99.44 fc00::24 fc00:1234:4bdf::1 )) {
        is(
            $reader->record_for_address($private),
            undef,
            "undef when a private IP address ($private) is passed to record_for_address()"
        );
    }
}

SKIP:
{
    skip 'This test requires Net::Works::Network 0.21+', 6
        unless eval {
        require Net::Works::Network;
        Net::Works::Network->VERSION(0.21);
        };

    my $reader = MaxMind::DB::Reader->new(
        file => 'maxmind-db/test-data/MaxMind-DB-test-mixed-24.mmdb' );

    my %nodes;
    my $node_cb = sub {
        $nodes{ $_[0] } = [ $_[1], $_[2] ];
    };

    my @networks;
    my $data_cb = sub {
        my $ipnum = shift;
        my $depth = shift;

        push @networks,
            Net::Works::Network->new_from_integer(
            integer     => $ipnum,
            mask_length => $depth,
            ip_version  => 6,
            )->as_string();
    };

    $reader->iterate_search_tree( $data_cb, $node_cb );

    my %node_tests = (
        0   => [ 1,   242 ],
        80  => [ 81,  197 ],
        96  => [ 97,  242 ],
        103 => [ 242, 104 ],
        241 => [ 96,  242 ],
    );

    for my $node ( sort keys %node_tests ) {
        is_deeply(
            $nodes{$node},
            $node_tests{$node},
            "values seen for node $node match expected values"
        );
    }

    my @expect_data = (
        '::1.1.1.1/128',
        '::1.1.1.2/127',
        '::1.1.1.4/126',
        '::1.1.1.8/125',
        '::1.1.1.16/124',
        '::1.1.1.32/128',
        '::1:ffff:ffff/128',
        '::2:0:0/122',
        '::2:0:40/124',
        '::2:0:50/125',
        '::2:0:58/127',
        '::ffff:1.1.1.1/128',
        '::ffff:1.1.1.2/127',
        '::ffff:1.1.1.4/126',
        '::ffff:1.1.1.8/125',
        '::ffff:1.1.1.16/124',
        '::ffff:1.1.1.32/128',
        '2001:0:101:101::/64',
        '2001:0:101:102::/63',
        '2001:0:101:104::/62',
        '2001:0:101:108::/61',
        '2001:0:101:110::/60',
        '2001:0:101:120::/64',
        '2002:101:101::/48',
        '2002:101:102::/47',
        '2002:101:104::/46',
        '2002:101:108::/45',
        '2002:101:110::/44',
        '2002:101:120::/48',
    );
    is_deeply(
        \@networks,
        \@expect_data,
        '$reader->iterate_search_tree() finds all the networks in the database'
    );
}

{
    is(
        exception {
            MaxMind::DB::Reader->new(
                file => file(
                    'maxmind-db/test-data/MaxMind-DB-test-mixed-24.mmdb')
                )
        },
        undef,
        'Using a file object does not cause a type error'
    );
}

{
    my $mmdb_record
        = MaxMind::DB::Reader->new(
        file => 'maxmind-db/test-data/GeoIP2-Domain-Test.mmdb' )
        ->record_for_address('2002:47a0:df00:0:0:0:0:0');
    ok( $mmdb_record, 'found record for expanded IPv6 address' );

    is(
        $mmdb_record->{domain}, 'verizon.net',
        'expanded IPv6 address has expected data'
    );

}

done_testing();

sub _test_ipv4_lookups {
    my $record_size = shift;
    my $file_type   = shift;

    my $filename = sprintf(
        'MaxMind-DB-test-%s-%s.mmdb',
        $file_type,
        $record_size
    );

    my $reader = MaxMind::DB::Reader->new(
        file => "maxmind-db/test-data/$filename" );

    my $ip_version = $file_type eq 'mixed' ? 6 : 4;
    _test_metadata(
        $reader,
        {
            ip_version  => $ip_version,
            record_size => $record_size,
        },
        $filename,
    );

    my @subnets = qw(
        1.1.1.1
        1.1.1.2
        1.1.1.4
        1.1.1.8
        1.1.1.16
        1.1.1.32
    );

    for my $ip (@subnets) {
        my $expect = ( $ip_version == 6 ? '::' : q{} ) . $ip;

        is_deeply(
            $reader->record_for_address($ip),
            { ip => $expect },
            "found expected data record for $ip - $filename"
        );
    }

    for my $pair (
        [ '1.1.1.3'  => '1.1.1.2' ],
        [ '1.1.1.5'  => '1.1.1.4' ],
        [ '1.1.1.7'  => '1.1.1.4' ],
        [ '1.1.1.9'  => '1.1.1.8' ],
        [ '1.1.1.15' => '1.1.1.8' ],
        [ '1.1.1.17' => '1.1.1.16' ],
        [ '1.1.1.31' => '1.1.1.16' ],
        [ '1.1.1.32' => '1.1.1.32' ],
        ) {

        my ( $ip, $expect ) = @{$pair};

        $expect = '::' . $expect if $ip_version == 6;

        is_deeply(
            $reader->record_for_address($ip),
            { ip => $expect },
            "found expected data record for $ip - $filename"
        );
    }

    for my $ip ( '1.1.1.33', '255.254.253.123' ) {
        is(
            $reader->record_for_address($ip),
            undef,
            "no data found for $ip - $filename"
        );
    }
}

sub _test_ipv6_lookups {
    my $record_size = shift;
    my $file_type   = shift;

    my $filename = sprintf(
        'MaxMind-DB-test-%s-%s.mmdb',
        $file_type,
        $record_size
    );

    my $reader = MaxMind::DB::Reader->new(
        file => "maxmind-db/test-data/$filename" );

    my @subnets = qw(
        ::1:ffff:ffff
        ::2:0:0
        ::2:0:40
        ::2:0:50
        ::2:0:58
    );

    _test_metadata(
        $reader,
        {
            ip_version  => 6,
            record_size => $record_size,
        },
        $filename,
    );

    for my $ip (@subnets) {
        is_deeply(
            $reader->record_for_address($ip),
            { ip => $ip },
            "found expected data record for $ip - $filename"
        );
    }

    for my $pair (
        [ '::2:0:1'  => '::2:0:0' ],
        [ '::2:0:33' => '::2:0:0' ],
        [ '::2:0:39' => '::2:0:0' ],
        [ '::2:0:41' => '::2:0:40' ],
        [ '::2:0:49' => '::2:0:40' ],
        [ '::2:0:52' => '::2:0:50' ],
        [ '::2:0:57' => '::2:0:50' ],
        [ '::2:0:59' => '::2:0:58' ],
        ) {

        my ( $ip, $expect ) = @{$pair};
        is_deeply(
            $reader->record_for_address($ip),
            { ip => $expect },
            "found expected data record for $ip - $filename"
        );
    }

    for my $ip ( '1.1.1.33', '255.254.253.123', '89fa::' ) {
        is(
            $reader->record_for_address($ip),
            undef,
            "no data found for $ip - $filename"
        );
    }
}

sub _test_metadata {
    my $reader          = shift;
    my $expect_metadata = shift;
    my $filename        = shift;

    my $metadata = $reader->metadata();
    my %expect   = (
        binary_format_major_version => 2,
        binary_format_minor_version => 0,
        ip_version                  => 6,
        standard_test_metadata(),
        %{$expect_metadata},
    );

    for my $key ( sort keys %expect ) {
        is_deeply(
            $metadata->$key(),
            $expect{$key},
            "read expected value for metadata key $key - $filename"
        );
    }

    my $epoch = $metadata->build_epoch();
    like(
        "$epoch",
        qr/^\d+$/,
        "build_epoch is an integer - $filename"
    );

    cmp_ok(
        $metadata->build_epoch(),
        '<=',
        time(),
        "build_epoch is <= the current timestamp - $filename"
    );
}
