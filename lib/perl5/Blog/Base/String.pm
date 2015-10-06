package Blog::Base::String;
use base qw/Blog::Base::Object/;

use strict;
use warnings;
use utf8;

use Blog::Base::Misc;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::String - Stringklasse

=head1 BASE CLASS

L<Blog::Base::Object|../Blog::Base/Object.html>

=head1 SYNOPSIS

    use Blog::Base::String;
    
    my $obj = Blog::Base::String->new($str);

=head1 DESCRIPTION

Diese Klasse definiert String-Methoden.

    [1] $str = Blog::Base::String->METH($str,...);
    [2] Blog::Base::String->METH(\$str,...);
    [3] ... = $str->METH(...);

Abfrage der Parameter:

    sub %METHOD% {
        # @_: $strObj -or- $class,$ref -or- $class,$str
    
        shift unless ref $_[0]; # Klassenmethode
        my $ref = ref $_[0]? shift: \(my $str = shift);
    
        # ...
    
        $ref == \$str? return $str: return;
    }

=head1 METHODS

=head2 new() - Instantiiere String-Objekt

=head3 Synopsis

    1. $strObj = $class->new;
    2. $strObj = $class->new(\$str);
    3. $strObj = $class->new($str);

=head3 Description

Instantiiere ein String-Objekt und liefere eine Referenz auf dieses
Objekt zurück.

=over 4

=item 1.

Ist kein Parameter angegeben oder ist dieser undef, wird
das Objekt auf einen Leerstring instanziiert.

=item 2.

Wird eine (String-)Referenz übergeben, wird der String nicht
kopiert, sondern auf Blog::Base::String geblesst.

=item 3.

Der Sting wird kopiert.

=back

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: String-Argument

    if (!defined $_[0]) {
        my $str = '';
        return bless \$str,$class;
    }
    elsif (ref $_[0]) {
        return bless $_[0],$class;
    }

    my $str = shift;
    return bless \$str,$class;
}

# -----------------------------------------------------------------------------

=head2 chomp() - Wende chomp() an und liefere Resultat zurück

=head3 Synopsis

    $newStr = $class->chomp($str);

=cut

# -----------------------------------------------------------------------------

sub chomp {
    my ($class,$str) = @_;
    chomp $str;
    return $str;
}

# -----------------------------------------------------------------------------

=head2 extractKeyVal() - Liefere Schüssel/Wert-Paare

=head3 Synopsis

    $arr|@arr = $strObj->extractKeyVal;
    $arr|@arr = $class->extractKeyVal(\$str);

=head3 Description

Liefere die in der Zeichenkette enthaltenen Schlüssel/Wert-Paare.

Die Schlüssel/Wert-Paare haben die Form:

    KEY="VAL"

Wenn VAL kein Whitespace enthält, können die Anführungsstriche
weggelassen werden:

    KEY=VAL

=head3 Example

    q| var1=val1 var2="val2a val2b" var3=val3 var4="val4" |;
    =>
    ('var1','val1','var2','val2a val2b','var3','val3','var4','val4')

=head3 Caveats

Wenn VAL mit einem doppelten Anführungsstrich beginnt, darf es
keine doppelten Anführungsstiche enthalten.

=cut

# -----------------------------------------------------------------------------

sub extractKeyVal {
    my $ref = ref $_[0]? $_[0]: $_[1];

    my @arr;
    my $str = $$ref;
    while ($str =~ s/^\s*(\w+)=//) {
        push @arr,$1;
        $str =~ s/^"([^"]*)"// || $str =~ s/^\{([^}]*)\}// ||
            $str =~ s/^(\S*)//;
        push @arr,$1;
    }

    return wantarray? @arr: bless \@arr,'Blog::Base::Array';
}

# -----------------------------------------------------------------------------

=head2 extractMailAddresses() - Liefere die in der Zeichenkette enthaltenen Email-Adressen

=head3 Synopsis

    @arr = $strObj->extractMailAddresses;
    @arr = $class->extractMailAddresses(\$str);

=head3 Description

