package Blog::Base::Sdoc::Code;
use base qw/Blog::Base::Sdoc::Node/;

use strict;
use warnings;
use utf8;

use Blog::Base::String;
use Blog::Base::IPC;
use Blog::Base::Html::Listing;
use Blog::Base::Path;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Sdoc::Code - Code-Block

=head1 BASE CLASS

L<Blog::Base::Sdoc::Node|../../Blog::Base/Sdoc/Node.html>

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf übergeordneten Knoten.

=item text => $text

Text des Code-Abschnitts. Im Gegensatz zu einem Paragraphen
enthält der Text eines Code-Knoten auch Leerzeilen.

=back

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Code-Abschniit
im Sdoc-Parsingbaum.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $node = $class->new($doc,$parent);

=head4 Description

Lies Code-Abschnitt aus Textdokument $doc und liefere
eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$doc,$parent,$att) = @_;

    # Ein Code-Abschnitt beginnt mit
    # a) | am Zeilenanfang gefolgt von Whitespace oder
    # b) nur mit Whitespace oder
    # c) mit "<<Code" am Zeilenende
    #
    # Der Abschnitt reicht im Falle von a) und b) so weit, bis der
    # betreffende Anfang nicht mehr vorhanden ist und im Falle
    # c) bis zu "<<Code"

    my $text = '';
    my $filter;
    if (@$att) {
        # Aufruf über %Code:

        if (my $i = $att->extractPair('listing')) {
            push @$att,ln=>$i,bg=>2;
        }

        my $stop = $att->extractPair('stop');
        if (!defined $stop) {
            if ($att->index('exec') >= 0 || $att->index('file') >= 0) {
                $stop = '';  # Default für exec und file
            }
            else {
                $stop = '.'; # normaler Default
            }
        }
        my $indentation = ' ' x $att->extractPair('indentation');

        my $reStop = $stop eq ''? qr/^$/: qr/^\Q$indentation$stop\E$/;
        my $reIndentation = qr/^$|^\Q$indentation/;

        while (@{$doc->lines}) {
            my $str = $doc->shiftLine->text;

            # Der Code-Abschnitt endet mit der ersten Zeile, die
            # den Stop-Pattern matcht

            if ($str =~ /$reStop/) {
                last;
            }

            $str =~ s/$reIndentation//; # Whitespace am Anfang entfernen
            $text .= "$str\n";
        }
    }
    else {
        my $line = $doc->lines->[0]->text;
        if ($line =~ /^\s*<<Code/) {
            $line =~ /^(\s*)/;
            my $reWS = qr/^$|^\Q$1/;

            if ($line =~ s/\s*\|(.*)//) {
                $filter = $1;
                $filter =~ s/^\s+//;
                $filter =~ s/\s+$//;
            }

            $line =~ s/<</>>/;
            my $reStop = qr/^\Q$line/;

            $doc->shiftLine;
            while (@{$doc->lines}) {
                my $str = $doc->shiftLine->text;

                # Der Code-Abschnitt endet mit der ersten Zeile,
                # die bei gleicher Einrückung auf <<Code endet.

                if ($str =~ /$reStop/) {
                    last;
                }

                $str =~ s/$reWS//; # Whitespace am Anfang entfernen
                $text .= "$str\n";
            }
        }
        else {
            $line =~ /^(\|?\s+)/;
            my $re = substr($1,0,1) eq '|'? qr/^\|$|^\Q$1/: qr/^$|^\Q$1/;

            while (@{$doc->lines}) {
                my $line = $doc->lines->[0];
                my $str = $line->text;

                # Ein Code-Abschnitt endet mit der ersten Zeile,
                # die nicht mit dem Anfang der Anfangszeile beginnt
                # Ausnahme: Leerzeile bei Einrückung.

                $str =~ s/$re// || last; # Zeilenanfang entfernen
                $text .= "$str\n";
                $doc->shiftLine;
            }
        }
    }
    $text =~ s/\s+$//;

    # Objekt instantiieren (Child-Objekte gibt es nicht)

    my $self = $class->SUPER::new(
        type=>'Code',
        text=>$text,
        file=>undef,
        exec=>undef,
        filter=>undef,
        ln=>0,
        cn=>0,
        bg=>0,
        esc=>1,
        cotedo=>0,
        extract=>undef,
        language=>undef,
        class=>'sdoc-code',
    );
    $self->parent($parent);
    $self->lockKeys;
    $self->set(@$att);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 dump() - Erzeuge externe Repräsentation für Code-Abschnitt

