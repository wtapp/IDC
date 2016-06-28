#!/usr/bin/perl -w
use strict;

use File::Basename;
use File::Find;
use Image::Magick;

my @files = <"S:/CSP/Small Projects/Sheridan Test/Journeyman Wireman/*">;


test();

sub test{
    my $file;
    my $status;
    
    #Make a new PDF File
    my $oMagick = Image::Magick->new(format=>"pdf");
    
    foreach $file (@files){
        
        #Determine if each file in the list is a TIF or not
        my($fileBaseName, $dirName, $fileExtension)  = fileparse($file, ('\.tif'));
        if (($fileExtension eq ".tif") or
            ($fileExtension eq ".TIF")){
                              
                
                #If it is a TIFF, then add it onto my PDF file?
                #!!!I think this will work
                $status = $oMagick->Read($file);
                warn "Read failed for " . $file . " $status\n" if $status;
                
                #print $file . "\n";    
        }
    }
    
    #Now that we are done with the files, save/write the PDF out
    $status = $oMagick->Write("pdf:combined.pdf");
    warn "Write failed! $status" if $status;
}
