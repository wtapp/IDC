#!/usr/bin/perl -w
##Liberty400.pl

## INPUT: Soft-copy scanned in-bound  images at 300 DPI
## OUTPUT: Converted to JPG images at 400 DPI
## Non-destructive uses IN/OUT dir

##8.2.11 XWWT - Created

use strict;

use Config;
use File::Basename;
use File::Find;
#use File::Copy;

use File::Path qw(make_path remove_tree); #This process of creating paths in Windows works!
use Image::Magick;

#use Scalar::Util qw(looks_like_number);


   #Processing constant
use constant PERMISSIONS => 755; #File permissions - ALL
use constant QUAL => 100; #image quality

#function predefinitions
sub showDateTime($);  
  

#my global variables
my @indir;
 

   #Processing directories
my $base = "T:/Liberty/400DPI"; #changed bc UNC paths were failing in File::
my $baseindir = $base."/2011_09_01";
my $baseoutdir = $base."/2011_09_01_OUT";
my $outdir; #Defined based on subdir and baseindir

#T:\Liberty\400 DPI\2011_8_16

use constant DPI=>400;   

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
my $MACHINE_NAME ="WES";


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
        writeLog(WARNING,"System file found...skipping.\n");
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
    }
}#end collect_directory_names


sub ProcDir ($)
{
    my $tmpdir = "@_";
    
    writeLog(REQUIRED,"Working on ". $tmpdir ."\n");
    
    my $dir = $baseindir."/".$tmpdir;
       
    
    #check to make sure the output directory doesn't exist
    $outdir = $baseoutdir."/".$tmpdir;
    
    if (-d $outdir)
    {
        writeLog(WARNING,"Output directory ($outdir) already exists, skipping $tmpdir!!!!\n");
        return 0;
    }
        
    #Make the output directory name
    $outdir = $baseoutdir."/".$tmpdir;  

    #Make the destination directory, or die if you cannot do that
    make_path($outdir, mode=>PERMISSIONS) or die "Cannot make the directory $outdir!!!\n$!\n";
        
    writeLog(REQUIRED,"INPUT directory ". $dir ."\n");
    writeLog(REQUIRED,"OUTPUT directory " . $outdir ."\n");
    find(\&ThunkDPI, $dir);
    
    writeLog(REQUIRED,"Done processing files in $tmpdir.\n");
    
    return 1;
}#end ProcDir

sub ThunkDPI
{
    #Takes inbound image, then thunks the DPI up to the DPI constant value
    if(!-f){writeLog(WARNING,"Not a file $_...skipping.\n");return;}
        
    #Then check to see if it is a TIFF file
    my ($filename, undef, $fileType) = fileparse($_, qr{\..*});
    if ($fileType !~ /jpg/i)
    {
        writeLog(WARNING, "Not a recognized file type ($_), check extensions and file types.  Skipping.\n");
        return;
    }
            
    my $err;
    
    my $n = $outdir."/".$filename.".jpg";
    
=POD    
    #instantiate an object
    my $oimage=Image::Magick->new;
    
    writeLog(MESSAGE, "Reading in file " . $_ . "\n");
    
    #Open the file         
    my $x = $oimage->Read($_);
    
    #$oimage->Set(quality=>QUAL);
    
    
    
    #get the image dimensions
    my ($height, $width) = $oimage->Get('height', 'width');
    
    
    
    #Write the image back out
    $err=$oimage->Write($n);
=cut    
    
    
    my $errState = system("convert $_ -resample 400x400 $n");
    
    
    warn "$err" if "$errState";
    #$err =~ /(\d+)/;
    #print $1;
    #print 0+$err;
    
    
    #Cleanup memory...
    #undef $oimage;
}#tiff2jpg

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
    writeLog(REQUIRED, "\n$initString: $day-".++$month. "-".($yr19+1900)."\t"); ####To print date format as expected
    writeLog(REQUIRED, sprintf("%02d",$hour).":".sprintf("%02d",$min).":".sprintf("%02d",$sec)."\n");###To print the current time
}
#
# end Date time functions
##########################

##########################
# Logging functions
#
sub openLog
{
   my $filename = shift;
   my ($sec,$min,$hour,$day,$month,$yr19,@rest) =   localtime(time);#####To get the localtime of your system
   $filename = $filename ."/".($yr19+1900)."-".++$month. "-$day-".sprintf("%02d",$hour).sprintf("%02d",$min).".log"; ####To print date format as expected
   
   open(LOGFILE, '>>', $filename) or die "can't open $filename for logging: $!";
   print LOGFILE "####################################################################\n";
   print LOGFILE "###\n";
   print LOGFILE "###\n";
   print LOGFILE showDateTime("LOG STARTED\n");
   print LOGFILE "$MACHINE_NAME.\n";
}

sub closeLog
{
   print LOGFILE showDateTime("LOG CLOSED\n");
   print LOGFILE "###\n";
   print LOGFILE "###\n";
   print LOGFILE "####################################################################\n";
   close LOGFILE;
}

sub writeLog
{
   my ($level, $message) = @_;
   print LOGFILE "   $message\n" if $level < $LEVEL;
   print $message."\n"; #Print the message out to the console too
}

sub logLevel
{
   my $level = shift;
   $LEVEL = $level if $level = ~ /^\d+$/;
}
#
# end Logging functions
###########################
