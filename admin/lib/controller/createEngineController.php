<?php

class createEngineController extends viewcontroller {
    private $msg = '';
    public function __construct() {
        parent::__construct();
       	parent::makeTemplate("createEngine.html");
    }
    
    public function doAction(){
      $createCmd = "scripts/create-engine.perl -f ".$_GET["input-extension"]." -e ".$_GET["output-extension"]." -run ".$_GET["run"];
      //exec($createCmd);
      $this->msg = $createCmd;
    }

    public function setTemplateVars() {
      $this->template->msg = $this->msg;
    }
}

?>
