package File::Timestamp::Test;
use strict;
use warnings;
use base qw( Test::Class );
use Test::More;
use File::Timestamp qw( timestamp );
use IO::File;

sub setup : Test(setup) {
    my $self = shift;
    my $tmp_dir = "$0.tmp";

    if ( ! -d $tmp_dir ) {
        if ( mkdir $tmp_dir ) {
            $self->{tmp_dir} = $tmp_dir;
        }
        else {
            die "Can't create tmp dir: $tmp_dir\n";
        }
    }

    for my $file ( qw( file1.txt file2.txt file3.txt ) ) {
        if ( _touch( "$tmp_dir/$file" ) ) {
            push @{$self->{tmp_files}}, "$tmp_dir/$file";
        }
        else {
            die "Can't create tmp file: $tmp_dir/$file\n";
        }
    }

    utime 0, 0, $self->{tmp_files}->[0];
    utime 0, 1234567890, $self->{tmp_files}->[1];
    utime 1234567890, 1234567890, $self->{tmp_files}->[2];
}

sub teardown : Test(teardown) {
    my $self = shift;
    my $tmp_dir = $self->{tmp_dir};
    while ( my $file = shift @{$self->{tmp_files}} ) {
        unlink( $file );
    }
    rmdir $tmp_dir;
    $self->{tmp_dir} = '';
}

sub _touch {
    my $path = shift;
    my $fh = IO::File->new( ">$path" );
    if ( defined $fh ) {
        print $fh "touch\n";
        $fh->close;
        return 1;
    }
    return;
}

sub t01_constructor : Tests {
    my $self = shift;
    my $s;

    $s = File::Timestamp->new;
    is( ref $s, 'File::Timestamp' );
    is( $s->{atime}, 0 );
    is( $s->{mtime}, 0 );
    ok( !$s->{_opts}->{inflate} );
    ok( !$s->{_opts}->{deflate} );
    undef $s;

    $s = File::Timestamp->new( $self->{tmp_files}->[0] );
    is( ref $s, 'File::Timestamp' );
    is( $s->{atime}, 0 );
    is( $s->{mtime}, 0 );
    ok( !$s->{_opts}->{inflate} );
    ok( !$s->{_opts}->{deflate} );
    undef $s;

    $s = File::Timestamp->new( $self->{tmp_files}->[1], { inflate => 'foo', deflate => 'bar' } );
    is( ref $s, 'File::Timestamp' );
    is( $s->{atime}, 0 );
    is( $s->{mtime}, 1234567890 );
    is( $s->{_opts}->{inflate}, 'foo' );
    is( $s->{_opts}->{deflate}, 'bar' );
    undef $s;

    $s = File::Timestamp->new( 1, 2 );
    is( ref $s, 'File::Timestamp' );
    is( $s->{atime}, 1 );
    is( $s->{mtime}, 2 );
    ok( !$s->{_opts}->{inflate} );
    ok( !$s->{_opts}->{deflate} );
    undef $s;

    $s = File::Timestamp->new( 1, 2, { inflate => 'foo', deflate => 'bar' } );
    is( ref $s, 'File::Timestamp' );
    is( $s->{atime}, 1 );
    is( $s->{mtime}, 2 );
    is( $s->{_opts}->{inflate}, 'foo' );
    is( $s->{_opts}->{deflate}, 'bar' );
    undef $s;

    is_deeply(
        File::Timestamp->new( $self->{tmp_files}->[2] ),
        timestamp( $self->{tmp_files}->[2] )
    );
}

sub t02_accessors : Tests {
    my $self = shift;
    my $s;

    $s = timestamp( $self->{tmp_files}->[0] );
    is( $s->atime, $s->{atime} );
    is( $s->mtime, $s->{mtime} );
    is( $s->atime, [stat $self->{tmp_files}->[0]]->[8] );
    is( $s->mtime, [stat $self->{tmp_files}->[0]]->[9] );
    undef $s;

    $s = timestamp( $self->{tmp_files}->[1] );
    is( $s->atime, [stat $self->{tmp_files}->[1]]->[8] );
    is( $s->mtime, [stat $self->{tmp_files}->[1]]->[9] );
    $s->atime( 1 );
    $s->mtime( 2 );
    is( $s->atime, 1 );
    is( $s->mtime, 2 );
    undef $s;

    $s = timestamp( $self->{tmp_files}->[2] );
    is( $s->atime, [stat $self->{tmp_files}->[2]]->[8] );
    is( $s->mtime, [stat $self->{tmp_files}->[2]]->[9] );
    undef $s;

    $s = timestamp( $self->{tmp_files}->[1], {
        inflate => sub { $_[0] + 1 }, deflate => sub { $_[0] - 1 }
    });
    is( $s->atime, [stat $self->{tmp_files}->[1]]->[8] + 1 );
    is( $s->mtime, [stat $self->{tmp_files}->[1]]->[9] + 1 );
    $s->atime( 3 );
    $s->mtime( 4 );
    is( $s->atime, 3 );
    is( $s->mtime, 4 );
    is( $s->{atime}, 2 );
    is( $s->{mtime}, 3 );
    undef $s;

    $s = timestamp( 'foo', 'bar' );
    is( $s->atime, 0 );
    is( $s->mtime, 0 );
    undef $s;
}

sub t03_set : Tests {
    my $self = shift;
    my $s;

    $s = timestamp( 1, 2 );
    $s->set( $self->{tmp_files}->[0] );
    is( [stat $self->{tmp_files}->[0]]->[8], $s->atime );
    is( [stat $self->{tmp_files}->[0]]->[9], $s->mtime );
    undef $s;
}

sub t04_clone : Tests {
    my $self = shift;

    my $s1 = timestamp( 1, 2 );

    my $s2 = $s1->clone;
    is_deeply( $s2, $s1 );
    $s2->atime( 3 );
    $s2->mtime( 4 );
    isnt( $s2->atime, $s1->atime );
    isnt( $s2->mtime, $s1->mtime );

    my $s3 = $s1;
    is_deeply( $s3, $s1 );
    $s3->atime( 5 );
    $s3->mtime( 6 );
    is( $s3->atime, $s1->atime );
    is( $s3->mtime, $s1->mtime );
}

__PACKAGE__->runtests;