=head4 Synopsis

    $str = $node->dump($format);

=head4 Description

Erzeuge eine externe Repräsentation des Code-Abschnitts
und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    my $root = $self->rootNode;
    my $cssPrefix = $self->rootNode->get('cssPrefix');

    my $text = $self->{'text'};
    my $esc = $self->{'esc'};
    my $extract = $self->{'extract'};

    if (my $file = $self->{'file'}) {
        $text = Blog::Base::Path->read($file);
    }
    elsif (my $execCmd = $self->{'exec'}) {
        if ($execCmd =~ s/%FORMAT%/$format/g) {
            $esc = 0;
        }
        ($text) = Blog::Base::IPC->filter($execCmd,undef);
    }

    # Extraktion vor dem Filtern!

    if ($extract) {
        if ($text =~ /$extract/sm) {
            $text = $1;
        }
    }
    Blog::Base::String->removeIndent(\$text);

    if (my $filterCmd = $self->{'filter'}) {
        if ($filterCmd =~ s/%FORMAT%/$format/g) {
            $esc = 0;
        }
        ($text) = Blog::Base::IPC->filter($filterCmd,$text);
    }

    if ($self->{'bg'} == 2) { # Krücke
        $esc = 0;
    }

    if ($esc && $format ne 'pod') {
        $text = $self->expand($format,$text,0,@_);
    }

    my $h;
    if ($format =~ /^e?html$/) {
        $h = shift;
    }

    if ($h && $self->{'bg'} == 2) {
        return Blog::Base::Html::Listing->html($h,
            colNumbers=>$self->{'cn'},
            cssPrefix=>"$cssPrefix-code",
            escape=>$self->{'cotedo'}, # oder doch 0? 1 wird für CoTeDo-SOURCE benötigt
            lineNumbers=>$self->{'ln'},
            minLineNumberWidth=>$root->{'minLnWidth'},
            language=>$self->{'language'},
            source=>\$text,
        );
    }

    if (my $i = $self->{'ln'}) {
        my $n = $text =~ tr/\n//;
        my $l = length $n;
        if (my $minLnWidth = $root->{'minLnWidth'}) {
            $l = $minLnWidth if $l < $minLnWidth;
        }
        $l = 1 if $l < 2;
        if ($h) {
            $text =~ s/^/
                $h->tag('span',
                    class=>"$cssPrefix-code-ln",
                    sprintf('%*d',$l,$i++)
                ).' '/gme,
        }
        else {
            $text =~ s/^/sprintf '%*d: ',$l,$i++/gme;
        }
    }

    if ($format eq 'debug') {
        return "CODE\n$text\n";
    }
    elsif ($h) {
        return $h->tag('div',
            class=>"$cssPrefix-code-div",
            $h->tag('pre',
                class=>"$cssPrefix-code-pre",
                $text,
            )
        );
    }
    elsif ($format eq 'pod')
    {
        $text =~ s/^/    /mg;
        return "$text\n\n";
    }
    elsif ($format eq 'man')
    {
        my $parent = $self->parent;
        if ($parent && $parent->{'type'} eq 'Section' &&
                $parent->{'childs'}->[0] == $self) {
            # Sonderbehandlung für SYNOPSIS o.ä.
            # Keine Einrückung wenn der Code-Knoten der erste
            # (und vermutlich einzige) Knoten des Abschnitts ist
        }
        else {
            $text =~ s/^/    /mg;
        }
        return "$text\n\n";
    }

    $self->throw(
        q{SDOC-00001: Unbekanntes Format},
        Format=>$format,
    );
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
