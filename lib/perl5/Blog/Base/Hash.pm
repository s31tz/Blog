package Blog::Base::Hash;
use base qw/Blog::Base::Object/;

use strict;
use warnings;
use utf8;

use Hash::Util ();
use Scalar::Util ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Hash - Zugriffssicherer Hash

=head1 BASE CLASS

L<Blog::Base::Object|../Blog::Base/Object.html>

=head1 SYNOPSIS

Klasse laden:

    use Blog::Base::Hash;

Objekt-Instanziierung:

    my $h = Blog::Base::Hash->new(a=>1,b=>1,c=>3);

Werte abfragen oder setzen:

    my $v = $h->get('a'); # oder: $v = $h->{'a'};
    $h->set(b=>2);        # oder: $h->{'b'} = 2;

Unerlaubte Zugriffe:

    $v = $h->get('d');    # Exception!
    $h->set(d=>4);        # Exception!

Erlaubte Zugriffe;

    $v = $h->try('d');    # undef
    $h->add(d=>4);

=head1 DESCRIPTION

Ein Objekt dieser Klasse repräsentiert einen I<Zugriffssicheren Hash>,
d.h. einen Hash, dessen Schlüsselvorrat bei der Instanziierung
festgelegt wird. Ein lesender oder schreibender Zugriff mit einem
Schlüssel, der nicht zu dem Schlüsselvorrat gehört, ist nicht erlaubt
und führt zu einer Exception.

Der Zugriffsschutz beruht auf der Funktionalität des
L<Restricted Hash|http://perldoc.perl.org/Hash/Util.html#Restricted-hash>.

Abgesehen vom Zugriffsschutz verhält sich ein Hash-Objekt dieser
Klasse wie einer normaler Hash und kann auch so angesprochen werden.
Bei den Methoden ist der entsprechende konventionelle Zugriff als
C<Alternative Formulierung> angegeben.

=head1 METHODS

=head2 Instanziierung

=head3 new() - Instanziiere Hash

=head4 Synopsis

    $h = $class->new;                       # [1]
    $h = $class->new(@keyVal);              # [2]
    $h = $class->new(\@keys,\@vals[,$val]); # [3]
    $h = $class->new(\@keys[,$val]);        # [4]
    $h = $class->new(\%hash);               # [5]

=head4 Description

Instanziiere ein Hash-Objekt, setze die Schlüssel/Wert-Paare
und liefere eine Referenz auf dieses Objekt zurück.

=over 4

=item [1]

Leerer Hash.

=item [2]

Die Argumentliste ist eine Aufzählung von Schlüssel/Wert-Paaren.

=item [3]

Schlüssel und Werte befinden sich in getrennten Arrays.
Ist ein Wert C<undef>, wird $val gesetzt, falls angegeben.

=item [4]

Nur die Schlüssel sind angegeben. Ist $val angegeben, werden
alle Werte auf diesen Wert gesetzt. Ist $val nicht angegeben,
werden alle Werte auf C<undef> gesetzt.

=item [5]

Blesse den Hash %hash auf Klasse Blog::Base::Hash.

=back

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

=head2 Getter/Setter

=head3 get() - Werte abfragen

=head4 Synopsis

    $val = $h->get($key);
    @vals = $h->get(@keys);

=head4 Description

Liefere die Werte zu den angegebenen Schlüsseln. In skalarem Kontext
liefere keine Liste, sondern den Wert des ersten Schlüssels.

Alternative Formulierung:

    $val = $h->{$key};    # ein Schlüssel
    @vals = @{$h}{@keys}; # mehrere Schlüssel

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
                    q{HASH-00001: Unzulässiger Lesezugriff},
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

=head3 getRef() - Referenz auf Wert

=head4 Synopsis

    $valS = $h->getRef($key);

=head4 Description

Liefere nicht den Wert zum Schlüssel $key, sondern eine Referenz auf
den Wert.

Dies kann praktisch sein, wenn der Wert manipuliert werden soll. Die
Manipulation kann dann über die Referenz erfolgen und der Wert muss
nicht erneut zugewiesen werden.

Alternative Formulierung:

    $valS = \$h->{$key};

=head4 Example

Newline an Wert anhängen mit getRef():

    $valS = $h->getRef('x');
    $$valS .= "\n";

Dasselbe ohne getRef():

    $val = $h->get('x');
    $val .= "\n";
    $val->set(x=>$val);

