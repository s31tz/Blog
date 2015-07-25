package Blog::Base::DbmsApi::Database;
BEGIN {
    $INC{'Blog::Base/DbmsApi/Database.pm'} ||= __FILE__;
}
use base qw/Blog::Base::Hash/;

use strict;
use warnings;

use Blog::Base::DbmsApi::Dbi::Database;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::DbmsApi::Database - Abstrakte Basisklasse für Datenbank-Verbindungen

=head1 BASE CLASS

L<Blog::Base::Hash|../../Blog::Base/Hash.html>

=head1 METHODS

=head2 Konstruktor/Destruktor

=head3 create() - Instantiiere Subklassen-Objekt

=head4 Synopsis

    $db = $class->create($udlObj);

=head4 Description

Instantiiere ein Subklassen-Datenbankverbindung auf Basis von
UDL-Objekt $udlObj und liefere eine Referenz auf das
Datenbank-Objekt zurück.

=head4 Example

    use Blog::Base::DbmsApi::Database;
    
    my $udl = 'dbi#mysql:test%root';
    my $udlObj = Blog::Base::Dbms::Udl->new($udl);
    my $db = Blog::Base::DbmsApi::Database->create($udlObj);
    print ref($db),"\n";
    __END__
    Blog::Base::Dbms::Dbi::Database

=cut

# -----------------------------------------------------------------------------

sub create {
    my $class = shift;
    my ($udlObj) = @_;

    my $apiName = ucfirst $udlObj->api;
    my ($base,$className) = $class =~ /(.*)::(\w+)$/;
    my $subClass = $base.'::'.$apiName.'::'.$className;

    return $subClass->new(@_);
}

# -----------------------------------------------------------------------------

=head3 new() - Öffne Datenbankverbindung (abstract)

=head4 Synopsis

    $db = $class->new($udlObj);

=head4 Description

Instantiiere eine Datenbankverbindung und liefere eine Referenz
auf dieses Objekt zurück.

=head3 destroy() - Schließe Datenbankverbindung (abstract)

=head4 Synopsis

    $db->destroy;

=head4 Description

Schließe die Datenbankverbindung. Die Methode liefert keinen Wert zurück.

=head2 Miscellaneous Methods

=head3 sql() - Führe SQL-Statement aus (abstract)

=head4 Synopsis

    $cur = $db->sql($stmt,$forceExec);

=head4 Description

Führe SQL-Statement $stmt auf der Datenbank $db aus, instantiiere ein
Resultat-Objekt $cur und liefere eine Referenz auf dieses Objekt
zurück.

Ist Parameter $forceExec angegeben und wahr, wird die Ausführung
des Statement forciert. Dies kann bei Oracle PL/SQL Code notwendig
sein (siehe Doku zu Blog::Base::Dbms::Database/sql).

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright © 2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
