#!/usr/bin/perl -w
##Colorsplit.pl
##Takes inbound images and splits into their component R,G,B, Opacity images
##for ebeam compilation

use strict;

use Image::Magick;
use Image::Magick::Info;
use Config;
use File::Basename;
use File::Find;


#Set my globals
my $indir = "f:/3/source";
my $outdir = "f:/3/result/";

#Run my app
find(\&doit, $indir);


sub doit
{
    
    if(-f)
    {
        #Then check to see if it is a TIFF file
        my ($name, undef, $ftype) = fileparse($_, qr{\..*});
        if (($ftype eq ".tif") or ($ftype eq ".tiff"))
        {
            #instantiate an object
            my $oimage=Image::Magick->new;
            my $gimage=Image::Magick->new;
            my $rimage=Image::Magick->new;
            my $bimage=Image::Magick->new;
            
            #define my image path
            my $filename = $_;
            
            
            print "Reading in file " . $filename . "\n";
            
            #Get the channels & write them out
            $rimage->Read($filename);
            $rimage->Channel(channel=>'Red');
            $rimage->Write($outdir . $name . "-r.tif");
            
            $gimage->Read($filename);
            $gimage->Channel(channel=>'Green');
            $rimage->Write($outdir . $name . "-g.tif");
            
            $bimage->Read($filename);
            $bimage->Channel(channel=>'Blue');
            $rimage->Write($outdir . $name . "-b.tif");
            
            $oimage->Read($filename);
            $oimage->Channel(channel=>'Opacity');
            $rimage->Write($outdir . $name . "-o.tif");
            
            
            
            undef $gimage, $rimage, $bimage, $oimage;
        }
    }
}