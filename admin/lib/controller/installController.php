<?php

class installController extends viewcontroller {
    public function __construct() {
        parent::__construct();
       	parent::makeTemplate("install.html");
    }
    
    public function doAction(){
    }
    
    public function setTemplateVars() {
    }
}

?>
