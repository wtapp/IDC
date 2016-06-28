use Filesys::Tree qw/tree/;

my $tree = tree({ 'full' => 1,'max-depth' => 3,'pattern' => qr/\.pl$/ } ,'.');
files($tree);

sub files
{
    my %tree = %{+shift};
    for (keys %tree) {
        if ($tree{$_}->{type} eq 'f'){
            print $_,"\n"
        }elsif ($tree{$_}->{type} eq 'd') {
            files($tree{$_}->{contents});
        }
    }
}

