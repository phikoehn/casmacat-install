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

#use Data::Dumper;
#print Dumper($dir, \%STEP);

# process ttable - old static phrase table
#my $ttable = "$exp_dir/model/phrase-table.".$STEP{"TRAINING_build-ttable"}.".gz";
#my $first_line = `zcat $ttable | head -1`;
#my @FIELD = split(/ \|\|\| /,$first_line);
#my @SCORE = split(/ /,$FIELD[2]);
#my $nscores = scalar @SCORE;
#$ttable =~ /\/([^\/]+).gz$/;
#`/opt/moses/bin/processPhraseTableMin -in $ttable -out $dir/$1 -threads all -nscores $nscores`;

# copy phrase table
`cp -r $exp_dir/model/phrase-table-thot.$STEP{"TRAINING_thot-build-ttable"} $dir/tm`;

# copy language model
foreach (keys %STEP) {
  if (/LM_(.+)_train/) {
    `cp -r $exp_dir/lm/$1.lm.$STEP{$_} $dir/lm`;
  }
}

# copy truecase model
if (defined($STEP{"TRUECASER_train"})) {
  `cp $exp_dir/truecaser/truecase-model.$STEP{"TRUECASER_train"}.* $dir`;
}

# copy configuration file
my $config_dir = "$exp_dir/tuning/thot.tuned.ini.".$STEP{"TUNING_thot-tune"};
my $config = "$config_dir/tuned_for_dev.cfg";
open(CONFIG,$config);
open(OUT,">$dir/thot.tuned.ini.".$STEP{"TUNING_thot-tune"});
while(<CONFIG>) {
  s/$config_dir/$dir/;
  print OUT $_;
}
close(OUT);
close(CONFIG);

open(OUT,">$dir/itp-server.conf.".$STEP{"TUNING_thot-tune"});
print OUT <<"END_OF_FILE";
{
  "server": {
    "port": 4501
  },
  "mt": {
    "id": "PE",
    "ref": "ITP"
  },
  "imt": {
    "id": "ITP",
    "module": "/opt/thot/lib/libthot_casmacat.so", 
    "name": "thot_imt_plugin",
    "parameters": "-c $dir/thot.tuned.ini.$STEP{"TUNING_thot-tune"}",
    "online-learning": false
  },
  "aligner": {
    "module": "/opt/thot/lib/libthot_casmacat.so", 
    "name": "thot_align_plugin",
    "parameters": "$dir/tm/main/src_trg_invswm",
    "online-learning": false
  },
  "confidencer": {
    "module": "/opt/thot/lib/libthot_casmacat.so", 
    "name": "thot_cm_plugin",
    "parameters": "$dir/tm/main/src_trg_invswm",
    "thresholds": [3, 30],
    "online-learning": false
  },
  "word-prioritizer": [ ],
  "source-processor": {
    "module": "/opt/casmacat/itp-server/src/lib/.libs/perl-tokenizer.so", 
    "parameters": "/opt/casmacat/itp-server/src/lib/processor.perl -l $F -d /opt/moses/scripts/share -c $dir/truecase-model.$STEP{"TRUECASER_train"}.$F"
  },
  "target-processor": {
    "module": "/opt/casmacat/itp-server/src/lib/.libs/perl-tokenizer.so", 
    "parameters": "/opt/casmacat/itp-server/src/lib/processor.perl -l $E -d /opt/moses/scripts/share  -c $dir/truecase-model.$STEP{"TRUECASER_train"}.$E"
  },
  "sentences": [ ]
}
END_OF_FILE
close(OUT);


# create run file
open(RUN,">$dir/RUN");
print RUN <<"END_OF_FILE";
#!/bin/bash

#! /bin/bash

export ROOTDIR=/opt/casmacat
export LOGDIR=\$ROOTDIR/log/mt

mkdir -p \$LOGDIR

killall -9 mosesserver
killall -9 online-mgiza
killall -9 symal
kill -9 `ps -eo pid,cmd -C python | grep 'python /opt/casmacat/mt-server/python_server/server.py' | grep -v grep | 
cut -c1-5`

kill -9 `ps -eo pid,cmd -C python | grep 'python /opt/casmacat/itp-server/server/casmacat-server.py' | grep -v grep | cut -c1-5`

if test "\$1" != "stop"; then 
  export PYTHONPATH=/opt/casmacat/itp-server/src/lib:/opt/casmacat/itp-server/src/python:\$PYTHONPATH 
  export LD_LIBRARY_PATH=/opt/casmacat/itp-server/src/lib/.libs 
  /opt/casmacat/itp-server/server/casmacat-server.py -c $dir/itp-server.conf.$STEP{"TUNING_thot-tune"} \$2 \\
    >  \$LOGDIR/$engine.thot.stdout \\
    2> \$LOGDIR/$engine.thot.stderr &
fi
END_OF_FILE
close(RUN);
`chmod +x $dir/RUN`;

my $size = `du -hd0 $dir`;
chop($size);
$size =~ s/^(\S+)\s.+$/$1/;
open(INFO,">>$dir/info");
print INFO "size = $size\n";
close(INFO);

