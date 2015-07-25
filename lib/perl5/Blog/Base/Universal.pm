package Blog::Base::Universal;

use strict;
use warnings;

use Blog::Base::Object;
use Blog::Base::Perl;
use Blog::Base::Array;
use Blog::Base::Misc;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Universal - Erweiterungen von UNIVERSAL

=head1 DESCRIPTION

FIXME: Diese Klasse auflösen und auf andere Klassen verteilen,
die bei Bedarf geladen werden. Z.B. Blog::Base::Perl::Class einführen.

Die Klasse erweitert UNIVERSAL, indem sie sich als Basisklasse von
UNIVERSAL installiert.

=head2 Methodensuche

Perl durchläuft bei der Methodensuche erst die @ISA-Hierarchie,
depth-first, und als *letztes* die Klasse UNIVERSAL. Hat UNIVERSAL
@ISA definiert, werden auch diese Klassen durchlaufen.

Die Klasse bildet die Basisklasse für alle Klassen der
Blog::Base::Misc-Klassenbibliothek.

=head2 Klassenhierarchie

    Blog::Base::Universal
        <Methoden>
            ^
            |
        UNIVERSAL
            ^
            |
      Blog::Base::Object
        <Methoden>
         ^      ^
         |      |

    Blog::Base::Array    Blog::Base::Hash   ...
     <Methoden>      <Methoden>

=cut

# -----------------------------------------------------------------------------

# Klasse als Basisklasse von UNIVERSAL installieren
# Wir setzen uns an den Anfang, denn wir delegieren weiter
unshift @UNIVERSAL::ISA,'Blog::Base::Universal';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Packages

=head3 createPackage() - Erzeuge Package

=head4 Synopsis

    $pkg->createPackage;

=head4 Description

