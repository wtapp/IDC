#!/usr/bin/perl -w
##Splitter1.plSPlit images
## INPUT: Soft-copy scanned in-bound TIFF images
## OUTPUT: Crops page to fixed width, crops edges, splits into two pages enhances text 
## Non-destructive

##12.23.11 Fork from CSPS

use strict;

use Config;
use File::Basename;
use File::Find;
use File::Copy;
use Net::Domain qw (hostname hostfqdn hostdomain);

use File::Path qw(make_path remove_tree); #This process of creating paths in Windows works!
use Image::Magick;

use Scalar::Util qw(looks_like_number);

#Processing constant
use constant PERMISSIONS => 755; #File permissions - ALL

#function predefinitions
sub showDateTime($);  
  

#my global variables
my @indir;

my $min_filename;
my $max_filename;

#Processing directories
my $base = "C:/AirCargo_Test"; #changed bc UNC paths were failing in File::
my $baseindir = $base."/IN";
my $baseoutdir = $base."/OUT";
my $outdir; #Defined based on subdir and baseindir  

my $page_number;
my $max_height;
my $max_width;



#Logfile variables
my $logBaseDir = $base."/LOGS";
my $message; #message for the logfile
use constant REQUIRED=>-1;
use constant WARNING=>1;
use constant ERROR=>0;
use constant MOST=>1;
use constant MESSAGE=>2;
use constant ALL_MSGS=>10;
my $LEVEL = MOST; #This is the maximum logging level you want to see!!


my $goImage; #Main current working image...kept as global to ensure memory not corrupted


####################
# MAIN
#
#Run my app...
print "Running...";
openLog($logBaseDir);

my $err = outterloop();

print "Done.";
closeLog();
#
# end MAIN
#####################



#####################
# Subs
#
sub outterloop
{
    my $tmpdir;

    #build list of directories to process
    writeLog(REQUIRED,"Building list of directories to process...\n");
    find(\&collect_directory_names, $baseindir);
    writeLog(REQUIRED,"Done building list of directories to process.\n");
 
    foreach $tmpdir(@indir)
    {
        ProcDir($tmpdir);
    }
    
}#end outterloop

sub collect_directory_names
{
    ## 4.27.2011 - Works
    
    ##This is a bit of a hack.  Just gets a list of directory names
    ##from the passed directory, runs recursively and pushes the next
    ##name onto the list.  This WILL fail if there are subdirectories
    ##under the main directory.

    if (($_ =~ /System Volume Information/) or ($_ =~ m/\$RECYCLE/))
    {
        writeLog(WARNING,"System file found...skipping.");
        return;
    }
    
    if (($_ eq ".") or ($_ eq "..") )
    {
            writeLog(WARNING, "Root or previous found, skipping.\n");
            return;
    }
    
    if(-d)
    {    
        push(@indir, $_);
        writeLog(REQUIRED, "$_.\n");
    }
}#end collect_directory_names


sub ProcDir ($)
{
    my $tmpdir = "@_";
    
    writeLog(REQUIRED,"Working on ". $tmpdir ."\n");
    
    my $dir = $baseindir."/".$tmpdir;
   
    #check to make sure the output directory doesn't exist
    $outdir = $baseoutdir."/".$tmpdir;

    #Make the destination directory, or die if you cannot do that
    make_path($outdir, mode=>PERMISSIONS) or warn "Cannot make the directory $outdir!!!\n$!\n";
 
    writeLog(REQUIRED,"INPUT directory $dir \n");
    writeLog(REQUIRED,"OUTPUT directory $outdir \n");
    
    find(\&proc_image, $dir);
    
    writeLog(REQUIRED,"Done processing files in $tmpdir.\n");
    
    return 1;
}#end ProcDir

