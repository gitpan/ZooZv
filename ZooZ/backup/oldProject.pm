package ZooZ::Project;

use strict;
use ZooZ::DefaultArgs;
use Tk;
use Tk::LabFrame;

my $cellWidth   = 50;
my $cellHeight  = 30;
my $handleSize  = 5;
my $handleColor = 'red';
my $resizeTh    = 10; # resize threshold
my $selColor    = 'orange';
my $bgColor     = 'dimgray';

sub new {
  my ($class,
      $id,
      $page,
      $tree,
      $name,
      $title,
      $rows,
      $cols,
      $select_ref,
      $icons,
     ) = @_;

  my $self = bless {
		    ID     => $id,
		    PAGE   => $page,
		    TREE   => $tree,
		    NAME   => $name,
		    TITLE  => $title,
		    ROWS   => $rows || 3,
		    COLS   => $cols || 3,
		    SELREF => $select_ref,
		    ICONS  => $icons,
		    IDS    => {},
		    PREV   => undef,   # preview window ref.
		   } => $class;

  my $f = $page->Frame(-relief      => 'sunken',
		       -borderwidth => 2,
		       -bg          => $bgColor,
		       )->pack(qw/-fill both -expand 1/);

  $self->{FRAME} = $f->Frame(#-relief      => 'ridge',
			     #-borderwidth => 2,
			     -bg          => $bgColor,
			     )->pack(qw/-expand 0 -anchor w -padx 20 -pady 20/);

  # create the cells.
  for my $r (0 .. $self->{ROWS} - 1) {
    for my $c (0 .. $self->{COLS} - 1) {
      $self->_addCell($r, $c);
    }
  }

  # create the resize handles.
  $self->_createResizeHandle;

  # create the popup menus.
  $self->_createPopupMenu;

  # create the preview window.
  $self->_createPreview;

  $self->_updatePreview;

  return $self;
}

sub newWithin {
  my ($class,
      $id,
      $page,
      $tree,
      $name,
      $title,
      $rows,
      $cols,
      $select_ref,
      $icons,
     ) = @_;

  $class = ref($class) || $class;

  my $self = bless {
		    ID     => $id,
		    PAGE   => $page,
		    TREE   => $tree,
		    NAME   => $name,
		    TITLE  => $title,
		    ROWS   => $rows || 3,
		    COLS   => $cols || 3,
		    SELREF => $select_ref,
		    ICONS  => $icons,
		    IDS    => {},
		    PREV   => undef,   # preview window ref.
		   } => $class;

#  my $f = $page->Frame(-relief      => 'sunken',
#		       -borderwidth => 2,
#		       -bg          => $bgColor,
#		      )->pack(qw/-fill both -expand 1/);

  $self->{FRAME} = $self->{PAGE}->Frame(#-relief      => 'ridge',
					#			     #-borderwidth => 2,
					-bg          => $bgColor,
				       )->pack(qw/-expand 0 -anchor w -padx 20 -pady 20/);

#  $self->{FRAME} = $self->{PAGE};

  # create the cells.
  for my $r (0 .. $self->{ROWS} - 1) {
    for my $c (0 .. $self->{COLS} - 1) {
      $self->_addCell($r, $c);
    }
  }

  # create the resize handles.
  $self->_createResizeHandle;

  # create the popup menus.
  $self->_createPopupMenu;

  # create the preview window.
  #$self->_createPreview;

  #$self->_updatePreview;

  return $self;
}

sub _createPreview {
  my $self = shift;

  my $t = $self->{PAGE}->Toplevel;
  $t->protocol(WM_DELETE_WINDOW => [$t, 'withdraw']);

  $self->{PREV} = $t;
}

# adds a new cell in the specified row/column
sub _addCell {
  my ($self, $row, $col) = @_;

  my $f = $self->{CELL}[$row][$col] = $self->{FRAME}->Frame(
							    -width  => $cellWidth,
							    -height => $cellHeight,
							    -relief => 'ridge',
							    -borderwidth => 1,
							    -bg          => 'white',
							    )->grid(-column => $col,
								    -row    => $row,
								    -sticky => 'nsew',
								    );
  $self->{USED}[$row][$col] = 0;

  # create DND site.
#   my $dnd;
#   $dnd = $self->{CELL}[$row][$col]->DragDrop(
# 					     -event        => '<B1-Motion>',
# 					     -sitetypes    => [qw/Local/],
# 					     -startcommand => sub {
# 					       # is there anything to drag?
# 					       return if $self->isCellEmpty($row, $col);

# 					       my $name = $self->{USED}[$row][$col][1];
# 					       $dnd->configure(-text => $name);
# 					     });

  $f->DropSite(
	       -droptypes   => [qw/Local/],
	       -dropcommand => [$self, 'dropWidget', $f],
	      );

  $f->bind('<3>' => sub {
	     #$self->{MENUPOSTAT} = [$row, $col];
	     $self->{MENUPOSTAT} = [@{$self->{L_FRAMES}{$f}}];
	     $self->{POPUP_M}->Post($f->pointerxy);
	   });

  $self->{L_FRAMES}{$f} = [$row, $col];
  #$f->bind('<1>' => [$self, '_selectCell', $f]);
}

