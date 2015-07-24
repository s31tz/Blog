package Blog::Base::Dbms::ResultSet::Object;
use base qw/Blog::Base::Dbms::ResultSet/;

use strict;
use warnings;

use Blog::Base::Option;
use Blog::Base::Hash;
use Blog::Base::Array;
use Blog::Base::Math;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Dbms::ResultSet::Object - Liste von Datensätzen in Objekt-Repräsentation

=head1 BASE CLASS

Blog::Base::Dbms::ResultSet

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Liste von gleichartigen
Datensätzen in Objekt-Repräsentation.

=head1 METHODS

=head2 Subklassenfunktionalität

=head3 lookupSub() - Suche Datensatz

=head4 Synopsis

    $row = $tab->lookupSub($key=>$val);

=head4 Description

Durchsuche die Tabelle nach dem ersten Datensatz, dessen
Attribut $key den Wert $val besitzt und liefere diesen zurück.
Erfüllt kein Datensatz das Kriterium, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub lookupSub {
    my ($self,$key,$val) = @_;

    for my $row (@{$self->rows}) {
        if ($row->$key eq $val) {
            return $row;
        }
    }

    return undef;
}

# -----------------------------------------------------------------------------

=head3 values() - Liefere Kolumnenwerte als Liste oder Hash

=head4 Synopsis

    @vals|$valA = $tab->values($key,@opt);
    %vals|$valH = $tab->values($key,@opt,-hash=>1);

=head4 Options

=over 4

=item -distinct => $bool (Default: 0)

Liefere in der Resultatliste nur verschiedene Kolumenwerte. Wird ein
Hash geliefert, ist dies zwangsläufig der Fall. Der Wert findet
sich in der Resultatliste an der Stelle seines ersten Auftretens.

=item -hash => $bool (Default: 0)

Liefere einen Hash bzw. eine Hashreferenz (Blog::Base::Hash) mit den
Kolumnenwerten als Schlüssel und 1 als Wert.

=item -notNull => $bool (Default: 0)

Ignoriere Nullwerte, d.h. nimm sie nicht ins Resultat auf.

=back

=cut

# -----------------------------------------------------------------------------

sub values {
    my $self = shift;
    my $key = shift;
    # @_: @opt

    my $distinct = 0;
    my $hash = 0;
    my $notNull = 0;

    if (@_) {
        Blog::Base::Option->extract(\@_,
            -distinct=>\$distinct,
            -hash=>\$hash,
            -notNull=>\$notNull,
        );
    }

    my (@arr,%seen);
    for my $row (@{$self->rows}) {
        my $val = $row->$key;
        if ($notNull && $val eq '') {
            next;
        }
        if ($distinct && $seen{$val}++) {
            next;
        }
        CORE::push @arr,$val;
        if ($hash) {
            CORE::push @arr,1;
        }
    }

    if (wantarray) {
        return @arr;
    }
    elsif ($hash) {
        return Blog::Base::Hash->bless({@arr});
    }
    else {
        return Blog::Base::Array->bless(\@arr);
    }
}

# -----------------------------------------------------------------------------

=head3 index() - Indiziere Tabelle nach Kolumne

=head4 Synopsis

    %idx|$idxH = $tab->index($key);

=cut

# -----------------------------------------------------------------------------

sub index {
    my ($self,$key) = @_;

    my %idx;
    for my $row (@{$self->rows}) {
        $idx{$row->$key} = $row;
    }

    return wantarray? %idx: Blog::Base::Hash->bless(\%idx);
}

# -----------------------------------------------------------------------------

=head2 Verschiedenes

=head3 absorbModifications() - Absorbiere Datensatz-Änderungen

=head4 Synopsis

    $tab->absorbModifications;

=head4 Returns

nichts

=head4 See Also

$row->absorbModifications()

=cut

# -----------------------------------------------------------------------------

