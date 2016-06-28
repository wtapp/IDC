#!/usr/bin/perl -w
#Findedge.pl
use strict;
use Config;
use File::Basename;
use File::Copy;
use File::Find;
use Image::Magick;

#tweaking variables
my $border_edge = 00; #assumes this is in pixels;
my $fuzz = .005;  #amount of fuzziness in a border;
my $margin_buffer = 20;

#initialize variables

my $filename = "C:/Users/wtapp/Desktop/JSTOR/004bw.tif";

my $oimg = Image::Magick->new();

$oimg->Read($filename);

my ($max_width, $max_height) = $oimg->Get('width', 'height');

print "Max image dimensions ". $max_width . " x " . $max_height ."\n";



#find top margin, looks for greatest change in total color
my $x;
my $y;

####ROWS
my @row_count = 0;
print "\nSumming rows...";

for($y=0; $y<$max_height; $y++)
{
    for($x=0; $x < $max_width; $x++)
    {
        my @color = $oimg->GetPixel(x=>$x, y=>$y);
        
        
        $row_count[$y] += color_sum(@color);
    }
}

####COLUMNS
my @column_count = 0;
print "\nSumming columns...";

for($x=0; $x < $max_width; $x++)
{
    for($y=0; $y<$max_height; $y++)    
    {
        my @color = $oimg->GetPixel(x=>$x, y=>$y);
        
        
        $column_count[$x] += color_sum(@color);
    }
}




#FIND TOP MARGIN
#Now look for point of variation...
my $top_margin = find_first_change_inc(@row_count);

#Modify to back up some...
$top_margin -= $margin_buffer;

#FIND BOTTOM MARGIN
#Now look for point of variation...
my $bottom_margin = find_first_change_dec(@row_count);

#Modify to back up some...
$bottom_margin += $margin_buffer;

#FIND LEFT MARGIN
#Now look for point of variation...
my $left_margin = find_first_change_inc(@column_count);

#Modify to back up some...
$left_margin -= $margin_buffer;

#FIND RIGHT MARGIN
#Now look for point of variation...
my $right_margin = find_first_change_dec(@column_count);

#Modify junk to back up some...
$right_margin += $margin_buffer;



##DRAW THE TEST IMAGE
my $top_margin2 = "0," . $top_margin. "  ". $max_width. ",".$top_margin;
$oimg->Draw(primitive=>'line', stroke=>'black', strokewidth=>'1.0', points=>$top_margin2);

my $bottom_margin2 = "0," . $bottom_margin. "  ". $max_width. ",".$bottom_margin;
$oimg->Draw(primitive=>'line', stroke=>'black', strokewidth=>'1.0', points=>$bottom_margin2);

my $left_margin2 =  $left_margin. ",0". "  ". $left_margin . ",".$max_height;
$oimg->Draw(primitive=>'line', stroke=>'black', strokewidth=>'1.0', points=>$left_margin2);

my $right_margin2 = $right_margin. ",0". "  ". $right_margin . ",".$max_height;
$oimg->Draw(primitive=>'line', stroke=>'black', strokewidth=>'1.0', points=>$right_margin2);


#Write out my test image
$oimg->Write("C:/Users/wtapp/Desktop/JSTOR/004bw-2.tif");

####NOW CROP The image

my $y_pos = $bottom_margin-$top_margin;
my $x_pos = $right_margin-$left_margin;

my $geo = $x_pos ."x".$y_pos."+".$left_margin."+".$top_margin;
print $geo . "\n";
$oimg->Crop(geometry=>$geo);
$oimg->Write("C:/Users/wtapp/Desktop/JSTOR/004bw-3.tif");

undef $oimg;
print "\nDone.\n";
##
#########################################


##########################################
## SUBS
sub find_first_change_inc
{
    my @img_array = @_;
    my $found = 0;
    my $max = @img_array;
    my $x = 0;
    my $edge = 0;
    
    do
    {
            if(($img_array[$x] * (1-$fuzz)) > $img_array[$x+1])
            {
                $found = 1;
                $edge = $x;
            }
            
            $x++;
    }
    while (!$found and ($x < $max));
    
    return $edge;
}

sub find_first_change_dec
{
    my @img_array = @_;
    my $found = 0;
    my $x = @img_array;
    my $edge = 0;
    
    do
    {
            if(($img_array[$x] * (1-$fuzz)) > $img_array[$x-1])
            {
                $found = 1;
                $edge = $x;
            }
            
            $x--;
    }
    while (!$found and ($x > 1));
    
    return $edge;
}

sub color_sum
#takes a color array and returns the sum of all the colors in the array (R+G+B)
{
    my @color = @_;
    
    my $sum = $color[0];
    $sum += $color[1];
    $sum += $color[2];
    $sum *= 255;


    return $sum;
}

sub find_max
#returns the biggest number and the position in the array it was in
{
    my @array = @_;
    my $max = 0;
    my $size = @array;
    my $position;
    my $value;
    
    #print "May array is ".$size."\n";
    
    for(my $x = 0; $x<$size; $x++)
    {
        #print "Row ". $x . " = ". $array[$x]."\n";
        
        if($array[$x] > $max)
        {
            $position = $x;
            $value = $array[$x];
        }
    }
    return($position, $value);
}