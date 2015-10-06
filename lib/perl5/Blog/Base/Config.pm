package Blog::Base::Config;
use base qw/Blog::Base::Hash/;

use strict;
use warnings;

use Blog::Base::Scalar;
use Blog::Base::Misc;
use Blog::Base::Program;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Config - Einfache Konfiguration

=head1 BASE CLASS

L<Blog::Base::Hash|../Blog::Base/Hash.html>

=head1 SYNOPSIS

    use Blog::Base::Config;
    
    my $cfg = Blog::Base::Config->new('/etc/webapp/test.conf');
    my $database = $cgf->get('database');

=head1 DESCRIPTION

Ein Objekt der Klasse Blog::Base::Config repräsentiert eine Menge von
Attribut/Wert-Paaren, die in einer Perl-Datei spezifiziert sind.

Beispiel für den Inhalt einer Konfigurationsdatei:

    host => 'localhost',
    datenbank => 'entw1',
    benutzer => ['sys','system']

=head2 Platzhalterersetzung

Im Wert einer Konfigurationsvariable können Platzhalter eingebettet
sein. Ein solcher Platzhalter wird mit Prozentzeichen (%) begrenzt
und beim Lese-Zugriff durch den Wert der betreffenden (anderen)
Konfigurationsvariable ersetzt. Beispiel:

    Konfigurationsdatei:
    
        VarDir => '/var/opt/myapp',
        SpoolDir => '%VarDir%/spool',
    
    Code:
    
        $val = $cfg->get('SpoolDir');
        # => '/var/opt/myapp/spool'

=head2 Besondere Platzhalter

=over 4

=item %CWD%

Wird ersetzt durch den Pfad des aktuellen Verzeichnisses.
Anwendungsfall: Testkonfiguration für Zugriff auf aktuelles
Verzeichnis über einen Dienst wie FTP:

    test.conf
    ---------
    FtpUrl => 'user:passw@localhost%CWD%'

=back

=head1 METHODS

=head2 Methods

=head3 new() - Instantiiere Konfigurationsobjekt

=head4 Synopsis

    [1] $cfg = $class->new($file);
    [2] $cfg = $class->new(\@dirs,$file);
    [3] $cfg = $class->new($code);

=head4 Description

[1] Instantiiere Konfigurationsobjekt aus Datei $file
und liefere eine Referenz auf dieses Objekt zurück.

[2] Durchsuche die Verzeichnisse @dirs nach Datei $file.
Die erste gefundene Datei wird geöffnet. Ein Leerstring '' in @dirs
hat dieselbe Bedeutung wie '.' und steht für das aktuelle Verzeichnis.

[3] Als Parameter ist der Konfigurationscode als Zeichenkette
der Form "$key => $val, ..." angegeben.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: $file -or- \@dirs,$file -or- $code

    my %cfg;
    if (@_ == 1 && $_[0] =~ /=>/) {
        %cfg = eval shift;
    }
    else {
        # Parameter

        my $dirA;
        if (Blog::Base::Scalar->isArrayRef($_[0])) {
            $dirA = shift;
        }
        my $cfgFile = shift;

        # Configdatei suchen, wenn \@dirs

        if ($dirA) {
            for my $dir (@$dirA) {
                my $file = $dir? "$dir/$cfgFile": $cfgFile;
                if (-e $file) {
                    $cfgFile = $file;
                    last;
                }
            }
        }

        if (!-e $cfgFile) {
            $class->throw(q{CFG-00002: Konfigurationsdatei nicht gefunden},
                ConfigFile=>$cfgFile,
            );
        }

        %cfg = Blog::Base::Misc->perlDoFile($cfgFile);
    }

    my $self = $class->bless(\%cfg);
    # $self->lockKeys;

    return $self;
}

# -----------------------------------------------------------------------------

=head3 get() - Liefere Konfigurationswerte

=head4 Synopsis

    $val = $cfg->get($key);
    @vals = $cfg->get(@keys);

=head4 Description

Liefere den Wert des Konfigurationsattributs $key bzw. die Werte
der Konfigurationsattribute @keys.

Existiert ein Konfigurationsattribut nicht, wirft die Methode eine
Exception.

=cut

# -----------------------------------------------------------------------------

sub get {
    my $self = shift;
    # @_: @keys

    # Existenz der Attribute überprüfen

    for my $key (@_) {
        if (!exists $self->{$key}) {
            $self->throw(
                q{CFG-00001: Config-Variable existiert nicht},
                Variable=>$key,
            );
        }
    }

    # Aufruf an try() delegieren
    return $self->try(@_);
}

# -----------------------------------------------------------------------------

=head3 try() - Liefere Konfigurationswerte

=head4 Synopsis

    $val = $cfg->try($key);
    @vals = $cfg->try(@keys);

=head4 Alias

getSloppy()

=head4 Description

Liefere den Wert des Konfigurationsattributs $key bzw. die Werte
der Konfigurationsattribute @keys. Existiert ein
Konfigurationsattribut nicht, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub try {
    my $self = shift;
    # @_: @keys

    my @arr;
    for my $key (@_) {
        my $val = $self->{$key};
        if (!ref $val && defined $val) {
            # Platzhalter suchen und ersetzen
            for my $key ($val =~ /%(\w+)%/g) {
                if ($key eq 'CWD') {
                    $val =~ s/%CWD%/Blog::Base::Program->cwd/e;
                }
                else {
                    $val =~ s/%$key%/$self->get($key)/e;
                }
            }
        }
        push @arr,$val;
    }

    return wantarray? @arr: $arr[0];
}

{
    no warnings 'once';
    *getSloppy = \&try;
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
