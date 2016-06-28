#!/usr/bin/perl -w
#Re-lay-JSTOR.pl
#
#   Open all the files in a directory,
#   Deskew all the images in the directory
#   find the biggest file in the directory, skipping the cover
#   Make a template sheet of that size,
#   Lay all the images back into that template
#   Add 1/2 inch border around the new pages
#   Make sure the pages are at least 6.5" x 10"


use strict;
use Config;
use File::Basename;
use File::Copy;
use File::Find;
use Image::Magick;



########################
## Main

#define constants
use constant MIN_PAGE_HEIGHT => 10*300; #minimum height of the image in pixels
use constant MIN_PAGE_WIDTH => 6.5*300; #minimum width of the image in pixels
use constant PERCENT_THRESHOLD => '73%';

#initialize variables
#Get the list of all the disrectories we want to process
my @indir = (
    #"Z:/Tests/JSTOR/009272010_ACADIENSIS_01_01",
    "Z:/Tests/JSTOR/009272010_ACADIENSIS_01_02"
    );


my $colordir;
my $bwdir;
my $max_height=0;
my $max_width=0;
my $max_height_image;
my $max_width_image;
my $max_file_num="000"; #This is a hack to determine the backcover filename
my $min_file_num="001"; #This is the id of the front-cover



# Process the list of directories
foreach(@indir)
{
    #initialize variables
    $colordir = $_ . "/COLOR";
    $bwdir = $_ . "/BITONAL";
    
    #tell the user what we are doing
    print "Working on directory " . $_ . "\n";

    #Clean out the BITONAL Directory - it is probably junk anyhow...
    print "Cleaning ". $bwdir . " of old files...";
    find(\&cleanDir, $bwdir);
    print "done!\n";

    #Figure out what my back cover number is based on the assumption that the last
    #page is the biggest number...
    print "Finding max file num...";  
    find(\&findMaxFileNum, $colordir);
    print "done!\n";
    
    #Walk the color directory and attempt a deskew on images.
    #11.05.10 - Note I need to deskew first to make sure the images are IGO...
    print "Deskewing images...";
    find(\&deskewMe, $colordir);
    print "done!\n";

    #Size all of the color files to be the same size
    #- look for the max size in all the files first.
    print "Finding max size of documents...";
    find(\&getmax_Size, $colordir);
    print "done!\n";

    #- make all the images, except the first image match that size, 
    print "Making the images match that size...";
    find(\&makemax_Size, $colordir);
    print "done!\n";
    
    #- make all images have at least a 1/2" border around them
    print "Adding at least 1/2in border around images...";
    find(\&addborder, $colordir);
    print "done!\n";

    #- make sure all pages are in the center of at least an 8x10 image
    print "Fitting all pages into an 8x10 page...";
    find(\&fitInMinPage_Size, $colordir);
    print "done!\n";

    ###
    ### Now make the image into a bitonal...
    print "Moving Color images to BW directory for sub processing...";
    find(\&move_Files, $colordir);
    print "done!\n";

    print "Mogrifying the Color images to GS in the " .$bwdir." directory...";
    find(\&make_gs, $bwdir);
    print "done!\n";

    #Finally, make the GS images into bitonal images...
    print "Mogrifying the GS images to BITONAL images in the ". $bwdir. " directory...";
    find(\&make_bw, $bwdir);
    print "done!\n";
    
    #make the BW directory files 600 dpi files;
    print "Making the files in the BW directory 600 DPI...";
    find(\&make_600, $bwdir);
    print "done!\n";


    print "All Done.\n";
}

## end main
########################



########################
## SUBS

sub cleanDir
{
    unlink $_;
    
}#end cleanDir

