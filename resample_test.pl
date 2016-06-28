#!/usr/bin/perl -w
##resample_test.pl
##Used to resample a set of images

##11.22.2010 XWWT

use strict;

use Config;

use File::Basename;
use File::Find;

use Image::Magick;

#Set my globals
my $indir = "X:/XanEdu ePub/Feedback/wes/OEBPS/Images";
my $outdir = "C:/Temp/PB/test/base_output/";

#Run my app
print "Running...";

#find(\&doit, $indir);

#doit($indir."/200050_20100301_001.tif");

find(\&doit, $indir);

print "Done.";

sub doit
{   
    #print "In doit...";
    if(-d)
    {
        #if it is a directory then create a mirror copy of it...
        
    }
    #print $_ ."\n";
    if(!-f)
    {
        return;
    }
    
    #Then check to see if it is a TIFF file
    my ($name, undef, $ftype) = fileparse($_, qr{\..*});
    if (!($ftype eq ".JPG") and !($ftype eq ".jpg"))
    {
        return;
    }
        
    #define my image path
    my $filename = $_;
           
    print "Reading in file " . $name . "\n";
    
    
    my $oimage=Image::Magick->new;
    $oimage->Read($filename);
    
    my($orig_h, $orig_w, $orig_den) = $oimage->Get('height', 'width', 'density');
    
    #print $orig_h . " " . $orig_w . " " . "\n";
    #print $orig_den ."\n";
    
    #Resample the file
    $oimage->Set(density=>'150x150');
    
    #Resize the file
    #$oimage->Resize($orig_w*1.62 .'x'. $orig_h*1.62);
    
    #$oimage->Enhance();
    #$oimage->Dither();
    $oimage->AdaptiveSharpen(radius=>'100.0');
    
    #$oimage->Resample(density=>'150x150');
    
    $oimage->Write(filename=>$_);
    undef $oimage;                        
}