Extrahiere Mailadressen der Art user@host.domain aus $str und liefere
ein Array mit diesen Adressen zurück.

=head3 Example

=over 2

=item *

Zwei Adressen:

    "To: lieschen Mueller <lieschen.mueller@irgendwo.de>,
        Ernst Mustermann <ernst@mustermann.de>"
    -->
    lieschen.mueller@irgendwo.de
    ernst@mustermann.de

=back

=cut

# -----------------------------------------------------------------------------

sub extractMailAddresses {
    my $ref = ref $_[0]? $_[0]: $_[1];

    # FIXME: Pattern verbessern
    my @arr = $$ref =~ m|([-\w.]+\@[-\w.]+(?:\.[-\w.]+)+)|g;

    return wantarray? @arr: bless \@arr,'Blog::Base::Array';
}

# -----------------------------------------------------------------------------

=head2 noUmlaut() - Kodiere ä, ö, ü usw. als ae, oe, ue usw.

=head3 Synopsis

    $strObj->noUmlaut;
    $class->noUmlaut(\$str);

=cut

# -----------------------------------------------------------------------------

sub noUmlaut {
    my $ref = ref $_[0]? $_[0]: $_[1];

    $$ref =~ s/ä/ae/g;
    $$ref =~ s/ö/oe/g;
    $$ref =~ s/ü/ue/g;
    $$ref =~ s/Ä/Ae/g;
    $$ref =~ s/Ö/Oe/g;
    $$ref =~ s/Ü/Ue/g;
    $$ref =~ s/ß/ss/g;

    return;
}

# -----------------------------------------------------------------------------

=head2 removeIndent() - Entferne Text-Einrückung

=head3 Synopsis

    $strObj->removeIndent(@opt);
    $str = $class->removeIndent($str,@opt);
    $class->removeIndent(\$str,@opt);

=head3 Options

=over 4

=item -addNL => $bool (Default: 0)

Nach dem Entfernen aller NEWLINEs am Ende füge ein NEWLINE hinzu.

=back

=head3 Description

Entferne Text-Einrückung aus Zeichenkette $str und liefere das
Resultat zurück [1]. Wird eine Referenz auf $str übergeben, wird die
Zeichenkette "in place" manipuliert und nichts zurückgegeben [2].

=over 2

=item o

NEWLINEs am Anfang werden entfernt.

=item o

Whitespace (SPACEs, TABs, NEWLINEs) am Ende wird entfernt.
Das Resultat endet also grundsätzlich nicht mit einem NEWLINE.

=item o

Die Methode kehrt zurück, wenn $str anschließend nicht mit wenigstens
einem Whitespace-Zeichen beginnt, denn dann existiert keine
Einrückung, die zu entfernen wäre.

=item o

Die Einrückung von $str ist die längste Folge von SPACEs
und TABs, die allen Zeilen von $str gemeinsam ist,
ausgenommen Leerzeilen. Diese Einrückung wird am Anfang
aller Zeilen von $str entfernt.

=item o

Eine Leerzeile ist eine Zeile, die nur aus Whitespace besteht.

=back

=head3 Example

=over 2

=item *

Einrückung entfernen, Leerzeile übergehen:

    |
    |  Dies ist
    |              <- Leerzeile ohne Einrückung
    |  ein Test-
    |  Text.
    |

wird zu

    |Dies ist
    |
    |ein Test-
    |Text.

=item *

Tiefere Einrückung bleibt bestehen:

    |
    |    Dies ist
    |  ein Test-
    |  Text.
    |

wird zu

    |  Dies ist
    |ein Test-
    |Text.

=back

=cut

# -----------------------------------------------------------------------------

