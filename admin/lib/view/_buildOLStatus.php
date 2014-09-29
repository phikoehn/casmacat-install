<?php
  $f = fopen("/tmp/build_ol_status", 'r');
  $line = fgets($f);
  fclose($f);

  $values = preg_split("/\s+/", $line);
  $n = intval($values[0]);
  $N = intval($values[1]);
  if ($n == $N) {
    print "<p>Online learning completed.</p>";
    print "<ul><li><a href=\"/\">Return to main menu</a></li>";
  } 
  else {
    printf("<progress value='$n' max='$N'></progress>\n", $progress);
  }
?>
