package Blog::Base::Object;

use strict;
use warnings;

use Blog::Base::Stacktrace;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Object - Basisklasse für alle Klassen der Klassenbibliothek

=head1 SYNOPSIS

    package MyClass;
    use base qw/Blog::Base::Object/;
    ...

=head1 METHODS

=head2 Instanziierung

=head3 bless() - Blesse Objekt auf Klasse

=head4 Synopsis

    $obj = $class->bless($ref);

=head4 Description

Objektorientierte Syntax für bless(). Blesse Objekt (Referenz) $ref auf
Klasse $class und liefere die geblesste Referenz zurück. Dies geht
natürlich nur, wenn $class eine direkte oder indirekte
Subklasse von Blog::Base::Object ist.

Der Aufruf ist äquivalent zu:

    $obj = bless $ref,$class;

=head4 Example

    $hash = Hash->bless({});

=cut

# -----------------------------------------------------------------------------

sub bless {
    my ($class,$ref) = @_;
    return CORE::bless $ref,$class;
}

# -----------------------------------------------------------------------------

=head3 rebless() - Blesse Objekt auf eine andere Klasse um

=head4 Synopsis

    $obj->rebless($class);

=head4 Description

Blesse Objekt $obj auf Klasse $class um.

Der Aufruf ist äquivalent zu:

    bless $obj,$class;

=head4 Example

    $hash->rebless('MyClass');

=cut

# -----------------------------------------------------------------------------

sub rebless {
    my ($self,$class) = @_;
    CORE::bless $self,$class;
    return;
}

# -----------------------------------------------------------------------------

=head2 Exceptions

=head3 throw() - Wirf Exception

=head4 Synopsis

    $this->throw;
    $this->throw(@opt,@keyVal);
    $this->throw($msg,@opt,@keyVal);

=head4 Options

=over 4

=item -stacktrace => $bool (Default: 1)

Ergänze den Exception-Text um einen Stacktrace.

=item -warning => $bool (Default: 0)

Wirf keine Exception, sondern gib lediglich eine Warnung aus.

=back

=head4 Description

Wirf eine Exception mit dem Fehlertext $msg und den hinzugefügten
Schlüssel/Wert-Paaren @keyVal. Die Methode kehrt nur zurück, wenn
Option -warning gesetzt ist.

=cut

# -----------------------------------------------------------------------------

sub throw {
    my $class = ref $_[0]? ref(shift): shift;
    # @_: $msg,@keyVal

    # Optionen nicht durch eine andere Klasse verarbeiten!
    # Die Klasse darf auf keiner anderen Klasse basieren.

    my $stacktrace = 1;
    my $warning = 0;

    for (my $i = 0; $i < @_; $i++) {
        if (!defined $_[$i]) {
            next;
        }
        elsif ($_[$i] eq '-stacktrace') {
            $stacktrace = $_[$i+1];
            splice @_,$i--,2;
        }
        elsif ($_[$i] eq '-warning') {
            $warning = $_[$i+1];
            splice @_,$i--,2;
        }
    }

    my $msg = 'Unerwarteter Fehler';
    if (@_ % 2) {
        $msg = shift;
    }

    # Newlines am Ende entfernen
    $msg =~ s/\n$//;

    # Schlüssel/Wert-Paare

    my $keyVal = '';
    for (my $i = 0; $i < @_; $i += 2) {
        my $key = $_[$i];
        my $val = $_[$i+1];

        # FIXME: überlange Werte berücksichtigen
        if (defined $val) {
            $val =~ s/\s+$//;    # Whitespace am Ende entfernen
        }

        if (defined $val && $val ne '') {
            $key = ucfirst $key;
            if ($warning) {
                if ($keyVal) {
                    $keyVal .= ', ';
                }
                $keyVal .= "$key=$val";
            }
            else {
                $val =~ s/^/    /mg; # Wert einrücken
                $keyVal .= "$key:\n$val\n";
            }
        }
    }

    if ($warning) {
        # Keine Exception, nur Warnung

        warn "$msg. $keyVal\n";
        return;
    }

    # Bereits generierte Exception noch einmal werfen
    # (nachdem Schlüssel/Wert-Paare hinzugefügt wurden)

    if ($msg =~ /^Exception:\n/) {
        my $pos = index($msg,'Stacktrace:');
        if ($pos >= 0) {
            # mit Stacktrace
            substr $msg,$pos,0,$keyVal;
        }
        else {
            # ohne Stacktrace
            $msg .= $keyVal;
        }
        die $msg;
    }

    # Generiere Meldung

    $msg =~ s/^/    /mg;
    my $str = "Exception:\n$msg\n";
    if ($keyVal) {
        $str .= $keyVal;
    }

    if ($stacktrace) {
        # Generiere Stacktrace

        my $stack = Blog::Base::Stacktrace->asString;
        chomp $stack;
        $stack =~ s/^/    /gm;
        $str .= "Stacktrace:\n$stack\n";
    }

    # Wirf Exception

    die $str;
}

# -----------------------------------------------------------------------------

=head2 Sonstiges

=head3 addMethod() - Füge Methode zu Klasse hinzu

=head4 Synopsis

    $this->addMethod($name,$ref);

=head4 Description

Füge Codereferenz $ref unter dem Namen $name zur Klasse $this hinzu.

=head4 Example

    MyClass->addMethod('myMethod',sub {
        my $self = shift;
        return 4711;
    });

=cut

# -----------------------------------------------------------------------------

sub addMethod {
    my $class = ref $_[0]? ref shift: shift;
    my $name = shift;
    my $ref = shift;

    no strict 'refs';
    *{"$class\::$name"} = $ref;

    return;
}

# -----------------------------------------------------------------------------

=head3 classFile() - Liefere Pfad der .pm-Datei

=head4 Synopsis

    $dir = $this->classFile;

=head4 Description

Ermitte den Pfad der .pm-Datei der Klasse $this und liefere
diesen zurück. Die Klasse muss bereits geladen worden sein.

=head4 Example

    $path = Blog::Base::Object->classFile;
    # <PFAD>Blog::Base/Object.pm

=cut

# -----------------------------------------------------------------------------

sub classFile {
    my $class = ref $_[0]? ref shift: shift;

    $class =~ s|::|/|g;
    $class .= '.pm';

    return $INC{$class} || $class->throw;
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
