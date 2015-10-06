package Blog::Base::Array;
use base qw/Blog::Base::Object/;

use strict;
use warnings;
use utf8;

use Blog::Base::Scalar;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Array - Array-Klasse

=head1 BASE CLASS

L<Blog::Base::Object|../Blog::Base/Object.html>

=head1 SYNOPSIS

    my $arr = Blog::Base::Array->new(qw/d g j a/);
    my $n = $arr->size; # 4

- oder in normaler Perl-Syntax -

    my $arr = bless [qw/d g j a/],'Blog::Base::Array';
    my $n = scalar @$arr; # 4

=head1 DESCRIPTION

Die Klasse stellt eine objektorientierte Hülle für einen
gewöhnliches Perl-Array dar. Ein normales Perl-Array, auf Blog::Base::Array
geblesst, wird zu einem Objekt der Klasse Blog::Base::Array.
Dieses kann wahlweise wie jedes andere Perl-Array angesprochen werden,
oder über die Methoden der Klasse.

=head2 Objektinstanziierung

Verschiedene, äquivalente Möglichkeiten der Objektinstanziierung:

    my $arr = Blog::Base::Array->new(qw/a b c d/);

oder

    my @arr = qw/a b c d/;
    my $arr = Blog::Base::Array->bless(\@arr);

oder

    my @arr = qw/a b c d/;
    my $arr = bless \@arr,'Blog::Base::Array';

oder

    my $arr = bless [qw/a b c d/],'Blog::Base::Array';

=head2 Vorteile

Vorteile der Verwendung der Klasse Blog::Base::Array gegenüber einem
ungeblessten Perl-Array:

=over 2

=item o

mehr Array-Operationen

=item o

vererbbare Schnittstelle

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $arr = $class->new(@arr);

=head4 Description

Instantiiere ein Array-Objekt, initialisiere es auf die Werte in @arr
und liefere eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = CORE::shift;
    return bless [@_],$class;
}

# -----------------------------------------------------------------------------

=head2 Dump/Restore

=head3 dump() - Erzeuge externe Repräsentation

=head4 Synopsis

    $str = $arr->dump;
    $str = $arr->dump($colSep);
    
    $str = $class->dump(\@arr);
    $str = $class->dump(\@arr,$colSep);

=head4 Alias

asString()

=head4 Description

Liefere eine einzeilige, externe Repräsentation für Array $arr bzw. @arr
in dem Format

    elem0|elem1|...|elemN

Die Array-Elemente werden durch "|" (bzw. $colSep) getrennt. In den
Elementen werden folgende Wandlungen vorgenommen:

    undef    -> '' (undef wird zu Leerstring)
    \        -> \\ (Backslash wird verdoppelt)
    $colSep  -> \!
    LF       -> \n
    CR       -> \r

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    my $colSep = CORE::shift || '|';

    my $regex = qr/\Q$colSep/;

    my $str;
    for (@$self) {
        $_ = '' if !defined;
        s/\\/\\\\/g;
        s/$regex/\\!/g;
        s/\n/\\n/g;
        s/\r/\\r/g;

        $str .= $colSep if defined $str;
        $str .= $_;
    }
    $str = '' if !defined $str;

    return $str;
}

{
    no warnings 'once';
    *asString = \&dump;
}

# -----------------------------------------------------------------------------

=head3 restore() - Wandele externe Array-Repräsentation in Array

=head4 Synopsis

    $arr = $class->restore($str,$colSep);
    $arr = $class->restore($str);

=head4 Description

Wandele einzeilige, externe Array-Repräsentation (siehe Methode dump())
in ein Array-Objekt und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

sub restore {
    my $class = CORE::shift;
    my $str = CORE::shift;
    my $colSep = CORE::shift || '|';

    my $f = sub {
        return '\\' if $_[0] eq '\\';
        return $colSep if $_[0] eq '!';
        return "\n" if $_[0] eq 'n';
        return "\r" if $_[0] eq 'r';

        $class->throw(
            q{ARR-00001: Inkorrekte Array-Repräsentation},
            EscapeSequence=>"\\$_[0]",
        );
    };

    my @arr = split /\Q$colSep/,$str,-1;
    for (@arr) {
        s/\\(.)/$f->($1,$colSep)/ge;
    }

    return bless \@arr,$class;
}

