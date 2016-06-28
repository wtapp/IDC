#!/usr/bin/perl -w
use strict;
###############################################################################
## UofMJP2.pl
## U of M Collections
##
## 03.10.2011
## XWWT
##
## Takes an inbound image (TIFF) and then collects all the data needed
## to match the U of M digital collections spec for XMP data
## then it takes the base image and converts it to a JP2 file using
## kdu_compress.  Once that is complete, then it collects the image and the XMP
## data and writes it back to the base image using EXIF tool
###############################################################################


use Cwd;
use File::Basename;
use File::Find;
use File::Path qw(make_path remove_tree); #This process of creating paths in Windows works!
use File::Util;
use Image::Info qw(image_info dim);
use Image::Magick;
use IO::File;
use Time::Piece::ISO;

use constant PERMISSIONS => 755;
use constant ROOTFILEEXT1 => ".tif";
use constant ROOTFILEEXT2 => ".TIF";

my $indrive = "t:/NRC/Kellogg";
my $outLocation = "T:/Wes/Kellogg_done";
my $currentOutPath;


sub writeXML(%);
sub makeJP2(%);


## Main
print "Making UofM images....\n";
find(\&moveFile, $indrive);
print "Done.\n";



sub moveFile
{
    #checks the inbound to see if it is a directory or a file
    #If it is a directory then it creates a copy of that sub directory
    #into the $outLocation
    #If it is a file it just does the next operation on the file
    if (($_ =~ /System Volume Information/) or ($_ =~ m/\$RECYCLE/))
    {
        print "System file found...skipping.\n";
        return;
    }
    
    if(-d)
    {
        if (($_ eq ".") or ($_ eq "..") )
        {
            print "Root or previous found, skipping.\n";
            return;
        }
        
        print "Creating a directory $_\n";
        #make the analog path on the $outLocation;
        
        my $endpath = "$outLocation/".substr(getcwd,3)."/$_";
        
        print "$endpath\n";
        
        make_path($endpath);# or die "Could not make $endpath - aborting.\n";
        #, mode => PERMISSIONS
        return;
    }
    
    if(-f)
    {
        workOnFile($_);
    }
    
}#end movefile

sub workOnFile
{
    #Make sure this is a file extention type we want to work on
    my($fileName, $dirName, $fileExtension)  = fileparse($_, ('\.tif'));
    
    if (!($fileExtension eq ROOTFILEEXT1) and !($fileExtension eq ROOTFILEEXT2))
        {return;}
        
    print "Working on $_\n";
    
    #fix file names that have spaces in them...
    my $newfilename = $_;
    $newfilename =~ s/ /_/g;
    $newfilename =~ s/,/_/g;
    rename($_, $newfilename) or die "Cannot rename the file $!";
    #print "past rename\n";
    
    
    #Collect the image data and process the file
    collectImageData($newfilename);    
    #print "Current directory ".getcwd."\n";
} #end workOnfile


##end Main




#####################################
## Subroutines

sub collectImageData
{
    ##Takes in bound image and collects 
    my $filename = shift;
    
       
    #instantiate an object
    my $oimage=Image::Magick->new;
    
    #Open the file         
    $oimage->Read($filename);

    #Get the height and width, density
    my($current_height, $current_width, $xres, $yres, $units, $fname) = $oimage->Get('height', 'width', 'x-resolution'
                                                                                      , 'y-resolution', 'units'
                                                                                      , 'filename');
    undef $oimage;    


    #now try to collect the creation date from the identify
    my $f = File::Util->new();
  
    my $dt = gmtime($f->created($filename))."Z";
        
    undef $f;
    #print "$dt\n";
    
    #Grab the balance of the metadata from the other info source
    my $oimage2  = image_info($filename);
    if (my $error = $oimage2->{error})
    {
        die "Can't parse the image: $error\n";
    }

    my $outputjp2 = fileparse($fname, ('\.tif')).".jp2";
    
    my %imagevar = (  'width' => $current_width      #var
                    , 'length' =>$current_height      #var
                    , 'bps' => $oimage2->{BitsPerSample}
                    , 'compression' =>34712   #fixed
                    , 'PI' => 1
                    #, 'Orient'=>($oimage2->{Orientation} eq 'top left' ? 1 : 0)
                    , 'Orient'=>1
                    , 'Spp'=> $oimage2->{SamplesPerPixel}
                    , 'XRes'=>$xres ."/1"
                    , 'YRes'=>$yres ."/1"
                    , 'ResU'=> ($units eq 'pixels / inch' ? 2 : 1)
                    , 'DateTime'=>$dt
                    , 'Artist'=>'Image Data Conversion'
                    , 'Make'=>'NextScan'
                    , 'Model'=>'FlexScan'
                    #, 'Source'=>'2011027'."/".substr(getcwd,9)."/".$outputjp2
                    , 'Source'=>'2011027'."/".$outputjp2
                    , 'JP2Name'=>$outputjp2
                    , 'TIFName'=>$filename
                    , 'BaseName'=>fileparse($fname, ('\.tif')));

    writeXMP(%imagevar);
    undef $oimage2;
    
    makeJP2(%imagevar);
    
} #end collectImageData


