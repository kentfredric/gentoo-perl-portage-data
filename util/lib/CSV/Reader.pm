use strict;
use warnings;
use utf8;
package CSV::Reader;

# ABSTRACT: Simple CSV reader wrapper around Text::CSV_XS

use Path::Tiny qw(path);
use Text::CSV_XS;

use Class::Tiny {
    file => sub { die "file required" },
    fo   => sub { path( $_[0]->file ) },
    reader => sub { $_[0]->fo->openr_utf8 },
    csv    =>  sub { Text::CSV_XS->new({ binary => 1, eol => "\n" }) },
};

sub getline {
    my ( $self ) = @_;
    return $self->csv->getline( $self->reader );
}

sub foreach_line {
    my ( $self, $cb ) = @_;
    while ( my $line = $self->getline ) {
        $cb->( @{ $line } );
    }
}


1;