# -----------------------------------------------------------------------------

=head2 Numerische Operationen

=head3 min() - Ermittele numerisches Minimum

=head4 Synopsis

    $x = $arr->min;
    $x = $class->min(\@arr);
    $x = $class->min(@arr);

=head4 Description

Ermittele die kleinste Zahl und liefere diese zurück.
Enthält $arr keine Elemente, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub min {
    my $self = CORE::shift;
    if (!ref $self) {
        # Klassenmethode: \@arr -or @arr
        $self = ref $_[0]? CORE::shift: \@_;
    }

    my $min;
    for my $x (@$self) {
        $min = $x if !defined $min || $x < $min;
    }

    return $min;
}

# -----------------------------------------------------------------------------

=head3 max() - Ermittele numerisches Maximum

=head4 Synopsis

    $x = $arr->max;
    $x = $class->max(\@arr);
    $x = $class->max(@arr);

=head4 Description

Ermittele die größte Zahl und liefere diese zurück.
Enthält $arr keine Elemente, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub max {
    my $self = CORE::shift;
    if (!ref $self) {
        # Klassenmethode: \@arr -or- @arr
        $self = ref $_[0]? CORE::shift: \@_;
    }

    my $max;
    for my $x (@$self) {
        $max = $x if !defined $max || $x > $max;
    }

    return $max;
}

# -----------------------------------------------------------------------------

=head3 minMax() - Ermittele numerisches Minimum und Maximum

=head4 Synopsis

    ($min,$max) = $arr->minMax;
    ($min,$max) = $class->minMax(\@arr);
    ($min,$max) = $class->minMax(@arr);

=head4 Description

Ermittele die kleinste und die größte Zahl und liefere die beiden Werte
zurück. Enthält $arr keine Elemente, wird jeweils C<undef> geliefert.

=cut

# -----------------------------------------------------------------------------

sub minMax {
    my $self = CORE::shift;
    if (!ref $self) {
        # Klassenmethode: \@arr -or @arr
        $self = ref $_[0]? CORE::shift: \@_;
    }

    my ($min,$max);
    for my $x (@$self) {
        $min = $x if !defined $min || $x < $min;
        $max = $x if !defined $max || $x > $max;
    }

    return ($min,$max);
}

# -----------------------------------------------------------------------------

=head3 meanValue() - Berechne Mittelwert

=head4 Synopsis

    $x = $arr->meanValue;
    $x = $class->meanValue(\@arr);

=head4 Description

Berechne das Arithmetische Mittel und liefere dieses
zurück. Enthält $arr keine Elemente, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub meanValue {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode

    return undef if !@$self;

    my $sum = 0;
    for my $x (@$self) {
        $sum += $x;
    }

    return $sum/@$self;
}

# -----------------------------------------------------------------------------

=head3 standardDeviation() - Berechne Standardabweichung

=head4 Synopsis

    $x = $arr->standardDeviation;

=head4 Description

Berechne die Standardabweichung und liefere diese zurück. Enthält
$arr keine Elemente, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub standardDeviation {
    my $self = CORE::shift;
    return undef if !@$self;
    return sqrt $self->variance;
}

# -----------------------------------------------------------------------------

=head3 variance() - Berechne Varianz

=head4 Synopsis

    $x = $arr->variance;

=head4 Description

Berechne die Varianz und liefere diese zurück. Enthält das Array
keine Elemente, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub variance {
    my $self = CORE::shift;

    return undef if !@$self;
    return 0 if @$self == 1;

    my $meanVal = $self->meanValue;

    my $sum = 0;
    for my $x (@$self) {
        $sum += ($meanVal-$x)**2;
    }

    return $sum/(@$self-1);
}

# -----------------------------------------------------------------------------

=head3 median() - Ermittele den Median

=head4 Synopsis

    $x = $arr->median;

=head4 Description

