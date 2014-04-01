#!/usr/bin/perl -w

use strict;

my $system = `cat /opt/casmacat/engines/deployed`;
chop($system);
my $cmd = "/opt/casmacat/engines/$system/RUN";
#print $cmd;
`$cmd &`;
