package Blog::Base::Program1;
use base qw/Blog::Base::Misc Blog::Base::Hash1 Blog::Base::Shell/;

use strict;
use warnings;

use Blog::Base::Misc;
use Blog::Base::String;
use Blog::Base::IPC;
use Blog::Base::Shell;
use Cwd ();
use Blog::Base::Path;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Program1 - Basisklasse für Programme

=head1 BASE CLASSES

=over 2

=item *

L<Blog::Base::Misc|../Blog::Base/Misc.html>

=item *

L<Blog::Base::Hash1|../Blog::Base/Hash1.html>

=item *

L<Blog::Base::Shell|../Blog::Base/Shell.html>

=back

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert das aktuell laufende Programm,
also den gerade ausgeführten Perl-Prozess.

Jedes in der Klassenbibliothek implementierte Programm wird von
dieser Klasse abgeleitet.

=head1 METHODS

=head2 Methoden

=head3 run() - Führe Programmcode aus

=head4 Synopsis

    $ret = $prog->run(@args);

=head4 Description

Führe Programmcode aus und liefere Exitcode zurück.
Die Methode wird von abgeleiteten überschreiben.

=head4 Example

    #!/usr/bin/perl
    
    use strict;
    use warnings;
    
    use MyProg;
    
    my $prog = MyProg->new;
    my $ret = $prog->run(@ARGV);
    exit $ret;

=cut

# -----------------------------------------------------------------------------

sub run {
    my $self = ref $_[0]? shift: shift->new;

    # Optionen

    $self->processOptions(
        -helpOptions=>['--help','-h'],
        -minArgs=>0,
        -maxArgs=>0,
        \@_,
    );

    return 0;
}

# -----------------------------------------------------------------------------

=head3 processOptions() - Verarbeite Programmoptionen

=head4 Synopsis

    $prog->processOptions(@methOpts,\@ARGV,@progOpts);

=head4 Options

=over 4

=item -helpOptions => \@str (Default: ['--help','-h'])

Optionen für Hilfe-Ausgabe.

=item -minArgs => $n (Default: 0)

Mindestanzahl an Argumenten.

=item -maxArgs => $n (Default: 0)

Höchstanzahl an Argumenten.

=back

=head4 Description

Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub processOptions {
    my $self = shift;
    # @_: @methOpts,$argsA,@progOpts

    # Methodenoptionen

    my $helpOptions = ['--help','-h'];
    my $minArgs = 0;
    my $maxArgs = 0;

    Blog::Base::Misc->argExtract(
        -mode=>'stop',
        -keepUndef=>1, # damit maxArgs auf unendlich gesetzt werden kann
        \@_,
        -helpOptions=>\$helpOptions,
        -minArgs=>\$minArgs,
        -maxArgs=>\$maxArgs,
    );

    # Referenz auf Argumentliste des Programms
    my $argsA = shift;

    my $optHelp = 0;

    eval {
        Blog::Base::Misc->argExtract(-progOpts=>1,-mode=>'strict-dash',$argsA,
            @_, #  @progOpts
            map {$_=>\$optHelp} @$helpOptions,
        );
    };

    my $msg;
    if ($optHelp) {
        print $self->help;
        exit 0;
    } # FIXME!!!
    elsif ($@) {
        $msg = q{OPT-00001: Fehler};
        $msg .= ' - '.$@;
    }
    elsif (defined($minArgs) && @$argsA < $minArgs) {
        $msg = q{OPT-00002: Zu wenige Argumente};
    }
    elsif (defined($maxArgs) && @$argsA > $maxArgs) {
        $msg = q{OPT-00003: Zu viele Argumente};
    }
    if ($msg) {
        # Blog::Base::Misc->dieUsage($self->usage,-error=>"FEHLER: $msg");
        Blog::Base::Misc->dieUsage($self->help,-error=>"FEHLER: $msg");
    }
    return;
}

# -----------------------------------------------------------------------------

=head3 usage() - Liefere Usage-Text

