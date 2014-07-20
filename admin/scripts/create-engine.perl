#!/usr/bin/perl -w

use strict;
use Getopt::Long "GetOptions";

my ($HELP,$F,$E,$RUN) = @_;
my %LINE_COUNT;

$HELP = 1
    unless &GetOptions('run=i' => \$RUN,
		       'f=s' => \$F,
		       'e=s' => \$E);

# directories
my $engine_dir = "/opt/casmacat/engines";
my $exp_dir = "/opt/casmacat/experiment/$F-$E";
my $data_dir = $exp_dir."/data";

# create directory for engine
my $engine = "$F-$E-$RUN";
my $dir = "$engine_dir/$engine";
`mkdir $dir`;

open(INFO,">$dir/info");
print INFO "source = $F\n";
print INFO "target = $E\n";
print INFO "run = $RUN\n";
print INFO "time_started = 1395900000\n";
print INFO "time_done = 1395900000\n";
print INFO "time_built = ".time()."\n";
close(INFO);

# get information about models that were built
my %STEP; # maps steps to run that was used
open(STEP,"ls $exp_dir/steps/$RUN/*INFO|");
while(<STEP>) {
  /\/([^\/]+)\.\d+\.INFO/;
  $STEP{$1} = $RUN;
  print "from info: $1 -> $RUN\n";
}
close(STEP);

open(RE_USE,"$exp_dir/steps/$RUN/re-use.$RUN");
while(<RE_USE>) {
  chop;
  s/\:/\_/g;
  my($step,$run) = split;
  $STEP{$step} = $run;
  print "from info: $step -> $run\n";
}
close(RE_USE);

# process ttable
my $ttable = "$exp_dir/model/phrase-table.".$STEP{"TRAINING_build-ttable"}.".gz";
my $first_line = `zcat $ttable | head -1`;
my @FIELD = split(/ \|\|\| /,$first_line);
my @SCORE = split(/ /,$FIELD[2]);
my $nscores = scalar @SCORE;
$ttable =~ /\/([^\/]+).gz$/;
`/opt/moses/bin/processPhraseTableMin -in $ttable -out $dir/$1 -threads all -nscores $nscores`;

# process reordering table
if (defined($STEP{"TRAINING_build-reordering"})) {
  my $reordering_table = `ls $exp_dir/model/reordering-table.$STEP{"TRAINING_build-reordering"}.*`;
  chop($reordering_table);
  $reordering_table =~ /\/([^\/]+).gz$/;
  `/opt/moses/bin/processLexicalTableMin -in $reordering_table -out $dir/$1 -threads all`;
}

# copy language model
if (defined($STEP{"INTERPOLATED-LM_binarize"})) {
  `cp $exp_dir/lm/interpolated-binlm.$STEP{"INTERPOLATED-LM_binarize"} $dir/lm`;
}
else {
  foreach (keys %STEP) {
    if (/LM_(.+)_binarize/) {
      `cp $exp_dir/lm/$1.binlm.$STEP{$_} $dir`;
    }
  }
}

# copy bilingual concordancer
if (defined($STEP{"TRAINING_build-biconcor"})) {
  `cp $exp_dir/model/biconcor.$RUN.* $dir`;
  `cp $exp_dir/model/biconcor.$RUN $dir`;
}

# build memory mapped suffix array for parallel corpus (needed for incremental updating)
# TODO: something has to be done with the config file
`mkdir $dir/mmsapt`;
`/opt/moses/bin/mtt-build < $exp_dir/training.$RUN.$F -i -o $dir/mmsapt/$F`;
`/opt/moses/bin/mtt-build < $exp_dir/training.$RUN.$E -i -o $dir/mmsapt/$E`;
`/opt/moses/bin/symal2mam < $exp_dir/model/aligned.$RUN.grow-diag-final-and $dir/mmsapt/$F-$E.mam`;
`/opt/moses/bin/mmlex-build $dir/mmsapt/ $F $E -o $dir/mmsapt/$F-$E.lex -c $dir/mmsapt/fr-en.cooc`;

# copy truecase model
if (defined($STEP{"TRUECASER_train"})) {
  `cp $exp_dir/truecaser/truecase-model.$STEP{"TRUECASER_train"}.* $dir`;
}

# copy configuration file
my $config = "$exp_dir/tuning/moses.tuned.ini.".$STEP{"TUNING_apply-weights"};
open(CONFIG,$config);
open(OUT,">$dir/moses.tuned.ini.".$STEP{"TUNING_apply-weights"});
while(<CONFIG>) {
  s/experiment\/..-..\/[^\/]+/engines\/$engine/g;
  s/PhraseDictionaryMemory/PhraseDictionaryCompact/;
  s/(reordering-table.+).gz/$1/;
  print OUT $_;
}
close(CONFIG);

# create run file
open(RUN,">$dir/RUN");
print RUN "#!/bin/bash

export ROOTDIR=/opt/casmacat
export SRCLANG=$F
export TGTLANG=$E
export MODELDIR=$dir
export SCRIPTDIR=\$ROOTDIR/engines/scripts
export PYTHONPATH=\$ROOTDIR/mt-server/python_server/python-module
export ENGINEPATH=\$ROOTDIR/engines

mkdir -p \$ENGINEPATH/log

killall -9 mosesserver
/opt/moses/bin/mosesserver -config \$MODELDIR/moses.tuned.ini.".$STEP{"TUNING_apply-weights"}." --server-port 9010 -mp -search-algorithm 1 -cube-pruning-pop-limit 100 -s 100 \\
  >  \$ENGINEPATH/log/$engine.moses.stdout \\
  2> \$ENGINEPATH/log/$engine.moses.stderr &

kill -9 `ps -eo pid,cmd -C python | grep 'python /opt/casmacat/mt-server/python_server/server.py' | grep -v grep | cut -c1-5`
\$ROOTDIR/mt-server/python_server/server.py \\
  -tokenizer \"\$SCRIPTDIR/tokenizer.perl -b -a -l $F\" \\
  -truecaser \"\$SCRIPTDIR/truecase.perl -b -model $dir/truecase-model.".$STEP{"TRUECASER_train"}.".$F\" \\
  -prepro \"\$SCRIPTDIR/normalize-punctuation.perl -b $F\" \\
  -detruecaser \"\$SCRIPTDIR/detruecase.perl -b\" \\
  -detokenizer \"\$SCRIPTDIR/detokenizer.perl -b -l $E\" \\
  -persist \\
  -nthreads 1 \\
  -ip 127.0.0.1 \\
  -port 9000 \\
  -mosesurl \"http://127.0.0.1:9010/RPC2\" \\
  >  \$ENGINEPATH/log/$engine.stdout \\
  2> \$ENGINEPATH/log/$engine.stderr &
";
close(RUN);
`chmod +x $dir/RUN`;

my $size = `du -h $dir`;
$size = s/ .+//;
open(INFO,">>$dir/info");
print INFO "size = $size\n";
close(INFO);

