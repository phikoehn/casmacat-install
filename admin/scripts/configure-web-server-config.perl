#!/usr/bin/perl -w

use strict;
use Getopt::Long "GetOptions";

my $itpenabled = 1;         # interactive translation prediction
my $srenabled = 1;          # search and replace
my $biconcorenabled = 0;    # biconcordancer
my $hidecontributions = 1;  # hide the TM suggestions
my $floatpredictions = 1;   # whether the ITP predictions should be displayed
                            # in a floating box rather than inserted directly
                            # into the textarea
my $translationoptions = 0; # translation options

my $HELP;
$HELP = 1
    unless &GetOptions('itpenabled=i' => \$itpenabled,
                       'srenabled=i' => \$srenabled,
                       'biconcorenabled=i' => \$biconcorenabled,
                       'hidecontributions=i' => \$hidecontributions,
                       'floatpredictions=i' => \$floatpredictions,
                       'translationoptions=i' => \$translationoptions);

open(TEMPLATE,"/opt/casmacat/web-server/inc/config.ini.sample");
open(MINE,">/opt/casmacat/web-server/inc/config.ini");
while(<TEMPLATE>) {
  if (/^\[db\]/) {
    print MINE $_;
    print MINE "hostname = \"127.0.0.1\"\n";
    print MINE "username = \"katze\"\n";
    print MINE "password = \"miau\"\n";
    print MINE "database = \"matecat_sandbox\"\n\n";
    while(<TEMPLATE>) {
      if (/^\[/) {
        print MINE $_;
        last;
      }
    }
  }
  elsif(/^itpserver/) {
    my $inet_string = `/sbin/ifconfig | grep 'inet addr' | grep -v 127.0.0.1`;
    my $host = "localhost";
    $host = $1 if $inet_string =~ /inet addr:(\d+\.\d+\.\d+\.\d+)/;
    print MINE "itpserver = \"http://$host:9999/cat\"\n";
  }
  elsif(/^itpenabled/) {
    print MINE "itpenabled = $itpenabled\n";
  }
  elsif(/^etenabled/) {
    print MINE "etenabled = 0\n";
  }
  elsif(/^srenabled/) {
    print MINE "srenabled = $srenabled\n";
  }
  elsif(/^biconcorenabled/) {
    print MINE "biconcorenabled = $biconcorenabled\n";
  }
  elsif(/^hidecontributions/) {
    print MINE "hidecontributions = $hidecontributions\n";
  }
  elsif(/^floatpredictions/) {
    print MINE "floatpredictions = $floatpredictions\n";
  }
  elsif(/^translationoptions/) {
    print MINE "translationoptions = $translationoptions\n";
  }
  else {
    print MINE $_;
  }
}
close(MINE);

