package Blog::Base::FileSystem;
use base qw/Blog::Base::Object/;

use strict;
use warnings;

use Blog::Base::Program;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::FileSystem - Dateisystem-Operationen

=head1 BASE CLASS

Blog::Base::Object

=head1 DESCRIPTION

Die Klasse definiert Basis-Dateisystem-Operationen wie link, mkdir,
rename, symlink usw. Im Unterschied zur Klasse Blog::Base::Path werden
von dieser Klasse keine Objekte instanziiert. Die Methoden erwarten
Pfadangaben als Strings und werfen eine Exception im Fehlerfall.

=head1 METHODS

=head2 isRelative() - Prüfe, ob Pfad relativ ist

=head3 Synopsis

    $bool = $class->isRelative($path);

=cut

# -----------------------------------------------------------------------------

sub isRelative {
    my ($class,$path) = @_;
    return substr($path,0,1) eq '/'? 0: 1;
}

# -----------------------------------------------------------------------------

=head2 link() - Erzeuge Link

=head3 Synopsis

    $class->link($path,$link);

=head3 Description

Erzeuge Link $link auf Pfad $path.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub link {
    my ($class,$path,$link) = @_;

    CORE::link $path,$link or do {
        $class->throw(
            q{FS-00002: Kann Link nicht erzeugen},
            Path=>$path,
            Link=>$link,
            Error=>$!,
        );
    };

    return;
}

# -----------------------------------------------------------------------------

=head2 rename() - Benenne Pfad um

=head3 Synopsis

    $class->rename($oldName,$newName);

=head3 Arguments

=over 4

=item $oldName

Aktueller Dateiname

=item $newName

Zukünftiger Dateiname

=back

=head3 Returns

nichts

=head3 Description

Benenne Pfad $oldName in $newName um.

=cut

# -----------------------------------------------------------------------------

sub rename {
    my ($class,$oldName,$newName) = @_;

    CORE::rename $oldName,$newName or do {
        $class->throw(
            q{FS-00003: Kann Pfad nicht umbenennen},
            OldPath=>$oldName,
            NewPath=>$newName,
        );
    };

    return;
}

# -----------------------------------------------------------------------------

=head2 symlink() - Erzeuge Symlink

=head3 Synopsis

    $class->symlink($path,$symlink);

=head3 Description

Erzeuge Symlink $symlink auf Pfad $path.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub symlink {
    my ($class,$path,$symlink) = @_;

    CORE::symlink $path,$symlink or do {
        $class->throw(
            q{FS-00001: Kann Symlink nicht erzeugen},
            Path=>$path,
            Symlink=>$symlink,
            Error=>$!,
        );
    };

    return;
}

# -----------------------------------------------------------------------------

=head2 symlinkRelative() - Erzeuge Symlink mit relativem Zielpfad

=head3 Synopsis

    $class->symlinkRelative($path,$symlink,@opt);

=head3 Options

=over 4

=item -dryRun => $bool (Default: 0)

Führe das Kommando nicht aus. Speziell Verbindung mit
-verbose=>1 sinnvoll, um Code zu testen.

=item -verbose => $bool (Default: 0)

Gib Informationen über die erzeugten Symlinks auf STDOUT aus.

=back

=head3 Description

Erzeuge einen Symlink $symlink, der auf den Pfad $path verweist.
Die Methode liefert keinen Wert zurück.

Die Methode zeichnet sich gegenüber der Methode symlink() dadurch
aus, dass sie, wenn $path ein relativer Pfad zum ist,
diesen so korrigiert, dass er von Pfad
auch von $symlink aus korrekt ist. Denn der Pfad $path ist als
relativer Pfad die Fortsetzung von $symlink!

=head3 Example

    Blog::Base::FileSystem->symlinkRelative('a','x')
    # x => a
    
    Blog::Base::FileSystem->symlinkRelative('a/b','x')
    # x => a/b
    
    Blog::Base::FileSystem->symlinkRelative('a/b','x/y')
    # x/y => ../a/b
    
    Blog::Base::FileSystem->symlinkRelative('a/b','x/y/z')
    # x/y/z => ../../a/b

=cut

# -----------------------------------------------------------------------------

sub symlinkRelative {
    my $class = shift;
    my $path = shift;
    my $symlink = shift;
    my %opt = @_;

    my $dryRun = delete $opt{'-dryRun'};
    my $verbose = delete $opt{'-verbose'};
    if (%opt) {
        $class->throw(
            q{FILESYS-00001: Unbekannte Option(en)},
            Options=>join(', ',keys %opt),
        );
    }

    # Sonderbehandlung, wenn der Pfad $path, auf den der Symlink zeigt,
    # relativ ist. Da der Pfad $path relativ zum Symlink gilt
    # und nicht relativ zum aktuellen Verzeichnis des Aufrufers
    # interpretiert wird, muss der Zielpfad ergänzt werden,
    # wenn der Symlink-Pfad nicht im aktuellen Verzeichnis liegt.
    # Die Pfad-Umschreibung nimmt diese Methode vor.

    my $pathIsRelative = $class->isRelative($path);
    if ($pathIsRelative && $symlink =~ m|/|) {
        my $symlinkIsRelative = $class->isRelative($symlink);
        if ($symlinkIsRelative) {
            # Wenn $symlink relativ ist, $path die Anzahl der
            # $symlink-Directories voranstellen

            my $n = $symlink =~ tr|/||;
            my $prefix = '';
            for (my $i = 0; $i < $n; $i++) {
                $prefix .= '../';
            }
            $path = "$prefix$path";
        }
        else {
            # Wenn $symlink absolut ist, $path das aktuelle
            # Verzeichnis voranstellen.
            $path = sprintf '%s/%s',Blog::Base::Program->cwd,$path;
        }
    }
    if ($verbose) {
        print "$symlink => $path\n";
    }
    if (!$dryRun) {
        $class->symlink($path,$symlink);
    }

    return;
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
