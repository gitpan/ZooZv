#!perl -w

use strict;
use Tk;
use Tk::LabFrame;
use Tk::DropSite;

my $mw = new MainWindow;

my $parent = $mw->LabFrame(-labelside => 'acrosstop',
			   -label     => 'Parent',
			   -height    => 400,
			   -width     => 200,
			   )->pack;

#$parent->packPropagate(0);

my $child = $parent->LabFrame(-labelside => 'acrosstop',
			  -label     => 'Child',
			  -height    => 200,
			  -width     => 180,
			      )->pack(qw/-padx 50 -pady 50/);#place(qw/-x 0 -y 0/);
#$child->Tk::raise;

#for my $f ($parent, $child) {
#    print "Dropsite for $f.\n";
#    $f->DropSite(-dropcommand => [sub { print "Dropping in >>$_[0]<<\n" }, $f],
#		 -droptypes =>($^O eq 'MSWin32' ? 'Win32' : ['KDE', 'XDND', 'Sun'])
#		 );
#}

$parent->DropSite(-dropcommand => [sub { print "Dropping in >>Parent<<\n" }],
	     -droptypes =>($^O eq 'MSWin32' ? 'Win32' : ['KDE', 'XDND', 'Sun'])
	     );
$child->DropSite(-dropcommand => [sub { print "Dropping in >>Child<<\n" }],
		 -droptypes =>($^O eq 'MSWin32' ? 'Win32' : ['KDE', 'XDND', 'Sun'])
		 );
MainLoop;
