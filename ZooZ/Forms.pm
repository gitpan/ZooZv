
package ZooZ::Forms;

# this implements all the forms in a "clean" way.
# unfortunately, it's not as clean as I'd like it to be!
# MUST RE-WRITE!!

use strict;
use Tk;
use Tk::LabFrame;
use Tk::ROText;
use Tk::DialogBox;
use Tk::Dialog;
use Tk::Font;
use Tk::Pane;

use ZooZ::Options;
use ZooZ::Fonts;

#
# vars
#

# the options to ignore. Those can't be (and shouldn't be)
# exposed to the user.
my %ignoreOptions = (
		     -class => 1,
		    );

# Just create one ZooZ::Fonts object.
our $fontObj;

my %Callbacks;

sub Callbacks {
  # this form let's users add/delete callbacks/subroutines.
  # as a side effect, it returns the name of the
  # selected callback so it can be used to assign
  # callbacks to -command arguments.
  my (
      $class,
      $mw,
      $cb,   # ZooZ::Callbacks object
     ) = @_;

  unless (exists $Callbacks{form}) {
    # create this only once
    my $t = $mw->Toplevel;
    $t->withdraw;
    $t->title('Subroutine Definitions');
    $t->protocol(WM_DELETE_WINDOW => sub {
		   $t->withdraw;
		   return undef;
		 });

    my $f1 = $t->Labelframe(
#			    -label     => 'Defined Subroutines',
#			    -labelside => 'acrosstop',
			    -text      => 'Defined Subroutines',
			   )->pack(qw/-side top -fill both -expand 1/);
    my $f2 = $t->Frame->pack(qw/-side bottom -fill x -padx 5 -pady 5/);

    my $l  = $f1->Scrolled(qw/Listbox -scrollbars se/,
			   -selectmode => 'single',
			   -width => 40,
			  )->pack(qw/-side left -fill y/);

    my $r  = $f1->Scrolled(qw/ROText -scrollbars se/,
			   -width  => 60,
			   #-height => 20,
			  )->pack(qw/-side left -fill both -expand 1/);

    $Callbacks{form} = $t;
    $Callbacks{text} = $r;
    $Callbacks{list} = $l;

    $l->bind('<1>' => sub {
	       my ($sel) = $l->curselection;
	       defined $sel or return;

	       $sel     = $l ->get($sel);
	       my $code = $cb->code($sel);
	       $Callbacks{text}->delete(qw/0.0 end/);
	       $Callbacks{text}->insert(end => $code);
	     });

    $f2->Button(-text    => 'Add Subroutine',
		-height  => 2,
		-command => sub {
		  my $name = $cb->newName;

		  unless (exists $Callbacks{newN}) {
		    my $d = $t->DialogBox(-buttons => [qw/Ok Cancel/],
					  -popover => $t);

		    my $f = $d->LabFrame(-label => 'Enter Unique Subroutine Name',
					 -labelside => 'acrosstop',
					)->pack(qw/-fill both -expand 1/);

		    $Callbacks{newN}   = $d;
		    $Callbacks{newN_e} = $f->Entry->pack;
		  }

		  my $e = $Callbacks{newN_e};

		  do {
		    $e->delete(qw/0.0 end/);
		    $e->insert(0.0 => $name);
		    $e->selectionRange(qw/0.0 end/);
		    $e->focus;

		    my $ans = $Callbacks{newN}->Show;
		    return if $ans eq 'Cancel';

		    $name = $e->get;
		  } while $cb->CallbackExists($name);

		  $cb->add($name, "sub $name {

}");

		  # add it to listbox.
		  #cbAddToListbox($cb, $name);
		  $Callbacks{list}->insert(end => $name);
		  $Callbacks{list}->selectionSet('end');

		  my $code = $cb->code($name);
		  $Callbacks{text}->delete(qw/0.0 end/);
		  $Callbacks{text}->insert(end => $code);
		})->pack(qw/-side left -fill x -expand 1/);

    $f2->Button(-text    => 'Delete Selected Sub',
		-height  => 2,
		-command => sub {
		  my ($sel) = $Callbacks{list}->curselection;
		  defined $sel or return;

		  my $nam = $Callbacks{list}->get($sel);
		  my $ans = $Callbacks{form}->Dialog
		    (-title   => 'Are you sure?',
		     -bitmap  => 'question',
		     -buttons => [qw/Yes No/],
		     -text    => <<EOT)->Show;
Are you sure you want to delete
callback '$nam' with its
associated code?
EOT
  ;
		  return if $ans eq 'No';
		  $cb->remove($nam);
		  $Callbacks{list}->delete($sel);
		  $Callbacks{text}->delete(qw/0.0 end/);
		})->pack(qw/-side left -fill x -expand 1/);

    $f2->Button(-text    => 'Rename Selected Sub',
		-height  => 2,
		-command => sub {
		  my ($sel) = $Callbacks{list}->curselection;
		  defined $sel or return;

		  my $name = $Callbacks{list}->get($sel);

		  unless (exists $Callbacks{rename}) {
		    my $d = $t->DialogBox(-buttons => [qw/Ok Cancel/],
					  -popover => $t);

		    my $f = $d->LabFrame(-label => 'Enter Unique Subroutine Name',
					 -labelside => 'acrosstop',
					)->pack(qw/-fill both -expand 1/);

		    $Callbacks{rename}   = $d;
		    $Callbacks{rename_e} = $f->Entry->pack;
		  }

		  my $e = $Callbacks{rename_e};

		  my $oldName = $name;
		  do {
		    $e->delete(qw/0.0 end/);
		    $e->insert(0.0 => $name);
		    $e->selectionRange(qw/0.0 end/);
		    $e->focus;

		    my $ans = $Callbacks{rename}->Show;
		    return if $ans eq 'Cancel';

		    $name = $e->get;
		  } while $cb->CallbackExists($name);

		  $cb->rename($oldName => $name);
		  $Callbacks{list}->delete($sel);
		  $Callbacks{list}->insert($sel => $name);

		  my $code = $cb->code($name);
		  $code =~ s/\b(sub\s+)$oldName\b/${1}$name/;
		  $cb->code($name, $code);
		})->pack(qw/-side left -fill x -expand 1/);

    $f2->Button(-text    => 'Edit Sub Code',
		-height  => 2,
		-command => sub {
		})->pack(qw/-side left -fill x -expand 1/);

    $f2->Button(-text    => 'Return Selected',
		-height  => 2,
		-command => sub {
		  my ($sel) = $Callbacks{list}->curselection;
		  $sel      = $Callbacks{list}->get($sel) if defined $sel;
		  $Callbacks{form}->withdraw;
		  return $sel;
		})->pack(qw/-side left -fill x -expand 1/);
  }

  my $l = $Callbacks{list};
  $l->delete(qw/0.0 end/);
  $l->insert(end => $_) for $cb->listAll;

  $Callbacks{form}->deiconify;
}

