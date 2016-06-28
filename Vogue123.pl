#!/usr/bin/perl -w
##Vogue.pl
##Reads in a Vogue image
##Converts the image to 400 DPI TIFF using IM
##Converts the image to Jp2 using J2K (image_to_j2k)
##Converts the image back to TIFF, set density to 400dpi compress None
##Convert the TIFF to 300 dpi resample 300x300
##Convert the TIFF to JPG quality 100%

use strict;

use Image::Magick;
use Image::Magick::Info;
use Config;
use File::Basename;
use File::Find;


#Set my globals
my $indir = "c:/temp/Kodak K3";
my $outdir = "c:/temp/Kodak K3/JPG";

#Run my app
print "Running...";

find(\&doit, $indir);

print "Done.";

sub doit
{
    #print "In doit...";
    
    if(-f)
    {
        #Then check to see if it is a TIFF file
        my ($name, undef, $ftype) = fileparse($_, qr{\..*});
        if (($ftype eq ".tif") or ($ftype eq ".tiff"))
        {
            #instantiate an object
            my $oimage=Image::Magick->new;
            
            #define my image path
            my $filename = $_;
            
            
            print "Reading in file " . $name . "\n";
            
            #Open the file         
            $oimage->Read($filename);
            
            #Operate on the file
            #$oimage->Channel(channel=>'Opacity');
            #$oimage->Resample(x=>'400', y=>'400');

            $oimage->Comment("The  Company");

            $oimage->Write($outdir . "/noncolorcorrected". "\\" . $name.".jpg");


            $oimage->AutoLevel(channel=>'All');
            $oimage->AutoGamma(channer=>'All');
            #$oimage->LinearStretch('Levels'=>'1', channel=>'All');
            #Write the image back out
            print "Writing out file " . $outdir . "\\" . $name.".jpg";
            $oimage->Write($outdir . "/colorcorrected". "\\" . $name.".jpg");
            #$oimage->Write($filename);
            
            #Cleanup memory...
            undef $oimage;
        }
    }
}
