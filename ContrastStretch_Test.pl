#!/usr/bin/perl -w
use strict;

use strict;
use Config;
use File::Basename;
use File::Copy;
use File::Find;
use Image::Magick;

my $dir = "Z:/Tests/JSTOR/test/";
my $in_file = $dir."002.tif";
my $out_file = $dir."a.tif";

my $oimg = Image::Magick->new;

$oimg->Read($in_file);
$oimg->ContrastStretch(levels=>'0');

#$oimg->Despeckle();
          
#$oimg->AdaptiveSharpen(radius=>'100.0');
  
#Set to gs
$oimg->Quantize(colorspace=>'gray');

$oimg->Threshold(threshold=>"73%");
        
#Save the file back out, setting the compression to G4
$oimg->write(filename=>$out_file, compression=>'Group4');
        
#$oimg->Write($out_file);
undef $oimg;