# deletes cell in the specified row/column.
sub _deleteCell {
  my ($self, $row, $col) = @_;

  my $f = $self->{CELL}[$row][$col];
  delete $self->{L_FRAMES}{$f};

  $f->destroy;
  # hmm .. do I need to clear up more data structures?
}

sub _selectCell {
  my ($self, $f) = @_;

  # unhilighted currently selected cell.
  if (my $cur = $self->{SELECTED}) {
    $cur->configure(-bg => Tk::NORMAL_BG);
  }

  # hilight the cell.
  #my $f = $self->{CELL}[$r][$c];
  $f->configure(-bg => $selColor);

  $self->{SELECTED} = $f;
}

# creates the little blob used to resize the grid.
sub _createResizeHandle {
  my $self = shift;
  my $f    = $self->{FRAME};

  my ($cols, $rows) = $f->gridSize;

  # stick it in the bottom right
  my $h = $self->{HANDLE} = $f->Frame(-width  => $handleSize,
				      -height => $handleSize,
				      -bg     => $handleColor,
				      -cursor => 'bottom_right_corner',
				     )->grid(-row    => $rows,
					     -column => $cols,
					    );

  # now .. let's bind it.
  my ($x, $y);

  $h->bind('<1>' => sub {
	     ($x, $y) = $h->pointerxy;
	   });

  $h->bind('<B1-Motion>' => sub {
	     my %info = $h->gridInfo;
	     my ($r, $c) = ($info{-row}, $info{-column});

	     # if we moved more than $resizeTh in a direction,
	     # then consider adding/removing cells.
	     # can only remove a row/column at a time, and only
	     # if all entries are empty.

	     my ($cx, $cy) = $h->pointerxy;
	     my $dx = $cx - $x;
	     my $dy = $cy - $y;

	     if ($dx > 0 && $dx > $cellWidth) {
	       # going right.
	       # just add another column.

	       my ($cols, $rows) = $f->gridSize;

	       # create the new cells.
	       $self->_addCell($_, $cols - 1) for 0 .. $rows - 2;

	       # shift the handle.
	       $h->grid(-column => $cols);

	       $x = $cx;
	     } elsif ($dx < 0 && $dx < -$cellWidth) {
	       # going left.
	       # make sure all the right-most column entries are empty.
	       my ($cols, $rows) = $f->gridSize;

	       return if $cols == 2;

	       my $empty = 1;
	       $empty &= $self->isCellEmpty($_, $cols - 2) for 0 .. $rows - 2;

	       return unless $empty;

	       # delete the cells.
	       $self->_deleteCell($_, $cols - 2) for 0 .. $rows - 2;

	       # adjust the handle.
	       $h->grid(-column => $cols - 2);

	       $x = $cx;
	     }

	     if ($dy > 0 && $dy > $cellHeight) {
	       # going down.
	       # just add another row.

	       my ($cols, $rows) = $f->gridSize;

	       # create the new cells.
	       $self->_addCell($rows - 1, $_) for 0 .. $cols - 2;

	       # shift the handle.
	       $h->grid(-row => $rows);

	       $y = $cy;
	     } elsif ($dy < 0 && $dy < -$cellHeight) {
	       # going up.
	       # make sure all the bottom-most row entries are empty.
	       my ($cols, $rows) = $f->gridSize;

	       return if $rows == 2;

	       my $empty = 1;
	       $empty &= $self->isCellEmpty($rows - 2, $_) for 0 .. $cols - 2;

	       return unless $empty;

	       # delete the cells.
	       $self->_deleteCell($rows - 2, $_) for 0 .. $cols - 2;

	       # adjust the handle.
	       $h->grid(-row => $rows - 2);

	       $y = $cy;
	     }
	   });
}

sub isCellEmpty {
  my ($self, $row, $col) = @_;

  return !$self->{USED}[$row][$col];
}

