package Blog::Base::Html;
use base qw/Blog::Base::Hash/;

use strict;
use warnings;

use Blog::Base::Hash;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Html - Basisklasse für HTML-Komponenten

=head1 BASE CLASS

Blog::Base::Hash

=head1 ATTRIBUTES

=over 4

=item id => $str (Default: undef)

Id des Konstrukts.

=item cssPrefix => $str (Default: undef)

Präfix für die CSS-Klassennamen.

=back

=head1 METHODS

=head2 Hilfsmethoden

=head2 Konstruktor

=head3 textToHtml() - Wandele Text nach HTML

=head4 Synopsis

    $html = $this->textToHtml($text);

=head4 Arguments

=over 4

=item $text

Einfacher Text (ohne Tags)

=back

=head4 Returns

=over 4

=item $html

Text, in dem &, < und > durch Entities ersetzt sind

=back

=cut

# -----------------------------------------------------------------------------

sub textToHtml {
    my ($this,$str) = @_;

    $str =~ s/&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;

    return $str;
}

# -----------------------------------------------------------------------------

=head3 new() - Konstruktor

=head4 Synopsis

    $obj = $class->new(@attVal);

=head4 Description

Instantiiere ein Html-Basisklassenobjekt, füge alle Attribute hinzu
(auch der Subklasse) und locke alle Keys. Liefere eine Referenz auf
das Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @attVal

    my $self = $class->SUPER::new(
        cssPrefix=>undef,
        id=>undef,
    );
    $self->set(@_); # Wir dürfen hier beliebig setzen
    $self->lockKeys;

    return $self;
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