Ermittele den Median und liefere diesen zurück. Enthält das Array
keine Elemente, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub median {
    my $self = CORE::shift;

    my $size = @$self;
    if ($size == 0) {
        # Array enthält keine Elemente
        return undef;
    }

    my $arr = $self->copy->sort;
    my $idx = int $size/2;
    if ($size%2) {
        # Ungerade Anzahl Elemente. Wir liefern das
        # mittlere Element.
        return $arr->[$idx];
    }
    else {
        # Gerade Anzahl Elemente. Wir liefern den Mittelwert
        # der beiden mittleren Elemente.
        return ($arr->[$idx-1]+$arr->[$idx])/2;
    }
    
    # nie erreicht
}

# -----------------------------------------------------------------------------

=head2 Other

=head3 compare() - Vergleiche Array gegen anderes Array

=head4 Synopsis

    ($only1A,$only2A,$bothA) = $arr1->compare(\@arr2);
    ($only1A,$only2A,$bothA) = $class->compare(\@arr1,\@arr2);

=head4 Description

Vergleiche die Elemente der Arrays @$arr1 und @arr2 und liefere
Referenzen auf drei Arrays (Mengen) zurück:

=over 4

=item $only1A:

Referenz auf die Liste der Elemente, die nur in @arr1
enthalten sind.

=item $only2A:

Referenz auf die Liste der Elemente, die nur in @arr2
enthalten sind.

=item $bothA:

Referenz auf die Liste der Elemente, die sowohl in @arr1
als auch in @arr2 enthalten sind.

=back

Die drei Ergebnislisten sind als Mengen zu sehen: Jedes Element taucht
in einer der drei Listen höchstens einmal auf, auch wenn es in den
Eingangslisten mehrfach vorkommt.

=head4 Example

=over 2

=item *

Verwalte Objekte auf Datenbank

Die Funktion ist nützlich, wenn eine Menge von Objekten
auf einer Datenbank identisch zu einer Menge von Elementen
einer Benutzerauswahl gehalten werden soll. Die Objekte werden
durch ihre Objekt-Id identifiziert. Die Liste der
Datenbankobjekte sei @idsDb und die Liste der Objekte der
Benutzerauswahl sei @idsUser. Dann liefert der Aufruf

    ($idsNew,$idsDel) = $idsUserA->compare(\@idsDb);

mit @$idsNew die Liste der zur Datenbank hinzuzufügenden Objekte und
mit @$idsDel die Liste der von der Datenbank zu entfernenden Objekte.
Die Liste der identischen Objekte wird hier nicht benötigt.

=item *

Prüfe, ob zwei Arrays die gleichen Elemente enthalten

Prüfe, ob zwei Arrays die gleichen Elemente enthalten, aber nicht
unbedingt in der gleichen Reihenfolge:

    ($only1,$only2) = $arr1->compare(\@arr2);
    if (!@$only1 && !@$only2) {
        # @$arr1 und @$arr2 enthalten die gleichen Elemente
    }

=back

=cut

# -----------------------------------------------------------------------------

sub compare {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    my $arr2 = CORE::shift;

    # Hash mit den Elementen von @$self

    my (%arr1,%arr2);
    @arr1{@$self} = (1) x @$self;
    @arr2{@$arr2} = (1) x @$arr2;

    my (%seen,@arr1,@arr2,@arr);
    for my $e (@$self,@$arr2) {
        next if $seen{$e}++;
        push @{$arr1{$e}? $arr2{$e}? \@arr: \@arr1: \@arr2},$e;
    }

    my $class = ref $self;

    return (
        bless(\@arr1,$class),
        bless(\@arr2,$class),
        bless(\@arr,$class),
    );
}

# -----------------------------------------------------------------------------

=head3 copy() - Kopiere Array

=head4 Synopsis

    $newArr = $arr->copy;
    $newArr = $class->copy(\@arr);

=head4 Description

Kopiere die Elemente des Array in ein neues Array und liefere eine
Referenz auf das neue Array zurück.

=cut

# -----------------------------------------------------------------------------

sub copy {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    my @arr = @$self;
    return bless \@arr,ref($self);
}

# -----------------------------------------------------------------------------

=head3 delete() - Lösche Vorkommen eines Elements

=head4 Synopsis

    $bool = $arr->delete($elem);
    $bool = $class->delete($arr,$elem);

=head4 Description

Lösche das erste Vorkommen von Element $elem aus Array $arr.  Der
Vergleich wird mit dem Operator eq vorgenommen. Die Funktion
liefert "wahr", wenn das Element gefunden und gelöscht wurde,
andernfalls "falsch".

