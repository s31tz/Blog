package Blog::Base::Option;
use base qw/Blog::Base::Object/;

use strict;
use warnings;
use utf8;

use Blog::Base::Hash;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Option - Verarbeitung von Programm- und Methoden-Argumenten

=head1 BASE CLASS

L<Blog::Base::Object|../Blog::Base/Object.html>

=head1 METHODS

=head2 extract() - Extrahiere Optionen aus Argumentliste

=head3 Synopsis

    $opt = $class->extract(@opt,\@args,@keyVal); # Options-Objekt
    $class->extract(@opt,\@args,@keyVal);        # Options-Variable

=head3 Options

=over 4

=item -hashObject => $bool (Default: 0)

Liefere das Options-Objekt als Blog::Base::HashObject, d.h. die Optionswerte
können per Methodenaufruf abgefragt werden.
FIXME: Intern wird das Optionsobjekt dafür kopiert. Dies wäre nicht
nötig, wenn die Keys des internen Optionsobjekts von vornherein ohne
Bindestriche gesetzt würden. Dies bei Gelegenheit so realisieren.

=item -mode => 'strict'|'sloppy' (Default: 'strict')

Im Falle von C<<-mode=>'strict'>> (dem Default), wird eine Exception
ausgelöst, wenn eine unbekannte Option vorkommt. Im Falle von
C<<-mode=>'sloppy'>> wird das Argument stillschweigend übergangen.

=item -properties => $bool (Default: 0)

Die Optionen beginnen nicht mit einem Bindestrich (-).

=back

=head3 Description

Extrahiere die Optionen @keyVal aus der Argumentliste @args und
weise sie im Void-Kontext Variablen zu oder im Skalar-Kontext
einem Optionsobjekt.

=head4 Schreibweisen für eine Option

Eine Option kann auf verschiedene Weisen angegeben werden.

Als Programm-Optionen:

    --log-level=5    (ein Argument)
    --logLevel=5     (mixed case)

Als Methoden-Optionen:

    -log-level 5     (zwei Argumente)
    -logLevel 5      (mixed case)

Die Schreibweise mit zwei Bindestrichen wird typischerweise bei
Programmaufrufen angegeben. Die Option besteht aus I<einem> Argument,
bei dem der Wert durch ein Gleichheitszeichen vom Optionsnamen
getrennt angegeben ist.

Die Schreibweise mit einem Bindestrich wird typischerweise bei
Methodenaufrufen angegeben. In Perl ist bei einem Bindestrich
kein Quoting nötig. Die Option besteht aus I<zwei> Argumenten.

Beide Schreibweisen sind gleichberechtigt, so dass derselbe Code
sowohl Programm- als auch Methodenoptionen verarbeiten kann.

=head3 Example

Options-Objekt:

    sub meth {
        my $self = shift;
        # @_: @args
    
        my $opt = Blog::Base::Option->extract(\@_,
            -logLevel=>1,
            -verbose=>0,
        );
        if (@_ != 1) {
            $self->help(5,'Falsche Anzahl an Argumenten');
        )
        my $file = shift @_;
        ...
    
        if ($opt->get(-verbose)) {
            ...
        }
    }

Mit der Setzung -hashObjekt=>1 ist eine Abfrage des Optionsobjekts
per Methode möglich:

    $verbose = $opt->verbose;

Options-Variablen:

    sub meth {
        my $self = shift;
        my $file = shift;
        # @_: @args
    
        my $logLevel = 1;
        my $verbose = 0;
    
        if (@_) {
            Blog::Base::Option->extract(\@_,
                -logLevel=>\$logLevel,
                -verbose=>\$verbose,
            );
        }
    
        ...
    }

Optionen bei Programmaufruf:

    $ ./prog --log-level=2 --verbose file.txt

Optionen bei Methodenaufruf:

    $prog->begin(-logLevel=>2,-verbose=>1,'file.txt');

Abfrage einer Option:

    $logLevel = $opt->get('logLevel');

=cut

# -----------------------------------------------------------------------------

sub extract {
    my $class = shift;
    # @_: @opt,$argA,@optVal

    my $hashObject = 0;
    my $mode = 'strict';
    my $properties = 0;

    # Methoden-Optionen verarbeiten

    while (!ref $_[0]) {
        my $key = shift;

        if ($key eq '-mode') {
            $mode = shift;
        }
        elsif ($key eq '-properties') {
            $properties = shift;
        }
        elsif ($key eq '-hashObject') {
            $hashObject = shift;
        }
        else {
            $class->throw(
                q{OPT-00001: Ungültige Methodenoption},
                Option=>$key,
            );
        }
    }
    my $argA = shift;

    # Wir sind im VarMode, wenn die Methode im Void-Kontext gerufen wird.
    # Im VarMode enthält der Options-Hash Referenzen auf
    # Programm-Variablen, auf die wir die Optionswerte schreiben,
    # nicht die Options-Defaultwerte.

    my $varMode = defined wantarray? 0: 1;

    # Options-Hash initialisieren

    my $opt = Blog::Base::Hash->new;
    %$opt = @_;

    # Argumente auswerten und auf Options-Hash schreiben

    my $i = 0;
    while ($i < @$argA) {
        my ($optKey,$key,$val,$skip);

        if ($properties) {
            $key = $optKey = $argA->[$i];
            $val = $argA->[$i+1];
            $skip = 2;
        }
        elsif (substr($argA->[$i],0,1) eq '-') {
            if (substr($argA->[$i],0,2) eq '--') {
                # Programm-Option: --KEY=VAL

                if ($argA->[$i] eq '--') {
                    # Ende der Optionsliste
                    last;
                }
                ($optKey,$val) = split /=/,$argA->[$i],2;
                $key = substr $optKey,1; # ersten - entfernen
                if (!defined $val) {
                    $val = 1;
                }
                $skip = 1;
            }
            else {
                # Methoden-Option: -KEY,VAL

                if ($argA->[$i] eq '-h' && exists $opt->{-help}) {
                    $optKey = '-h';
                    $key = '-help';
                    $val = 1;
                    $skip = 1;
                }
                else {
                    $key = $optKey = $argA->[$i];
                    $val = $argA->[$i+1];
                    $skip = 2;
                }
            }
        }
        else {
            # Keine Option, weitergehen
            $i++;
            next;
        }

        if (!$properties) {
            # eingebettete Bindestriche in CamelCase-Schreibweise wandeln
            $key =~ s/(.)-(.)/$1\U$2/g;
        }

        # warn "OPTKEY=$optKey KEY=$key VAL=$val\n";

        # Existenz des Key prüfen

        if (!exists $opt->{$key}) {
            if ($mode eq 'sloppy') {
                $i += $skip;
                next;
            }
            $class->throw(
                q{OPT-00002: Ungültige Option},
                Option=>$optKey,
            );
        };

        # Optionswert setzen

        if (defined $val) { # Defaultwert bleibt. NEU! 27.7.2014
            if ($varMode) {
                ${$opt->{$key}} = $val;
            }
            else {
                $opt->{$key} = $val;
            }
        }

        # Option und Wert aus Argumentliste entfernen
        splice @$argA,$i,$skip;
    }

    if ($varMode) {
        return;
    }
    else {
        if ($hashObject) {
            my %opt;
            while (my ($key,$val) = each %$opt) {
                $key =~ s/^-+//;
                $opt{$key} = $val;
            }
            $opt = bless \%opt,'Blog::Base::HashObject';
        }
        $opt->lockKeys;
        return $opt;
    }
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