sub makeJP2(%)
{
    #Makes the JPEG2000 file from the TIFF
    #Burns the XMP data into the JPEG2000 file
    #Move the JP2 file off to another location
    #Deletes the XMP file to tidy up the solution
    
    my %img_var = @_;
    my $tiffilename = $img_var{'TIFName'};
    my $jp2filename = $img_var{'JP2Name'};
    my $basename = $img_var{'BaseName'};
    
    #Make the JP2 from TIFF
    #my $err = system("kdu_compress -quiet -no_palette -i $tiffilename Clayers=8 Corder=RLCP -o \"$jp2filename\" -slope 51492 -jp2_space sRGB Clevels=2");
    my $err = system("kdu_compress -quiet -no_palette -i $tiffilename Clayers=8 Corder=RLCP -o \"$jp2filename\" -slope 51492 Clevels=2");
    
    #Alt method to put XMP in with the JP2 file.  Requires xmp_uuidfy.pl to be run on the xmp first
    #C:\Perl\scripts>kdu_compress -no_palette -i a.tif Clayers=8 Corder=RLCP -o a3.jp2 -slope 51492 -jp2_space sRGB Clevels=2 -jp2_box a.xmp.box
    my $outfilename = $outLocation."/".substr(getcwd,3)."/".$jp2filename;
    #Burn the XMP data into the TIFF
    print "Writing out...$outfilename\n";
    $err = system("exiftool -q -overwrite_original -tagsfromfile \"$basename.xmp\" \"$jp2filename\"");
    
    rename($jp2filename, $outfilename);
    
    #Clean up the XMP file
    unlink("$basename.xmp");
    
    unlink $jp2filename;    
  
    

}#end makeJP2

sub writeXMP(%)
{
    my %img_var = @_;
    
    my $output = new IO::File(">$img_var{'BaseName'}.xmp");
    
    print $output "<?xpacket begin='' id='W5M0MpCehiHzreSzNTczkc9d'?>\n";
    print $output "<x:xmpmeta xmlns:x='adobe:ns:meta/'>\n";
    print $output "<rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdfsyntax-ns#'>\n";
    print $output "<rdf:Description rdf:about=''xmlns:tiff='http://ns.adobe.com/tiff/1.0/'>\n";
    print $output "<tiff:ImageWidth>$img_var{'width'}</tiff:ImageWidth>\n";
    print $output "<tiff:ImageLength>$img_var{'length'}</tiff:ImageLength>\n";
    print $output "<tiff:BitsPerSample>$img_var{'bps'}</tiff:BitsPerSample>\n";
    print $output "<tiff:Compression>$img_var{'compression'}</tiff:Compression>\n";
    print $output "<tiff:PhotometricInterpretation>$img_var{'PI'}</tiff:PhotometricInterpretation>\n";
    print $output "<tiff:Orientation>$img_var{'Orient'}</tiff:Orientation>\n";
    print $output "<tiff:SamplesPerPixel>$img_var{'Spp'}</tiff:SamplesPerPixel>\n";
    print $output "<tiff:XResolution>$img_var{'XRes'}</tiff:XResolution>\n";
    print $output "<tiff:YResolution>$img_var{'YRes'}</tiff:YResolution>\n";
    print $output "<tiff:ResolutionUnit>$img_var{'ResU'}</tiff:ResolutionUnit>\n";
    print $output "<tiff:DateTime>$img_var{'DateTime'}</tiff:DateTime>\n";
    print $output "<tiff:Artist>$img_var{'Artist'}</tiff:Artist>\n";
    print $output "<tiff:Make>$img_var{'Make'}</tiff:Make>\n";
    print $output "<tiff:Model>$img_var{'Model'}</tiff:Model>\n";
    print $output "</rdf:Description>\n";
    print $output "<rdf:Description rdf:about=''xmlns:dc='http://purl.org/dc/elements/1.1/'>\n";
    print $output "<dc:source>$img_var{'Source'}</dc:source>\n";
    print $output "</rdf:Description>\n";
    print $output "</rdf:RDF>\n";
    print $output "</x:xmpmeta>\n";
    print $output "<?xpacket end='w'?>\n";
    
    $output->close();
    undef $output;    
}#end writeXMP

##
#####################################################