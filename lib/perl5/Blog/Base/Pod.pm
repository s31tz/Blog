package Blog::Base::Pod;

use strict;
use warnings;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Pod - Methoden zur Generierung von POD-Code

=head1 METHODS

=head2 Methods

=head3 inlineSegment() - Liefere Inline-Segment

=head4 Synopsis

    $str = $class->inlineSegment($type,$text);

=head4 Description

Erzeuge POD Inline-Segment vom Typ $type (B, I, C usw.)
und liefere dieses zurück.

Die Methode sorgt dafür, dass das Segment korrekt generiert wird,
wenn in $text die Zeichen '<' oder '>' vorkommen.

=cut

# -----------------------------------------------------------------------------

sub inlineSegment {
    my ($class,$type,$text) = @_;

    my $maxL = 0;
    while ($text =~ /(>+|<+)/g) {
        my $l = length($1);
        if ($l > $maxL) {
            $maxL = $l;
        }
    }
    if ($text =~ /^</ or $text =~ />$/) {
        $text = " $text ";
    }
    $maxL++;

    return sprintf '%s%s%s%s',$type,'<'x$maxL,$text,'>'x$maxL;
}

# -----------------------------------------------------------------------------

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright © 2009-2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