sub proc_image
{   
    #Takes inbound image, then crops the image based on geometry
    
    if(!-f)
    {
        writeLog(WARNING,"Not a file $_...skipping.\n");
        return;
    }
    
    #Then check to see if it is a TIFF/JPG file
    my ($filename, undef, $fileType) = fileparse($_, qr{\..*});
    if (($fileType !~ /tif/i) and ($fileType !~ /tiff/i))
    {
        writeLog(WARNING, "Not a recognized file type ($_), check extensions and file types.  Skipping.\n");
        return;
    }
  
    writeLog(MESSAGE, "Reading in file " . $_ . "...\n");
    
    #Open the file/Read in the base image
    $goImage = Image::Magick->new;
    my $rc = $goImage->Read($_);
    
    if($rc)
    {
        my ($errno) = $rc =~/(\d+)/;
        ($errno >= 400) ? die "Fatal error in Read: $rc!!\n" : warn "Error: $rc\n";
    }
    
    #Crop the images, cropper knows to look for specific years...
    writeLog(MESSAGE, "crop...");
    crop_image($_);
    

    #Fix and center the image on a white background
    writeLog(MESSAGE, "center...");
    fixandCenter($_);
    
    
    #split the image
    writeLog(MESSAGE, "split...");
    splitit($_);   
    
     
    #Cleanup memory...
    undef $goImage;
    writeLog(MESSAGE, "done.\n");
}#proc_image



sub splitit
{
    #Enhances the global image by overlaying b/w copy of the image
 
    my ($filename, undef, $fileType) = fileparse($_, qr{\..*});
    
    my $outImage=Image::Magick->new;
    
    #Grab the right image...
    $outImage = $goImage->Clone();
    
    my $bgcolor = $goImage->Get('background');
   # print "\nBackground color $bgcolor\n";
    
    my $n = $outdir."/".$filename."_R".$fileType;
    my ($width, $height) = $outImage->Get('width', 'height');
    
    $width = $width /2 ;
    
    my $geo_string = $width."x".$height."+0+0";
    
    $outImage->Crop(geometry=>$geo_string, gravity=>"East");
    writeLog(MESSAGE, "write...");
    #Write the image back out
    $outImage->Trim();
    
    $outImage->Set(background=>'(0,0,0)');
    $outImage->Trim();
    $outImage->Set(background=>$bgcolor);
    
    $outImage->Deskew(threshold=>"40%");
    my $rc=$outImage->Write($n);
    
    if($rc)
    {
        my ($errno) = $rc =~/(\d+)/;
        ($errno >= 400) ? die "Fatal error in Write: $rc!!\n" : warn "Error: $rc\n";
    }
    
    
    #Grab the left image...
    $outImage = $goImage->Clone();
    
    $n = $outdir."/".$filename."_L".$fileType;
    ($width, $height) = $outImage->Get('width', 'height');
    
    $width = $width /2 ;
    
    $geo_string = $width."x".$height."+0+0";
    
    $outImage->Crop(geometry=>$geo_string, gravity=>"West");
    writeLog(MESSAGE, "write...");
    $outImage->Trim();
    
    $outImage->Set(background=>'(0,0,0)');
    $outImage->Trim();
    $outImage->Set(background=>$bgcolor);
    
    $outImage->Deskew(threshold=>"40%");
    #Write the image back out
    $rc=$outImage->Write($n);
    
    if($rc)
    {
        my ($errno) = $rc =~/(\d+)/;
        ($errno >= 400) ? die "Fatal error in Write: $rc!!\n" : warn "Error: $rc\n";
    }
    
}#end splitit


sub crop_image
{   
    #$TRIM_FACTOR = 25; #35 #38; #1/8"
    
    
    my ($width, $height) = $goImage->Get('width', 'height');
    
       
  #######CHANGE THIS STRING TO CHANGE THE CROP IMAGE
  #WIDTHxHEIGHT+x-offset+y-offset
    my $geometry_string = "4300x2700+250+830";
    
    my $rc = $goImage->Crop(geometry=>$geometry_string);#, gravity=>'Center');
    
    if($rc)
    {
        my ($errno) = $rc =~/(\d+)/;
        ($errno >= 400) ? die "Fatal error in Read: $rc!!\n" : warn "Error: $rc\n";
    }

}#end crop_image



