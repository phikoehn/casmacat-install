<?php

class setupController extends viewcontroller {
    private $guid = '';
    public function __construct() {
        parent::__construct();
       	parent::makeTemplate("setup.html");
    }
    
    public function doAction(){
    }

    public function setTemplateVars() {
      // get default language pair
      $default_source = "de";
      $default_target = "es";
      $dir = "/opt/casmacat/data/";
      $max_time = 0;
      $msg = "";
      if ($handle = opendir($dir)) {
        while (false !== ($file = readdir($handle))) {
          if (preg_match("/([a-z]{2})-([a-z]{2})/",$file,$match) && filectime("$dir/$file") > $max_time) {
            $max_time = filectime("$dir/$file");
            $default_source = $match[1];
            $default_target = $match[2];
          }
        }
      }
      
      global $language;
      foreach($language as $code => $name) {
        $lang_info = array("code" => $code, "name" => $name);
        $lang_info["default_source"] = ($code == $default_source);
        $lang_info["default_target"] = ($code == $default_target);
        $lang_display[] = $lang_info;
      }
      function cmp($a,$b) {
         return strcmp($a["name"], $b["name"]);
      }
      usort($lang_display, 'cmp');
      $this->template->languages = $lang_display;
    }
}

?>
