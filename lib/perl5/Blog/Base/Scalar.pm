package Blog::Base::Scalar;
use base qw/Blog::Base::Object/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Scalar - Klasse mit Methoden für Skalare

=head1 BASE CLASS

Blog::Base::Object

=head1 METHODS

=head2 Defaultwert

=head3 ifNull() - Ersetze null durch Wert

=head4 Synopsis

    $newVal = $class->ifNull($val,$defaultVal);

=head4 Description

Liefere $defaultVal, wenn $val ein Leerstring oder undef ist,
andernfalls $val.

=cut

# -----------------------------------------------------------------------------

sub ifNull {
    my $class = shift;
    return !defined $_[0] || $_[0] eq ''? $_[1]: $_[0];
}

# -----------------------------------------------------------------------------

=head2 Referenzen

=head3 isBlessedRef() - Test, ob Referenz geblesst ist

=head4 Synopsis

    $bool = $class->isBlessedRef($ref);

=head4 Alias

isBlessed()

=cut

# -----------------------------------------------------------------------------

sub isBlessedRef {
    my ($class,$ref) = @_;
    return Scalar::Util::blessed($ref)? 1: 0;
}

{
    no warnings 'once';
    *isBlessed = \&isBlessedRef;
}

# -----------------------------------------------------------------------------

=head3 isArrayRef() - Teste auf Array-Referenz

=head4 Synopsis

    $bool = $class->isArrayRef($ref);

=cut

# -----------------------------------------------------------------------------

sub isArrayRef {
    my ($class,$ref) = @_;
    $ref = Scalar::Util::reftype($ref);
    return defined $ref && $ref eq 'ARRAY'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isCodeRef() - Teste auf Code-Referenz

=head4 Synopsis

    $bool = $class->isCodeRef($ref);

=cut

# -----------------------------------------------------------------------------

sub isCodeRef {
    my ($class,$ref) = @_;
    $ref = Scalar::Util::reftype($ref);
    return defined $ref && $ref eq 'CODE'? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isRegexRef() - Teste auf Regex-Referenz

=head4 Synopsis

    $bool = $class->isRegexRef($ref);

=head4 Caveats

Wenn die Regex-Referenz umgeblesst wurde, muss sie auf
eine Subklasse von Regex geblesst worden sein, sonst schlägt
der Test fehl. Aktuell gibt es nicht den Grundtyp REGEX, der
von reftype() geliefert würde, sondern eine Regex-Referenz gehört
standardmäßig zu der Klasse Regex.

=cut

# -----------------------------------------------------------------------------

sub isRegexRef {
    my ($class,$ref) = @_;
    return Scalar::Util::blessed($ref) && $ref->isa('Regexp')? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 refType() - Liefere Grundtyp der Referenz

=head4 Synopsis

    $refType = $class->refType($ref);

=head4 Description

Liefere den Grundtyp der Referenz.

Grundtypen sind:

    SCALAR
    ARRAY
    HASH
    CODE
    GLOB
    IO
    REF

=cut

# -----------------------------------------------------------------------------

sub refType {
    return Scalar::Util::reftype($_[1]);
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
