#!/usr/bin/perl -w
##PAO-mini.pl
##Reads in a TIF file, converts to Grayscale, writes back out

use strict;

use Image::Magick;
use Image::Magick::Info;
use Config;
use File::Basename;
use File::Find;
use Time::localtime;

#M:\CSP\Small Projects\AADL

#Set my globals
my $LEVEL = 1;
my $indir = "M:/CSP/PAONEW/PAO SHIPMENT 2/Ready_To_Process/Wes";
my $outdir = $indir; #"c:/temp/OUTPUT/AADL";

#Run my app
print "Running...";


my $msg = "nothing";

#start my tracking log
openLog("c:/temp/PAO.log");


#get the inbound directory from the command line arguments
#$indir = $ARGV[0];
$msg = "Working on directory $indir\n";
print $msg;
writeLog(0, $msg);
find(\&doit, $indir);
$msg = "Done.";
writeLog(0, $msg);
print $msg;


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
            
            $msg = "Working on file " . $name . "\n"; 
            #print $msg;
            writeLog( 0, $msg);
            
            #Open the file         
            $oimage->Read($filename);
            
            my $density = $oimage->Get('density');
            print "Checking file " . $name ."\n";
            if (!($density eq "600x600"))
            {
                print "Making 600 dpi image\n";
                $oimage->Set(density=>'600x600');
                
                $oimage->Write(filename=>$filename, compression=>'Group4');
            }
            
            
            
            #Cleanup memory...
            undef $oimage;
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

