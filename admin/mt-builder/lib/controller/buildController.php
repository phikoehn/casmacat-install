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
      foreach($_POST["corpus"] as $corpus ) {
        $buildCmd .= " -corpus $corpus";
      }
      //exec($buildCmd);
      $this->msg = $buildCmd;
    }

    public function setTemplateVars() {
      $this->template->msg = $this->msg;
    }
}

?>
