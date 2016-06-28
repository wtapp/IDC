#!/usr/bin/perl -w
use strict;


use Image::Info qw(image_info dim);

my $oimage  = image_info("C:/Perl/scripts/a.tif");


if (my $error = $oimage->{error})
{
    die "Can't pare the image: $error\n";
}

print $oimage->{BitsPerSample};
print $oimage->{SamplesPerPixel};

#foreach()

print %$oimage;

undef $oimage;


=pod
width3440
file_media_typeimage/tiff
file_exttifPhotometricInterpretationRGB PaletteResolutionUnitdpi
CompressionPackBytes
BitsPerSample8
YResolution
SamplesPerPixel1
RowsPerStrip2
StripByteCountsARRAY(0x46960f4)height4600
StripOffsetsARRAY(0x4696024)Orientationtop_left
PlanarConfigurationChunky
XResolution
SoftwareIrfanView
ColorMapARRAY(0x18778c4)
=cut