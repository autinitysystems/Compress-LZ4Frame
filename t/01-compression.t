#!/usr/bin/env perl

use 5.010_001;
use strict;
use warnings;

use constant PKG => 'Compress::LZ4Frame';

use Test::More tests => 10;

# try using
BEGIN { use_ok(PKG, ':all') };

# check interface
can_ok(PKG, 'compress');
can_ok(PKG, 'compress_checksum');
can_ok(PKG, 'decompress');
can_ok(PKG, 'looks_like_lz4frame');

# try some simple compression
my @data = map { $_ => rand } (1..50000);
my $input = pack('d*', @data);
my $compressed = compress $input;
my $decompressed = decompress $compressed;
is($input, $decompressed, 'decompressing compressed data yields original');
ok(length $compressed < length $input, 'compressed data is smaller than original');

# check the checker
ok(looks_like_lz4frame($compressed), 'compressed data should be detected as such');
ok(!looks_like_lz4frame($decompressed), 'uncompressed data should be detected as such');

# check decompressing concatenated data
my $catted_compressed = $compressed . $compressed;
my $catted_original = $input . $input;
my $catted_decompressed = decompress $catted_compressed;
is($catted_original, $catted_decompressed, 'decompressing concatenated frames yields concatenated original');
