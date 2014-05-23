<?php

class buildController extends viewcontroller {
    private $msg = '';
    private $guid = '';
    public function __construct() {
        parent::__construct();
       	parent::makeTemplate("build.html");
    }
    
    public function doAction(){
      $buildCmd = "scripts/build-system.perl -f ".$_POST["input-extension"]." -e ".$_POST["output-extension"];

      $buildCmd .= " -tuning-corpus ".$_POST["tuning-corpus"];
      if ($_POST["tuning-select"] != "all") {
        $buildCmd .= " -tuning-select ".$_POST["tuning-count"];
      } 

      $buildCmd .= " -evaluation-corpus ".$_POST["evaluation-corpus"];
      if ($_POST["evaluation-select"] != "all") {
        $buildCmd .= " -evaluation-select ".$_POST["evaluation-count"];
      } 

      $name = $_POST["name"];
      if ($name == "") { $name = "not named"; }
      $name = preg_replace("/'/","\"",$name);
      $buildCmd .= " -name '$name'";

      foreach($_POST["corpus"] as $corpus ) {
        $buildCmd .= " -corpus $corpus";
      }

      $_POST["previous-settings"] = ""; # TODO: delete array element instead
      $buildCmd .= " -info '".json_encode($_POST)."'";

      $buildCmd .= " >/tmp/build_status &";

      exec($buildCmd);
      $this->msg = $buildCmd;
    }

    public function setTemplateVars() {
      $this->template->msg = $this->msg;
    }
}

?>
