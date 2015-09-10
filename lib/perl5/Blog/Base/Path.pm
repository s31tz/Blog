package Blog::Base::Path;
BEGIN {
    $INC{'Blog::Base/Path.pm'} ||= __FILE__;
}
use base qw/Blog::Base::Object/;

use strict;
use warnings;
use utf8;

use overload '""'=>'asString',cmp=>sub { ${$_[0]} cmp (ref($_[1])? ${$_[1]}: $_[1]) };
use Blog::Base::Process;
use File::Find ();
use Blog::Base::Array;
use Blog::Base::Misc;
use Blog::Base::DirHandle;
use Blog::Base::FileHandle;
use Encode::Guess ();
use Fcntl qw/:DEFAULT/;
use Blog::Base::Shell;
use Blog::Base::FileSystem;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Path - Dateisystem-Pfad

=head1 BASE CLASS

L<Blog::Base::Object|../Blog::Base/Object.html>

=head1 SYNOPSIS

    use Blog::Base::Path;
    
    my $obj = Blog::Base::Path->new($path);
    my $bool = $obj->isDir;
    
    # oder
    
    use Blog::Base::Path;
    
    my $bool = Blog::Base::Path->isDir($path);

=head1 DESCRIPTION

Ein Objekt der Klasse Blog::Base::Path repräseniert einen Dateisystem-Pfad.

Alle Methoden (außer dem Konstruktor) können als Instanz- oder als
Klassenmethode gerufen werden. Der Aufruf als Klassenmethode ist
praktisch, wenn eine einzige Operation auf dem Pfad ausgeführt
werden soll. Bei mehreren Operationen ist ein Objekt vorteilhaft,
da der Code dann übersichtlicher ist.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Pfad-Objekt

=head4 Synopsis

    $obj = $class->new($path);

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$path) = @_;
    $path = '' if !defined $path;
    return bless \$path,$class;
}

# -----------------------------------------------------------------------------

=head2 Accessor

=head3 path() - Liefere Pfad

=head4 Synopsis

    $path = $obj->path;

=head4 Alias

asString()

=cut

# -----------------------------------------------------------------------------

sub path {
    return ${$_[0]};
}

{
    no warnings 'once';
    *asString = \&path;
}

# -----------------------------------------------------------------------------

=head2 Tests

=head3 exists() - Test auf Existenz

=head4 Synopsis

    $bool = $obj->exists;
    $bool = $class->exists($path);

=cut

# -----------------------------------------------------------------------------