=cut

# -----------------------------------------------------------------------------

sub delete {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    my $elem = CORE::shift;

    for (my $i = 0; $i < @$self; $i++) {
        if ($self->[$i] eq $elem) {
            splice @$self,$i,1;
            return 1;
        }
    }

    return 0;
}

# -----------------------------------------------------------------------------

=head3 eq() - Vergleiche Arrays per eq

=head4 Synopsis

    $bool = $arr->eq(\@arr);
    $bool = $class->eq(\@arr1,\@arr2);

=head4 Description

Vergleiche @arr1 und @arr2 elementweise per eq. Liefere "wahr",
wenn alle Elemente identisch sind, andernfalls "falsch".

Sind zwei Elemente undef, gelten sie als identisch.

=cut

# -----------------------------------------------------------------------------

sub eq {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    my $arr = CORE::shift;

    return 0 if $#$self != $#$arr;

    my $l = @$self;
    for (my $i = 0; $i < $l; $i++) {
        my $val1 = $self->[$i];
        my $val2 = $arr->[$i];

        # Wenn einer der Werte undefiniert ist,
        # können wir nicht mit den normalen
        # Operatoren vergleichen

        if (!defined $val1 || !defined $val2) {
            return 0 if defined $val1 || defined $val2;
            next;
        }
        return 0 if $val1 ne $val2;
    }

    return 1;
}

# -----------------------------------------------------------------------------

=head3 exists() - Teste, ob Element existiert

=head4 Synopsis

    $bool = $arr->exists($str);
    $bool = $class->exists(\@arr,$str);

=head4 Description

Durchsuche $arr nach Element $str. Kommt $str in $arr vor,
liefere "wahr", sonst "falsch". Vergleichsoperator ist eq.

=cut

# -----------------------------------------------------------------------------

sub exists {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    my $str = CORE::shift;

    for (my $i = 0; $i < @$self; $i++) {
        if ($self->[$i] eq $str) {
            return 1;
        }
    }

    return 0;
}

# -----------------------------------------------------------------------------

=head3 extractPair() - Extrahiere Paar, liefere Wert

=head4 Synopsis

    $val = $arr->extractPair($key);
    $val = $class->extractPair(\@arr,$key);

=head4 Description

Durchsuche $arr paarweise nach Element $key. Kommt es vor, entferne
es und das nächste Element und liefere letzteres zurück.
Vergleichsoperator ist eq.

=cut

# -----------------------------------------------------------------------------

sub extractPair {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    my $key = CORE::shift;

    for (my $i = 0; $i < @$self; $i += 2) {
        if ($self->[$i] eq $key) {
            my $val = $self->[$i+1];
            splice @$self,$i,2;
            return $val;
        }
    }

    return undef;
}

# -----------------------------------------------------------------------------

=head3 findPairValue() - Liefere Wert zu Schlüssel

=head4 Synopsis

    $val = $arr->findPairValue($key);
    $val = $class->findPairValue(\@arr,$key);

=head4 Returns

Wert oder C<undef>

=head4 Description

Durchsuche $arr paarweise nach Element $key. Kommt es vor, liefere
dessen Wert. Kommt es nicht vor, liefere C<undef>.
Vergleichsoperator ist eq.

=cut

# -----------------------------------------------------------------------------

sub findPairValue {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    my $key = CORE::shift;

    for (my $i = 0; $i < @$self; $i += 2) {
        if ($self->[$i] eq $key) {
            return $self->[$i+1];
        }
    }

    return undef;
}

# -----------------------------------------------------------------------------

=head3 select() - Selektiere Array-Elemente

=head4 Synopsis

    $arr2|@arr2 = $arr->select($test);
    $arr2|@arr2 = $class->select(\@arr,$test);

=head4 Description

Wende Test $test auf alle Arrayelemente an und liefere ein Array mit
den Elementen zurück, die den Test erfüllen.

Folgende Arten von Tests sind möglich:

=over 4

=item Regex qr/REGEX/

=back

Wende Regex-Test auf jedes Element an.

=over 4

=item Code-Referenz sub { CODE }

=back

