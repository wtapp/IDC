#!/usr/bin/perl -w
use strict;
###############################################################################
## UofMJP2_2012_04_13.pl
## U of M Collections
##
## 02.07.2012 - root
## XWWT
##
## Takes an inbound image (TIFF)
## Determines if the file should stay as a TIFF or be converted to JP2
## and then collects all the data needed
## to match the U of M digital collections spec for XMP data
## then it takes the base image and converts it to a JP2 file using
## kdu_compress.  Once that is complete, then it collects the image and the XMP
## data and writes it back to the base image using EXIF tool

## 04.13.2012 XWWT - Add in UUID code from UofM, changed method to create UUID in the JP2
##                   files so they are stored in the JP2 using kdu_compress instead of ExifTool
## 03.11.2012 XWWT - Fixed compression saving of the files.
## 03.02.2012 XWWT - Fixed some of the issues around exif fields
## 02.07.2012 XWWT - Added in functionality to read scan.csv in each cwd for the scanner info
## 02.01.2012 XWWT - Added MD5 checksum functions
## 01.26.2012 XWWT - Added functions to separate TIFF and JP2 processing
## 07.12.2011 XWWT
##          Cleaned up some of the code...
##          Fixed the pathing creation for output directory
##          Added code to check the TIFF files to make them uncompressed
## 01.26.2012 XWWT - Branch from previous code
##

###############################################################################

###All Tiff get metadata (see doc)
### 600 DPI bitonal stays TIFF
### 400 dpi color convert to Jp2
### Need to make sure checksum is run on deck
### Folder name is the book barcode
### stick with in/out process
### Make sure TIFF images have ext of TIF, not TIFF
### Come up with process to handle make/model

### Report on any TIFF that is not 400 or 600 DPI
###8 digit filename check
###14 digit bar code (folder name)
### Sequential number for file names

### - For cengage stuff make sure you figure out what to do with DPI in JP2 files so they show up in IrfanView

use Cwd;
use File::Basename;
use File::Find;
use File::Path qw(make_path remove_tree); #This process of creating paths in Windows works!
use File::Util;
use Image::Info qw(image_info dim);
use Image::Magick;
#use Image::ExifTool;

use IO::File;
use Time::Piece::ISO;
use Digest::MD5;
use DBI; #For CSV read interface

use constant PERMISSIONS => 755;


#C:\Temp\UofM_Thesis\QC_COMPLETE
my $base = "C:/Temp/UofM_Thesis"; #"Q:/BENTLY_HISTORICAL/PROCESSING";
my $baseindir = $base."/IN/Rescan";#"c:/temp/jp2tiff/in";
my $baseoutdir = $base."/OUT";
my $currentOutPath;
my $outdir;

#Logfile variables
my $logBaseDir = $base."/LOGS";
my $message; #message for the logfile
use constant REQUIRED=>-1;
use constant WARNING=>1;
use constant ERROR=>0;
use constant MOST=>1;
use constant MESSAGE=>2;
use constant ALL_MSGS=>10;
my $LEVEL = MOST; #This is the maximum logging level you want to see!!

my @indir;


sub writeXML(%);
sub makeJP2(%);
sub makeTIFF(%);
sub showDateTime($);  

####################
# MAIN
#
#Run my app...
print "Running...";
openLog($logBaseDir);

my $err = outterloop();

print "Done.";
closeLog();
#
# end MAIN
#####################


sub outterloop
{
    my $tmpdir;

    #build list of directories to process
    writeLog(REQUIRED,"Building list of directories to process...\n");
    find(\&collect_directory_names, $baseindir);
    writeLog(REQUIRED,"Done building list of directories to process.\n");
 
    foreach $tmpdir(@indir)
    {
        ProcDir($tmpdir);
    }
    
}#end outterloop

sub collect_directory_names
{
    ## 4.27.2011 - Works
    
    ##This is a bit of a hack.  Just gets a list of directory names
    ##from the passed directory, runs recursively and pushes the next
    ##name onto the list.  This WILL fail if there are subdirectories
    ##under the main directory.

    if (($_ =~ /System Volume Information/) or ($_ =~ m/\$RECYCLE/))
    {
        writeLog(WARNING,"System file found...skipping.");
        return;
    }
    
    if (($_ eq ".") or ($_ eq "..") )
    {
            writeLog(WARNING, "Root or previous found, skipping.\n");
            return;
    }
    
    if(-d)
    {    
        push(@indir, $_);
        writeLog(REQUIRED, "$_.\n");
    }
}#end collect_directory_names


