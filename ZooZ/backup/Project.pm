
package ZooZ::Project;

use strict;
use Tk qw/:colors/;
use Tk::Tree;

use ZooZ::DefaultArgs;

#############
#
# Global variables
#
#############
my $gridW = 90;     # width of each grid.
my $gridH = 50;     # height of each grid.
my $XoffS = 30;     # X offset of first grid.
my $YoffS = 30;     # Y offset of first grid.

my $maxR  = 20;    # max number of rows.
my $maxC  = 20;    # max number or cols.

my $isContainer = qr/^(?:Tk::)?(?:Lab(?:el)?)?[Ff]rame$/;  # for container widgets.

##############
#
# Constructor
#
##############

sub new {
  my ($self, %args) = @_;

  my $class = ref($self) || $self;

  my $obj = bless {
		   PROJID    => $args{-id},
		   PROJNAME  => $args{-name},
		   PARENT    => $args{-parent},
		   TITLE     => $args{-title},
		   ICONS     => $args{-icons},
		   SELECTED  => undef,                  # currently selected widget
		   MOVABLE   => undef,                  # currently movable widget
		   IDS       => $args{-ids} || {},      # widget ids to use when creating unique names.
		   BALLOON   => $args{-parent}->Balloon,
		   DRAGMODE  => 0,                      # if we are in drag mode.
		   HIERTOP   => $args{-hiertop} || 'MainWindow',
		   ISCHILD   => $args{-ischild} || 0,
		   SUBHIERS  => {},
		   CUROBJ    => $args{-curobj}  || [],
		  } => $class;

  $obj->_createGrid;
  $obj->_defineBindings;

  # create the hier list and preview window if we have to.
  if ($obj->{ISCHILD}) {
    $obj->{TREE}    = $args{-tree};
    $obj->{PREVIEW} = $args{-preview};
  } else {
    $obj->_createHierList;
    $obj->_createPreviewWindow;
  }

  $obj->{CUROBJ}[0] = $obj;

  return $obj;
}

sub _createHierList {
  my $self = shift;

  # bind tree such that when we click on a widget, it is selected.
  my $tree = $self->{PARENT}->Tree(-borderwidth => 1,
				   -browsecmd   => sub {
				     return unless @_ == 1;

				     my $labS = shift;
				     $labS =~ s/.*\.// or do { # mainwindow
				       $self->unselectCurrentWidget;
				       return;
				     };

				     # $labS is just a string.
				     # get the actual label widget.
				     my ($r, $c) = @{$self->{LABEL2GRID}{$labS}};
				     my $lab = $self->{GRID}[$r][$c]{LABEL};

				     $self->selectWidget($lab);
				   },
				  )->pack(qw/-side right -fill y/);

  # create the entry for the main window.
  $tree->add('MainWindow', -text => 'MainWindow');

  # save it.
  $self->{TREE} = $tree;
}

###############
#
# This sub creates a new Toplevel that serves as a preview
# of the project.
#
###############

sub _createPreviewWindow {
  my $self = shift;

  my $t = $self->{PARENT}->Toplevel;
  $t->protocol(WM_DELETE_WINDOW => [$t => 'withdraw']);

  $self->{PREVIEW} = $t;
}

###############
#
# This sub hides/unhides the preview window
#
###############

sub togglePreview {
  my $self = shift;

  # toggle.
  if ($self->{PREVIEW}->ismapped) {
    $self->{PREVIEW}->withdraw;
  } else {
    $self->{PREVIEW}->deiconify;
  }
}

###########
#
# This subroutine creates the grid canvas along with other
# canvas objects.
#
###########