# handles dropping widgets. Calls addWidget() to actually add the widget.
sub dropWidget {
  #my ($self, $row, $col) = @_;
  my ($self, $f)  = @_;

  my ($row, $col) = @{$self->{L_FRAMES}{$f}};

  # if cell is not empty, then don't do anything.
  return unless $self->isCellEmpty($row, $col);

  $self->addWidget(${$self->{SELREF}}, $row, $col);
}

# adds a widget of a specified type in the specified location.
sub addWidget {
  my ($self, $w, $row, $col) = @_;

  # get parent frame to place object into.
  my $f  = $self->{CELL}[$row][$col];

  # create a new object, and place it there.
  # if it's a labframe, then instantiate a REAL labframe.
  my $id   = ++$self->{IDS}{$w};
  my $name = $w . $id;
  my $im   = lc $w;

  my $l1;
  my $lf;
  if ($w eq 'LabFrame') {
    $lf = $f->LabFrame(-label => $name,
		       -labelside => 'acrosstop',
		      )->pack(qw/-side top -fill both/);
  } else {
    $l1 = $f->Label((exists $self->{ICONS}{$im} ? (-image => $self->{ICONS}{$im}) : (-bitmap => 'error')),
		   )->pack(qw/-side top -fill both/);
  }

  my $l2 = $f->Label(-text => $name)->pack(qw/-side top -fill both/);

  $self->{USED}[$row][$col]   = [$w, $name];    # cross ref
  $self->{WIDGETS}{$w}{$name} = [$row, $col];   # cross ref

  # bind the labels for posting the menu.
  for my $l ($l2, $l1) {
    defined $l or next;
    $l->bind('<3>' => sub {
	       #$self->{MENUPOSTAT} = [$row, $col];
	       $self->{MENUPOSTAT} = [@{$self->{L_FRAMES}{$f}}];
	       $self->{POPUP_M}->Post($self->{CELL}[$row][$col]->pointerxy);
	     });

    #$l->bind('<1>'               => [$self, '_selectCell', $f]);
    $l->bind('<Double-Button-1>' => [$self, '_configureWidget', $f]);
  }

  # if labframe, create a new project within this one.
  if ($lf) {
    $self->newWithin(
		     $id,
		     $lf,
		     $self->{TREE},
		     $name,
		     '',
		     3,
		     3,
		     $self->{SELREF},
		     $self->{ICONS},
		    );
  }

  # update the preview.
  $self->_updatePreview;
}

sub _createPopupMenu {
  my $self = shift;

  my $m = $self->{PAGE}->Menu(-tearoff     => 0,
			      -postcommand => [$self, '_postMenu']);

  $m->add('command',
	  -label   => 'Add Row Above',
	  -command => [\&_addRow, $self, 0],
	 );

  $m->add('command',
	  -label   => 'Add Row Below',
	  -command => [\&_addRow, $self, 1],
	 );

  $m->add('command',
	  -label   => 'Add Column Left',
	  -command => [\&_addCol, $self, 0],
	 );

  $m->add('command',
	  -label   => 'Add Column Right',
	  -command => [\&_addCol, $self, 1],
	 );

  $m->add('separator');

  $m->add('command',
	  -label   => 'Collapse Row',
	  -command => [\&_collapseRow, $self],
	 );

  $m->add('command',
	  -label   => 'Collapse Column',
	  -command => [\&_collapseCol, $self],,
	 );

# need to add menu items to expand cell into neighbouring cell.
#  $m->separator;

#  $m->add('command',
#	  -label   => '',
#	  -command => [],
#	 );

  $self->{POPUP_M} = $m;
  $self->{POPUP_L} = $m->index('end');
}

sub _postMenu {
  my $self = shift;

  my $m = $self->{POPUP_M};

  # remove any non-fixed entries.
  if ($m->index('end') > $self->{POPUP_L}) {
    $m->delete($self->{POPUP_L} + 1, 'end');
  }

  # add any entries depending on where we clicked.
  my ($r, $c) = @{$self->{MENUPOSTAT}};
  return if $self->isCellEmpty($r, $c);

  my $n = $self->{USED}[$r][$c][1];

  $m->separator;
  $m->add(command  =>
	  -label   => "Delete $n",
	  -command => [\&_clearCell, $self, $r, $c]);
}

# deletes the widget inside the specified cell.
sub _clearCell {
  my ($self, $r, $c) = @_;

  # destroy the widget. Keep the frame.
  my $f = $self->{CELL}[$r][$c];
  $_->destroy for $f->children;

  # resize the frame to original size.
  $f->configure(-width  => $cellWidth,
		-height => $cellHeight);

  # clear up the data structures.
  my ($w, $n) = @{$self->{USED}[$r][$c]};
  delete $self->{WIDGETS}{$w}{$n};
  $self->{USED}[$r][$c] = 0;

  # indicate to preview window that we want to destroy
  # this widget.
  $self->{DESTROY}{$n} = 1;
  #$self->_previewDestroyWidget($n)

  # update preview win.
  $self->_updatePreview;
}

