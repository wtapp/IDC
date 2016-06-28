#!/usr/bin/perl -w
use strict;
use DBI;
    
#We will need to define some global parameters that will be necessary later in the example. We will need a variable with our username, password, and DSN name to start with:

    #
    # Database/ODBC declarations and options
    #
my $db_user     = "perl_me";
my $db_pass     = "testing";
my $dsn_name    = 'dbi:ODBC:PERLSQL2';

my $dbh = DBI->connect($dsn_name, $db_user, $db_pass,
                        {RaiseError=> 1, AutoCommit =>0})
    or die("\n\bCONNECT ERROR:\n\nDBI->errstr");

if (! defined($dbh)){ print "ERROR!!!"};

my @rows = ();

my $sql = "SELECT * FROM dbo.a GO";
my $sth = $dbh->prepare($sql)
    or die("\n\nQUERY ERROR:\n\n$dbh->errstr");

my $rv = $sth->execute;

#print $rv;

print "\n";    
while (@rows = $sth->fetchrow_array())
{
    print join(", ", @rows);
    print "\n";
}

$dbh->disconnect;


