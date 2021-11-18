# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::R1::Help - Programm-Dokumentation

=head1 BASE CLASS

L<Blog::Base::Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Blog::Base::R1::Help;
use base qw/Blog::Base::Quiq::Object/;

use v5.10;
use strict;
use warnings;

use Encode ();
use Blog::Base::Quiq::Option;
use Blog::Base::Quiq::Converter;
use Blog::Base::Quiq::FileHandle;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 text() - Liefere Programm-Dokumentation

=head4 Synopsis

  $text = $this->text(@opt);
  $text = $this->text($msg,@opt);

=head4 Options

=over 4

=item -noUmlaut => $bool

Wandele ä, ä, ü, ß, Ä, Ö, Ü in ae, oe, ue, ss, Ae, Oe, Ue.

=back

=head4 Description

Liefere die Programm-Dokumentation formatiert für die Ausgabe auf
ein Terminal.

Ist der optionale Parameter $msg angegeben, wird diese
Zeichenkette mit Leerzeilen getrennt der Programmdokumentation
voran- und nachgestellt.

  MSG
  
  DOKU DOKU DOKU DOKU DOKU DOKU
  DOKU DOKU DOKU DOKU DOKU DOKU
  DOKU DOKU DOKU DOKU DOKU DOKU
  DOKU DOKU DOKU DOKU DOKU DOKU
  ...
  
  MSG

Diese Funktionalität kann genutzt werden, der Dokumentation
eine Fehlermeldung hinzuzufügen.

=head4 Example

  $text = Blog::Base::R1::Help->text("FEHLER: Zu viele Parameter (@ARGV)");

=cut

# -----------------------------------------------------------------------------

sub text {
    my $this = shift;

    # Optionen und Argumente

    my $noUmlaut = 0;

    Blog::Base::Quiq::Option->extract(-mode=>'sloppy',\@ARGV,
        -noUmlaut=>\$noUmlaut,
    );
    my $msg = shift;

    # Verarbeitung

    # my $text = qx/pod2text $0/;
    my $text = Encode::decode('utf8',qx/pod2text $0/);
    if ($noUmlaut) {
        $text = Blog::Base::Quiq::Converter->umlautToAscii($text);
    }

    if ($msg) {
        $msg =~ s/\n+$//;
        $text = "$msg\n\n$text$msg\n";
    }

    return $text;
}

# -----------------------------------------------------------------------------

=head3 exit() - Gib Programm-Dokumentation aus und beende Programm

=head4 Synopsis

  $class->exit(@opt);
  $class->exit($exitCode,@opt);
  $class->exit($exitCode,$msg,@opt);

=head4 Returns

Die Methode kehrt nicht zurück

=head4 Description

Gib die Programm-Dokumentation aus und beende das Programm.

Die Dokumentation wird für die Ausgabe auf ein Terminal formatiert
und in dessen Encoding gewandelt.

Ist kein $exitCode angegeben oder 0, wird die Programmdokumentation
auf STDOUT ausgegeben und das Programm mit Exitcode 0 beendet.

Ist $exitCode ungleich 0, wird die Dokumentation auf STDERR ausgegeben,
und das Programm mit dem angegebenen Exitcode beendet.

Ist eine Meldung $msg angegeben, wird diese vor und nach der
Programmdokumentation ausgegeben.

=head4 Example

  if (grep {/^(-h|--help)$/} @ARGV) {
      Blog::Base::R1::Help->exit;
  }
  if (@ARGV) {
      Blog::Base::R1::Help->exit(10,"FEHLER: Unerwartete Parameter (@ARGV)");
  }

=cut

# -----------------------------------------------------------------------------

sub exit {
    my $class = shift;
    my $exitCode = shift || 0;
    # @_: @opt -or- $msg,@opt

    my $text = $class->text(@_);

    if ($exitCode) {
        # hmm...
        # binmode STDERR,':locale';
        print STDERR $text;
    }
    else {
        if (-t STDOUT) {
            my $pager = $ENV{'PAGER'} || 'less -i';
            my $fh = Blog::Base::Quiq::FileHandle->new('|-',"LESSCHARSET=utf-8 $pager");
            binmode $fh,':utf8';
            print $fh $text;
            $fh->close;
        }
        else {
            # binmode STDOUT,':locale';
            print $text;
        }
    }

    exit $exitCode;
}

# -----------------------------------------------------------------------------

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=cut

# -----------------------------------------------------------------------------

1;

# eof