# this adds a row above/below selection.
sub _addRow {
  my ($self, $side) = @_;

  my ($row, $col)   = @{$self->{MENUPOSTAT}};
  my $f             = $self->{FRAME};
  my ($cols, $rows) = $f->gridSize;

  if ($side == 0) { # above
    for my $r (reverse $row .. $rows - 2) {
      $_->grid(-row => $r + 1) for $f->gridSlaves(-row => $r);
      # must update data structures. TBD.

      for my $c (0 .. $cols - 2) {
	my $f = $self->{CELL}[$r + 1][$c] = $self->{CELL}[$r][$c];
	my $u = $self->{USED}[$r + 1][$c] = $self->{USED}[$r][$c];
	$self->{L_FRAMES}{$f} = [$r + 1, $c];

	if ($u) {
	  my ($w, $n) = @$u;
	  $self->{WIDGETS}{$w}{$n} = [$r + 1, $c];
	}
      }
    }

    # adjust the handle.
    $self->{HANDLE}->grid(-row => $rows);

    # create the new cells
    $self->_addCell($row, $_) for 0 .. $cols - 2;

  } else          { # below
    for my $r (reverse $row + 1 .. $rows - 2) {
      # shift everything down.
      $_->grid(-row => $r + 1) for $f->gridSlaves(-row => $r);

      # update data structures.
      for my $c (0 .. $cols - 2) {
	my $f = $self->{CELL}[$r + 1][$c] = $self->{CELL}[$r][$c];
	my $u = $self->{USED}[$r + 1][$c] = $self->{USED}[$r][$c];

	$self->{L_FRAMES}{$f} = [$r + 1, $c];

	if ($u) {
	  my ($w, $n) = @$u;
	  $self->{WIDGETS}{$w}{$n} = [$r + 1, $c];
	}
      }
    }

    # adjust the handle.
    $self->{HANDLE}->grid(-row => $rows);

    # create the new cells
    $self->_addCell($row + 1, $_) for 0 .. $cols - 2;
  }
}

# this adds a row to left/right of selection.
# code dup.
sub _addCol {
  my ($self, $side) = @_;

  my ($row, $col)   = @{$self->{MENUPOSTAT}};
  my $f             = $self->{FRAME};
  my ($cols, $rows) = $f->gridSize;

  if ($side == 0) { # left
    for my $c (reverse $col .. $cols - 2) {
      $_->grid(-column => $c + 1) for $f->gridSlaves(-column => $c);

      for my $r (0 .. $rows - 2) {
	my $f = $self->{CELL}[$r][$c + 1] = $self->{CELL}[$r][$c];
	my $u = $self->{USED}[$r][$c + 1] = $self->{USED}[$r][$c];

	$self->{L_FRAMES}{$f} = [$r, $c + 1];

	if ($u) {
	  my ($w, $n) = @$u;
	  $self->{WIDGETS}{$w}{$n} = [$r, $c + 1];
	}
      }
    }

    # adjust the handle.
    $self->{HANDLE}->grid(-column => $cols);

    # create the new cells
    $self->_addCell($_, $col) for 0 .. $rows - 2;

  } else          { # right
    for my $c (reverse $col + 1 .. $cols - 2) {
      # shift everything right.
      $_->grid(-column => $c + 1) for $f->gridSlaves(-column => $c);

      # update data structures.
      for my $r (0 .. $rows - 2) {
	my $f = $self->{CELL}[$r][$c + 1] = $self->{CELL}[$r][$c];
	my $u = $self->{USED}[$r][$c + 1] = $self->{USED}[$r][$c];

	$self->{L_FRAMES}{$f} = [$r, $c + 1];

	if ($u) {
	  my ($w, $n) = @$u;
	  $self->{WIDGETS}{$w}{$n} = [$r, $c + 1];
	}
      }
    }

    # adjust the handle.
    $self->{HANDLE}->grid(-column => $cols);

    # create the new cells
    $self->_addCell($_, $col + 1) for 0 .. $rows - 2;
  }
}

