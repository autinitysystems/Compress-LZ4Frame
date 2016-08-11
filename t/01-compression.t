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
my $input = pack 'd*', @data;
my $compressed = compress $input;
my $decompressed = decompress $compressed;
is($decompressed, $input, 'decompressing compressed data yields original');
ok(length $compressed < length $input, 'compressed data is smaller than original');

# check the checker
ok(looks_like_lz4frame($compressed), 'compressed data should be detected as such');
ok(!looks_like_lz4frame($decompressed), 'uncompressed data should be detected as such');

# check decompressing concatenated data
my $catted_compressed = $compressed . $compressed;
my $catted_original = $input . $input;
my $catted_decompressed = decompress $catted_compressed;
is($catted_decompressed, $catted_original, 'decompressing concatenated frames yields concatenated original');

# check decompressing data without size info
my $hello_compressed = pack 'W*',
    0x04, 0x22, 0x4d, 0x18, 0x64, 0x70, 0xb9, 0x0d, 0, 0, 0x80, 0x48, 0x65. 0x6c, 0x6c, 0x6f,
    0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x21, 0x0a, 0, 0, 0,    0,    0xe8, 0x1e, 0x4b, 0x08;
my $hello_decompressed = decompress $hello_compressed;
is($hello_decompressed, "Hello world!\n", 'decompressing frames where size header is 0 should work');
