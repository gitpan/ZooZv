#!perl -w

use strict;
use lib '/home/aqumsieh/Tk804.025_beta15/lib/site_perl/5.8.3/i686-linux';
use lib '/home/aqumsieh/Perl/myLib';
use Tk 804.025;
use Tk qw/:colors/;
use Tk::NoteBook;
use Tk::Adjuster;
use Tk::ToolBar;
use Tk::Tree;
use Tk::Compound;
use Tk::ItemStyle;

use ZooZ::Options;
use ZooZ::Fonts;
use ZooZ::Forms;
use ZooZ::Callbacks;
use ZooZ::Project;
use ZooZ::Generic;

#
# Global vars
#

our (
     $MW,
     $VERSION,

     # MainWindow frames
     $FRAME_L,
     $FRAME_M,
     $FRAME_R,

     # toolbar
     $TB,

     # Project notebook
     $NB,

     # per project Tree widget.
     $HIER_F,
     @TREES,

     # Widget frame
     $WIDGET_F,

     # Project data
     $PROJID,
     $CURID,
     @PROJECTS, # holds the objects.

     # icons
     %ICONS,
     $SELECTED_W, # selected widget
     $SELECTED_L, # dummy label
    );


#
# temp vars
#
our %availableWidgets = (
			 butLab   => [qw/Label Image Button Radiobutton Checkbutton/],
			 text     => [qw/Entry Text ROText/],
			 menuList => [qw/Listbox Optionmenu/],
			 datadisp => [qw/Canvas Scale ProgressBar HList NoteBook/],
			 dialog   => [qw/Dialogbox Toplevel/],
			 misc     => [qw/Scrollbar Labelframe Frame Adjuster/],
			);


#
# Inits
#
$VERSION = '0.9a';
$PROJID  = 0;

#
# create stuff
#

createGUI     ();
createToolBar ();
defineSettings();
loadIcons     ();
loadBitmaps   ();
defineFonts   ();
defineWidgets ();
defineStyles  ();

MainLoop;

sub createGUI {
  $MW = new MainWindow;
  $MW->title("ZooZ v$VERSION");
  $MW->geometry("800x600+0+0");

  $FRAME_L = $MW->Frame->pack(qw/-side left -fill y/);
  $MW->Adjuster(-widget => $FRAME_L, -side => 'left')->pack(qw/-side left -fill y/);
  $FRAME_M = $MW->Frame->pack(qw/-side left -fill both -expand 1/);
  $FRAME_R = $MW->Frame->pack(qw/-side right -fill y/);

  $NB = $FRAME_M->NoteBook(qw/-borderwidth 1/)->pack(qw/-fill both -expand 1/);
  $NB->add(qw/settings -label Settings/);

  $WIDGET_F = $FRAME_L->Labelframe(
				   -text => 'Available Widgets',
				  )->pack(qw/-side top -fill both -expand 1/);

  $SELECTED_L = $MW->Label(-textvariable => \$SELECTED_W,
			   #-cursor       => ['@trans_cur.xbm', 'trans_cur.msk', 'black', 'white'],
			   -bg           => 'cornflowerblue',
			   -relief       => 'raised',
			   -borderwidth  => 1,
			  );

}

sub defineSettings {
  # this sub populates the Setting tab.
}

sub defineWidgets {
  my @frames;
  my $firstBut;

  my $dum;

  for my $o ([butLab   => 'Labels and Buttons'],
	     [text     => 'Text Related'],
	     [menuList => 'Menus and Lists'],
	     [datadisp => 'Data Presentation'],
	     [dialog   => 'Dialogs'],
	     [misc     => 'Miscellaneous'],
	    ) {

    my $b;

    my $dnd;

    my $f = $WIDGET_F->Scrolled(qw/HList -scrollbars oe -bg white -columns 2/,
				-font        => 'WidgetName', #[qw/helvetica 10/],
				-borderwidth => 1,
				-browsecmd   => \&selectWidgetToAdd,
			       );
				#-browsecmd => sub {
#				  $SELECTED_W = shift;
#				  print "Selected $SELECTED_W.\n";
#				  $dnd->configure(-text        => $SELECTED_W,
#						  -relief      => 'raised',
#						  (exists $ICONS{lc $SELECTED_W} ?
#						   (-image => $ICONS{lc $SELECTED_W}) :
#						   (-image => '')),
#						  -borderwidth => 1);
#				});

    $b    = $WIDGET_F->Radiobutton(-text        => $o->[1],
				   -indicatoron => 0,
				   -variable    => \$dum,
				   -value       => $o->[0],
                                   -height      => 2,
                                   -borderwidth => 1,
				   -command     => sub {
				     $_->packForget for @frames;
				     $f->pack(-before => $b, qw/-side top -fill both -expand 1/);
				   })->pack(qw/-fill x -side top/);

    push @frames => $f;

    for my $w (@{$availableWidgets{$o->[0]}}) {
      my $image = lc $w;
      $f->add($w);
      $f->itemCreate($w, 0, -itemtype => 'imagetext',
		     (exists $ICONS{$image} ? (-image => $ICONS{$image}) : (-bitmap => 'error')),
		    );
      $f->itemCreate($w, 1, -text => uc $w);
    }
    $firstBut ||= $b;

  }

  $firstBut->invoke;
}

