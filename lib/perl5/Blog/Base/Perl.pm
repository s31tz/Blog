package Blog::Base::Perl;
use base qw/Blog::Base::Object/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Perl - Erweiterte/Abgesicherte Perl-Operationen

=head1 BASE CLASS

L<Blog::Base::Object|../Blog::Base/Object.html>

=head1 DESCRIPTION

Die Klasse implementiert grundlegende Perl-Operationen, die
Erweiterungen darstellen und/oder durch Exception-Behandlung
abgesichert sind.

=head1 METHODS

=head2 I/O

=head3 autoFlush() - Aktiviere/Deaktiviere Pufferung auf Dateihandle

=head4 Synopsis

    $this->autoFlush($fh);
    $this->autoFlush($fh,$bool);

=head4 Description

Schalte Pufferung auf Dateihandle ein oder aus.

Der Aufruf ist äquivalent zu

    $oldFh = select $fh;
    $| = $bool;
    select $oldFh;

=head4 Example

    Blog::Base::Perl->autoFlush(*STDOUT);

=head4 See Also

perldoc -f select

=cut

# -----------------------------------------------------------------------------

sub autoFlush {
    my $class = shift;
    my $fh = shift;
    my $bool = @_? shift: 1;

    my $oldFh = CORE::select $fh;
    $ | = $bool;
    CORE::select $oldFh;

    return;
}

# -----------------------------------------------------------------------------

=head3 binmode() - Aktiviere Binärmodus oder setze Layer

=head4 Synopsis

    $class->binmode($fh);
    $class->binmode($fh,$layer);

=head4 Description

Schalte Filehandle $fh in Binärmodus oder setze Layer $layer.
Die Methode ist eine Überdeckung der Perl-Funktion binmode und prüft
deren Returnwert. Im Fehlerfall wirft die Methode eine Exception.

=head4 Example

    Blog::Base::Perl->binmode(*STDOUT,'utf-8');

=head4 See Also

perldoc -f binmode

=cut

# -----------------------------------------------------------------------------

sub binmode {
    my $class = shift;
    my $fh = shift;
    # @_: $layer

    my $r = @_? CORE::binmode($fh,$_[0]): CORE::binmode($fh);
    if (!defined $r) {
        $class->throw(
            q{FH-00012: binmode fehlgeschlagen},
            Errstr=>$!,
        );
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 print() - Schreibe auf Dateihandle

=head4 Synopsis

    Blog::Base::Perl->print($fh,@data);

=head4 Description

Schreibe Daten @data auf Dateihandle $fh. Die Methode ist eine
Überdeckung der Perl-Funktion print und prüft deren Returnwert.
Im Fehlerfall wirft die Methode eine Exception.

=head4 Example

    Blog::Base::Perl->print($fh,"Hello world\n");

=head4 See Also

perldoc -f print

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

=head2 Klassen/Packages

=head3 classExists() - Prüfe Existenz von Klasse/Package

=head4 Synopsis

    $bool = Blog::Base::Perl->classExists($class);

=head4 Alias

packageExists()

=head4 Description

Prüfe, ob die Perl-Klasse bzw. das Package $class in-memory
existiert, also von Perl bereits geladen wurde. Liefere I<wahr>,
wenn Klasse existiert, andernfalls I<falsch>.

=head4 Example

    Blog::Base::Perl->classExists('Blog::Base::Object');
    ==>
    1

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

=head3 use() - Lade Klasse per use

=head4 Synopsis

    Blog::Base::Perl->use($class,$sloppy);

=head4 Description

Lade Klasse $class per use. Im Fehlerfall wirft die Methdoe eine Exception.
Ist $sloppy wahr, wird keine Exception geworfen, sondern ein boolscher
Wert: 1 für erfolgreiche Ausführung, 0 für fehlgeschlagen. Die globale
Variable $@ gibt den Grund an.

=head4 See Also

loadClass()

=cut

# -----------------------------------------------------------------------------

sub use {
    my ($class,$useClass,$sloppy) = @_;

    eval "CORE::use $useClass ()";
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

=head3 loadClass() - Lade Klasse, falls ungeladen

=head4 Synopsis

    Blog::Base::Perl->loadClass($class);

=head4 Description

Lade Klasse $class. Im Unterschied zu Methode use() wird die Moduldatei
nur zu laden versucht, wenn es den Namensraum (Package) der
Klasse noch nicht gibt.

=head4 Example

    Blog::Base::Perl->loadClass('My::Application');

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

=head2 Suchpfade

=head3 basicIncPaths() - Liefere die grundlegenden Modul-Suchpfade

=head4 Synopsis

    @paths|$pathA = Blog::Base::Perl->basicIncPaths;

=head4 Description

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

    $ PERLLIB= PERL5LIB= perl -le 'print join "\n",@INC'

=head4 Example

    Blog::Base::Perl->basicIncPaths;
    ==>
    /etc/perl
    /usr/local/lib/x86_64-linux-gnu/perl/5.20.2
    /usr/local/share/perl/5.20.2
    /usr/lib/x86_64-linux-gnu/perl5/5.20
    /usr/share/perl5
    /usr/lib/x86_64-linux-gnu/perl/5.20
    /usr/share/perl/5.20
    /usr/local/lib/site_perl
    .

=cut

# -----------------------------------------------------------------------------

my @Paths;

sub basicIncPaths {
    my $class = shift;

    if (!@Paths) {
        my $cmd = qq|PERLLIB= PERL5LIB= $^X -e 'print join "\n",\@INC'|;
        @Paths = split /\n/,qx/$cmd/;
    }

    return wantarray? @Paths: \@Paths;
}

# -----------------------------------------------------------------------------

=head3 additionalIncPaths() - Liefere die ergänzten Modul-Suchpfade

=head4 Synopsis

    @paths|$pathA = Blog::Base::Perl->additionalIncPaths;

=head4 Description

Liefere alle Suchpfade, die über die grundlegenden Suchpfade
hinausgehen.

=head4 See Also

basicIncPaths()

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

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2011-2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