sub _createGrid {
  my $self = shift;

  # create the canvas.
  my $cv = $self->{CV} = $self->{PARENT}->Canvas(-bg      => 'white',
						 -confine => 1,
						)->pack(qw/-side left
							-fill both
							-expand 1/);

  # draw the grid.
  my $x = $XoffS;
  my $y = $YoffS;

  for my $r (0 .. $maxR - 1) {
    for my $c (0 .. $maxC - 1) {
      $self->{GRID}[$r][$c]{ID} =
	$cv->createRectangle($x, $y,
			     $x + $gridW, $y + $gridH,
			     -stipple => 'transparent',
			     -fill    => 'white',
			     -outline => 'grey',
			     -tags    => ['GRID', "GRID_$ {r}_$ {c}"]
			    );

      $x += $gridW;
    }

    $x = $XoffS;
    $y += $gridH;
  }

  { # Add the row/col numbers.
    my $x = $XoffS / 2;
    my $y = $YoffS + $gridH / 2;

    for my $r (0 .. $maxR - 1) {
      $cv->createText($x, $y,
		      -text => $r,
		      -font => 'Row/Col Num',
		      -fill => 'grey25',
		     );
      $y += $gridH;
    }

    $x = $XoffS + $gridW / 2;
    $y = $YoffS / 2;

    for my $c (0 .. $maxC - 1) {
      $cv->createText($x, $y,
		      -text => $c,
		      -font => 'Row/Col Num',
		      -fill => 'grey25',
		     );
      $x += $gridW;
    }
  }

  $cv->configure(-scrollregion => [0, 0, ($cv->bbox('all'))[2, 3]]);

  # create a dummy outline rectangle to display when moving widgets.
  $self->{DRAG_OUTLINE} = $cv->createRectangle(0, 0, 0, 0,
						 -width   => 2,
						 -outline => 'grey12',
						 -fill    => 'white',
						 -stipple => 'transparent',
						 -state   => 'hidden',
						);

  # create the expand/contract buttons.
  my @opts = (
	      -highlightthickness => 0,
	      -borderwidth        => 1,
	      -pady               => 0,
	      -relief             => 'flat',
	     );

  for (
       [qw/CONTRACT_H white leftArrow /, 'Decrease size horizontally by 1'],
       [qw/EXPAND_H   white rightArrow/, 'Increase size horizontally by 1'],
       [qw/CONTRACT_V white upArrow   /, 'Decrease size vertically by 1'  ],
       [qw/EXPAND_V   white downArrow /, 'Increase size vertically by 1'  ],
      ) {
    $self->{$_->[0]} = $cv->Label(
				  -bitmap => $_->[2],
				  -bg     => $_->[1],
				  @opts,
				 );

    $self->{BALLOON}->attach($self->{$_->[0]},
			     -balloonmsg => $_->[3],
			    );

    $self->{$_->[0]}->bind('<Enter>' => [$self->{$_->[0]}, 'configure', -bg => 'tan']);
    $self->{$_->[0]}->bind('<Leave>' => [$self->{$_->[0]}, 'configure', -bg => $_->[1]]);
    $self->{$_->[0]}->bind('<1>'     => [$self, 'resizeWidget', $_->[0]]);
  }

  # the DESCEND button (for containers only)
  $self->{DESCEND} = $cv->Label(-bitmap => 'box',
				-fg     => 'red',
				-bg     => 'white',
				@opts,
			       );
  $self->{BALLOON}->attach($self->{DESCEND},
			   -balloonmsg => "Manage this widget's children",
			  );
  $self->{DESCEND}->bind('<Enter>' => [$self->{DESCEND}, 'configure', -bg => 'tan']);
  $self->{DESCEND}->bind('<Leave>' => [$self->{DESCEND}, 'configure', -bg => 'white']);
  $self->{DESCEND}->bind('<1>'     => [$self, 'descendHier']);
}

##########
#
# defines all the default bindings for interactivity.
#
##########

sub _defineBindings {
  my $self = shift;

  my $cv = $self->{CV};

  $cv->CanvasBind('<1>' => [$self => 'unselectCurrentWidget']);

  #$cv->CanvasBind('<<DropWidget>>' => \&dropWidget);
}

############
#
# called when a user clicks on any of the resizing arrows.
#
############

