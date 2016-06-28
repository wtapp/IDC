#!/usr/bin/perl -w
##pb_recolor.pl
##Reads in a PB image and changes the color values, then saves as a 75% JPG

##11.3.2010 XWWT

use strict;

use Config;

use File::Basename; #to break filenames up
use File::Find; #to process sub dirs
#use File::Path qw(make_path);#for mkdir
use Image::Magick; #for image handling




#Set my globals
my $base_indir = "Y:/Playboy/2010 PB Crop images";
my $base_outdir = "Y:/Playboy/2010 PB CROP JPG images";

my @indir = (
    #"200050_20100301",
    "200050_20100401",
    "200050_20100501",
    "200050_20100601",
    "200050_20100701",
    "200050_20100801",
    "200050_20100901",
    "200050_20101001",
    "200050_20101101",
    "200050_20101201"
    );

my $workingdir = "";

#Run my app
print "Running...";
 my $err = Proc_Subdir();


sub Proc_Subdir
{
    print "Processing sub directories...";
    foreach(@indir)
    {
        #make a subdirectory in the baseoutdir as a landing spot
        $workingdir = $base_outdir."\\".$_."\\\n";
        
        #system "mkdir ".$workingdir;
        #print "\n".$workingdir;
        find(\&doit, $base_indir."\\".$_);        
    }


    print "Done.";
    return 1;
}#end Proc_Subdir

sub doit
{
    #print "In doit...";
    if(-d)
    {
        #if it is a directory then create a mirror copy of it...
        
    }
    
    if(!-f) {return;}
    
    #Then check to see if it is a TIFF file
    my ($name, undef, $ftype) = fileparse($_, qr{\..*});
    if (!($ftype eq ".tif") and !($ftype eq ".tiff"))    {return; }
        
    #define my image path
    my $filename = $_;
           
    print "Reading in file " . $name . "\n";
    
    my $g = 0;
    my $b = .2;
    
    my $oimage=Image::Magick->new;
    $oimage->Read($filename);
    my $err = $oimage->ColorMatrix([1, 0, 0, 0, 0,
                                    $g, 1, 0, 0, 0,
                                    $b, 0, 1, 0, 0,
                                    0, 0, 0, 1, 0,
                                    0, 0, 0, 0, 1]);
#print "!!!".$workingdir;
    $err = $oimage->Write(filename=>$workingdir.$name.".jpg", quality=>75);

=pod    
    warn "$err" if !ref($err);  # print the error message
    $err =~ /(\d+)/;
    print $1;               # print the error number
=cut    
    undef $oimage;                        

}#end doit



