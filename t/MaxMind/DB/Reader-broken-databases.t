use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More;

use lib 't/lib';
use Test::MaxMind::DB::Reader;

use MaxMind::DB::Reader;
use Path::Class qw( tempdir );

{    # Test broken doubles
    my $reader
        = MaxMind::DB::Reader->new( file =>
            'maxmind-db/test-data/GeoIP2-City-Test-Broken-Double-Format.mmdb'
        );
    like(
        exception { $reader->record_for_address('2001:220::') },
        qr/The MaxMind DB file's data section contains bad data \(unknown data type or corrupt data\)/,
        'got expected error for broken doubles'
    );
}

{    # test broken search tree pointer
    my $reader = MaxMind::DB::Reader->new( file =>
            'maxmind-db/test-data/MaxMind-DB-test-broken-pointers-24.mmdb' );
    like(
        exception { $reader->record_for_address('1.1.1.32') },
        qr/The MaxMind DB file's search tree is corrupt/,
        'received expected exception with broken search tree pointer'
    );
}

{    # test broken data pointer
    my $reader = MaxMind::DB::Reader->new( file =>
            'maxmind-db/test-data/MaxMind-DB-test-broken-pointers-24.mmdb' );
    like(
        exception { $reader->record_for_address('1.1.1.16') },
        qr/The MaxMind DB file's data section contains bad data \(unknown data type or corrupt data\)/,
        'received expected exception with broken data pointer'
    );
}

{    # test non-database
    my $dir = tempdir( CLEANUP => 1 );
    my $file = $dir->file('garbage');
    open my $fh, '>', $file;
    print {$fh} "garbage text\n"
        or die $!;
    close $fh;

    like(
        exception { MaxMind::DB::Reader->new( file => $file ) },
        qr/Error opening database file "\Q$file\E": The MaxMind DB file contains invalid metadata/,
        'expected exception with unknown file type'
    );
}

{    # test missing file
    like(
        exception {
            MaxMind::DB::Reader->new( file => 'does/not/exist.mmdb' );
        },
        qr/Error opening database file "does\/not\/exist.mmdb"/,
        'expected exception with file that does not exist'
    );
}

done_testing();