sub ProcDir ($)
{
    my $tmpdir = "@_";
    
    writeLog(REQUIRED,"Working on ". $tmpdir ."\n");
    
    my $dir = $baseindir."/".$tmpdir;

    #check to make sure the output directory doesn't exist
    $outdir = $baseoutdir."/".$tmpdir;

    #Make the destination directory, or die if you cannot do that
    make_path($outdir, mode=>PERMISSIONS) or warn "Cannot make the directory $outdir!!!\n$!\n";
            
    writeLog(REQUIRED,"INPUT directory $dir \n");
    writeLog(REQUIRED,"OUTPUT directory $outdir \n");
        
    find(\&workOnFile, $dir);
    
    makeMD5($outdir);
    
    writeLog(REQUIRED,"Done processing files in $tmpdir.\n");
    
    return 1;
}#end ProcDir

sub makeMD5($)
{
    my $curdir = shift;
    my $tmpMD5;
    writeLog(REQUIRED,"Creating MD5 Checksum on $curdir\n");
    open(MD5FILE, ">".$curdir."/checksum.md5");
    
    #print md5sum($_)."\n";
    print $curdir."\n";
    find(\&md5sum, $curdir);
    
    close(MD5FILE);
}


sub md5sum
{
    
    #my $file = shift;
    my $digest = "";
    if(!-f)
    {
      return; #not a file
    }
  
  #Make sure this is a file extention type we want to work on
    my $fileType  = substr($_, length($_)-3);
    
    print "$fileType\n";
    
    if ($fileType eq "md5")
    {
        writeLog(WARNING,"MD5 file $_...skipping.\n");
        return;
    }
  
  print "Working on MD5 for $_\n";
  eval{
    open(FILE, $_) or die "Can't find file $_\n";
    my $ctx = Digest::MD5->new;
    $ctx->addfile(*FILE);
    $digest = $ctx->hexdigest;
    print MD5FILE $digest."  ".$_."\n";
    close(FILE);
  };
  if($@){
    print $@;
    return "";
  }
  writeLog(REQUIRED, "$digest  $_.\n");
}

