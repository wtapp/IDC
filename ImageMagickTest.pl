#!/usr/bin/perl -w
use strict;

use Image::Magick;
use Image::Magick::Info;
use Config;


#instantiate an object
my $image=Image::Magick->new;
my $filename = "00001.tif";

#my $info=get_info('00001.tif', ("filesize"));
#print $info . "\n";

#open an image
print "Reading in file " . $filename . "\n";
$image->Read($filename);


#look at the histogram of the image

#my $x;
#my $y;
#find XxY resolution on the image
#($x, $y) = $image->get('x-resolution', 'y-resolution');
#print "Image resolution is : " . $x . " x " . $y . "\n";

#$image->Contrast("True");
#$image->Equalize("All");
#$image->ContrastStretch()

#Only use to get more info on the image iself.
#print $image->Identify; #('00001.tif');

#write the resultant image back out
$image->Write('final4.tif');

#display the image
#$image->Write('win:');


Histo();
#cleanup
undef $image;

sub Histo
{
    
    print "Perl V $Config{'version'}. \n";
    print "Image::Magick V $Image::Magick::VERSION. \n";

    my($old_image)	= Image::Magick -> new();
    my($old_name)	= '00001.tif';

    print "Reading old file: $old_name... \n";

    my($result) = $old_image -> Read($old_name);
    die $result if $result;

    print "Read old file: $old_name. \n";
    print "Getting width and height... \n";

    my(@detail) = $old_image -> Get('width', 'height');

    print "Size: $detail[0] x $detail[1]. Pixel count: @{[$detail[0] * $detail[1]]}. \n";
    print "Getting histogram... \n";

    my(@histogram) = $old_image -> Histogram();

    print "Elements in histogram array: @{[scalar @histogram]}. \n";

    my($max_pixel_count)	= 0;
    my($total_pixel_count)	= 0;
    my(@color)		= qw/red green blue/;
    my($bit_count)		= 9;
    my($power_of_2)		= 2 ** $bit_count;

    print "Bit count: $bit_count. Power of 2: $power_of_2. \n";

    my(%color, $count, %count);
    my($opacity);
    my($rgb);

    $count{$_} = [(0) x 256] for (@color);

    while (@histogram)
    {
        ($color{'red'}, $color{'green'}, $color{'blue'}, $opacity, $count) = splice(@histogram, 0, 5);

        $count{$_}[$color{$_} >> $bit_count]	+= $count for (@color);
	$max_pixel_count = $count if ($count > $max_pixel_count);
	$total_pixel_count += $count;

	#print sprintf "Red: 0x%04x. Green: 0x%04x. Blue: 0x%04x. Opacity: 0x%04x. 
        Count: "%10i. \n", $color{'red'}, $color{'green'}, $color{'blue'}, $opacity, $count;
    }

    print "Max pixel count:   $max_pixel_count. \n";
    print "Total pixel count: $total_pixel_count. \n";
    
    my($x);

    #=pod

    print "Counts: \n";
    print 'index', join('  ', map{sprintf '%8s', $_} @color), "\n";

    for $x (0 .. 255)
    {
	print sprintf '%5i', $x;
	print join('  ', map{sprintf '%8i', int($count{$_}[$x] / $power_of_2)} @color);
	print "\n";
    }
}