<table width="100%">
<?php
  $exp_dir = "/opt/casmacat/experiment";
  if ($handle = opendir($exp_dir)) {
    while (false !== ($file = readdir($handle))) {
      if (preg_match("/([a-z]{2})-([a-z]{2})/",$file,$match)) {
        $lang_dir = "$exp_dir/$file";
        if ($handle2 = opendir($lang_dir."/steps")) {
          while (false !== ($file = readdir($handle2))) {
            if (preg_match("/^(\d+)$/",$file,$match) && $match[1]>0) {
              $run = $match[1];
              if (!file_exists("$lang_dir/evaluation/report.$run") &&
                  !file_exists("$lang_dir/steps/$run/stopped.$run") &&
                  file_exists("$lang_dir/steps/$run/running.$run")) {
                if (filectime("$lang_dir/steps/$run/running.$run")+60 > time()) {
                  $log = file("$lang_dir/OUT.$run");
                  $steps_to_run = 0;
                  foreach($log as $line) {
                    if (preg_match("/\s*\-\>\s*run$/",$line) ||
			preg_match("/\s*\-\>\s*re-using \($run\)/",$line)) {
                      $steps_to_run++;
                    }
                  }
                  $finished = array();
                  exec("ls $lang_dir/steps/$run/*DONE | wc -l",$finished);
                  printf ("<tr><td><b>Building:</b></td><td>%d of %d steps finished</td><td><progress value=\"%d\" max=\"%d\"></progress> <img src=\"/inspect/spinner.gif\" width=12 height=12></td></tr>",$finished[0],$steps_to_run,$finished[0],$steps_to_run);
                  $step = array();
		  exec("ls -t $lang_dir/steps/$run | grep '^[A-Z]'",$step);
                  printf ("<tr><td></td><td colspan=\"2\">%s</td></tr>",$step[1]);
                }
              }
            }
          }
        }
      }
    }
  } 
?>
<?php
  $deployed = file("/opt/casmacat/engines/deployed");
  if (isset($deployed[0])) {
    print "<tr><td><b>Deployed:</b></td><td colspan=\"2\">".$deployed[0]."</td></tr>";;
  }
?>
<?php
  $ret = array();
  exec('/usr/bin/free',$ret);
  foreach($ret as $line) {
    if (preg_match('/buffers\/cache:\s+(\d+)\s+(\d+)/',$line,$match)) {
      $used = $match[1]/1024/1024;
      $free = $match[2]/1024/1024;
      printf ("<tr><td><b>Memory:</b></td><td>%.1f GB used, %.1f GB free</td><td><progress value=\"%.3f\" max=\"%.3f\"></progress></td></tr>",$used,$free,$used,$used+$free);
    }
  }
?>
<?php
  $ret = array();
  exec('/bin/df',$ret);
  foreach($ret as $line) {
    if (preg_match('/(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\% \/$/',$line,$match)) {
      $total = $match[1]/1024/1024;
      $used = $match[2]/1024/1024;
      $free = $match[3]/1024/1024;
      $ratio = $match[4];
      printf ("<tr><td><b>Disk:</b></td><td>%.1f GB used, %.1f GB free</td><td><progress value=\"%.3f\" max=\"%.3f\"></progress></td></tr>",$used,$free,$used,$used+$free);
    }
  }
?>
<?php
  exec('/usr/bin/uptime',$uptime);
  preg_match('/up (.+), *\d+ users?, *load average: (.+)/',$uptime[0],$match);
  print "<tr><td><b>Uptime:</b></td><td colspan=\"2\">".$match[1]."</td></tr>";;
  print "<tr><td><b>Load:</b></td><td colspan=\"2\">".$match[2]."</td></tr>";;
?>
<?php
  date_default_timezone_set('UTC'); // hmmmm...
  print strftime("<tr><td colspan=\"3\">%A, %d %B %G, %H:%M:%S</td></tr>",time());
?>
</table>