my %Fonts;

sub Fonts {
  # this form let's users add/delete fonts.
  # as a side effect, it returns the name of the
  # selected font so it can be used to assign
  # fonts.

  my (
      $class,
      $mw,
      $fn,   # ZooZ::Fonts object
      $return,
     ) = @_;

  # if we got a real Tk::Font object, convert it to a ZooZ::Font object.
  if (ref $fn eq 'Tk::Font') {
    my $tmp = $fn;
    $fn = new ZooZ::Fonts;

    my $name = $fn->newName;
    $fn->add($name, $tmp);
  }

  unless (exists $Fonts{form}) {
    my $t = $mw->Toplevel;
    #$t->withdraw;

    $t->title('Font Definitions');
    $t->protocol(WM_DELETE_WINDOW => sub {
		   $t->withdraw;
		   $t->grabRelease;

		   #return $$return = 'Default';
		   $Fonts{localReturn} = 'Default';
		 });

    my $f1 = $t->Frame->pack(qw/-side top -fill both -expand 1/);
    my $f2 = $t->LabFrame(-label     => 'Sample Font',
			  -labelside => 'acrosstop',
			  -height    => 200,
			 )->pack(qw/-side bottom -fill x/);

    my $f3 = $f1->LabFrame(-label => 'Defined Fonts',
			   -labelside => 'acrosstop',
			   )->pack(qw/-side left -fill both -expand 1/);
    my $l3 = $f3->Scrolled(qw/Listbox -scrollbars se/,
			   -exportselection => 0,
			   -selectmode      => 'browse',
			  )->pack(qw/-fill both -expand 1/);

    my $f4 = $f1->LabFrame(-label => 'Available Families',
			   -labelside => 'acrosstop',
			  )->pack(qw/-side left -fill both -expand 1/);
    my $l4 = $f4->Scrolled(qw/Listbox -scrollbars se/,
			   -exportselection => 0,
			   -selectmode      => 'browse',
			   -width => 30,
			  )->pack(qw/-fill both -expand 1/);

    my $F4 = $f1->Frame->pack(qw/-side left -fill y -expand 0/);
    my $f5 = $F4->LabFrame(-label     => 'Extra Options',
			   -labelside => 'acrosstop',
			  )->pack(qw/-side top -fill none -expand 0 -anchor n/);

    # populate family list.
    $l4->insert(end => $_) for sort $mw->fontFamilies;

    $F4->Button(-text => 'Register Font',
		-command => sub {
		  #my $name = $fn->newName;
		  my $name = "$Fonts{family} $Fonts{size} $Fonts{weight} $Fonts{slant} " .
		    ($Fonts{underline} ? 'u ' : '') . ($Fonts{overstrike} ? 'o': '');

		  unless (exists $Fonts{newN}) {
		    my $d = $t->DialogBox(-buttons => [qw/Ok Cancel/],
					  -popover => $t);

		    my $f = $d->LabFrame(-label => 'Enter Unique Font Name',
					 -labelside => 'acrosstop',
					)->pack(qw/-fill both -expand 1/);

		    $Fonts{newN}   = $d;
		    $Fonts{newN_e} = $f->Entry->pack;
		  }

		  my $e = $Fonts{newN_e};

		  do {
		    $e->delete(qw/0.0 end/);
		    $e->insert(0.0 => $name);
		    $e->selectionRange(qw/0.0 end/);
		    $e->focus;

		    my $ans = $Fonts{newN}->Show;
		    return if $ans eq 'Cancel';

		    $name = $e->get;
		  } while $fn->FontExists($name);

		  my $obj = $mw->fontCreate($name,
					    map {
					      '-' . $_ =>  $Fonts{$_}
					    } qw/family size weight slant underline overstrike/);
		  $fn->add($name, $obj);

		  $l3->insert(end => $name);
		})->pack(qw/-side top -padx 5 -pady 0 -fill x/);

    $F4->Button(-text => 'Delete Font',
		-command => sub {
		  my ($sel) = $Fonts{fontlist}->curselection;
		  defined $sel or return;

		  my $nam = $Fonts{fontlist}->get($sel);
		  my $ans = $Fonts{form}->Dialog
		    (-title   => 'Are you sure?',
		     -bitmap  => 'question',
		     -buttons => [qw/Yes No/],
		     -text    => <<EOT)->Show;
Are you sure you want to delete
font '$nam'?
EOT
  ;
		  return if $ans eq 'No';
		  $fn->remove($nam);
		  $Fonts{fontlist}->delete($sel);
		})->pack(qw/-side top -padx 5 -pady 0 -fill x/);

    $F4->Button(-text => 'Return Selected',
		-command => sub {
		  my ($sel) = $Fonts{fontlist}->curselection;
		  $sel      = $Fonts{fontlist}->get($sel) if defined $sel;
		  $sel    ||= 'Default';

		  $Fonts{form}->withdraw;
		  $Fonts{form}->grabRelease;

		  return $Fonts{localReturn} = $sel;
		})->pack(qw/-side top -padx 5 -pady 0 -fill x/);

    my $sample         = $f2->Label(-text => "There's More Than One Way To Do It",
				   )->pack(qw/-side top/);# -fill both -expand 1/);

    my $default        = $sample->cget('-font');
    if ($default =~ /\{(.+)\}\s+(\d+)/) {
      $Fonts{family}   = $1;
      $Fonts{size}     = $2;
    } else {
      $Fonts{family}   = '';
      $Fonts{size}     = 8;
    }

    $Fonts{weight}     = 'normal';
    $Fonts{slant}      = 'roman';
    $Fonts{underline}  = 0;
    $Fonts{overstrike} = 0;

    for my $i (0 .. $l4->size - 1) {
      next unless $l4->get($i) eq $Fonts{family};
      $l4->selectionSet($i);
      $l4->see($i);
    }

    $sample->configure(
		       -font => [$Fonts{family},
				 $Fonts{size},
				 $Fonts{weight},
				 $Fonts{slant},
				 $Fonts{underline}  ? 'underline'  : (),
				 $Fonts{overstrike} ? 'overstrike' : ()],
		      );

    $f5->Label(-text => 'Size',
	      )->grid(-column => 0, -row => 0, -sticky => 'w');
    $f5->Optionmenu(-options => [5 .. 25],
		    -textvariable => \$Fonts{size},
		    -command      => sub {
		      $sample->configure(
					 -font => [$Fonts{family},
						   $Fonts{size},
						   $Fonts{weight},
						   $Fonts{slant},
						   $Fonts{underline}  ? 'underline'  : (),
						   $Fonts{overstrike} ? 'overstrike' : ()],
					);
		    })->grid(-column => 1, -row => 0, -sticky => 'ew',
			   -columnspan => 2);

    $f5->Label(-text => 'Weight',
	      )->grid(-column => 0, -row => 1, -sticky => 'w');
    $f5->Radiobutton(-text => 'Normal',
		     -value => 'normal',
		     -variable => \$Fonts{weight},
		     -command  => sub {
		       $sample->configure(
					  -font => [$Fonts{family},
						    $Fonts{size},
						    $Fonts{weight},
						    $Fonts{slant},
						    $Fonts{underline}  ? 'underline'  : (),
						    $Fonts{overstrike} ? 'overstrike' : ()],
					 );
		     })->grid(-column => 1, -row => 1, -sticky => 'w');
    $f5->Radiobutton(-text => 'Bold',
		     -value => 'bold',
		     -variable => \$Fonts{weight},
		     -command  => sub {
		       $sample->configure(
					  -font => [$Fonts{family},
						    $Fonts{size},
						    $Fonts{weight},
						    $Fonts{slant},
						    $Fonts{underline}  ? 'underline'  : (),
						    $Fonts{overstrike} ? 'overstrike' : ()],
					 );
		     })->grid(-column => 2, -row => 1, -sticky => 'w');

    $f5->Label(-text => 'Slant',
	      )->grid(-column => 0, -row => 2, -sticky => 'w');
    $f5->Radiobutton(-text => 'Normal',
		     -value => 'roman',
		     -variable => \$Fonts{slant},
		     -command  => sub {
		       $sample->configure(
					  -font => [$Fonts{family},
						    $Fonts{size},
						    $Fonts{weight},
						    $Fonts{slant},
						    $Fonts{underline}  ? 'underline'  : (),
						    $Fonts{overstrike} ? 'overstrike' : ()],
					 );
		     })->grid(-column => 1, -row => 2, -sticky => 'w');
    $f5->Radiobutton(-text => 'Italic',
		     -value => 'italic',
		     -variable => \$Fonts{slant},
		     -command  => sub {
		       $sample->configure(
					  -font => [$Fonts{family},
						    $Fonts{size},
						    $Fonts{weight},
						    $Fonts{slant},
						    $Fonts{underline}  ? 'underline'  : (),
						    $Fonts{overstrike} ? 'overstrike' : ()],
					 );
		     })->grid(-column => 2, -row => 2, -sticky => 'w');

    $f5->Label(-text => 'Underline',
	      )->grid(-column => 0, -row => 3, -sticky => 'w');
    $f5->Checkbutton(-text => 'Yes/No',
		     -variable => \$Fonts{underline},
		     -command  => sub {
		       $sample->configure(
					  -font => [$Fonts{family},
						    $Fonts{size},
						    $Fonts{weight},
						    $Fonts{slant},
						    $Fonts{underline}  ? 'underline'  : (),
						    $Fonts{overstrike} ? 'overstrike' : ()],
					 );
		     })->grid(-column => 1, -row => 3, -sticky => 'ew',
			   -columnspan => 2);

    $f5->Label(-text => 'Overstrike',
	      )->grid(-column => 0, -row => 4, -sticky => 'w');
    $f5->Checkbutton(-text => 'Yes/No',
		     -variable => \$Fonts{overstrike},
		     -command  => sub {
		       $sample->configure(
					  -font => [$Fonts{family},
						    $Fonts{size},
						    $Fonts{weight},
						    $Fonts{slant},
						    $Fonts{underline}  ? 'underline'  : (),
						    $Fonts{overstrike} ? 'overstrike' : ()],
					 );
		     })->grid(-column => 1, -row => 4, -sticky => 'ew',
			      -columnspan => 2);

    $l3->bind('<1>' => sub {
		my ($sel) = $l3->curselection;
		defined $sel or return;

		$sel    = $l3->get($sel);
		my $obj = $fn->obj($sel);

		for my $o (qw/family size weight slant underline overstrike/) {
		  $Fonts{$o} = $obj->configure("-$o");
		}

		$sample->configure(-font => $obj);

		for my $i (0 .. $l4->size - 1) {
		  next unless $l4->get($i) eq $Fonts{family};
		  $l4->selectionClear(qw/0.0 end/);
		  $l4->selectionSet($i);
		  $l4->see($i);
		}
	      });

    $l4->bind('<1>' => sub {
		my ($sel) = $l4->curselection;
		defined $sel or return;

		$l3->selectionClear(qw/0.0 end/);
		$Fonts{family} = $l4->get($sel);
		$sample->configure(
				   -font => [$Fonts{family},
					     $Fonts{size},
					     $Fonts{weight},
					     $Fonts{slant},
					     $Fonts{underline}  ? 'underline'  : (),
					     $Fonts{overstrike} ? 'overstrike' : ()],
				  );
	      });

    $Fonts{form}       = $t;
    $Fonts{fontlist}   = $l3;
    $Fonts{familylist} = $l4;
  }

  my $l = $Fonts{fontlist};
  $l->delete(qw/0.0 end/);
  $l->insert(end => $_) for $fn->listAll;

  $Fonts{form}->deiconify;
  $Fonts{form}->grab;
  $Fonts{form}->raise;
  $Fonts{form}->waitVariable(\$Fonts{localReturn});

  $$return = $Fonts{localReturn};
}

