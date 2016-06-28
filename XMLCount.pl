#!/usr/bin/perl -w
use strict;
#XMLCount.pl
# Takes directory as commandline parameters and determines the number of XML files in the directory and
# subdirectories.

use Config;
use File::Basename;
use File::Copy;
use File::Find;
use File::Dircmp;


#sub compare($$);

#############################
## Main
#Check to see if both params/arguments come in on the command line
=POD
if($#ARGV != 1)
{
    print "\nXML File check script\n";
    print "    Usage: perl xmlcount.pl <input directory root>\n";
    exit;
}
=cut
#init my variables
my $dir1 = '';
my $count1 = 0;
my $counta=0;

#now read in the cmd line into my variables
#get the inbound directory from the command line arguments
#$dir1 = $ARGV[0];
$dir1 = "X:/AADL_11-2010/From NineStars";


##Check to see if someone called for help
if (($dir1 eq '-h') or ($dir1 eq '//?'))
{
    print "\nTIFF Count check script\n";
    print "    Usage: perl xmlcount.pl <dir1>\n";
    print "    Returns count of TIFF or TIF in each directory.";
    exit;
}

## Grab my directory name from the first command line argument
#$dir1 = collectDirName($ARGV[0]);

#Quick check to see if the file counts match...
$count1 = countDir($dir1);

## Print results
print "--------------------------------------------------\n";
if($count1)
{
    print "\n\nDirectories contain $count1 XML files!\n";

}else
{
    print "\n\nSomething happened and I can't compare!\n"
}
print "--------------------------------------------------\n";

## end MAIN
#############################

#############################
## SUBS
sub countDir
{
    my $dircount = shift;
    $counta = 0;
    
    print "\n\nCounting directory $dircount\n";

    find(\&countDir2, $dircount);
    
    return $counta;   
}#end countDir

sub countDir2
{
    #print "In Count dir 2\n";
    if(-f)
    {
        my($fileBaseName, $dirName, $fileExtension)  = fileparse($_, ('\.xml'));
        if (lc($fileExtension) eq ".xml")
        {
            $counta=$counta+1;            
        }
    }
} #end countDir2

## end SUBS
#############################