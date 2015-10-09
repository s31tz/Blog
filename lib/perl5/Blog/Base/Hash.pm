package Blog::Base::Hash;
use base qw/Blog::Base::Object/;

use strict;
use warnings;

use Hash::Util ();
use Scalar::Util ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Hash - Sicherer Hash

=head1 BASE CLASS

L<Blog::Base::Object|../Blog::Base/Object.html>

=head1 METHODS

=head2 Instanziierung

=head3 new() - Instanziiere Hash

=head4 Synopsis

    $h = $class->new; # [1]
    $h = $class->new(@keyVal); # [2]
    $h = $class->new(\@keys,\@vals[,$val]); # [3]
    $h = $class->new(\@keys[,$val]); # [4]
    $h = $class->new(\%hash); # [5]

=head4 Description

Instanziiere ein Hash-Objekt, setze die Schlüssel/Wert-Paare
und liefere eine Referenz auf dieses Objekt zurück.

[1] Leerer Hash.

[2] Die Argumentliste ist eine Abfolge von Schlüssel/Wert-Paaren.

[3] Schlüssel und Werte befinden sich in getrennten Arrays.
Ist ein Wert CL<lt>undef>, wird stattdessen $val gesetzt, falls angegeben.

[4] Nur die Schlüssel sind angegeben. Ist $val angegeben, werden
alle Werte auf diesen Wert gesetzt. Ist $val nicht angegeben,
werden alle Werte auf C<undef> gesetzt.

[5] Blesse den Hash %hash auf Blog::Base::Hash.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: Argumente

    my $h;
    if (!ref $_[0]) {
        # Aufruf: $h = $class->new;
        # Aufruf: $h = $class->new(@keyVal);

        $h = \my %h;
        while (@_) {
            my $key = shift;
            $h{$key} = shift;
        }
    }
    elsif (Scalar::Util::reftype($_[0]) eq 'HASH') {
        # Aufruf: $h = $class->new(\%hash);
        $h = bless shift,$class;
    }
    else {
        # Aufruf: $h = $class->new(\@keys,...);
        my $keyA = shift;

        $h = \my %h;
        if (ref $_[0]) {
            # Aufruf: $h = $class->new(\@keys,\@vals,...);
            my $valA = shift;

            if (@_) {
                # Aufruf: $h = $class->new(\@keys,\@vals,$val);
                my $val = shift;

                my $i = 0;
                for my $key (@$keyA) {
                    $h{$key} = $valA->[$i++];
                    if (!defined $h{$key}) {
                        $h{$key} = $val;
                    }
                }
            }
            else {
                # Aufruf: $h = $class->new(\@keys,\@vals);
                @h{@$keyA} = @$valA;
            }
        }
        else {
            # Aufruf: $h = $class->new(\@keys[,$val]);

            my $val = shift;
            @h{@$keyA} = ($val) x @$keyA;
        }
    }

    # Sperre Schlüssel gegen Änderungen

    bless $h,$class;
    $h->lockKeys;

    return $h;
}

# -----------------------------------------------------------------------------

=head3 destroy() - Zerstöre Hash

=head4 Synopsis

    $hash->destroy;

=head4 Description

Zerstöre den Hash und gib sämtlichen Speicher frei, sofern keine
weitere Referenz auf den Hash existiert. Die Methode liefert keinen
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

=head3 get() - Liefere Werte

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
    if (Hash::Util::hash_locked(%$self)) {
        # Restricted Hash -> Exception-Handling

        while (@_) {
            my $key = shift;
            my $val = eval {$self->{$key}};
            if ($@) {
                $self->throw(
                    q{HASH-00001: Illegal get() access},
                    Key=>$key,
                    Value=>$val,
                );
            }
            push @arr,$val;
        }
    }
    else {
        # Hash mit freiem Zugriff

        while (@_) {
            my $key = shift;
            push @arr,$self->{$key};
        }
    }

    return wantarray? @arr: $arr[0];
}

# -----------------------------------------------------------------------------