sub exists {
    my $self = shift;
    $self = \shift if !ref $self; # Klassenmethode
    return -e $$self? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isDir() - Test auf Verzeichnis

=head4 Synopsis

    $bool = $obj->isDir;
    $bool = $class->isDir($path);

=head4 Description

Liefere "wahr", wenn Pfad ein Verzeichnis ist, andernfalls "falsch".

=cut

# -----------------------------------------------------------------------------

sub isDir {
    my $self = shift;
    $self = \shift if !ref $self; # Klassenmethode
    return -d $$self? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 isEmpty() - Test, ob Datei oder Verzeichnis leer ist

=head4 Synopsis

    $bool = $obj->isEmpty;
    $bool = $class->isEmpty($path);

=cut

# -----------------------------------------------------------------------------

sub isEmpty {
    my $self = shift;
    $self = \shift if !ref $self; # Klassenmethode

    if (-d $$self) {
        local *D;

        my $i = 0;
        unless (opendir D,$$self) {
            $self->throw(
                q{PATH-00005: Verzeichnis kann nicht geöffnet werden},
                Path=>$$self,
                Error=>"$!",
            );
        }
        while (readdir D) {
            last if ++$i > 2;
        }
        closedir D;

        return $i <= 2? 1: 0;
    }
    else {
        return -z $$self? 1: 0;
    }
}

# -----------------------------------------------------------------------------

=head2 Directory Operations

=head3 cd() - Wechsele in Verzeichnis

=head4 Synopsis

    $obj->cd;
    $class->cd($path);

=cut

# -----------------------------------------------------------------------------

sub cd {
    my $self = ref($_[0])? shift: shift->new(shift);

    if (!defined($$self) || $$self eq '' || $$self eq '.') {
        return;
    }

    CORE::chdir $$self or do {
        my $cwd = Blog::Base::Process->cwd;
        $self->throw(
            q{PATH-00009: Kann nicht in Verzeichnis wechseln},
            Path=>$$self,
            CurrentWorkingDirectory=>$cwd,
        );
    };

    return;
}

# -----------------------------------------------------------------------------

=head3 expandTilde() - Expandiere Tilde

=head4 Synopsis

    $path = $class->expandTilde($path);

=head4 Returns

Pfad (String)

=head4 Description

Ersetze eine Tilde am Pfadanfang durch das Home-Verzeichnis des
Benutzers und liefere den resultierenden Pfad zurück.

=cut

# -----------------------------------------------------------------------------

sub expandTilde {
    my ($class,$path) = @_;

    if (!exists $ENV{'HOME'}) {
        $class->throw(
            q{PATH-00016: Environment-Variable HOME existiert nicht},
        );
    }
    $path =~ s|^~/|$ENV{'HOME'}/|;

    return $path;
}

# -----------------------------------------------------------------------------

=head3 find() - Liefere Pfade innerhalb eines Verzeichnisses

=head4 Synopsis

    @arr|$arr = $obj->find(@opt);
    @arr|$arr = $class->find($path,@opt);

=head4 Options

=over 4

=item -follow => $bool (Default: 1)

Folge Symbolic Links.

=item -olderThan => $seconds (Default: 0)

Liefere nur Dateien, die vor mindestens $seconds zuletzt geändert
wurden. Diese Option ist z.B. nützlich, um veraltete temporäre Dateien
zu finden, um sie zu löschen.

=item -pattern => $regex (Default: keiner)

Schränke die Treffer auf jene Pfade ein, die Muster $regex erfüllen.

=item -slash => $bool (Default: 0)

Füge einen Slash (/) am Ende von Directory-Namen hinzu.

=item -sloppy => $bool (Default: 0)

Wirf keine Exception, wenn $path nicht existiert, sondern liefere
undef bzw. eine leere Liste.

=item -subPath => $bool (Default: 0)

Liefere nur den Subpfad, entferne also $path am Anfang.

=item -type => 'd' | 'f' | undef (Default: undef)

Liefere nur Verzeichnisse ('d') oder nur, was kein Verzeichnis ist ('f'),
oder liefere alles (undef).

=back

=head4 Description

Finde alle Dateien und Verzeichnisse unterhalb von und einschließlich
Verzeichnis $path und liefere die Liste der gefundenen Pfade
zurück. Im Skalarkontext liefere eine Referenz auf die Liste.

Ist $dir Null (Leerstring oder undef), wird das aktuelle Verzeichnis
('.') durchsucht.

Die Reihenfolge der Dateien ist undefiniert.

=cut

# -----------------------------------------------------------------------------

sub find {
    my $self = ref $_[0]? shift: shift->new(shift);
    # @_: @opt

    # Optionen

    my $follow = 1;
    my $olderThan = 0;
    my $pattern = undef;
    my $slash = 0;
    my $sloppy = 0;
    my $subPath = 0;
    my $type = undef;

    if (@_) {
        Blog::Base::Misc->argExtract(\@_,
            -follow=>\$follow,
            -olderThan=>\$olderThan,
            -pattern=>\$pattern,
            -slash=>\$slash,
            -sloppy=>\$sloppy,
            -subPath=>\$subPath,
            -type=>\$type,
        );
    }

    # Parameter-Tests

    if (!defined $$self || $$self eq '') {
        $$self = '.';
    }
    elsif (!-e $$self) {
        if ($sloppy) {
            return wantarray? (): undef;
        }
        $self->throw(q{PATH-00011: Pfad existiert nicht},
            Path=>$$self,
        );
    }
    elsif (!$self->isDir) {
        $self->throw(q{PATH-00013: Pfad ist kein Verzeichnis},
            Path=>$$self,
        );
    }

    # Liste der Pfade
    my $arr = Blog::Base::Array->new;

    # Zeitpunkt der Suche (für Zeitvergleich bei -olderThan)
    my $time = time;

    my $sub = sub {
        if ($pattern && $File::Find::name !~ /$pattern/) {
            return;
        }

        if ($type || $slash || $olderThan) {
            # Test muss auf $_ erfolgen, da abgestiegen wird!
            my $isDir = -d;

            if ($type) {
                if ($type eq 'd' && !$isDir || $type eq 'f' && $isDir) {
                    return;
                }
            }
            if ($olderThan) { 
                # Datei ist jünger als $olderThan Sekunden
                return if (stat $File::Find::name)[9] > $time-$olderThan;
            }
            if ($slash && $isDir) {
                $File::Find::name .= '/';
            }       
        }

        if ($subPath) {
            # Pfadanfang entfernen
            $File::Find::name =~ s|^\Q$$self/||;
        }

        $File::Find::name =~ s|^\./||; # ./ am Anfang entfernen

        # Pfad-Objekte machen Probleme, wenn die Pfade an open()
        # übergeben werden, da open() eine Stringreferenz als String öffnet.
        # push @$arr,ref($self)->new($File::Find::name);

        push @$arr,$File::Find::name;
    };

    my $opts = {
        wanted=>$sub,
        follow=>$follow,
    };

    File::Find::find($opts,$$self);

    return wantarray? @$arr: $arr;
}

# -----------------------------------------------------------------------------

=head3 maxFilename() - Liefere den lexikalisch größten Dateinamen

=head4 Synopsis

    $max = $obj->maxFilename(@opt);
    $max = $class->maxFilename($path,@opt);

=head4 Options

zur Zeit keine

=head4 Description

Liefere den lexikalisch größten Dateinamen. Die Methode ist nützlich, wenn
die Dateinamen mit einer Zahl NNNNNN beginnen und man die Datei mit der
größten Zahl ermitteln möchte um einer neu erzeugten Datei die
nächsthöhere Nummer zuzuweisen.

=cut

# -----------------------------------------------------------------------------

sub maxFilename {
    my $self = ref $_[0]? shift: shift->new(shift);
    # @_: @opt

    my $max;
    my $dh = Blog::Base::DirHandle->new($$self);
    while (my $file = $dh->next) {
        if ($file eq '.' || $file eq '..') {
            next;
        }
        if (!defined($max) || $file gt $max) {
            $max = $file;
        }
    }
    $dh->close;

    return $max;
}

# -----------------------------------------------------------------------------

=head3 mkdir() - Erzeuge Verzeichnis

=head4 Synopsis

    $obj->mkdir(@opt);
    $class->mkdir($path,@opt);

=head4 Options

=over 4

=item -forceMode => $mode (Default: keiner)

Setze Verzeichnisrechte auf $mode ohne Berücksichtigung
der umask des Prozesses.

=item -mode => $mode (Default: 0775)

Setze Verzeichnisrechte auf $mode mit Berücksichtigung
der umask des Prozesses.

=item -mustNotExist => $bool (Default: 0)

Das Verzeichnis darf nicht existieren. Wenn es existiert, wird
eine Exception geworfen.

=item -recursive => 0 | 1 (Default: 0)

Erzeuge übergeordnete Verzeichnisse, wenn nötig.

=back

=head4 Description

Erzeuge Verzeichnis. Existiert das Verzeichnis bereits, hat
der Aufruf keinen Effekt. Kann das Verzeichnis nicht angelegt
werden, wird eine Exception ausgelöst.

=cut

# -----------------------------------------------------------------------------

sub mkdir {
    my $self = ref $_[0]? shift: shift->new(shift);
    # @_: @opt

    return if !$$self;

    my $forceMode = undef;
    my $mode = 0755;
    my $mustNotExist = 0;
    my $recursive = 0;

    if (@_) {
        Blog::Base::Misc->argExtract(-dontExtract=>1,\@_,
            -forceMode=>\$forceMode,
            -mode=>\$mode,
            -mustNotExist=>\$mustNotExist,
            -recursive=>\$recursive,
        );
    }

    if (-d $$self) {
        if ($mustNotExist) {
            $self->throw(
                q{PATH-00005: Verzeichnis existiert bereits},
                Path=>$$self,
            );
        }    
        return;
    }

    if ($recursive) {
        $self->parent->mkdir(@_,-mustNotExist=>0);
    }

    if (-d $$self) {
        # Hack, damit rekursiv erzeugte Pfade wie /tmp/a/b/c/..
        # angelegt werden können. Ohne diesen zusätzlichen
        # Existenz-Test schlägt sonst das folgende mkdir fehl.
        return;
    }

    CORE::mkdir($$self,$mode) || do {
        $self->throw(
            q{PATH-00004: Kann Verzeichnis nicht erzeugen},
            Path=>$$self,
        );
    };

    if ($forceMode) {
        $self->chmod($forceMode);
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 File Operations

=head3 append() - Hänge Daten an Datei an

=head4 Synopsis

    $obj->append($data);
    $class->append($path,$data);

=head4 Description

Hänge Daten $data an Datei an. Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub append {
    my $this = shift;
    $this->write(@_,-append=>1);
    return;
}

# -----------------------------------------------------------------------------

=head3 compare() - Prüfe, ob Inhalt der Dateien differiert

=head4 Synopsis

    $bool = $file1->compare($file2);
    $bool = $class->compare($file1,$file2);

=head4 Description

Prüfe, ob der Inhalt der Dateien $file1 und $file2
(jeweils Blog::Base::Path-Objekt oder String) differiert. Ist dies der Fall,
liefere 1, andernfalls 0.

=cut

# -----------------------------------------------------------------------------

sub compare {
    my $self = ref $_[0]? shift: shift->new(shift);
    my $file2 = ref $_[0]? shift: ref($self)->new(shift);

    if (-s $self != -s $file2) {
        return 1;
    }

    return $self->read eq $file2->read? 0: 1;
}

# -----------------------------------------------------------------------------

=head3 compareData() - Prüfe, ob Datei-Inhalt von Daten differiert

=head4 Synopsis

    $bool = $file->compareData($data);
    $bool = $class->compareData($file,$data);

=head4 Alias

different()

=head4 Description

Prüfe, ob der Inhalt der Datei $file (Blog::Base::Path-Objekt oder String)
von $data differiert. Ist dies der Fall, liefere 1, andernfalls 0.
Die Datei muss nicht existieren.

=cut

# -----------------------------------------------------------------------------

sub compareData {
    my $self = ref $_[0]? shift: shift->new(shift);
    # @_: $data

    if (!-e $self || -s $self != length $_[0]) {
        return 1;
    }

    return $self->read eq $_[0]? 0: 1;
}

{
    no warnings 'once';
    *different = \&compareData;
}

# -----------------------------------------------------------------------------

=head3 newlineStr() - Ermittele Zeilentrenner

=head4 Synopsis

    $nl = $p->newlineStr;
    $nl = $class->newlineStr($file);

=head4 Description

Ermittele den physischen Zeilentrenner (CR, LF oder CRLF) der Datei
$p bzw. $file und liefere diesen zurück. Wird kein Zeilentrenner
gefunden, liefere undef.

=head4 Example

    local $/ = Blog::Base::Path->newlineStr($file);
    
    while (<$fh>) {
        chomp;
        # Zeile verarbeiten
    }

=cut

# -----------------------------------------------------------------------------

sub newlineStr {
    my $this = shift;
    # @_: empty -or- $file

    my $file = ref $this? $$this: shift;

    my $fh = Blog::Base::FileHandle->new('<',$file);
    $fh->binmode;

    my $nl;
    while (defined(my $c = getc $fh)) {
        if ($c eq "\cM") {
            $c = getc $fh;
            if (defined($c) && $c eq "\cJ") {
                $nl = "\cM\cJ";
                last;
            }
            $nl = "\cM";
            last;
        }
        elsif ($c eq "\cJ") {
            $nl = "\cJ";
            last;
        }
    }
    $fh->close;

    return $nl;
}

# -----------------------------------------------------------------------------

=head3 read() - Lies Datei

=head4 Synopsis

    $data = $obj->read(@opt);
    $data = $class->read($path,@opt);

=head4 Options

=over 4

=item -maxLines => $n (Default: 0)

Lies höchstens $n Zeilen. Die Zählung beginnt nach den
Skiplines (s. Option -skipLines). 0 bedeutet, lies alle Zeilen.

=item -skip => $regex (Default: keiner)

Überlies alle Zeilen, die das Muster $regex erfüllen. $regex
wird als Zeichenkette angegeben. Die Option kann beispielsweise dazu
verwendet werden, um Kommentarzeilen zu überlesen.

=item -skipLines => $n (Default: 0)

Überlies die ersten $n Zeilen.

=back

=head4 Description

Lies den Inhalt der Datei und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub read {
    my $this = shift;
    my $self = ref $this? $this: \shift; # Objekt- vs. Klassenmethode
    # @_: Optionen

    # Optionen

    my $maxLines = 0;
    my $skip = undef;
    my $skipLines = 0;

    if (@_) {
        Blog::Base::Misc->argExtract(\@_,
            -maxLines=>\$maxLines,
            -skip=>\$skip,
            -skipLines=>\$skipLines,
        );
    }

    # Datei lesen

    my $data = '';
    my $fh = Blog::Base::FileHandle->new('<',"$$self"); # Anführungsstriche!

    if ($maxLines || $skip || $skipLines) {
        my $i = 0;
        my $j = 0;
        while (<$fh>) {
            next if $skipLines && $i++ < $skipLines;
            last if $maxLines && ++$j > $maxLines;
            next if $skip && /$skip/; # Zeile überlesen
            $data .= $_;
        }
    }
    else {
        local $/ = undef;
        $data = <$fh>;
    }

    $fh->close;

    return $data;
}

# -----------------------------------------------------------------------------

=head3 readDecode() - Lies und decode Textdatei

=head4 Synopsis

    $text = $obj->readDecode(@opt);
    $text = $class->readDecode($path,@opt);

=head4 Options

Siehe Methode read().

=head4 Description

Lies den Inhalt der Textatei $path, analysiere das Encoding,
dekodiere den Text entsprechend und liefere ihn zurück.

=cut

# -----------------------------------------------------------------------------

sub readDecode {
    my $this = shift;

    my $text = $this->read(@_);

    # Wir dekodieren UTF-8 und ISO-8859-1
    my $dec = Encode::Guess::guess_encoding($text,'iso-8859-1');
    if (ref $dec) {
        # Character Encoding eindeutig bestimmt
        $text = $dec->decode($text);
    }
    elsif ($dec =~ /utf8/ && $dec =~ / or / && $dec =~ /iso-8859-1/) {
        # Datei ist UTF-8 oder ISO-8859-1 kodiert. Da es sehr
        # unwahrscheinlich ist, dass eine ISO-8859-1 Textdatei zufällig
        # korrektes UTF-8 enthält, gehen wir davon aus, dass die
        # Datei UTF-8 encoded ist.
        $text = Encode::decode('utf-8',$text);
    }
    else {
        # Es ist ein anderer Fehler aufgetreten
        $this->throw(
            q{PATH-00099: Zeichen-Dekodierung fehlgeschlagen},
            Message=>$dec,
        );
    }

    return $text;
}

# -----------------------------------------------------------------------------

=head3 write() - Schreibe Datei

=head4 Synopsis

    $obj->write; # leere Datei
    
    $obj->write($data,@opt);
    $obj->write(\$data,@opt);
    
    $class->write($path,$data,@opt);
    $class->write($path,\$data,@opt);

=head4 Options

=over 4

=item -append => $bool (Default: 0)

Öffne die Datei im Append-Modus, d.h. hänge die Zeichenkette an die
Datei an.

=item -recursive => $bool (Default: 0)

Erzeuge übergeordnete Verzeichnisse, wenn nötig.

=back

=cut

# -----------------------------------------------------------------------------

sub write {
    my $self = shift;
    $self = \shift if !ref $self; # Klassenmethode
    my $data = shift;

    # Optionen

    my $append = 0;
    my $recursive = 0;

    if (@_) {
        Blog::Base::Misc->argExtract(\@_,
            -append=>\$append,
            -recursive=>\$recursive,
        );
    }
        
    my $ref = ref $data? $data: \$data;

    my $dir = Blog::Base::Path->parent($$self);
    if ($dir && !-d $dir) {
        Blog::Base::Path->mkdir($dir,-recursive=>1);
    }

    my $flags = Fcntl::O_WRONLY|Fcntl::O_CREAT;
    $flags |= $append? Fcntl::O_APPEND: Fcntl::O_TRUNC;

    local *F;
    sysopen(F,$$self,$flags) || do {
        Blog::Base::Path->throw(
            q{PATH-00006: Datei kann nicht zum Schreiben geöffnet werden},
            Path=>$$self,
            Error=>"$!",
        );
    };

    # Wenn keine Daten zu schreiben sind, print auslassen,
    # da sonst eine Exception ausgelöst wird.

    if (defined($$ref) && $$ref ne '') {
        print F $$ref or do {
            my $errStr = "$!";
            close F;
            Blog::Base::Path->throw(
                q{PATH-00007: Schreiben auf Datei fehlgeschlagen},
                Path=>$$self,
                Error=>$errStr,
            );
        }
    }

    close F;

    return;
}

# -----------------------------------------------------------------------------

=head3 writeIfDifferent() - Schreibe Datei, wenn Inhalt differiert

=head4 Synopsis

    $obj->writeIfDifferent($data);
    $class->writeIfDifferent($path,$data);

=cut

# -----------------------------------------------------------------------------

sub writeIfDifferent {
    my $self = shift;
    $self = \shift if !ref $self; # Klassenmethode
    # @_: $data

    if ($self->compareData($_[0])) {
        $self->write($_[0]);
        return 1;
    }

    return 0;
}

# -----------------------------------------------------------------------------

=head2 Path Operations

=head3 basename() - Liefere Grundnamen

=head4 Synopsis

    $basename = $obj->basename;
    $basename = $class->basename($path);

=head4 Alias

baseName()

=head4 Description

Liefere den Grundnamen des Pfads, d.h. ohne Verzeichnis und Extension.

=cut

# -----------------------------------------------------------------------------

sub basename {
    return (shift->split(@_))[2];
}

{
    no warnings 'once';
    *baseName = \&basename;
}

# -----------------------------------------------------------------------------

=head3 chmod() - Setze Permissions

=head4 Synopsis

    $obj->chmod($mode);
    $class->chmod($path,$mode);

=head4 Description

Setze Permissions auf Pfad. Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub chmod {
    my $self = shift;
    $self = \shift if !ref $self; # Klassenmethode
    my $mode = shift;

    CORE::chmod $mode,$$self or do {
        Blog::Base::Path->throw(
            q{PATH-00003: Permissions setzen fehlgeschlagen},
            Path=>$$self,
            Mode=>$mode,
        );
    };

    return;
}

# -----------------------------------------------------------------------------

=head3 copy() - Kopiere Datei

=head4 Synopsis

    $obj->copy($destName);
    $class->copy($sourceName,$destName);

=head4 Description

Kopiere Datei nach $destName. Die Methode liefert keinen Wert
zurück.

=cut

# -----------------------------------------------------------------------------

sub copy {
    my $this = shift;
    my $self = ref $this? $this: \shift; # Klassen- oder Instanzmethode
    my $destName = shift;

    my $fh1 = Blog::Base::FileHandle->new('<',$$self);
    my $fh2 = Blog::Base::FileHandle->new('>',$destName);
    while (<$fh1>) {
        print $fh2 $_ or $this->throw(
            q{PATH-00007: Schreiben auf Datei fehlgeschlagen},
            Path=>$destName,
        );
    }
    $fh1->close;
    $fh2->close;

    return;
}

# -----------------------------------------------------------------------------

=head3 delete() - Lösche Pfad (rekursiv)

=head4 Synopsis

    $obj->delete;
    $class->delete($path);

=head4 Description

Lösche den Pfad aus dem Dateisystem, also entweder die Datei oder
das Verzeichnis einschließlich Inhalt. Es ist kein Fehler, wenn
der Pfad im Dateisystem nicht existiert. Existiert der Pfad und
kann nicht gelöscht werden, wird eine Exception ausgelöst.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub delete {
    my $self = shift;
    $self = \shift if !ref $self; # Klassenmethode

    if (!-e $$self && !-l $$self) {
        # bei Nichtexistenz nichts tun, aber nur, wenn es
        # kein Symlink ist. Bei Symlinks schlägt -e fehl, wenn
        # das Ziel nicht existiert!
    }
    elsif (-d $$self) {
        # Verzeichnis löschen
        (my $dir = $$self) =~ s/'/\\'/g; # ' quoten
        eval { Blog::Base::Shell->exec("/bin/rm -r '$dir' >/dev/null 2>&1") };
        if ($@) {
            Blog::Base::Path->throw(
                q{PATH-00001: Verzeichnis löschen fehlgeschlagen},
                Error=>$@,
                Path=>$$self,
            );
        }
    }
    else {
        # Datei löschen
        if (!CORE::unlink $$self) {
            Blog::Base::Path->throw(
                q{PATH-00002: Datei löschen fehlgeschlagen},
                Path=>$$self
            );
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 glob() - Liefere Pfade, die Shell-Pattern erfüllen

=head4 Synopsis

    $p = $class->glob($pat);
    @p = $class->glob($pat);

=head4 Description

Liefere die Pfad-Objekte, die Shell-Pattern $pat erfüllen.
Im Skalarkontext liefere den ersten Pfad, der dann
der einzig erfüllbare Pfad sein muss, sonst wird eine Exception
geworfen.

=cut

# -----------------------------------------------------------------------------

sub glob {
    my ($class,$pat) = @_;

    my @arr = CORE::glob $pat;
    for (@arr) {
        $_ = $class->new($_);
    }

    if (wantarray) {
        return @arr;
    }

    if (!@arr) {
        $class->throw(
            q{PATH-00014: Kein Pfad erfüllt Muster},
            Pattern=>$pat,
        );
    }
    elsif (@arr > 1) {
        $class->throw(
            q{PATH-00015: Mehr als ein Pfad erfüllt Muster},
            Pattern=>$pat,
        );
    }

    return $arr[0];
}

# -----------------------------------------------------------------------------

=head3 mode() - Liefere Permissions

=head4 Synopsis

    $mode = $obj->mode;
    $mode = $class->mode($path);

=head4 Description

Liefere Permissions des Pfads.

=cut

# -----------------------------------------------------------------------------

sub mode {
    my $self = shift;
    $self = \shift if !ref $self; # Klassenmethode

    my @stat = CORE::stat $$self;
    unless (@stat) {
        __PACKAGE__->throw(
            q{PATH-00001: stat ist fehlgeschlagen},
            Path=>$$self,
        );
    }

    return $stat[2] & 07777;
}

# -----------------------------------------------------------------------------

=head3 mtime() - Setze/Liefere Modifikationszeit

=head4 Synopsis

    $mtime = $obj->mtime;
    $mtime = $obj->mtime($mtime);
    $mtime = $class->mtime($path);
    $mtime = $class->mtime($path,$mtime);

=head4 Description

Liefere die Zeit der letzten Modifikation des Pfads $path. Wenn der
Pfad nicht existiert, liefere 0.

Ist ein zweiter Parameter $mtime angegeben, setze die Zeit auf den
angegebenen Wert. In dem Fall muss der Pfad existieren.

=cut

# -----------------------------------------------------------------------------

sub mtime {
    my $self = shift;
    $self = \shift if !ref $self; # Klassenmethode
    # @_: $mtime

    if (@_) {
        my $mtime = shift;

        if (!-e $$self) {
            $self->throw(
                q{PATH-00011: Pfad existiert nicht},
                Path=>$$self,
            );
        }
        my $atime = (stat($$self))[8]; # atime lesen, die nicht ändern
        if (!utime $atime,$mtime,$$self) {
            $self->throw(
                q{PATH-00012: Kann mtime nicht setzen},
                Path=>$$self,
                Error=>"$!",
            );
        }
    }

    return (stat($$self))[9] || 0;
}

# -----------------------------------------------------------------------------

=head3 newer() - Vergleiche Modifikationsdatum zweier Pfade

=head4 Synopsis

    $bool = $path1->newer($path2);
    $bool = $class->newer($path1,$path2);

=head4 Description

Prüfe, ob Pfad $path1 ein jüngeres Modifikationsdatum besitzt als
$path2. Ist dies der Fall, liefere 1, andernfalls 0. Liefere
ebenfalls 1, wenn Datei $path2 nicht existiert. Pfad
$path1 muss existieren.

Pfad $path2 kann eine Zeichenkette oder ein Pfad-Objekt sein.

Dieser Test ist nützlich, wenn $path2 aus $path1 erzeugt wird
und geprüft werden soll, ob eine Neuerzeugung notwendig ist.

=cut

# -----------------------------------------------------------------------------

sub newer {
    my $self = shift;
    $self = \shift if !ref $self; # Klassenmethode
    my $path = ref $_[0]? shift: \shift;

    # if (!$self->exists) {
    if (!-e $$self) {
        $self->throw(
            q{PATH-00011: Pfad existiert nicht},
            Path=>$$self,
        );
    }

    my $t1 = (stat $$self)[9];
    my $t2 = (stat $$path)[9] || 0;

    return $t1 > $t2? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 child() - Liefere Child-Pfadobjekt

=head4 Synopsis

    $pChild = $p->child($subPath);

=cut

# -----------------------------------------------------------------------------

sub child {
    my ($self,$subPath) = @_;

    my $path = $$self;
    if (length $path) {
        $path .= '/';
    }
    $path .= $subPath;

    return ref($self)->new($path);
}

# -----------------------------------------------------------------------------

=head3 parent() - Liefere Parent-Pfad

=head4 Synopsis

    $objParent = $obj->parent;
    $pathParent = $class->parent($path);

=head4 Description

Liefere Parent-Objekt zu Path-Objekt. Existiert kein Parent
(im Falle von '/', '.' oder ''), liefere undef.

Wird die Methode als Klassenmethode gerufen, wird der Parent-Pfad
als Zeichenkette statt als Objekt geliefert.

=cut

# -----------------------------------------------------------------------------

sub parent {
    my $this = shift;
    my $self = ref($this)? $this: \shift; # Instanz- oder Klassenmethode

    my $path;
    if ($$self eq '/' || $$self eq '.' || $$self eq '') {
        return undef;
    }
    elsif ($$self !~ m|/|) {
        $path = '.';
    }
    elsif ($$self =~ m|^/[^/]+$|) {
        $path = '/';
    }
    else {
        ($path = $$self) =~ s|/+[^/]+/*$||;
    }

    return ref $this? ref($self)->new($path): $path;
}

# -----------------------------------------------------------------------------

=head3 rename() - Benenne Pfad um

=head4 Synopsis

    $obj->rename($newName);
    $class->rename($oldName,$newName);

=head4 Description

Benenne Pfad in $newName um, intern und im Dateisystem.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub rename {
    my $this = shift;
    my $self = ref $this? $this: \shift; # Klassen- oder Instanzmethode
    my $newName = shift;

    CORE::rename $$self,$newName or do {
        $this->throw(
            q{PATH-00010: Kann Pfad nicht umbenennen},
            Error=>"$!",
            OldPath=>$$self,
            NewPath=>$newName,
        );
    };

    # Neuen Namen intern setzen

    if (ref $this) {
        $$self = $newName;
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 searchProgram() - Suche Programm oder Skript via PATH

=head4 Synopsis

    $path = $class->searchProgram($program);

=cut

# -----------------------------------------------------------------------------

sub searchProgram {
    my ($class,$program) = @_;

    if (substr($program,0,1) eq '/') {
        # Wenn absoluter Pfad, diesen liefern
        return $program;
    }

    # PATH absuchen

    for my $path (split /:/,$ENV{'PATH'}) {
        if (-e "$path/$program") {
            return "$path/$program";
        }
    }

    # Nicht gefunden

    $class->throw(
        q{PATH-00020: Programm/Skript nicht gefunden},
        Program=>$program,
        Paths=>$ENV{'PATH'},
    );
}

# -----------------------------------------------------------------------------

=head3 split() - Zerlege Pfad in seine Komponenten

=head4 Synopsis

    ($dir,$file,$base,$ext) = $obj->split;
    ($dir,$file,$base,$ext) = $class->split($path);

=head4 Description

Zerlege Pfad in die vier Komponenten Verzeichnisname, Dateiname,
Basisname (= Dateiname ohne Extension) und Extension und liefere diese
zurück.

Für eine Komponente, die nicht existiert, wird ein Leerstring
geliefert.

=cut

# -----------------------------------------------------------------------------

sub split {
    my $this = shift;
    my $self = ref $this? $this: \shift; # Klassen- oder Instanzmethode

    my $path = $$self;
    my ($dir,$file,$base,$ext) = ('') x 4;

    $dir = $1 if $path =~ s|(.*)/||;
    $file = $path;

    $ext = $1 if $path =~ s/\.(.*?)$//;
    $base = $path;

    return ($dir,$file,$base,$ext);
}

# -----------------------------------------------------------------------------

=head3 symlink() - Erzeuge Symlink

=head4 Synopsis

    $obj->symlink($symlink);
    $class->symlink($path,$symlink);

=head4 Description

Erzeuge Symlink $symlink für Pfad $obj bzw. $path.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub symlink {
    my $this = shift;
    my $self = ref $this? $this: \shift; # Klassen- oder Instanzmethode
    my $symlink = shift;

    Blog::Base::FileSystem->symlink($$self,$symlink);
    return;
}

# -----------------------------------------------------------------------------

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright © 2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
