#!/usr/bin/env perl
# FILENAME: aggregate_gentoo_to_perl.pl
# CREATED: 12/23/13 00:20:33 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Map gentoo-to-perl/* into top level CSV files

use strict;
use warnings;
use utf8;

use Path::Tiny qw(path);
use FindBin;
use Text::CSV_XS;

my $wd    = path($FindBin::Bin)->parent;
my $gtopl = $wd->child('gentoo-to-perl');

my $it = $gtopl->iterator( { recurse => 1, follow_symlinks => 0 } );
my @all;

my $add_item = sub {
    my ( $atom, $upstream ) = @_;
    push @all, [ $atom, $upstream ];
};

while ( my $file = $it->() ) {
    next unless -f $file;
    next unless $file->basename =~ /\.csv\z/msx;
    my $rpath = $file->relative($gtopl);
    decode_file( $file );
}
@all = sort { $a->[0] cmp $b->[0] } @all;
write_csv( $wd->child('gentoo-to-perl.csv'), \@all );

sub write_csv { 
    my ( $file, $lines ) = @_;
    my $fh = $file->openw_utf8;
    my $csv = Text::CSV_XS->new({ binary => 1, auto_diag => 1 });
    #$csv->column_names ('#gentoo package','upstream');
    $csv->eol("$/");
    for my $row ( @{ $lines } ) {
        $csv->print( $fh, $row );
    }
}

sub decode_file {
    my ( $file ) = @_;
    my $rpath = $file->relative($gtopl);
    my (@parts) = split '/', $rpath;
    if ( @parts == 1 ) {
        return decode_toplevel_csv( $file, $add_item );
    }
    if ( @parts == 2 ) {
        return decode_category_csv( $file, $parts[0] , $add_item);
    }
    if ( @parts == 3 ) {
        return decode_package_csv( $file, $parts[0], $parts[1], $add_item );
    }
    if ( @parts == 4 ) { 
        return decode_version_csv( $file, $parts[0],$parts[1],$parts[2], $add_item );
    }
    warn "Unhandled file $rpath";
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

sub decode_toplevel_csv {
    my ( $file, $cb ) = @_;
    return decode_csv(
        $file => sub {
            my (@fields) = @_;
            if ( @fields == 2 ) {
                $cb->(@fields);
            }
        }
    );
}

sub decode_category_csv {
    my ( $file, $category, $cb ) = @_;
    return decode_csv(
        $file => sub {
            my (@fields) = @_;
            if ( @fields == 2 ) {
                my $pkg = shift @fields;
                $cb->( $category . '/' . $pkg, @fields );
            }
        }
    );

}

sub decode_package_csv {
    my ( $file, $category, $package, $cb ) = @_;
    return decode_csv(
        $file => sub {
            my (@fields) = @_;
            if ( @fields == 2 ) {
                my $version = shift @fields;
                $cb->( $category . '/' . $package . '-' . $version, @fields );
            }
        }
    );

}

sub decode_version_csv {
    my ( $file, $category, $package, $version, $cb ) = @_;
    return decode_csv(
        $file => sub {
            my (@fields) = @_;
            if ( @fields == 1 ) {
                $cb->( $category . '/' . $package . '-' . $version, @fields );
            }
        }
    );

}
