#!/usr/bin/perl -w
use strict;

#Tries to create a checksum for files.
use Digest::MD5;
use File::Basename;
use File::Find;
use Class::CSV;


my @dirlst =
(
"Z:/Tests/colorado/Spec/Master/i7349835x"
,"Z:/Tests/colorado/Spec/Master/i73336427"
);


my $outdir="Z:/Tests/colorado/Spec/Master"; #Defined based on subdir and baseindir
my $outputfilename = $outdir . "/MD5Checksum.csv";
    
#Run my app
print "Running...";

open CSVFILE,">",$outputfilename or die $!;

    #Make a new CSV class to save stuff too
my $csv = Class::CSV->new(
    fields=> [qw/file_name HEX_MD5_Checksum/],
    line_separator=>"\n"
    #filename=>"test.csv"
);

$csv->add_line(["File_Name", "HEX_MD5_Checksum", ]);

my $err = ProcDir();

print CSVFILE $csv->string; #write the contents of CSV to the file
close(CSVFILE);
print "Done.";


sub ProcDir
{


    my $indir;
    
    foreach $indir(@dirlst)
    {
        find(\&checksum_proc, $indir);
    }
}

sub checksum_proc
{
    #Error check - make sure this is an image file we can process
    print $_ ."\n";
    if(!-f){return;}
        
    #Then check to see if it is a TIFF file
    my ($filename, undef, $filetype) = fileparse($_, qr{\..*});
    if (!($filetype eq ".tif") and !($filetype eq ".tiff"))
    { return;}
    
    #Open the file and figure out the checksum
    open(FILE, $_) or die "Cannot open file $_, $!\n";
    binmode(FILE);
    
    my $ctx = Digest::MD5->new;
    
    $ctx->addfile(*FILE);    
    
    
    close(FILE);
    my $str = $ctx->hexdigest;
    print "Digest is $str \n";
    $csv->add_line([$_, $str]);
    
    undef $ctx;
    
}