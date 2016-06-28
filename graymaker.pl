#!/usr/bin/perl -w
use strict;

use Config;
use File::Basename;
use File::Copy;
use File::Find;
use Image::Magick;


#Always start the process with the indir...this is the directory that is the root directory.contains the base color files...

my $indir;


my $max_height = -1;
my $max_width = -1;

$indir = "Z:/Tests/goofy images/working";

main($indir);


sub main
{
   
####################
## Main routines
##
##


    my $dir = shift;
    
    
#Size all of the color files to be the same size - look for the max size in all the files first.
print "Finding max size of documents...";
#find(\&getmax_Size, $dir);
print "\n";
print "Resizing all of the color files...\n";
#find(\&setmax_Size, $dir);
print "\n";

#Move the color files to the BW directory
#print "Moving a derivative copy of color files to BW directory...";
#find(\&move_Files, $colordir);
print "\n";


#Finally, make the GS images into bitonal images...
print "Making the GS images in the BW directory into Bitonal files...\n";
find(\&make_bw2, $dir);

#make the BW directory files 600 dpi files;
print "Making the files in the BW directory 600 DPI...\n";
find(\&make_600, $dir);


print "Done processing " . $indir ."\n";

#Also may need to look at affine to handle skew in the image
##
## end main routines
##################
}


##################
## Sub routines
##
sub getmax_Size
{
    #Determines the maxiumum file size needed in a directory to set all files to that size,
    #stores the values in the global variables
    
       
    if(-f)
    {
        print ".";
     my($fileBaseName, $dirName, $fileExtension)  = fileparse($_, ('\.tif'));
     if (($fileExtension eq ".tif") or ($fileExtension eq ".TIF"))
     {
    
        
        
        #instantiate an object
        my $oimage=Image::Magick->new;
    
        #Open the file         
        $oimage->Read($_);
 
        
        my($current_height, $current_width) = $oimage->Get('height', 'width');
     
        #print "Current height: " . $current_height . " by width: " . $current_width . "\n";
        if($max_height < $current_height)
        {
            #print "New Max height!\n";
            $max_height = $current_height;
            $max_width = $current_width;
        }
    
        #$oimage->write(filename=>$_);
    
        undef $oimage;
     }
    }
}

sub setmax_Size
{
    #Makes all the files passed to this function the same height and width as the max height and width...
    
    if(-f)
    {
        print ".";
        
        my($fileBaseName, $dirName, $fileExtension)  = fileparse($_, ('\.tif'));
        if (($fileExtension eq ".tif") or ($fileExtension eq ".TIF"))
        {
        #instantiate an object
        my $oimage=Image::Magick->new;
    
        #Open the file         
        $oimage->Read($_);
 
        
        my($current_height, $current_width) = $oimage->Get('height', 'width');
        
        if(($max_height != $current_height) or ($max_width != $current_width))
        {
            #print "Resizing file " .$_ ."\n";
            $oimage->Scale(width=>$max_width, height=>$max_height);
            $oimage->write(filename=>$_);
        }
       
        undef $oimage;
        }
    }
}



sub make_600
{
    #makes a file into a 600 dpi file, keeping the aspect ratio constant;
        
    if(-f)
    {
        my($fileBaseName, $dirName, $fileExtension)  = fileparse($_, ('\.tif'));
        if (($fileExtension eq ".tif") or ($fileExtension eq ".TIF"))
        {
        print "Making file " . $_ . " 600 dpi.\n";
        #instantiate an object
        my $oimage=Image::Magick->new;
    
        #Open the file         
        $oimage->Read($_);
    
        my($current_height, $current_width) = $oimage->Get('height', 'width');
    
        #Resample the file
        $oimage->Set(density=>'600x600');
    
        my $new_height = $current_height * 2;
        my $new_width = $current_width * 2;
    
        #$oimage->Resize($new_width .'x'. $new_height);
        $oimage->Scale(width=>$new_width, height=>$new_height);
        
        $oimage->write(filename=>$_);
    
        undef $oimage;
        }
    }
}

sub make_gs
{
    #destructive - takes inbound 600 dpi color images and
    #makes them 300 dpi Greyscale
    
    
    if(-f)
    {
        my($fileBaseName, $dirName, $fileExtension)  = fileparse($_, ('\.tif'));
        if (($fileExtension eq ".tif") or ($fileExtension eq ".TIF"))
        {
        #my $error;
    
        print "Working on file " . $_ . "\n";
        #instantiate an object
        my $oimage=Image::Magick->new;
        
        #Open the file         
        $oimage->Read($_);
      
        $oimage->Despeckle();
        
        $oimage->Enhance();
        $oimage->Dither();
        $oimage->AdaptiveSharpen(radius=>'100.0');
    
        #Set to gs
        $oimage->Quantize(colorspace=>'gray');
    
        #Save the file back out
        $oimage->write(filename=>$_, compression=>'None');
    
        
        undef $oimage;
        }
    }
    
}

sub make_bw
{
    #destructive - takes inbound 600 dpi color images and
    #makes them 600 dpi Bitonal
    
       
    
    if(-f)
    {
        my($fileBaseName, $dirName, $fileExtension)  = fileparse($_, ('\.tif'));
        if (($fileExtension eq ".tif") or ($fileExtension eq ".TIF"))
        {
        #my $error;
    
        print "Working on file " . $_ . "\n";
        #instantiate an object
        my $oimage=Image::Magick->new;
    
        #Open the file         
        $oimage->Read($_);
      
        $oimage->AdaptiveSharpen(radius=>'100.0');
    
        #Set to bitonal on the threshold 220
        $oimage->BlackThreshold('220');
    
        #Save the file back out, setting the compression to G4
        $oimage->write(filename=>$_, compression=>'Group4');
    
            
        undef $oimage;
        }
    }
}

sub make_bw2
{
    #destructive - takes inbound 600 dpi color images and
    #makes them 600 dpi Bitonal
    
       
    
    if(-f)
    {
        my($fileBaseName, $dirName, $fileExtension)  = fileparse($_, ('\.tif'));
        if (($fileExtension eq ".tif") or ($fileExtension eq ".TIF"))
        {
        #my $error;
    
        print "Working on file " . $_ . "\n";
        #instantiate an object
        my $oimage=Image::Magick->new;
    
        #Open the file         
        $oimage->Read($_);
      
        $oimage->AdaptiveSharpen(radius=>'100.0');
    
        $oimage->Quantize(colorspace=>'gray', dither=>'True', 'dither-method'=>'FloydSteinberg', colors=>2);
    
    
        #Save the file back out, setting the compression to G4
        $oimage->write(filename=>$_, compression=>'Group4');
    
            
        undef $oimage;
        }
    }
}

sub make_color
{
    #destructive - takes inbound 600 dpi color images and
    #makes them 300 dpi color
    
    
     
    
    if(-f)
    {
    #my $error;
    
    print "Working on file " . $_ . "\n";
    #instantiate an object
    my $oimage=Image::Magick->new;
    
    #Open the file         
    $oimage->Read($_);
    
    my($orig_h, $orig_w) = $oimage->Get('height', 'width');
    
    print $orig_h . " " . $orig_w . " " . "\n";
    
    #Resample the file
    $oimage->Set(density=>'300x300');
    
    #Resize the file
    $oimage->Resize($orig_w/2 .'x'. $orig_h/2);
    
    #$oimage->AdaptiveSharpen(radius=>'100.0');
    
    
    #Save the file back out
    $oimage->write(filename=>$_, compression=>'None');
    
        
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

##
## end subroutines
##################