sub workOnFile
{
    if(!-f)
    {
        writeLog(WARNING,"Not a file $_...skipping.\n");
        return;
    }
    
    #Make sure this is a file extention type we want to work on
    my($fileName, $dirName, $fileType)  = fileparse($_, ('\.tif'));
    
    
    if ($fileType !~ /tif/i)
    {
        writeLog(WARNING,"Not a TIFF file $_...skipping.\n");
        return;
    }
        
    print "Working on $_\n";
  
    #07.12.2011 - Fix files to be uncompressed
    my $errState = system("mogrify -compress None $_");
    #print "Completed mogrify to remove compression\n";
   
    #fix file names that have spaces in them...
    my $newfilename = $_;
#    $newfilename =~ s/ /_/g;
#    $newfilename =~ s/,/_/g;
#   rename($_, $newfilename) or die "Cannot rename the file $!";
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
    my $original_file = cwd."/".$filename;
    #Open the file         
    $oimage->Read($filename);
    #print $filename;

    #Get the height and width, density
    my($current_height, $current_width, $xres, $yres, $units, $fname, $compress) = $oimage->Get('height', 'width', 'x-resolution'
                                                                                      , 'y-resolution', 'units'
                                                                                      , 'filename', 'compression');
    
    print "Compression $compress.\n";
    #Check to make sure the tiff file has a correct resolution
    if($xres != $yres)
    {
        writeLog(WARNING,"Image X/Y $_ resolution is not equal $xres x $yres...skipping.\n");
        return;
    }
    
    if(($xres != 600) and ($xres !=400))
    {
        writeLog(WARNING,"Image $_ resolution is $xres x $yres...skipping.\n");
        return;
    }

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
    
    my $src = substr(getcwd, length($baseindir)+1)."/".$fname;#substr($outputjp2, 0, length($outputjp2));#-4);
    #print "Source: $src\n";
    #$src =~ s/$baseoutdir//g;
     
    #print $src."\n";
    
    #Find the scanner info from the CSV...
    my $dbh = DBI->connect("DBI:CSV:f_dir=.;csv_eol=\n;");

    #$dbh->{'csv_tables'}->{'scanner'}={'file' => 'C:/Temp/UofM_Thesis/QC_COMPLETE_2/39015003283465/scan.csv'};
    #03.02.2012 xwwt fix to allow file name change.
    my $namepart = substr(getcwd, length($baseindir)+1);
    my $a = substr($namepart, 0 , -4);  ###Allows for a the last 4 digits of the barcode directory name being in the directory
    $namepart = substr($namepart, length($a));
    my $scan_csv = "scan".$namepart.".csv";
#print $scan_csv ."\n";

unless( -e $scan_csv)
{
    die "$scan_csv does not exist in ". getcwd."\nSTOP\n";
}

# Associate our csv file with the table name 'Scanner'    
    $dbh->{'csv_tables'}->{'scanner'}={'file' => $scan_csv};
    
    
    #{'C:/Temp/UofM_Thesis/QC_COMPLETE_2/39015003283465/scan.csv'} = {'col_names' => ["id", "make", "model", "software"]};# 
    
    # Output the name and contact field from each row
    my $file_num = fileparse($fname, ('\.tif'));
    
    
    my $sth = $dbh->prepare("SELECT * FROM scanner WHERE My_ID LIKE $file_num"); #'%199'");
    $sth->execute();

    
#    if ( $sth->err )
#    {
#        die "ERROR in DB execution! return code: $sth->err  error msg:  $sth->errstr \n";
#    }
    
    #while (my $row = $sth->fetchrow_hashref) {
    my $row = $sth->fetchrow_hashref;
    my $make;
    my $model;
    
    if (defined $row)# we got some row value back...
    {

           $make = $row->{make};
           $model = $row->{model};

    }
    else #try the default value
    {
        $file_num = "00000000";
        my $sth = $dbh->prepare("SELECT * FROM scanner WHERE My_ID LIKE $file_num"); #'%199'");
        $sth->execute();
        
        if ( $sth->err )
        {
            die "ERROR in DB execution! return code: $sth->err  error msg:  $sth->errstr \n";
        }
        
        my $row = $sth->fetchrow_hashref;
        if (!defined $row)
        {
            die "ERROR: Could not find any record to store make and model info to the images.\n";
        }
        $make = $row->{make};
        $model = $row->{model};
        
    }
    
    unless($make)
    {
        die "Make is not set for $filename\n";
    }

    unless($model)
    {
        die "Model is not set for $filename\n";
    }


    #check to make sure the x & y DPI are the same - if not die...
    if($xres != $yres)
    {
        die "X and Y Resolutions are not equal for $filename\n";
    }
    
    if($xres==600)
    {
        #Process this as a TIFF Image...
        
        my %imagevar = (  'width' => $current_width      #var
                    , 'length' =>$current_height      #var
                    , 'bps' => $oimage2->{BitsPerSample}
                    , 'compression' =>4   #fixed
                    , 'PI' => 1
                    #, 'Orient'=>($oimage2->{Orientation} eq 'top left' ? 1 : 0)
                    , 'Orient'=>1
                    , 'Spp'=> $oimage2->{SamplesPerPixel}
                    , 'XRes'=>$xres ."/1"
                    , 'YRes'=>$yres ."/1"
                    , 'ResU'=> ($units eq 'pixels / inch' ? 2 : 1)
                    , 'DateTime'=>$dt
                    , 'Artist'=>'Image Data Conversion'
                    , 'Make'=>$make #'Copibook i2S'
                    , 'Model'=>$model #'CBookHD/600'
                    #, 'Source'=>'2011027'."/".substr(getcwd,9)."/".$outputjp2
                    , 'Source'=>$src
                    , 'JP2Name'=>$outputjp2
                    , 'TIFName'=>$filename
                    , 'BaseName'=>fileparse($fname, ('\.tif'))
                    , 'OriginalFile'=>$filename
                    , 'helper'=>$original_file
                    , 'DocumentName'=>substr(getcwd, length($baseindir)+1)."/".$filename);

        writeXMP(%imagevar);

        makeTIFF(%imagevar);   
    }
    else
    {
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
                    , 'Make'=>$make #'Copibook i2S'
                    , 'Model'=>$model #'CBookHD/600'
                    #, 'Source'=>'2011027'."/".substr(getcwd,9)."/".$outputjp2
                    , 'Source'=>$src
                    , 'JP2Name'=>$outputjp2
                    , 'TIFName'=>$filename
                    , 'BaseName'=>fileparse($fname, ('\.tif'))
                    , 'OriginalFile'=>$filename
                    , 'helper'=>$original_file
                    , 'DocumentName'=>substr(getcwd, length($baseindir)+1)."/".$outputjp2);

        writeXMP(%imagevar);
        my $xmp_file = fileparse($fname, ('\.tif')).".xmp";      
        xmp_uuidify($xmp_file);
        makeJP2(%imagevar);
    }
    
    undef $oimage2;
    
} #end collectImageData

