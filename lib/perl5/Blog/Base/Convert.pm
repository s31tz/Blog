package Blog::Base::Convert;
use base qw/Blog::Base::Object/;

use strict;
use warnings;
use utf8;

use Blog::Base::String;
use Time::Local ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Convert - Klasse mit Konvertierungsmethoden

=head1 BASE CLASS

Blog::Base::Object

=head1 METHODS

=head2 germanUmlautToAscii() - Wandele deutsche Umlaute und SZ nach ASCII

=head3 Synopsis

    $newStr = $class->germanUmlautToAscii($str);

=head3 Description

Übersetze ä, Ä, ö, Ö, ü, Ü, ß in ae, Ae, oe, Oe, ue, Ue, ss
und liefere das Resultat zurück.

=cut

# -----------------------------------------------------------------------------

# FIXME: diese Methode ist redundant zu Blog::Base::String->noUmlaut(),
#        eine von beiden bei Gelegenheit beseitigen.

# FIXME: Prüfe bei den Großbuchstaben auf das Folgezeichen. Ist es ein
#        Großbuchstabe, wandele Ä in AE statt Ae.

sub germanUmlautToAscii {
    my ($class,$str) = @_;

    $str =~ s/ä/ae/g;
    $str =~ s/ö/oe/g;
    $str =~ s/ü/ue/g;
    $str =~ s/Ä/Ae/g;
    $str =~ s/Ö/Oe/g;
    $str =~ s/Ü/Ue/g;
    $str =~ s/ß/ss/g;

    return $str;
}

# -----------------------------------------------------------------------------

=head2 timestampToEpoch() - Wandele Timestamp in lokaler Zeit nach Epoch

=head3 Synopsis

    $t = $class->timestampToEpoch($timestamp);

=head3 Description

Es wird vorausgesetzt, dass der Timestamp das Format hat:

    YYYY-MM-DD HH24:MI:SSXFF

Diese Methode ist vor allem nützlich um einen Oracle-Timestamp
(in lokaler Zeit) nach Epoch zu wandeln.

Fehlende Teile werden als 0 angenommen, so dass insbesondere
auch folgende Formate gewandelt werden können:

    YYYY-MM-DD HH24:MI:SS    (keine Sekundenbruchteile)
    YYYY-MM-DD               (kein Zeitanteil)

=cut

# -----------------------------------------------------------------------------

sub timestampToEpoch {
    my ($class,$timestamp) = @_;

    my ($y,$m,$d,$h,$mi,$s,$ms) = split /\D+/,$timestamp;
    $h ||= 0;
    $mi ||= 0;
    $s ||= 0;
    my $t = Time::Local::timelocal($s,$mi,$h,$d,$m-1,$y-1900);
    if ($ms) {
        $t .= ".$ms";
    }

    return $t;
}

# -----------------------------------------------------------------------------

=head2 epochToTimestamp() - Wandele Epoch in Timestamp in lokaler Zeit

=head3 Synopsis

    $timestamp = $class->epochToTimestamp($t);

=cut

# -----------------------------------------------------------------------------

sub epochToTimestamp {
    my ($class,$t) = @_;

    ($t,my $ms) = split /\./,$t;
    my ($s,$mi,$h,$d,$m,$y) = localtime $t;
    $m++;
    $y += 1900;

    my $str = sprintf '%4d-%02d-%02d %02d:%02d:%02d',$y,$m,$d,$h,$mi,$s;
    if ($ms) {
        $str .= ",$ms";
    }
    return $str;
}

# -----------------------------------------------------------------------------

=head1 AUTHOR

Frank Seitz, http://fseitz.de/

=head1 COPYRIGHT

Copyright (C) 2011-2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