Wende Subroutine-Test auf jedes Element an. Als erster Parameter wird
das zu testende Element übergeben. Die Subroutine muss einen
boolschen Wert liefern.

=cut

# -----------------------------------------------------------------------------

sub select {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    my $test = CORE::shift;

    my @arr;
    if (Blog::Base::Scalar->isCodeRef($test)) {
        for (@$self) {
            push @arr,$_ if $test->($_);
        }
    }
    else {
        for (@$self) {
            push @arr,$_ if /$test/;
        }
    }

    return wantarray? @arr: bless \@arr,ref($self);
}

# -----------------------------------------------------------------------------

=head3 index() - Suche Element (vorwärts)

=head4 Synopsis

    $idx = $arr->index($str);
    $idx = $class->index(\@arr,$str);

=head4 Description

Durchsuche $arr vom Anfang her nach Element $str und liefere
dessen Index zurück. Vergleichsoperator ist eq. Kommt $str in
$arr nicht vor, liefere -1.

=cut

# -----------------------------------------------------------------------------

sub index {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    my $str = CORE::shift;

    for (my $i = 0; $i < @$self; $i++) {
        if ($self->[$i] eq $str) {
            return $i;
        }
    }

    return -1;
}

# -----------------------------------------------------------------------------

=head3 indexStrict() - Suche Element (vorwärts)

=head4 Synopsis

    $idx = $arr->indexStrict($str);

=head4 Description

Wie index(), nur dass eine Exception geworfen wird, wenn
das Element nicht gefunden wird.

=cut

# -----------------------------------------------------------------------------

sub indexStrict {
    my $self = CORE::shift;
    my $str = CORE::shift;

    my $idx = $self->index($str);
    if ($idx < 0) {
        $self->throw(
            q{ARR-00002: Element nicht gefunden},
            Element=>$str,
        );
    }

    return $idx;
}

# -----------------------------------------------------------------------------

=head3 join() - Konkateniere Elemente

=head4 Synopsis

    $str = $arr->join($del);
    $str = $class->join(\@arr,$del);

=head4 Description

Konkateniere die Elemente mit Trennzeichen $del und liefere
die resultierende Zeichenkette zurück.

=cut

# -----------------------------------------------------------------------------

sub join {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    my $del = CORE::shift;

    return CORE::join $del,@$self;
}

# -----------------------------------------------------------------------------

=head3 last() - Liefere letztes Element

=head4 Synopsis

    $e = $arr->last;
    $e = $class->last(\@arr);

=cut

# -----------------------------------------------------------------------------

sub last {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    return @{$self}[-1];
}

# -----------------------------------------------------------------------------

=head3 map() - Wende map auf Arrayelemente an

=head4 Synopsis

    $arr->map($sub);
    $class->map($arr,$sub);
    
    $arr2 = $arr->map($sub);
    $arr2 = $class->map($arr,$sub);
    
    @arr = $arr->map($sub);
    @arr = $class->map($arr,$sub);

=head4 Example

=over 2

=item *

Manipulation "in place"

    my $arr = Array->new(1..5);
    $arr->map(sub { $_[0]+1 });
    # @$arr => (2, 3, 4, 5, 6)

=item *

Kopie liefern (Perl Array)

    my $arr = Array->new(1..5);
    my @arr = $arr->map(sub { $_[0]+1 });
    # @arr => (2, 3, 4, 5, 6)

=item *

Kopie liefern (Array Objekt)

    my $arr1 = Array->new(1..5);
    my $arr2 = $arr1->map(sub { $_[0]+1 });
    # @$arr2 => (2, 3, 4, 5, 6)

=back

=cut

# -----------------------------------------------------------------------------

sub map {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    my $code = CORE::shift;

    if (!defined wantarray) {
        @$self = eval { map $code->($_),@$self };
        return;
    }
    my @arr = eval { map $code->($_),@$self };

    return wantarray? @arr: bless \@arr,ref($self);
}

# -----------------------------------------------------------------------------

=head3 maxLength() - Länge des längsten Elements

=head4 Synopsis

    $n = $arr->maxLength;
    $n = $class>maxLength(\@arr);

=head4 Description

Ermittele die Länge des längsten Arrayelements und liefere diese
zurück.

=cut

# -----------------------------------------------------------------------------

