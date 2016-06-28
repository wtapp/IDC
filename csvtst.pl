#!/usr/bin/perl -w
use strict;
use Text::CSV;

my $header =   "Batch,Issue_Order",
                "Title,journal-id",
                "Volume,Issue",
                "Root_Folder",
                "Page,Logical_Page_#",
                "HasColorGrayContent?",
                "Art_Correction,Comment";

my $csv = Text::CSV->new()
    or die "Cannot use CSV: " . Text::CSV->error_diag();

my $column = '';
if ($csv->parse($header))
{
    my @field = $csv->$fields;
    my $count = 0;
    for $column(@field)
    {
        print ++$count, " => "
    }
}
my $file = 'c:/test/Test.CSV';


print $status;

#open($csv, "+>", $file) or die $!;

#close $csv;


