
package ZooZ::Options;

use strict;
use Tk;
use Tk::BrowseEntry;
use ZooZ::Forms;
use ZooZ::TiedVar;

#use Tk::chooseColor;

# I need to get the height of an optionmenu widget.
# this will be the height we configure the rows to be at.
our $maxHeight;

# this package defines all the options and their possible values.

our %options = ( # generics
		-activebackground   => ['Color'],
		-activeborderWidth  => ['Integer', 'positive'],
		-activeforeground   => ['Color'],
		-activeimage        => ['Image'],
		-activetile         => ['Image'],
		-anchor             => ['List', qw/n s e w ne se sw nw center/],
		-background         => ['Color'],
		-bitmap             => ['Image'],
		-borderwidth        => ['Integer', 'positive'],
		-command            => ['Callback'],
		-cursor             => ['Image'],
		#-dash              => [],
		-disabledforeground => ['Color'],
		-disabledtile       => ['Image'],
		-exportselection    => ['Boolean'],
		-font               => ['Font'],
		-foreground         => ['Color'],
		-height             => [qw/Integer positive/],
		-highlightbackground => ['Color'],
		-highlightcolor     => ['Color'],
		-highlightthickness => ['Integer', 'positive'],
		-image              => ['Image'],
		-insertbackground   => ['Color'],
		-insertborderwidth  => [qw/Integer positive/],
		-insertofftime      => [qw/Integer positive/],
		-insertontime       => [qw/Integer positive/],
		-insertwidth        => [qw/Integer positive/],
		-ipadx              => [qw/Integer positive/],
		-ipady              => [qw/Integer positive/],
		-jump               => ['Boolean'],
		-justify            => [qw/List left right center/],
		-minsize            => [qw/Integer positive/],  # for gridConfigure
		-offset             => [qw/List n s e w ne se sw nw center/],
		-orient             => [qw/List horizontal vertical/],
		-pad                => [qw/Integer positive/],  # for gridConfigure
		-padx               => [qw/Integer positive/],
		-pady               => [qw/Integer positive/],
		-relief             => [qw/List raised sunken flat ridge solid groove/],
		-repeatdelay        => [qw/Integer positive/],
		-repeatinterval     => [qw/Integer positive/],
		-selectbackground   => ['Color'],
		-selectborderwidth  => [qw/Integer positive/],
		-selectforeground   => ['Color'],
		-setgrid            => ['Boolean'],
		-state              => [qw/List normal disabled/],
		-takefocus          => ['Boolean'],
		-text               => ['String'],
		-textvariable       => ['VarRef'],
		-tile               => ['Image'],
		-troughColor        => ['Color'],
		-troughtile         => ['Image'],
		-underline          => [qw/Integer positive/],
		-weight             => [qw/Integer positive/],  # for gridConfigure
		-width              => [qw/Integer positive/],
		-wraplength         => [qw/Integer positive/],
		-xscrollcommand     => ['Callback'],
		-yscrollcommand     => ['Callback'],
	       );


###############
#
# Generic functions
#
###############

# args to this are:
# 1. option name.
# 2. option text to use in the label.
# 3. frame to add stuff to.
# 4. row to add stuff to.
# 5. var ref to save result to.
# 6. additional args that depend on type of option.
#    for -font, $args[0] is a ZooZ::Fonts object.

sub addOptionGrid {
  my ($class, $option, $optionLabel, $frame, $row, $ref, @args) = @_;

  unless (exists $options{$option}) {
    # hmmm .. should change this to some default. Just an entry.
    #print "ERROR: option '$option' is unknown!\n";
    return undef;
  }

  unless ($maxHeight) { # this feels like a hack.
    my $om     = $frame->Optionmenu;
    $maxHeight = $om->reqheight;
    $om->destroy;
  }

  my @list = @{$options{$option}};
  my $type = shift @list;

  my $label = $frame->Label(-text          => $optionLabel,
			    #-relief        => 'groove',
			    #-borderwidth   => 1,
			    -anchor        => 'w',
			    #-bg            => 'white',
			   )->grid(-column => 0,
				   -row    => $row,
				   -sticky => 'ewns',
				  );

  my $entry;

  if ($type eq 'Color') {
    $entry = $frame->Entry(-textvariable => $ref,
			  )->grid(-column => 1,
				  -row    => $row,
				  -sticky => 'ew',
				 );
    my $b;
    $b = $frame->Button(
			-bitmap  => 'transparent',
			-fg      => Tk::NORMAL_BG,
			-command => [\&_chooseColor, $frame, $ref, \$b],
			-height  => 9,
			-width   => 9,
		       )->grid(-column => 2,
			       -row    => $row,
			       -padx   => 1,
			       -sticky => 'ew',
			 );

  } elsif ($type eq 'Image') {

  } elsif ($type eq 'List') {
    my $e = $frame->BrowseEntry(
				-choices  => [@list],
				-state    => 'readonly',
				-variable => $ref,
				-disabledforeground => 'black',
				#-bg => 'red',
		       )->grid(-column     => 1,
			       -row        => $row,
			       -columnspan => 2,
			       -sticky     => 'ew',
			      );

  } elsif ($type eq 'Integer') {
    my $pos = shift @list || 0;
    my $rgx = $pos ? qr/^\d$/ : qr/^(?:-|\d|\.)$/;

    $frame->Entry(
		  -textvariable      => $ref,
		  -validate        => 'key',
		  -validatecommand => sub {
		    return 1 unless $_[4] == 1;
		    return 0 unless $_[1] =~ /$rgx/;
		    return 1;
		  },
		 )->grid(-column     => 1,
			 -row        => $row,
			 -columnspan => 2,
			 -sticky     => 'ew',
			);

  } elsif ($type eq 'String') {
    $entry = $frame->Entry(
			   -textvariable      => $ref,
			  )->grid(-column     => 1,
				  -row        => $row,
				  -columnspan => 2,
				  -sticky     => 'ew',
				 );

  } elsif ($type eq 'Boolean') {
    $frame->Checkbutton(-text     => 'On/Off',
			-variable => $ref,
			-anchor   => 'w',
		       )->grid(-column     => 1,
			       -row        => $row,
			       -columnspan => 2,
			       -sticky     => 'ew',
			      );

  } elsif ($type eq 'Font') {
    $$ref ||= 'Default';
    my $b;
    $b = $frame->Button(#-textvariable => $ref,  # this causes a core dump at app exit!
			-text         => 'Select Font',
			-font         => $$ref,
			-command      => sub {
			  ZooZ::Forms->Fonts($frame, $args[0], $ref);

			  $$ref or return $$ref = 'Default';

			  $b->configure(-font => $$ref);
			})->grid(-column     => 1,
				 -row        => $row,
				 -columnspan => 2,
				 -sticky     => 'ew',
				);

  } elsif ($type eq 'Callback') {
    # TBD
  } elsif ($type eq 'VarRef') {
    # TBD
  }

  # configure the row to make it look nice.
  $frame->gridRowconfigure($row, -minsize => $maxHeight, -weight => 2);

  return $label;
}

sub _chooseColor {
  my ($f, $ref, $b) = @_;

  my $color = $f->chooseColor;
  $color or return;

  $$ref = $color;
  $$b->configure(-bg => $color);
}

{
  my $form;

  sub _chooseCB {
    my ($f) = @_;

    unless ($form) {
      my $t = $form = $f->Toplevel;
      $t->withdraw;
      $t->title('Choose Callback');
      $t->protocol(WM_DELETE_WINDOW => sub {
		     $t->withdraw;
		     return undef;
		   });

      $t->LabFrame();
    }
    $form->deiconify;
  }
}

1;

