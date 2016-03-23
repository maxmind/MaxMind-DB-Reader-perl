# NAME

MaxMind::DB::Reader - Read MaxMind DB files and look up IP addresses

# VERSION

version 1.000012

# SYNOPSIS

    my $reader = MaxMind::DB::Reader->new( file => 'path/to/database.mmdb' );

    my $record = $reader->record_for_address('1.2.3.4');

# DESCRIPTION

This module provides a low-level interface to the [MaxMind DB file
format](http://maxmind.github.io/MaxMind-DB/).

If you are looking for an interface to MaxMind's [GeoIP2 or GeoLite2
downloadable databases](http://dev.maxmind.com/geoip/), you should also check
out the [GeoIP2](https://metacpan.org/pod/GeoIP2) distribution. That distribution provides a higher level OO
interface to those databases.

This API will work with any MaxMind DB databases, regardless of whether it is
a GeoIP2 database or not. In addition, if speed is critical, this API will
always be faster than the [GeoIP2](https://metacpan.org/pod/GeoIP2) modules, since it returns results as a raw
Perl data structure rather than as an object.

# PURE PERL VERSUS XS

The MaxMind-DB-Reader distribution ships with a single pure Perl
implementation of the Reader API. There is a separate distribution on CPAN,
[MaxMind::DB::Reader::XS](https://metacpan.org/pod/MaxMind::DB::Reader::XS), that provides an XS implementation which links
against [libmaxminddb](http://maxmind.github.io/libmaxminddb/).

The XS implementation is approximately 100 times faster than the pure Perl
implementation, so if speed is important to you, we highly recommend that you
install it!

If you install the XS implementation it will be automatically loaded. You do
not need to change your code to take advantage of it.

# API

This module provides the following API:

## MaxMind::DB::Reader->new( file => $path )

This method returns a new reader object. Note that the class of the object
returned will actually be either [MaxMind::DB::Reader::PP](https://metacpan.org/pod/MaxMind::DB::Reader::PP) or
[MaxMind::DB::Reader::XS](https://metacpan.org/pod/MaxMind::DB::Reader::XS).

If you need to check that an object is a valid reader, you should check that
the object does the `MaxMind::DB::Reader::Role::Reader` role.

The "file" parameter is a required attribute for the constructor. It must be a
string containing a path to a file. The constructor will die if the file
provided is not readable.

You can also pass an additional parameter, "data\_source", which must be a valid
filehandle. This is useful in testing. For example, you can have the reader
read from a filehandle opened to a scalar reference. Under normal usage, the
reader simply opens the provided file to read from.

## $reader->record\_for\_address($ip\_address)

This method takes an IPv4 or IPv6 address as a string. This can be either a
dotted quad (`1.2.3.4`) or any valid IPv6 format (`abcd::1234`,
`::1.2.3.4`, etc.).

This method will die if the address is not a valid IP address.

The method returns the data associated with the IP address. Depending on the
contents of the database, this can be a scalar or a reference to an array or
hash.

## $reader->iterate\_search\_tree( $data\_callback, $node\_callback )

This method iterates over the entire search tree, calling the callbacks you
provided for each data record and node in the tree.

Both callbacks are optional (although calling this with neither will do a lot
of work for no good reason).

The node callback is called for every node in the database's search tree. This
callback is called with three arguments. These are the node's number (which is
based on its position in the file) and the values of its left and right
records. These values are themselves numbers. See the [MaxMind DB
spec](http://maxmind.github.io/MaxMind-DB/) for more details on what node
record values mean.

The data callback is called for records that point to the database's data
section. The first two arguments identify the network that the data record
applies to. The first argument is an IP address as an integer and the second
is a network mask length. The final argument is the data associated with the
network.

## $reader->metadata()

This method returns a [MaxMind::DB::Metadata](https://metacpan.org/pod/MaxMind::DB::Metadata) object for the database.

## $reader->file()

This method returns the file path passed to the constructor.

# VERSIONING POLICY

This module uses semantic versioning as described by
[http://semver.org/](http://semver.org/). Version numbers can be read as X.YYYZZZ, where X is the
major number, YYY is the minor number, and ZZZ is the patch number.

# SUPPORT

Please report all issues with this code using the GitHub issue tracker at
[https://github.com/maxmind/MaxMind-DB-Reader-perl/issues](https://github.com/maxmind/MaxMind-DB-Reader-perl/issues).

# AUTHORS

- Dave Rolsky &lt;drolsky@maxmind.com>
- Olaf Alders &lt;oalders@maxmind.com>

# CONTRIBUTORS

- Greg Oschwald &lt;goschwald@maxmind.com>
- Mateu X Hunter &lt;mhunter@maxmind.com>
- Ran Eilam &lt;reilam@maxmind.com>
- William Stevenson &lt;skyblue@skybluecircles.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
