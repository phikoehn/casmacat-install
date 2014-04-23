<?php
  global $language, $data_dir,$exp_dir,$id,$alert;
  $language = array( "en" => "English",
                     "fr" => "French",
                     "de" => "German",
                     "es" => "Spanish" );
  $data_dir = "/opt/casmacat/data";
  $exp_dir = "/opt/casmacat/experiment";
  $engine_dir = "/opt/casmacat/engines";

  // check on IP address 
  $ret = array();
  exec('/sbin/ifconfig',$ret);
  foreach($ret as $line) {
    if (preg_match('/inet addr:(\d+\.\d+\.\d+\.\d+)/',$line,$match) && $match[1] != '127.0.0.1') {
      $ip = $match[1];
    }
  }
  if ($ip) {
    if ($_SERVER['REMOTE_ADDR'] == $ip || $_SERVER['REMOTE_ADDR'] == '127.0.0.1') {
      $alert = "You can access this page also from a web browser on your host computer under the address: <b>http://$ip/</b>\n";
    }
  }
  else {
    $alert = "Networking is not set up correctly!<p>Please on your virtual machine Devices / Network / Network settings / Bridged Adapter";
  }

  // pretty time printing
  function pretty_time($timestamp) {
    date_default_timezone_set('UTC'); // hmmmm...
    if ($timestamp + 12*3600 > time()) {
      return strftime("%T",$timestamp);
    }
    if ($timestamp + 5*24*3600 > time()) {
      return strftime("%a %H:%M",$timestamp);
    }
    if ($timestamp + 180*24*3600 > time()) {
      return strftime("%d %b",$timestamp);
    }
    return strftime("%d %b %g",$timestamp);
  }

?>
