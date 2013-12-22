#!/usr/bin/env perl
# FILENAME: aggregate_upstream_provides.pl
# ABSTRACT: Map upstream-provides/* into top level CSV files

use strict;
use warnings;
use utf8;

use Path::Tiny qw(path);
use FindBin;
use Text::CSV_XS;

my $wd    = path($FindBin::Bin)->parent;
my $gtopl = $wd->child('upstream-provides');

my $it = $gtopl->iterator( { recurse => 1, follow_symlinks => 0 } );
my @all;

while ( my $file = $it->() ) {
    next unless -f $file;
    next unless $file->basename =~ /\.csv\z/msx;
    decode_file( $file, \@all );
}

sub xsort {
    my ( $a, $b ) = @_;
    my $delta = $a->[0] cmp $b->[0];
    return $delta if $delta != 0;
    $delta = $a->[1] cmp $b->[1];
    return $delta if $delta != 0;
    return $a->[2] cmp $b->[2];
}
@all = sort { xsort( $a, $b ) } @all;
write_csv( $wd->child('upstream-provides.csv'), \@all );

sub write_csv {
    my ( $file, $lines ) = @_;
    my $fh = $file->openw_utf8;
    my $csv = Text::CSV_XS->new( { binary => 1, auto_diag => 1 } );

    #$csv->column_names ('#gentoo package','upstream');
    $csv->eol("$/");
    for my $row ( @{$lines} ) {
        $csv->print( $fh, $row );
    }
}

sub decode_file {
    my ( $file, $all ) = @_;
    my $rpath   = $file->parent->relative($gtopl);
    my $release = "$rpath";
    return decode_csv(
        $file => sub {
            my (@row) = @_;
            next unless @row == 3;
            push @$all, [ $release, @row ];
        }
    );
}

sub decode_csv {
    my ( $file, $cb ) = @_;
    my $csv = Text::CSV_XS->new( { binary => 1, auto_diag => 1 } );
    my $fh = $file->openr_utf8;
    while ( my $row = $csv->getline($fh) ) {
        $cb->(@$row);
    }
    return;
}