=head4 Synopsis

    $text = $prog->usage;
    $text = $prog->usage($msg);

=head4 Description

Liefere als Usage-Text den Inhalt des SYNOPSIS-Abschnitts aus
der POD-Doku des Programms und setze diesem den String "Usage: " voran.

Enthält die POD-Doku keinen Abschnitt SYNOPSIS, liefere den Text:

    SYNOPSIS-Abschnitt in POD zum Programm nicht vorhanden.

Ist der Parameter $msg angegeben, wird dem Usage-Text der String:

    FEHLER: $msg\n\n

vorangestellt.

=cut

# -----------------------------------------------------------------------------

sub usage {
    my ($self,$msg) = @_;

    # my $binDir = $self->perlDir;
    my $str = qx|perldoc -u $0 2>&1|;

    # SYNOPSIS extrahieren

    ($str) = $str =~ /^=head1 USAGE\n+(.*?)^=head1/sm;
    if ($str) {
        $str = 'Usage: '.Blog::Base::String->removeIndent($str,-addNL=>1);
    }
    else {
        $str = 'SYNOPSIS-Abschnitt in POD zum Programm nicht vorhanden.';
    }

    if ($msg) {
        $str = "FEHLER: $msg\n\n$str";
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head3 help() - Liefere Hilfe-Text

=head4 Synopsis

    $text = $prog->help;

=head4 Description

Liefere als Hilfetext die formatierte POD-Doku zum Programm.

=cut

# -----------------------------------------------------------------------------

sub help {
    my $self = shift;

    # my $binDir = $self->perlDir;
    # my $str = Blog::Base::Shell->exec("perldoc $0");
    my ($str) = eval{Blog::Base::IPC->filter("pod2text $0")};

    # Fehler "unable to format" tritt auf, wenn der Quelltext kein POD enthält

    if ($@ && $@ !~ /unable to format/) {
        die $@;
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head3 cwd() - Pfad-Objekt des Current Working Directory

=head4 Synopsis

    $pathObj = $this->cwd;
    $pathObj = $this->cwd($subPath);

=head4 Example

    $path = Blog::Base::Program1->cwd;
    # => "/home/fs"
    
    $path = Blog::Base::Program1->cwd('.signature');
    # => "/home/fs/.signature"

=cut

# -----------------------------------------------------------------------------

sub cwd {
    my $this = shift;
    # @_: $subPath

    my $cwd = Cwd::getcwd;
    if (@_) {
        $cwd .= "/$_[0]";
    }

    return Blog::Base::Path->new($cwd);
}

# -----------------------------------------------------------------------------

=head3 perlDir() - Pfad-Objekt des Perl-Interpreter-Verzeichnisses

=head4 Synopsis

    $pathObj = $this->perlDir;

=head4 Example

    $path = Blog::Base::Program1->perlDir;
    # $$path ==> '/usr/local/bin'

=cut

# -----------------------------------------------------------------------------

sub perlDir {
    my $this = shift;

    my $path = $^X;
    $path =~ s|[^/]+$||;
    if ($path ne '/') {
        chop $path;
    }

    return Blog::Base::Path->new($path);
}

# -----------------------------------------------------------------------------

=head3 progName() - Name des Programms

=head4 Synopsis

    $name = $this->progName;

=cut

# -----------------------------------------------------------------------------

sub progName {
    my $this = shift;
    (my $name = $0) =~ s|.*/||;
    return $name;
}

# -----------------------------------------------------------------------------

=head3 progDir() - Pfad-Objekt des Programm-Verzeichnisses

=head4 Synopsis

    $path = $this->progDir;

=head4 Description

Liefere Pfad-Objekt des Verzeichnisses, in dem sich das Programm
(= Perl-Skript) befindet.

=cut

# -----------------------------------------------------------------------------

sub progDir {
    my $this = shift;

    (my $path = $0) =~ s|[^/]+$||;
    if ($path ne '/') {
        chop $path;
    }

    return Blog::Base::Path->new($path);
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
