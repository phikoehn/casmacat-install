#!/usr/bin/perl -w

use strict;
use Getopt::Long "GetOptions";

my ($F,$E,$RUN,$NAME) = @_;
my %LINE_COUNT;

die unless &GetOptions('run=i' => \$RUN,
		       'f=s' => \$F,
		       'name=s' => \$NAME,
		       'e=s' => \$E);
die unless defined($F) && defined($E) && defined($RUN);
$NAME = "unnamed" unless defined($NAME) && $NAME !~ /^\s*$/;

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
print INFO "name = $NAME\n";
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
  #print "from info: $1 -> $RUN\n";
}
close(STEP);

open(RE_USE,"$exp_dir/steps/$RUN/re-use.$RUN");
while(<RE_USE>) {
  chop;
  s/\:/\_/g;
  my($step,$run) = split;
  $STEP{$step} = $run;
  #print "from re-use: $step -> $run\n";
}
close(RE_USE);

# process ttable - old static phrase table
#my $ttable = "$exp_dir/model/phrase-table.".$STEP{"TRAINING_build-ttable"}.".gz";
#my $first_line = `zcat $ttable | head -1`;
#my @FIELD = split(/ \|\|\| /,$first_line);
#my @SCORE = split(/ /,$FIELD[2]);
#my $nscores = scalar @SCORE;
#$ttable =~ /\/([^\/]+).gz$/;
#`/opt/moses/bin/processPhraseTableMin -in $ttable -out $dir/$1 -threads all -nscores $nscores`;

# copy phrase table (memory mapped suffix array)
`cp -r $exp_dir/model/phrase-table-mmsapt.$STEP{"TRAINING_build-mmsapt"} $dir`;

# copy reordering table
`cp $exp_dir/model/moses.bin.ini.$STEP{"TRAINING_create-config"}.tables/reordering-table.$STEP{"TRAINING_build-reordering"}.wbe-msd-bidirectional-fe.minlexr $dir`;

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

# copy word alignment models
`cp -r $exp_dir/training/giza.$STEP{"TRAINING_run-giza"} $dir`;
`cp -r $exp_dir/training/giza-inverse.$STEP{"TRAINING_run-giza-inverse"} $dir`;
`cp -r $exp_dir/training/prepared.$STEP{"TRAINING_prepare-data"} $dir`;

# copy truecase model
if (defined($STEP{"TRUECASER_train"})) {
  `cp $exp_dir/truecaser/truecase-model.$STEP{"TRUECASER_train"}.* $dir`;
}

# copy configuration file
my $config = "$exp_dir/tuning/moses.tuned.ini.".$STEP{"TUNING_apply-weights"};
open(CONFIG,$config);
open(OUT,">$dir/moses.tuned.ini.".$STEP{"TUNING_apply-weights"});
while(<CONFIG>) {
  s/moses.bin.ini.\d+.tables\/(reordering-table)/$1/;
  s/experiment\/..-..\/[^\/]+/engines\/$engine/g;
  s/(reordering-table.+).gz/$1/;
  print OUT $_;
}
close(CONFIG);

# create run file
open(RUN,">$dir/RUN");
print RUN "#!/bin/bash

export ROOTDIR=/opt/casmacat
export SCRIPTDIR=/opt/moses/scripts
export PYTHONDIR=\$ROOTDIR/mt-server/python_server/python-module
export ENGINEDIR=\$ROOTDIR/engines
export LOGDIR=\$ROOTDIR/log/mt
export USER=www-data

export SRCLANG=$F
export TGTLANG=$E
export MODELDIR=$dir
export S2TMODEL=\$MODELDIR/giza.".$STEP{"TRAINING_run-giza"}."/\${TGTLANG}-\${SRCLANG}
export T2SMODEL=\$MODELDIR/giza-inverse.".$STEP{"TRAINING_run-giza-inverse"}."/\${SRCLANG}-\${TGTLANG}
export PREPARED=\$MODELDIR/prepared.".$STEP{"TRAINING_prepare-data"}."

mkdir -p \$LOGDIR

killall -9 mosesserver
/opt/moses/bin/mosesserver -config \$MODELDIR/moses.tuned.ini.".$STEP{"TUNING_apply-weights"}." --server-port 9010 -mp -search-algorithm 1 -cube-pruning-pop-limit 100 -s 100 \\
  >  \$LOGDIR/$engine.moses.stdout \\
  2> \$LOGDIR/$engine.moses.stderr &

