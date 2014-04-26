<?php

class buildEngineController extends viewcontroller {
    private $msg = '';

    public function __construct() {
      parent::__construct();
      if (array_key_exists("do",$_GET)) {
        if ($_GET['do'] == 'corpus-table') {
       	  parent::makeTemplate("_corpusTable.html");
        }
      }
      else if (array_key_exists("submit-upload",$_POST)) {
        parent::makeTemplate("_generic.html");
      }
      else {
        parent::makeTemplate("buildEngine.html");
      }
    }
    
    public function doAction(){
      if (array_key_exists("submit-upload",$_POST)) {
        if (!$_FILES["file"]["error"]) {
          $name = $_POST["name"];
          if ($name == "") { $name = $_FILES["name"]; }
          $name = preg_replace("/'/","\"",$name);
          $processCmd = "scripts/process-xliff.perl ".$_POST["input-extension"]." ".$_POST["output-extension"]." ".$_FILES["file"]["tmp_name"]." '$name'";
          $this->msg = "Uploaded corpus $name";
	  exec($processCmd);
        }
      }
    }

    public function setLanguagePairSelect() {
      // get default language pair
      $default_source = "";
      $default_target = "";
      $max_time = 0;
      $msg = "";
      global $data_dir;
      if ($handle = opendir($data_dir)) {
        while (false !== ($file = readdir($handle))) {
          if (preg_match("/([a-z]{2})-([a-z]{2})/",$file,$match) && filectime("$data_dir/$file") > $max_time) {
            $max_time = filectime("$data_dir/$file");
            $default_source = $match[1];
            $default_target = $match[2];
          }
        }
      }
      $default_source = "";
      $default_target = "";
      
      global $language;
      $language[""] = "(select)";
      foreach($language as $code => $name) {
        $lang_info = array("code" => $code, "name" => $name);
        $lang_info["default_source"] = ($code == $default_source);
        $lang_info["default_target"] = ($code == $default_target);
        $lang_display[] = $lang_info;
      }
      function cmp($a,$b) {
         return strcmp($a["name"], $b["name"]);
      }
      usort($lang_display, 'cmp');
      $this->template->languages = $lang_display;
    }

    public function buildCorpusTable() {
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
            $corpus["upload_time"] = pretty_time($corpus["upload_time"]);
            $corpora[] = $corpus;
          }
        }
      }
      $this->template->corpora = $corpora;
      $this->template->haveCorpora = count($corpora);
      $this->template->haveNoCorpora = (count($corpora) == 0);
    }

    public function setTemplateVars() {
      if (array_key_exists("do",$_GET)) {
        if ($_GET['do'] == 'corpus-table') {
          $this->buildCorpusTable();
        }
      }
      else if (array_key_exists("submit-upload",$_POST)) {
        $this->template->msg = '<script>uploadComplete();</script>';
      }
      else {
        $this->setLanguagePairSelect();
      }
    }
}
?>