# this collapses a row, only if it's empty.
sub _collapseRow {
  my $self = shift;

  my ($row, $col)   = @{$self->{MENUPOSTAT}};
  my $f             = $self->{FRAME};
  my ($cols, $rows) = $f->gridSize;

  # make sure the whole row is empty.
  my $empty = 1;
  $empty &= $self->isCellEmpty($row, $_) for 0 .. $cols - 2;
  $empty or return;

  # delete the extra cells.
  $self->_deleteCell($row, $_) for 0 .. $cols - 2;

  for my $r ($row + 1 .. $rows - 2) {
    # shift everything up.
    $_->grid(-row => $r - 1) for $f->gridSlaves(-row => $r);

    # update data structures.
    for my $c (0 .. $cols - 2) {
      my $f = $self->{CELL}[$r - 1][$c] = $self->{CELL}[$r][$c];
      my $u = $self->{USED}[$r - 1][$c] = $self->{USED}[$r][$c];

      $self->{L_FRAMES}{$f} = [$r - 1, $c];

      if ($u) {
	my ($w, $n) = @$u;
	$self->{WIDGETS}{$w}{$n} = [$r - 1, $c];
      }
    }
  }

  # adjust the handle.
  $self->{HANDLE}->grid(-row => $rows - 2);
}

# this collapses a col, only if it's empty.
sub _collapseCol {
  my $self = shift;

  my ($row, $col)   = @{$self->{MENUPOSTAT}};
  my $f             = $self->{FRAME};
  my ($cols, $rows) = $f->gridSize;

  # make sure the whole col is empty.
  my $empty = 1;
  $empty &= $self->isCellEmpty($_, $col) for 0 .. $rows - 2;
  $empty or return;

  # delete the extra cells.
  $self->_deleteCell($_, $col) for 0 .. $rows - 2;

  for my $c ($col + 1 .. $cols - 2) {
    # shift everything left.
    $_->grid(-column => $c - 1) for $f->gridSlaves(-column => $c);

    # update data structures.
    for my $r (0 .. $rows - 2) {
      my $f = $self->{CELL}[$r][$c - 1] = $self->{CELL}[$r][$c];
      my $u = $self->{USED}[$r][$c - 1] = $self->{USED}[$r][$c];

      $self->{L_FRAMES}{$f} = [$r, $c - 1];

      if ($u) {
	my ($w, $n) = @$u;
	$self->{WIDGETS}{$w}{$n} = [$r, $c - 1];
      }
    }
  }

  # adjust the handle.
  $self->{HANDLE}->grid(-column => $cols - 2);
}

# this updates the preview window with the latest widgets.
# will be called after every single tiny modification.
# hopefully it won't be too slow.
sub _updatePreview {
  my $self = shift;

  my $t;
  if ($self->{PREV}) {
    $t = $self->{PREV};

    # first the title.
    $t->title("Preview - $self->{TITLE}");
  } else {
    $t = $self->{FRAME};
  }

  # now the widgets.
  # first, check for any widgets that need to be destroyed
  for my $name (keys %{$self->{DESTROY}}) {
    my $o = delete $self->{CREATED}{$name};
    $o->destroy;
  }
  $self->{DESTROY} = {};

  # now create/configure existing widgets.
  my $ref = $self->{WIDGETS};
  for my $type (keys %$ref) {
    for my $name (keys %{$ref->{$type}}) {
      my ($r, $c) = @{$ref->{$type}{$name}};
      # if widget already created, just update it.
      # else, create it first and then grid it.

      unless (exists $self->{CREATED}{$name}) {
	# some widgets need to be handled specially.
	# - check for Image object: defaults to some image.

	my $a = ZooZ::DefaultArgs->getDefaults($type, $name);

	if ($type eq 'Image') {
	  $type = 'Label'; # switch to label.
	}

	my $o = $t->$type(%$a);

	$self->{CREATED}{$name} = $o;
      }

      my $o = $self->{CREATED}{$name};
      $o->grid(-column => $c,
	       -row    => $r);  # other options?
    }
  }
}

# hide/unhide the preview window.
sub togglePreview {
  my $self = shift;

  if ($self->{PREV}->ismapped) {
    $self->{PREV}->withdraw;
  } else {
    $self->{PREV}->deiconify;
  }
}

# this calls the proper sub in ZooZ::Forms
sub _configureWidget {
  my ($self, $f) = @_;

  my ($r, $c)       = @{$self->{L_FRAMES}{$f}};
  my ($type, $name) = @{$self->{USED}[$r][$c]};
  my $widget        =   $self->{CREATED}{$name};

  #print "Reconfiguring $widget ($name).\n";
  ZooZ::Forms->widgetConf($self->{PAGE},
			  $self->{ID},
			  #$self->{NAME},
			  $name,
			  $widget,
			 );
}

1;
