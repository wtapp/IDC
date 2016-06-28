#!/usr/bin/perl -w
##PAO.pl
##Reads in a TIF file, converts to Grayscale, writes back out to same directory
##
## Usage: perl pao.pl <in-bound directory> <threshold> 


use strict;

use Image::Magick;
use Config;
use File::Basename;
use File::Find;
use Time::localtime;

#Set my globals
my $LEVEL = 1; #Level of messaging to the log file
my $indir;  #Inbound directory to read from
my $outdir = $indir; #outbound directory to write to
my $threshold = 190; #threshold setting for B/W conversion

#Offer help if needed
if(($ARGV[0] eq "-h") or ($ARGV[0] eq '-H') or ($ARGV[0] eq '?'))
{
    print "Usage: \n";
    print "perl pao.pl <inbound directory> <threshold> \n";
    print "ex: perl pao.pl e:\\hello 190\n";
}

#Run my app
print "Running...";

my $msg = "nothing";

#start my tracking log
openLog("c:/temp/PAO.log");

#Get the current time
my @timeData = localtime(time);
$msg = join(' ', @timeData);
print $msg ."\n";
writeLog(0, $msg);

#get the inbound directory from the command line arguments
$indir = $ARGV[0];
$threshold = $ARGV[1];

$msg = "Working on directory $indir\n";
print $msg;
writeLog(0, $msg);
find(\&doit, $indir);
$msg = "Done.";
writeLog(0, $msg);
print $msg;

@timeData = localtime(time);
$msg = join(' ', @timeData);
print $msg . "\n";
writeLog(0, $msg);


sub doit
{
    #print "In doit...";
    #check to make sure this is a file...
    if(-d)
    {
        $msg = "In directory " . $_ ."\n";
    }
    elsif(-f)
    {
        #Then check to see if it is a TIFF file
        my ($name, $dir, $ftype) = fileparse($_, qr{\..*});
               
        #if (($ftype eq ".tif") or ($ftype eq ".tiff"))
        {
            #instantiate an object
            my $oimage=Image::Magick->new;
            
            
            #define my image path
            my $filename = $_;
            
            $msg = "Working on file " . $_; 
            print $msg;
            writeLog( 0, $msg);
            print "  .";
            
            #Open the file         
            $oimage->Read($filename);
            print ".";
            #Determine original image height and width
            #my ($width, $height) = $oimage->Get('width', 'height');
            
            #print "Original sizes \n";
            #print "Width = " . $width ."\n";
            #print "Height = " .$height ."\n";
            #$width = $width * 2;
            #$height = $height * 2;
            
            #print "New sizes \n";
            #print "Width = " . $width ."\n";
            #print "Height = " .$height ."\n";
            
                                
            #Convert it to grayscale
            #print "Making grayscale...\n";
            $oimage->Quantize(colorspace=>'gray');
            print ".";
            
            #Resize the image and upsample to 600 dpi
            #$oimage->Resample(density=>'600x600', x=>$height, y=>$width, filter=>'Point');
            $oimage->Set(density=>'600x600');
            print ".";
            #print "Making black & white...\n";
            #$oimage->Threshold();
            $oimage->BlackThreshold($threshold);
            print ".";
            #Write the image back out
            #$msg = "Writing out file " . $filename ."\n";
            
            #print $msg;
            #writeLog(0, $msg);
            
            $oimage->Write(filename=>$filename, compression=>'Group4');
            print ".";
            #Cleanup memory...
            undef $oimage;
            print ".\n";
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
   print LOGFILE "   Log started", scalar(localtime), "\n";
}

sub closeLog
{
   print LOGFILE "   Log closed", scalar(localtime), "\n";
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

