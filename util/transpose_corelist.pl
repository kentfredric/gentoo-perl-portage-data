#!/usr/bin/env perl
# FILENAME: transpose_corelist.pl
# CREATED: 12/23/13 01:09:28 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Transpose contents of Module::CoreList to a Provides map

use strict;
use warnings;
use utf8;


my ($perl_version, $upstream_path ) = @ARGV;

if ( not $perl_version or not $upstream_path ) {
    for ( *STDERR ) {
        $_->print("Expected: $0 <perlversion> <perlreleasestring>\n");
        $_->print("     e.g: $0 5.8.8 NWCLARK/perl-5.8.8.tar.gz\n");
        die "Args not happy";
    }
}

use Module::CoreList;
use Text::CSV_XS;
use Path::Tiny;
use FindBin;
use version;

my $v = version->parse($perl_version);

my $vmap = $Module::CoreList::version{$v->numify};

my $csv = Text::CSV_XS->new({ binary => 1, eol => "$/" });
my $wd = path($FindBin::Bin)->parent;
my $upstreams = $wd->child('upstream-provides');
my $tf = $upstreams->child($upstream_path)->absolute;
my $ntf = $tf->child('upstream-provides.csv');
$tf->mkpath;
print "Writing " . $ntf->relative($wd) . "\n";

my $wfh = $ntf->openw_utf8;
for my $module ( sort keys %{ $vmap } ) {
    my $row = [ $module , '', '' ];
    if ( exists $vmap->{$module} and not defined $vmap->{$module} ) {
        $row->[2] = 'undefined';
    } else { 
        $row->[1] = $vmap->{$module};
    }
    $csv->print($wfh, $row);
}

