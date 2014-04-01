<?php

class uploadController extends viewcontroller {
    private $msg = '';
    public function __construct() {
        parent::__construct();
       	parent::makeTemplate("upload.html");
    }
    
    public function doAction(){
      if ($_POST["input-extension"] == $_POST["output-extension"]) {
        // better do that with javascript on form....
      }
      if (!$_FILES["file"]["error"]) {
        $processCmd = "scripts/process-xliff.perl ".$_POST["input-extension"]." ".$_POST["output-extension"]." ".$_FILES["file"]["tmp_name"]." ".$_FILES["file"]["name"];
        $this->msg = "Uploaded corpus ".$_FILES["file"]["name"];
      }
      exec($processCmd);
    }

    public function setTemplateVars() {
      global $language,$data_dir;
      $this->template->inputLanguage = $language[ $_POST["input-extension"] ];
      $this->template->inputExtension = $_POST["input-extension"];
      $this->template->outputLanguage = $language[ $_POST["output-extension"] ];
      $this->template->outputExtension = $_POST["output-extension"];

      $corpora = array();
      $dir = $data_dir."/".$_POST["input-extension"]."-".$_POST["output-extension"];
      if ($handle = opendir($dir)) {
        while (false !== ($entry = readdir($handle))) {
          if (preg_match("/(\d+)\.info/",$entry,$match)) {
            $corpus = array();
            $corpus["id"] = $match[1];
            $corpus["checkbox_name"] = "corpus-".$match[1];
            $info = file($dir."/".$entry);
            foreach($info as $line) {
              if (preg_match("/^(\S+) = (.+)/",$line,$match)) {
                $corpus[$match[1]] = $match[2];
              }
            } 
            $corpora[] = $corpus;
          }
        }
      }
      $this->template->corpora = $corpora;
      $this->template->msg = "hey!";
      $this->template->msg = $this->msg;
    }
}

?>