sub resizeWidget {
  my ($self, $dir) = @_;

  my $cv = $self->{CV};

  # first thing, get the location of the widget to be resized.
  my $lab = $self->{SELECTED};
  my ($row, $col) = @{$self->{LABEL2GRID}{$lab}};

  my $gridRef = $self->{GRID}[$row][$col];
  my $rsize   = $gridRef->{ROWS};
  my $csize   = $gridRef->{COLS};

  if      ($dir eq 'EXPAND_H') {
    # check for edges.
    return if $row + $rsize == $maxR;

    # check if the column on the right is used or not.
    for my $r ($row .. $row + $rsize - 1) {
      return if $self->{GRID}[$r][$col + $csize]{WIDGET};
    }

    # we have space. let's expand it.
    $gridRef->{COLS}++;

    # get the bbox of the new area.
    my @tags = map {'GRID_' . $_ . '_' . ($col+$csize)} $row .. $row + $rsize - 1;
    my @new  = $cv->bbox(@tags);
    my @box  = $cv->bbox($gridRef->{WINDOW});

    $cv->coords($gridRef->{WINDOW},
		($box[0] + $new[2] - 1) / 2,
		($box[1] + $new[3] - 1) / 2,
	       );

    $cv->itemconfigure($gridRef->{WINDOW},
		       -width => $gridRef->{COLS} * $gridW,
		      );

    # indicate that the new location is used.
    for my $r ($row .. $row + $rsize - 1) {
      $self->{GRID}[$r][$col + $csize]{WIDGET} = $gridRef->{WIDGET};
      $self->{GRID}[$r][$col + $csize]{MASTER} = $lab;
    }

  } elsif ($dir eq 'CONTRACT_H') {
    # can't shrink if there is only one column.
    return if $csize == 1;

    # ok .. let's shrink.
    $gridRef->{COLS}--;

    my @tags = map {'GRID_' . $_ . '_' . ($col+$csize - 1)} $row .. $row + $rsize - 1;
    my @new  = $cv->bbox(@tags);
    my @box  = $cv->bbox($gridRef->{WINDOW});

    $cv->coords($gridRef->{WINDOW},
		($box[0] + $new[0]) / 2,
		($box[1] + $box[3] - 1) / 2,
	       );

    $cv->itemconfigure($gridRef->{WINDOW},
		       -width => $gridRef->{COLS} * $gridW,
		      );

    # empty the location.
    for my $r ($row .. $row + $rsize - 1) {
      $self->{GRID}[$r][$col + $csize - 1]{WIDGET} = undef;
      $self->{GRID}[$r][$col + $csize - 1]{MASTER} = undef;
    }

  } elsif ($dir eq 'EXPAND_V') {
    # check for edges.
    return if $col + $csize == $maxC;

    # check if the row below is used or not.
    for my $c ($col .. $col + $csize - 1) {
      return if $self->{GRID}[$row + $rsize][$c]{WIDGET};
    }

    # we have space. let's expand it.
    $gridRef->{ROWS}++;

    # get the bbox of the new area.
    my @tags = map {'GRID_' . ($row + $rsize) . '_' . $_} $col .. $col + $csize - 1;
    my @new  = $cv->bbox(@tags);
    my @box  = $cv->bbox($gridRef->{WINDOW});

    $cv->coords($gridRef->{WINDOW},
		($box[0] + $new[2] - 1) / 2,
		($box[1] + $new[3] - 1) / 2,
	       );

    $cv->itemconfigure($gridRef->{WINDOW},
		       -height => $gridRef->{ROWS} * $gridH,
		      );

    # indicate that the new location is used.
    for my $c ($col .. $col + $csize - 1) {
      $self->{GRID}[$row + $rsize][$c]{WIDGET} = $gridRef->{WIDGET};
      $self->{GRID}[$row + $rsize][$c]{MASTER} = $lab;
    }

  } else { # $dir eq 'CONTRACT_V'
    # can't shrink if there is only one row.
    return if $rsize == 1;

    # ok .. let's shrink.
    $gridRef->{ROWS}--;

    my @tags = map {'GRID_' . ($row+$rsize - 1) . '_' . $_} $col .. $col + $csize - 1;
    my @new  = $cv->bbox(@tags);
    my @box  = $cv->bbox($gridRef->{WINDOW});

    $cv->coords($gridRef->{WINDOW},
		($box[0] + $box[2] - 1) / 2,
		($box[1] + $new[1]) / 2,
#		($box[0] + $new[0]) / 2,
#		($box[1] + $box[3] - 1) / 2,
	       );

    $cv->itemconfigure($gridRef->{WINDOW},
		       -height => $gridRef->{ROWS} * $gridH,
		      );

    # empty the location.
    for my $c ($col .. $col + $csize - 1) {
      $self->{GRID}[$row + $rsize - 1][$c]{WIDGET} = undef;
      $self->{GRID}[$row + $rsize - 1][$c]{MASTER} = undef;
    }

  }

  # update the preview
  $self->updatePreviewWindow;
}

