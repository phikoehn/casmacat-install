<?php
  $status = file("/tmp/build_ol_status");
  if (preg_match("/Already running/",$status[0]) ||
      preg_match("/Identical setup/",$status[0])) {
    print $status[0];
    print "<p>If you want to build a different system, please change the configuration.</p>";
    print "<ul><li><a href=\"/\">Return to main menu</a></li>";
    print "<li><a href=\"/?action=setup\">Build new engine</a></li></ul>";
  } 
  else if (preg_match("/Started/",$status[0])) {
    print $status[0];
    print "<ul><li><a href=\"/\">Return to main menu</a></li>";
    print "<li><a href=\"/?action=list\">List of engines</a></li></ul>";
  }
  else {
    print $status[0];
    print "Waiting for build process to start...\n";
  }
?>
