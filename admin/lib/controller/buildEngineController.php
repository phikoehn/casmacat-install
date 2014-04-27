<?php

class buildEngineController extends viewcontroller {
    private $msg = '';

    public function __construct() {
      parent::__construct();
      if (array_key_exists("do",$_GET) && $_GET['do'] == 'corpus-table') {
       	parent::makeTemplate("_corpusTable.html");
      }
      else if (array_key_exists("do",$_GET) && $_GET['do'] == 'upload') {
        parent::makeTemplate("_empty.html");
      }
      else {
        parent::makeTemplate("buildEngine.html");
      }
    }
    
    public function doAction(){
      if (array_key_exists("do",$_GET) && $_GET['do'] == 'upload') {
	$fileElementName = 'fileToUpload';
	if(!empty($_FILES[$fileElementName]['error'])) {
	  switch($_FILES[$fileElementName]['error']) {
       	    case '1':
		$error = 'The uploaded file exceeds the upload_max_filesize directive in php.ini';
		break;
	    case '2':
		$error = 'The uploaded file exceeds the MAX_FILE_SIZE directive that was specified in the HTML form';
		break;
  	    case '3':
		$error = 'The uploaded file was only partially uploaded';
		break;
	    case '4':
		$error = 'No file was uploaded.';
		break;
  	    case '6':
		$error = 'Missing a temporary folder';
		break;
	    case '7':
		$error = 'Failed to write file to disk';
		break;
	    case '8':
		$error = 'File upload stopped by extension';
		break;
  	    default:
		$error = 'No error code avaiable';
	   }
	}
        elseif(empty($_FILES['fileToUpload']['tmp_name']) || $_FILES['fileToUpload']['tmp_name'] == 'none') {
		$error = 'No file was uploaded..';
	}
        else {
	  $msg .= " File Name: " . $_FILES['fileToUpload']['name'] . ", ";
	  $msg .= " File Size: " . @filesize($_FILES['fileToUpload']['tmp_name']);
          $name = $_FILES['fileToUpload']['name'];
          $processCmd = "scripts/process-xliff.perl ".$_GET["input-extension"]." ".$_GET["output-extension"]." ".$_FILES["fileToUpload"]["tmp_name"]." '$name'";
          // $msg .= ", Command: " . $processCmd;
	  exec($processCmd);
	//for security reason, we force to remove all uploaded file
	//		@unlink($_FILES['fileToUpload']);		
	}		
	$this->msg = "{error: '" . $error . "',\nmsg: '" . $msg . "'\n}";

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

      $corpora = array();
      $dir = $data_dir."/".$_GET["input-extension"]."-".$_GET["output-extension"];
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
      if (array_key_exists("do",$_GET) && $_GET['do'] == 'corpus-table') {
        $this->buildCorpusTable();
      }
      else if (array_key_exists("do",$_GET) && $_GET['do'] == 'upload') {
        $this->template->msg = $this->msg;
      }
      else {
        $this->setLanguagePairSelect();
      }
    }
}
?>
