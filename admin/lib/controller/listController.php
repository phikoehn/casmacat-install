<?php

class listController extends viewcontroller {
    private $msg = '';

    public function __construct() {
        parent::__construct();
       	parent::makeTemplate("list.html");
    }
    
    public function doAction(){
      if ($engine = $_GET["deploy-engine"]) {
        $handle = fopen("/opt/casmacat/engines/deployed","w");
        fwrite($handle,$engine."\n");
        fclose($handle);
        exec("/opt/casmacat/admin/scripts/start-mt-server.perl");
        exec("/opt/casmacat/admin/scripts/start-cat-server.sh");
      }
    }
    
    private function init_lang_pair($source,$target) {
      global $language;
      $lang_pair = array();
      $lang_pair["name"] = $language[$source]."-".$language[$target];
      $lang_pair["source"] = $source;
      $lang_pair["target"] = $target;
      $lang_pair["has_building"] = 0;
      $lang_pair["has_done"] = 0;
      return $lang_pair;
    }

    public function setTemplateVars() {
      $list = array();
      global $exp_dir,$engine_dir;

      # which engine is deployed?
      $deployed_array = file("$engine_dir/deployed"); # todo read into single line
      $deployed = chop($deployed_array[0]);
 
      # get information about available engine
      $available_engines = array();
      if ($handle = opendir($engine_dir)) {
	while (false !== ($engine = readdir($handle))) {
          if (file_exists("$engine_dir/$engine/info")) {
            $info_file = file("$engine_dir/$engine/info");
            $info_from_file = array();
            foreach($info_file as $line) {
              if (preg_match("/^(\S+) = (.+)/",$line,$match)) {
                $info_from_file[$match[1]] = $match[2];
              }
            }
            # find language pair and maybe initial its array
            $key = $info_from_file["source"]."-".$info_from_file["target"];
            if (!array_key_exists($key,$lang_pair_hash)) {
              $lang_pair_hash[$key] = $this->init_lang_pair($info_from_file["source"],$info_from_file["target"]);
            }
	    $info = array();
	    $info["run"] = $info_from_file["run"];
            $info["status"] = "done";
            $info["time_started"] = $info_from_file["time_started"];
            $info["time_done"] = $info_from_file["time_done"];
            $deployed_flag = ($engine == $deployed);
	    $info["deployed"] = $deployed_flag;
	    $info["available"] = !$deployed_flag;
            if (!$deployed_flag) {
	      $info["action"] = "/?action=list&deploy-engine=$engine";
            }
	    $info["not_available"] = 0;
            $lang_pair_hash[$key]["has_done"] = 1;
            $lang_pair_hash[$key]["exp_done"][] = $info;
          }
        }
      }
      
      # get status of all experimental runs
      if ($handle = opendir($exp_dir)) {
        while (false !== ($file = readdir($handle))) {
          if (preg_match("/([a-z]{2})-([a-z]{2})/",$file,$match)) {

            # process runs for one language pair
            $source = $match[1];
            $target = $match[2];
            $key = "$source-$target";
            if (!array_key_exists($key,$lang_pair_hash)) {
              $lang_pair_hash[$key] = $this->init_lang_pair($source,$target);
            }
            $lang_dir = "$exp_dir/$file";
            if ($handle2 = opendir($lang_dir."/steps")) {
              while (false !== ($file = readdir($handle2))) {
                if (preg_match("/^(\d+)$/",$file,$match) && $match[1]>0) {

                  # get info on run
		  $info = array();
		  $info["time_started"] = filectime("$lang_dir/steps/$run/config.$run");
                  $run = $match[1];
		  $info["run"] = $run;
                  if (file_exists("$lang_dir/evaluation/report.$run")) {
                    $info["status"] = "done";
                    $info["time_done"] = filectime("$lang_dir/evaluation/report.$run");
		    $info["deployed"] = 0;
		    $info["available"] = 0; # todo
		    $info["not_available"] = 1; # todo
		    $info["action"] = "/?action=createEngine&input-extension=$source&output-extension=$target&run=$run";
                    $lang_pair_hash[$key]["has_done"] = 1;
                    $lang_pair_hash[$key]["exp_done"][] = $info;
                  }
                  else if (file_exists("$lang_dir/steps/$run/running.$run")) {
                    $lang_pair_hash[$key]["has_building"] = 1;
                    if (filectime("$lang_dir/steps/$run/running.$run")+60 > time()) {
                      $info["status"] = "building";
                    }
                    else {
                      $info["status"] = "crashed";
                      $info["time_crashed"] = filectime("$lang_dir/steps/$run/running.$run");
                    }
                    $lang_pair_hash[$key]["exp_building"][] = $info;
                  }
                  else {
                    $lang_pair_hash[$key]["has_building"] = 1;
                    $info["status"] = "starting";
                    $lang_pair_hash[$key]["exp_building"][] = $info;
                  }
                }
              }
            }
            function run_cmp($a,$b) {
              if ($a["run"] == $b["run"]) return 0;
              return $a["run"] < $b["run"] ? 1 : -1;
            }
            if ($lang_pair_hash[$key]["has_done"]) {
              usort($lang_pair_hash[$key]["exp_done"], 'run_cmp');
            }
            if ($lang_pair_hash[$key]["has_building"]) {
              usort($lang_pair_hash[$key]["exp_building"], 'run_cmp');
            }

          }
        }
      }
      foreach($lang_pair_hash as $lang_pair) {
        $list[] = $lang_pair;
      }
      function list_cmp($a,$b) {
         return strcmp($a["name"], $b["name"]);
      }
      usort($list, 'list_cmp');
      $this->template->list = $list;
      $this->template->msg = $msg;
    }
}

?>