sub createToolBar {
  # create the ToolBar
  $TB = $MW->ToolBar(qw/-movable 0 -side top -cursorcontrol 0/);
  $TB->Button(-image   => 'filenew22',
	      -tip     => 'New Project',
	      -command => \&newProject,
	     );
  $TB->Button(-image   => 'fileclose22',
	      -tip     => 'Close Project',
	      -command => \&closeProject,
	     );
  $TB->separator;
  $TB->Button(-image   => 'filesave22',
	      -tip     => 'Save Project',
	      -command => \&saveProject);
  $TB->Button(-image   => 'fileopen22',
	      -tip     => 'Load Project',
	      -command => \&loadProject);
  $TB->separator;
  $TB->Button(-image   => 'viewmag22',
	      -tip     => 'Hide/Unhide Preview Window',
	      -command => sub {
		my $raised = $NB->raised;
		$raised =~ s/PROJ// or return;
		$PROJECTS[$raised]->togglePreview;
	      });
  $TB->Button(-image   => 'apptool22',
	      -tip     => 'Configure Selected Widget',
	      -command => sub {
		my $raised = $NB->raised;
		$raised =~ s/PROJ// or return;
		$PROJECTS[$raised]->configureSelectedWidget(1);
	      });
  $TB->Button(-image   => 'actcross16',
	      -tip     => 'Delete Selected Widget',
	      -command => sub {
		my $raised = $NB->raised;
		$raised =~ s/PROJ// or return;
		#$PROJECTS[$raised]->_deleteWidget('selected', 1);
		$PROJECTS[$raised]->deleteSelectedWidget;
	      });
  $TB->Button(-image   => 'viewmulticolumn22',
	      -tip     => 'Configure Selected Row',
	      -command => sub {
		my $raised = $NB->raised;
		$raised =~ s/PROJ// or return;
		$PROJECTS[$raised]->_configureRowCol('row', 'selected');
	      });
  $TB->Button(-image   => 'viewicon22',
	      -tip     => 'Configure Selected Column',
	      -command => sub {
		my $raised = $NB->raised;
		$raised =~ s/PROJ// or return;
		$PROJECTS[$raised]->_configureRowCol('col', 'selected');
	      });
}

sub newProject {
  $PROJID++;
  my $name = "Project $PROJID";

  my ($title, $rows, $cols);

  # pop up the form.
  ($name, $title, $rows, $cols) = ZooZ::Forms->projectData($MW, $name);
  unless ($name) {
    $PROJID--;
    return;
  }

  # create the notebook page to house it.
  my $page = $NB->add("PROJ$PROJID",
		      -label    => $name,
		      -raisecmd => \&focusIt);

  $PROJECTS[$PROJID] = new ZooZ::Project
    (
     -id     => $PROJID,
     -parent => $page,
     -name   => $name,
     -title  => $title,
#     -rows   => $rows,
#     -cols   => $cols,
#     -selref => \$SELECTED_W,
     -icons  => \%ICONS,
    );

  $NB->raise("PROJ$PROJID");
  focusIt();
}

sub closeProject {

}

sub saveProject {

}

sub loadProject {

}

# invoked when user selects a project tab.
# must make sure everything displayed is relevant
# to selected project.
sub focusIt {
  # unmap the old project
  #$PROJECTS[$CURID]->unmap if $CURID;
  #$PROJECTS[$CURID]->disableDrops if $CURID;

  my $raised = $NB->raised;
  $raised =~ s/PROJ//;

  $_->packForget for @TREES;
  #$TREES[$raised]->pack(qw/-fill both -expand 1/);

  $CURID = $raised;

  # map the new project
  #$PROJECTS[$CURID]->remap;
  #$PROJECTS[$CURID]->enableDrops;
}

sub loadIcons {
  for my $file (<ZooZ/icons/*gif>) {  # should this use Tk->findINC ??
    my ($name) = $file =~ m|.*/(.+)\.gif|;
    $ICONS{$name} = $MW->Photo("$name-zooz", -format => 'gif', -file => $file);
    #print "Size of $name = ", $ICONS{$name}->width, " by ", $ICONS{$name}->height, ".\n";
  }
}

