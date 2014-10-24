<?php

class createEngineController extends viewcontroller {
    private $msg = '';
    public function __construct() {
        parent::__construct();
       	parent::makeTemplate("createEngine.html");
    }
    
    public function doAction(){
      // check if it is a Thot model
      $thot = "";
      $config = "/opt/casmacat/experiment/".$_GET["input-extension"]."-".$_GET["output-extension"]."/steps/".$_GET["run"]."/config.".$_GET["run"];
      $setup_file = file("inspect/setup");
      foreach(file($config) as $line) {
        if (preg_match("/^thot/",$line)) {
          $thot = "-thot";
        }
      }
      $createCmd = "scripts/create-engine$thot.perl -f ".$_GET["input-extension"]." -e ".$_GET["output-extension"]." -run ".$_GET["run"]." -name '".escapeshellarg($_GET["name"])."'";
      exec($createCmd);
      $this->msg = $createCmd;
    }

    public function setTemplateVars() {
      $this->template->msg = $this->msg;
    }
}

?>