sub dropWidgetInCurrentObject {
  @_ = ($_[0]{CUROBJ}[0]);
  goto &dropWidget;
}

#############
#
# called when the user clicks on the canvas to drop a new widget.
# For new widgets, this is called directly from ZooZ.pl
#
#############

sub dropWidget {
  my $self = shift;

  my $cv = $self->{CV};

  # check where the click happened.
  my ($id, $row, $col) = $self->_getGridClick;

  # didn't click on anything useful.
  return undef unless defined $id;

  my $ref = $self->{GRID}[$row][$col];

  # is it an empty location?
  return undef if $ref->{WIDGET};

  # it is empty. Fill it up.
  $ref->{WIDGET}= $::SELECTED_W;

  # create a new and uniqe name.
  my $name = $::SELECTED_W . ++$self->{IDS}{$::SELECTED_W};

  # get coordinates of new window.
  my @c = $cv->coords($id);
  my $w = $c[2] - $c[0];
  my $h = $c[3] - $c[1];

  # create the label and window.
  my $frame = $cv->Frame(-relief => 'raised', -borderwidth => 1);
  my $label = $frame->Label->pack(qw/-fill both -expand 1/);

  $ref->{WINDOW} = $cv->createWindow($c[0] + $w / 2,
				     $c[1] + $h / 2,
				     -window => $frame,
				     -width  => $w,
				     -height => $h,
				    );

  $ref ->{NAME}               = $name;
  $ref ->{LABEL}              = $label;
  $ref ->{LABFRAME}           = $frame;
  $ref ->{ROWS}               = 1;
  $ref ->{COLS}               = 1;
  $self->{LABEL2GRID}{$label} = [$row, $col];

  # create the compound image to place in the label.
  my $compound = $label->Compound;
  $label   ->configure(-image => $compound);
  if (exists $self->{ICONS}{lc $::SELECTED_W}) {
    $compound->Image(-image => $self->{ICONS}{lc $::SELECTED_W});
  } else {
    $compound->Bitmap(-bitmap => 'error');#, -background => 'cornflowerblue');
  }
  $compound->Line;
  $compound->Text(-text => $name,
		  -font => 'WidgetName',
		 );

  $self->_bindWidgetLabel($label);

  # create the actual preview widget.
  {
    my $args = ZooZ::DefaultArgs->getDefaults($::SELECTED_W, $name);
    my $type = $::SELECTED_W eq 'Image' ? 'Label' : $::SELECTED_W;

    $ref->{PREVIEW} = $self->{PREVIEW}->$type(%$args);
  }

  # add to the hier tree
  $self->{TREE}->add($self->{HIERTOP} . '.' . $label, -text => $name);
  $self->{TREE}->autosetmode;

  # select it
  $self->selectWidget    ($label);

  # must update the preview window.
  $self->updatePreviewWindow;

  return 1;
}

#############
#
# This sub sets up the bindings for moving a widget around.
#
#############

sub _bindWidgetLabel {
  my ($self, $lab) = @_;

  #my $lab = $self->{GRID}[$row][$col]{LABEL};

  $lab->bind('<1>'                => [$self, 'selectWidget', $lab]);
  $lab->bind('<B1-Motion>'        => [$self, 'dragWidget',   $lab]);
  $lab->bind('<B1-ButtonRelease>' => [$self, 'moveWidget',   $lab]);
}

#####################
#
# This sub is called when a user ends the dragging of
# an already existing widget (dropping it) over the canvas.
#
#####################