my %projectData;

sub projectData {
  my ($class, $mw,
      $name, # optional .. to end
      $title,
      $rows,
      $cols,
     ) = @_;

  unless (exists $projectData{form}) {
    my $top = $mw->Toplevel;
    $top->withdraw;
    $top->title('Project Settings');
    $top->protocol(WM_DELETE_WINDOW => sub {
		   $top->withdraw;
		   return undef;
		 });

    $top->optionAdd('*Button.BorderWidth' => 1);
    $top->optionAdd('*Entry.BorderWidth'  => 1);

    my $t = $top->Frame->pack(qw/-fill both -expand 1
			      -ipadx 10 -ipady 10/);

    $t->gridColumnconfigure(0, -minsize => 50);
    $t->Label(-text => 'Name',
	     )->grid(-column => 0,
		     -row    => 0,
		     -sticky => 'w');
    $t->Entry(-textvariable  => \$projectData{name},
	     )->grid(-column => 1,
		     -row    => 0,
		     -columnspan => 4,
		     -sticky => 'ew');
    $t->Label(-text => 'Title',
	     )->grid(-column => 0,
		     -row    => 1,
		     -sticky => 'w');
    $t->Entry(-textvariable  => \$projectData{title},
	     )->grid(-column => 1,
		     -row    => 1,
		     -columnspan => 4,
		     -sticky => 'ew');

    $t->Label(-text => 'Rows',
	     )->grid(-column => 0,
		     -row    => 2,
		     -sticky => 'w');
    $t->Entry(-textvariable    => \$projectData{rows},
	      -justify         => 'right',
	      -validate        => 'key',
	      -validatecommand => sub {
		return 1 unless $_[4] == 1;
		return 0 unless $_[1] =~ /^\d$/;
		return 1;
	      })->grid(-column => 1,
		       -row    => 2,
		       -columnspan => 4,
		       -sticky => 'e');
    $t->Label(-text => 'Columns',
	     )->grid(-column => 0,
		     -row    => 3,
		     -sticky => 'w');
    $t->Entry(-textvariable    => \$projectData{cols},
	      -justify         => 'right',
	      -validate        => 'key',
	      -validatecommand => sub {
		return 1 unless $_[4] == 1;
		return 0 unless $_[1] =~ /^\d$/;
		return 1;
	      })->grid(-column => 1,
		       -row    => 3,
		       -columnspan => 4,
		       -sticky => 'e');

    $t->gridColumnconfigure(0, -pad => 10);

    my $f = $top->Frame(-relief => 'ridge',
			-borderwidth => 2,
		       )->pack(qw/-side bottom -fill both
                               -padx 5 -pady 5/);

    $projectData{okbutton} =
      $f->Button(-text    => 'Ok',
		 -command => sub {
		   $projectData{wait} = 1;
		 })->pack(qw/-side left -fill both -expand 1/);

    $f->Button(-text    => 'Cancel',
	       -command => sub {
		 $projectData{wait} = 0;
	       })->pack(qw/-side left -fill x -expand 1/);

    $projectData{form} = $top;
  }

  $projectData{name}   = $name   ? $name   : "Project " . ++$projectData{index};
  $projectData{title}  = $title  ? $title  : $projectData{name};
  $projectData{rows}   = $rows || 3;
  $projectData{cols}   = $cols || 3;
  $projectData{wait}   = undef;

  centerOnParent($projectData{form}, $mw);
  $projectData{okbutton}->focus;
  $projectData{form}->grab;
  $projectData{form}->waitVariable(\$projectData{wait});
  $projectData{form}->grabRelease;
  $projectData{form}->withdraw;

  return undef unless $projectData{wait};
  return map $projectData{$_}, qw/name title rows cols/;
}