sub makeTIFF(%)
{
    #Keeps the image as TIFF, copies it off to the correct directory...
    
    my %img_var = @_;
    my $tiffilename = $img_var{'TIFName'};
    my $basename = $img_var{'BaseName'};
    my $oimage=Image::Magick->new;
    
    $oimage->Read($img_var{'helper'});
    print "Reading in $img_var{'helper'}\n";
    
    my $outfilename = $outdir."/".$tiffilename;
    $oimage->Write(filename=>$outfilename, compression=>'Group4');
    
    #Burn the XMP data into the TIFF
    print "Writing out...$outfilename\n";
    $err = system("exiftool -q -overwrite_original -tagsfromfile \"$basename.xmp\" \"$outfilename\"");
    
    if ($? == -1) {
        print "failed to execute: $!\n";
    }
    elsif ($? & 127) {
        printf "child died with signal %d, %s coredump\n",
            ($? & 127),  ($? & 128) ? 'with' : 'without';
    }
    else {
        printf "child exited with value %d\n", $? >> 8;
    }
    
    #print "The new tiff name is $outfilename\n";
    unlink("$basename.xmp");
    undef $oimage;
    
}#end makeTIFF

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
    rename($basename."xmp", $basename."box");
    #my $tst = "!!kdu_compress -quiet -no_palette -i $tiffilename Clayers=8 Corder=RLCP -o \"$jp2filename\" -slope 51492 Clevels=2 -jp2_box \"$basename.box\"!!\n";
    #print $tst;
    
    my $err = system("kdu_compress -quiet -no_palette -i $tiffilename Clayers=8 Corder=RLCP -o \"$jp2filename\" -slope 51492 Clevels=2 -jp2_box \"$basename.xmp\"");
    
    #Alt method to put XMP in with the JP2 file.  Requires xmp_uuidfy.pl to be run on the xmp first
    #C:\Perl\scripts>kdu_compress -no_palette -i a.tif Clayers=8 Corder=RLCP -o a3.jp2 -slope 51492 -jp2_space sRGB Clevels=2 -jp2_box a.xmp.box
    #my $outfilename = $outLocation."/".substr(getcwd,3)."/".$jp2filename;
    
    my $outfilename = $outdir."/".$jp2filename;
    #substr(getcwd, length($indrive))."/$_"
    
    #Burn the XMP data into the TIFF
    #print "Writing out...$outfilename\n";
    #$err = system("exiftool -q -overwrite_original -tagsfromfile \"$basename.xmp\" \"$jp2filename\"");
    
    rename($jp2filename, $outfilename);
    
    #Clean up the XMP file
    unlink("$basename.box");
    
    unlink $jp2filename;    
  
    

}#end makeJP2

sub xmp_uuidify($)
{
    #Shifts the UUID box into a better form for import to JP2 file

    
    my $fname = shift;
#print "Making uuidify of file $fname\n";

    my $XMP_UUID_BYTES = [0xBE,0x7A,0xCF,0xCB,
                           0x97,0xA9,0x42,0xE8,
                           0x9C,0x71,0x99,0x94,
                           0x91,0xE3,0xAF,0xAC];
                           
    my $XMP_UUID = "";
    foreach ( @$XMP_UUID_BYTES ) {
        $XMP_UUID .= chr($_);
    }
   
    open(IN, $fname) or die "Could not read $fname - $!";
    my $tmp = "";
    while ( my $line = <IN> ) {
        $tmp .= $line;
    }
    close(IN);
    $tmp =~ s!\015\012!\012!gsm;
    $tmp =~ s!\013!\012!gsm;
    
    my @xmldata = split(/\n/, $tmp);
    
    if ( $xmldata[0] eq "uuid" ) {
        # we'll add this back later
        shift @xmldata;
    }
    open(OUT, ">$fname") or die "Could not write $fname - $!";
    print OUT "uuid\n";
    print OUT $XMP_UUID;
    print OUT join("\n", @xmldata);
    close(OUT);
    print STDERR "Processed: $fname\n";

} #end xmp_uuidify


