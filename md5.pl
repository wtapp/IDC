#!/usr/local/bin/perl
use strict;
use Digest::MD5::File qw(file_md5_hex);
use File::Copy;

my $start = $ARGV[0];
if(! -d $start){
            print <<EOF;
'$start' is not a valid directory.
Usage:
            ./create_md5_manifest.pl DIRECTORY
EOF
}

opendir(my $dh, $start);
my(@subs) = grep(!/\.\.?$/ && -d $start.'/'.$_, readdir($dh));
closedir($dh);

&md5_dir($start.'/'.$_) foreach(@subs);

sub md5_dir
{
my $dir = shift;
if(-f $dir.'/manifest.txt'){
            move($dir.'/manifest.txt', $dir.'/manifest.txt.bkp');
}

open(my $fh, '>', $dir.'/manifest.txt');

opendir(my $dh, $dir);
my(@contents) = grep(!/^\.\.?$/ && ! -d $dir.'/'.$_, readdir($dh));
closedir($dh);

foreach my $file (@contents){
            print $fh "$file: ".file_md5_hex($dir.'/'.$file)."\n";
} 

close($fh);

}