sub removeIndent {
    # @_: $strObj -or- $class,$ref -or- $class,$str

    shift unless ref $_[0]; # Klassenmethode => Klassenname entfernen
    my $ref = ref $_[0]? shift: \(my $str = shift);

    my $addNL = 0;
    if (@_) {
        Blog::Base::Misc->argExtract(\@_,
            -addNL=>\$addNL,
        );
    } 

    if (defined $$ref) {
        $$ref =~ s/^\n+//;
        $$ref =~ s/\s+$//;
        if ($addNL && $$ref) {
            $$ref .= "\n";
        }

        # Wir brauchen uns nur mit dem String befassen, wenn
        # das erste Zeichen ein Whitespacezeichen ist. Wenn dies nicht
        # der Fall ist, existiert keine Einrückung.

        if ($$ref =~ /^\s/) {
            my $ind;
            while ($$ref =~ /^([ \t]*)(.?)/gm) {
                next if length $2 == 0; # leere Zeile oder nur Whitespace
                $ind = $1 if !defined $ind || length $1 < length $ind;
                last if !$ind;
            }
            $$ref =~ s/^$ind//gm if $ind;
        }
    }

    $ref == \$str? return $str: return;
}

# -----------------------------------------------------------------------------

=head2 strip() - Entferne Whitespace

=head3 Synopsis

    $strObj->strip;
    $class->strip(\$str);
    $str = $class->strip($str);

=head3 Description

Entferne Whitespace am Anfang und am Ende der Zeichenkette.

=cut

# -----------------------------------------------------------------------------

sub strip {
    # @_: $strObj -or- $class,$ref -or- $class,$str

    if (@_ == 2) {
        shift;
    }
    if (ref $_[0]) {
        my $ref = shift;
        $$ref =~ s/^\s+//g;
        $$ref =~ s/\s+$//g;
        return;
    }

    my $str = shift;
    $str =~ s/^\s+//g;
    $str =~ s/\s+$//g;
    return $str;
}

# -----------------------------------------------------------------------------

=head2 toHtml() - Wandele Text in HTML

=head3 Synopsis

    $strObj->toHtml(@opt);
    $class->toHtml(\$str,@opt);
    $html = $class->toHtml($str,@opt);

=head3 Options

=over 4

=item -preserveWS => $bool (Default: 0)

Sorge dafür, das der Leerraum in $str so gut wie möglich erhalten bleibt.
Die Leerzeichen am Anfang jeder Zeile in &nbsp; gewandelt und danach
in Folgen von mehreren Leerzeichen jedes zweite.

=item -wrap => $bool (Default: 0)

Die Option modifiziert das Verhalten im Falle von -preserveWS=>1,
indem alle Leerzeichen in $str in &nbsp; umgewandelt werden, d.h. der
resultierende HTML-Code wird vom Browser nicht umbrochen.

=back

=head3 Description

Wandele Zeichenkette in HTML, so dass diese in eine HTML-Seite
eingesetzt werden kann.

Per Default werden nur die Zeichen '&', '<' und '>' durch Entities ersetzt.

Im Falle von -preserveWS=>1 wird zusätzlich der Leerraum zu reproduzieren
versucht, entweder exakt oder mit erlaubten Umbrüchen -wrap=>1

Wird eine Referenz auf den Text übergeben, wird dieser "in place"
manipuliert und kein Wert zurückgegeben.

=cut

# -----------------------------------------------------------------------------

sub toHtml {
    # @_: $strObj -or- $class,$ref -or- $class,$str

    my ($ref,$str);
    if (@_ == 2) {
        shift;
    }
    if (ref $_[0]) {
        $ref = shift;
    }
    else {
        $ref = \($str = shift);
    }

    # Optionen

    my $preserveWS = 0;
    my $wrap = 0;

    if (@_) {
        Blog::Base::Misc->argExtract(\@,
            -preserveWS=>0,
            -wrap=>0,
        );
    }

    $$ref =~ s/&/&amp;/g;
    $$ref =~ s/</&lt;/g;
    $$ref =~ s/>/&gt;/g;

    if ($preserveWS) {
        $$ref =~ s/\t/    /g;

        if ($wrap) {
            $$ref =~ s/^( +)/'&nbsp;' x length($1)/emg;
            $$ref =~ s/  / &nbsp;/g;
        } else {
            $$ref =~ s/ /&nbsp;/g;
        }

        $$ref =~ s/\n/<BR>\n/g;
    }

    if (defined $str) {
        return $$ref;
    }
    return;
}

# -----------------------------------------------------------------------------

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2009-2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
