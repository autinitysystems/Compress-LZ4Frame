#!/usr/bin/env perl

use strict;
use warnings;

use Compress::LZ4Frame ':all';

open(my $fh, '<', $ARGV[0]);
binmode($fh);
my $data = do { local $/; <$fh> };
close($fh);

my $uncompressed = decompress($data);
print length($uncompressed) . "\n";
