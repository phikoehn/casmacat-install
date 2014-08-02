<?php

class uploadEngineController extends viewcontroller {
    private $msg = '';

    public function __construct() {
      parent::__construct();
      parent::makeTemplate("uploadEngine.html");
    }
    
    public function doAction(){
      ini_set('post_max_size', '1024M');
      if (array_key_exists("do",$_POST) && $_POST["do"] == "upload") {
        $this->upload();
      }
    }

    public function upload() {
      // catch some upload errors (does not work)
      if ($_FILES['engine']['error'] != UPLOAD_ERR_OK) {
        switch ($_FILES['engine']['error']) {
          case UPLOAD_ERR_NO_FILE:
            $this->msg = 'Upload failed: No file sent.';
        case UPLOAD_ERR_INI_SIZE:
        case UPLOAD_ERR_FORM_SIZE:
            $this->msg = 'Upload failed: Exceeded filesize limit.';
        default:
            $this->msg = 'Upload failed: Unknown errors.';
        }
        $this->msg .= "<br>Crash!";
        return;
      }
      
      // get the uploaded file into the /tmp directory
      $engine = "/tmp/uploaded-engine-".rand().".tgz";
      move_uploaded_file($_FILES["engine"]["tmp_name"],$engine);
      // various sanity checks
      exec("tar tzf $engine",$output);
      if (count($output) == 0) {
        $this->msg = "Upload failed: Not an engine.";
        unlink($engine);
        return;
      }
      $dir = "";
      $has_run_file = 0;
      $moses_ini = "";
      foreach ($output as $file) {
        if (!preg_match('/^([^\/]+)\/(.*)$/',$file,$match)) {
          $this->msg .= "<br>Bad file: ".$file;
        }
        else {
          if ($dir == "") {
            $dir = $match[1];
          }
          else if ($dir != $match[1]) {
            $this->msg .= "<br>Engine contains multiple directories: $dir and $match[1]";
          } 
          if ($match[2] == "RUN") {
            $has_run_file = 1;
          }
          else if (preg_match('/^moses.*ini*/',$match[2])) {
            $moses_ini = $match[2];
          }
        }
      }
      if (! $has_run_file) {
        $this->msg .= "<br>No RUN file in engine.";
      }
      if ($moses_ini == "") {
        $this->msg .= "<br>No moses.ini file in engine.";
      }
      if ($this->msg != "") {
        $this->msg = "Upload failed:".$this->msg;
        unlink($engine);
        return;
      }
      // okay, all's fine, let's move it into the engine directory
      exec("cd /tmp ; tar xzf $engine");
      unlink($engine);
      if (! file_exists("/opt/casmacat/engines/$dir")) {
        exec("mv /tmp/$dir /opt/casmacat/engines");
      }
      else {
        $rand = rand(1000,9999);
        while(file_exists("/opt/casmacat/engines/$dir-$rand")) {
          $rand = rand(1000,9999);
        }
        exec("mv /tmp/$dir /opt/casmacat/engines/upload-$dir-$rand");
        $this->fixDirInFile("/opt/casmacat/engines/upload-$dir-$rand/RUN","/opt/casmacat/engines/$dir","/opt/casmacat/engines/upload-$dir-$rand");
        $this->fixDirInFile("/opt/casmacat/engines/upload-$dir-$rand/moses.ini","/opt/casmacat/engines/$dir","/opt/casmacat/engines/upload-$dir-$rand");
      }
      $this->msg = "Successfully uploaded";
    }

    private function fixDirInFile($file,$old,$new) {
      $content = file($file);
      $handle = fopen($file,"w");
      foreach ($content as $line) {
        $line = str_replace($old,$new,$line);
        fwrite($handle, $line);
      }
      fclose($handle);
    }

    public function setTemplateVars() {
      $this->template->msg = $this->msg;
    }

}
?>
