#!/usr/bin/perl -w
#wes.pl
use strict;
use Image::Magick;
use Image::Magick::Info;
use Config;
use File::Basename;
use File::Find;

#C:\Temp\PQ>gswin32c -q -dSAFER -dNOPAUSE -dBATCH -r300x300 -dUseCropBox -sOutputFile=GPC0010%05d.tif -sDEVICE=tiffg4 1.pdf

#find(\&doit, "c:/temp/pq");

my $image=Image::Magick->new;

#create a base image
$image->Set(size=>'2550x3300', density=>'300x300');  #8.5x11
$image->ReadImage('xc:white');   #lay in a white background

#read in my nice image to manipulate
my $image2=Image::Magick->new;
#read in the other image
$image2->Read("c:/temp/concourse/sep.jpg");

#open a digital watermark and hide it in the image
my $water=Image::Magick->new;
$water->Read("c:/temp/concourse/napcdigitalwatermark.tif");
$image2->Stegano(image=>$water, offset=>300);
undef $water;

#Put a physical watermark on the image
my $water2=Image::Magick->new;
$water2->Read("c:/temp/concourse/watermark.jpg");

$image2->Composite(image=>$water2, tile=>'True', compose=>'Bumpmap' );
undef $water2;

#Make the image 8.3x10.5
$image2->Resize(width=>2508, height=>3150);

#lay the second image on top of the other
$image->Composite(image=>$image2, gravity=>"North");
undef $image2;

#Lay in a comment in the digital object
$image->Comment("created by:National Archive Publishing Company");

#Write an annotation on the base image
$image->Annotate(font=>'Generic.ttf', gravity=>"South", pointsize=>12, stroke=>'blue', fill=>'blue',
                 text=>"\x{A9}Copyright 2009 SATURDAY EVENING POST SOCIETY\nFor reprints & licensing information go to http://www.saturdayeveningpostcovers.com/");



#write the image back out
$image->Write("c:/temp/concourse/wes.jpg");
undef $image;




sub doit
{

    if(-f)
    {
            #Then check to see if it is a TIFF file
        my (undef, undef, $ftype) = fileparse($_, qr{\..*});
        if (($ftype eq ".tif") or ($ftype eq ".tiff"))
        {
            my $image=Image::Magick->new;
            
            $image->Read($_);
            
            $image->Resize(width=>2250, height=>3300, filter=>'Point');
            $image->Write(filename=>$_);
            undef $image;
            #gm mogrify -resize 2550x3300! -gravity Center -filter Point $_
        }
    }   
}
