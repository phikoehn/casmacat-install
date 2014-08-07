<?php
  require_once '/opt/casmacat/admin/lib/utils/globals.php';
  $log_dir = "/opt/casmacat/log/install";
  $most_recent = "";
  $most_recent_time = 0;
  if ($handle = opendir($log_dir)) {
    while (false !== ($file = readdir($handle))) {
      $timestamp = filectime("$log_dir/$file");
      if ($file == "install") {
        if ($most_recent_time == 0) {
          $most_recent_time = $timestamp;
          $most_recent = $file;
        }
      }
      else if (preg_match("/^\d+$/",$file,$match)) {
        if ($timestamp > $most_recent_time) { 
          $most_recent_time = $timestamp;
          $most_recent = $file;
        }
      }
    }
  }
  $recent_log_dir = "/opt/casmacat/log/install/".$most_recent;
  $done = 1;
  $status = array();
  if ($handle = opendir($recent_log_dir)) {
    while (false !== ($file = readdir($handle))) {
      if (preg_match("/out$/",$file)) {
        $log = file("$recent_log_dir/$file");
        foreach($log as $line) {
          if (preg_match("/^STEP \d+\/\d+/",$line) ||
              preg_match("/^DONE /",$line)) {
            $last_line = $line;
          }
        }
        $status[$file] = $last_line;
        if (!preg_match("/^DONE /",$last_line)) {
          $done = 0;
        }
      }
    }
  } 
  if (!$done) {
    print "<table class=\"updateframe\"><tr><td>";
    print "Installation $most_recent<br>";
    print "<table width=\"100%\">";
    foreach($status as $file => $status_line) {
      print "<tr><td valign=\"top\" width=\"200\">";
      if ($file == "moses.out") {
        print "MT software";
      }
      else if ($file == "admin.out") {
        print "Administration tool";
      }
      else if ($file == "casmacat.out") {
        print "CAT software";
      }
      else if ($file == "dependencies.out") {
        print "Basic software";
      }
      else if ($file == "test-model.out") {
        print "Example MT Engine";
      }
      print "</td><td>";
      if (preg_match("/STEP (\d+)\/(\d+): (.+) (\d+)$/",$status_line,$match)) {
        printf("<progress value=\"%d\" max=\"%d\"></progress> started %d seconds ago<br>step %d of %d: %s",$match[1],$match[2]+1,time()-$match[4],$match[1],$match[2],$match[3]);
      }
      else {
        print "complete";
      }
    }
    print "</table></td></tr></table>";
    print "<script>";
    print "var mainframe = document.getElementById('mainframe');";
    print "mainframe.style.display = 'none';";
    print "setTimeout(function(){ $.ajax({ url: '/lib/view/_install.php', method: 'get', dataType: 'text', success: function(remoteData) { $('#install').html(remoteData); }}) },500);";
    // print "setTimeout(function(){ new Ajax.Updater('install', '/lib/view/_install.php', { method: 'get', evalScripts: true }); },500);";
    print "</script>";

  }
  else {
    print "<script>";
    print "var mainframe = document.getElementById('mainframe');";
    print "mainframe.style.display = 'block';";
    print "</script>";
  }
?>
