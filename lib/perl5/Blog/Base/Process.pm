package Blog::Base::Process;
use base qw/Blog::Base::Object/;

use strict;
use warnings;

use Cwd ();
use Blog::Base::Array;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Process - Informationen über den laufenden Prozess

=head1 BASE CLASS

L<Blog::Base::Object|../Blog::Base/Object.html>

=head1 METHODS

=head2 setUid() - Setze (effektive) User-Id

=head3 Synopsis

    $class->setUid($uid);

=head3 Description

Setze die Effektive User-Id (EUID) auf ID $uid.

=cut

# -----------------------------------------------------------------------------

sub setUid {
    my $this = shift;
    my $uid = shift;

    $> = $uid;
    if ($> != $uid) {
        $this->throw(
            q{PROCESS-00001: Kann Effektive User-Id nicht setzen},
            UID=>$<,
            EUID=>$>,
            NewEUID=>$uid,
            Error=>"$!",
        );
    };
}

# -----------------------------------------------------------------------------

=head2 cwd() - Liefere das Current Working Directory

=head3 Synopsis

    $dir = $this->cwd;

=cut

# -----------------------------------------------------------------------------

sub cwd {
    my $this = shift;
    return Cwd::getcwd;
}

# -----------------------------------------------------------------------------

=head2 perlModules() - Liste der geladenen Perl-Module

=head3 Synopsis

    @arr|$arr = $this->perlModules;

=head3 Description

Liefere die Liste der Namen der geladenen Perl-Module. Die Liste ist
alphabetisch sortiert. Im Skalarkontext liefere eine Referenz auf
die Liste.

=cut

# -----------------------------------------------------------------------------

sub perlModules {
    my $this = shift;

    my @arr;
    for my $key (sort keys %INC) {
        push @arr,$key;
    }

    return wantarray? @arr: Blog::Base::Array->bless(\@arr);
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
