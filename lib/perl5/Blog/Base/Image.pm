package Blog::Base::Image;
use base qw/Blog::Base::Object/;

use strict;
use warnings;

use Blog::Base::FileHandle;

# -----------------------------------------------------------------------------

=head1 NAME

Blog::Base::Image - Operationen auf Bildern

=head1 BASE CLASS

Blog::Base::Object

=head1 METHODS

=head2 type() - Liefere Typ einer Bilddatei

=head3 Synopsis

    $type = $class->type($file);

=head3 Description

Liefere den Typ der Bilddatei $file. Drei Bildtypen werden
erkannt: 'jpg', 'png', 'gif'. Ist der Bildtyp nicht bekannt, wirf
eine Exception.

=cut

# -----------------------------------------------------------------------------

sub type {
    my ($class,$file) = @_;

    my $fh = Blog::Base::FileHandle->new('<',$file);
    my $data = $fh->read(8);
    $fh->close;

    if ($data =~ /^\xff\xd8\xff/) {
        return 'jpg';
    }
    elsif ($data =~ /^\x89PNG\r\n\x1a\n/) {
        return 'png';
    }
    elsif ($data =~ /^(GIF89a|GIF87a)/) {
        return 'gif';
    }
    else {
        $class->throw(
            q{IMG-00001: Unbekannter Bildtyp},
            File=>$file,
            Data=>$data,
        );
    }

    # nicht erreicht
}

# -----------------------------------------------------------------------------

=head1 AUTHOR

Frank Seitz, http://fseitz.de/

=head1 COPYRIGHT

Copyright (C) 2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
