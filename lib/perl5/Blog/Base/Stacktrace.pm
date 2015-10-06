package Blog::Base::Stacktrace;

use strict;
use warnings;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Stacktrace - Generiere und visualisiere einen Stacktrace

=head1 SYNOPSIS

    use Blog::Base::Stacktrace;
    
    my $st = Blog::Base::Stacktrace->new; # generiere Stacktrace
    print $st->asString,"\n";       # visualisiere Stacktrace
    
    -or-
    
    print Blog::Base::Stacktrace->asString,"\n";  # in einem Aufruf

=head1 DESCRIPTION

Ein Objekt der Klasse Blog::Base::Stacktrace repräsentiert die Aufrufhierarchie
des laufenden Perl-Programms zum Zeitpunkt der Instanziierung des
Stacktrace-Objektes.

Die Klasse kann zum Debuggen verwendet werden oder bei der Erzeugung
von Exceptions.

Folgendes Beispielprogramm (test.pl)

     1: #!/usr/bin/env perl
     2: 
     3: use Blog::Base::Stacktrace;
     4: 
     5: sub a {
     6:     b();
     7: }
     8: 
     9: sub b {
    10:     c();
    11: }
    12: 
    13: sub c {
    14:     print Blog::Base::Stacktrace->asString,"\n";
    15: }
    16: 
    17: a();

erzeugt die Ausgabe

    main::a() [+17 ./test.pl]
      main::b() [+6 ./test.pl]
        main::c() [+10 ./test.pl]
          Blog::Base::Stacktrace::asString() [+14 ./test.pl]

Von oben nach unten gelesen gibt der Stacktrace die Hierarchie der
Subroutine-Aufrufe (= Methoden oder Funktionsaufrufe) in der
Aufrufreihenfolge wieder. Jede Zeile beschreibt einen Subroutine-Aufruf:

    main::a() [+17 ./test.pl]
    ^     ^     ^  ^
    |     |     |  +-- Datei, in der der Aufruf steht
    |     |     +-- Zeilennummer, an der der Aufruf in der Datei steht
    |     +-- Name der aufgerufenen Subroutine
    +-- Package, zu dem die Subroutine gehört

Die in eckigen Klammern genannte Quelltextposition kann bei
Aufruf von vi(1) oder less(1) benutzt werden, um unmittelbar auf die
entsprechende Zeile zu positionieren:

    $ vi +17 ./test.pl

bzw.

    $ less +17 ./test.pl

Der unterste Eintrag im Stacktrace ist der Aufruf des
Konstruktors new() oder der Methode asString(), wenn sie
als Klassenmethode gerufen wird. Sollen Stacktrace-Frames am
Ende weggelassen werden, kann dies durch Angabe des Parameters
$i erreicht werden.

=head1 METHODS

=head2 Instanziierung

=head3 new() - Konstruktor

=head4 Synopsis

    $st = $class->new;
    $st = $class->new($i);

=head4 Arguments

=over 4

=item $i (Default: 0)

Anzahl der Stackframes vom Ende des Stacktrace, die nicht
berücksichtigt werden. Ist $i == 0 (was der Default ist), werden
alle Frames berücksichtigt.

=back

=head4 Description

Instanziiere ein Stacktrace-Objekt und liefere eine Referenz auf diese
Objekt zurück. Das Stacktrace-Objekt repräsentiert die Aufruf-Hierarchie
des laufenden Perl-Programms zum Zeitpunkt der Instanziierung. Letztes
Element in der Hierarchie ist der Konstruktor-Aufruf. Soll der
Stacktrace vorher enden,

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $i = shift || 0;

    my @frames;
    while (my (undef,$file,$line,$sub) = caller $i++) {
        push @frames,[$file,$line,$sub];
    }

    return bless \@frames,$class;
}

# -----------------------------------------------------------------------------

=head2 Externe Repräsentation

=head3 asString() - Visualisiere Stacktrace-Objekt

=head4 Synopsis

    $str = $st->asString;
    $str = $class->asString($i);

=head4 Arguments

=over 4

=item $i (Default: 0)

Siehe new().

=back

=head4 Description

Visualisiere das Stacktrace-Objekt in Form einer Zeichenkette und liefere
diese zurück. Aufbau der Zeichenkette siehe Abschnitt DESCRIPTION.

=cut

# -----------------------------------------------------------------------------

sub asString {
    my $self = ref $_[0]? $_[0]: $_[0]->new(($_[1] || 0)+1);

    if (!ref $self) {
        my $i = shift || 0;
        $self = $self->new($i);
    }

    my $str = '';

    my $i = 0;
    for my $frame (reverse @$self) {
        my ($file,$line,$sub) = @$frame;
        $sub .= "()" if $sub ne '(eval)';
        $str .= sprintf "%s%s [+%s %s]\n",('  'x$i++),$sub,$line,$file;
    }
    chomp $str;

    return $str;
}

# -----------------------------------------------------------------------------

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2011-2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