=cut

# -----------------------------------------------------------------------------

sub getRef {
    my ($self,$key) = @_;
    return \$self->{$key};
}

# -----------------------------------------------------------------------------

=head3 try() - Werte abfragen ohne Exception

=head4 Synopsis

    $val = $h->try($key);
    @vals = $h->try(@keys);

=head4 Description

Wie get(), nur dass im Falle eines unerlaubten Schlüssels
keine Exception geworfen, sondern C<undef> geliefert wird.

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

    $h->set(@keyVal);

=head4 Description

Setze die angegebenen Schlüssel/Wert-Paare.

Alternative Formulierung:

    $h->{$key} = $val;    # ein Schlüssel/Wert-Paar
    @{$h}{@keys} = @vals; # mehrere Schlüssel/Wert-Paare

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
                    q{HASH-00001: Unzulässiger Schreibzugriff},
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

=head3 add() -  Setze Schlüssel/Wert-Paare ohne Exception

=head4 Synopsis

    $val = $h->add($key=>$val);
    @vals = $h->add(@keyVal);

=head4 Description

Wie set(), nur dass im Falle eines unerlaubten Schlüssels keine
Exception generiert, sondern der Hash um das Schlüssel/Wert-Paar
erweitert wird.

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

=head3 apply() - Wende Subroutine auf Schlüssel/Wert-Paar an

=head4 Synopsis

    $val = $h->apply($key,$sub);

=head4 Description

Wende Subroutine $sub auf den Wert des Schlüssels $key an. Die
Subroutine hat die Struktur:

    sub {
        my ($h,$key) = @_;
        ...
        return $val;
    }

Der Rückgabewert der Subroutine wird an Schlüssel $key zugewiesen.

=head4 Example

Methode increment() mit apply() realisiert:

    $val = $h->apply($key,sub {
        my ($h,$key) = @_;
        return $h->{$key}+1;
    });

=cut

# -----------------------------------------------------------------------------

sub apply {
    my ($self,$key,$sub) = @_;
    return $self->{$key} = $sub->($self,$key);
}

# -----------------------------------------------------------------------------

=head2 Schlüssel

=head3 keys() - Liste der Schlüssel

=head4 Synopsis

    @keys|$keyA = $h->keys;

=head4 Description

Liefere die Liste aller Schlüssel. Die Liste ist unsortiert.
Im Skalarkontext liefere eine Referenz auf die Liste.

Die Reihenfolge der Schlüssel ist undefiniert.

Alternative Formulierung:

    @keys = keys %$h;

=cut

# -----------------------------------------------------------------------------

sub keys {
    my $self = shift;
    my @keys = CORE::keys %$self;
    return wantarray? @keys: \@keys;
}

# -----------------------------------------------------------------------------

=head3 size() - Anzahl der Schlüssel

=head4 Synopsis

    $n = $h->size;

=head4 Description

Liefere die Anzahl der Schlüssel/Wert-Paare des Hash.

Alternative Formulierung:

    $n = keys %$h;

=cut

# -----------------------------------------------------------------------------

sub size {
    my $self = shift;
    return scalar CORE::keys %$self;
}

# -----------------------------------------------------------------------------

=head2 Kopieren

=head3 copy() - Kopiere Hash

=head4 Synopsis

    $h2 = $h->copy;
    $h2 = $h->copy(@keyVal);

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

    my %hash = %$self;
    my $h = bless \%hash,ref $self;
    if (@_) {
        $h->set(@_);
    }
    if (Hash::Util::hash_locked(%$self)) {
        Hash::Util::lock_keys(%$h);
    }

    return $h;
}

# -----------------------------------------------------------------------------

=head2 Löschen

=head3 delete() - Entferne Schlüssel/Wert-Paare

=head4 Synopsis

    $h->delete(@keys);

=head4 Description

Entferne die Schlüssel @keys (und ihre Werte) aus dem Hash. An der Menge
der zulässigen Schlüssel ändert sich dadurch nichts!

Alternative Formulierung:

    delete $h->{$key};   # einzelner Schlüssel
    delete @{$h}{@keys}; # mehrere Schlüssel

=cut

# -----------------------------------------------------------------------------

