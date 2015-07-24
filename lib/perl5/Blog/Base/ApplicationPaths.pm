package Blog::Base::ApplicationPaths;
use base qw/Blog::Base::RestrictedHash/;

use strict;
use warnings;

use 5.010;
use Cwd ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::ApplicationPaths - Determine fundamental paths of an Unix application

=head1 BASE CLASS

Blog::Base::RestrictedHash

=head1 SYNOPSIS

Pfadsetzung:

    PATH=<application_homedir>/bin:$PATH

Programmcode:

    # Applikationsinstallation mit Versionisierung
    # /opt/<app>/version/<version>/bin/<prog>
    
    use FindBin qw/$Bin/;
    use lib "$Bin/../lib/perl5";           # $depth = 1, siehe new()
    use Blog::Base::ApplicationPaths;
    
    my $app = Blog::Base::ApplicationPaths->new($depth);        # <-- $depth = Anzahl ../ oben
    
    my $name = $app->name;                 # <app>
    my $version = $app->version;           # <version>
    
    my $prefix = $app->prefix($subPath);   # '' (Leerstring)
    
    my $rootDir = $app->rootDir($subPath); # /opt/<app>
    my $homeDir = $app->homeDir($subPath); # /opt/<app>/version/<version>
    my $etcDir = $app->etcDir($subPath);   # /etc/opt/<app>
    my $varDir = $app->varDir($subPath);   # /var/opt/<app>
    
    my $etcPath = $app->etcPath($suffix);  # /etc/opt/<app>
    my $varPath = $app->varPath($suffix);  # /var/opt/<app>

Beispiele siehe im Testcode.

=head1 DESCRIPTION

Die Klasse ermöglicht einer Applikation ohne hartkodierte absolute
Pfade auszukommen. Alle Pfade, unter denen sich die verschiedenen
Teile einer Applikation (opt-, etc-, var-Bereich) im Dateisystem
befinden, werden von der Klasse aus dem Pfad des ausgeführten
Programms und Installations-Konventionen hergeleitet.

Wir unterscheiden zwei Installations-Konventionen (Layouts).

Layout 1:

=over 2

=item *

/opt/<app> (Programmcode und statische Daten)

=item *

/etc/opt/<app> (Konfiguration)

=item *

/var/opt/<app> (Bewegungsdaten)

=back

Layout 2:

=over 2

=item *

/opt/<app> (Programmcode und statische Daten)

=item *

/etc/<app> (Konfiguration)

=item *

/var/<app> (Bewegungsdaten)

=back

Die Pfade müssen nicht im Root-Verzeichnis beginnen, ihnen kann
auch Präfix-Pfad <prefix> vorangestellt sein. In dem Fall ist
<app> in einem tieferen Teil des Dateisystems installiert,
z.B. im Home-Verzeichnis eines Benutzers.

Layout 1 entspricht der modernen opt-Installatiosstruktur eines
Unix-Systems und kommt vorzugsweise zur Anwendung, wenn das
opt-Verzeichnis im Root-Verzeichnis liegt.

Layout 2 ist eine klassische Struktur, die vorzugsweise zur Anwendung
kommt, wenn die Installation tiefer im Dateisystem liegt, also
den Pfaden noch ein Präfix-Pfad <prefix> vorangestellt ist.
Beispiel:

    /home/<user>/opt/<app>
    /home/<user>/etc/<app>
    /home/<user>/var/<app>

Zu jedem Layout ist eine unversionisierte und eine versionisierte
Installation möglich. Die versionisierte Installation stellt eine
Erweiterung der obigen Layouts dar.

Unversionierte Installation:

    <prefix>/opt/<app>/...

Versionierte Installation:

    <prefix>/opt/<app>/version/<version>/...

Der Konstruktor der Klasse erkennt das Layout der Installation und
die Objektmethoden liefern Informationen über die Installation.

=head1 EXAMPLES

=over 2

=item *

/opt/<app>/...

    name() => : <app>
    version() => : (Leerstring)
    prefix () => : (Leerstring)
    rootDir() => : /opt/<app>
    homeDir() => : /opt/<app>
    etcDir(), etcPath() => : /etc/opt/<app>
    varDir(), varPath() => : /var/opt/<app>
=item *

/opt/<app>/version/<version>/...

    name() => : <app>
    version() => : <version>
    prefix () => : (Leerstring)
    rootDir() => : /opt/<app>
    homeDir() => : /opt/<app>/version/<version>
    etcDir(), etcPath() => : /etc/opt/<app>/<version>
    varDir(), varPath() => : /var/opt/<app>/<version>
=item *

