#!/usr/bin/perl -w
use strict;

use File::DiffTree;
use File::Compare;

if (@ARGV != 1) {
    print STDERR "usage: $0 dir1 dir2\n";
    #exit(1);
}

my $dirA = shift;
my $dirB = shift;

sub onlyA { print "Only in $dirA: ", $_[0]->[0], "\n" }

sub onlyB { print "Only in $dirB: ", $_[0]->[0], "\n" }

# This will be called if names match.
# The file size or contents (or mtimes or inodes) could still be different.
sub match {
    my $arr1 = shift;
    my $arr2 = shift;
    my $fn1 = $dirA . $arr1->[0];
    my $fn2 = $dirB . $arr2->[0];
    my $compare = $arr1->[1] <=> $arr2->[1];    # different if sizes differ
    if (! $compare)
    {
        my $retval = File::Compare::compare($fn1, $fn2);
        if ($retval == -1) {
            print STDERR "Problems opening $fn1 or $fn2: $!\n";
            return;
        }
        $compare = $retval;
    }
    if (! $compare) {
        print "Match: ", join('|', @$arr1), "\t", join('|', @$arr2), "\n"
    }
    else {
        print "Different: ", join('|', @$arr1), "\t", join('|', @$arr2), "\n"
    }
}

File::DiffTree::diffTree($dirA, $dirB, {
    Only_A              => \&onlyA,
    Only_B              => \&onlyB,
    Match               => \&match,
    Significant_Fields  => 0,   # just name (not size, mtime or inode)
    Reject              => sub { /(?:~|\.bak|\.tmp)$/ || ! -r _ },
    Fold_Case => ($^O eq 'Win32'),      # if on OS that doesn't care like windoze
});



