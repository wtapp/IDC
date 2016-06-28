#!/usr/bin/perl -w
use strict;


use strict;
use Config;
use File::Basename;
use File::Copy;
use File::Find;
use Image::Magick;

my $dir = "Z:/Tests/JSTOR/test/";
my $in_file = $dir."072.tif";
my $out_file = $dir."a.tif";

my $oimg = Image::Magick->new;

$oimg->Read($in_file);
$oimg->Deskew(threshold=>'40%');
$oimg->Write($out_file);
undef $oimg;

