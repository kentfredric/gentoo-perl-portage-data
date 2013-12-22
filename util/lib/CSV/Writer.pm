use strict;
use warnings;
use utf8;
package CSV::Writer;

# ABSTRACT: Simple CSV writer wrapper around Text::CSV_XS

use Path::Tiny qw(path);
use Text::CSV_XS;

use Class::Tiny {
    file => sub { die "file required" },
    fo   => sub { path( $_[0]->file ) },
    writer => sub { $_[0]->fo->openw_utf8 },
    csv    =>  sub { Text::CSV_XS->new({ binary => 1, eol => "\n" }) },
};

sub writeline {
    my ( $self , $line ) = @_;
    return $self->csv->print( $self->writer, $line );
}

sub writelines {
    my ( $self, $lines ) = @_;
    for my $line ( @$lines ) {
        $self->writeline( $line );
    }
}
1;

