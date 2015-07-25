package Blog::Base::ColumnFormat;
use base qw/Blog::Base::Object/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::ColumnFormat - Format einer Text-Kolumne

=head1 BASE CLASS

L<Blog::Base::Object|../Blog::Base/Object.html>

=head1 DESCRIPTION

Ein Objekt der Klasse ist Träger von Formatinformation über eine
Menge von Werten, die tabellarisch dargestellt werden sollen,
z.B. in einer Text- oder HTML-Tabelle.

Die Methoden der Klasse formatieren die Werte der Wertemenge
entsprechend und liefern Information über die Ausrichtung.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

    $fmt = $class->new($type,$width,$scale,$null,$mask);

=head4 Description

Die übergebenen Parameter enthalten folgende Information:

=over 4

=item $type

Typ ('t', 's', 'd' oder 'f').

=item $width

Länge des längsten Werts.

=item $scale

Maximale Anzahl an Nachkommastellen (im Falle von Werten vom
Typ f).

=item $null

Anzahl der Nullwerte.

=item $mask

Maximale Anzahl der zu maskierenden Zeichen bei einzeiliger
Darstellung. Maskiert werden die Zeichen \n, \r, \t, \0, \\.

=back

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$type,$length,$scale,$null,$mask) = @_;
    #             0     1       2      3     4
    return bless [$type,$length,$scale,$null,$mask],$class;
}

# -----------------------------------------------------------------------------

=head2 Formatierung

=head3 asFixedWidthString() - Formatiere Wert auf feste Breite

=head4 Synopsis

    $str = $fmt->asFixedWidthString($value);

=cut

# -----------------------------------------------------------------------------

sub asFixedWidthString {
    my ($self,$value) = @_;

    my $type = $self->[0];
    my $width = $self->[1];
    my $scale = $self->[2];

    if (!defined($value) || $value eq '') {
        return ' ' x $width;
    }
    elsif ($type eq 's' || $type eq 't') {
        $value = sprintf '%-*s', $self->[1],$value;
    }
    elsif ($type eq 'd') {
        $value = sprintf '%*d',$self->[1],$value;
    }
    elsif ($type eq 'f') {
        $value = sprintf '%*.*f',$self->[1],$self->[2],$value;
    }
    else {
        $self->throw(
            q{COL-00001: Unbekanntes Kolumnenformat},
            Type=>$type,
        );
    }

    return $value;
}

# -----------------------------------------------------------------------------

=head3 asTdContent() - Formatiere Wert für eine HTML td-Zelle

=head4 Synopsis

    $html = $fmt->asTdContent($value);

=cut

# -----------------------------------------------------------------------------

sub asTdContent {
    my ($self,$value) = @_;

    if (!defined($value) || $value eq '') {
        return '';
    }
    elsif ($self->[0] eq 'f') {
        $value = sprintf '%*.*f',$self->[1],$self->[2],$value;
        $value =~ s/^ +//g;
    }
    elsif ($self->[0] eq 's' || $self->[0] eq 't') {
        $value =~ s/&/&amp;/g;
        $value =~ s/</&lt;/g;
        $value =~ s/>/&gt;/g;
    }

    return $value;
}

# -----------------------------------------------------------------------------

=head3 htmlAlign() - Horizontale Ausrichtung in HTML

=head4 Synopsis

    $align = $fmt->htmlAlign;

=head4 Description

Für numerische Kolumnen wird der Wert 'right' geliefert,
für Textkolumnen der Wert 'left';

=cut

# -----------------------------------------------------------------------------

sub htmlAlign {
    my $self = shift;

    my $type = $self->[0];
    if ($type eq 'f' || $type eq 'd') {
        return 'right';
    }
    return 'left';
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