sub maxLength {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode

    my $max = 0;
    for (@$self) {
        my $l = length;
        $max = $l if $l > $max;
    }

    return $max;
}

# -----------------------------------------------------------------------------

=head3 pick() - Liefere Elemente nach Position heraus

=head4 Synopsis

    $arr2 | @arr = $arr->pick($n,$m);
    $arr2 | @arr = $arr->pick($n);

=head4 Description

Picke jedes $n-te Array-Element ab Positon $m heraus, bilde aus diesen
Elementen ein neues Array und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

sub pick {
    my $self = CORE::shift;
    my $n = CORE::shift;
    my $m = CORE::shift || 0;

    my @arr;
    for (my $i = $m; $i < @$self; $i += $n) {
        CORE::push @arr,$self->[$i];
    }

    return wantarray? @arr: bless \@arr,ref($self);
}

# -----------------------------------------------------------------------------

=head3 pop() - Entferne Element am Ende

=head4 Synopsis

    $e = $arr->pop;
    $e = $class->pop(\@arr);

=head4 Description

Entferne letztes Element am Ende des Array. Die Methode liefert
das Element zurück.

=cut

# -----------------------------------------------------------------------------

sub pop {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode

    return CORE::pop @$self;
}

# -----------------------------------------------------------------------------

=head3 push() - Füge Elemente zum Ende des Array hinzu

=head4 Synopsis

    $arr->push(@e);
    $class->push(\@arr,@e);

=head4 Returns

Nichts

=cut

# -----------------------------------------------------------------------------

sub push {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    # @_: @e

    CORE::push @$self,@_;
    return;
}

# -----------------------------------------------------------------------------

=head3 resizeTo() - Ändere Arraygröße

=head4 Synopsis

    $arr->resizeTo($n);
    $class->resizeTo(\@arr,$n);

=head4 Description

Ändere die Arraygröße auf $n Elemente. Die Methode liefert keinen
Wert zurück.

Ein Array kann vergrößert oder verkleinert werden.

=cut

# -----------------------------------------------------------------------------

sub resizeTo {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    my $n = CORE::shift;

    $#$self = $n-1;
    return;
}

# -----------------------------------------------------------------------------

=head3 rindex() - Suche Element (rückwärts)

=head4 Synopsis

    $idx = $arr->rindex($str);
    $idx = $class->rindex(\@arr,$str);

=head4 Description

Durchsuche $arr vom Ende her nach Element $str und liefere
dessen Index zurück. Vergleichsoperator ist eq. Kommt $str in
$arr nicht vor, liefere -1.

=cut

# -----------------------------------------------------------------------------

sub rindex {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    my $str = CORE::shift;

    for (my $i = $#$self; $i >= 0; $i--) {
        if ($self->[$i] eq $str) {
            return $i;
        }
    }

    return -1;
}

# -----------------------------------------------------------------------------

=head3 set() - Setze Array-Elemente

=head4 Synopsis

    $arr->set(@new);
    $class->set(\@arr,@new);

=head4 Description

Setze die Array-Elemente auf die Elemente des Array @new.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub set {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    return @$self = @_;
}

# -----------------------------------------------------------------------------

=head3 shift() - Entferne erstes Element

=head4 Synopsis

    $e = $arr->shift;
    $e = $class->shift(\@arr);

=head4 Description

Entfere erstes Element des Array und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

sub shift {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    return CORE::shift(@$self);
}

# -----------------------------------------------------------------------------

=head3 shuffle() - Mische Elemente

=head4 Synopsis

    $arr | @arr = $arr->shuffle;

=head4 Description

Mische die Elemente des Array, d.h. bringe sie in eine
zufällige Reihenfolge.

Im Skalarkontext mische die Elemente "in place" und liefere
die Array-Referenz zurück (Method-Chaining).

Im Listkontext liefere die Elemente gemischt zurück, ohne
den Inhalt des Array zu verändern.

=cut

# -----------------------------------------------------------------------------

sub shuffle {
    my $self = CORE::shift;

    if (wantarray) {
        $self = $self->copy;
    }

    for (my $i = @$self; $i--;) {
        my $j = rand($i+1);
        next if $i == $j;
        @$self[$i,$j] = @$self[$j,$i];
    }

    return wantarray? @$self: $self;
}

