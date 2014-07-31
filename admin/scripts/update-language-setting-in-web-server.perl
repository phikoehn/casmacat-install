#!/usr/bin/perl -w

use strict;

# get language info
my ($source,$target) = ("","");;
my $engine = `cat /opt/casmacat/engines/deployed`;
chop($engine);
open(ENGINE_INFO,"/opt/casmacat/engines/$engine/info");
while(<ENGINE_INFO>) {
  $source = $1 if /^source *\= *(\S+)/;
  $target = $1 if /^target *\= *(\S+)/;
}
close(ENGINE_INFO);

my @OLD = `cat /opt/casmacat/web-server/inc/config.ini`;

open(MINE,">/opt/casmacat/web-server/inc/config.ini");
foreach (@OLD) {
  if(/^sourcelanguage/) {
    print MINE "sourcelanguage = \"$source\"\n";
  }
  elsif(/^targetlanguage/) {
    print MINE "targetlanguage = \"$target\"\n";
  }
  else {
    print MINE $_;
  }
}
close(MINE);

