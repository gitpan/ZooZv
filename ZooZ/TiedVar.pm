
package ZooZ::TiedVar;

1;

sub TIESCALAR {
  my ($class, $w, $m, $o, $l, $p) = @_;

  $p ||= [];

  return bless {
		W => $w,  # the widget
		V => 0,   # default value
		M => $m,  # method to use.
		O => $o,  # the option name
		L => $l,  # the label.
		P => $p,  # pre-options
	       } => $class;
}

sub FETCH { $_[0]{V} }

sub STORE {
  my ($self, $v) = @_;

  $self->{V} = $v;

  # try to apply it.
  my $m = $self->{M};
  #print "running $m with $self->{O} => $v on $self->{W}.\n";

  # don't apply it if it's undefined.
  defined $v or return;

  eval {
    $self->{W}->$m(@{$self->{P}}, $self->{O} => $v);
  };

  if ($@) {
    $self->{L}->configure(-fg => 'red') if $self->{L};
  } else {
    $self->{L}->configure(-fg => 'black') if $self->{L};
  }
}
