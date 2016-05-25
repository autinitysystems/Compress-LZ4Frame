#!/usr/bin/env perl

use 5.010_001;
use strict;
use warnings;

use constant PKG => 'Compress::LZ4Frame';

use Compress::LZ4Frame qw(:all);

my @data = map { $_ => rand } (1..50000);
my $input = pack('d*', @data);
my $compressed = compress $input;
unless (defined($compressed)) {
    die 'compress returned undef';
}

my $decompressed = decompress $compressed;
if ($decompressed ne $input) {
    die 'decompressing compressed data yields original';
}

my $catted_compressed = $compressed . $compressed;
my $catted_original = $input . $input;
my $catted_decompressed = decompress $catted_compressed;
if ($catted_decompressed ne $catted_original) {
    die 'decompressing concatenated frames yields concatenated original';
}
