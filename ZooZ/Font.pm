
package ZooZ::Fonts;

use strict;

sub new {
  my $class = shift;

  my $self  = bless {
		     FONTS => {},
		     } => $class;

  return $self;
}

sub add {
  my ($self, $name, $desc) = @_;

  $self->{FONTS}{$name} = $desc;
}

sub remove  { delete $_[0]{FONTS}{$_[1]} }
sub listAll { keys %{$_[0]{FONTS} }

sub FontExists { exists $_[0]{FONTS}{$_[1]} }

1;