# -----------------------------------------------------------------------------

=head3 size() - Anzahl der Elemente

=head4 Synopsis

    $n = $arr->size;
    $n = $class->size(\@arr);

=head4 Description

Liefere die Anzahl der Elemente des Array.

=cut

# -----------------------------------------------------------------------------

sub size {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    return scalar @$self;
}

# -----------------------------------------------------------------------------

=head3 sort() - Sortiere Elemente alphanumerisch

=head4 Synopsis

    $arr | @arr = $arr->sort;
    $arr | @arr = $class->sort(\@arr);

=head4 Description

Sortiere die Elemente des Array alphanumerisch.

Im Skalarkontext sortiere die Elemente "in place" und liefere
die Array-Referenz zurück (Method-Chaining).

Im Listkontext liefere die Elemente sortiert zurück, ohne
den Inhalt des Array zu verändern.

=cut

# -----------------------------------------------------------------------------

sub sort {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode

    if (wantarray) {
        return sort @$self;
    }

    @$self = sort @$self;
    return $self;
}

# -----------------------------------------------------------------------------

=head3 sortNumic() - Sortiere Elemente numerisch

=head4 Synopsis

    $arr | @arr = $arr->sortNumic;
    $arr | @arr = $class->sortNumic(\@arr);

=head4 Alias

sortNum()

=head4 Description

Sortiere die Elemente des Array numerisch.

Im Skalarkontext sortiere die Elemente "in place" und liefere
die Array-Referenz zurück (Method-Chaining).

Im Listkontext liefere die Elemente sortiert zurück, ohne
den Inhalt des Array zu verändern.

=cut

# -----------------------------------------------------------------------------

sub sortNumic {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode

    if (wantarray) {
        return sort { $a <=> $b } @$self;
    }

    @$self = sort { $a <=> $b } @$self;
    return $self;
}

{
    no warnings 'once';
    *sortNum = \&sortNumic;
}

# -----------------------------------------------------------------------------

=head3 splice() - Entferne/ersetze Arrayelemente

=head4 Synopsis

    @arr | $last = $arr->splice($offset,$length,\@arr);
    @arr | $last = $arr->splice($offset,$length);
    @arr | $last = $arr->splice($offset);
    @arr | $last = $arr->splice;

=head4 Description

Ersetze die Elemente, die mit $offset und $length spezifiziert
sind, durch die Elemente in @arr. Im Array-Kontext liefere alle
entfernten Element zurück, im Skalarkontext nur das letzte.

Detaillierte Doku:

    $ perldoc -f splice

=cut

# -----------------------------------------------------------------------------

sub splice {
    my ($self,$offset,$length,$arr) = @_;

    if (@_ == 1) {
        return CORE::splice @$self;
    }
    elsif (@_ == 2) {
        return CORE::splice @$self,$offset;
    }
    elsif (@_ == 3) {
        return CORE::splice @$self,$offset,$length;
    }
    else {
        return CORE::splice @$self,$offset,$length,@$arr;
    }
}

# -----------------------------------------------------------------------------

=head3 unique() - Entferne Doubletten

=head4 Synopsis

    $arr->unique;
    $class->unique(\@arr);

=head4 Alias

deleteDoublets()

=head4 Description

Entferne alle mehrfachen Vorkommen eines Elements. Das erste
Vorkommen bleibt erhalten. Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub unique {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    my $str = CORE::shift;

    my %seen;
    for (my $i = 0; $i < @$self; $i++) {
        if ($seen{$self->[$i]}++) {
            CORE::splice @$self,$i--,1;
        }
    }

    return;
}

{
    no warnings 'once';
    *deleteDoublets = \&unique;
}

# -----------------------------------------------------------------------------

=head3 unshift() - Füge Element am Anfang hinzu

=head4 Synopsis

    $arr->unshift($e);
    $class->unshift(\@arr,$e);

=head4 Description

Füge Element $e am Anfang des Array hinzu. Die Methode liefert keinen
Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub unshift {
    my $self = CORE::shift;
    $self = CORE::shift if !ref $self; # Klassenmethode
    my $e = CORE::shift;

    CORE::unshift @$self,$e;
    return;
}

# -----------------------------------------------------------------------------

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
