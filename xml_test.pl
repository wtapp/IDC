#!/usr/bin/perl -w
use strict;

use XML::Writer;
use IO::File;

my $output = new IO::File(">output.xml");

my $writer = new XML::Writer (OUTPUT=>$output
                              , NEWLINES=>2);

$writer->startTag("?xpacket"
                  , 'begin' => ' '
                  , 'id'=> 'W5M0MpCehiHzreSzNTczkc9d');
$writer->startTag("x:xmpmeta");
$writer->startTag("rdf:RDF"
                  , 'xmlns:rdf'=>"http://www.w3.org/1999/02/22-rdfsyntax-ns#");
$writer->startTag("rdf:Description"
                  , 'rdf:about'=>"xmlns:tiff='http://ns.adobe.com/tiff/1.0/'");
$writer->startTag("tiff:ImageWidth");
$writer->endTag("tiff:ImageWidth");
$writer->characters("123456");
$writer->endTag("rdf:Description");

$writer->startTag("rdf:Description"
                  , 'rdf:about'=>"'xmlns:dc='http://purl.org/dc/elements/1.1/'");
$writer->startTag("dc:source");
$writer->characters("2011027"); #may also need to add the filename here
$writer->endTag("dc:source");
$writer->endTag("rdf:Description");

$writer->endTag("rdf:RDF");

$writer->endTag("x:xmpmeta");
$writer->endTag("?xpacket"
                , 'end'=>'w');
$writer->end();
$output->close();

undef $output;


=POD
<?xpacket begin='' id='W5M0MpCehiHzreSzNTczkc9d'?>
<x:xmpmeta xmlns:x='adobe:ns:meta/'>
<rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdfsyntax-ns#'>
<rdf:Description 
rdf:about=''xmlns:tiff='http://ns.adobe.com/tiff/1.0/'>
<tiff:ImageWidth>2359</tiff:ImageWidth>
<tiff:ImageLength>3229</tiff:ImageLength>
<tiff:BitsPerSample>8</tiff:BitsPerSample>
<tiff:Compression>34712</tiff:Compression>
<tiff:PhotometricInterpretation>1</tiff:PhotometricInt
erpretation>
<tiff:Orientation>1</tiff:Orientation>
<tiff:SamplesPerPixel>1</tiff:SamplesPerPixel>
<tiff:XResolution>600/1</tiff:XResolution>
<tiff:YResolution>600/1</tiff:YResolution>
<tiff:ResolutionUnit>2</tiff:ResolutionUnit>
<tiff:DateTime>2007-01-03 00:00:00+08:00</tiff:DateTime>
<tiff:Artist>University of Michigan – Digital Conversion 
Unit</tiff:Artist>
<tiff:Make>Zeutschel</tiff:Make>
<tiff:Model>7000</tiff:Model>
</rdf:Description>
<rdf:Description 
rdf:about=''xmlns:dc='http://purl.org/dc/elements/1.1/'>
<dc:source>12345.0002/00000021.jp2</dc:source>
</rdf:Description>
</rdf:RDF>
</x:xmpmeta>
<?xpacket end='w'?>
=cut
