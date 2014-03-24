#!/usr/bin/perl -w

use strict;
use Getopt::Long "GetOptions";

my $dir = "/opt/casmacat/admin/mt-builder/scripts";

my ($HELP,$F,$E,@CORPUS,$TUNING_SET,$EVALUATION_SET) = @_;
my %LINE_COUNT;

$HELP = 1
    unless &GetOptions('corpus=s' => \@CORPUS,
		       'tuning-set=s' => \$TUNING_SET,
		       'evaluation-set=s' => \$EVALUATION_SET,
		       'f=s' => \$F,
		       'e=s' => \$E);

# directories
my $exp_dir = "/opt/casmacat/experiment/$F-$E";
my $data_dir = $exp_dir."/data";
my $corpus_dir = "/opt/casmacat/data/$F-$E";
`mkdir -p $data_dir` unless -d $data_dir;

# basic settings
my %CONFIG;
$CONFIG{"E"} = $E;
$CONFIG{"F"} = $F;

# tuning
my %USED_IN_TUNING_OR_EVAL;
if ($TUNING_SET =~ /^subset-corpus-(\d+)-(\d+)$/) {
  my $name = &create_subsample("tuning",$1,$2,\%{$USED_IN_TUNING_OR_EVAL{$1}});
  $CONFIG{"TUNING_INPUT_SGM"} = $name."-src.sgm";
  $CONFIG{"TUNING_REFERENCE_SGM"} = $name."-ref.sgm";
}

# evaluation
if ($EVALUATION_SET =~ /^subset-corpus-(\d+)-(\d+)$/) {
  my $name = &create_subsample("evaluation",$1,$2,\%{$USED_IN_TUNING_OR_EVAL{$1}});
  $CONFIG{"EVALUATION"} = "[EVALUATION:$EVALUATION_SET]\ninput-sgm = $name-src.sgm\nreference-sgm = $name-ref.sgm\n";
}

# build corpus sections
foreach my $corpus (@CORPUS) {
  if ($corpus =~ /^corpus-(\d+)$/) {
    my $id = $1;
    if (!defined($USED_IN_TUNING_OR_EVAL{$id})) {
      $CONFIG{"CORPUS"} .= "[CORPUS:$corpus]\n";
      $CONFIG{"CORPUS"} .= "raw-stem = $corpus_dir/$id\n";
    }
    else {
      my $name = "reduced$id";
      $name .= "-not$1" if $TUNING_SET =~ /subset-corpus-$id-(.+)/;
      $name .= "-noe$1" if $EVALUATION_SET =~ /subset-corpus-$id-(.+)/;
      $CONFIG{"CORPUS"} .= "[CORPUS:$name]\n";
      $CONFIG{"CORPUS"} .= "raw-stem = $data_dir/$name\n";
      next if -e "$data_dir/$name.$E";
      open(CORPUS_E,"$corpus_dir/$id.$E");
      open(CORPUS_F,"$corpus_dir/$id.$F");
      open(REDUCED_E,">$data_dir/$name.$E");
      open(REDUCED_F,">$data_dir/$name.$F");
      my $line = 0;
      while(my $e = <CORPUS_E>) {
        my $f = <CORPUS_F>;
        next if defined($USED_IN_TUNING_OR_EVAL{$id}{$line++});
        print REDUCED_E $e;
        print REDUCED_F $f; 
      }
      close(REDUCED_E);
      close(REDUCED_F);
    }
  }
}

# build lm section
foreach my $corpus (@CORPUS) {
  if ($corpus =~ /^corpus-(\d+)$/) {
    my $id = $1;
    if (!$USED_IN_TUNING_OR_EVAL{$id}) {
      $CONFIG{"LM"} .= "[LM:$corpus]\n";
      $CONFIG{"LM"} .= "raw-corpus = $corpus_dir/$id.$F\n";
    }
    else {
      my $name = "reduced$id";
      $name .= "-not$1" if $TUNING_SET =~ /subset-corpus-$id-(.+)/;
      $name .= "-noe$1" if $EVALUATION_SET =~ /subset-corpus-$id-(.+)/;
      $CONFIG{"LM"} .= "[LM:$name]\n";
      $CONFIG{"LM"} .= "raw-corpus = $data_dir/$name.$F\n";
    } 
  }
}

# customize the configuration template 
open(TEMPLATE,"$dir/config.template");
open(CONFIG,">$exp_dir/config");
while(<TEMPLATE>) {
  s/<XXX (\S+)>/$CONFIG{$1}/g;
  print CONFIG $_;
}
close(CONFIG);
close(TEMPLATE);

# detailed reporting 
my $setup = "/opt/casmacat/admin/mt-builder/inspect/setup";
open(EXP,$setup);
my $already = 0;
my $line_count = 0;
while(<EXP>) {
  chop;
  my ($id,$owner,$name,$path) = split(/\;/);
  $already = 1 if $path eq $exp_dir;
  $line_count++;
}
close(EXP);
if (!$already) {
  open(EXP,">>$setup");
  print EXP "".($line_count+1).";casmacat;Language pair $F-$E;$exp_dir\n";
  close(EXP);
}

# good to go
chdir($exp_dir);
#my $plan = `/opt/moses/scripts/ems/experiment.perl -config $exp_dir/config -no-graph`;
#print $plan;
#`/opt/moses/scripts/ems/experiment.perl -config $exp_dir/config -no-graph -exec &`

### subs

sub create_subsample {
  my ($type,$corpus,$count,$USED) = @_;
  my $total = &line_count($corpus);
  my $offset = ($type eq "tuning") ? 0 : 1;
  my $step = $total/$count;
  my $name = "$data_dir/$type-$corpus-$count";
  &create_subsample_file("$corpus_dir/$corpus.$F","$name-src.sgm",$offset,$step);
  &create_subsample_file("$corpus_dir/$corpus.$E","$name-ref.sgm",$offset,$step,$USED);
  return $name;
}

sub create_subsample_file {
  my ($in,$out,$offset,$step,$USED) = @_;
  my $write = 1;
  open(IN,$in);
  if (-e $out) { 
    open(OUT,">/dev/null");
  }
  else {
    open(OUT,">$out");
  }
  if ($out =~ /src.sgm$/) {
    print OUT "<srcset setid=\"dummy\" srclang=\"$F\">\n";
    print OUT "<doc docid=\"dummy\">\n";
  }
  else {
    print OUT "<refset trglang=\"$E\" setid=\"dummy\" srclang=\"$F\">\n";
    print OUT "<doc sysid=\"ref\" docid=\"dummy\">\n";
  }
  my $line = 0;
  my $next = 0;
  my @USED;
  while(<IN>) {
    chomp;
    if ($line >= $next+$offset && !defined($$USED{$line})) {
      $$USED{$line}++;
      print OUT "<seg id=$line>$_</seg>\n";
      $next += $step;
    }  
    $line++;
  }
  if ($out =~ /src.sgm$/) {
    print OUT "</doc>\n</srcset>\n";
  }
  else {
    print OUT "</doc>\n</refset>\n";
  }
  close(OUT);
  close(IN);
  return @USED;
}

# could also get that out of the info file...
sub line_count {
  my ($corpus) = @_;
  if (defined($LINE_COUNT{$corpus})) {
    return $LINE_COUNT{$corpus};
  }
  my $line_count = int(`cat $corpus_dir/$corpus.$F | wc -l`);
  $LINE_COUNT{$corpus} = $line_count;
  return $line_count;
}

