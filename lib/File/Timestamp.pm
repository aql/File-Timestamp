package File::Timestamp;
use strict;
use warnings;
use Carp;
use version;
our $VERSION = qv('0.0.1');
use base qw( Exporter::Lite );
our @EXPORT_OK = qw( timestamp );

sub timestamp { __PACKAGE__->new( @_ ); }

sub new {
    my $class = shift;

    my $self = bless {}, $class;
    $self->{_opts} = ref $_[-1] eq 'HASH' ? pop @_ : {};

    ( $self->{atime}, $self->{mtime} ) = _normalize(
        @_ == 1 ? _get_timestamp( $_[0] ) : @_ == 2 ? @_ : ( 0, 0 )
    );

    return $self;
}

sub set {
    my $self = shift;
    my $path = shift;
    utime $self->atime, $self->mtime, $path if $path and -e $path;
}

sub atime { shift->_accessor( 'atime', @_ ); }
sub mtime { shift->_accessor( 'mtime', @_ ); }

sub clone {
    my $self = shift;
    return bless { %$self }, ( ref $self || $self );
}

sub _accessor {
    my $self  = shift;
    my $key   = shift;
    my $value = shift;

    if ( $value ) {
        $self->{$key} = $self->_deflate( $value );
        return $value;
    }
    else {
        return $self->_inflate( $self->{$key} );
    }
}


sub _inflate {
    my $self = shift;
    my @inflated = ref $self->{_opts}->{inflate} eq 'CODE'
        ? map { $self->{_opts}->{inflate}->( $_ ) } @_
        : @_;
    return wantarray ? @inflated : $inflated[0];
}

sub _deflate {
    my $self = shift;
    my @deflated = _normalize(
        ref $self->{_opts}->{deflate} eq 'CODE'
            ? map { $self->{_opts}->{deflate}->( $_ ) } @_
            : @_
    );
    return wantarray ? @deflated : $deflated[0];
}

sub _normalize {
    map { $_ =~ m{^\d+$} ? $_ : 0 } @_
}

sub _get_timestamp {
    my $path = shift;
    return ( $path and -e $path ) ? @{[stat $path]}[8,9] : ();
}

1;
__END__

=head1 NAME

File::Timestamp - OO interface for timestamp.


=head1 SYNOPSIS

    use File::Timestamp qw( timestamp );

    $stamp = File::Timestamp->new( $foo );
        # same as "$stamp = timestamp( $foo )"
    $stamp->atime;
    $stamp->mtime( $new_time );
    $stamp->set( $bar );


=head1 DESCRIPTION

File::Timestamp is a interface for atime/mtime of built-in stat() function.


=head1 METHODS

=over 4

=item C<< new >>

=item C<< atime >>

=item C<< mtime >>

=item C<< set >>

=item C<< clone >>

=item C<< timestamp >>

=back


=head1 AUTHOR

TOYODA Tetsuya  C<< <cpan@hikoboshi.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, TOYODA Tetsuya C<< <cpan@hikoboshi.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
