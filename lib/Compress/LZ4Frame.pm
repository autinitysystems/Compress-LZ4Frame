package Compress::LZ4Frame;
# ABSTRACT: Compression package using the lz4frame library

use 5.010_001;
use strict;
use warnings;
use vars qw($VERSION);

use base qw(XSLoader);
use Exporter qw(import);

__PACKAGE__->load($VERSION);

our @EXPORT_OK = qw(compress compress_checksum decompress);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

1;

