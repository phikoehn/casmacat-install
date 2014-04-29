#!/usr/bin/perl -w

$|=1;

use strict;
use Getopt::Long "GetOptions";

my $dir = "/opt/casmacat/admin/scripts";

my ($HELP,$F,$E,@CORPUS,$TUNING_CORPUS,$TUNING_SELECT,$EVALUATION_CORPUS,$EVALUATION_SELECT,$NAME) = @_;
my %LINE_COUNT;

$HELP = 1
    unless &GetOptions('corpus=s' => \@CORPUS,
		       'tuning-corpus=s' => \$TUNING_CORPUS,
		       'tuning-select=s' => \$TUNING_SELECT,
		       'evaluation-corpus=s' => \$EVALUATION_CORPUS,
		       'evaluation-select=s' => \$EVALUATION_SELECT,
		       'name=s' => \$NAME,
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
if (defined($TUNING_SELECT)) {
  my $name = &create_subsample("tuning",$TUNING_CORPUS,$TUNING_SELECT,\%{$USED_IN_TUNING_OR_EVAL{$TUNING_CORPUS}});
  $CONFIG{"TUNING_INPUT_SGM"} = $name."-src.sgm";
  $CONFIG{"TUNING_REFERENCE_SGM"} = $name."-ref.sgm";
}

# evaluation
if (defined($EVALUATION_SELECT)) {
  my $name = &create_subsample("evaluation",$EVALUATION_CORPUS,$EVALUATION_SELECT,\%{$USED_IN_TUNING_OR_EVAL{$EVALUATION_CORPUS}});
  $CONFIG{"EVALUATION"} = "[EVALUATION:corpus-$EVALUATION_CORPUS]\ninput-sgm = $name-src.sgm\nreference-sgm = $name-ref.sgm\n";
}

# build corpus sections
foreach my $id (@CORPUS) {
  if (!defined($USED_IN_TUNING_OR_EVAL{$id})) {
    $CONFIG{"CORPUS"} .= "[CORPUS:corpus-$id]\n";
    $CONFIG{"CORPUS"} .= "raw-stem = $corpus_dir/$id\n";
  }
  else {
    my $name = "reduced$id";
    $name .= "-not".$TUNING_SELECT if $TUNING_CORPUS == $id;
    $name .= "-noe".$EVALUATION_SELECT if $EVALUATION_CORPUS == $id;
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

# build lm section
foreach my $id (@CORPUS) {
  if (!$USED_IN_TUNING_OR_EVAL{$id}) {
    $CONFIG{"LM"} .= "[LM:corpus-$id]\n";
    $CONFIG{"LM"} .= "raw-corpus = $corpus_dir/$id.$F\n";
  }
  else {
    my $name = "reduced$id";
    $name .= "-not".$TUNING_SELECT if $TUNING_CORPUS == $id;
    $name .= "-noe".$EVALUATION_SELECT if $EVALUATION_CORPUS == $id;
    $CONFIG{"LM"} .= "[LM:$name]\n";
    $CONFIG{"LM"} .= "raw-corpus = $data_dir/$name.$F\n";
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

# is this a duplicate of a running or finished experiment?
my $max_run = 0;
if (-e "$exp_dir/steps") {
  open(OLD_RUN,"ls $exp_dir/steps|");
  while(my $old_run = <OLD_RUN>) {
    chop($old_run);
    next if $old_run == 0;
    $max_run = $old_run if $old_run > $max_run;
    # check against old configuration file
    my $old_config = "$exp_dir/steps/$old_run/config.$old_run";
    next unless -e $old_config;
    my $diff = `diff $exp_dir/config $old_config`;
    next unless $diff eq '';
    # check if running or completed
    if (-e "$exp_dir/evaluation/report.$old_run") {
      # maybe todo: exception if software updated
      print "Identical setup to finished system $old_run.\n";
      exit;
    }
    my $old_running = "$exp_dir/steps/$old_run/running.$old_run";
    if (-e $old_running) {
      my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($old_running);
      if (time()-$mtime < 60) {
        print "Already running (system $old_run)\n"; 
        exit;
      }
    }
  }
  close(EXP);
}
my $run = $max_run+1;

# set up directory for "inspect details"
my $setup = "/opt/casmacat/admin/inspect/setup";
open(EXP,$setup);
my $dir_id = 0;
my $line_count = 0;
while(<EXP>) {
  chop;
  my ($id,$owner,$name,$path) = split(/\;/);
  $dir_id = $id if $path eq $exp_dir;
  $line_count++;
}
close(EXP);
if (!$dir_id) {
  $dir_id = $line_count+1;
  open(EXP,">>$setup");
  print EXP "$dir_id;casmacat;Language pair $F-$E;$exp_dir\n";
  close(EXP);
}

# store name
my $comment = "/opt/casmacat/admin/inspect/comment";
open(COMMENT,">>$comment");
print COMMENT "$dir_id-$run;$NAME\n";
close(COMMENT);

# good to go
chdir($exp_dir);
#my $plan = `/opt/moses/scripts/ems/experiment.perl -config $exp_dir/config -no-graph`;
#print $plan;
print "Started, this may take a while.";
`/opt/moses/scripts/ems/experiment.perl -config $exp_dir/config -no-graph -exec 2>&1 > $exp_dir/OUT.$run`;

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

