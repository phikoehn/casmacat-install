<?php

class indexController extends viewcontroller {
    private $guid = '';
    public function __construct() {
        parent::__construct();
       	parent::makeTemplate("index.html");
    }
    
    public function doAction(){
    }
    
    public function setTemplateVars() {
        $this->template->upload_session_id = $this->guid;
    }
}

?>
