#!/usr/bin/perl -w
use strict;
#jpg2tiff.pl
#Takes an starting folder and does a destructive convert of the image from
#PDF to TIFF images using GhostScript
# Specifically coded for ACS project.
#
#PDF 2 Tiff.pl
#  
#6.14.11 XWWT
#6.16.11 XWWT - removed fixMod4 code as the passing function slows this down - moved to in-line

use Config;
use File::Basename;
use File::Find;
use File::Path qw(make_path remove_tree); #This process of creating paths in Windows works!
use Image::Magick;


#Logfile variables
my $logBaseDir = "i:/ACS/LOGS";
my $message; #message for the logfile
use constant REQUIRED=>-1;
use constant ERROR=>0;
use constant WARNING=>1;
use constant MOST=>2;
use constant IMPORTANT=>3;
use constant MESSAGE=>9;
use constant ALL_MSGS=>10;
my $LEVEL = ALL_MSGS; #This is the maximum logging level you want to see!!

use constant PERMISSIONS => 755; #File permissions - ALL


my $dir = "i:/ACS/Chemical and Engineering News";
my $outdir = "i:/ACS/output";

my $PDF_counter=0; #number of PDF files processed
my $TIFF_counter=0; #number of TIFF files that had to be fixed


#MAIN
openLog($logBaseDir);
showDateTime("START");
find(\&PDF2tiff, $dir);
find(\&TIFF_EBEAM_prep, $outdir);
writeLog(IMPORTANT, "Completed $PDF_counter PDF conversions!\n");
writeLog(IMPORTANT, "Completed $TIFF_counter TIFF image fixes!\n");
showDateTime("END");
closeLog();



#####################MAIN SUBS#################################################
##
sub TIFF_EBEAM_prep
#Takes an inbound TIFF image, makes sure the strip is set correct and that it
#has a width evenly divisable by 4
{
    #Then check to see if it is a TIFF file
    if(!-f){ writeLog(WARNING, "Not a file $_...skipping.\n"); return;}
    
    my ($filename, undef, $filetype) = fileparse($_, qr{\..*});
    if ($filetype !~ /tif/i)
    {
        writeLog(WARNING, "Not a TIF ($_), skipping.\n");
        
        return;
    }
    
    
    #instantiate an object
    my $oimage=Image::Magick->new;
    
    writeLog(IMPORTANT, "Reading in file " . $_ . "\n");
    
    #Open the file         
    my $err = $oimage->Read($_);
    
    my $width = $oimage->Get('width');
    my $height = $oimage->Get('height');
    
    #writeLog(IMPORTANT, "$_: Height: $height, Width: $width\n");
    
    #print "$width\n";
    
    #Fix the width so mod 4 = 0
    my $newwidth =  $width +(4-($width%4));
    
    #writeLog(IMPORTANT, "$_: New width: $newwidth\n");
    #print "New width $newwidth\n";
    
    $err = $oimage->Resize(height=>$height, width=>$newwidth);
    
    
    $err=$oimage->Set('tiff:rows-per-strip'=>$height);
    #Write the image back out
    $err=$oimage->Write($_);
    
    #Cleanup memory...
    undef $oimage;
        
    $TIFF_counter++;
}



sub PDF2tiff
{
    #Takes inbound PDF image, then converts it to TIFF images
    if(!-f){writeLog(WARNING, "Not a file $_...skipping.\n"); return;}
        
    #Then check to see if it is a TIFF file
    my ($filename, undef, $filetype) = fileparse($_, qr{\..*});
    
    if ($filetype !~ /pdf/i)
    {
        writeLog(WARNING, "Not a pdf ($_), skipping.\n");
        return;
    }
    
    #make myself an output directory...
    my $err;
    
    if(! -d $outdir)
    {
        make_path($outdir, mode=>PERMISSIONS) or die "Cannot make the directory $outdir!!!\n$!\n";;
    }
    
    #Check to see if I can make a directory with this filename in the
    #Outdir path.  Fail if the folder already exists...
    my $tmpdir = "$outdir./$filename";
    if(! -d $tmpdir)
    {
        make_path($tmpdir, mode=>PERMISSIONS) or die "Cannot make the directory $outdir!!!\n$!\n";;
    }
    else
    {
        writeLog(WARNING, "$tmpdir  already exists.  Skipping file $_!\n");
        return;
    }
    
    #Now use GS to unpackage the file..
    my $errState = system("gswin32c -q -dSAFER -dNOPAUSE -dBATCH -dTextAlphaBits=4 -r300x300 -sOutputFile=$tmpdir/p%04d.tif -sDEVICE=tiffgray $_");
    
    warn $errState if $errState;
    
    
    #delete the old PDF file...
    #unlink $_;
    
    $PDF_counter++;
}
##
##############################Main Subs###########################

##############################LOGGING#############################
##
sub showDateTime
{
    my $initString = "@_";
    
    my ($sec,$min,$hour,$day,$month,$yr19,@rest) =   localtime(time);#####To get the localtime of your system
    print "\n$initString: $day-".++$month. "-".($yr19+1900)."\t"; ####To print date format as expected
    print sprintf("%02d",$hour).":".sprintf("%02d",$min).":".sprintf("%02d",$sec)."\n";###To print the current time
}


#
# Logging functions
#
sub openLog
{
   my $filename = shift;
   my ($sec,$min,$hour,$day,$month,$yr19,@rest) =   localtime(time);#####To get the localtime of your system
   $filename = $filename ."/".($yr19+1900)."-".++$month. "-$day-".sprintf("%02d",$hour).sprintf("%02d",$min).".log"; ####To print date format as expected
   
   open(LOGFILE, '>>', $filename) or die "can't open $filename: $!";
   print LOGFILE "####################################################################\n";
   print LOGFILE "###\n";
   print LOGFILE "###\n";
   print LOGFILE showDateTime("LOG STARTED\n");
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


=POD
sub fixMod4
{
    #takes a number and then returns the corrected number to fix mod4 errors
    #so num %4 = 0
    
    my $num = $_;
    
    my $remainder = $num%4;
    
    my $retnum = $num +(4-$remainder);
    
    return $retnum; 
}
=cut