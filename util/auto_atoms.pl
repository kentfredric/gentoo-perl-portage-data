#!/usr/bin/env perl
# FILENAME: auto_atoms.pl
# CREATED: 12/23/13 03:30:40 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Generate an automatic atom list from gentoo-provides.csv

use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/lib";

use CSV::Reader;
use CSV::Writer;
use Data::Dump qw(pp);

my $c = CSV::Reader->new( file => "$FindBin::Bin/../gentoo-provides.csv" );

my $map = {};

$c->foreach_line(
    sub {
        my ( $atom, $module, $version, $flags ) = @_;
        $map->{$module} = {} if not exists $map->{$module};
        $map->{$module}->{0} = [] if not exists $map->{$module}->{0};
        push @{ $map->{$module}->{0} }, $atom;

        if ( $flags ne 'undefined' ) {
            $map->{$module}->{$version} = [] if not exists $map->{$module}->{$version};
            push @{ $map->{$module}->{$version} }, $atom;
        }

    }
);

my $w = CSV::Writer->new( file => "$FindBin::Bin/../auto-atoms.csv" );

for my $module ( sort keys %{$map} ) {
    for my $version ( sort keys %{ $map->{$module} } ) {
        my $atoms = $map->{$module}->{$version};
        if ( @{$atoms} == 1 ) {
            $w->writeline([ $module, $version, '=' . $atoms->[0] ]);
        } else {
            $w->writeline([ $module, $version, '|| ( ' . ( join ' ', map { '=' . $_ } @{$atoms}  ) . ' )' ]);
        }
    }
}
