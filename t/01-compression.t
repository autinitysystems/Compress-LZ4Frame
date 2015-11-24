#!/usr/bin/env perl

use 5.010_001;
use strict;
use warnings;

use constant PKG => 'Compress::LZ4Frame';

use Test::More tests => 5;

# try using
BEGIN { use_ok(PKG, ':all') };

# check interface
can_ok(PKG, 'compress');
can_ok(PKG, 'compress_checksum');
can_ok(PKG, 'decompress');

# try some simple compression
my @data = map { rand } (1..5000);
my $input = pack('d*', @data);
my $compressed = compress $input;
my $decompressed = decompress $compressed;
is($input, $decompressed, 'decompressing compressed data yields original');

