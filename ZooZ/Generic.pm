package ZooZ::Generic;

# this defines some generic functions that can be used by anyone.

use strict;

my $msgFrame;
my $msgLabel;
my ($msgX, $msgY, $msgDelay);
my $msgMoving = 0;

'the truth';

sub BindMouseWheel {
  my ($top, $w) = @_;

  if ($^O eq 'MSWin32') {
    # not tested!!!
    $top->bind('<MouseWheel>' =>
	       [ sub {
		   my $w2 = ref $w eq 'CODE' ? $w->() : $w;
		   $w2->yview('scroll', -($_[1] / 120) * 3, 'units') },
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

########
#
# This method pops up a message for the user.
# The message is contained in a frame that drops down from the middle
# of the top border of the given window, stays there for a few secs, then
# goes back up .. animated .. sort of like the auto-hidden taskbar.
#
########

sub popMessage {
  return if $msgMoving;

  my ($over, $msg) = @_;

  $msgDelay = $_[2] || 3000;  # 3 secs

  unless ($msgFrame) {
    $msgFrame = $::MW->Frame(qw/-bd 1 -relief solid/);
    $msgLabel = $msgFrame->Label(qw/-padx 20 -pady 20/,
				 -bg   => 'white',
				 -font => 'Level',
				)->pack(qw/-fill both/);
  }

  $msgLabel->configure(-text => $msg);
  $msgFrame->update;
  $msgFrame->raise;

  $msgMoving = 1;

  animateDown($over);
}

sub animateDown {
  my $top = shift;

  unless (defined $msgX) {
    $msgY = -$msgFrame->reqheight;
    $msgX = int 0.5 * ($top->width - $msgFrame->reqwidth);
  } else {
    $msgY++;
  }

  $msgFrame->place(-x => $msgX,
		   -y => $msgY);

  if ($msgY == 0) {
    $top->after($msgDelay => [\&animateUp, $top]);
    return;
  }

  $top->after(5 => [\&animateDown, $top]);
}

sub animateUp {
  my $top = shift;

  $msgY--;

  $msgFrame->place(-x => $msgX,
		   -y => $msgY);

  if ($msgY == -$msgFrame->height) {
    $msgX = $msgY = undef;
    $msgFrame->placeForget;
    $msgMoving = 0;

    return;
  }

  $top->after(5 => [\&animateUp, $top]);
}