sub moveWidget {
  my ($self, $lab) = @_;

  return unless $self->{MOVABLE};
  return unless $self->{DRAGMODE};

  $self->{DRAGMODE} = 0;

  my $cv = $self->{CV};

  $cv->itemconfigure($self->{DRAG_OUTLINE},
		     -state => 'hidden',
		    );

  # where did we release the button?
  my ($id, $row, $col) = $self->_getGridClick;

  # didn't click on anything useful.
  return undef unless defined $id;

  # get the old location first.
  my ($oldR, $oldC) = @{$self->{LABEL2GRID}{$lab}};

  # is it an empty location?
  # must check multiple locations if widget is larger than min.
  # it's ok if the new location is occupied by the movable label.
  {
    my ($r, $c)   = @{$self->{GRID}[$oldR][$oldC]}{qw/ROWS COLS/};
    for my $ri (0 .. $r - 1) {
      for my $ci (0 .. $c - 1) {
	next if $row + $ri == $oldR && $col + $ci == $oldC;
	return undef if
	  ($self->{GRID}[$row + $ri][$col + $ci]{WIDGET} and
	   !$self->{GRID}[$row + $ri][$col + $ci]{MASTER} ||
	   $self->{GRID}[$row + $ri][$col + $ci]{MASTER} != $lab);
      }
    }
  }

  # empty. re-position the widget.

  # now swap logically.
  $self->{GRID}[$row] [$col]  = $self->{GRID}[$oldR][$oldC];
  #$self->{GRID}[$oldR][$oldC] = {};
  for my $r (0 .. $self->{GRID}[$row][$col]{ROWS} - 1) {
    for my $c (0 .. $self->{GRID}[$row][$col]{COLS} - 1) {
      next if $oldR + $r == $row && $oldC + $c == $col;

      $self->{GRID}[$oldR + $r][$oldC + $c] = {};
    }
  }

  for my $r (0 .. $self->{GRID}[$row][$col]{ROWS} - 1) {
    for my $c (0 .. $self->{GRID}[$row][$col]{COLS} - 1) {
      next if $r == 0 && $c == 0;

      $self->{GRID}[$row + $r][$col + $c]{WIDGET} = $self->{GRID}[$row] [$col]{WIDGET};
      $self->{GRID}[$row + $r][$col + $c]{MASTER} = $lab;
    }
  }

  $self->{LABEL2GRID}{$lab}   = [$row, $col];

  # and swap physically.
  my @c = $cv->coords($id);
#  my $w = $c[2] - $c[0];
#  my $h = $c[3] - $c[1];
  my $w = $self->{MOVABLE}->width;
  my $h = $self->{MOVABLE}->height;

  $cv->coords($self->{GRID}[$row][$col]{WINDOW},
	      $c[0] + $w / 2 + 1,
	      $c[1] + $h / 2 + 1,
	     );

  # update the resize buttons.
  $self->_showResizeButtons;

  # must update the preview window.
  $self->updatePreviewWindow;
}

###################
#
# This sub is called when the user drags an already existing
# widget over the canvas with the intention of moving it.
#
###################

sub dragWidget {
  my ($self, $lab) = @_;

  return unless $self->{MOVABLE};
  my $cv = $self->{CV};

  my $x = $cv->canvasx($cv->pointerx - $cv->rootx);
  my $y = $cv->canvasy($cv->pointery - $cv->rooty);

  $cv->itemconfigure($self->{DRAG_OUTLINE},
		     -state => 'normal',
		    );

  my $w = $self->{MOVABLE}->width;
  my $h = $self->{MOVABLE}->height;

  # mouse pointer is always at the center of the top left grid.
  $cv->coords($self->{DRAG_OUTLINE} =>
	      $x - $gridW / 2,
	      $y - $gridH / 2,
	      $x + $w - $gridW / 2,
	      $y + $h - $gridH / 2,
	     );

  $self->{DRAGMODE} = 1;
}

#############
#
# This sub is called when a user selects a widget by clicking on it.
#
#############

sub selectWidget {
  my ($self, $lab) = @_;

  $self->unselectCurrentWidget;

  $lab->configure(-bg => 'cornflowerblue');
  $self->{SELECTED} = $lab;
  $self->{MOVABLE}  = $lab;

  # must show the resize buttons.
  $self->_showResizeButtons;

  # reflect this in the hier tree.
  $self->{TREE}->selectionClear;
  $self->{TREE}->selectionSet("$self->{HIERTOP}.$lab");
  $self->{TREE}->anchorSet   ("$self->{HIERTOP}.$lab");
}