=head3 try() - Liefere Werte ohne Exception

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

    if (Hash::Util::hash_locked(%$self)) {
        # Restricted Hash -> Exception-Handling

        while (@_) {
            my $key = shift;
            my $val = shift;
            eval {$self->{$key} = $val};
            if ($@) {
                $self->throw(
                    q{HASH-00001: Illegal set() access},
                    Key=>$key,
                    Value=>$val,
                );
            }
        }
    }
    else {
        # Hash mit freiem Zugriff

        while (@_) {
            my $key = shift;
            $self->{$key} = shift;
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 add() -  Erweitere Hash um Schlüssel/wert-Paare

=head4 Synopsis

    $val = $h->add($key=>$val);
    @vals = $h->add(@keyVal);

=head4 Description

Erweitere den Hash um die angegebenen Schlüssel/Wert-Paare und liefere
die gesetzten Werte zurück. In skalarem Kontext liefere nur den
ersten Wert.

=cut

# -----------------------------------------------------------------------------

sub add {
    my $self = shift;
    # @_: @keyVal

    my $isLocked = Hash::Util::hash_locked(%$self);
    if ($isLocked) {
        Hash::Util::unlock_keys(%$self);
    }

    my @arr = $self->set(@_);

    if ($isLocked) {
        Hash::Util::lock_keys(%$self);
    }

    return wantarray? @arr: $arr[0];
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

    # my $isLocked = Hash::Util::hash_locked(%$self);
    # if ($isLocked) {
    #     Hash::Util::unlock_keys(%$self);
    # }

    %$self = ();

    # if ($isLocked) {
    #     Hash::Util::lock_keys(%$self);
    # }

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

    # my $isLocked = Hash::Util::hash_locked(%$self);
    # if ($isLocked) {
    #     Hash::Util::unlock_keys(%$self);
    # }

    for my $key (@_) {
        CORE::delete $self->{$key};
    }

    # if ($isLocked) {
    #     Hash::Util::lock_keys(%$self);
    # }

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

    $bool = $h->exists($key);

=head4 Description

Prüfe, ob der angegebene Schlüssel im Hash existiert. Wenn ja,
liefere 1, andernfalls 0.

=cut

# -----------------------------------------------------------------------------

sub exists {
    my ($self,$key) = @_;

    # my $isLocked = Hash::Util::hash_locked(%$self);
    # if ($isLocked) {
    #     Hash::Util::unlock_keys(%$self);
    # }

    my $r = CORE::exists $self->{$key};

    # if ($isLocked) {
    #     Hash::Util::lock_keys(%$self);
    # }

    return $r? 1: 0;
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
    Hash::Util::lock_keys(%$self);
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
    Hash::Util::unlock_keys(%$self);
    return;
}

# -----------------------------------------------------------------------------

=head3 isLocked() - Prüfe, ob Hash gelockt ist

=head4 Synopsis

    $bool = $hash->isLocked;

=head4 Description

Alternative Formulierung:

    Hash::Util::hash_locked(%$hash);

=cut

# -----------------------------------------------------------------------------

sub isLocked {
    my $self = shift;
    return Hash::Util::hash_locked(%$self)? 1: 0;
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
        my $isLocked = $self->isLocked;
        if ($isLocked) {
            $self->unlockKeys;
        }
        $self->{"this_is_a_pseudo_key_$$"} = 1;
        $n = scalar %$self;
        delete $self->{"this_is_a_pseudo_key_$$"};
        if ($isLocked) {
            $self->lockKeys;
        }
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

Kopiere Hash, d.h. instanziiere einen neuen Hash mit den
gleichen Schlüssel/Wert-Paaren. Es wird I<nicht> rekursiv kopiert,
sondern eine "shallow copy" erzeugt.

Sind Schlüssel/Wert-Paare @keyVal angegeben, werden
diese nach dem Kopieren per set() auf dem neuen Hash gesetzt.

=cut

# -----------------------------------------------------------------------------

sub copy {
    my $self = shift;
    # @_: @keyVal

    my $isLocked = Hash::Util::hash_locked(%$self);

    my %hash = %$self;
    my $hash = bless \%hash,ref $self;
    if (@_) {
        $hash->set(@_);
    }

    if ($isLocked) {
        Hash::Util::lock_keys(%$self);
    }

    return $hash;
}

# -----------------------------------------------------------------------------

=head3 keys() - Liefere Liste der Schlüssel

=head4 Synopsis

    $arr|@arr = $hash->keys;

=head4 Description

Liefere die Liste aller Schlüssel. Im Skalarkontext liefere eine
Referenz auf die Liste.

Die Reihenfolge der Schlüssel ist undefiniert.

Alternative Formulierung:

    @arr = keys %$hash;

=cut

# -----------------------------------------------------------------------------

sub keys {
    my $self = shift;
    my @keys = CORE::keys %$self;
    return wantarray? @keys: \@keys;
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
        Scalar::Util::weaken($self->{$_});
    }

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
