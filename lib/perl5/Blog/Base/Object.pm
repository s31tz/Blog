package Blog::Base::Object;

use strict;
use warnings;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Object - Basisklasse für alle Klassen der Blog::Base-Klassenbibliothek

=head1 SYNOPSIS

    package Blog::Base::A;
    use base qw/Blog::Base::Object/;
    ...

=head1 METHODS

=head2 Allgemein

=head3 bless() - Blesse Referenz

=head4 Synopsis

    $obj = $class->bless($ref);

=head4 Description

Objektorientierte Syntax für bless(). Blesse Referenz $ref auf
Klasse $class und liefere die geblesste Referenz zurück.

Der Aufruf ist äquivalent zu:

    $obj = bless $ref,$class;

=head4 Example

    $hash = Blog::Base::Hash->bless({});

=cut

# -----------------------------------------------------------------------------

sub bless {
    my ($class,$ref) = @_;
    return CORE::bless $ref,$class;
}

# -----------------------------------------------------------------------------

=head3 rebless() - Blesse Objekt auf eine andere Klasse

=head4 Synopsis

    $obj->rebless($class);

=head4 Returns

Die Methode liefert keinen Wert zurück.

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

=head3 classDir() - Liefere Klassenverzeichnis

=head4 Synopsis

    $dir = $this->classDir;

=head4 Returns

Pfad zum Klassenverzeichnis (String)

=cut

# -----------------------------------------------------------------------------

sub classDir {
    my $class = ref $_[0]? ref shift: shift;

    $class =~ s|::|/|g;
    $class .= '.pm';

    my $path = $INC{$class} || $class->throw;
    $path =~ s/\.pm$//;

    return $path;
}

# -----------------------------------------------------------------------------

=head3 addMethod() - Füge Methode zur Klasse hinzu

=head4 Synopsis

    $this->addMethod($name,$ref);

=head4 Description

Füge Codereferenz $ref unter dem Namen $name zur Klasse $this hinzu.

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

=head2 Exceptions

=head3 throw() - Wirf Exception

=head4 Synopsis

    $this->throw;
    $this->throw(@keyVal);
    $this->throw($msg,@keyVal);

=head4 Description

Wirf Exception mit dem Fehlertext $msg und den hinzugefügten
Schlüssel/Wert-Paaren @keyVal. Die Methode kehrt nicht zurück.

=cut

# -----------------------------------------------------------------------------

sub throw {
    my $class = ref $_[0]? ref(shift): shift;
    # @_: $msg,@keyVal

    # Optionen (nicht per Blog::Base::Option verarbeiten, die Klasse
    # darf auf keiner anderen Klasse basieren)

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

    # Generiere Stacktrace

    my @frames;
    my $i = 0;
    while (my (undef,$file,$line,$sub) = caller $i++) {
        # $file =~ s|.*/||;
        push @frames,[$file,$line,$sub];
    }

    $i = 0;
    my $stack = '';
    for my $frame (reverse @frames) {
        my ($file,$line,$sub) = @$frame;
        $sub .= "()" if $sub ne '(eval)';
        $stack .= sprintf "%s%s [%s %s]\n",('  'x$i++),$sub,$file,$line;
    }
    chomp $stack;
    $stack =~ s/^/    /gm;

    # Generiere Meldung

    $msg =~ s/^/    /mg;
    my $str = "Exception:\n$msg\n";
    if ($keyVal) {
        $str .= $keyVal;
    }
    if ($stacktrace) {
        $str .= "Stacktrace:\n$stack\n";
    }

    # Wirf Exception

    die $str;
}

# -----------------------------------------------------------------------------

=head3 throwMsg() - Wirf Exception als einfache Meldung (ohne Stacktrace etc.)

=head4 Synopsis

    $this->throwMsg($msg,@keyVal);

=head4 Description

Wirf Exception mit dem Fehlertext $msg und den hinzugefügten
Schlüssel/Wert-Paaren @keyVal. Die Methode kehrt nicht zurück.

=cut

# -----------------------------------------------------------------------------

sub throwMsg {
    my $class = ref $_[0]? ref(shift): shift;
    my $msg = shift;
    # @_: @keyVal

    # Schlüssel/Wert-Paare

    my $str;
    for (my $i = 0; $i < @_; $i += 2) {
        my $key = $_[$i];
        my $val = $_[$i+1];
        if (defined $val && $val ne '') {
            $val =~ s/\s+$//;    # Whitespace am Ende entfernen
            $str .= ', ' if $str;
            $str .= "$key: $val";
        }
    }
    if ($str) {
        $msg .= " ($str)";
    }
    $msg =~ s/\s+$//;

    # Wirf Exception
    die "$msg\n";
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
