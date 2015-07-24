package Blog::Base::Hash;
use base qw/Blog::Base::Object/;

use strict;
use warnings;

use Hash::Util ();
use Scalar::Util ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Hash - Hash-Klasse

=head1 BASE CLASS

Blog::Base::Object

=head1 SYNOPSIS

In objektorientierter Syntax:

    my $hash = Blog::Base::Hash->new(a=>1,b=>2,c=>3);
    
    $hash->set(d=>4);
    my $d = $hash->get('d');

In Standard-Perl-Syntax:

    my $hash = bless {a=>1,b=>2,c=>3},'Blog::Base::Hash';
    
    $hash->{'d'} = 4;
    my $d = $hash->{'d'};

=head1 DESCRIPTION

Die Klasse bildet eine objektorientierte Hülle für einen gewöhnlichen
Perl-Hash. Ein Perl-Hash, der auf Blog::Base::Hash geblesst wird, wird zu
einem Objekt der Klasse Blog::Base::Hash. Dieser kann wahlweise über die Methoden
der Klasse angesprochen werden oder wie jeder andere Perl-Hash in
der üblichen Perl-Syntax.

=head2 Objektinstantiierung

Verschiedene äquivalente Möglichkeiten der Objektinstantiierung:

    my $hash = Blog::Base::Hash->new(a=>1,b=>2,c=>3);

oder

    my %hash = (a=>1,b=>2,c=>3);
    my $hash = Blog::Base::Hash->bless(\%hash);

oder

    my %hash = (a=>1,b=>2,c=>3);
    my $hash = bless \%hash,'Blog::Base::Hash';

oder

    my $hash = bless {a=>1,b=>2,c=>3},'Blog::Base::Hash';

=head2 Vorteile

Vorteile der Verwendung der Klasse Blog::Base::Hash gegenüber einem
ungeblessten Perl-Hash:

=over 2

=item *

mehr Hash-Operationen

=item *

vererbbare Schnittstelle

=back

=head1 METHODS

=head2 Konstruktor/Destruktor

=head3 new() - Instantiiere Hash

=head4 Synopsis

    $hash = $class->new; # [1]
    $hash = $class->new(@keyVal); # [2]
    $hash = $class->new(\@keys,\@vals[,$val]); # [3]
    $hash = $class->new(\@keys[,$val]); # [4]

=head4 Description

Instantiiere ein Hash-Objekt, setze die Schlüssel/Wert-Paare
und liefere eine Referenz auf dieses Objekt zurück.

[1] Leerer Hash

[2] Die Argumentliste ist eine Abfolge von Schlüssel/Wert-Paaren.

[3] Schlüssel und Werte befinden sich in getrennten Arrays.
Ist ein Wert CL<lt>undef>, wird stattdessen $val gesetzt, falls angegeben.

[4] Nur die Schlüssel sind angegeben. Ist $val angegeben, werden
alle Werte auf diesen Wert gesetzt. Ist $val nicht angegeben,
werden alle Werte auf C<undef> gesetzt.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: Argumente

    my %hash;
    if (!ref $_[0]) {
        # Aufruf: $hash = $class->new;
        # Aufruf: $hash = $class->new(@keyVal);

        while (@_) {
            my $key = shift;
            $hash{$key} = shift;
        }
    }
    else {
        # Aufruf: $hash = $class->new(\@keys,...);
        my $keyA = shift;

        if (ref $_[0]) {
            # Aufruf: $hash = $class->new(\@keys,\@vals,...);
            my $valA = shift;

            if (@_) {
                # Aufruf: $hash = $class->new(\@keys,\@vals,$val);
                my $val = shift;

                my $i = 0;
                for my $key (@$keyA) {
                    $hash{$key} = $valA->[$i++];
                    if (!defined $hash{$key}) {
                        $hash{$key} = $val;
                    }
                }
            }
            else {
                # Aufruf: $hash = $class->new(\@keys,\@vals);
                @hash{@$keyA} = @$valA;
            }
        }
        else {
            # Aufruf: $hash = $class->new(\@keys[,$val]);

            my $val = shift;
            @hash{@$keyA} = ($val) x @$keyA;
        }
    }

    return bless \%hash,$class;
}

