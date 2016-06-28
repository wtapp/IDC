#!/usr/bin/perl -w
# dircomp.pl
#
# Compares filenames in two directories, without regard to 3-letter file extension.
# Displays list(s) of the differences.
#
# This was written to show missing transcoded files in one dir compared to another.
#

use strict;
use List::Compare;
use File::Basename;

 
my $resultsFound = 0;

my $fileName;

my $filePath;

my $fileExt;
 
if ( $#ARGV < 1 ) {
&usage;
}
 
my $dir1 = $ARGV[0];
my $dir2 = $ARGV[1];
 
print "\ndircomp directory comparison\n";
print "\ncomparing:\t$dir1\nwith:\t\t$dir2";
 
opendir( DIR1h, $dir1 )
|| die("cannot open directory: $dir1");
opendir( DIR2h, $dir2 )
|| die("cannot open directory: $dir2");
 
my @files1 = readdir(DIR1h);
my @files2 = readdir(DIR2h);

print @files1;
print @files2;

# Remove filename extensions for each list.
foreach my $item (@files1) {
my ( $fileName, $filePath, $fileExt ) = fileparse($item, qr/\.[^.]*/);
$item = $fileName;
}
 
foreach my $item (@files2) {
my ( $fileName, $filePath, $fileExt ) = fileparse($item, qr/\.[^.]*/);
$item = $fileName;
}
 
my $lc = List::Compare->new( \@files1, \@files2 );
 
my @onlyInDir1 = $lc->get_Lonly;
my @onlyInDir2 = $lc->get_Ronly;
 
if ( @onlyInDir1 > 0 ) {
$resultsFound = 1;
print "\n\nonly in $dir1:\n\n";
for my $entry (@onlyInDir1) {
print "$entry\n";
}
}
 
if ( @onlyInDir2 > 0 ) {
$resultsFound = 1;
print "\n\nonly in $dir2:\n\n";
for my $entry (@onlyInDir2) {
print "$entry\n";
}
}
 
if ( !$resultsFound ) {
print "\n\nboth directories are identical.\n";
}
 
sub usage
{
print "usage: dircomp.pl dir1 dir2\n";
exit(0);
}