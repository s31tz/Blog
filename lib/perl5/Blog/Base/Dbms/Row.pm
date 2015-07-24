package Blog::Base::Dbms::Row;
use base qw/Blog::Base::Object/;

use strict;
use warnings;

use Blog::Base::Universal;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Dbms::Row - Basisklasse Datensatz (abstrakt)

=head1 BASE CLASS

Blog::Base::Object

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Datensatz.

=head1 METHODS

=head2 Miscellaneous

=head3 tableClass() - Liefere Namen der Tabellenklasse

=head4 Synopsis

    $tableClass = $this->tableClass;

=head4 Returns

Name der Tabellenklasse (String)

=head4 Description

Ermittele den Namen der Tabellenklasse zur Datensatzklasse
und liefere diesen zurück.

=head4 Details

Eine Tabellenklasse speichert die Ergebnismenge einer Selektion.

Die bei einer Selektion verwendete Tabellenklasse hängt von der
Datensatz-Klasse ab. Es gelten die Defaults:

=over 2

=item *

Tabellenklasse bei Objekt-Datensätzen: C<<Blog::Base::Dbms::ResultSet::Object>>

=item *

Tabellenklasse bei Array-Datensätzen: C<<Blog::Base::Dbms::ResultSet::Array>>

=back

Abweichend vom Default kann eine abgeleitete Datensatzklasse die
Tabellenklasse über die Klassenvariable

    our $TableClass = '...';

festlegen.

Ferner ist es möglich, die Tabellenklasse bei der Selektion per
Option festzulegen:

    $tab = $rowClass->select($db,
        -tableClass=>$tableClass,
    );

=cut

# -----------------------------------------------------------------------------

my %cache;

sub tableClass {
    my $class = ref $_[0] || $_[0];

    # FXIME: auf Klasse ClassConfig umstellen (?)

    # state %cache;

    if (!$cache{$class}) {
        no strict 'refs';
        my $found = 0;
        for ($class,$class->baseClassesISA) {
            my $ref = *{"$_\::TableClass"}{SCALAR};
            if ($$ref) {
                $cache{$class} = $$ref;
                $found = 1;
                last;
            }
        }
        # Paranoia-Test
        if (!$found) {
            $class->throw(
                q{ROW-00001: Datensatz-Klasse definiert keine Tabellenklasse},
                RowClass=>$class,
            );
        }
    }

    return $cache{$class};
}

# -----------------------------------------------------------------------------

=head3 makeTable() - Erzeuge Datensatz-Tabelle

=head4 Synopsis

    $tab = $class->makeTable(\@titles,\@data);

=head4 Description

Erzeuge eine Datensatz-Tabelle mit Kolumnentiteln @titles und den
Datensätzen @rows und liefere eine Referenz auf dieses Objekt zurück.

=head4 Example

    $tab = Person->makeTable(
        [qw/per_id per_vorname per_nachname/],
        qw/1 Rudi Ratlos/,
        qw/2 Elli Pirelli/,
        qw/3 Susi Sorglos/,
        qw/4 Kai Nelust/,
    );

=cut

# -----------------------------------------------------------------------------

sub makeTable {
    my $class = shift;
    my $titles = shift;
    # @_: @rows;

    my $n = scalar @$titles;

    my @rows;
    while (@_) {
        my @arr = splice @_,0,$n;
        push @rows,$class->new($titles,\@arr);
    }

    return $class->tableClass->new($class,$titles,\@rows);
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
