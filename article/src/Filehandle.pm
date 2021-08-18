package Filehandle;

use strict;
use warnings;

sub new {
    my ($class,$mode,$file) = @_;

    open my $fh,$mode,$file or die "ERROR: open failed: $file ($!)\n";
    return bless $fh,$class;
}

sub close {
    my $self = shift;

    close $self or die "ERROR: close failed ($!)\n";
    return;
}

sub slurp {
    my $self = shift;

    local $/;
    return scalar <$self>;
}

1;

# eof
