#!/usr/local/bin/perl
#use LocalLib;
use TiffUtil qw(:standard);
use File::Find;
use Data::Dumper;
use File::Copy::Vigilant;

# Unbuffer output
select((select(STDOUT), $|=1)[0]);
select((select(STDERR), $|=1)[0]);


my $indir = $ARGV[0];
my $outdir = $ARGV[1];

if(! -d $indir){
	print <<EOF;
!! Error input directory "$indir" does no exist or is not a directory !!


	Usage: ./tiff_check.pl INDIR [OUTDIR]
EOF
}

if(defined($outdir) && length($outdir)){
	if(! -e $outdir){
		print "Output directory does not exist.\n\tWould you like me to create it? [y] : ";
		my $res = <STDIN>;
		if($res=~m/^y(?:es)?/i){
			system("mkdir -p $outdir");
		}else{
			exit;
		}
	}elsif(! -d $outdir){
		print "!! Error: output directory exists, but is not a directory !!\n";
		exit;
	}
}

my $error = 0;
my $tiffs = 0;
print "Begining check of tiff files:\n\n";

find(\&check, $ARGV[0]);



print "\n\tFound $error ".(($error == 1) ? 'error' : 'errors')." in $tiffs tiffs\n";

if(length($outdir) && -d $outdir && $error < 1 && $tiffs > 0){
	print "\tBegining Copy Proccess:\n\n";
	&copy_tiffs($indir, $outdir);
}


sub copy_tiffs
{
	my($src, $des) = @_;
	opendir(my $dh, $src);
	my(@contents) = grep(!/^\.\.?$/, readdir($dh));
	closedir($dh);
	foreach my $tif (grep(/\.tiff?$/i, @contents)){
		if(copy_vigilant($src.'/'.$tif, $des.'/'.$tif)){
			print $src.'/'.$tif." copied successfully\n";
		}else{
			print STDERR "!! Error: $src/$tif failed to copy into $des: $!\n";
		}
	}
	foreach my $dir (grep({-d $src.'/'.$_} @contents)){
		if(-d $des.'/'.$dir || mkdir($des.'/'.$dir)){
			copy_tiffs($src.'/'.$dir, $des.'/'.$dir);
		}else{
			print STDERR "!! Error: Failed to create directory $dest/$dir: $!\n";
		}
	}
}



sub check
{
	return unless(m/\.tiff?$/i);
	$tiffs++;
	my $r;
	eval{ $r = ParseTiff($File::Find::name, 2); };
	if($@ || ! defined($r)){
		print STDERR "Error Parsing tiff $File::Find::name\n";
		$error++;
		return;
	}
	if($r->{Pages}[0]{Tags}{SamplesPerPixel}{Value} != 3 || $r->{Pages}[0]{Tags}{BitsPerSample}{Values}[0] != 8){
		print STDERR "!!!! Found bad bit depth in $File::Find::name\n";
		$error++;
	}else{
		print "$File::Find::name looks good\n";
	}
}
