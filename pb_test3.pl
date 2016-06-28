#!/usr/bin/perl -w
##pb_test.pl
##Reads in a PB image

##11.3.2010 XWWT

use strict;

use Config;

use File::Basename;
use File::Find;

use Image::Magick;




#Set my globals
my $indir = "C:/Temp/PB/test/Base";
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
    if (!($ftype eq ".tif") and !($ftype eq ".tiff"))
    {
        return;
    }
        
    #define my image path
    my $filename = $_;
           
    print "Reading in file " . $name . "\n";
    
    for (my $g = .00; $g<.5; $g+=.1)
    {
        for(my $b = .00; $b<.5; $b+=.1)
        {
            my $oimage=Image::Magick->new;
            $oimage->Read($filename);
            my $err = $oimage->ColorMatrix([1, 0, 0, 0, 0,
                                            $g, 1, 0, 0, 0,
                                            $b, 0, 1, 0, 0,
                                            0, 0, 0, 1, 0,
                                            0, 0, 0, 0, 1]);
   
            $oimage->Write(filename=>$outdir . "\\" . $g."-".$b."-".$name.".jpg", quality=>75);
            undef $oimage;                        
        }
    }            
    
}

=pod
[1, 0, 0, 0, 0,
                             0.1, 1, 0, 0, 0,
                             0.4, 0, 1, 0, 0,
                             0, 0, 0, 1, 0,
                             0.5, 0.5, 0.5, 0, 1]
=cut

sub Desaturate_and_Overlay
{
    if(!-f) {return;}
    
    my ($name, undef, $ftype) = fileparse($_, qr{\..*});
    if (!($ftype eq ".tif") and !($ftype eq ".tiff")) {return;}
    
    my $oimg = Image::Magick->new();
    
    $oimg->Read($_);
    
    my $oimgOverlay = $oimg->Copy();
    
    $oimg->Write($_);
    
       
    
}