sub move_Files
{
    
    
    #moves a copy of the files from the Color Directory to the BW directory
    #$bwdir is a global variable
    
    if(-f)
    {
        my($fileBaseName, $dirName, $fileExtension)  = fileparse($_, ('\.tif'));
        if (($fileExtension eq ".tif") or ($fileExtension eq ".TIF"))
        {
            
        my $newfile = $bwdir . "/" . $_;
        #print "Copying file " . $_ . " to ". $newfile ."\n";
        print ".";
        copy($_, $newfile) or die "File " . $_ . " cannot be copied";
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
        #print "Making file " . $_ . " 600 dpi.\n";
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
    
    #11.05.10 XWWT modified this to meet new character specifications
    
    if(-f)
    {
        my($fileBaseName, $dirName, $fileExtension)  = fileparse($_, ('\.tif'));
        if (($fileExtension eq ".tif") or ($fileExtension eq ".TIF"))
        {
        #my $error;
    
        print ".";
        #instantiate an object
        my $oimage=Image::Magick->new;
        
        #Open the file         
        $oimage->Read($_);
      
        $oimage->Despeckle();
=POD        
        $oimage->Enhance();
        $oimage->Dither();
=cut          
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
    
        #print "Working on file " . $_ . "\n";
        #instantiate an object
        my $oimage=Image::Magick->new;
    
        #Open the file         
        $oimage->Read($_);
      
        $oimage->AdaptiveSharpen(radius=>'100.0');
    
        #10.6.10 -- Removed this method in place of the one below...    
        #Set to bitonal on the threshold 220
        #$oimage->BlackThreshold('220');
#C:\Temp\Wes Test\acadenisis>convert -colorspace gray -dither FloydSteinberg -unsharp 0x3+1.5+0.0.196 -blur 0x2 -colors 16 -compress Group4 001.tif a.tif
#Made a nice little image that cleaned up some of the issues around the text.  Filled it in of sorts.
        #10.6.10 Revampped method
        ##$oimage->Quantize(colorspace=>'gray',  dither=>'True', 'dither-method'=>'FloydSteinberg',colors=>2);
    
        $oimage->Threshold(threshold=>PERCENT_THRESHOLD);
        
        #Save the file back out, setting the compression to G4
        $oimage->write(filename=>$_, compression=>'Group4');
    
            
        undef $oimage;
        }
    }
}

sub findMaxFileNum
{
    if(!-f){return;}  #get out of this isn't a file...
    my($fileBaseName, $dirName, $fileExtension)  = fileparse($_, ('\.tif'));
    if (($fileExtension eq ".tif") or ($fileExtension eq ".TIF"))
    {
        if ($fileBaseName > $max_file_num)
        {
            $max_file_num = $fileBaseName;    
        }
    }
}#end findMaxFileNum;



sub fitInMinPage_Size
{
    #Make sure all the pages are MIN_PAGE_WIDTH x MIN_PAGE_HEIGHT page size...
    my $direction = "center"; #lay the final image into the center of the composed image
    my $composition = "over"; #over the background image
    
    #Tries to create a blank page and then $direction the image on that page, then
    #write the page back out with the original filename
    
    if(-f)
    {
     
     my $err;
     
     my($fileBaseName, $dirName, $fileExtension)  = fileparse($_, ('\.tif'));
     if (($fileExtension eq ".tif") or ($fileExtension eq ".TIF"))
     {
        #Construct my image object
        my $oimage=Image::Magick->new;
        
        #Open the file into the object
        $oimage->Read($_);
             
        my $new_height;
        my $new_width;
        
        my ($height, $width) = $oimage->Get('height', 'width');
        
        #Check to see if this page meets the minimum standard
        if(($height>= MIN_PAGE_HEIGHT) and ($width>= MIN_PAGE_WIDTH))
        {
            #skip this page
            print "Page ". $fileBaseName . " meets standard...skipping\n";
            return;
        }
        
        #If the page doesn't meet the minimum standard, try to calculate
        #the correct size...
        if($height < MIN_PAGE_HEIGHT)
        {
            $new_height = MIN_PAGE_HEIGHT;    
        }
        else
        {
            $new_height = $height;
        }
        
        if($width < MIN_PAGE_WIDTH)
        {
            $new_width = MIN_PAGE_WIDTH;
        }
        else
        {
            $new_width = $width;
        }
        
        
        ###Mod the image

        #instantiate an object to represent the needed image size
        my $background=Image::Magick->new;
        my $size = $new_width .'x'. $new_height;
        #print "Original height for " . $fileBaseName . " is " . $height."\n";
        #print "Size for ". $fileBaseName . " is ". $size . "\n";

        #Set the image defaults for this image...    
        $err = $background->Set(size=>$size);
        $err = $background->Set(units=>'PixelsPerInch');
        $err = $background->Set(density=>'300x300');
                      
        warn ($err) if $err;
        $err =~ /(\d+)/;
        print $err;
            
        #Make the background white in color
        $background->Read('xc:white');
            
        warn ($err) if $err;
        $err =~ /(\d+)/;
        print $err;
            
        #Compose the original image over new base size image
        # based on the composition and gravity settings 
        $background->Composite(image=>$oimage, compose=>$composition, gravity=>$direction);         
        
        warn ($err) if $err;
        $err =~ /(\d+)/;
        print $err;
            
            
        #11.5.10 XWWT - Overlay of the image is causing the depth to report at 16/8-bit, explicitly call depth to 8
        $background->Set(depth=>8);
            
        #Save the image off
        $background->write(filename=>$_);
                        
        warn ($err) if $err;
        $err =~ /(\d+)/;
        print $err;
        
        #cleanup after ourselves    
        undef $background;       
        
        undef $oimage;
     }
     
    }
    
}#end fitInMinPage_Size

sub addborder
{  
    #figure out max size of images,
    # - already have that in $max_size
    
    #determine what density we are dealing with...
    
    #compose a base image that is 1" bigger all around (top, bottom, left and right)
    
    #lay my image back into that image
    
    my $direction = "center"; #lay the final image into the center of the composed image
    
    #Tries to create a blank page and then $direction the image on that page, then
    #write the page back out with the original filename
    
    if(-f)
    {
     
     my $err;
     
     my($fileBaseName, $dirName, $fileExtension)  = fileparse($_, ('\.tif'));
     if (($fileExtension eq ".tif") or ($fileExtension eq ".TIF"))
     {
        
        ##Skip the file it is the front or back cover...
        if(($fileBaseName eq $min_file_num)
           or($fileBaseName eq $max_file_num))
        {
            #Skip it...
            return;
        }
        
        my $oimage=Image::Magick->new;
        
        #Open the file         
        $oimage->Read($_);
        #print "\n\n".$fileBaseName."!!!\n\n";

        
        my ($height, $width) = $oimage->Get('height', 'width');

        ###Mod the image
        {
            #Add a 1/2" border all the way around the image...            
            my $new_width = $width + (300 * 1);  #density times 1" (MIN_PAGE_WIDTH-$width); #
            my $new_height = $height + (300 * 1); #density times 1" (MIN_PAGE_HEIGHT-$height); #
            
            #instantiate an object
            my $background=Image::Magick->new;
            my $size = $new_width .'x'. $new_height;
            
            
            $err = $background->Set(size=>$size);
            $err = $background->Set(units=>'PixelsPerInch');
            $err = $background->Set(density=>'300x300');
                      
            warn ($err) if $err;
            $err =~ /(\d+)/;
            print $err;
            
            #Make the background white in color
            $background->Read('xc:white');
            
            warn ($err) if $err;
            $err =~ /(\d+)/;
            print $err;
            
            #Compose this image over that image.. in the center, top of that image...
            $background->Composite(image=>$oimage, compose=>'over', gravity=>$direction);         
        
            warn ($err) if $err;
            $err =~ /(\d+)/;
            print $err;
            
            
            #11.5.10 XWWT - Overlay of the image is causing the depth to report at 16/8-bit, explicitly call depth to 8
            $background->Set(depth=>8);
            
            $background->write(filename=>$_);
            
            warn ($err) if $err;
            $err =~ /(\d+)/;
            print $err;
            
            undef $background;       
        }
        
        #cleanup after ourselves
        undef $oimage;
     }
     
    }
}#end addborder

sub makemax_Size
{
    my $direction = "North"; #could also be center
    
    #Tries to create a blank page and then *North* the image on that page, then
    #write the page back out with the original filename
    
    if(-f)
    {
     
     my $err;
     
     my($fileBaseName, $dirName, $fileExtension)  = fileparse($_, ('\.tif'));
     if (($fileExtension eq ".tif") or ($fileExtension eq ".TIF"))
     {
        my $oimage=Image::Magick->new;
        
        #Open the file         
        $oimage->Read($_);
        
        #Determine the max size of the canvas to use...skipping front and back cover        
        if(($fileBaseName eq $min_file_num)
           or($fileBaseName eq $max_file_num))
        {
            #Skip it...
            return;
        }
        else #modify the image to make them all standardized
        {    
            #instantiate an object
            my $background=Image::Magick->new;
            my $size = $max_width .'x'. $max_height;
            
            
            $err = $background->Set(size=>$size);
            $err = $background->Set(units=>'PixelsPerInch');
            $err = $background->Set(density=>'300x300');
                      
            warn ($err) if $err;
            $err =~ /(\d+)/;
            print $err;
            
            #Make the background white in color
            $background->Read('xc:white');
            
            warn ($err) if $err;
            $err =~ /(\d+)/;
            print $err;
            
            #Compose this image over that image.. in the center, top of that image...
            $background->Composite(image=>$oimage, compose=>'over', gravity=>$direction);         
        
            warn ($err) if $err;
            $err =~ /(\d+)/;
            print $err;
            
            
            #11.5.10 XWWT - Overlay of the image is causing the depth to report at 16/8-bit
            $background->Set(depth=>8);
            
            $background->write(filename=>$_);
                        
            warn ($err) if $err;
            $err =~ /(\d+)/;
            print $err;
            
            undef $background;       
        }
        
        #cleanup after ourselves
        undef $oimage;
     }
     
    }
}#end makemax_Size

sub getmax_Size
{
    #Determines the maxiumum file size needed in a directory to set all files to that size,
    #makes sure the numbers derived are divisable by two.
    #stores the values in the global variables
    
       
    if(-f)
    {
        print ".";
     my($fileBaseName, $dirName, $fileExtension)  = fileparse($_, ('\.tif'));
     if (($fileExtension eq ".tif") or ($fileExtension eq ".TIF"))
     {
        if(($fileBaseName eq "001") or ($fileBaseName > 98))
        {
            #Skip it...we don't want to use this for predominate image size
            #print "\nSkipping image ". $fileBaseName." in determining max size";
            return;
        }
        
        #instantiate an object
        my $oimage=Image::Magick->new;
    
        #Open the file         
        $oimage->Read($_);
   
        my($current_height, $current_width) = $oimage->Get('height', 'width');
     
        #Grab the new max height if it is different
        if($max_height < $current_height)
        {
            #print "New Max height!\n";
            $max_height = $current_height;
            
            
            #10.13.10 - Function to make sure the image height & width are even numbers
            if ( ($max_height % 2) != 0)
            {
                $max_height +=1;
            }
            $max_height_image = $fileBaseName;
        }
        
        #Grab the new max width if it is different
        if ($max_width < $current_width)
        {
            $max_width = $current_width;
            
            #10.13.10 - Function to make sure the image height & width are even numbers
            if ( ($max_width % 2) != 0)
            {
                $max_width +=1;
            }   
            $max_width_image = $fileBaseName;
        }
        
        undef $oimage;
     }
    }
}


sub deskewMe()
{
    #Runs the PM deskew on all the images.
    #10.21.10 - XWWT Created
    #10.22.10 - XWWT Added in crop function to tighten geometry.   
    if(-f)
    {
     print ".";
     my($fileBaseName, $dirName, $fileExtension)  = fileparse($_, ('\.tif'));
     if (($fileExtension eq ".tif") or ($fileExtension eq ".TIF"))
     {
        #...skipping front and back cover        
        if(($fileBaseName eq $min_file_num)
           or($fileBaseName eq $max_file_num))
        {
            #Skip it...
            return;
        }
        
        #11.16.10 XWWT - Old method chopped up the images and lost content...
        #system('mogrify -fill white -background white -set option:deskew:auto-crop 20 -deskew 40% '.$_);    

        #instantiate an object
        my $oimage=Image::Magick->new;
    
        #Open the file         
        $oimage->Read($_);
 
        $oimage->Deskew(threshold=>"40%"); #, option=>'deskew:auto-crop 20'           
        $oimage->write(filename=>$_);
    
        undef $oimage;
     }
    }
}#end deskewMe


##
########################