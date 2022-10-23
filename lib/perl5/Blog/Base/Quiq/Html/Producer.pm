# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Blog::Base::Quiq::Html::Producer - Generierung von HTML-Code

=head1 BASE CLASS

L<Blog::Base::Quiq::Html::Construct>

=head1 DESCRIPTION

Die Klasse vereinigt die Funktionalität der Klassen Blog::Base::Quiq::Html::Tag
und Blog::Base::Quiq::Html::Construct und erlaubt somit die Generierung von
einzelnen HTML-Tags und einfachen Tag-Konstrukten. Sie
implementiert keine eigene Funktionalität, sondern erbt diese von
ihren Basisklassen. Der Konstruktor ist in der Basisklasse
Blog::Base::Quiq::Html::Tag implementiert.

Vererbungshierarchie:

  Blog::Base::Quiq::Html::Tag        (einzelne HTML-Tags)
      |
  Blog::Base::Quiq::Html::Construct  (einfache Konstrukte aus HTML-Tags)
      |
  Blog::Base::Quiq::Html::Producer   (vereinigte Funktionalität)

Einfacher Anwendungsfall:

  my $h = Blog::Base::Quiq::Html::Producer->new;
  print Blog::Base::Quiq::Html::Page->html($h,
      ...
  );

=cut

# -----------------------------------------------------------------------------

package Blog::Base::Quiq::Html::Producer;
use base qw/Blog::Base::Quiq::Html::Construct/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.206';

# -----------------------------------------------------------------------------

=head1 VERSION

1.206

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2022 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
