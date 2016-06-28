#!/usr/bin/perl -w
use strict;
#7zipunpack.pl
#Traverses a directory tree and uses 7-zip to unpack files.  Unlinks the original ZIP file if it exists
#06.08.11

use Config;
use File::Basename;
use File::Find;
use File::Path qw(make_path remove_tree); #This process of creating paths in Windows works!


my $dir = "I:/ACS";#"Z:/Cengage/Jackie_Film_Scan_Test/REEL_64";#Western_JRL_Med_Sur_18551201";

showDateTime("START");
find(\&unzip, $dir);
showDateTime("END");



sub unzip
{
    #Takes inbound ZIP and unpacks it.  Unlinks original ZIP
    if(!-f){print "Not a file $_...skipping.\n"; return;}
        
    #Then check to see if it is a TIFF file
    my ($filename, undef, $filetype) = fileparse($_, qr{\..*});
    if (!($filetype eq ".zip") and !($filetype eq ".ZIP"))
    { print "Not a ZIP ($_), check extensions and file types.  Skipping.\n";
     return;}
     
    
    print "Reading in file " . $_ . "\n";
    
#C:\Program Files\7-Zip
    my $err = system("7z e $_");
    
       
    warn "$err" if "$err";
    $err =~ /(\d+)/;
    #print $1;
    print 0+$err;
    
    unlink $_;
}

sub showDateTime(@_)
{
    my $initString = "@_";
    
    my ($sec,$min,$hour,$day,$month,$yr19,@rest) =   localtime(time);#####To get the localtime of your system
    print "\n$initString: $day-".++$month. "-".($yr19+1900)."\t"; ####To print date format as expected
    print sprintf("%02d",$hour).":".sprintf("%02d",$min).":".sprintf("%02d",$sec)."\n";###To print the current time
}