sub fixandCenter()
{
    #Tries to create a blank page and then center the image on that page, then
    #write the page back out with the original filename
    
    #The intent to to create equal margins on the page...
    
    my ($curr_height, $curr_width) = $goImage->Get('height', 'width');
    
    ##Change values here to make the overall modification to the page sizes            
    $max_height = $curr_height + 300;#* 1.15;
    $max_width = $curr_width + 300;#* 1.15;

    #instantiate an object
    my $background=Image::Magick->new;
    my $size = $max_width .'x'. $max_height;
        
    my $rc = $background->Set(size=>$size);
    if($rc)
    {
        my ($errno) = $rc =~/(\d+)/;
        ($errno >= 400) ? die "Fatal error in Read: $rc!!\n" : warn "Error: $rc\n";
    }
    
    $rc = $background->Set(units=>'PixelsPerInch');
    if($rc)
    {
        my ($errno) = $rc =~/(\d+)/;
        ($errno >= 400) ? die "Fatal error in Read: $rc!!\n" : warn "Error: $rc\n";
    }
    
    $rc = $background->Set(density=>'300x300');
    if($rc)
    {
        my ($errno) = $rc =~/(\d+)/;
        ($errno >= 400) ? die "Fatal error in Read: $rc!!\n" : warn "Error: $rc\n";
    }

    $rc = $background->Read('xc:white');
    if($rc)
    {
        my ($errno) = $rc =~/(\d+)/;
        ($errno >= 400) ? die "Fatal error in Read: $rc!!\n" : warn "Error: $rc\n";
    }
       
    
    $rc = $background->Composite(image=>$goImage, compose=>'over', gravity=>'center');
    if($rc)
    {
        my ($errno) = $rc =~/(\d+)/;
        ($errno >= 400) ? die "Fatal error in Read: $rc!!\n" : warn "Error: $rc\n";
    }
   
    #11.5.10 XWWT - Overlay of the image is causing the depth to report at 16/8-bit
    #Force the depth to be 8 for backward compatibility
    $rc = $background->Set(depth=>8);
    if($rc)
    {
        my ($errno) = $rc =~/(\d+)/;
        ($errno >= 400) ? die "Fatal error in Read: $rc!!\n" : warn "Error: $rc\n";
    }

    #Copy the background image back to the global image for remainder of process
    $goImage = $background->Clone();
}#end fixandCenter

#
# end Subs
###########################

###########################
#
# Date time functions
#


sub showDateTime($)
{
    my $initString = "@_";
    
    my ($sec,$min,$hour,$day,$month,$yr19,@rest) =   localtime(time);#####To get the localtime of your system
    #writeLog(REQUIRED, "\n$initString: $day-".++$month. "-".($yr19+1900)."\t"); ####To print date format as expected
    #writeLog(REQUIRED, sprintf("%02d",$hour).":".sprintf("%02d",$min).":".sprintf("%02d",$sec)."\n");###To print the current time
    my $str = "$initString: $day-".++$month. "-".($yr19+1900)."\t".sprintf("%02d",$hour).":".sprintf("%02d",$min).":".sprintf("%02d",$sec)."\n";
    
    return $str;
}
#
# end Date time functions
##########################

##########################
# Logging functions
#
sub openLog
{
    #print $0."\n";
    
   # use Net::Domain qw (hostname hostfqdn hostdomain);
   #  
   my $hostname = `hostname`;

   my $filename = shift;
   my ($sec,$min,$hour,$day,$month,$yr19,@rest) =   localtime(time);#####To get the localtime of your system
   $filename = $filename ."/".($yr19+1900)."-".++$month. "-$day-".sprintf("%02d",$hour).sprintf("%02d",$min).".log"; ####To print date format as expected
   
   open(LOGFILE, '>>', $filename) or die "can't open $filename for logging: $!";
   print LOGFILE "####################################################################\n";
   print LOGFILE "###\n";
   print LOGFILE "###\n";
   print LOGFILE showDateTime("LOG STARTED");
   print LOGFILE "From computer $hostname\n";
   print LOGFILE "Running script $0.\n";
   
}

sub closeLog
{
   print LOGFILE showDateTime("LOG CLOSED");
   print LOGFILE "###\n";
   print LOGFILE "###\n";
   print LOGFILE "####################################################################\n";
   close LOGFILE;
}

sub writeLog
{
   my ($level, $message) = @_;
   print LOGFILE "   $message" if $level < $LEVEL;
   print $message; #Print the message out to the console too
}

sub logLevel
{
   my $level = shift;
   $LEVEL = $level if $level = ~ /^\d+$/;
}
#
# end Logging functions
###########################