#!/usr/bin/perl -w
use strict;

use CAM::PDF;       #to manipulate PDF
use File::Find;     #to find in directory
use File::Basename; #to break filenames up

use Class::CSV;

#if(!-d "c:/temp/wes123")
#{mkdir("c:/temp/wes123", 0777) || print $!;}

my @dirList = (
  "C:/test/2"  
);
my $curr_path;

my $dt = localtime(time);

#Make a new CSV class to save stuff too
my $csv = Class::CSV->new(
    fields=> [qw/path file_name page_count can_modify/],
    line_separator=>"\n"
    #filename=>"test.csv"
);
$csv->add_line(["path", "file_name", "page_count", "can_modify"]);

print getMyTime()."\n";
foreach(@dirList)
{
    print "Working on directory $_ ...\n";
    my $outputfilename = getMyTime()."_output.csv";
    print "$outputfilename\n";
    open FILE,">",$outputfilename or die $!;
    
    find(\&getPDFInfo, $_);
    
    print FILE $csv->string or die $!; #write the contents of CSV to the file
    close(FILE);
    print "done.\n";
}


sub getPDFInfo
{print "here\n";
       
    return if(!-f);#   {return;}
    if(-d)
    {
        $curr_path = $_;        
    }
    
    #Then check to see if it is a PDF file
    my ($name, $path, $ftype) = fileparse($_, qr{\..*});
    return if (!($ftype eq ".PDF") and !($ftype eq ".pdf"));#    {return; }
    
    print "Working on file $_\n"; 
    my $pdf=CAM::PDF->new($_);
    
    my $pageone_tree = $pdf->getPageContentTree(1);
    
    print CAM::PDF::PageText->render($pageone_tree) ."\n";
    
    
    #print $_. " " .$pdf->numPages . "\n";
    $csv->add_line([$path,$_, $pdf->numPages, ($pdf->canModify)]);
    undef $pdf;    
}

sub figureOutPageLayout
{
    #Passes in a pagecontenttree
    
    
}


sub BreakIntoTIFF
{
    
}

sub getMyTime
{
    #Prints the time format nicely so it is readable - operates on localtime
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
    my($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) =
        localtime();
    my $year = 1900 + $yearOffset;
    #my $theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
    my $theTime = sprintf("%04d",$year)."_".sprintf("%02d",$month)."_".sprintf("%02d",$dayOfMonth);
    return $theTime; 
}# end getMyTime

