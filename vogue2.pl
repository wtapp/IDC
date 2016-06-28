#!/usr/bin/perl -w
##Vogue.pl
##Hack for Vogue processing since IM is dead
#gm convert %1 -resample 400x400 002.tif
#image_to_j2k -i 002.tif -o 002.jp2
#j2k_to_image -i 002.jp2 -o 003.tif -OutFor TIF
#gm mogrify -density 400x400 003.tif
#gm convert 003.tif -resample 300x300 004.tif

use strict;

#use Image::Magick;
#use Image::Magick::Info;
use Config;
use File::Basename;
use File::Find;


#Set my globals
#my $indir = "f:/3/source";
#my $outdir = "f:/3/result/";
#set my local variables
my $LEVEL = 1;
my $indir = "nothing";
my $outdir = "nothing";
my $tempdir = "nothing";
my $msg = "nothing";
my $logName;

#get the inbound directory from the command line arguments
$indir = $ARGV[0];
$outdir = $ARGV[1];
$logName = $ARGV[2];
$tempdir="C:\\TEMP\\WES";

##Check to see if someone called for help
if (($indir eq '-h') or ($indir eq '//?'))
{
    print "\nVogue script\n";
    print "    Usage: perl vogue.pl <input directory root> <output directory root> <logfilename>\n";
    exit;
}
    
##Give us a default name
if ($logName eq '')
{
    $logName = "C:/temp/vogue.Log";
}

openLog($logName);

#Run my app
print ("Working...\n");

find(\&doit, $indir);

writeLog(0,"Done.");
closeLog();

sub doit
{
    

    if(-f)
    {
	#Parse the file name        
        my ($name, undef, $ftype) = fileparse($_, qr{\..*});

print $ftype . "\n";

	#Then check to see if it is a TIFF file
        if (($ftype eq ".TIF") or ($ftype eq ".tiff"))
        {
            print "Here...";
            #define my image path
            my $filename = basename($_, ".tif");
            
            
            print "Reading in file " . $filename . "\n";

	my $errState = system("gm convert $_ -resample 400x400 $tempdir\\$filename.tif");
writeLog(0, "ERROR converting $indir..." . $errState) if $errState != 0;
	$errState = system("image_to_j2k -i $tempdir\\$filename.tif -o $tempdir\\$filename.jp2");
writeLog(0, "ERROR converting $indir..." . $errState) if $errState != 0;
	$errState = system("j2k_to_image -i $tempdir\\$filename.jp2 -o $tempdir\\$filename.a.tif -OutFor TIF");
writeLog(0, "ERROR converting $indir..." . $errState) if $errState != 0;
	$errState = system("gm mogrify -density 400x400 -compress None $tempdir\\$filename.a.tif");
writeLog(0, "ERROR converting $indir..." . $errState) if $errState != 0;
	$errState = system("gm convert $tempdir\\$filename.a.tif -resample 300x300 $tempdir\\$filename.tif");
writeLog(0, "ERROR converting $indir..." . $errState) if $errState != 0;
	$errState = system("gm convert -quality 100 -compress JPEG $tempdir\\$filename.tif $outdir\\$filename.jpg");
writeLog(0, "ERROR converting $indir..." . $errState) if $errState != 0;	
       
       $errState = system("del /Q $tempdir\\*.*");
writeLog(0, "ERROR converting $indir..." . $errState) if $errState != 0;
        }
    }
}



#
# Logging functions
#
sub openLog
{
   my $filename = shift;
   open(LOGFILE, '>>', $filename) or die "can't open $filename: $!";
   print LOGFILE "####################################################################\n";
   print LOGFILE "###\n";
   print LOGFILE "###\n";
   print LOGFILE "   Log started ", scalar(localtime), "\n";
}

sub closeLog
{
   print LOGFILE "   Log closed ", scalar(localtime), "\n";
   print LOGFILE "###\n";
   print LOGFILE "###\n";
   print LOGFILE "####################################################################\n";
   close LOGFILE;
}

sub writeLog
{
   my ($level, $message) = @_;
   print LOGFILE "   $message\n" if $level < $LEVEL;
}

sub logLevel
{
   my $level = shift;
   $LEVEL = $level if $level = ~ /^\d+$/;
}