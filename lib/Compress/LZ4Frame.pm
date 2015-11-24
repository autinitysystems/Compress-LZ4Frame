package Compress::LZ4Frame;
# ABSTRACT: Compression package using the lz4frame library

use 5.010_001;
use strict;
use warnings;

use base qw(XSLoader);

__PACKAGE__->load($VERSION);

1;

