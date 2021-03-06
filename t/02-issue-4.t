#!/usr/bin/env perl

use 5.010_001;
use strict;
use warnings;

use Compress::LZ4Frame qw(:all);

use Test::More tests => 1;

my $sample_data = pack('H*', '04224d186040822901000014000100ff0b01080cc120a6f701000000015e7b08a6d5ffffffff000107f6580100ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc5505858585858130000001f580100ffffffffffffffff0750585858585800000000');
my $decompressed = decompress($sample_data);
is(67608, length($decompressed), "test data should be decompressed correctly.");

