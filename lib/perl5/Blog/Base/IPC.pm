package Blog::Base::IPC;
use base qw/Blog::Base::Object/;

use strict;
use warnings;

use IPC::Open3 ();
use Blog::Base::Shell;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::IPC - Interprozesskommunikation

=head1 BASE CLASS

Blog::Base::Object

=head1 METHODS

=head2 Methods

=head3 filter() - Rufe ein Kommando als Filter auf

=head4 Synopsis

    ($out,$err) = Blog::Base::IPC->filter($cmd,$in);

=head4 Description

Rufe Kommando $cmd als Filter auf. Das Kommando erhält die
Daten $in auf stdin und liefert die Daten $out und
$err auf stdout bzw. stderr.

=cut

# -----------------------------------------------------------------------------

sub filter {
    my ($class,$cmd,$in) = @_;

    local (*W,*R,*E,$/);
    my $pid = IPC::Open3::open3(\*W,\*R,\*E,$cmd);
    unless ($pid) {
        $class->throw(
            q{IPC-00001: Kann Filterkommando nicht forken},
            Cmd=>$cmd,
        );
    }

    if (defined $in) {
        print W $in;
    }
    close W;

    my $out = <R>;
    close R;

    my $err = <E>;
    close E;

    waitpid $pid,0;
    # FIXME: checkError nach Blog::Base::IPC verlagern, in checkExit umbenennen
    Blog::Base::Shell->checkError($?,$err,$cmd);

    return  ($out,$err);
}

# -----------------------------------------------------------------------------

=head1 AUTHOR

Frank Seitz, http://fseitz.de/

=head1 COPYRIGHT

Copyright (C) 2010-2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
