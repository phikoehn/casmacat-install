#!/usr/bin/perl -w

use strict;
use Getopt::Long "GetOptions";
use Digest::MD5 qw(md5_hex);

my ($f,$e,$tmp_file,$name,$url);
die unless &GetOptions('f=s' => \$f,
                       'e=s' => \$e,
                       'tmp=s' => \$tmp_file,
                       'name=s' => \$name,
                       'url=s' => \$url);

$name = "unnamed" unless defined($name) && $name !~ /^\s*$/;

if (defined($url)) {
  $tmp_file = "/tmp/process.$$.gz";
  `wget -O $tmp_file $url`;
}

# create checksum
open(XLIFF, "<", $tmp_file);
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

# process the file

if (defined($url) || $tmp_file =~ /gz$/) {
  open(XLIFF,"zcat $tmp_file|");
}
else {
  open(XLIFF,$tmp_file);
}
my ($source,$target) = ("","");
my $line_count = 0;
my $next;
my $SOURCE = \$source;
my $TARGET = \$target;
open(E,">$stem.$e");
open(F,">$stem.$f");
while(<XLIFF>) {
   if (/<file.*source-language=\"(..)/) {
     if ($1 eq $e) {
       $SOURCE = \$target;
       $TARGET = \$source;
     }
     else {
       $SOURCE = \$source;
       $TARGET = \$target;
     }
   }
   if (/<source[^\>]*>(.+)<\/source>/i) { # XLIFF
     $$SOURCE = $1;
   }
   elsif (/<tuv xml:lang="$f[^\"]*"><seg>(.+)<\/seg><\/tuv>/i) { # TMX
     $$SOURCE = $1;
   }
   elsif (/<tuv xml:lang="$f[^\"]*">\s*$/i) {
     my $next = <XLIFF>;
     if ($next =~ /<seg>(.+)<\/seg>/) {
       $$SOURCE = $1;
     }
   }
   elsif (/<target[^\>]*>(.+)<\/target>/i) { # XLIFF
     $$TARGET = $1;
   }
   elsif (/<tuv xml:lang="$e[^\"]*"><seg>(.+)<\/seg><\/tuv>/i) { # TMX
     $$TARGET = $1;
   }
   elsif (/<tuv xml:lang="$e[^\"]*">\s*$/i) {
     my $next = <XLIFF>;
     if ($next =~ /<seg>(.+)<\/seg>/) {
       $$TARGET = $1;
     }
   }
   elsif (/<\/trans-unit>/i || /<\/tu>/i) { 
     if ($source ne "" && $target ne "") {
       print F $source."\n";
       print E $target."\n";
       $source = "";
       $target = "";
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

`rm $tmp_file` if defined($url);
