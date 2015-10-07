package Blog::Base::Process;
use base qw/Blog::Base::Object/;

use strict;
use warnings;

use Cwd ();
use Blog::Base::System;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Process - Information über den laufenden Prozess

=head1 BASE CLASS

L<Blog::Base::Object|../Blog::Base/Object.html>

=head1 METHODS

=head2 Prozess-Eigenschaften

=head3 cwd() - Liefere/setze aktuelles Verzeichnis

=head4 Synopsis

    $dir = $this->cwd;
    $this->cwd($dir);

=head4 Description

Liefere das aktuelle Verzeichnis ("current working directory") des
Prozesses. Ist ein Argument angegeben, wechsele in das betreffende
Verzeichnis.

=head4 Examples

Ermittele aktuelles Verzeichnis:

    $dir = Blog::Base::Process->cwd;

Wechsele Verzeichnis:

    Blog::Base::Process->cwd('/tmp');

=cut

# -----------------------------------------------------------------------------

sub cwd {
    my $this = shift;
    # @_: $dir

    if (!@_) {
        return Cwd::cwd;
    }

    my $dir = shift;
    CORE::chdir $dir or do {
        $this->throw(
            q{PROC-00001: Cannot change directory},
            Argument=>$dir,
            CurrentWorkingDirectory=>Cwd::cwd,
        );
    };

    return;
}

# -----------------------------------------------------------------------------

=head3 euid() - Liefere/setze effektive User-Id

=head4 Synopsis

    $uid = $class->euid;
    $class->euid($uid);

=head4 Description

Liefere die Effektive User-Id (EUID) des Prozesses. Ist ein Argument
angegeben, setze die EUID auf die betreffende User-Id.

=head4 Examples

Liefere aktuelle EUID:

    $uid = Blog::Base::Process->euid;

Setze EUID:

    Blog::Base::Process->euid(1000);

=cut

# -----------------------------------------------------------------------------

sub euid {
    my $this = shift;
    # @_: $uid

    if (!@_) {
        return $>;
    }

    my $uid = shift;
    $> = $uid;
    if ($> != $uid) {
        $this->throw(
            q{PROC-00002: Cannot set EUID},
            UID=>$<,
            EUID=>$>,
            NewEUID=>$uid,
            Error=>"$!",
        );
    };

    return;
}

# -----------------------------------------------------------------------------

=head3 user() - Name des Benutzers

=head4 Synopsis

    $user = $this->user;

=head4 Description

Liefere den Namen des Benutzers, unter dessen Rechten der laufende
Prozess ausgeführt wird.

=cut

# -----------------------------------------------------------------------------

sub user {
    my $this = shift;
    return Blog::Base::System->user($>);
}

# -----------------------------------------------------------------------------

=head2 Sonstiges

=head3 modules() - Liste der geladenen Perl Moduldateien

=head4 Synopsis

    @arr|$arr = $this->modules;

=head4 Description

Liefere die Liste der Pfade der geladenen Perl Moduldateien.
Die Liste ist alphabetisch sortiert. Im Skalarkontext liefere eine
Referenz auf die Liste.

=head4 Example

    $ perl -MBlog::Base::Process -e 'printf "%s\n",join "\n",Blog::Base::Process->modules'
    /home/fs/lib/perl5/Prty/Object.pm
    /home/fs/lib/perl5/Prty/Process.pm
    /home/fs/lib/perl5/Prty/Stacktrace.pm
    /usr/lib/x86_64-linux-gnu/perl/5.20/Cwd.pm
    /usr/share/perl/5.20/Exporter.pm
    /usr/share/perl/5.20/XSLoader.pm
    /usr/share/perl/5.20/base.pm
    /usr/share/perl/5.20/strict.pm
    /usr/share/perl/5.20/vars.pm
    /usr/share/perl/5.20/warnings.pm
    /usr/share/perl/5.20/warnings/register.pm

=cut

# -----------------------------------------------------------------------------

sub modules {
    my $this = shift;

    my @arr;
    for my $key (sort values %INC) {
        push @arr,$key;
    }
    @arr = sort @arr;

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2011-2015 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
