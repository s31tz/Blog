package Blog::Base::Image;
use base qw/Blog::Base::Object/;

use strict;
use warnings;

use Blog::Base::FileHandle;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Image - Operationen auf Bildern

=head1 BASE CLASS

L<Blog::Base::Object|../Blog::Base/Object.html>

=head1 METHODS

=head2 type() - Liefere Typ einer Bilddatei

=head3 Synopsis

    $type = $class->type($file);
    $type = $class->type($file,$enumType);

=head3 Description

Liefere den Typ der Bilddatei $file. Drei Bildtypen werden erkannt:

=over 2

=item *

JPEG

=item *

PNG

=item *

GIF

=back

Die Typbezeichnung, die geliefert wird, hängt von PArameter
$enumType ab:

=over 4

=item 0 oder nicht angegeben

'jpg', 'png', 'gif'

=item 1

'jpeg', 'png', 'gif'

=back

Wird der Bildtyp nicht erkannt, wirft die Methode eine Exception.

Anstelle eines Dateinamens kann auch eine Skalarreferenz
(Bild in-memory) übergeben werden.

=cut

# -----------------------------------------------------------------------------

sub type {
    my $class = shift;
    my $file = shift;
    my $enumType = shift || 0;

    my $fh = Blog::Base::FileHandle->new('<',$file);
    my $data = $fh->read(8);
    $fh->close;

    if ($data =~ /^\xff\xd8\xff/) {
        return $enumType? 'jpeg': 'jpg';
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

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright © 2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
