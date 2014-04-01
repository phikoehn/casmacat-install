<?php

class indexController extends viewcontroller {
    private $cat_server_online = 0;
    private $mt_server_online = 0;

    public function __construct() {
        parent::__construct();
       	parent::makeTemplate("index.html");
    }
    
    public function doAction(){
      $ret = array();
      exec('/bin/ps -ef',$ret);
      foreach($ret as $line) {
        if (strpos($line,"/opt/casmacat/cat-server/cat-server.py --port 9999") !== false) {
          $this->cat_server_online++;
        }
        if (strpos($line,"/opt/moses/bin/mosesserver") !== false) {
          $this->mt_server_online++;
        }
        if (strpos($line,"/opt/casmacat/mt-server/python_server/server.py") !== false) {
          $this->mt_server_online++;
        }
      }
    }
    
    public function setTemplateVars() {
      global $ip;
      $this->template->show_start_cat_server = ! $this->cat_server_online;
      $this->template->show_start_mt_server = ($this->mt_server_online != 2);
      $this->template->show_translate_document = 
        ($this->cat_server_online == 1 && $this->mt_server_online == 2);
      $this->template->url = "http://$ip:8000/";
    }
}

?>
