
package ZooZ::DefaultArgs;

use strict;

our %defaultWidgetArgs = (
			  'Image' => sub {
			    return {-image => 'image-zooz'};
			  },
			  'Label' => sub {
			    my $n = shift;
			    return {-text => $n};
			  },
			  'Button' => sub {
			    my $n = shift;
			    return {-text => $n};
			  },
			  'Checkbutton' => sub {
			    my $n = shift;
			    return {-text => $n};
			  },
			  'Radiobutton' => sub {
			    my $n = shift;
			    return {-text => $n};
			  },
			  'Labelframe' => sub {
			    my $n = shift;
			    return {-text     => $n };
			  },
			  'LabFrame' => sub {
			    my $n = shift;
			    return {-text     => $n };
			  },
			 );

sub getDefaults {
  my ($class, $w, $n) = @_;

  return exists $defaultWidgetArgs{$w} ?
    $defaultWidgetArgs{$w}->($n) : {};
}
