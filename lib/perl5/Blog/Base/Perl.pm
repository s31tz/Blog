package Blog::Base::Perl;
use base qw/Blog::Base::Object/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Perl - Perl-Operationen

=head1 BASE CLASS

Blog::Base::Object

=head1 DESCRIPTION

Die Methoden der Klasse implementieren Perl-Operationen mit
Fehlerbehandlung. Im Fehlerfall werfen diese eine Exception.

=head1 METHODS

=head2 autoflush() - Aktiviere Autoflush auf Dateihandle

=head3 Synopsis

    Blog::Base::Perl->autoflush($fh);
    Blog::Base::Perl->autoflush($fh,$bool);

=head3 Returns

Die Methode liefert keinen Wert zurück.

=head3 Description

Der Aufruf ohne Parameter ist äquivalent zu

    $oldFh = select($fh);
    $| = 1;
    select($oldFh);

=head3 Example

    Blog::Base::Perl->autoflush(*STDOUT);

=cut

# -----------------------------------------------------------------------------

sub autoflush {
    my $class = shift;
    my $fh = shift;
    my $bool = @_? shift: 1;

    my $oldFh = CORE::select $fh;
    $ | = $bool;
    CORE::select $oldFh;

    return;
}

# -----------------------------------------------------------------------------

=head2 binmode() - Schalte Filehandle in Binärmodus

=head3 Synopsis

    $class->binmode($fh);
    $class->binmode($fh,$layer);

=head3 Description

Schalte Filehandle $fh in Binärmodus oder setze Layer $layer. Genaue
Funktionsbeschreibung siehe Perl-Dokumentation (perldoc -f binmode).

=cut

# -----------------------------------------------------------------------------

sub binmode {
    my $class = shift;
    my $fh = shift;
    # @_: $layer

    my $r = @_? CORE::binmode($fh,$_[0]): CORE::binmode($fh);
    if (!defined $r) {
        $class->throw(q{FH-00012: binmode fehlgeschlagen},Errstr=>$!);
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 classExists() - Prüfe, ob Klasse/Package existiert

=head3 Synopsis

    $bool = Blog::Base::Perl->classExists($class);

=head3 Alias

packageExists()

=head3 Returns

Liefere I<wahr>, wenn Klasse existiert, andernfalls I<falsch>.

=head3 Description

Prüfe, ob Perl-Klasse/Package $class existiert.

=cut

# -----------------------------------------------------------------------------

sub classExists {
    my ($class,$testClass) = @_;
    no strict 'refs';
    return defined *{"$testClass\::"}? 1: 0;
}

{
    no warnings 'once';
    *packageExists = \&classExists;
}

# -----------------------------------------------------------------------------

=head2 additionalIncPaths() - Liefere die ergänzten Suchpfade für Module

=head3 Synopsis

    @paths|$pathA = Blog::Base::Perl->additionalIncPaths;

=head3 Description

Liefere alle Suchpfade, die über die grundlegenden Suchpfade
(siehe basicIncPaths()) hinausgehen.

=cut

# -----------------------------------------------------------------------------

sub additionalIncPaths {
    my $class = shift;

    my %path;
    @path{@INC} = (1) x @INC;
    for ($class->basicIncPaths) {
        delete $path{$_};
    }
    my @paths = keys %path;

    return wantarray? @paths: \@paths;
}

# -----------------------------------------------------------------------------

=head2 basicIncPaths() - Liefere die grundlegenden Suchpfade für Module

=head3 Synopsis

    @paths|$pathA = Blog::Base::Perl->basicIncPaths;

=head3 Description

Liefere die Liste der I<anfänglichen> Suchpfade des aktuell laufenden
Perl-Interpreters. Ergänzungen durch

=over 2

=item *

-II<path>

=item *

PERLLIB

=item *

PERL5LIB

=item *

use lib (I<@paths>)

=item *

usw.

=back

sind I<nicht> enthalten.

Die Liste entspricht dem Ergebnis des Aufrufs

    $ PERLLIB= PERL5LIB= perl -le 'print join "\n",\@INC'

=cut

# -----------------------------------------------------------------------------

sub basicIncPaths {
    my $class = shift;

    my $cmd = qq|PERLLIB= PERL5LIB= $^X -e 'print join "\n",\@INC'|;
    my @paths = split /\n/,qx/$cmd/;

    return wantarray? @paths: \@paths;
}

# -----------------------------------------------------------------------------

=head2 loadClass() - Lade Klasse

=head3 Synopsis

    Blog::Base::Perl->loadClass($class);

=head3 Returns

Die Methode liefert keinen Wert zurück.

=head3 Description

Lade Klasse $class. Im Unterschied zu Methode use() wird die Moduldatei
nur zu laden versucht, wenn es den Namensraum (Package) der
Klasse noch nicht gibt.

=cut

# -----------------------------------------------------------------------------

sub loadClass {
    my ($class,$useClass) = @_;

    if (!$class->classExists($useClass)) {
        $class->use($useClass);
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 print() - Schreibe Daten auf Dateihandle

=head3 Synopsis

    Blog::Base::Perl->print($fh,@data);

=head3 Description

Schreibe Daten @data auf Dateihandle $fh. Die Methode liefert
keinen Wert zurück.

=head3 Example

Schreibe Zeichenkette nach STDOUT:

    Blog::Base::Perl->print(*STDOUT,"Hello world\n");

=cut

# -----------------------------------------------------------------------------

sub print {
    my $class = shift;
    my $fh = shift;
    # @_: @data

    # Wir unterdrücken Warnungen auf STDERR, die z.B. auftreten,
    # wenn die Handle nicht geöffnet ist. Solche Fehler generieren
    # hier sowieso eine Exception.
    no warnings;

    unless (CORE::print $fh @_) {
        $class->throw(
            q{PERL-00002: print fehlgeschlagen},
            Errstr=>$!,
        );
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 use() - Lade Klasse per use

=head3 Synopsis

    Blog::Base::Perl->use($class,$sloppy);

=head3 Description

Lade Klasse $class per use. Im Fehlerfall wird eine Exception geworfen.
Ist $sloppy wahr, wird keine Exception geworfen sondern ein boolscher
Wert: 1 für erfolgreiche Ausführung, 0 für fehlgeschlagen. Die globale
Variable $@ gibt den genauen Grund an.

=head3 See Also

=over 2

=item *

loadClass()

=back

=cut

# -----------------------------------------------------------------------------

sub use {
    my ($class,$useClass,$sloppy) = @_;

    eval "use $useClass ()";
    if ($@) {
        $@ =~ s/ at .*//s; # unnütze/störende Information abschneiden
        if ($sloppy) {
            return 0;
        }
        $class->throw(
            q{PERL-00001: use fehlgeschlagen},
            Class=>$useClass,
            Error=>$@,
        );
    }

    return 1;
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