sub unselectCurrentWidget {
  my $self = shift;

  my $lab  = $self->{SELECTED};
  $lab or return;

  $lab->configure(-bg => NORMAL_BG);
  $self->{SELECTED} = '';
  $self->{MOVABLE}  = '';

  # must hide the resize buttons.
  $self->_hideResizeButtons;

  # reflect this in the hier tree.
  $self->{TREE}->selectionClear;
  $self->{TREE}->selectionSet($self->{HIERTOP});
  $self->{TREE}->anchorSet   ($self->{HIERTOP});

  return $lab;
}

#############
#
# this sub finds out the grid location we clicked on.
#
#############

sub _getGridClick {
  my $self = shift;
  my $cv   = $self->{CV};

  my $x  = $cv->pointerx - $cv->rootx;
  my $y  = $cv->pointery - $cv->rooty;

  for my $id ($cv->find(overlapping => $x, $y, $x, $y)) {
    my @t  = $cv->gettags($id);

    my ($r, $c) = "@t" =~ /\bGRID_(\d+)_(\d+)\b/;
    defined $r or next;

    return ($id, $r, $c);
  }

  return undef;
}

###############
#
# This sub is called when a widget is selected.
# It displays the arrows used to resize the widget.
#
###############

sub _showResizeButtons {
  my $self = shift;

  my $cv = $self->{CV};

  # get the frame where the label is.
  my ($r, $c) = @{$self->{LABEL2GRID}{$self->{SELECTED}}};
  my $frame = $self->{GRID}[$r][$c]{LABFRAME};

  # place the buttons in $frame.
  $self->{EXPAND_H}  ->place(-in => $frame,
			     -x  => 23,
			     -y  => 2,
			    );
  $self->{CONTRACT_H}->place(-in => $frame,
			     -x  => 10,
			     -y  => 2,
			    );

  $self->{EXPAND_V}  ->place(-in => $frame,
			     -x  => 2,
			     -y  => 23,
			    );
  $self->{CONTRACT_V}->place(-in => $frame,
			     -x  => 2,
			     -y  => 10,
			    );

  # if it's a container, then show the box button.
  if ($self->{GRID}[$r][$c]{WIDGET} =~ $isContainer) {
    $self->{DESCEND}->place(-in => $frame,
			    -x  => 2,
			    -y  => 2,
			   );
  }

  $self->{$_}->raise for qw/EXPAND_H CONTRACT_H EXPAND_V CONTRACT_V DESCEND/;
}

sub _showResizeButtons_old {
  my $self = shift;

  my $cv = $self->{CV};

  # get the frame where the label is.
  my ($r, $c) = @{$self->{LABEL2GRID}{$self->{SELECTED}}};
  my $frame = $self->{GRID}[$r][$c]{LABFRAME};

  # place the buttons in $frame.
  $self->{EXPAND_H}  ->place(-in => $frame,
			     -x  => $gridW - 20,
			     -y  => 5,
			    );
  $self->{CONTRACT_H}->place(-in => $frame,
			     -x  => $gridW - 20,
			     -y  => 15,
			    );

  $self->{EXPAND_V}  ->place(-in => $frame,
			     -x  => 5,
			     -y  => 5,
			    );
  $self->{CONTRACT_V}->place(-in => $frame,
			     -x  => 15,
			     -y  => 5,
			    );

  $self->{$_}->raise for qw/EXPAND_H CONTRACT_H EXPAND_V CONTRACT_V DESCEND/;

}

###############
#
# This sub is called when a widget is unselected.
# It hides the arrows used to resize the widget.
#
###############

sub _hideResizeButtons {
  my $self = shift;

  $self->{$_}->placeForget for qw/EXPAND_H CONTRACT_H EXPAND_V CONTRACT_V DESCEND/;
}

###############
#
# This sub is called when the Delete key is pressed
# or when the delete toolbutton is invoked
#
###############