sub centerOnParent {
  my ($form, $mw) = @_;

  my $x = int 0.5 * ($mw->width  - $form->width);
  my $y = int 0.5 * ($mw->height - $form->height);

  my $g = $mw->geometry;
  my ($cx, $cy) = $g =~ /\+(\S+)\+(\S+)/;

  $x += $cx;
  $y += $cy;

  $form->geometry("+$x+$y");
  $form->deiconify;
  $form->raise;
}

my $widgetForm;
my $widgetName;
my $widgetNB;
my $widgetNBwidget;
my $widgetNBplacement;
my %widgetConf;

sub widgetConf {
  my ($class, $mw, $projid,
      $name, $widget, $force,
     ) = @_;

  unless ($widgetForm) {
    my $top = $mw->Toplevel;
    $top->withdraw;
    $top->title("Configure Widget - $name");
    $top->protocol(WM_DELETE_WINDOW => sub {
		     $top->withdraw;
		     return undef;
		   });
    #$top->resizable(0, 1);

    $widgetForm = $top;
    $widgetName = $top->Label(-font => [helvetica => 12],
			      -fg   => 'darkolivegreen',
			      -bg   => 'white',
			      -borderwidth => 1,
			      -relief      => 'ridge',
			      -pady       => 5,
			     )->pack(qw/-fill x -padx 5 -pady 5/);

    # create the notebook.
    $widgetNB          = $widgetForm->NoteBook(
					       -borderwidth => 1,
					      )->pack(qw/-fill both -expand 1/);
    $widgetNBplacement = $widgetNB->add('PLACE',  -label => 'Placement Specific');
    $widgetNBwidget    = $widgetNB->add('WIDGET', -label => 'Widget Specific');

    # make things a bit nicer
    for ($widgetNBplacement, $widgetNBwidget) {
      $_->optionAdd('*Entry.BorderWidth'  => 1);
      $_->optionAdd('*Button.BorderWidth' => 1);
    }

    # bind for mouse wheel.
    ZooZ::Generic::BindMouseWheel($widgetForm, sub {
				    my $r = $widgetNB->raised;
				    my $s = $r eq 'PLACE' ? $widgetNBplacement : $widgetNBwidget;
				    ($s->packSlaves)[0];
				  });
  }

  unless (exists $widgetConf{$projid}{$name}{forms}) {
    # should create one frame per widget per project.

    # frame for widget options.
    my $f = $widgetNBwidget->Scrolled('Pane',
				      -sticky     => 'nw',
				      -scrollbars => 'e',
				      -gridded => 'xy');

    # frame for placement options.
    my $g = $widgetNBplacement->Scrolled('Pane',
					 -sticky     => 'nsew',
					 -scrollbars => 'e',
					);

    # configure the scrollbar's appearance.
    $_->Subwidget('yscrollbar')->configure(-borderwidth => 1) for $f, $g;

    $widgetConf{$projid}{$name}{forms} = [$f, $g];

    # populate the widget options frame
    {
      #my @conf = grep @$_ > 2 && !ref($_->[-1]), $widget->configure;
      my @conf = grep @$_ > 2, $widget->configure;
      my $row = 0;
      for my $c (@conf) {
	my $option = $c->[0];

	next if exists $ignoreOptions{$option};

	my @extra;   # additional options to be passed to ZooZ::Options::addOptionGrid

	if ($option eq '-font') {
	  unless ($fontObj) {
	    $fontObj = new ZooZ::Fonts;

	    # create the default object.
	    my $font = $mw->fontCreate('Default',
				       map {$_ => $c->[-1]->actual($_)}
				       qw/-family -size -weight -slant -underline -overstrike/,
				      );

	    $widget ->configure(-font => 'Default');
	    $fontObj->add(Default => $font);
	  }

	  @extra = ($fontObj);
	} else {
	  @extra = ();
	}

	my $label = ZooZ::Options->addOptionGrid($option, $option, $f, $row,
						 \$widgetConf{$projid}{$name}{widget}{$option},
						 @extra,
						);

	#print "Tying $projid.$name.widget.option to $widget ...\n";
	tie $widgetConf{$projid}{$name}{widget}{$option},
	  'ZooZ::TiedVar', $widget, 'configure', $option, $label;

	$row++;
      }
    }

    # populate the placement options frame.
    {
      my $f1 = $g->Labelframe(-text => "Stick to Which Container's Edge",
			     )->pack(qw/-side top -fill both -expand 0/);
      my $f2 = $g->Labelframe(-text => "Internal Padding",
			     )->pack(qw/-side top -fill both -expand 0/);
      my $f3 = $g->Labelframe(-text => "External Padding",
			     )->pack(qw/-side top -fill both -expand 0/);

      for my $ref ([qw/North n/],
		   [qw/South s/],
		   [qw/East  e/],
		   [qw/West  w/]
		  ) {
	$widgetConf{$projid}{$name}{place}{$ref->[1]} = '';

	$f1->Checkbutton(-text     => $ref->[0],
			 -onvalue  => $ref->[1],
			 -offvalue => '',
			 -borderwidth => 1,
			 -variable => \$widgetConf{$projid}{$name}{place}{$ref->[1]},
			 -command  => [sub {
#					 print
					   $widgetConf{$projid}{$name}{place}{-sticky} =
					     join '' => @{$widgetConf{$projid}{$name}{place}}{qw/n s e w/};
				       }],
			)->pack(qw/-side top -anchor w/);
      }

      tie $widgetConf{$projid}{$name}{place}{-sticky},
	'ZooZ::TiedVar', $widget, 'grid', '-sticky';

      my $row = 0;
      for my $ref (['Horizontal', '-ipadx'],
		   ['Vertical', '-ipady'],
		  ) {

	my $label = ZooZ::Options->addOptionGrid
	  ($ref->[1], $ref->[0], $f2, $row,
	   \$widgetConf{$projid}{$name}{place}{$ref->[1]},
	  );

	tie $widgetConf{$projid}{$name}{place}{$ref->[1]},
	  'ZooZ::TiedVar', $widget, 'grid', $ref->[1], $label;

	$row++;
      }

      $row = 0;
      for my $ref (['Horizontal', '-padx'],
		   ['Vertical', '-pady'],
		  ) {

	my $label = ZooZ::Options->addOptionGrid
	  ($ref->[1], $ref->[0], $f3, $row,
	   \$widgetConf{$projid}{$name}{place}{$ref->[1]},
	  );

	tie $widgetConf{$projid}{$name}{place}{$ref->[1]},
	  'ZooZ::TiedVar', $widget, 'grid', $ref->[1], $label;

	$row++;
      }
    }
  }

  #return if !$force && $widgetForm->state ne 'normal';
  $widgetName->configure(-text => "Configuring $name");

  # let's update the variables with the current values.
  my @conf = grep @$_ > 2 && !exists $ignoreOptions{$_->[0]}, $widget->configure;
  $widgetConf{$projid}{$name}{widget}{$_->[0]} = $_->[4] for @conf;

  # display the correct frames in the notebook.
  my $ref = $widgetConf{$projid}{$name}{forms};
  $_->packForget for map $_->packSlaves, $widgetNBplacement, $widgetNBwidget;

  $_->pack(qw/-fill both -expand 1/) for @$ref;

  return unless $force;

  # pop-up the window.
  $widgetForm->title("Configure Widget - Project $projid - $name");
  $widgetForm->deiconify;
  $widgetForm->waitVisibility;
  $widgetForm->geometry($widgetForm->reqwidth . 'x500');
  $widgetForm->raise;
}

