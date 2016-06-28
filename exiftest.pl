#!/usr/bin/perl -w
use strict;

use Image::ExifTool;

my $exifTool = new Image::ExifTool;

my $info = $exifTool->ImageInfo('C:/BuildFolder/leptonlib-1.67/vs2008/prog_projects/hellolept/a.tif');

my ($height, $width) = $exifTool->GetInfo('C:/BuildFolder/leptonlib-1.67/vs2008/prog_projects/hellolept/a.tif','ImageHeight','ImageWidth');

print "$height $width\n";


foreach(keys %$info)
{
    print "$_ => $$info{$_}\n";

}





