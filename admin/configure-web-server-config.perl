#!/usr/bin/perl -w

my $itpenabled = 1;         # interactive translation prediction
my $srenabled = 1;          # search and replace
my $biconcorenabled = 0;    # biconcordancer
my $hidecontributions = 0;  # hide the TM suggestions
my $floatpredictions = 1;   # whether the ITP predictions should be displayed
                            # in a floating box rather than inserted directly
                            # into the textarea
my $translationoptions = 0; # translation options

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
    print MINE "itpserver = \"localhost:9999\"\n";
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

