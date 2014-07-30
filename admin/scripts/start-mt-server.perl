#!/usr/bin/perl -w

use strict;

# get system name
my $system = `cat /opt/casmacat/engines/deployed`;
chop($system);

# link biconcordancer
# ... delete old
`rm /opt/casmacat/engines/biconcor*` if -e "/opt/casmacat/engines/biconcor";

# ... check if there is one
`echo 'ls /opt/casmacat/engines/$system/biconcor*' > /opt/casmacat/engines/debug`;
open(LS,"ls /opt/casmacat/engines/$system/biconcor*|");
my $stem = <LS>;
close(LS);

# ... set links
if (defined($stem)) {
  chop($stem);
  `ln -s $stem /opt/casmacat/engines/biconcor`;
  `ln -s $stem.tgt /opt/casmacat/engines/biconcor.tgt`;
  `ln -s $stem.align /opt/casmacat/engines/biconcor.align`;
  `ln -s $stem.src-vcb /opt/casmacat/engines/biconcor.src-vcb`;
  `ln -s $stem.tgt-vcb /opt/casmacat/engines/biconcor.tgt-vcb`;
}

# run start script of engine
my $cmd = "/opt/casmacat/engines/$system/RUN";
`$cmd &`;
