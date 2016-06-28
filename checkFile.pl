#!/usr/bin/perl -w
use strict;
use Image::Magick;
use Image::Magick::Info;
use File::Basename;
use File::Find;
use Cwd 'abs_path';

######
## checkFile.pl
##
## Tests to see if a Tiff file has a generic error
## the method assumes that if the image is opened and we check to see if the x/y values are undefined in the image,
## then the image is malformed in someway that ImageMagick cannot handle
##
## Enhances the check by trying to read the image and look for error return codes...






######
#Check to see if both params/arguments come in on the command line
if($#ARGV != 1)
{
    print "\nTIFF File check script\n";
    print "    Usage: perl filetest.pl <input directory root> <logfilename>\n";
    exit;
}

#set my local variables
my $LEVEL = 1;
my $indir = "nothing";
my $msg = "nothing";
my $logName;

#get the inbound directory from the command line arguments
$indir = $ARGV[0];
$logName = $ARGV[1];

##Check to see if someone called for help
if (($indir eq '-h') or ($indir eq '//?'))
{
    print "\nResolution check script\n";
    print "    Usage: perl resolutioncheck.pl <input directory root> <logfilename>\n";
    exit;
}
    
##Give us a default name
if ($logName eq '')
{
    $logName = "C:/temp/filecheck.Log";
}

print "Using logfile " . $logName . "\n";


#start my tracking log
openLog($logName);


$msg = "Working on directory $indir\n";
print "$msg";
writeLog(0, $msg);
$msg = "These are files that were shown to be bad by trying IM\n";
print "$msg";
writeLog(0, $msg);

find(\&checkFile, $indir);
print "\nDone \n";
writeLog(0, "Done.");


#close out my log
closeLog();
exit;



##########
## checkFile
## Looks to see if the file is in good order, called with the current file from find
sub checkFile
{
    #my $ft = File::Type->new();
    
    if(-f)
    {
        my (undef, undef, $ftype) = fileparse($_, qr{\..*});
        
        #Check to see if the file is a TIFF image
        if (($ftype eq ".tif") or ($ftype eq ".tiff"))
        {
            #Load up a perl magick object and test the image
            my $image=Image::Magick->new;

            #open the image
            my $myError = $image->Read($_);
            
            warn "$myError" if "$myError";
            $myError =~ /(\d+)/;
            print $1;
            print 0+$myError;
            #find XxY resolution on the image
            #my ($x, $y) = $image->get('x-resolution', 'y-resolution');
            
            #if(!defined($x) or !defined($y) )
            #{
            #    writeLog(0, abs_path($_));        
            #}
            
            #cleanup
            undef $image;

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