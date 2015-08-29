package Blog::Base::Math;
use base qw/Blog::Base::Object/;

use strict;
use warnings;

use Scalar::Util ();
use POSIX ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Math - Mathematische Funktionen

=head1 BASE CLASS

L<Blog::Base::Object|../Blog::Base/Object.html>

=head1 METHODS

=head2 pi() - Liefere PI

=head3 Synopsis

    $pi = $class->pi;

=cut

# -----------------------------------------------------------------------------

sub pi {
    return 4*CORE::atan2(1,1);
}

# -----------------------------------------------------------------------------

=head2 degreeToRad() - Wandele Grad in Rad

=head3 Synopsis

    $rad = $class->degreeToRad($degree);

=cut

# -----------------------------------------------------------------------------

sub degreeToRad {
    my ($class,$degree) = @_;
    return $degree*$class->pi/180;
}

# -----------------------------------------------------------------------------

=head2 geoToDegree() - Wandele Geo-Ortskoordinate in dezimale Gradangabe

=head3 Synopsis

    $dezDeg = $class->geoToDegree($deg,$min,$sec,$dir);

=head3 Description

Wandele eine geographische Ortsangabe in Grad, Minuten, Sekunden,
Himmelsrichtung in eine dezimale Gradzahl und liefere diese zurück.

=head3 Example

    50 6 44 N -> 50.11222
    50 6 44 S -> -50.11222

=cut

# -----------------------------------------------------------------------------

sub geoToDegree {
    my ($class,$deg,$min,$sec,$dir) = @_;

    $deg = $deg + $min/60 + $sec/3600;

    if ($dir) {
        if ($dir eq 'N' || $dir eq 'E') {
            # nixtun
        }
        elsif ($dir eq 'S' || $dir eq 'W') {
            $deg = -$deg;
        }
        else {
            $class->throw(
                q{MATH-00001: Unbekannte Himmelsrichtung},
                Direction=>$dir,
            );
        }
    }

    return $deg;
}

# -----------------------------------------------------------------------------

=head2 normalizeNumber() - Normalisiere Zahldarstellung

=head3 Synopsis

    $x = $class->normalizeNumber($x);

=head3 Description

Entferne unnötige Nullen von einer Zahl, forciere als Dezimaltrennzeichen
einen Punkt (anstelle eines Komma) und liefere das Resultat zurück.

=head3 Example

    123.456000 -> 123.456
    70.00 -> 70
    0.0 -> 0
    -0.0 -> 0
    007 -> 7
    23,7 -> 23.7

=cut

# -----------------------------------------------------------------------------

sub normalizeNumber {
    my ($class,$x) = @_;

    # Wandele Komma in Punkt
    $x =~ s/,/./;

    # Entferne führende 0en
    $x =~ s/^(-?)0+(?=\d)/$1/;

    if (index($x,'.') >= 0) {
        # Bei einer Kommazahl entferne 0en und ggf. Punkt am Ende
        $x =~ s/\.?0+$//;
    }

    if ($x eq '-0') {
        $x = 0;
    }

    return $x;
}

# -----------------------------------------------------------------------------

=head2 interpolate() - Ermittele Wert durch lineare Interpolation

=head3 Synopsis

    $y = $class->interpolate($x0,$y0,$x1,$y1,$x);

=head3 Returns

Float

=head3 Description

Berechne durch lineare Interpolation den Wert y=f(x) zwischen
den gegebenen Punkten y0=f(x0) und y1=f(x1) und liefere diesen zurück.

Siehe: L<http://de.wikipedia.org/wiki/Interpolation_%28Mathematik%29#Lineare_Interpolation>

=cut

# -----------------------------------------------------------------------------

sub interpolate {
    my ($class,$x0,$y0,$x1,$y1,$x) = @_;
    return $y0+($y1-$y0)/($x1-$x0)*($x-$x0);
}

# -----------------------------------------------------------------------------

=head2 isNumber() - Prüfe, ob Skalar eine Zahl darstellt

=head3 Synopsis

    $bool = $class->isNumber($str);

=cut

# -----------------------------------------------------------------------------

sub isNumber {
    return Scalar::Util::looks_like_number($_[1])? 1: 0;
}

# -----------------------------------------------------------------------------

=head2 roundTo() - Runde Zahl auf n Nachkommastellen

=head3 Synopsis

    $y = $class->roundTo($x,$n);
    $y = $class->roundTo($x,$n,$normalize);

=head3 Description

Runde $x auf $n Nachkommastellen und liefere das Resultat zurück.

Ist $normalize "wahr", wird die Zahl nach der Rundung mit
normalizeNumber() normalisiert.

Bei $n > 0 rundet die Methode mittels

    $y = sprintf '%.*f',$n,$x;

bei $n == 0 mittels roundToInt().

=cut

