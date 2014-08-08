<?php

class listController extends viewcontroller {
    private $msg = '';
    private $lp2id = array();

    public function __construct() {
        parent::__construct();
       	parent::makeTemplate("list.html");
    }
    
    public function doAction(){
      if (array_key_exists("deploy-engine",$_GET) && $engine = $_GET["deploy-engine"]) {
        $this->deploy($engine);
      }
      else if (array_key_exists("stop-building",$_GET) && $run = $_GET["stop-building"]) {
        $this->stop_building($run);
      }
      else if (array_key_exists("resume",$_GET) && $run = $_GET["resume"]) {
        $this->resume($run);
      }
      else if (array_key_exists("delete-run",$_GET) && $run = $_GET["delete-run"]) {
        $this->delete_run($run);
      }
      else if (array_key_exists("delete-engine",$_GET) && $engine = $_GET["delete-engine"]) {
        $this->delete_engine($engine);
      }
      else if (array_key_exists("download-engine",$_GET) && $engine = $_GET["download-engine"]) {
        $this->download_engine($engine);
      }
    }
    
    private function deploy($engine) {
      // set engine name (is read by start-mt-server.perl
      $handle = fopen("/opt/casmacat/engines/deployed","w");
      fwrite($handle,$engine."\n");
      fclose($handle);

      // restart MT and CAT server
      exec("/opt/casmacat/admin/scripts/start-mt-server.perl");
      exec("/opt/casmacat/admin/scripts/start-cat-server.sh");
      exec("/opt/casmacat/admin/scripts/update-language-setting-in-web-server.perl");
    }

    private function stop_building($run) {
      global $exp_dir;
      // get information about process tree
      exec("ps -o \"%p %P %a\"",$process);
      // pattern to match a running step
      $pattern = "/\/".$_GET["lp"]."\/steps\/$run\/(\S+\.$run)/";
      foreach ($process as $p) {
        if (preg_match("/^ *(\d+) +(\d+) +(.+)$/",$p,$match)) {
          if (preg_match($pattern,$match[3],$match2)) {
            $root = $match[1]; // one relevant process - still need to climb up
            $running_step[] = $match2[1];
          }
          $parent[$match[1]] = $match[2];
          $child[$match[2]][] = $match[1];
        } 
      } 
      // if there is a process matching the specified language pair and run number...
      if ($root) {
        // get the root of the process tree for the experiment
        while($parent[$root] != 1) {
          $root = $parent[$root];
        }
	// note steps as killed
        foreach ($running_step as $s) {
	  $noteKillCmd = "echo 'killed' >> $exp_dir/".$_GET["lp"]."/steps/$run/$s.STDERR.digest";
          exec($noteKillCmd);
        }
        // get all processes in the tree to be killed
        $process_list = $this->get_children($root,$child);
        $killCmd = "kill -9 $process_list"; 
        exec($killCmd);
	// mark run as stopped
	$touchCmd = "touch $exp_dir/".$_GET["lp"]."/steps/$run/stopped.$run";
        exec($touchCmd);
        $this->msg = "Stopped #$run + $killCmd + $touchCmd";
      }
    }

    private function get_children($parent,$child) {
      $list = " ".$parent;
      if (array_key_exists($parent,$child)) {
        foreach ($child[$parent] as $c) {
          $list .= $this->get_children($c,$child);
        }
      }
      return $list;
    }

    private function resume($run) {
      chdir("/opt/casmacat/experiment/".$_GET["lp"]);
      $prepCmd .= "export USER=www-data";
      $prepCmd .= " ; rm -f steps/$run/stopped.$run";
      $prepCmd .= " ; /opt/moses/scripts/ems/experiment.perl -delete-crashed $run -no-graph -exec";
      $prepCmd .= " ; touch steps/$run/running.$run";
      $continueCmd = "/opt/moses/scripts/ems/experiment.perl -continue $run -no-graph -max-active 1 -sleep 1 -exec > OUT.$run 2>&1 &";
      exec($prepCmd);
      exec($continueCmd);
      $this->msg = $prepCmd . " ; ".$continueCmd;
      chdir("/opt/casmacat/admin");
    }

    private function delete_run($run) {
      $deleteCmd = "cd /opt/casmacat/experiment/".$_GET["lp"]." ; /opt/moses/scripts/ems/experiment.perl -delete-run $run -no-graph -exec";
      exec($deleteCmd);
      $this->msg = $deleteCmd;
    }

    private function delete_engine($engine) {
      $deleteCmd = "rm -r /opt/casmacat/engines/$engine";
      exec($deleteCmd);
      $this->msg = "Deleted Engine $enigne.";
    }

    private function download_engine($engine) {
      $tarBall = "/opt/casmacat/engines/$engine-".rand().".tgz";
      $tarCmd = "cd /opt/casmacat/engines ; tar czf $tarBall $engine";
      exec($tarCmd);
      header("Content-type: application/gnutar");
      header("Content-length: ".filesize($tarBall));
      header("Content-disposition: attachment ; filename=\"mt-$engine.tgz\"");
      print readfile($tarBall);
      exec("rm $tarBall");
      exit();
    }

    private function init_lang_pair($source,$target) {
      global $language;
      $lang_pair = array();
      $lang_pair["name"] = $language[$source]."-".$language[$target];
      $lang_pair["source"] = $source;
      $lang_pair["target"] = $target;
      $lang_pair["has_engines"] = 0;
      $lang_pair["has_prototypes"] = 0;
      $lang_pair["inspect_link"] = "/inspect/?setup=".$this->lp2id["$source-$target"];;
      return $lang_pair;
    }

