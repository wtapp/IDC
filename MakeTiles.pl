#!/usr/bin/perl
# make tiles from large image.

use Image::Magick;

use subs qw(configure readconfig syntax tileimage ($) version);
#
# get image
#
my $inimage=Image::Magick->new;
my $outimage=Image::Magick->new;
my @files;
my $filename;
my $path;
my $configflag = 0;     #flag indicating that a config file was read
my $imageh;             # image height
my $imagew;             #image width
my $h;
my $w;
my $dpi;
my $rows;
my $cols;
my $newh;
my $neww;
my $i;
my $j;
my $z;
my $y;
my $t;
 ($optionc, $optiond, $optionh, $optionl, $optionv) = 0;

#$filename ="e:/data/test/B.tif";

configure;

if ($path){
    if ($optiond){
        print "path: ".$path , "\n";
    }
    opendir PATH, $path or die $!;
    while ($_ = readdir PATH){
        next if ($_ =~ m/^\./);
        if ($_ =~ m/\./){
            push @files , $_;
        }
    }
    closedir PATH;
}
#print $#files, "\n";
if ($#files < 0){
    print "No files to process! \n";
}
foreach (@files){
    if ($optionl){
        print $_, "\n";
    }else{
        if ($path){
            $filename = $path."/".$_;
        }else{
            $filename = $_;
        }
        if ($optiond){
            print "File: ", $filename,"\n";
        }
        tileimage $filename;
    }
}


undef $inimage;
undef $outimage;

#----------------- Subroutines -----------------#

#------------------ configure ------------------#
sub configure{
    #setup program parameters
    
    my $ok = 0;
    
    #note: these default values may get changed by the following routines
    $imageh = 11;     #default image height
    $imagew = 8.5;    #default image height
    
    #check for config file in current directory
    if (-e "MakeTiles.cfg"){
        readconfig;
        $configflag++;
    }
    #read and process any command line parameters
    $ok = 0;
    foreach (@ARGV){
        if ($_ =~ m/^-/){
            #print $_, $ok;
            if ($_ eq "-c"){
                $optionc++ ;
                $ok++;
            }
            if ($_ eq "-d"){
                $optiond++ ;
                $ok++;
            }
            if ($_ eq "-h"){
                $optionh++ ; #print syntax
                $ok++;
            }
            if ($_ eq "-l"){
                $optionl++ ;
                $ok++;
            }
            if ($_ eq "-v"){
                $optionv++ ; #print version
                $ok++;
            }
        }else{
            #check for file name/path
            if (/\./){
                if (-e $_){
                    @files = ();
                    push @files, $_;
                }else{
                    print "File ".$_." was not found!\n";
                    die;
                }
                
            }else{
                if (-d $_){
                    $path = $_;
                }else{
                    print "Path ".$_." was not found!\n";
                    die;
                }
                
            }    
        }
    }
    
    if ($ok==0){
        print "Invalid argument!\n";
        $optionh++;
    }
    if ($optionh) {
    syntax;
    die;
    }
    if ($optionv) {
    version;
    }
    if ($optiond){
        if ($configflag){
            print "Config file found and processed \n";
        }
    }
}

#----------- readconfig -------------------
sub readconfig {
    #read program parameters from 'MakeTiles.cfg'
    
    open FILE, "MakeTiles.cfg" or die $!;
    while (<FILE>){
        chomp;
        if (m/^file/i) {
            push @files, substr($_,length('file '));
        }
        if (m/^height/i) {
            $imageh = substr($_,length('height '));
        }
        if (m/^path/i) {
            $path = substr($_,length('path '));
        }
        if (m/^width/i) {
            $imagew = substr($_,length('width '));
        }
    }
    close FILE;
}

#-------------------- syntax -----------------
sub syntax {
    #print the program syntax
    
    print "Usage:\n";
    print "  perl maketiles {file/directory name} {options} \n";
    print "    if no file/directory name is given, the files in the current directory \n";
    print "      will be processed, unless a path is specified in the configuation \n";
    print "      file (maketiles.cfg). \n";
    print "    options:\n";
    print "      -d  debug mode (verbose messages) \n";
    print "      -h  print help \n";
    print "      -l  list files but don't process them \n";
    print "      -v  print program version \n";
    print ;
    
}

#--------------- tileimage --------------------#
sub tileimage{
    my $name = shift;
    my $fileout;
    my $r = $inimage->Read($name);
    
    warn("$r")  if $r;
    exit  if $r =~ /^Exception/;
    
    $h = $inimage->Get('rows');
    $w = $inimage->Get('columns');
    $dpi = $inimage->Get('x-resolution');
    
    $newh=$imageh;
    $neww=$imagew;
    if ($imageh <= 40) {
        $newh *= $dpi;   #convert image height to pixels
    }
    if ($imagew <= 30) {
        $neww *= $dpi;   #convert image height to pixels
    }
    if($newh > $h) {$newh = $h};
    if($neww > $w) {$neww = $w};
    $rows = int(($h-1)/$newh) +1;
    $cols = int(($w-1)/$neww) +1;

    print "Splitting image into ".$rows." rows & ".$cols." columns.\n";
    if ($optiond){
        #print "cols:\t", $cols, "\n";
        print "new height:\t", $newh, "\n";
        print "new width:\t", $neww, "\n";
        print "image rows:\t", $inimage->Get('rows'), "\n";
        print "image width:\t", $inimage->Get('width'), "\n";
        print "image resolution:\t",$dpi, "\n";
        print "image rows-per-strip:\t", $inimage->Get('Tiff:rows-per-strip'), "\n";
        print "image depth:\t", $inimage->Get('depth'), "\n";
        
    }
    $i=0;
    while ($i < $rows){
        $j = 0;
        $z = 0;
        if ($rows > 1){
            $z = $i * ($h - $newh)/($rows - 1);
        }
        while ($j < $cols){
            $outimage = $inimage->Clone();
            $y = 0;
            if ($cols >1){
                $y = $j * ($w - $neww)/($cols - 1);
            }
            
            $r = $outimage->Crop($neww."x".$newh."+".$y."+".$z);
            #print $neww."x".$newh."+".$y."+".$z, "\n";
            $t = $j + ( $i * $cols);
            if (length($t) == 1)
            {
                $t = "0".$t;
            }
            $fileout = $name;
            $fileout =~ s/\./-$t\./;
            #print $fileout, "\n";
            $r = $outimage->Write($fileout);
            #print "e:/data/test/x".$t.".tif", "\n";
              warn "$r" if "$r";
              #print $i, $j, "\n";
            $j++;
        }
        $i++;
    }
    @$inimage = ();
    @$outimage = ();
}

#------------------- version --------------------#
sub version {
    #print the program name and version number
    # 1.0 base program
    
    my $v = "1.0";
    print "MakeTiles - version ".$v,"\n";
    
}