# -----------------------------------------------------------------------------

=head3 destroy() - Zerstöre Hash

=head4 Synopsis

    $hash->destroy;

=head4 Description

Zerstöre den Hash, gib sämtlichen Speicher frei (sofern keine
weitere Referenz auf den Hash existiert). Die Methode liefert keinen
Wert zurück.

Alternative Formulierung:

    $hash = undef;

=cut

# -----------------------------------------------------------------------------

sub destroy {
    $_[0] = undef;
}

# -----------------------------------------------------------------------------

=head2 Getter/Setter

=head3 get() - Liefere Werte zu Schlüsseln

=head4 Synopsis

    $val = $hash->get($key);
    @vals = $hash->get(@keys);

=head4 Description

Liefere die Werte zu den angegebenen Schlüsseln. In skalarem Kontext
liefere keine Liste, sondern den Wert des ersten Schlüssels.

Alternative Formulierung (für ein Schlüssel/Wert-Paar):

    $val = $hash->{$key};

=cut

# -----------------------------------------------------------------------------

sub get {
    my $self = shift;

    my @arr;
    while (@_) {
        my $key = shift;
        push @arr,$self->{$key};
    }

    return wantarray? @arr: $arr[0];
}

# -----------------------------------------------------------------------------

=head3 try() - Liefere Werte zu Schlüsseln

=head4 Synopsis

    $val = $hash->try($key);
    @vals = $hash->try(@keys);

=head4 Description

Wie get(), nur dass im Falle eines Restricted Hash keine Exception
bei nicht-existentem Schlüssel generiert, sondern undef geliefert wird.

=cut

# -----------------------------------------------------------------------------

sub try {
    my $self = shift;

    my @arr;
    while (@_) {
        my $key = shift;
        push @arr,exists($self->{$key})? $self->{$key}: undef;
    }

    return wantarray? @arr: $arr[0];
}

# -----------------------------------------------------------------------------

=head3 set() - Setze Schlüssel/Wert-Paare

=head4 Synopsis

    $hash->set(@keyVal);

=head4 Description

Setze die angegebenen Schlüssel/Wert-Paare. Die Methode liefert keinen
Wert zurück.

Alternative Formulierung (für ein Schlüssel/Wert-Paar):

    $hash->{$key} = $val;

=cut

# -----------------------------------------------------------------------------

