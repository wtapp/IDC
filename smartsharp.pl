#!/usr/local/bin/perl
# Original Author: Joseph Bylund
# Based on an idea from: Eric Jeschke, gimp guru
# License: cc-by-sa
# please report bugs
use strict;

my $image = @ARGV[0];
my $sharp_radius = 5;
my $sharp_sigma = sqrt($sharp_radius);
my $sharp_amount = 1.2;
my $sharp_threshold = 0.003;
my $a1 = 0;
my $b1 = 0;
my $c1 = 1.2;
my $d1 = -0.1;
my $blur_radius = 3;
my $blur_sigma = sqrt($blur_radius);
my $edge_width = 2;
my $clip_low = "40";#percentage left totally untouched by the sharpening
my $clip_high = "1";#percentage sharpened full strength
my $prefix = "intermediates";
my $outdir = "finals";

$image =~ s/.jpg//;

system("mkdir -p finals");
system("mkdir -p intermediates");

#first make the edges
system("convert $image.jpg -edge $edge_width -colorspace Gray ${prefix}/${image}_inner_edges.jpg
convert $image.jpg -negate -edge $edge_width -colorspace Gray ${prefix}/${image}_outer_edges.jpg
composite -compose plus ${prefix}/${image}_inner_edges.jpg ${prefix}/${image}_outer_edges.jpg ${prefix}/${image}_added_edges.jpg
convert ${prefix}/${image}_added_edges.jpg -gaussian-blur ${blur_radius}x${blur_sigma} ${prefix}/${image}_edges_blurred.jpg
convert ${prefix}/${image}_edges_blurred.jpg -linear-stretch ${clip_low}\%x${clip_high}% ${prefix}/${image}_edges.jpg");
#cp ${image}_edges_blurred.jpg ${image}_edges.jpg
#convert ${image}_edges_blurred.jpg -linear-stretch ${clip_low}\%x${clip_high}% ${image}_edges.jpg
#convert ${image}_edges_blurred.jpg -function Polynomial $a1,$b1,$c1,$d1 ${image}_edges.jpg

#then get the value channel and sharpen it
system("convert $image.jpg -colorspace HSB -channel B -separate ${prefix}/${image}_value.jpg
convert ${prefix}/${image}_value.jpg -unsharp ${sharp_radius}x${sharp_sigma}+${sharp_amount}+${sharp_threshold} ${prefix}/${image}_value_8.jpg
composite ${prefix}/${image}_value_8.jpg ${prefix}/${image}_value.jpg ${prefix}/${image}_edges.jpg ${prefix}/${image}_value_partial_sharp.jpg");

#then get the hue and saturation channels
system("convert $image.jpg -colorspace HSB -channel R -separate ${prefix}/${image}_hue.jpg
convert $image.jpg -colorspace HSB -channel G -separate ${prefix}/${image}_saturation.jpg");

#finally put it all together
system("convert ${prefix}/${image}_hue.jpg -colorspace HSB ${prefix}/${image}_hue.jpg -compose CopyRed -composite ${prefix}/${image}_saturation.jpg -compose CopyGreen -composite ${prefix}/${image}_value_partial_sharp.jpg -compose CopyBlue -composite -colorspace RGB ${outdir}/${image}_smartsharp.jpg");

#clean up workspace
system("/bin/rm ${prefix}/${image}_hue.jpg ${prefix}/${image}_saturation.jpg");
#system("/bin/rm ${image}_inner_edges.jpg ${image}_outer_edges.jpg ${image}_edges_blurred.jpg ${image}_added_edges.jpg ${image}_edges.jpg ${image}_value.jpg ${image}_value_8.jpg ${image}_value_partial_sharp.jpg");
system("cp -t finals ${image}.jpg");

