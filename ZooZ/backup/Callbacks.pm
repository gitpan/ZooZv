
package ZooZ::Callbacks;

# this package takes care of registering and keeping
# track of callbacks. Ideally, only one callback object
# needs to be created per project which contains all
# the information of all registered callbacks.
# By callbacks, I really mean subroutines.

use strict;

1;

sub new {
  my ($class) = @_;

  my $self    = bless {
		       CB => {},
		       I  => 0, # just an index
		      } => $class;

  return $self;
}

sub add {
  my ($self, $name, $code) = @_;

  $self->{CB}{$name} = $code;
}

sub remove  { delete $_[0]->{CB}{$_[1]} }
sub listAll { keys %{$_[0]->{CB}} }

sub rename  {
  my ($self, $old, $new) = @_;

  $self->{CB}{$new} = delete $self->{CB}{$old};
}

sub code {
  my ($self, $name, $code) = @_;

  $self->{CB}{$name} = $code if $code;
  return $self->{CB}{$name};
}

sub index   { $_[0]->{I}++ }

sub newName {
  my $self = shift;

  my $i = $self->index;
  return "_Subroutine_$i";
}

sub CallbackExists { exists $_[0]{CB}{$_[1]} }