/home/<user>/opt/<app>/...

    name() => : <app>
    version() => : (Leerstring)
    prefix () => : /home/<user>
    rootDir() => : /home/<user>/opt/<app>
    homeDir() => : /home/<user>/opt/<app>
    etcDir(), etcPath() => : /home/<user>/etc/<app>
    varDir(), varPath() => : /home/<user>/var/<app>
=item *

/home/<user>/opt/<app>/version/<version>/...

    name() => : <app>
    version() => : <version>
    prefix () => : /home/<user>
    rootDir() => : /home/<user>/opt/<app>
    homeDir() => : /home/<user>/opt/<app>/version/<version>
    etcDir(), etcPath() => : /home/<user>/etc/<app>/<version>
    varDir(), varPath() => : /home/<user>/var/<app>/<version>
=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $app = $class->new;
    $app = $class->new($depth);
    $app = $class->new($depth,$layout);

=head4 Arguments

=over 4

=item $depth (Default: 1)

Gibt an, wie viele Subverzeichnisse tief das Programm unterhalb des
Homedir (/opt/<app> bzw. /opt/<app>/version/<version>) angesiedelt ist.

=item $layout (Default: 1)

Forciert ein bestimmtes Layout. Mögliche Werte: 1 oder 2 (s.o.).

=back

=head4 Description

