<?php
  error_reporting(-1);
  ini_set("display_errors", 1);

  if (array_key_exists("action",$_GET)) {
    if ($_GET['action'] == 'start-mt-server') {
      exec('scripts/start-mt-server.sh');
    }
    if ($_GET['action'] == 'start-cat-server') {
      exec('scripts/start-cat-server.sh');
    }
  }
?>
<html><head><title>CASMACAT Home Edition</title>
<link href="/public/css/style.css" rel=stylesheet type="text/css">
<body>
<center><img src="casmacat-logo.png" width=421 height=174>
<p><b>Home Edition</b>
<table><tr><td>
<?php
  $ret = array();
  exec('/sbin/ifconfig',$ret);
  foreach($ret as $line) {
    if (preg_match('/inet addr:(\d+\.\d+\.\d+\.\d+)/',$line,$match) && $match[1] != '127.0.0.1') {
      $ip = $match[1];
    }
  }
  if ($ip) {
    if ($_SERVER['REMOTE_ADDR'] == $ip || $_SERVER['REMOTE_ADDR'] == '127.0.0.1') {
      print "You can access this page also from a web browser on your host computer under the address:<br>http://$ip/\n";
    }
  }
  else {
    print "Networking is not set up correctly!<p>Please on your virtual machine Devices / Network / Network settings / Bridged Adapter";
  }
?>
</center>

<br><progress value="10" max="100"></progress> Installing Web Server
<br><progress value="10" max="100"></progress> Installing CAT Server
<br><progress value="10" max="100"></progress> Installing MT Server
<br><progress value="10" max="100"></progress> Downloading Toy System
</ol>

<p>Administration</p>
<ul>
<?php
  $cat_server_online = 0;
  $mt_server_online = 0;
  $ret = array();
  exec('/bin/ps -ef',$ret);
  foreach($ret as $line) {
    if (strpos($line,"/opt/casmacat/cat-server/cat-server.py --port 9999") !== false) {
      $cat_server_online++;
    }
    if (strpos($line,"/opt/moses/bin/mosesserver") !== false) {
      $mt_server_online++;
    }
    if (strpos($line,"/opt/casmacat/mt-server/python_server/server.py") !== false) {
      $mt_server_online++;
    }
  }
  if ($cat_server_online == 0) {
    print "<li><a href=\"/?action=start-cat-server\">Start CAT server</a>\n";
  }
  if ($mt_server_online != 2) {
    print "<li><a href=\"/?action=start-mt-server\">Start MT server</a>\n";
  }
  if ($cat_server_online == 1 && $mt_server_online == 2) {
    print "<li><a href=\"http://$ip:8000/\">Translate new document</a>\n";
  }
?>
<li><a href="/mt-builder/">Build MT system</a>
<li>MT settings
<li>CAT settings
</ul>
<?php
  $ret = array();
  exec('/usr/bin/free',$ret);
  foreach($ret as $line) {
    if (preg_match('/buffers\/cache:\s+(\d+)\s+(\d+)/',$line,$match)) {
      $used = $match[1]/1024/1024;
      $free = $match[2]/1024/1024;
      printf ("<p>Virtual machine memory status: %.1f GB used, %.1f GB free",$used,$free);
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
      printf ("<br>Virtual machine disk status: %.1f GB used, %.1f GB free",$used,$free);
    }
  }
?>
</td></tr></table>
</body></html>
