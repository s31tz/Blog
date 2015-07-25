package Blog::Base::DirHandle;
use base qw/Blog::Base::Object/;

use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::DirHandle - Object oriented interface to Perls directory handles

=head1 BASE CLASS

L<Blog::Base::Object|../Blog::Base/Object.html>

=head1 SYNOPSIS

    use Blog::Base::DirHandle;
    
    my $dh = Blog::Base::DirHandle->new($dir);
    while (my $entry = $dh->next) {
        say $entry;
    }
    $dh->close;

=head1 DESCRIPTION

Die Klasse stellt eine objektorientierte Schnittstelle zu
Perls Directory Handles her. Mit den Methoden der Klasse kann
ein Verzeichnis geöffnet und über seine Einträge iteriert werden.

=head1 METHODS

=head2 new() - Konstruktor

=head3 Synopsis

    $dh = $class->new($dir);

=head3 Alias

open()

=head3 Description

Instantiiere ein Dirhandle-Objekt für Verzeichnis $dir und liefere
eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$dir) = @_;

    opendir my $dh,$dir or do {
        $class->throw(
            q{DIR-00001: Verzeichnis öffnen fehlgeschlagen},
            Dir=>$dir,
            Error=>"$!",
        );
    };

    return bless $dh,$class;
}

{
    no warnings 'once';
    *open = \&new;
}

# -----------------------------------------------------------------------------

=head2 close() - Schließe Verzeichnis

=head3 Synopsis

    $dh->close;

=head3 Description

Schließe das Verzeichnis. Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub close {
    my $self = shift;

    closedir $self or do {
        $self->throw(
            q{DIR-00002: Dirhandle schließen fehlgeschlagen},
            Error=>"$!",
        );
    };

    return;
}

# -----------------------------------------------------------------------------

=head2 next() - Liefere nächsten Verzeichniseintrag

=head3 Synopsis

    $entry = $dh->next;

=head3 Description

Liefere den nächsten Verzeichniseintrag. Die Einträge werden in
der Reihenfolge geliefert, wie sie im Verzeichnis stehen, also
de facto ungeordnet. Ist das Ende erreicht, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub next {
    return readdir shift;
}

# -----------------------------------------------------------------------------

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright © 2010-2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
