#!/usr/bin/perl -w
use strict;

#Deskewme.pl
#03.30.11 XWWT
#Takes files from indrive and deskews them, then saves the file to the
#outlocation directory

my $indrive = "T:/New_Leader/READY_For_Deskew";
my $outLocation = "T:/New_Leader/DESKEW_COMPLETE";
my $currentOutPath;

use Cwd;
use File::Basename;
use File::Find;
use File::Path qw(make_path remove_tree); #This process of creating paths in Windows works!
use Image::Magick;


use constant PERMISSIONS => 755;

find(\&moveFile, $indrive);

sub moveFile
{
    #checks the inbound to see if it is a directory or a file
    #If it is a directory then it creates a copy of that sub directory
    #into the $outLocation
    #If it is a file it just does the next operation on the file
    if (($_ =~ /System Volume Information/) or ($_ =~ m/\$RECYCLE/))
    {
        print "System file found...skipping.\n";
        return;
    }
    
    if(-d)
    {
        if (($_ eq ".") or ($_ eq "..") )
        {
            print "Root or previous found, skipping.\n";
            return;
        }
        
        print "Creating a directory $_\n";
        #make the analog path on the $outLocation;
        
        my $endpath = "$outLocation/".substr(getcwd,length($indrive))."/$_";
        
        print "$endpath\n";
        
        make_path($endpath) or die "Could not make $endpath - aborting.\n";
        $currentOutPath = $endpath;
        
        #, mode => PERMISSIONS
        return;
    }
    
    if(-f)
    {
        deskewMe($_);
    }
    
}#end movefile


sub deskewMe()
{
    #Runs the PM deskew on all the images.
    #10.21.10 - XWWT Created
    #10.22.10 - XWWT Added in crop function to tighten geometry.
    #03.30.11 - Fixed to work in a new directory
    if(-f)
    {
     print ".";
     my($fileBaseName, $dirName, $fileExtension)  = fileparse($_, ('\.tif'));
     if (($fileExtension eq ".tif") or ($fileExtension eq ".TIF"))
     {     
        #11.16.10 XWWT - Old method chopped up the images and lost content...
        #system('mogrify -fill white -background white -set option:deskew:auto-crop 20 -deskew 40% '.$_);    

        #instantiate an object
        my $oimage=Image::Magick->new;
    
        #Open the file         
        $oimage->Read($_);
 
        $oimage->Deskew(threshold=>"40%"); #, option=>'deskew:auto-crop 20'           
        $oimage->write(filename=>$currentOutPath."/".$fileBaseName.$fileExtension);
    
        undef $oimage;
     }
    }
}#end deskewMe