# form to configure the row or column.
# supplies options for minsize/weight/padding
my $rowColConfForm;
my $rowColConfTitle;
my %rowColConf;

sub rowColConf {
  my ($class, $mw, $projid, $hier, $widget,
      $rowORcol, $index,
     ) = @_;

  unless ($rowColConfForm) {
    my $top = $mw->Toplevel;
    $top->withdraw;
    #$top->title("Configure Widget - $name");
    $top->protocol(WM_DELETE_WINDOW => sub {
		     $top->withdraw;
		     return undef;
		   });
    $top->resizable(0, 1);

    $rowColConfForm = $top;

    $rowColConfTitle =
      $top->Label(-font => [helvetica => 12],
		  -fg   => 'darkolivegreen',
		  -bg   => 'white',
		  -borderwidth => 1,
		  -relief      => 'ridge',
		  -pady       => 5,
		 );
#		  )->pack(qw/-fill both -expand 1/);
#		  )->grid(-row        => 0,
#			  -column     => 0,
#			  -columnspan => 2,
#			  -sticky     => 'ew',
#			 )
  }

  unless (exists $rowColConf{$projid}{$hier}{$rowORcol}[$index]) {
    my $f = $rowColConfForm->Frame;

    # populate it.
    my $row = 1;
    for my $ref (
		 ['Extra Space Greediness', '-weight'],
		 ['Minimum Size',           '-minsize'],
		 ['Extra Padding',          '-pad'],
		) {

      my $dummy;
      my $label = ZooZ::Options->addOptionGrid($ref->[1],
					       $ref->[0],
					       $f,
					       $row,
					       \$dummy,
					      );

      tie $dummy, 'ZooZ::TiedVar', $widget,
	($rowORcol eq 'row' ? 'gridRowconfigure' :
	 'gridColumnconfigure'),
	   $ref->[1], $label, [$index];
      $row++;
    }

    $rowColConf{$projid}{$hier}{$rowORcol}[$index] = $f;
  }

  $_->packForget for $rowColConfForm->packSlaves;
  $rowColConfTitle->pack(qw/-fill both -expand 1/);
  $rowColConf{$projid}{$hier}{$rowORcol}[$index]->pack(qw/-fill both -expand 1/);

  $rowColConfForm ->title("Configure \u$rowORcol $index - Project $projid");
  $rowColConfTitle->configure(-text => "Configuring \u$rowORcol $index");

  $rowColConfForm->deiconify;
  $rowColConfForm->raise;
}

1;