sub loadBitmaps {
  my $downbits = pack("b10" x 5,
		      "11......11",
		      ".11....11.",
		      "..11..11..",
		      "...1111...",
		      "....11....",
		     );

  $MW->DefineBitmap('down_size', 10, 5, $downbits);

  my $upbits = pack("b10" x 5,
		    "....11....",
		    "...1111...",
		    "..11..11..",
		    ".11....11.",
		    "11......11",
		   );

  $MW->DefineBitmap('up_size', 10, 5, $upbits);

  # define the h bitmap.
  my $rightbits = pack("b5" x 10,
		       "1....",
		       "11...",
		       ".11..",
		       "..11.",
		       "...11",
		       "...11",
		       "..11.",
		       ".11..",
		       "11...",
		       "1....",
		      );

  $MW->DefineBitmap('right_size', 5, 10, $rightbits);

  my $leftbits = pack("b5" x 10,
		       "....1",
		       "...11",
		       "..11.",
		       ".11..",
		       "11...",
		       "11...",
		       ".11..",
		       "..11.",
		       "...11",
		       "....1",
		      );

  $MW->DefineBitmap('left_size', 5, 10, $leftbits);

  my $rightArrow = pack("b10" x 5,
			"......11..",
			".......11.",
			"1111111111",
			".......11.",
			"......11..",
		       );

  my $leftArrow = pack("b10" x 5,
		       "..11......",
		       ".11.......",
		       "1111111111",
		       ".11.......",
		       "..11......",
		      );

  my $upArrow = pack("b5" x 10,
		     "..1..",
		     ".111.",
		     "11111",
		     "1.1.1",
		     "..1..",
		     "..1..",
		     "..1..",
		     "..1..",
		     "..1..",
		     "..1..",
		    );

  my $downArrow = pack("b5" x 10,
		       "..1..",
		       "..1..",
		       "..1..",
		       "..1..",
		       "..1..",
		       "..1..",
		       "1.1.1",
		       "11111",
		       ".111.",
		       "..1..",
		      );

  my $box = pack("b5" x 5,
		 ".....",
		 ".111.",
		 ".111.",
		 ".111.",
		 ".....",
		);

  $MW->DefineBitmap('rightArrow', 10,  5, $rightArrow);
  $MW->DefineBitmap('leftArrow',  10,  5, $leftArrow );
  $MW->DefineBitmap('upArrow',     5, 10, $upArrow   );
  $MW->DefineBitmap('downArrow',   5, 10, $downArrow );
  $MW->DefineBitmap('box',         5,  5, $box       );
}

sub defineFonts {
  $MW->fontCreate('Row/Col Num',
		  -family => 'Nimbus',
		  -size   => 10,
		  -weight => 'bold',
		 );

  $MW->fontCreate('WidgetName',
		  -family => 'helvetica',
		  -size   => 9,
		 );
}

sub selectWidgetToAdd {
  return unless $PROJID;

  $SELECTED_W = shift;

  $SELECTED_L->configure(exists $ICONS{lc $SELECTED_W} ?
			 (-image => $ICONS{lc $SELECTED_W}) :
			 (-image => ''));

  my $w = $SELECTED_L->reqwidth  / 2;
  my $h = $SELECTED_L->reqheight / 2;

  my ($x, $y) = $MW->pointerxy;
  $x -= $MW->rootx;
  $y -= $MW->rooty;

  $SELECTED_L->place(-x => $x - $w,
		     -y => $y - $h);

  # set the bindings.

  # when the mouse moves, update the dummy label.
  $MW->bind('<Motion>' => sub {
	      my ($x, $y) = $MW->pointerxy;
	      $x -= $MW->rootx;
	      $y -= $MW->rooty;

	      $SELECTED_L->place(-x => $x - $w,
				 -y => $y - $h);
	    });

  # clicking somewhere does something.
  $MW->bind('<1>' => sub {
	      #$PROJECTS[$CURID]->dropWidget or return;
	      $PROJECTS[$CURID]->dropWidgetInCurrentObject or return;

	      endDrag();
	    });

  # pressing escape cancels.
  $MW->bind('<Escape>'    => \&endDrag);
  $MW->bind('<<EndDrag>>' => \&endDrag);
}

sub endDrag {
  $SELECTED_L->placeForget;
  $MW->bind($_ => '') for qw/<Escape> <Motion> <1>/;
}

sub defineStyles {
  $MW->ItemStyle(imagetext  =>
		 -stylename => 'container',
		 -fg        => 'red',
		 -selectforeground => 'red',
		);
}
