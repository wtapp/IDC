#!/usr/bin/perl -w
use strict;
use Image::ExifTool  qw(:Public);

my $info = ImageInfo('c:/temp/sim/saturn1.jpg');
   
foreach (sort keys %$info){
    print "$_ => $$info{$_}\n";    
}





