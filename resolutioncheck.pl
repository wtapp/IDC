#!/usr/bin/perl -w
use strict;
use Image::Magick;
use Image::Magick::Info;
use File::Basename;
use File::Find;
use Cwd 'abs_path';


##
# Resolution checked for TIFF files
#
# Opens each image in a directory and gives the density of the image
# If there is an error then the application prints the location, file name and the density of the image for later correction.
#
# Usage
# perl resolutioncheck.pl <search directory> <logfilename>
##

#Check to see if both params/arguments come in on the command line
if($#ARGV != 2)
{
    print "\nResolution check script\n";
    print "    Usage: perl resolutioncheck.pl <input directory root> <logfilename>\n";
    exit;
}

#set my local variables
my $LEVEL = 1;
my $indir = "nothing";
my $msg = "nothing";
my $logName;
my $resolution;

#get the inbound directory from the command line arguments
$indir = $ARGV[0];
$logName = $ARGV[1];
$resolution = $ARGV[2];

##Check to see if someone called for help
if (($indir eq '-h') or ($indir eq '//?'))
{
    print "\nResolution check script\n";
    print "    Usage: perl resolutioncheck.pl <input directory root> <logfilename> <resolution>\n";
    exit;
}
    
##Give us a default name
if ($logName eq '')
{
    $logName = "C:/temp/resolutioncheck.Log";
}

##Give us a default resolution check
if($resolution eq '')
{
    $resolution = 300;
}

##MAIN
print "Using logfile " . $logName . "\n";


#start my tracking log
openLog($logName);

$msg = "Working on directory $indir, checking for resolution at $resolution x $resolution...\n";
print "$msg";
writeLog(0, $msg);
find(\&checkFile, $indir);
print "\nDone.\n";
writeLog(0, "Done.");


#close out my log
closeLog();
exit;
##END MAIN


#
# Checking functions
#
sub checkFile()
{
    
    #If this is a file
    if(-f)
    {
        #Then check to see if it is a TIFF file
        my (undef, undef, $ftype) = fileparse($_, qr{\..*});
        if (($ftype eq ".tif") or ($ftype eq ".tiff"))
        {
            #We want to get the x & y density of the the image
            #instantiate Image object
            my $image=Image::Magick->new;

            #open the image
            my $myError = $image->Read($_);
            
            # Check to see if we had any errors reading this file, tell the user
            if($myError)
            {
                my $myOutput = "ERROR READING FILE: " . abs_path($_);
                print $myOutput;
                writeLog(0, $myOutput);
            }
            else #We were able to read/open the file normally, so we should continue checking the file...
            {
                #find XxY resolution on the image
                my ($x, $y) = $image->get('x-resolution', 'y-resolution');
                
                #if either the x or the y value is greater or less than 300 dpi,
                if (($x != $resolution) or ($y != $resolution))
                {
                    #then print the file location, name and density of the image out to the output log file.
                    my $myOutput = abs_path($_) . ";" . $x . ";" . $y;
                    print "\n" . $myOutput . "\n";
                    writeLog(0, $myOutput);
                }else #resolution must be correct keep going, make a nice mark in stdout so people know we are still working
                {
                    print ".";
                }
            }
            #be a good citizen, cleanup the base Image::Magick object
            undef $image;
        }
        else #not a TIFF, make a nice mark in stdout so people know we are still working
        {
            print ".";
        }
    }else #Not a file, keep going, make a nice mark in stdout so people know we are still working
    {
        print ".";
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