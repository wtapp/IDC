#!/usr/bin/perl -w
##CAR2.pl
## Assumes inbound 600dpi color image
##


use strict;

use Image::Magick;
use Config;
use File::Basename;
use File::Find;

my $indir = "Z:/echantillon_microfiches/test";


#Make 'em PDF to TIFF first,
find(\&GSWin32, $indir);
find(\&DivBy4Check, $indir);

sub GSWin32
{
    my $file = $_;
    my($fileBaseName, $dirName, $fileExtension)  = fileparse($file, ('\.pdf'));
    
    if(-f)
    {
        #check to make sure this is a nice PDF we are working on...
        if (($fileExtension eq ".pdf") or ($fileExtension eq ".PDF"))
        {
            system("gswin32c", "-q", "-dSAFEER", "-dNOPAUSE", "-dBATCH", "-r300x300", "-sOutputFile=%03d.tif", "-sDEVICE=tiffg4",  $_);
        }
    }
    
}

sub DivBy4Check
{
    my $file = $_;
    my($fileBaseName, $dirName, $fileExtension)  = fileparse($file, ('\.pdf'));
    
    if(-d)
    {
        print "Working in directory " . $dirName . "\n";
    }elsif(-f){
    
        
        #check to make sure this is a nice PDF we are working on...
        if (($fileExtension eq ".tif") or ($fileExtension eq ".tiff"))
        {
            print "Working on file ".$fileBaseName . "\n";
            
            #instantiate the object
            my $oimage=Image::Magick->new;
    
            #Open the file         
            $oimage->Read($file);
        
            #check div/4 error
            my $width = $oimage->Get('width');
            my $height = $oimage->Get('height');
            
            #set all of the TIFF properties we need
                
               
            #Handle div by 4 errors for ebeam            
            my $myMod = (4-$width%4);

            my $newwidth = $width + $myMod;
                            
            $oimage->Scale(width=>$newwidth, height=>$height);
                
                
            $oimage->Set(compression=>'None',
                               option=>'quantum:polarity=min-is-white',
                               #option=>'tiff:rows-per-strip=10000',
                               density=>'300x300',
                               height => $height,
                               width => $newwidth);
                
                
            #Save the image back out to disk
            $oimage->write(filename=>$fileBaseName. ".tif",
                                 option=>'tiff:rows-per-strip=$newheight' );
            
            
            #clean up nicely after ourselves...
            undef $oimage;
        }
    }
}

sub PDF_2_TIFF
{
    my $file = $_;
    my($fileBaseName, $dirName, $fileExtension)  = fileparse($file, ('\.pdf'));
    
    if(-d)
    {
        print "Working in directory " . $dirName . "\n";
    }elsif(-f){
    
        
        #check to make sure this is a nice PDF we are working on...
        if (($fileExtension eq ".pdf") or ($fileExtension eq ".PDF"))
        {
            print "Working on file ".$fileBaseName . "\n";
            
            #instantiate the object
            my $oimage=Image::Magick->new;
    
            #Open the file         
            $oimage->Read($file);
        
            my $x;
            
            for($x = 0; $oimage->[$x]; $x++)
            {
                
            
                
                    
                #check div/4 error
                my $width = $oimage->[$x]->Get('width');
                my $height = $oimage->[$x]->Get('height');
                #my $density = $oimage->[$x]->Get('density');
                
                $width = ($width/72) *300;
                $height = ($height/72) * 300;
            
                #set all of the TIFF properties we need
                
                         
                #Handle div by 4 errors for ebeam            
                my $myMod = (4-$width%4);
                #print "Modulo...".$myMod."\n";
                my $newwidth = $width + $myMod;
                            
                #$oimage->[$x]->Scale(width=>$newwidth, height=>$height);
                
                
                $oimage->[$x]->Set(compression=>'None',
                         option=>'quantum:polarity=min-is-white',
                         #option=>'tiff:rows-per-strip=10000',
                         density=>'300x300',
                         height => $height,
                         width => $newwidth);
                
                #Make the image positive
                #$oimage->Negate();
            
                #Save the image back out to disk
                $oimage->[$x]->write(filename=>$fileBaseName. "-" .$x . ".tif",
                               option=>'tiff:rows-per-strip=$newheight' );
            
            }
            #clean up nicely after ourselves...
            undef $oimage;
        }
    }
}



sub check_file
{
    #looks at inbound JP2 file and creates a TIFF derivative from it
    my $file = $_;
    
        
    if(-f)
    {
    my($fileBaseName, $dirName, $fileExtension)  = fileparse($file, ('\.jp2'));
    
    #my $error;
    
    print "Working on file " . $fileBaseName . "\n";
    #instantiate an object
    my $oimage=Image::Magick->new;
    
    #Open the file         
    $oimage->Read($file);
      
    #my $info = $oimage->Get('id');
    #print $info .'\n';
    #Save the file back out
    #$oimage->write(filename=>$fileBaseName . ".tif", compression=>'None');
    
        
    undef $oimage;
    }
    
}

sub make_BW
{
    #destructive - takes inbound 600 dpi color images and
    #makes them 600 dpi Bitonal
    
    my $file = $_;
    
    
    if(-f)
    {
    #my $error;
    
    print "Working on file " . $file . "\n";
    #instantiate an object
    my $oimage=Image::Magick->new;
    
    #Open the file         
    $oimage->Read($file);
    
    my $new_w = 5328;
    my $new_h = 7154;
    
    #Set standard size for the images width x height
    $oimage->Resize($new_w .'x'. $new_h);
    
    $oimage->AdaptiveSharpen(radius=>'100.0');
    
    #Set to bitonal
    $oimage->BlackThreshold('220');
    
    #Save the file back out
    $oimage->write(filename=>$file, compression=>'Group4');
    
        
    undef $oimage;
    }
}

sub make_color
{
    #destructive - takes inbound 600 dpi color images and
    #makes them 300 dpi color
    
    
    my $file = $_;
    
    
    if(-f)
    {
    #my $error;
    
    print "Working on file " . $file . "\n";
    #instantiate an object
    my $oimage=Image::Magick->new;
    
    #Open the file         
    $oimage->Read($file);
    
    my($orig_h, $orig_w) = $oimage->Get('height', 'width');
    
    print $orig_h . " " . $orig_w . " " . "\n";
    
    #Resample the file
    $oimage->Set(density=>'300x300');
    
    #Resize the file
    $oimage->Resize($orig_w/2 .'x'. $orig_h/2);
    
    #$oimage->AdaptiveSharpen(radius=>'100.0');
    
    
    #Save the file back out
    $oimage->write(filename=>$file, compression=>'None');
    
        
    undef $oimage;
    }
    
}


sub chunk_map
{
    #Take 600 dpi color map, turn it into consituent parts.
    #Assumes the inbound filename will need to be changed
    
    ## **** NOT FINISHED ****
    
    my $file = $_;
    
    #instantiate an object
    my $oimage=Image::Magick->new;
    
    #Open the file         
    $oimage->Read($file);
 
    my ($name, $dir, $ext) = fileparse($file, '\..*');
    
    my($orig_h, $orig_w) = $oimage->Get('height', 'width');
    
    
}