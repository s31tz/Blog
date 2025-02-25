# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Quiq::Database::Api - Lowlevel Datenbank-Schnittstelle

=head1 BASE CLASS

L<Blog::Base::Quiq::Object>

=head1 DESCRIPTION

Eine grundlegende Datenbank-Schnittstelle Blog::Base::Quiq::Database::Api::*
wird durch zwei Klassen definiert:

B<< Blog::Base::Quiq::Database::Api::*::Connection >>

  $db = $class->new($udlObj);  # Datenbankverbindung aufbauen
  $cur = $db->sql($stmt);      # SQL-Statement ausführen
  $db->destroy;                # Datenbankverbindung abbauen

B<< Blog::Base::Quiq::Database::Api::*::Cursor >>

  $cur = $class->new(@keyVal); # Cursor instantiieren
  
  $n = $cur->bindVars;         # Anzahl Bind-Variablen
  $n = $cur->hits;             # Anzahl "Treffer"
  $id = $cur->id;              # Generierter Autoinkrement-Wert
  $titlesA = $cur->titles;     # Kolumnentitel
  
  $cur2 = $cur->bind(@vals);   # Platzhalter einsetzen
  $row = $cur->fetch;          # nächsten Datensatz lesen
  
  $cur->destroy;               # Cursor schließen

Die bislang einzige Lowlevel-Datenbank-Schnittstelle ist DBI, die
die beiden Klassen umfasst:

=over 2

=item *

Blog::Base::Quiq::Database::Api::Dbi::Connection

=item *

Blog::Base::Quiq::Database::Api::Dbi::Cursor

=back

Potentielle andere Lowlevel-Datenbank-Schnittstellen müssen
die gleichen Methoden implementieren.

=cut

# -----------------------------------------------------------------------------

package Blog::Base::Quiq::Database::Api;
use base qw/Blog::Base::Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.224';

use Blog::Base::Quiq::Database::Api::Dbi::Connection;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Verbindungsaufbau

=head3 connect() - Instantiiere Lowlevel-Datenbankverbindung

=head4 Synopsis

  $db = $class->connect($udlObj);

=head4 Description

Instantiiere eine Lowlevel-Datenbankverbindung auf Basis von
UDL-Objekt $udlObj und liefere eine Referenz auf die
Datenbankverbindung zurück.

=head4 Example

  use Blog::Base::Quiq::Database::Api;
  
  my $udl = 'dbi#mysql:test%root';
  my $udlObj = Blog::Base::Quiq::Udl->new($udl);
  my $db = Blog::Base::Quiq::Database::Api->connect($udlObj);
  print ref($db),"\n";
  __END__
  Blog::Base::Quiq::Database::Api::Dbi::Connection

=cut

# -----------------------------------------------------------------------------

sub connect {
    my $class = shift;
    my ($udlObj) = @_;

    my $apiName = ucfirst $udlObj->api;
    my $apiClass = $class.'::'.$apiName.'::Connection';

    return $apiClass->new(@_);
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.224

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2025 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
