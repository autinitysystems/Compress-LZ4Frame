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
my $hello_compressed =
    "\x04\x22\x4d\x18\x64\x70\xb9\x0d\x00\x00\x80\x48\x65\x6c\x6c\x6f"
.   "\x20\x77\x6f\x72\x6c\x64\x21\x0a\x00\x00\x00\x00\xe8\x1e\x4b\x08";
my $hello_decompressed = decompress $hello_compressed;
is($hello_decompressed, "Hello world!\n", 'decompressing frames where size header is 0 should work');
