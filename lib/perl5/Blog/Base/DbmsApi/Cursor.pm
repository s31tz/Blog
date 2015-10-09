package Blog::Base::DbmsApi::Cursor;
use base qw/Blog::Base::Hash1/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::DbmsApi::Cursor - Abstrakte Basisklasse für Datenbank-Cursor

=head1 BASE CLASS

L<Blog::Base::Hash1|../../Blog::Base/Hash1.html>

=head1 METHODS

=head2 Konstruktor/Destruktor

=head3 new() - Instantiiere Cursor (abstract)

=head4 Synopsis

    $cur = $class->new(@keyVal);

=head4 Description

Instantiiere ein Cursor-Objekt mit den Attributen @keyVal
und liefere dieses zurück.

=head3 destroy() - Schließe Cursor (abstract)

=head4 Synopsis

    $cur->destroy;

=head4 Description

Schließe Cursor. Die Objektreferenz ist anschließend ungültig.
Die Methode liefert keinen Wert zurück.

=head2 Accessors

=head3 bindVars() - Liefere die Anzahl der Bind-Variablen (abstract)

=head4 Synopsis

    $n = $cur->bindVars;

=head4 Description

Liefere die Anzahl der Bind-Variablen, die im SQL-Statement enthalten
waren.

=head3 bindTypes() - Setze/Liefere Datentypen der Bind-Variablen (abstract)

=head4 Synopsis

    @arr|$arr = $cur->bindTypes(@dataTypes);
    @arr|$arr = $cur->bindTypes;

=head3 hits() - Liefere die Anzahl der getroffenen Datensätze (abstract)

=head4 Synopsis

    $n = $cur->hits;

=head4 Description

Liefere die Anzahl der Datesätze, die bei der Ausführung des
Statement getroffen wurden. Im Falle einer Selektion ist dies die
Anzahl der (bislang) gelesenen Datensätze.

=head3 id() - Liefere die Id des eingefügten Datensatzes (abstract)

=head4 Synopsis

    $id = $cur->id;

=head3 titles() - Liefere eine Referenz auf Liste der Kolumnentitel (abstract)

=head4 Synopsis

    $titlesA = $cur->titles;

=head2 Miscellaneous Methods

=head3 bind() - Führe Bind-Statement aus (abstract)

=head4 Synopsis

    $cur = $cur->bind(@vals);

=head4 Description

Führe Bind-Statement aus und liefere einen (neuen) Cursor über
das Resultat der Statement-Ausführung zurück.

=head3 fetch() - Liefere den nächsten Datensatz (abstract)

=head4 Synopsis

    $row = $cur->fetch;

=head4 Description

Liefere eine Referenz auf den nächsten Datensatz der Ergebnismenge.
Ist das Ende der Ergebnismenge erreicht, liefere undef.

Der Datensatz ist ein Array mit den Kolumnenwerten.

Bei DBI liefert jeder Aufruf dieselbe Referenz, so dass das Array vom
Aufrufer normalerweise kopiert werden muss.

Nullwerte werden durch einen Leerstring repräsentiert.
Da DBI einen Nullwert durch undef repräsentiert, nimmt die
Methode eine Abbildung von undef auf '' vor.

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