#Makes an XMP box to add to a file.
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
    print $output "<tiff:DocumentName>$img_var{'DocumentName'}</tiff:DocumentName>";
    print $output "</rdf:Description>\n";
    
    print $output "<rdf:Description rdf:about=''xmlns:dc='http://purl.org/dc/elements/1.1/'>\n";
    print $output "<dc:source>$img_var{'Source'}</dc:source>\n";
    print $output "</rdf:Description>\n";
    
    print $output "<rdf:Description rdf:about=''xmlns:exif='http://ns.adobe.com/exif/1.0/'>\n";
    #print $output "<exif:UserComment>$img_var{'Artist'}</exif:UserComment>\n";
    print $output "<exif:FocalPlaneXResolution>$img_var{'XRes'}</exif:FocalPlaneXResolution>\n";
    print $output "<exif:FocalPlaneYResolution>$img_var{'YRes'}</exif:FocalPlaneYResolution>\n";
    print $output "<exif:FocalPlaneResolutionUnit>$img_var{'ResU'}</exif:FocalPlaneResolutionUnit>\n";
    print $output "</rdf:Description>\n";
    
    print $output "</rdf:RDF>\n";
    print $output "</x:xmpmeta>\n";
    print $output "<?xpacket end='w'?>\n";
    
    $output->close();
    undef $output;    
}#end writeXMP

##
#####################################################

###########################
#
# Date time functions
#


sub showDateTime($)
{
    my $initString = "@_";
    
    my $a = localtime(time);
   
    $a =~ s/:/_/g;
    $a =~ s/-/_/g;
    my $str = "$initString: $a\n";
    
    return $str;
}
#
# end Date time functions
##########################

##########################
# Logging functions
#
sub openLog
{
    #print $0."\n";
    
   # use Net::Domain qw (hostname hostfqdn hostdomain);
   #  
   my $hostname = `hostname`;

   my $filename = shift;
   #print "AAA".localtime(time)."\n";
   my $a = localtime(time);
   
   $a =~ s/:/_/g;
   $a =~ s/-/_/g;
   print $a;
     
   $filename = $filename."/".$a.".log";
   
   open(LOGFILE, '>>', $filename) or die "can't open $filename for logging: $!";
   print LOGFILE "####################################################################\n";
   print LOGFILE "###\n";
   print LOGFILE "###\n";
   print LOGFILE showDateTime("LOG STARTED");
   print LOGFILE "From computer $hostname\n";
   print LOGFILE "Running script $0.\n";
   
}

sub closeLog
{
   print LOGFILE showDateTime("LOG CLOSED");
   print LOGFILE "###\n";
   print LOGFILE "###\n";
   print LOGFILE "####################################################################\n";
   close LOGFILE;
}

sub writeLog
{
   my ($level, $message) = @_;
   print LOGFILE "   $message" if $level < $LEVEL;
   print $message; #Print the message out to the console too
}

sub logLevel
{
   my $level = shift;
   $LEVEL = $level if $level = ~ /^\d+$/;
}
#
# end Logging functions
###########################

#We did 2 theses books as samples for U of M. The barcode for the 2 books are:
#
#39015003283465
#39015003283366
#
#They are located at  I:\NetworkStorage\IDCDATA01\UofM_THESES\2012082\QC_COMPLETE
#
#All the pages were scanned on Copibook 2 except the last 3 images (00000104, 00000105 and 00000106) of book 39015003283465. Those 3 pages were scanned on the digibook.
#
#Equipment information:
#
#Make: Copibook i2S
#Model: CBookHD/600
#Software Version: HD600 3.6.0(1371)
#
#Make: Digibook i2S
#Model: Suprascan II
#Software version: 6.1.0333