<?php

class catsettingsController extends viewcontroller {
    private $msg = '';

    public function __construct() {
        parent::__construct();
       	parent::makeTemplate("catsettings.html");
    }
    
    public function doAction(){
      if (array_key_exists("do",$_POST)) {
        if ($_POST['do'] == 'update') {
          $cmd = "scripts/configure-web-server-config.perl";
          $cmd .= " -itpenabled ".($_POST["itpenabled"] ? 1 : 0); 
          $cmd .= " -srenabled ".($_POST["srenabled"] ? 1 : 0); 
          $cmd .= " -biconcorenabled ".($_POST["biconcorenabled"] ? 1 : 0); 
          $cmd .= " -hidecontributions ".($_POST["hidecontributions"] ? 1 : 0); 
          $cmd .= " -floatpredictions ".($_POST["floatpredictions"] ? 1 : 0); 
          $cmd .= " -translationoptions ".($_POST["translationoptions"] ? 1 : 0); 
          exec($cmd);
          $this->msg = "Updated.";
        }
      }
    }

    public function setTemplateVars() {
      $current = file("/opt/casmacat/web-server/inc/config.ini");
      foreach($current as $line) {
        if (preg_match("/itpenabled = (\d)/",$line,$match)) {
          $this->template->itpenabled = $match[1];
        }
        if (preg_match("/srenabled = (\d)/",$line,$match)) {
          $this->template->srenabled = $match[1];
        }
        if (preg_match("/biconcorenabled = (\d)/",$line,$match)) {
          $this->template->biconcorenabled = $match[1];
        }
        if (preg_match("/hidecontributions = (\d)/",$line,$match)) {
          $this->template->hidecontributions = $match[1];
        }
        if (preg_match("/floatpredictions = (\d)/",$line,$match)) {
          $this->template->floatpredictions = $match[1];
        }
        if (preg_match("/translationoptions = (\d)/",$line,$match)) {
          $this->template->translationoptions = $match[1];
        }
      } 
      $this->template->msg = $this->msg;
    }
}

?>
