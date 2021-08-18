#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

# begin
my $max = '-inf';
for my $n (-100,-10,-50) {
    $max = $n if $n > $max;
}
say $max;
__END__
-10