    public function setTemplateVars() {
      $list = array();
      $lang_pair_hash = array();
      global $exp_dir,$engine_dir;

      # get names of engines
      $setup_file = file("inspect/setup");
      foreach($setup_file as $line) {
        if (preg_match("/^(\d+).+\/([a-z]{2}\-[a-z]{2})$/",$line,$match)) {
          $id2lp[$match[1]] = $match[2];
          $this->lp2id[$match[2]] = $match[1];
        }
      }
      $comment_file = file("inspect/comment");
      foreach($comment_file as $line) {
        if (preg_match("/^(\d+)\-(\d+);(.+)/",$line,$match)) {
          $engine_name[$id2lp[$match[1]]][$match[2]] = $match[3];
        }
      }
 
      # which engine is deployed?
      $deployed_array = file("$engine_dir/deployed"); # todo read into single line
      $deployed = chop($deployed_array[0]);
 
      # get information about available engine
      $is_engine = array();
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
	    $info["name"] = $info_from_file["name"];
            if (preg_match('/upload-(\d+)/',$engine,$match)) {
              $info["run"] = "x".$match[1];
            }
            else if ($info["run"] > 0) {
              $is_engine[$key][$info["run"]] = 1;
              if ($info["name"] == "") {
	        $info["name"] = $engine_name[$key][$info["run"]];
              }
            }
            $info["time_started"] = pretty_time($info_from_file["time_started"]);
            $info["time_done"] = pretty_time($info_from_file["time_done"]);
	    $info["size"] = $info_from_file["size"];
            if ($engine == $deployed) {
	      $info["deployed"] = 1;
	      $info["available"] = 0;
	      $info["status"] = "deployed";
            }  
            else {
	      $info["deployed"] = 0;
	      $info["available"] = 1;
	      $info["action"] = "/?action=list&deploy-engine=$engine";
	      $info["status"] = "available";
            }
	    $info["delete"] = "/?action=list&delete-engine=$engine";
	    $info["download"] = "/?action=list&download-engine=$engine";
	    $info["not_available"] = 0;
            $lang_pair_hash[$key]["has_engines"] = 1;
            $lang_pair_hash[$key]["engines"][] = $info;
          }
        }
      }
      
      # get status of all prototypes
      if ($handle = opendir($exp_dir)) {
        while (false !== ($file = readdir($handle))) {
          if (preg_match("/([a-z]{2})-([a-z]{2})/",$file,$match)) {

            # process prototypes for one language pair
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
                  $run = $match[1];
		  $setup_id = $this->lp2id[$key];

                  # ignore deleted
                  if (file_exists("$lang_dir/steps/$run/deleted.$run")) {
                    continue;
                  }
 
                  # get info on prototype
		  $info = array();
		  $info["time_started"] = pretty_time(filectime("$lang_dir/steps/$run/config.$run"));
		  $info["run"] = $run;
	          $info["name"] = "<a id=\"run-name-$setup_id-$run\" href='javascript:createCommentBox(\"$setup_id-$run\");'>".$engine_name[$key][$run]."</a>";
                  $built = array_key_exists($key,$is_engine) && array_key_exists($run,$is_engine[$key]);
	          $info["delete"] = "/?action=list&delete-run=$run&lp=$source-$target";
		  $info["inspect_graph_link"] = "/inspect/?setup=$setup_id&show=graph.$run.png";
		  $info["action"] = "";

                  # successfully completed prototype
                  if (file_exists("$lang_dir/evaluation/report.$run")) {
                    $info["status"] = "done";
                    $info["time_done"] = pretty_time(filectime("$lang_dir/evaluation/report.$run"));
		    $info["action"] .= ($built) ? "" : "<a href=\"/?action=createEngine&input-extension=$source&output-extension=$target&run=$run&name=".urlencode($engine_name[$key][$run])."\">create engine</a>";
                  }

		  # various stages of building
                  else if (file_exists("$lang_dir/steps/$run/running.$run")) {

		    # stopped
                    if (file_exists("$lang_dir/steps/$run/stopped.$run")) {
                      $info["status"] = "stopped";
	              $info["action"] .= "<a href=\"/?action=list&resume=$run&lp=$source-$target\">resume</a>";
                    }
		
		    # actively building
                    else if (filectime("$lang_dir/steps/$run/running.$run")+60 > time()) {
	              $info["action"] .= "<a href=\"/?action=list&stop-building=$run&lp=$source-$target\">stop</a>";
                      $info["status"] = "building";
	 	      $info["delete"] = 0;
                    }

		    # crashed
                    else {
                      $info["status"] = "crashed";
                      $info["time_crashed"] = pretty_time(filectime("$lang_dir/steps/$run/running.$run"));
	              $info["action"] .= "<a href=\"/?action=list&resume=$run&lp=$source-$target\">resume</a>";
                    }
                  }

		  # not properly started -> old: misconfigured
                  else if (filectime("$lang_dir/steps/$run/config.$run") < time()-3600) {
                    $info["status"] = "misconfigured";
                  }

		  # ... -> new: still starting up
                  else {
                    $info["status"] = "starting";
		    $info["delete"] = 0;
                  }

                  # okay, it's a wrap, add it to the list
                  $lang_pair_hash[$key]["has_prototypes"] = 1;
                  $lang_pair_hash[$key]["prototypes"][] = $info;
                }
              }
            }
            if ($lang_pair_hash[$key]["has_engines"]) {
              usort($lang_pair_hash[$key]["engines"], 'run_cmp');
            }
            if ($lang_pair_hash[$key]["has_prototypes"]) {
              usort($lang_pair_hash[$key]["prototypes"], 'run_cmp');
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
      $this->template->msg = $this->msg;
    }
}
function run_cmp($a,$b) {
  if ($a["run"] == $b["run"]) { return 0; }
  return $a["run"] < $b["run"] ? 1 : -1;
}

?>