Instantiiere ein Objekt der Klasse und liefere dieses zurück. Das Objekt
ist ein Singleton.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $depth = shift // 1;
    my $layout = shift || 1;

    # Wir arbeiten nicht mit den Variablen von FindBin, da diese
    # Symlinks auflösen und wir keinen Symbolischen Namen wie
    # 'prod' als Version erhalten, wenn dies ein Symlink auf eine
    # reale Version ist.

    my $path = $0;
    if ($path !~ m|^/|) {
        # Einen relativen Pfad ergänzen wir um das aktuelle Verzeichnis.
        # Achtung: getcwd liefert möglicherweise nicht den Versionspfad
        # den wir meinen, wenn wir unterhalb von version/<version> stehen.
        # Denn getcwd liefert den realen Pfad und beinhaltet keine Symlinks.
        # Wenn <version> ein Symlink ist, erscheint der reale Name im Pfad.

        $path =~ s|^./||;
        $path = sprintf '%s/%s',Cwd::getcwd,$path;
    }

    my @path = split m|/|,$path;
    splice @path,-($depth+1);
    my $homeDir = join '/',@path;

    my ($name,$version,$rootDir,$etcPath,$varPath);
    if ($path[-2] eq 'version') {
        $name = $path[-3];
        $version = $path[-1];
        splice @path,-2; # entferne: version/<version>
        $rootDir = join '/',@path;
        $etcPath = "$name/$version";
        $varPath = "$name/$version";
    }
    else {
        $name = $path[-1];
        $version = '';
        $rootDir = $homeDir;
        $etcPath = $name;
        $varPath = $name;
    }

    pop @path; # <name> entfernen
    my $parent = pop @path; # Pfadkomponente über <name>
    my $prefix = join '/',@path;

    if ($layout == 1) {
        $etcPath = "$prefix/etc/opt/$etcPath";
        $varPath = "$prefix/var/opt/$varPath";
    }
    else {
        $etcPath = "$prefix/etc/$etcPath";
        $varPath = "$prefix/var/$varPath";
    }

    return $class->SUPER::new(
        name=>$name,
        version=>$version,
        prefix=>$prefix,
        rootDir=>$rootDir,
        homeDir=>$homeDir,
        etcPath=>$etcPath,
        varPath=>$varPath,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 name() - Name der Applikation

=head4 Synopsis

    $name = $app->name;

=head4 Description

Liefere den Namen <name> der Applikation.

=cut

# -----------------------------------------------------------------------------

sub name {
    shift->{'name'};
}

# -----------------------------------------------------------------------------

=head3 version() - Version der Applikation

=head4 Synopsis

    $version = $app->version;

=head4 Description

Liefere die Version <version> der Applikation. Ist die Installation nicht
versionisiert, liefere '' (Leerstring).

=cut

# -----------------------------------------------------------------------------

sub version {
    shift->{'version'};
}

# -----------------------------------------------------------------------------

=head3 prefix() - Pfad-Präfix der Installation

=head4 Synopsis

    $prefix = $app->prefix;
    $prefix = $app->prefix($subPath);

=head4 Description

Liefere den Pfad-Präfix <prefix> der Installation, also den Pfad
oberhalb des opt-Verzeichnisses. Ist die Applikation in /opt
installiert, liefere den Wert '' (Leerstring).

=cut

# -----------------------------------------------------------------------------

sub prefix {
    my $self = shift;
    # @_: $subPath

    my $path = $self->{'prefix'};
    if (@_) {
        $path .= '/'.shift;
    }

    return $path;
}

# -----------------------------------------------------------------------------

=head3 rootDir() - Wurzelverzeichnis der Applikation

=head4 Synopsis

    $rootDir = $app->rootDir;
    $rootDir = $app->rootDir($subPath);

=head4 Description

Liefere das Wurzelverzeichnis der Applikation <prefix>/opt/<name>.
Wenn die Installation I<nicht> versionisiert ist, ist das
Wurzelverzeichnis der Applikation gleich dem Home-Verzeichnis der
Applikation.

=cut

# -----------------------------------------------------------------------------

sub rootDir {
    my $self = shift;
    # @_: $subPath

    my $path = $self->{'rootDir'};
    if (@_) {
        $path .= '/'.shift;
    }

    return $path;
}

# -----------------------------------------------------------------------------

=head3 homeDir() - Home-Verzeichnis der Applikation

=head4 Synopsis

    $homeDir = $app->homeDir;
    $homeDir = $app->homeDir($subPath);

=head4 Description

Das Home-Verzeichnis der Applikation ist das Verzeichnis, in dem
der Programmcode und statische Daten abgelegt sind.

Bei einer unversionisierten Installation:

    <prefix>/opt/<app>

Bei einer versionisierten Installation:

    <prefix>/opt/<app>/version/<version>

=cut

# -----------------------------------------------------------------------------

sub homeDir {
    my $self = shift;
    # @_: $subPath

    my $path = $self->{'homeDir'};
    if (@_) {
        $path .= '/'.shift;
    }

    return $path;
}

# -----------------------------------------------------------------------------

=head3 etcDir() - Konfigurations-Verzeichnis der Applikation

=head4 Synopsis

    $etcDir = $app->etcDir;
    $etcDir = $app->etcDir($subPath);

=head4 Description

Das Konfigurations-Verzeichnis der Applikation ist das Verzeichnis,
in dem die Konfigurationsdateien der Applikation abgelegt sind.

Bei einer unversionisierten Installation:

    /etc/opt/<app>
    -oder-
    <prefix>/etc/<app>

Bei einer versionisierten Installation:

    /etc/opt/<app>/<version>
    -oder-
    <prefix>/etc/<app>/<version>

=cut

# -----------------------------------------------------------------------------

sub etcDir {
    my $self = shift;
    # @_: $subPath

    my $path = $self->etcPath;
    if (@_) {
        $path .= '/'.shift;
    }

    return $path;
}

# -----------------------------------------------------------------------------

=head3 etcPath() - Konfigurations-Pfad der Applikation

=head4 Synopsis

    $etcPath = $app->etcPath;
    $etcPath = $app->etcPath($suffix);

=head4 Description

Ohne Parameter gerufen liefert die Methode den gleichen Wert
wie etcDir(). Ist ein Parameter angegeben, wird dieser
ohne Trennzeichen konkateniert.

=cut

# -----------------------------------------------------------------------------

sub etcPath {
    my $self = shift;
    # @_: $suffix

    my $path = $self->{'etcPath'};
    if (@_) {
        $path .= shift;
    }

    return $path;
}

# -----------------------------------------------------------------------------

=head3 varDir() - Bewegungsdaten-Verzeichnis der Applikation

=head4 Synopsis

    $varDir = $app->varDir;
    $varDir = $app->varDir($subPath);

=head4 Description

Das Bewegungsdaten-Verzeichnis der Applikation ist das Verzeichnis,
in dem die Applikation Bewegungsdaten speichert.

Bei einer unversionisierten Installation:

    /var/opt/<app>
    -oder-
    <prefix>/var/<app>

Bei einer versionisierten Installation:

    /var/opt/<app>/<version>
    -oder-
    <prefix>/var/<app>/<version>

=cut

# -----------------------------------------------------------------------------

sub varDir {
    my $self = shift;
    # @_: $subPath

    my $path = $self->varPath;
    if (@_) {
        $path .= '/'.shift;
    }

    return $path;
}

# -----------------------------------------------------------------------------

=head3 varPath() - Bewegungsdaten-Pfad der Applikation

=head4 Synopsis

    $varPath = $app->varPath;
    $varPath = $app->varPath($suffix);

=head4 Description

Ohne Parameter gerufen liefert die Methode den gleichen Wert
wie varDir(). Ist ein Parameter angegeben, wird dieser
ohne Trennzeichen konkateniert.

=cut

# -----------------------------------------------------------------------------

sub varPath {
    my $self = shift;
    # @_: $suffix

    my $path = $self->{'varPath'};
    if (@_) {
        $path .= shift;
    }

    return $path;
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