sub delete {
    my $self = shift;
    # @_: @keys

    # my $isLocked = Hash::Util::hash_locked(%$self);
    # if ($isLocked) {
    #     Hash::Util::unlock_keys(%$self);
    # }

    # CORE::delete @{$self}->{@_}; # Warum geht dies nicht?

    for (@_) {
        CORE::delete $self->{$_};
    }

    # if ($isLocked) {
    #     Hash::Util::lock_keys(%$self);
    # }

    return;
}

# -----------------------------------------------------------------------------

=head3 clear() - Leere Hash

=head4 Synopsis

    $h->clear;

=head4 Description

Leere Hash, d.h. entferne alle Schlüssel/Wert-Paare. An der Menge der
zulässigen Schlüssel ändert sich dadurch nichts!

Alternative Formulierung:

    %$h = ();

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

=head2 Tests

=head3 exists() - Prüfe Schlüssel auf Existenz

=head4 Synopsis

    $bool = $h->exists($key);

=head4 Description

Prüfe, ob der angegebene Schlüssel im Hash existiert. Wenn ja,
liefere I<wahr>, andernfalls I<falsch>.

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

=head3 isEmpty() - Prüfe auf leeren Hash

=head4 Synopsis

    $bool = $->isEmpty;

=head4 Description

Prüfe, ob der Hash leer ist. Wenn ja, liefere I<wahr>,
andernfalls I<falsch>.

Alternative Formulierung:

    $bool = %$h;

=cut

# -----------------------------------------------------------------------------

sub isEmpty {
    my $self = shift;
    return %$self? 0: 1;
}

# -----------------------------------------------------------------------------

=head2 Sperren

=head3 isLocked() - Prüfe, ob Hash gesperrt ist

=head4 Synopsis

    $bool = $h->isLocked;

=head4 Description

Prüfe, ob der Hash gelockt ist. Wenn ja, liefere I<wahr>,
andernfalls I<falsch>.

Alternative Formulierung:

    Hash::Util::hash_locked(%$h);

=cut

# -----------------------------------------------------------------------------

sub isLocked {
    my $self = shift;
    return Hash::Util::hash_locked(%$self);
}

# -----------------------------------------------------------------------------

=head3 lockKeys() - Sperre Hash

=head4 Synopsis

    $h->lockKeys;

=head4 Description

Sperre den Hash. Anschließend kann kein weiterer Schlüssel zugegriffen
werden. Wird dies versucht, wird eine Exception geworfen.

Alternative Formulierung:

    Hash::Util::lock_keys(%$h);

=cut

# -----------------------------------------------------------------------------

sub lockKeys {
    my $self = shift;
    Hash::Util::lock_keys(%$self);
    return;
}

# -----------------------------------------------------------------------------

=head3 unlockKeys() - Entsperre Hash

=head4 Synopsis

    $h->unlockKeys;

=head4 Description

Entsperre den Hash. Anschließend kann der Hash uneingeschränkt
manipuliert werden.

Alternative Formulierung:

    Hash::Util::unlock_keys(%$h);

=cut

# -----------------------------------------------------------------------------

sub unlockKeys {
    my $self = shift;
    Hash::Util::unlock_keys(%$self);
    return;
}

# -----------------------------------------------------------------------------

=head2 Sonstiges

=head3 increment() - Inkrementiere Integer-Wert

=head4 Synopsis

    $n = $h->increment($key);

=head4 Description

Inkrementiere (Integer-)Wert zu Schlüssel $key und liefere das
Resultat zurück.

Alternative Formulierung:

    $n = ++$h->{$key};

=cut

# -----------------------------------------------------------------------------

sub increment {
    my ($self,$key) = @_;
    return ++$self->{$key};
}

# -----------------------------------------------------------------------------

=head3 weaken() - Erzeuge schwache Referenz

=head4 Synopsis

    $h->weaken(@keys);

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

=head2 Interna

=head3 buckets() - Ermittele/Vergrößere Bucketanzahl

=head4 Synopsis

    $n = $h->buckets;
    $n = $h->buckets($m);

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
        $self->add(this_is_a_pseudo_key=>1);
        $n = scalar %$self;
        $self->delete('this_is_a_pseudo_key');
    }
    $n =~ s|.*/||;

    return $n;
}

# -----------------------------------------------------------------------------

=head3 bucketsUsed() - Anzahl der genutzten Buckets

=head4 Synopsis

    $n = $h->bucketsUsed;

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

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
