#!/usr/bin/env perl
# FILENAME: gentoo_provides.pl
# CREATED: 12/23/13 02:04:29 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Combine gentoo-to-perl.csv and upstream-provides.csv

use strict;
use warnings;
use utf8;

use Path::Tiny qw(path);
use FindBin;
use Text::CSV_XS;

my $wd = path($FindBin::Bin)->parent;

{

    package CSV::Reader;
    use Path::Tiny qw(path);
    use Class::Tiny {
        file => sub {
            die "File not specified";
        },
        csv => sub {
            return Text::CSV_XS->new(
                { binary => 1, auto_diag => 1, eol => "$/" } );
        },
        fo => sub {
            return path( $_[0]->file );
        },
        reader => sub {
            return $_[0]->fo->openr_utf8;
        },
    };

    sub getline {
        my ($self) = @_;
        return $self->csv->getline( $self->reader );
    }
}

my $gtopl = CSV::Reader->new( { fo => $wd->child('gentoo-to-perl.csv') } );
my $upp   = CSV::Reader->new( { fo => $wd->child('upstream-provides.csv') } );

my $db = {};

warn "Loading upstream-provides.csv\n";
while ( my $line = $upp->getline ) {
    my ( $dist, @rest ) = @{$line};
    $db->{$dist} = [] if not exists $db->{$dist};
    push @{ $db->{$dist} }, \@rest;
}

my @out;
while ( my $line = $gtopl->getline ) {
    my ( $gentoo, $cpan ) = @{$line};
    if ( not exists $db->{$cpan} ) {
        warn "$cpan not in the upstream-provides map";
        next;
    }
    for my $entry ( @{ $db->{$cpan} } ) {
        push @out, [ $gentoo, @{$entry} ];
    }
}

my $output = $wd->child('gentoo-provides.csv');
my $ofh    = $output->openw_utf8;

my $csv = Text::CSV_XS->new( { binary => 1, eol => "$/" } );

sub xsort {
    my ( $a, $b ) = @_;
    my $d;
    $d = $a->[0] cmp $b->[0];
    return $d unless $d == 0;
    $d = $a->[1] cmp $b->[1];
    return $d unless $d == 0;
    return $a->[2] cmp $b->[1];
}

@out = sort { xsort( $a, $b ) } @out;

for my $ol (@out) {
    $csv->print( $ofh, $ol );
}