killall -9 online-mgiza
killall -9 symal
kill -9 `ps -eo pid,cmd -C python | grep 'python /opt/casmacat/mt-server/python_server/server.py' | grep -v grep | cut -c1-5`
\$ROOTDIR/mt-server/python_server/server.py \\
  -logprefix \$LOGDIR/$engine \\
  -tokenizer \"\$SCRIPTDIR/tokenizer/tokenizer.perl -b -a -l $F -protected \$SCRIPTDIR/tokenizer/basic-protected-patterns\" \\
  -truecaser \"\$SCRIPTDIR/recaser/truecase.perl -b -model $dir/truecase-model.".$STEP{"TRUECASER_train"}.".$F\" \\
  -prepro \"\$SCRIPTDIR/tokenizer/normalize-punctuation.perl -b $F\" \\
  -detruecaser \"\$SCRIPTDIR/recaser/detruecase.perl -b\" \\
  -detokenizer \"\$SCRIPTDIR/tokenizer/detokenizer.perl -b -l $E\" \\
  -tgt-tokenizer \"\$SCRIPTDIR/tokenizer/tokenizer.perl -b -a -l $E\ -protected \$SCRIPTDIR/tokenizer/basic-protected-patterns\" \\
  -omgiza_tgt2src \"/opt/moses/external/bin/online-mgiza \${T2SMODEL}.gizacfg -onlineMode 1 -coocurrencefile \${T2SMODEL}.cooc -corpusfile \${PREPARED}/\${SRCLANG}-\${TGTLANG}-int-train.snt -previousa \${T2SMODEL}.a3.final -previousd \${T2SMODEL}.d3.final -previousd4 \${T2SMODEL}.d4.final -previousd42 \${T2SMODEL}.D4.final -previoushmm \${T2SMODEL}.hhmm.5 -previousn \${T2SMODEL}.n3.final -previoust \${T2SMODEL}.t3.final -sourcevocabularyfile \${PREPARED}/\$TGTLANG.vcb -sourcevocabularyclasses \${PREPARED}/\$TGTLANG.vcb.classes -targetvocabularyfile \${PREPARED}/\$SRCLANG.vcb -targetvocabularyclasses \${PREPARED}/\$SRCLANG.vcb.classes -o \$LOGDIR -m1 0 -m2 0 -m3 0 -m4 3 -mh 0 -restart 11\" \\
  -omgiza_src2tgt \"/opt/moses/external/bin/online-mgiza \${S2TMODEL}.gizacfg -onlineMode 1 -coocurrencefile \${S2TMODEL}.cooc -corpusfile \${PREPARED}/\${TGTLANG}-\${SRCLANG}-int-train.snt -previousa \${S2TMODEL}.a3.final -previousd \${S2TMODEL}.d3.final -previousd4 \${S2TMODEL}.d4.final -previousd42 \${S2TMODEL}.D4.final -previoushmm \${S2TMODEL}.hhmm.5 -previousn \${S2TMODEL}.n3.final -previoust \${S2TMODEL}.t3.final -sourcevocabularyfile \${PREPARED}/\$SRCLANG.vcb -sourcevocabularyclasses \${PREPARED}/\$SRCLANG.vcb.classes -targetvocabularyfile \${PREPARED}/\$TGTLANG.vcb -targetvocabularyclasses \${PREPARED}/\$TGTLANG.vcb.classes -o \$LOGDIR -m1 0 -m2 0 -m3 0 -m4 3 -mh 0 -restart 11\" \\
  -symal \"/opt/moses/bin/symal -alignment=grow -diagonal=yes -final=yes -both=yes\" \\
  -persist \\
  -nthreads 4 \\
  -ip 127.0.0.1 \\
  -port 9000 \\
  -mosesurl \"http://127.0.0.1:9010/RPC2\" \\
  >  \$LOGDIR/$engine.stdout \\
  2> \$LOGDIR/$engine.stderr &
";
close(RUN);
`chmod +x $dir/RUN`;

my $size = `du -hd0 $dir`;
chop($size);
$size =~ s/^(\S+)\s.+$/$1/;
open(INFO,">>$dir/info");
print INFO "size = $size\n";
close(INFO);

