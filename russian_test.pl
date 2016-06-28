#!/usr/bin/perl -w
# Makes files for Russian project smaller through a resize function.
#Also forces the images to be no bigger than 5MB

use strict;

use Config;
use File::Basename;
use File::Find;
use File::Path qw(make_path remove_tree); #This process of creating paths in Windows works!
use Image::Magick;


showDateTime("START");
find(\&resize, "Z:/Russia/Effort");
showDateTime("END");



sub resize
{
    #Takes inbound TIFF image, then converts it to a QUAL quality JPEG
    if(!-f){print "Not a file $_...skipping.\n"; return;}
        
    #Then check to see if it is a TIFF file
    my ($filename, undef, $filetype) = fileparse($_, qr{\..*});
    if (!($filetype eq ".JPG") and !($filetype eq ".jpg"))
    { print "Not a JPEG ($_), check extensions and file types.  Skipping.\n";
     return;}
    
    my $err;
    
    #instantiate an object
    my $oimage=Image::Magick->new;
    
    #print "Reading in file " . $_ . "\n";
    
    #Open the file         
    my $x = $oimage->Read($_);
    
    #get the image dimensions
    my ($height, $width) = $oimage->Get('height', 'width');
    
    #print "Original height and width ($height x $width)\n";
    $height *= .8;
    $width *= .8;
    #print "New height and width ($height x $width)\n";
    
    $err = $oimage->Resize(height=>$height, width=>$width);
    warn "$err" if "$err";
    $err =~ /(\d+)/;
    #print $1;
    print 0+$err;
    
    $err=$oimage->Set('jpeg:extent'=>'5000kb');
        
    #Write the image back out
    $err=$oimage->Write($_);
    
    warn "$err" if "$err";
    $err =~ /(\d+)/;
    #print $1;
    print 0+$err;
    
    #Cleanup memory...
    undef $oimage;
}

sub showDateTime
{
    my $initString = "@_";
    
    my ($sec,$min,$hour,$day,$month,$yr19,@rest) =   localtime(time);#####To get the localtime of your system
    print "\n$initString: $day-".++$month. "-".($yr19+1900)."\t"; ####To print date format as expected
    print sprintf("%02d",$hour).":".sprintf("%02d",$min).":".sprintf("%02d",$sec)."\n";###To print the current time
}
