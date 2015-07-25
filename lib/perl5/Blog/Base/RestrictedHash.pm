package Blog::Base::RestrictedHash;
use base qw/Blog::Base::Hash/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::RestrictedHash - Hash-Klasse ohne änderbare Schüssel

=head1 BASE CLASS

L<Blog::Base::Hash|../Blog::Base/Hash.html>

=head1 DESCRIPTION

Identisch zu Blog::Base::Hash, nur dass am Ende des Konstruktors
alle Hash-Keys gelockt werden.

=head1 METHODS

=head2 new()

=head3 Description

Siehe Basisklasse Blog::Base::Hash.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: Argumente

    my $self = $class->SUPER::new(@_);
    $self->lockKeys;

    return $self;
}

# -----------------------------------------------------------------------------

=head2 copy()

=head3 Description

MEMO: Diese Methode macht Probleme im Zusammenhang mit CoTeDo! Dateien
werden alternierend gelöscht und generiert. Grund unklar.

Siehe Basisklasse Blog::Base::Hash.

=cut

# -----------------------------------------------------------------------------

#sub copy {
#    my $self = shift;
#
#    my $h = $self->SUPER::copy;
#    $h->lockKeys;
#
#    return $h;
#}

# -----------------------------------------------------------------------------

=head2 add() -  Füge neue Schlüssel/Wert-Paare hinzu

=head3 Synopsis

    $hash->add(@keyVal);

=cut

# -----------------------------------------------------------------------------

sub add {
    my $self = shift;
    # @_: @keyVal

    # FIXME: Nachdenken, ob Exception, wenn Attribut bereits existiert

    $self->unlockKeys;
    while (@_) {
        my $key = shift;
        $self->{$key} = shift;
    }
    $self->lockKeys;

    return;
}

# -----------------------------------------------------------------------------

=head2 exists()

=head3 Description

Siehe Basisklasse Blog::Base::Hash.

=cut

# -----------------------------------------------------------------------------

sub exists {
    my ($self,$key) = @_;

    $self->unlockKeys;
    my $bool = $self->SUPER::exists($key);
    $self->lockKeys;

    return $bool;
}

# -----------------------------------------------------------------------------

=head2 rebless()

=head3 Description

Siehe Basisklasse Blog::Base::Object.

=cut

# -----------------------------------------------------------------------------

sub rebless {
    my ($self,$class) = @_;

    $self->unlockKeys;
    $self->SUPER::rebless($class);
    $self->lockKeys;

    return;
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
