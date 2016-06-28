#!/usr/bin/perl -w
##NYPRessTest.pl
## Assumes inbound 300dpi gray TIFF image
## Thunks DPI to 600 and sets all image sizes to double the original size.
##


use strict;

use Image::Magick;
use Config;
use File::Basename;
use File::Find;


my $indir = "Y:/NYU Press/Missing pages/wes";


find(\&THUNK_TIFF, $indir);


sub THUNK_TIFF
{
    my $file = $_;
    my($fileBaseName, $dirName, $fileExtension)  = fileparse($file, ('\.jpg'));
    
    if(-d)
    {
        print "Working in directory " . $dirName . "\n";
    }elsif(-f){
    
        
        #check to make sure this is a nice JPEG we are working on...
        if (($fileExtension eq ".jpg") or ($fileExtension eq ".JPG"))
        {
            print "Working on file ".$fileBaseName . "\n";
            
            #instantiate the object
            my $oimage=Image::Magick->new;
    
            #Open the file         
            $oimage->Read($file);
        
           my $newwidth = 1710; #$oimage->Get('width') * 2;
           my $newheight = 2690; #$oimage->Get('height') * 2;
           $oimage->Scale(width=>$newwidth, height=>$newheight);
           $oimage->Set(density=>'600x600');
            
            #paper-white the image
            #$oimage->Negate();
            #$oimage->Modulate(brightness=>'91');
            #$oimage->Negate();
            
            
            #$oimage->ReduceNoise('3.0');  #funny edges to the characters
            #$oimage->Set(gamma=>'2.2');
            #$oimage->Contrast(sharpen=>'True');
            
            
            $oimage->Despeckle();
            
            
            #Save the image back out to disk
            $oimage->write(compression=>'None', filename=>$fileBaseName . ".tif", colorspace=>'Gray');
            #               option=>'tiff:rows-per-strip=$newheight' );
            
    
            #clean up nicely after ourselves...
            undef $oimage;
        }
    }
}


