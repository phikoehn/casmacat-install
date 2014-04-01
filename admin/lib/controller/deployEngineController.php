<?php

class deployEngineController extends viewcontroller {
    private $msg = '';
    public function __construct() {
        parent::__construct();
       	parent::makeTemplate("deployEngine.html");
    }
    
    public function doAction(){
      $engine = $_GET["engine"];
      $handle = fopen("/opt/casmacat/engines/deployed","w");
      fwrite($handle,$engine."\n");
      fclose($handle);
      $this->msg = "$engine deployed";
    }

    public function setTemplateVars() {
      $this->template->msg = $this->msg;
    }
}

?>