# -----------------------------------------------------------------------------

sub roundTo {
    my ($class,$x,$n,$normalize) = @_;

    if ($n == 0) {
        return $class->roundToInt($x);
    }

    $x = sprintf '%.*f',$n,$x;
    if ($normalize) {
        $x = $class->normalizeNumber($x);
    }

    return $x;
}

# -----------------------------------------------------------------------------

=head2 roundToInt() - Runde Zahl zu Ganzer Zahl (Integer)

=head3 Synopsis

    $n = $class->roundToInt($x);

=head3 Description

Runde Zahl $x zu ganzer Zahl und liefere das Resultat zurück, nach
folgender Regel:

Für Nachkommastellen < .5 runde ab, für Nachkommastellen >= .5 runde auf.
Für negative $x ist es umgekehrt.

Folgender Ansatz funktioniert nicht:

    $n = sprintf '%.0f',$x;

Manchmal wird nicht richtig auf oder abgerundet:

    0.5 => 0
    1.5 => 2
    2.5 => 2

=cut

# -----------------------------------------------------------------------------

sub roundToInt {
    return $_[1] > 0? int($_[1]+0.5): -int(-$_[1]+0.5);
}

# -----------------------------------------------------------------------------

=head2 roundMinMax() - Runde Breichsgrenzen auf nächsten geeigneten Wert

=head3 Synopsis

    ($minRounded,$maxRounded) = $class->roundMinMax($min,$max);

=head3 Description

Die Methode rundet $min ab und $max auf, so dass geeignete
Bereichsgrenzen für eine Diagrammskala entstehen.

Sind $min und $max gleich, schaffen wir einen künstlichen Bereich
($min-1,$max+1).

Die Rundungsstelle leitet sich aus der Größe des Bereichs
$max-$min her.

=head3 Examples

8.53, 8.73 -> 8.5, 8.8

8.53, 8.53 -> 7, 10

=cut

# -----------------------------------------------------------------------------

sub roundMinMax {
    my ($class,$min,$max) = @_;

    if ($min == $max) {
        # Sind Minimum und Maximum gleich, schaffen wir einen
        # künstlichen Bereich

        $min -= 1;
        $max += 1;
    }

    my $delta = $max-$min;
    for (0.0001,0.001,0.01,0.1,1,10,100,1_000,10_000,100_000) {
        if ($delta < $_) {
            my $step = $_/10;
            $min = POSIX::floor($min/$step)*$step;
            $max = POSIX::ceil($max/$step)*$step;
            last;
        }
    }

    return ($min,$max)
}

# -----------------------------------------------------------------------------

=head2 readableNumber() - Zahl mit Trenner an Tausender-Stellen

=head3 Synopsis

    $str = $class->readableNumber($x);
    $str = $class->readableNumber($x,$sep);

=head3 Example

    1 -> 1
    12 -> 12
    12345 -> 12.345
    -12345678 -> -12.345.678

=cut

# -----------------------------------------------------------------------------

sub readableNumber {
    my $class = shift;
    my $x = shift;
    my $sep = shift || '.';

    if ($sep eq '.') {
        $x =~ s/\./,/;
    }
    1 while $x =~ s/^([-+]?\d+)(\d{3})/$1$sep$2/;

    return $x;
}

# -----------------------------------------------------------------------------

=head2 worldToPixelFactor() - Umrechnungsfaktor Welt- in Pixelkoordinaten

=head3 Synopsis

    $factor = $class->worldToPixelFactor($length,$min,$max)

=head3 Returns

Faktor

=head3 Description

Liefere den Faktor für die Umrechung von Welt- in Pixelkoordinaten.
Die Weltkoordinaten werden transformiert auf einen Bildschirmabschnitt
der Länge $length, dessen Randpunkte den Werten $min und $max
entsprechen.

=cut

# -----------------------------------------------------------------------------

sub worldToPixelFactor {
    my ($class,$size,$min,$max) = @_;
    return ($size-1)/($max-$min);
}

# -----------------------------------------------------------------------------

=head2 worldToPixelX() - Transformiere Weltkoordinate in X-Pixelkoordinate

=head3 Synopsis

    $x = $class->worldToPixelX($width,$xFac,$xMin,$xVal);

=head3 Alias

worldToPixel()

=head3 Returns

X-Position

=head3 Description

Transformiere Weltkoordinate $xVal in eine Pixelkoordinate
auf einer X-Pixelachse der Breite $width. Das Weltkoordinaten-Minimum
ist $xMin und der Umrechnungsfaktor ist $xFac, welcher von
Methode worldToPixelFactor() geliefert wird. Die gelieferten
Werte sollen im Bereich 0 .. $width-1 liegen.

=cut

# -----------------------------------------------------------------------------

