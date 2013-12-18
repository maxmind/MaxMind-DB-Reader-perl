use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More;

use lib 't/lib';
use Test::MaxMind::DB::Common::Util qw( standard_test_metadata );
use Test::MaxMind::DB::Reader;

use Net::Works::Network;

use MaxMind::DB::Reader;

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
        like(
            exception { $reader->record_for_address($private) },
            qr/\QThe IP address you provided ($private) is not a public IP address\E/,
            "exception when a private IP address ($private) is passed to record_for_address()"
        );
    }
}

{
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
        0   => [ 1,   225 ],
        80  => [ 81,  197 ],
        96  => [ 97,  225 ],
        103 => [ 225, 104 ],
        224 => [ 96,  225 ],
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
        '::1.1.1.63/128',
        '::1:ffff:ffff/128',
        '::3:ffff:ffc0/122',
        '::3:ffff:fff0/124',
        '::3:ffff:fff8/125',
        '::3:ffff:fffe/127',
        '::ffff:255.255.255.255/128',
        '::ffff:255.255.255.254/127',
        '::ffff:255.255.255.252/126',
        '::ffff:255.255.255.248/125',
        '::ffff:255.255.255.240/124',
        '::ffff:255.255.255.255/128',
        '2002:101:101::/48',
        '2002:101:102::/47',
        '2002:101:104::/46',
        '2002:101:108::/45',
        '2002:101:110::/44',
        '2002:101:13f::/48',
    );
    is_deeply(
        \@networks,
        \@expect_data,
        '$reader->iterate_search_tree() finds all the networks in the database'
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

    my @subnets
        = Net::Works::Network->range_as_subnets( '1.1.1.1', '1.1.1.32' );

    for my $ip ( map { $_->first()->as_string() } @subnets ) {
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

    my @subnets = Net::Works::Network->range_as_subnets(
        '::1:ffff:ffff',
        '::2:0000:0059'
    );

    _test_metadata(
        $reader,
        {
            ip_version  => 6,
            record_size => $record_size,
        },
        $filename,
    );

    for my $ip ( map { $_->first()->as_string() } @subnets ) {
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
