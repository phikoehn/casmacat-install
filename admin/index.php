<?php
error_reporting(-1);
ini_set("display_errors", 1);

require_once 'inc/config.inc.php';
require_once 'lib/utils/globals.php';

INIT::obtain();

require_once INIT::$CONTROLLER_ROOT.'/frontController.php';
$dispatcher= controllerDispatcher::obtain();
$controller=$dispatcher->getController();
$controller->doAction();

$parentController=get_parent_class($controller);

switch ($parentController){
	case 'ajaxcontroller':
		$controller->echoJSONResult();
		break;
	case 'viewcontroller':
		$controller->executeTemplate();
		break;
	case 'downloadController':
		$controller->download();
}
?>
