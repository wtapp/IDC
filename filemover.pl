#!/usr/bin/perl -w
use strict;
use File::Util;

#set my local variables
my $LEVEL = 1;
#my $indir = "//172.31.1.253/FILM_SCAN/Valut Sent";
my $indir="c://temp";
my $msg = "nothing";

#start my tracking log
openLog("c:/temp/APSIIConvert.log");

#get the inbound directory from the command line arguments
#$indir = $ARGV[0];
$msg = "Working on directory $indir\n";
print "$msg";
writeLog(0, $msg);
find(\&moveFile, $indir);
writeLog(0, "Done.");


#close out my log
closeLog();





sub moveFile
{
    if (-d)
    {
        print $_ . " " . scalar localtime File::Util->created($_);
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