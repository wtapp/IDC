#!/usr/bin/perl -w
use strict;

#pdfcombine.pl
#Takes an starting folder and tries to put a number of PDF files together in the
#directory (Based on sort order) and saves them out to an output directory under the name
use Config;
use File::Basename;
use File::Find;
use File::Path qw(make_path remove_tree); #This process of creating paths in Windows works!
use Image::Magick;
use CAM::PDF;

my $basedir = "i:/ACS/ACS Journals/REWORK";

#Logfile variables
my $logBaseDir = $basedir. "/LOGS";
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


my $dir = $basedir."/work";
my $outdir = $basedir."/output";

my $PDF_counter=0; #number of PDF files processed


#MAIN
openLog($logBaseDir);
showDateTime("START");
find(\&CombineTiff, $dir);
writeLog(IMPORTANT, "Completed $PDF_counter PDF combine functions!\n");
showDateTime("END");
closeLog();



#####################MAIN SUBS#################################################
##
sub CombineTiff
{
    #Takes inbound PDF image, then converts it to TIFF images
    if(!-d){writeLog(WARNING, "Not a directory $_\n");return;}
        
    
    if(($_ =~/755/i) or ($_ =~ /mode/i))
    {
        return; #dummy directory
    }
    
    #make myself an output directory...
    my $err;
    
    #my $tmpdir = $outdir."/".$_;
    
    my $tmpdir = $outdir;
    #if(! -d $tmpdir)
    #{
    #    make_path($tmpdir, mode=>PERMISSIONS) or die "Cannot make the directory $tmpdir!!!\n$!\n";;
    #}
    
    
    #Collect up the names of the files to process in this directory
    #remember the directory name for the PDF file...
    print "Working on directory $_ \n";
      
    
    #list of PDFS
    my @docs;
    
    #Get a listing of all the files in the current directory
    my @files = <$_/*>;
    
    
    #THIS IS A HACK FOR ACS!!!!
    if (@files < 5)
    {
        print "Less than 5 files, quitting\n";
        return;
    }
    
    #build up the list of docs...
    my $file;
    
    #Add the file to a list of PDF files if it is really a PDF
    foreach $file (@files)
    {
        next if($file !~/.pdf/i);  #Make sure we don't add something that is not a PDF
        
        print "Adding $file\n";
        #Make a new PDF called the name of the directory
        my $doc = CAM::PDF->new($file);    
        push @docs,$doc;
    }
    
    if (@docs < 5)
    {
        print "Less than 5 files, quitting\n";
        return;
    }
    $docs[0]->appendPDF($docs[1]);
    undef $docs[1];
    $docs[0]->appendPDF($docs[2]);
    undef $docs[2];
    $docs[0]->appendPDF($docs[3]);
    undef $docs[3];
    $docs[0]->appendPDF($docs[4]);
    undef $docs[4];
    
    
    $docs[0]->cleanoutput($tmpdir."/".$_.".pdf");
    #$finaldoc->cleanoutput($tmpdir."/".$_.".pdf");
    
    warn $err if $err;
    
    
    #delete the old PDF file...
    #unlink $_;
    undef @docs;
    
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