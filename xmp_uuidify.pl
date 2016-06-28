#!/usr/bin/env perl

$XMP_UUID_BYTES = [0xBE,0x7A,0xCF,0xCB,
                           0x97,0xA9,0x42,0xE8,
                           0x9C,0x71,0x99,0x94,
                           0x91,0xE3,0xAF,0xAC];
                           
my $XMP_UUID = "";
foreach ( @$XMP_UUID_BYTES ) {
    $XMP_UUID .= chr($_);
}

## my $UUID_BOX = chr(0) . chr(0) . chr(0) . chr(1) . "uuid";

my @filenames = @ARGV;
unless ( scalar @filenames ) {
    while ( my $filename = <> ) {
        chomp $filename;
        push @filenames, $filename;
    }
}

foreach my $filename ( @filenames ) {
    open(IN, $filename) or die "Could not read $filename - $!";
    my $tmp = "";
    while ( my $line = <IN> ) {
        $tmp .= $line;
    }
    close(IN);
    $tmp =~ s!\015\012!\012!gsm;
    $tmp =~ s!\013!\012!gsm;
    
    my @xmldata = split(/\n/, $tmp);
    # my $tmp = shift @xmldata;
    # print "?? $tmp\n";
    # foreach my $ch ( split(//, $tmp) ) {
    #     print ord($ch), "\n";
    # }
    
    if ( $xmldata[0] eq "uuid" ) {
        # we'll add this back later
        shift @xmldata;
    }
    open(OUT, ">$filename.box") or die "Could not write $filename.box - $!";
    print OUT "uuid\n";
    print OUT $XMP_UUID;
    print OUT join("\n", @xmldata);
    close(OUT);
    print STDERR "Processed: $filename\n";
}