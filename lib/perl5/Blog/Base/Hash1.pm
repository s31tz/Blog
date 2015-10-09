package Blog::Base::Hash1;
use base qw/Blog::Base::Hash/;

use strict;
use warnings;

# -----------------------------------------------------------------------------

=head1 NAME

Blog::Base::Hash1 - Hash-Klasse

=head1 BASE CLASS

L<Blog::Base::Hash|../Blog::Base/Hash.html>

=head1 METHODS

=head2 new()

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @args

    my $h = $class->SUPER::new(@_);
    $h->unlockKeys;
    
    return $h;
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
