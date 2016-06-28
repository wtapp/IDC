#!/usr/bin/perl -w
##ColorCount.pl
## Tool to fix cengage problems...
## Works on TIFF & JPG images
## Works through a set of directories and counts the total number of images
## and the number of images that are in the colorspace RGB.

##2.28.2011 XWWT

use strict;

use Config;

use File::Basename;
use File::Find;
use File::Path;
use Image::Magick;

#Set my globals
my $baseindir = "I:/Tarry Town";
my $baseoutdir = $baseindir;
my $total_image_count;
my $total_jpeg_compress_count;
my $rgb_color_count;

my @indir =
(
    "/Disk 1"
    ,"/Disk 2"
    ,"/Disk 3"
    ,"/Disk 4"
    ,"/Disk 5"
);

my $outdir; #Defined based on subdir and baseindir

#Run my app
print "Running...";

my $err = ProcDir();

print "Done.";


sub ProcDir
{
    my $tmpdir;
    
    foreach $tmpdir(@indir)
    {
        my $dir = $baseindir.$tmpdir;
           
        print "\nWorking on ". $dir ."\n";
           
        find(\&count_color, $dir);
    }
    
    print "Total images inspected: " . $total_image_count . "\n";
    print "Total JPEG compress images: " . $total_jpeg_compress_count . "\n";
    print "Total RGB colorspace images: " . $rgb_color_count . "\n";
    
    return 1;
}



sub count_color
{
    #Error check - make sure this is an image file we can process
    
    if(!-f){return;}
    
    
    #Then check to see if it is a TIFF file
    my ($filename, undef, $filetype) = fileparse($_, qr{\..*});
    if (!($filetype eq ".tif") and !($filetype eq ".tiff") and !($filetype eq ".jpg") and !($filetype eq ".jpeg"))
    { return;}
    
    my $err;
    $total_image_count++;
    
    #instantiate an object
    my $oimage=Image::Magick->new;
    
        
    #Open the file         
    $err = $oimage->Read($_);
     
    
    my ($image_type, $compression) = $oimage->Get('colorspace', 'compression');
    
    print $_ ."\t". $image_type . "\t" . $compression ."\n";
    
    if ($compression eq "JPEG")
    {
        $total_jpeg_compress_count++;
    }
       
    if ($image_type eq "RGB")
    {
        $rgb_color_count++;
    }
    #Cleanup memory...
    undef $oimage;
}