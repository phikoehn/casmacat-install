#!/usr/bin/perl -w

use Digest::MD5 qw(md5_hex);

use strict;

my ($f,$e,$xliff,$name) = @ARGV;
$name = "unnamed" unless defined($name) && $name !~ /^\s*$/;

# create checksum
open(XLIFF, "<", $xliff);
my $checksum = md5_hex(<XLIFF>);
close(XLIFF);

# directory for this language pair
my $outdir = "/opt/casmacat/data/$f-$e";
if (! -d $outdir) {
  `mkdir -p $outdir`;
}
elsif (`grep 'checksum = $checksum' $outdir/*.info`) {
  # if already uploaded, done
  exit;
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
print INFO "upload_time = ".time()."\n";
print INFO "name = $name\n";
print INFO "checksum = $checksum\n";
close(INFO);