sub set {
    my $self = shift;
    # @_: @keyVal

    while (@_) {
        my $key = shift;
        $self->{$key} = shift;
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 getRef() - Liefere Referenz auf Attribut

=head4 Synopsis

    $valS = $hash->getRef($key);

=cut

# -----------------------------------------------------------------------------

sub getRef {
    my ($self,$key) = @_;
    return \$self->{$key};
}

# -----------------------------------------------------------------------------

=head2 Löschen

=head3 clear() - Leere Hash

=head4 Synopsis

    $hash->clear;

=head4 Description

Leere Hash, d.h. entferne alle Schlüssel/Wert-Paare. Die Methode
liefert keinen Wert zurück.

Alternative Formulierung:

    %$hash = ();

Anmerkung: Die interne Größe des Hash (Anzahl der allozierten Buckets)
wird durch das Leeren nicht verändert.

=cut

# -----------------------------------------------------------------------------

sub clear {
    my $self = shift;
    %$self = ();
    return;
}

# -----------------------------------------------------------------------------

=head3 delete() - Entferne einzelne Schlüssel

=head4 Synopsis

    $hash->delete(@keys);

=head4 Description

Entferne die Schlüssel @keys aus dem Hash. Die Methode liefert keinen
Wert zurück.

Alternative Formulierung (für einen einzelnen Key):

    delete $hash->{$key};

=cut

# -----------------------------------------------------------------------------

sub delete {
    my $self = shift;
    # @_: @keys

    for my $key (@_) {
        CORE::delete $self->{$key};
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Tests

=head3 isEmpty() - Teste auf leeren Hash

=head4 Synopsis

    $bool = $hash->isEmpty;

=head4 Description

Liefere "wahr", wenn der Hash leer ist, andernfalls "falsch".

Alternative Formulierung:

    $bool = %$hash;

=cut

# -----------------------------------------------------------------------------

sub isEmpty {
    my $self = shift;
    return %$self? 0: 1;
}

# -----------------------------------------------------------------------------

=head3 exists() - Prüfe Schlüssel auf Existenz

=head4 Synopsis

    $bool = $hash->exists($key);

=head4 Description

Prüfe, ob der angegebene Schlüssel im Hash existiert. Wenn ja,
liefere "wahr", andernfalls "falsch".

Alternative Formulierung:

    $bool = exists $hash->{$key};

=cut

# -----------------------------------------------------------------------------

sub exists {
    my ($self,$key) = @_;
    return CORE::exists $self->{$key};
}

# -----------------------------------------------------------------------------

=head2 Locking

=head3 lockKeys() - Locke Keys

=head4 Synopsis

    $hash->lockKeys;

=head4 Description

Locke die Keys des Hash. Anschließend kann kein weiterer Key
hinzugefügt werden, kein existierender gelöscht werden und
kein nicht-existierender gelesen werden. All dies führt zu
einer Exception. Die Methode liefert keinen Wert zurück.

Alternative Formulierung:

    Hash::Util::lock_keys(%$hash);

=cut

# -----------------------------------------------------------------------------

sub lockKeys {
    my $self = shift;
    if ($] >= 5.01) { Hash::Util::lock_ref_keys($self) } # ab Perl 5.10
    else { Hash::Util::lock_keys(%$self) }
    return;
}

# -----------------------------------------------------------------------------

=head3 unlockKeys() - Unlocke Keys

=head4 Synopsis

    $hash->unlockKeys;

=head4 Description

Unlocke die Keys des Hash. Anschließend kann der Hash wieder beliebig
manipuliert werden. Die Methode liefert keinen Wert zurück.

Alternative Formulierung:

    Hash::Util::unlock_keys(%$hash);

=cut

# -----------------------------------------------------------------------------

sub unlockKeys {
    my $self = shift;
    if ($] >= 5.01) { Hash::Util::unlock_ref_keys($self) } # ab Perl 5.10
    else { Hash::Util::unlock_keys(%$self) }
    return;
}

# -----------------------------------------------------------------------------

=head2 Hash-Buckets

=head3 buckets() - Ermittele/Vergrößere Bucketanzahl

=head4 Synopsis

    $n = $hash->buckets;
    $n = $hash->buckets($m);

=head4 Description

Vergrößere die Bucketanzahl des Hash auf (mindestens) $m.
Die Methode liefert die Anzahl der Buckets zurück. Ist kein
Parameter angegeben, wird nur die Anzahl der Buckets geliefert.

Anmerkungen:

=over 2

=item o

$m wird von Perl auf die nächste Zweierpotenz aufgerundet

=item o

Die Bucketanzahl kann nur vergrößert, nicht verkleinert werden

=back

=cut

# -----------------------------------------------------------------------------

sub buckets {
    my ($self,$n) = @_;

    if (defined $n) {
        CORE::keys(%$self) = $n;
    }

    # scalar(%hash) liefert 0, wenn der Hash leer ist, andernfalls
    # $x/$n, wobei $n die Anzahl der zur Verfügung stehenden Buckets ist
    # und $x die Anzahl der genutzten Buckets. Um die Bucketanzahl
    # eines leeren Hash zu ermitteln, müssen wir also temporär ein
    # Element hinzufügen.

    unless ($n = scalar %$self) {
        $self->{"this_is_a_pseudo_key_$$"} = 1;
        $n = scalar %$self;
        delete $self->{"this_is_a_pseudo_key_$$"};
    }
    $n =~ s|.*/||;

    return $n;
}

# -----------------------------------------------------------------------------

=head3 bucketsUsed() - Liefere Anzahl der genutzten Buckets

=head4 Synopsis

    $n = $hash->bucketsUsed;

=head4 Description

Liefere die Anzahl der genutzten Hash-Buckets.

=cut

# -----------------------------------------------------------------------------

sub bucketsUsed {
    my $self = shift;

    my $n = scalar %$self;
    if ($n) {
        $n =~ s|/.*||;
    }

    return $n;
}

# -----------------------------------------------------------------------------

=head2 Sonstige Methoden

=head3 copy() - Kopiere Hash

=head4 Synopsis

    $hash2 = $hash->copy;
    $hash2 = $hash->copy(@keyVal);

=head4 Description

Kopiere Hash, d.h. instantiiere einen neuen Hash mit den
gleichen Schlüssel/Wert-Paaren. Es wird I<nicht> rekursiv kopiert,
sondern eine "shallow copy" erzeugt.

Sind Schlüssel/Wert-Paare @keyVal angegeben, werden
diese nach dem Kopieren per set() auf dem neuen Hash gesetzt.

=cut

# -----------------------------------------------------------------------------

sub copy {
    my $self = shift;
    # @_: @keyVal

    my %hash = %$self;
    my $hash = bless \%hash,ref $self;
    if (@_) {
        $hash->set(@_);
    }

    return $hash;
}

# -----------------------------------------------------------------------------

=head3 keys() - Liefere Liste der Schlüssel

=head4 Synopsis

    $arr|@arr = $hash->keys;

=head4 Description

Liefere die Liste aller Schlüssel. Im Skalarkontext liefere eine
Referenz auf die Liste (geblesst auf Blog::Base::Array).

Die Reihenfolge der Schlüssel ist undefiniert.

Alternative Formulierung:

    @arr = keys %$hash;

=cut

# -----------------------------------------------------------------------------

sub keys {
    my $self = shift;
    my @keys = CORE::keys %$self;
    return wantarray? @keys: bless \@keys,'Blog::Base::Array';
}

# -----------------------------------------------------------------------------

=head3 increment() - Inkrementiere Wert

=head4 Synopsis

    $n = $hash->increment($key);

=head4 Description

Inkrementiere Wert zu Schlüssel $key und liefere das Resultat zurück.

Alternative Formulierung:

    $n = ++$hash->{$key};

=cut

# -----------------------------------------------------------------------------

sub increment {
    my ($self,$key) = @_;
    return ++$self->{$key};
}

# -----------------------------------------------------------------------------

=head3 size() - Liefere Anzahl der Schlüssel/Wert-Paare

=head4 Synopsis

    $n = $hash->size;

=head4 Description

Liefere die Anzahl der Schlüssel/Wert-Paare des Hash.

Alternative Formulierung:

    $n = keys %$hash;

=cut

# -----------------------------------------------------------------------------

sub size {
    my $self = shift;
    return scalar CORE::keys %$self;
}

# -----------------------------------------------------------------------------

=head3 weaken() - Erzeuge schwache Referenzen

=head4 Synopsis

    $hash->weaken(@keys);

=head4 Description

Mache die Werte der Schlüssel @keys zu schwachen Referenzen.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub weaken {
    my $self = shift;
    # @_: @keys

    for (@_) {
        Scalar::Util::weaken $self->{$_};
    }

    return;
}

# -----------------------------------------------------------------------------

=head1 AUTHOR

Frank Seitz, http://fseitz.de/

=head1 COPYRIGHT

Copyright (C) 2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
