<?php

class buildController extends viewcontroller {
    private $msg = '';
    private $guid = '';
    public function __construct() {
        parent::__construct();
       	parent::makeTemplate("build.html");
    }
    
    public function doAction(){
      $buildCmd = "scripts/build-system.perl -f ".$_POST["input-extension"]." -e ".$_POST["output-extension"]." -tuning-set ".$_POST["tuning-set"]." -evaluation-set ".$_POST["evaluation-set"];

      $name = $_POST["name"];
      if ($name == "") { $name = "not named"; }
      $name = preg_replace("/'/","\"",$name);
      $buildCmd .= " -name '$name'";

      foreach($_POST["corpus"] as $corpus ) {
        $buildCmd .= " -corpus $corpus >/tmp/build_status &";
      }

      exec($buildCmd);
      $this->msg = $buildCmd;
    }

    public function setTemplateVars() {
      $this->template->msg = $this->msg;
    }
}

?>