sub deleteSelectedWidget {
  my $self = shift;

  return unless $self->{SELECTED};
  my $lab = $self->unselectCurrentWidget;

  # delete the data structures.
  my $rc  = delete $self->{LABEL2GRID}{$lab};
  my $ref = delete $self->{GRID}[$rc->[0]][$rc->[1]];

  # delete the widgets.
  $_->destroy for $lab, $ref->{LABFRAME};
  $self->{CV}->delete($ref->{WINDOW});

  # free up the space.
  for my $r (0 .. $ref->{ROWS} - 1) {
    for my $c (0 .. $ref->{COLS} - 1) {
      $self->{GRID}[$rc->[0] + $r][$rc->[1] + $c] = {};
    }
  }

  # update the preview window;
  $self->updatePreviewWindow;
}

##############################
#
# This updates the preview window whenever
# something changes
#
##############################

sub updatePreviewWindow {
  my $self = shift;

  my $top = $self->{PREVIEW};

  # first, the title.
  $top->title($self->{TITLE}) unless $self->{ISCHILD};

  # now iterate through all the objects and update.
  for my $lab (keys %{$self->{LABEL2GRID}}) {
    my ($row, $col) = @{$self->{LABEL2GRID}{$lab}};

    my $ref = $self->{GRID}[$row][$col];

    $ref->{PREVIEW}->grid(-row        => $row,
			  -column     => $col,
			  -rowspan    => $ref->{ROWS},
			  -columnspan => $ref->{COLS},
			 );
  }
}

sub descendHier {
  my $self = shift;

  my $lab  = $self->{SELECTED};

  my ($r, $c) = @{$self->{LABEL2GRID}{$lab}};

  # create one if it doesn't exist.
  unless (exists $self->{SUBHIERS}{$lab}) {
    my $proj = $self->new(-id      => $self->{PROJID},
			  -parent  => $self->{PARENT},
			  -name    => $self->{PROJNAME},
			  -title   => $self->{TITLE},
			  -icons   => $self->{ICONS},
			  -ids     => $self->{IDS},
			  -hiertop => "$self->{HIERTOP}.$lab",
			  -ischild => 1,
			  -tree    => $self->{TREE},
			  -preview => $self->{GRID}[$r][$c]{PREVIEW},
			  -curobj  => $self->{CUROBJ},
			 );

    $proj->_hideCanvas;

    $self->{SUBHIERS}{$lab} = $proj;
  }

  # hide the current. unhide the child.
  $self->_hideCanvas;
  $self->{SUBHIERS}{$lab}->_unhideCanvas;
}

sub _hideCanvas   { $_[0]{CV}->packForget                               }
sub _unhideCanvas { $_[0]{CV}->pack(qw/-side left -fill both -expand 1/)}

##############################
#
# Data structures:
#
# $self->{TREE}                          = Hierarchy Tree.
# $self->{CV}                            = canvas object.
#
# $self->{GRID}[$row][$column]{ID}       = canvas ID of rectangle.
# $self->{GRID}[$row][$column]{WIDGET}   = Type of widget in that grid (if any).
# $self->{GRID}[$row][$column]{WINDOW}   = ID of canvas window object (if any).
# $self->{GRID}[$row][$column]{LABEL}    = Label of widget (what is inside the window)
# $self->{GRID}[$row][$column]{NAME}     = Name of widget (unique)
# $self->{GRID}[$row][$column]{LABFRAME} = frame widget where LABEL is
# $self->{GRID}[$row][$column]{ROWS}     = number of rows widget is occupying
# $self->{GRID}[$row][$column]{COLS}     = number of cols widget is occupying
# $self->{GRID}[$row][$column]{MASTER}   = label of widget in the top left grid
# $self->{GRID}[$row][$column]{PREVIEW}  = preview widget object
#
# $self->{LABEL2GRID}{$label}            = [row, col] of labels of widgets
#
# $self->{DRAG_OUTLINE}                  = ID of dummy rectangle when moving widgets.
#
# $self->{EXPAND_H}                      = ID of resize button
# $self->{EXPAND_V}                      = ID of resize button
# $self->{CONTRACT_H}                    = ID of resize button
# $self->{CONTRACT_V}                    = ID of resize button
#

1;
