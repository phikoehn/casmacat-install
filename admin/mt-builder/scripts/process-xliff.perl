#!/usr/bin/perl -w

use strict;

my ($f,$e,$xliff,$name) = @ARGV;

# directory for this language pair
my $outdir = "/opt/casmacat/data/$f-$e";
if (! -d $outdir) {
  `mkdir -p $outdir`;
}

# stem for this corpus
my $max = 0;
open(LS,"ls $outdir|");
while(<LS>) {
  if (/(\d+)\./) {
    $max = ($1 > $max) ? $1 : $max;
  }
}
close(LS);
my $stem = $outdir."/".($max+1);

open(XLIFF,$xliff);
my ($source,$target);
my $line_count = 0;
open(E,">$stem.$e");
open(F,">$stem.$f");
while(<XLIFF>) {
   if (/^<source>(.+)<\/source>$/) {
     $source = $1;
   }
   if (/^<target>(.+)<\/target>$/) {
     $target = $1;
   }
   if (/<\/trans-unit>/) { 
     if (defined($source) && defined($target)) {
       print F $source."\n";
       print E $target."\n";
       $line_count++;
     }
   }
}
close(E);
close(F);

open(INFO,">$stem.info");
print INFO "lines = $line_count\n";
print INFO "upload_time = ".`date`;
print INFO "name = $name\n";
close(INFO);

