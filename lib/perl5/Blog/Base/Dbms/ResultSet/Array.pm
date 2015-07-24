package Blog::Base::Dbms::ResultSet::Array;
use base qw/Blog::Base::Dbms::ResultSet/;

use strict;
use warnings;

use Blog::Base::Array;
use Blog::Base::Hash;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Dbms::ResultSet::Array - Liste von Datensätzen in Array-Repräsentation

=head1 BASE CLASS

Blog::Base::Dbms::ResultSet

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Liste von gleichartigen
Datensätzen in Array-Repräsentation.

=head1 METHODS

=head2 Miscellaneous

=head3 columnIndex() - Liefere Index des Kolumnentitels

=head4 Synopsis

    $idx = $tab->columnIndex($title);

=head4 Description

Liefere den Index der Kolumne mit dem Titel $title. Existiert die
Kolumne nicht, löse eine Exception aus.

=cut

# -----------------------------------------------------------------------------

sub columnIndex {
    my ($self,$key) = @_;

    my $i = $self->{'titles'}->index($key);
    if ($i < 0) {
        $self->throw(q{TAB-00002: Kolumne existiert nicht},Column=>$key);
    }

    return $i;
}

# -----------------------------------------------------------------------------

=head3 defaultRowClass() - Liefere Namen der Default-Rowklasse

=head4 Synopsis

    $rowClass = $class->defaultRowClass;

=head4 Description

Liefere den Namen der Default-Rowklasse: 'Blog::Base::Dbms::Row::Array'

Auf die Default-Rowklasse werden Datensätze instanziiert, für die
bei der Instanziierung einer Table-Klasse keine Row-Klasse
explizit angegeben wurde.

=cut

# -----------------------------------------------------------------------------

sub defaultRowClass {
    return 'Blog::Base::Dbms::Row::Array';
}

# -----------------------------------------------------------------------------

=head2 Subclass Implementation

=head3 lookupSub() - Suche Datensatz

=head4 Synopsis

    $row = $tab->lookupSub($key=>$val);

=head4 Description

Durchsuche die Tabelle nach dem ersten Datensatz, dessen
Attribut $key den Wert $val besitzt und liefere diesen zurück.
Erfüllt kein Datensatz das Kriterium, liefere undef.

=head4 Details

Wird durch Basisklasse getestet

=cut

# -----------------------------------------------------------------------------

sub lookupSub {
    my ($self,$key,$val) = @_;

    my $idx = $self->columnIndex($key);

    for my $row (@{$self->rows}) {
        if ($row->[$idx] eq $val) {
            return $row;
        }
    }

    return undef;
}

# -----------------------------------------------------------------------------

=head3 values() - Liefere die Werte einer Kolumne

=head4 Synopsis

    @vals|$valA = $tab->values($key);

=cut

# -----------------------------------------------------------------------------

sub values {
    my ($self,$key) = @_;

    my $idx = $self->columnIndex($key);

    my @arr;
    for my $row (@{$self->rows}) {
        CORE::push @arr,$row->[$idx];
    }

    return wantarray? @arr: Blog::Base::Array->bless(\@arr);
}

# -----------------------------------------------------------------------------

=head3 index() - Indiziere Tabelle nach Kolumne

=head4 Synopsis

    %idx|$idxH = $tab->index($key);

=cut

# -----------------------------------------------------------------------------

sub index {
    my ($self,$key) = @_;

    my $idx = $self->columnIndex($key);

    my %idx;
    for my $row (@{$self->rows}) {
        $idx{$row->[$idx]} = $row;
    }

    return wantarray? %idx: Blog::Base::Hash->bless(\%idx);
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
