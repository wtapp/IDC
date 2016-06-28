#!/usr/bin/perl -w
##Sheridan.pl
## Assumes inbound 300dpi gray TIFF image
## Thunks DPI to 800 and sets all image sizes to the same fixed outer size.
##


use strict;

use Image::Magick;
use Config;
use File::Basename;
use File::Find;

#my $indir = "//sacr-mfiler01/SalineCrowley/CSP/Sheridan test/2";
my $indir = "z:/Tests/Sheridan_Test/3";
#my $indir = "Z:/Tests/Sheridan_Test/Working/biblia de bosquejos y sermones";


find(\&THUNK_TIFF, $indir);


sub THUNK_TIFF
{
    my $file = $_;
    my($fileBaseName, $dirName, $fileExtension)  = fileparse($file, ('\.tif'));
    
    if(-d)
    {
        print "Working in directory " . $dirName . "\n";
    }elsif(-f){
    
        
        #check to make sure this is a nice JPEG we are working on...
        if ($fileExtension eq ".tif")
        {
            print "Working on file ".$fileBaseName . "\n";
            
            #instantiate the object
            my $oimage=Image::Magick->new;
    
            #Open the file         
            $oimage->Read($file);
        
            
            $oimage->Scale(width=>6400, height=>8550);
            $oimage->Set(density=>'800x800');
            
            #paper-white the image
            #$oimage->Negate();
            #$oimage->Modulate(brightness=>'91');
            #$oimage->Negate();
            
            
            #$oimage->ReduceNoise('3.0');  #funny edges to the characters
            #$oimage->Set(gamma=>'2.2');
            #$oimage->Contrast(sharpen=>'True');
            
            
            #$oimage->Despeckle();
            
            
            #Save the image back out to disk
            $oimage->write(filename=>$fileBaseName . ".tif");
            #               option=>'tiff:rows-per-strip=$newheight' );
            
    
            #clean up nicely after ourselves...
            undef $oimage;
        }
    }
}


