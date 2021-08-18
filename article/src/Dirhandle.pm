package Dirhandle;

use strict;
use warnings;

sub new {
    my ($class,$dir) = @_;

    opendir my $dh,$dir or die "ERROR: opendir failed: $dir ($!)\n";
    return bless $dh,$class;
}

sub close {
    my $self = shift;

    closedir $self or die "ERROR: closedir failed ($!)\n";
    return;
}

sub next {
    return readdir shift;
}

1;

# eof