sub absorbModifications {
    my $self = shift;

    for my $row (@{$self->rows}) {
        $row->absorbModifications;
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 addAttribute() - Füge Attribut zu Datensätzen hinzu

=head4 Synopsis

    $tab->addAttribute($key=>$val);

=head4 Arguments

=over 4

=item $key

Attributname.

=item $val

Attributwert.

=back

=head4 Returns

Nichts

=head4 Description

Füge Attribut $key mit Wert $val zu allen Datensätzen der
Ergebnismenge hinzu.

=cut

# -----------------------------------------------------------------------------

sub addAttribute {
    my ($self,$key,$val) = @_;

    for my $row (@{$self->rows}) {
        $row->addAttribute($key=>$val);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 normalizeNumber() - Normalisiere Zahldarstellung

=head4 Synopsis

    $tab->normalizeNumber(@titles);

=head4 Alias

fixNumber()

=head4 Returns

nichts

=head4 Description

Normalisiere die Zahldarstellung der genannten Kolumnen. D.h. entferne
unnötige Nullen und forciere als Dezimaltrennzeichen einen Punkt
(anstelle eines Komma).

=cut

# -----------------------------------------------------------------------------

sub normalizeNumber {
    my $self = shift;
    # @_: @titles

    for my $row (@{$self->rows}) {
        for my $title (@_) {
            my $val = $row->$title;
            $val = Blog::Base::Math->normalizeNumber($val);
            $row->$title($val);
        }
    }

    return;
}

{
    no warnings 'once';
    *fixNumber = \&normalizeNumber;
}

# -----------------------------------------------------------------------------

=head3 selectChilds() - Selektiere Kind-Datensätze

=head4 Synopsis

    @rows|$rowT = $tab->selectChilds($db,$primaryKeyColumn,
        $foreignTable,$foreignKeyColumn,@opt);

=head4 Options

=over 4

=item -type => $type (Default: "$foreignTable.$foreignKeyColumn")

Bezeichner für den Satz an Kind-Objekten.

=item I<Select-Optionen>

Select-Optionen, die der Selektion der Kinddatensätze
hinzugefügt werden.

=back

=head4 Description

Selektiere alle Datensätze der Tabelle $foreignTable, deren
Kolumne $foreignKeyColumn auf die Kolumne $primaryKeyColumn
verweist und liefere diese zurück.

Die Kind-Datensätze werden ihren Eltern-Datensätzen zugeordnet
und können per

    @childRows = $row->childs("$foreignTable,$foreignKeyColumn");

oder

    $childRowT = $row->childs("$foreignTable,$foreignKeyColumn");

abgefragt werden. Z.B.

    -select=>@titles oder -oderBy=>@titles

Mittels der Option C<<-type=>$type>> kann ein anderer Typbezeichner
anstelle von "$foreignTable,$foreignKeyColumn" für den Satz an
Kinddatensätzen vereinbart werden.

=cut

# -----------------------------------------------------------------------------

sub selectChilds {
    my $self = shift;
    my $db = shift;
    my $primaryKeyColumn = shift;
    my $foreignTable = shift;
    my $foreignKeyColumn = shift;
    # @_: @opt

    # Optionen

    my $type = "$foreignTable.$foreignKeyColumn";

    Blog::Base::Option->extract(-mode=>'sloppy',\@_,
        -type=>\$type,
    );

    # Subselect generieren

    my $stmt = $self->stmtBody;
    $stmt = "SELECT\n    $primaryKeyColumn\n$stmt";
    $stmt =~ s/^/    /gm;

    # Kind-Datensätze selektieren
    # (die restlichen Optionen sind Select-Optionen)

    my $tab = $db->select($foreignTable,
        -where,"$foreignKeyColumn IN (\n$stmt\n)",
        @_,
    );

    # Kind-Datensätze zuordnen

    my $rowClass = $tab->rowClass;
    my $titleA = $tab->titles;

    # Eltern-Datensätze um Kind-Typ erweitern

    for my $row ($self->rows) {
        $row->addChildRowType($type,$rowClass,$titleA);
    }

    # Indiziere Eltern-Datensätze nach Primärschlüssel
    my %idx = $self->index($primaryKeyColumn);

    for my $childRow ($tab->rows) {
        my $key = $childRow->$foreignKeyColumn;
        my $parentRow = $idx{$key} || die;

        # Kind-Datensatz zum Elterndatensatz hinzufügen
        $parentRow->addChildRow($type,$childRow);
    }

    return wantarray? $tab->rows: $tab;
}

# -----------------------------------------------------------------------------

=head3 selectParents() - Selektiere Parent-Datensätze

=head4 Synopsis

    @rows|$rowT = $tab->selectParents($db,$foreignKeyColumn,
        $parentTable,$primaryKeyColumn,@opt);

=head4 Options

=over 4

=item -type => $type (Default: $foreignKeyColumn)

Bezeichner für den Parent-Datensatz beim Child-Datensatz.

=item I<Select-Optionen>

Select-Optionen, die der Selektion der Parent-Datensatzes
hinzugefügt werden.

=back

=head4 Description

Selektiere alle Datensätze der Tabelle $parentTable, auf die
von der Kolumne $foreignKeyColumn aller in Tabelle $tab
enthaltenen Datensätze verwiesen wird und liefere diese zurück.

Der Parent-Datensatz wird jeweils seinem Kind-Datensatz
zugeordnet und kann per

    $parentRow = $row->parent($foreignKeyColumn);

abgefragt werden.

Mittels der Option C<<-type=>$type>> kann ein anderer Typbezeichner
anstelle von "$foreignKeyColumn" für den Parent-Datensatz
vereinbart werden.

=cut

# -----------------------------------------------------------------------------

sub selectParents {
    my $self = shift;
    my $db = shift;
    my $foreignKeyColumn = shift;
    my $parentTable = shift;
    my $primaryKeyColumn = shift;
    # @_: @opt

    # Optionen

    my $type = $foreignKeyColumn;

    Blog::Base::Option->extract(-mode=>'sloppy',\@_,
        -type=>\$type,
    );

    # Subselect generieren

    my $stmt = $self->stmtBody;
    $stmt = "SELECT\n    $foreignKeyColumn\n$stmt";
    $stmt =~ s/^/    /gm;

    # Parent-Datensätze selektieren
    # (die restlichen Optionen sind Select-Optionen)

    my $tab = $db->select($parentTable,
        -where,"$primaryKeyColumn IN (\n$stmt\n)",
        @_,
    );
    my %idx = $tab->index('id');

    # Datensätze mit Eltern-Datensatz verknüpfen erweitern

    for my $row ($self->rows) {
        my $parentRow;
        if (my $parentId = $row->$foreignKeyColumn) {
           $parentRow = $idx{$parentId} || $self->throw;
        }
        $row->addParentRow($foreignKeyColumn=>$parentRow);
    }

    return wantarray? $tab->rows: $tab;
}

# -----------------------------------------------------------------------------

=head3 selectParentRows() - Selektiere Datensätze via Schlüsselkolumne

=head4 Synopsis

    @rows|$rowT = $tab->selectParentRows($db,$fkTitle,$pClass,@select);

=head4 Returns

=over 4

=item Array-Kontext

Liste von Datensätzen

=item Skalar-Kontext

Tabellenobjekt (Blog::Base::Dbms::ResultSet::Object)

=back

=head4 Description

Die Methode ermöglicht es, Fremschlüsselverweise einer Selektion
durch effiziente Nachselektion aufzulösen.

Die Methode selektiert die Elterndatensätze der Tabellen-Klasse
C<$pClass> zu den Fremdschlüsselwerten der Kolumne C<$fkTitle> und
den zusätzlichen Selektionsdirektiven C<@select>. Die
Selektionsdirektiven sind typischerweise C<-select> und C<-orderBy>.

Die Klasse C<$pClass> muss eine Tabellenklasse sein, denn nur diese
definiert eine Primäschlüsselkolumne.

=head4 Example

Bestimme Informationen zu Route, Abschnitt, Fahrt, Fahrt_Parameter
und Parameter zu der Kombination aus Fahrten und Parametern:

     1: my @pas_id = $req->getArray('pas_id');
     2: my @mea_id = $req->getArray('mea_id');
     3: 
     4: my $tab = FerryBox::Model::Join::RouSecPasPamMea->select($db2,
     5:     -select=>'rou.id rou_id','sec.id sec_id','pas.id pas_id',
     6:         'pam.id pam_id','mea.id mea_id',
     7:     -where,
     8:         'pas.id'=>['IN',@pas_id],
     9:         'mea.id'=>['IN',@mea_id],
    10: );
    11: 
    12: my $rouT = $tab->selectParentRows($db2,
    13:     rou_id=>'FerryBox::Model::Table::Route',
    14:     -select=>qw/id name/,
    15: );
    16: 
    17: my $secT = $tab->selectParentRows($db2,
    18:     sec_id=>'FerryBox::Model::Table::Section',
    19:     -select=>qw/id route_id secname/,
    20: );
    21: 
    22: my $pasT = $tab->selectParentRows($db2,
    23:     pas_id=>'FerryBox::Model::Table::Passage',
    24:     -select=>qw/id section_id starttime/,
    25: );
    26: 
    27: my $pamT = $tab->selectParentRows($db2,
    28:     pam_id=>'FerryBox::Model::Table::Passage_Measseq',
    29:     -select=>qw/id passage_id measseq_id/,
    30: );
    31: 
    32: my $meaT = $tab->selectParentRows($db2,
    33:     mea_id=>'FerryBox::Model::Table::Measseq',
    34:     -select=>qw/id route_id meas/,
    35: );

=cut

# -----------------------------------------------------------------------------

sub selectParentRows {
    my ($self,$db,$fkTitle,$pClass,@select) = @_;

    # Bestimme alle Foreign-Key-Werte
    my @pkValues = $self->values($fkTitle,-notNull=>1,-distinct=>1);

    # Bestimme PK-Kolumne der Parent-Tabelle
    my $pkTitle = $pClass->primaryKey($db);

    # Selektiere alle Parent-Datensätze

    return $pClass->select($db,
        -where,'+null',$pkTitle=>['IN',@pkValues],
        @select,
    );
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
