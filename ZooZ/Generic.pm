package ZooZ::Generic;

# this defines some generic functions that can be used by anyone.

'the truth';

sub BindMouseWheel {
  my ($top, $w) = @_;

  if ($^O eq 'MSWin32') {
    # not tested!!!
    $top->bind('<MouseWheel>' =>
	       [ sub { $_[0]->yview('scroll', -($_[1] / 120) * 3, 'units') },
		 Tk::Ev('D') ]
	      );
  } else {
    $top->bind('<4>' => sub {
		 my $w2 = ref $w eq 'CODE' ? $w->() : $w;
		 $w2->yview('scroll', -3, 'units') unless $Tk::strictMotif;
	       });

    $top->bind('<5>' => sub {
		 my $w2 = ref $w eq 'CODE' ? $w->() : $w;
		 $w2->yview('scroll', +3, 'units') unless $Tk::strictMotif;
	       });
  }
}