sub worldToPixelX {
    my ($class,$width,$xFac,$xMin,$xVal) = @_;
    return sprintf '%.0f',($xVal-$xMin)*$xFac;
}

{
    no warnings 'once';
    *worldToPixel = \&worldToPixelX;
}

# -----------------------------------------------------------------------------

=head2 worldToPixelY() - Transformiere Weltkoordinate in Y-Pixelkoordinate

=head3 Synopsis

    $y = $class->worldToPixelY($height,$yFac,$yMin,$yVal);

=head3 Returns

Y-Position

=head3 Description

Transformiere Weltkoordinate $yVal in eine Pixelkoordinate
auf einer Y-Pixelachse der Höhe $height. Das Weltkoordinaten-Minimum
ist $yMin und der Umrechnungsfaktor ist $yFac, welcher von
Methode worldToPixelFactor() geliefert wird. Die gelieferten
Werte sollen im Bereich $height-1 .. 0 liegen.

=cut

# -----------------------------------------------------------------------------

sub worldToPixelY {
    my ($class,$height,$yFac,$yMin,$yVal) = @_;
    my $y = sprintf '%.0f',($yVal-$yMin)*$yFac;
    return $height-1-$y;
}

# -----------------------------------------------------------------------------

=head2 pixelToWorldFactor() - Umrechnungsfaktor von Pixel- in Weltkoordinaten

=head3 Synopsis

    $factor = $class->pixelToWorldFactor($length,$min,$max);

=head3 Returns

Faktor

=head3 Description

Liefere den Faktor für die Umrechung von Pixel- in Weltkoordinaten
entlang eines Bildschirmabschnitts der Länge $length, dessen Randpunkt
den Weltkoordinaten $min und $max entsprechen.

=cut

# -----------------------------------------------------------------------------

sub pixelToWorldFactor {
    my ($class,$size,$min,$max) = @_;
    return 1/R1::Math->worldToPixelFactor($size,$min,$max);
}

# -----------------------------------------------------------------------------

=head2 epochToDuration() - Wandele Sekunden in (lesbare) Angabe einer Dauer

=head3 Synopsis

    $str = $class->epochToDuration($epoch,$truncate,$format);

=head3 Alias

secondsToDuration()

=head3 Description

Wandele eine Zeitangabe in Sekunden in eine Zeichenkette der Form

    HH:MM:SS  ($format nicht angegeben oder 1)

oder

    HHhMMmSSs ($format == 2)

oder

    HhMmSs ($format == 3)

=cut

# -----------------------------------------------------------------------------

sub epochToDuration {
    my $class = shift;
    my $s = shift;
    my $truncate = shift || 0;
    my $format = shift || 1;

    my $h = int $s/3600;
    $s -= $h*3600;
    my $m = int $s/60;
    $s -= $m*60;

    my $str;
    if ($format == 1) {
        $str = sprintf '%02d:%02d:%02d',$h,$m,$s;
    }
    elsif ($format == 2) {
        $str = sprintf '%02dh%02dm%02ds',$h,$m,$s;
    }
    elsif ($format == 3) {
        $str = sprintf '%dh%dm%ds',$h,$m,$s;
    }
    if ($truncate) {
        $str =~ s/^[0\D]+//;
        if ($str eq '') {
            $str = '0';
            if ($format > 1) {
                $str .= 's';
            }
        }
    }
    
    return $str;
}

{
    no warnings 'once';
    *secondsToDuration = \&epochToDuration;
}

# -----------------------------------------------------------------------------

=head2 intToWord() - Wandele positive ganze Zahl in Wort über Alphabet

=head3 Synopsis

    $word = $this->intToWord($n);
    $word = $this->intToWord($n,$alphabet);

=head3 Returns

Zeichenkette

=head3 Description

Wandele positive ganze Zahl $n in ein Wort über dem Alphabet
$alphabet und liefere dieses zurück. Für 0 liefere
einen Leerstring.

Das Alphabet, über welchem die Worte gebildet werden, wird in Form
einer Zeichenkette angegeben, in der jedes Zeichen einmal
vorkommt. Per Default wird das Alphabet

    'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

verwendet. Die Funktion implementiert folgende Abbildung:

    0 -> ''
    1 -> 'A'
    2 -> 'B'
    
    ...
    26 -> 'Z'
    27 -> 'AA'
    28 -> 'AB'
    ...
    52 -> 'AZ'
    53 -> 'BA'
    ...

=cut

# -----------------------------------------------------------------------------

sub intToWord {
    my $this = shift;
    my $n = shift;
    my $alphabet = shift || 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    my $l = length $alphabet;

    my $word = '';
    my $m = $n; # warum dies?

    while ($m) {
        my $mod = $m%$l;
        $word = substr($alphabet,$mod-1,1).$word;
        $m = POSIX::floor($m/$l);
        $m -= 1 if $mod == 0;
    }

    return $word;
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