Erzeuge Package $pkg. Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub createPackage {
    my $pkg = shift;

    eval "package $pkg";
    if ($@) {
        Blog::Base::Object->throw(
            q{PERL-00002: Package-Erzeugung fehlgeschlagen},
            Package=>$pkg,
            Error=>$@,
        );
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 packageExists() - Prüfe, ob Package existiert

=head4 Synopsis

    $bool = $pkg->packageExists;

=head4 Alias

classExists()

=head4 Description

NOTIZ: Die Methode ist obsolet. Sie sollte durch Blog::Base::Perl::classExists
ersetzt werden.

Prüfe, ob Perl-Package $pkg existiert. Wenn ja, liefere "wahr",
andernfalls "falsch".

=cut

# -----------------------------------------------------------------------------

sub packageExists {
    my $pkg = shift;
    #no strict 'refs';
    #return defined *{"$pkg\::"}? 1: 0;
    return Blog::Base::Perl->packageExists($pkg);
}

{
    no warnings 'once';
    *classExists = \&packageExists;
}

# -----------------------------------------------------------------------------

=head3 packages() - Liefere Liste der existierenden Packages

=head4 Synopsis

    @arr|$arr = $pkg->packages;

=head4 Description

Liefere die Liste der existierenden Packages, die im Stash
des Package $pkg und darunter enthalten sind, einschließlich
Package $pkg selbst. Im Skalarkontext liefere eine Referenz
auf die Liste.

B<Anmerkung>

Packages entstehen zur Laufzeit. Die Liste der Packages wird
nicht gecacht, sondern mit jedem Aufruf neu ermittelt.

=head4 Example

=over 2

=item *

Liste aller Packages, die das Programm aktuell geladen hat:

    @arr = main->packages;

=item *

Liste in sortierter Form

    @arr = main->packages->sort;

=item *

Liste, eingeschränkt auf Packages, deren Name einen Regex erfüllt:

    @arr = main->packages->find(qr/patch\d+/);

=item *

Liste aller Packages unterhalb und einschließlich Package X:

    @arr = X->packages;

=back

=cut

# -----------------------------------------------------------------------------

sub packages {
    my $pkg = shift;

    # Wenn Stash nicht existiert, liefere leere Liste bzw. undef
    my $stash = $pkg->stash || return;

    push my(@arr),$pkg;
    for (keys %$stash) {
        if (/::$/) {
            s/::$//; # :: am Ende entfernen

            my $subPkg;
            if ($pkg eq 'main') {
                # Der Stash main:: enthält zwei Einträge, die wir ignorieren:
                # 1) die Referenz auf sich selbst
                # 2) einen Eintrag "<none>", der kein gültiger Paketname ist

                next if $_ eq 'main' || $_ eq '<none>';
                $subPkg = $_; # wir wollen main:: am Anfang nicht
            }
            else {
                $subPkg = "$pkg\::$_";
            }

            push @arr,$subPkg->packages;
        }
    }

    return wantarray? @arr: Blog::Base::Array->bless(\@arr);
}

# -----------------------------------------------------------------------------

=head3 stash() - Liefere Referenz auf Symboltabelle

=head4 Synopsis

    $refH = $pkg->stash;

=head4 Description

Liefere eine Referenz auf den Symbol Table Hash (Stash) des Package $pkg.
Existiert der Stash nicht (und somit nicht das Package), liefere undef.

=cut

# -----------------------------------------------------------------------------

# # Variante mit "no strict 'refs'"
# 
# sub stash {
#     my $pkg = shift;
# 
#     no strict 'refs';
#     if (defined *{"$pkg\::"}) {
#         return \%{"$pkg\::"};
#     }
# 
#     return undef; 
# }

# Variante ohne "no strict 'refs'"

sub stash {
    my $pkg = shift;

    # o main:: verweist unter Key 'main::' auf sich selbt
    # o $stash->{$key} ist ein Tyeglob. Im Falle eines Verweises auf
    #   einen Unter-Stash findet sich der Unter-Stash auf dem Hash-Slot.
    #   Daher als Returnwert \%{$stash}, nicht $stash!

    my $stash = \%main::;
    for my $key (split /::/,$pkg) {
        $key .= '::';
        if (!exists $stash->{$key}) {
            return undef;
        }
        $stash = $stash->{$key};
    }

    return \%{$stash}; 
}

# -----------------------------------------------------------------------------

=head2 Typeglobs

=head3 createAlias() - Setze Typeglob-Eintrag

=head4 Synopsis

    $pkg->createAlias($sym=>$ref);

=head4 Description

Weise dem Typeglob-Eintrag $sym in der Symboltabelle des Package $pkg
die Referenz $ref zu. Die Methode liefert keinen Wert zurück.

Der Aufruf ist äquivalent zu:

    no strict 'refs';
    *{"$class\::$sym"} = $ref;

=head4 Example

=over 2

=item *

Alias für Subroutine aus anderer Klasse:

    MyClass->createAlias(mySub=>\&MyClass1::mySub1);

=item *

Eintrag einer Closure in die Symboltabelle:

    __PACKAGE__->createAlias(mySub=>sub { <code> });

=back

=cut

# -----------------------------------------------------------------------------

sub createAlias {
    my ($class,$sym,$ref) = @_;

    no strict 'refs';
    *{"$class\::$sym"} = $ref;

    return;
}

# -----------------------------------------------------------------------------

=head3 createHash() - Erzeuge Package-globalen Hash

=head4 Synopsis

    $ref = $pkg->createHash($sym);

=head4 Description

Erzeuge einen globalen Hash in Package $pkg und liefere eine Referenz
diesen zurück.

=head4 Example

=over 2

=item *

Erzeuge in $class den Hash %H:

    $ref = $class->createHash('H');

=item *

die Referenz kann geblesst werden:

    bless $ref,'Blog::Base::Hash';

=back

=cut

# -----------------------------------------------------------------------------

sub createHash {
    my ($class,$sym) = @_;

    no strict 'refs';
    *{"$class\::$sym"} = {};

    return *{"$class\::$sym"}{HASH};
}

# -----------------------------------------------------------------------------

=head3 getHash() - Liefere Referenz auf Package-Hash

=head4 Synopsis

    $ref = $pkg->getHash($name);

=head4 Example

    $ref = $pkg->getHash('H');

=cut

# -----------------------------------------------------------------------------

sub getHash {
    my ($pkg,$sym) = @_;

    no strict 'refs';
    my $ref = *{"$pkg\::$sym"}{HASH};
    if (!$ref) {
        Blog::Base::Object->throw(
            q{UNIVERSAL-00003: Basisklassen laden fehlgeschlagen},
            BaseClasses=>"@_",
            Error=>$@,
        );
    }

    return $ref;
}

# -----------------------------------------------------------------------------

=head3 createArray() - Erzeuge Package-globales Array

=head4 Synopsis

    $ref = $pkg->createArray($sym);

=head4 Description

Erzeuge ein globales Array in Package $pkg und liefere eine Referenz
dieses zurück.

=head4 Example

=over 2

=item *

Erzeuge in $class das Array @A:

    $ref = $class->createArray('A');

=item *

die Referenz kann geblesst werden:

    bless $ref,'Blog::Base::Array';

=back

=cut

# -----------------------------------------------------------------------------

sub createArray {
    my ($class,$sym) = @_;

    no strict 'refs';
    *{"$class\::$sym"} = [];

    return *{"$class\::$sym"}{ARRAY};
}

# -----------------------------------------------------------------------------

=head3 setArray() - Setze Package-Array auf Wert

=head4 Synopsis

    $ref = $pkg->setArray($name,$ref);

=head4 Description

Setze Package-Array mit dem Namen $name auf den von $ref
referenzierten Wert, also auf @$ref und liefere eine Referenz
auf die Variable zurück.

Die Methode kopiert den Wert, sie erzeugt keinen Alias!

=head4 Example

=over 2

=item *

Setze Paket-Array 'a' auf den Wert @arr:

    $ref = $pkg->setArray('a',\@arr);

=back

=cut

# -----------------------------------------------------------------------------

sub setArray {
    my ($pkg,$sym,$ref) = @_;

    no strict 'refs';
    @{"$pkg\::$sym"} = @$ref;

    return *{"$pkg\::$sym"}{ARRAY};
}

# -----------------------------------------------------------------------------

=head3 setHash() - Setze Package-Hash auf Wert

=head4 Synopsis

    $ref = $pkg->setHash($name,$ref);

=head4 Description

Setze Package-Hash mit dem Namen $name auf den von $ref
referenzierten Wert, also auf %$ref und liefere eine Referenz
auf die Variable zurück.

Die Methode kopiert den Wert, sie erzeugt keinen Alias!

=head4 Example

=over 2

=item *

Setze Paket-Hash 'h' auf den Wert %hash:

    $ref = $pkg->setHash('h',\%hash);

=back

=cut

# -----------------------------------------------------------------------------

sub setHash {
    my ($pkg,$sym,$ref) = @_;

    no strict 'refs';
    %{"$pkg\::$sym"} = %$ref;

    return *{"$pkg\::$sym"}{HASH};
}

# -----------------------------------------------------------------------------

=head3 setScalar() - Setze Package-Skalar auf Wert

=head4 Synopsis

    $ref = $pkg->setScalar($name,$val);

=head4 Description

Setze Package-Skalar mit dem Namen $name auf den Wert $val
und liefere eine Referenz auf die Variable zurück.

=head4 Example

=over 2

=item *

Setze Paket-Skalar 'n' auf den Wert 99:

    $ref = $pkg->setScalar(n=>99);

=back

=cut

# -----------------------------------------------------------------------------

sub setScalar {
    my ($pkg,$sym,$val) = @_;

    no strict 'refs';
    ${"$pkg\::$sym"} = $val;

    return *{"$pkg\::$sym"}{'SCALAR'};
}

# -----------------------------------------------------------------------------

=head3 setScalarValue() - Setze Package-Skalar auf Wert

=head4 Synopsis

    $pkg->setScalarValue($name=>$val);

=head4 Description

Setze Package-Skalar mit dem Namen $name auf den Wert $val.

=head4 Example

=over 2

=item *

Setze Paket-Skalar 'n' auf den Wert 99:

    $ref = $pkg->setScalarValue(n=>99);

=back

=cut

# -----------------------------------------------------------------------------

sub setScalarValue {
    my ($pkg,$sym,$val) = @_;

    no strict 'refs';
    no warnings 'once';
    ${"$pkg\::$sym"} = $val;

    return;
}

# -----------------------------------------------------------------------------

=head3 getScalarValue() - Liefere Wert von Package-Skalar

=head4 Synopsis

    $val = $pkg->getScalarValue($name);

=head4 Example

=over 2

=item *

Ermittele Wert von Paket-Skalar 'n':

    $val = $pkg->getScalarValue('n');

=back

=cut

# -----------------------------------------------------------------------------

sub getScalarValue {
    my ($pkg,$name) = @_;

    no strict 'refs';
    no warnings 'once';
    return ${"$pkg\::$name"};
}

# -----------------------------------------------------------------------------

=head3 setVar() - Setze Package-Variable auf Wert

=head4 Synopsis

    $ref = $pkg->setVar($sigil,$name,$ref);

=head4 Description

Setze Paketvariable vom Typ $sigil ('$', '@' oder '%') mit dem Namen
$name auf den von $ref referenzierten Wert (also $$ref
(falls Skalar) oder @$ref (falls Array) oder %$ref (falls Hash))
und liefere eine Referenz auf die Variable zurück.

Die Subroutine kopiert den Wert, sie erzeugt keinen Alias!

=head4 Example

=over 2

=item *

Skalar

    $ref = $pkg->setVar('$','s',\99);

=item *

Array

    $ref = $pkg->setVar('@','a',\@arr);

=item *

Hash

    $ref = $pkg->setVar('%','h',\%hash);

=back

=cut

# -----------------------------------------------------------------------------

sub setVar {
    my ($pkg,$sigil,$sym,$ref) = @_;

    # Exception, wenn Sigil nicht korrekt
    my $type = Blog::Base::Misc->perlSigilToType($sigil);

    no strict 'refs';
    if ($sigil eq '$') {
        ${"$pkg\::$sym"} = $$ref;
    }
    elsif ($sigil eq '@') {
        @{"$pkg\::$sym"} = @$ref;
    }
    elsif ($sigil eq '%') {
        %{"$pkg\::$sym"} = %$ref;
    }

    return *{"$pkg\::$sym"}{$type};
}

# -----------------------------------------------------------------------------

=head3 getVar() - Liefere Referenz auf Package-Variable

=head4 Synopsis

    $ref = $pkg->getVar($sigil,$name,@opt);

=head4 Options

=over 4

=item -create => $bool (Default: 0)

Erzeuge Variable, falls sie nicht existiert.

=back

=head4 Description

Liefere eine Referenz auf Package-Variable $name vom Typ $sigil
('$','@' oder '%'). Existiert die Variable nicht, liefere undef.

=head4 Caveats

=over 2

=item *

Skalare Variable

=back

Skalare Paketvariable, die mit "our" vereinbart sind und den Wert undef
haben, werden von der Funktion nicht erkannt bzw. nicht sicher
erkannt (Grund ist unklar). Mit "our" vereinbarte skalare
Paketvariable mit definiertem Wert werden sicher erkannt. Workaround:
Skalare Paketvariable, die mit der Methode abgefragt werden sollen,
auch wenn sie den Wert undef haben, mit "use vars" vereinbaren.

=cut

# -----------------------------------------------------------------------------

sub getVar {
    my $pkg = shift;
    my $sigil = shift;
    my $name = shift;

    my $type = Blog::Base::Misc->perlSigilToType($sigil);

    my $create = 0;
    if (@_) {
        Blog::Base::Misc->argExtract(\@_,
            -create=>\$create,
        );
    }

    no strict 'refs';

    if (!$create) {
        # Zunächst auf Symboltabelleneintrag testen. Wenn keiner
        # existiert, gibt es die Variable nicht. Ohne diesen Test
        # würden Symboltabelleneinträge durch den darauffolgenden Code
        # angelegt werden.

        return undef if !exists ${"$pkg\::"}{$name};

        if ($type eq 'SCALAR') {
            if (!defined ${"$pkg\::$name"}) {
                use strict;
                # Unterdrücke 'Variable "..." not imported' Warnungen,
                # die neben der Exception generiert werden.
                local $SIG{__WARN__} = sub {};
                eval "package $pkg; \$$name";
                return undef if $@;
            }
        }
    }

    my $ref = *{"$pkg\::$name"}{$type};

    # Wenn $create "wahr", Variable erzeugen, falls nicht existent

    if (!$ref && $create) {
        $ref = $pkg->setVar($sigil,$name,
            {'$'=>\undef,'@'=>[],'%'=>{}}->{$sigil});
    }

    return $ref;
}

# -----------------------------------------------------------------------------

=head3 setSubroutine() - Setze Package-Subroutine auf Wert

=head4 Synopsis

    $ref = $pkg->setSubroutine($name=>$ref);

=head4 Returns

Referenz auf die Subroutine.

=head4 Description

Füge Subroutine $ref zu Package $pkg unter dem Namen $name hinzu.
Existiert eine Package-Subroutine mit dem Namen bereits,
wird diese ersetzt.

=head4 Examples

Definition:

    $ref = My::Class->setSubroutine(m=>sub {...});

Aufruf:

    My::Class->m(...);

oder

    $ref->(...);

=cut

# -----------------------------------------------------------------------------

sub setSubroutine {
    my ($pkg,$name,$ref) = @_;

    no strict 'refs';
    no warnings 'redefine';
    return *{"$pkg\::$name"} = $ref;
}

# -----------------------------------------------------------------------------

=head3 getSubroutine() - Liefere Referenz auf Subroutine

=head4 Synopsis

    $ref = $pkg->getSubroutine($name);

=head4 Description

Liefere Referenz auf Subroutine $name in Package $pkg. Enthält
das Package keine Subroutine mit dem Namen $name, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub getSubroutine {
    my ($pkg,$name) = @_;

    no strict 'refs';
    if (defined *{"$pkg\::$name"}) {
        return *{"$pkg\::$name"}{CODE};
    }

    return undef;
}

# -----------------------------------------------------------------------------

=head2 Classes

=head3 bless() - Blesse Referenz

=head4 Synopsis

    $obj = $class->bless($ref);

=head4 Description

Objektorientierte Syntax für bless(). Blesse Referenz $ref auf
Klasse $class und liefere die geblesste Referenz zurück.

Der Aufruf ist äquivalent zu:

    $obj = bless($ref,$class);

=head4 Example

    $hash = Blog::Base::Hash->bless({});

=cut

# -----------------------------------------------------------------------------

sub bless {
    my ($class,$ref) = @_;
    return bless $ref,$class;
}

# -----------------------------------------------------------------------------

=head3 createClass() - Erzeuge Klasse

=head4 Synopsis

    $class->createClass(@baseClasses);

=head4 Description

Erzeuge Package $class und definiere die Klassen @baseClasses
als dessen Basisklassen. Die Methode liefert keinen Wert zurück.

Die Basisklassen werden per "use base" geladen.

=cut

# -----------------------------------------------------------------------------

sub createClass {
    my $class = shift;
    # @_: @baseClasses

    # Package erzeugen
    $class->createPackage;

    # Basisklassen definieren
    # $class->setArray('ISA',\@_);

    eval "package $class; use base qw/@_/";
    if ($@) {
        Blog::Base::Object->throw(
            q{PERL-00003: Basisklassen laden fehlgeschlagen},
            BaseClasses=>"@_",
            Error=>$@,
        );
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 baseClasses() - Liefere Liste aller Basisklassen (einschl. UNIVERSAL)

=head4 Synopsis

    @arr | $arr = $class->baseClasses;

=head4 Description

Liefere die Liste der *aller* Basisklassen der Klasse $class,
einschließlich UNIVERSAL und deren Basisklassen.

=head4 Example

Gegeben folgende Vererbungshierarchie:

    Pkg6  Pkg7
      \   /
     UNIVERSAL
    
       Pkg1
        |
       Pkg2
       / \
     Pkg3 Pkg4
       \ /
       Pkg5

Der Aufruf Pkg5->baseClasses liefert ein Array mit den Elementen

    Pkg3 Pkg2 Pkg1 Pkg4 UNIVERSAL Pkg6 Pkg7

Die Klassen Pkg2 und Pkg1 werden nicht wiederholt.

=cut

# -----------------------------------------------------------------------------

sub baseClasses {
    my $class = shift;

    my (@arr,%seen);
    for ($class->baseClassesISA,'UNIVERSAL',UNIVERSAL->baseClassesISA) {
        push @arr,$_ if !$seen{$_}++;
    }

    return wantarray? @arr: Blog::Base::Array->bless(\@arr);
}

# -----------------------------------------------------------------------------

=head3 baseClassesISA() - Liefere Liste der ISA-Basisklassen

=head4 Synopsis

    @arr | $arr = $class->baseClassesISA;

=head4 Description

Liefere die Liste der Basisklassen der Klasse $class.
Jede Basisklasse kommt in der Liste genau einmal vor.

=head4 Example

Gegeben folgende Vererbungshierarchie:

      Pkg1
       |
      Pkg2
      / \
    Pkg3 Pkg4
      \ /
      Pkg5

Der Aufruf Pkg5->baseClassesISA liefert ein Array mit den Elementen

    Pkg3 Pkg2 Pkg1 Pkg4

Die Klassen Pkg2 und Pkg1 werden nicht wiederholt.

=cut

# -----------------------------------------------------------------------------

sub baseClassesISA {
    my $class = shift;

    my (@arr,%seen);
    for ($class->hierarchyISA) {
        push @arr,$_ if !$seen{$_}++;
    }

    return wantarray? @arr: Blog::Base::Array->bless(\@arr);
}

# -----------------------------------------------------------------------------

=head3 hierarchyISA() - Liefere ISA-Hierarchie

=head4 Synopsis

    @arr | $arr = $class->hierarchyISA;

=head4 Description

Liefere die ISA-Hierarchie der Klasse $class. Kommt eine Basisklasse
in der Hierarchie mehrfach vor, erscheint sie mehrfach in der Liste.

=head4 Example

Gegeben folgende Vererbungshierarchie:

      Pkg1
       |
      Pkg2
      / \\
    Pkg3 Pkg4
      \ /
      Pkg5

Der Aufruf Pkg5->hierarchyISA liefert ein Array mit den Elementen

    Pkg3 Pkg2 Pkg1 Pkg4 Pkg2 Pkg1

Die Basisklassen Pkg2 und Pkg1 erscheinen zweimal.

=cut

# -----------------------------------------------------------------------------

sub hierarchyISA {
    my $class = shift;

    my @arr;
    if (my $ref = $class->getVar('@','ISA')) {
        for my $base (@$ref) {
            push @arr,$base,$base->hierarchyISA;
        }
    }

    return wantarray? @arr: Blog::Base::Array->bless(\@arr);
}

# -----------------------------------------------------------------------------

=head3 subClasses() - Liefere Liste aller Subklassen

=head4 Synopsis

    @arr | $arr = $class->subClasses;

=head4 Description

Liefere die Liste der Subklassen der Klasse $class.

=head4 Example

Gegeben folgende Vererbungshierarchie:

      Pkg1
       |
      Pkg2
      / \
    Pkg3 Pkg4
      \ /
      Pkg5

Der Aufruf Pkg1->subClasses liefert ein Array mit den Elementen:

    Pkg2 Pkg3 Pkg4 Pkg5

Die Reihenfolge der Elemente ist nicht definiert.

=over 2

=item *

Liste in sortierter Form

    @arr = main->subClasses->sort;

=item *

Liste, eingeschränkt auf Klassen, deren Name einen Regex erfüllt:

    @arr = main->subClasses->select(qr/[45]/);

=back

=cut

# -----------------------------------------------------------------------------

sub subClasses {
    my $class = shift;

    my @arr;
    for my $pkg (main->packages) {
        push @arr,$pkg if $pkg ne $class && $pkg->isa($class);
    }

    return wantarray? @arr: Blog::Base::Array->bless(\@arr);
}

# -----------------------------------------------------------------------------

=head3 nextMethod() - Finde nächste Methoden-Instanz

=head4 Synopsis

    ($nextClass,$nextMeth) = $class->nextMethod($name,$startClass);

=cut

# -----------------------------------------------------------------------------

sub nextMethod {
    my ($class,$name,$startClass) = @_;

    my ($search,$nextClass,$nextMeth);
    for my $pkg ($class,$class->baseClasses) {
        if ($search) {
            if (my $sub = $pkg->getSubroutine($name)) {
                return wantarray? ($pkg,$sub): $sub;
            }
        }
        elsif ($pkg eq $startClass) {
            $search = 1;
        }
    }

    return;
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
