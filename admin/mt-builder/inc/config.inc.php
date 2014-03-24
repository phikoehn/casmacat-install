<?php

class INIT {
    private static $instance;

    public static $DEBUG;
    public static $ERROR_REPORTING;

    public static $ROOT;
    public static $BASE_URL;
    public static $TEMPLATE_ROOT;
    public static $MODEL_ROOT;
    public static $CONTROLLER_ROOT;
    public static $UTILS_ROOT;
    public static $UPLOAD_ROOT;
    public static $ENABLED_BROWSERS;
    public static $BUILD_NUMBER;

    public static function obtain() {
        if (!self::$instance) {
            self::$instance = new INIT();
        }
        return self::$instance;
    }

     private function __construct() {
        // Read general config from INI file
        global $_INI_FILE;

        $root = realpath(dirname(__FILE__).'/../');
        self::$ROOT = $root;  // Accesible by Apache/PHP

        self::$BASE_URL = "/mt-builder/";

	set_include_path(get_include_path() . PATH_SEPARATOR . $root);

        self::$TEMPLATE_ROOT = self::$ROOT . "/lib/view";
        self::$MODEL_ROOT = self::$ROOT . '/lib/model';
        self::$CONTROLLER_ROOT = self::$ROOT . '/lib/controller';
        self::$UTILS_ROOT = self::$ROOT . '/lib/utils';
        self::$UPLOAD_ROOT = self::$ROOT . "/" . $_INI_FILE['ui']['uploads'];

	self::$ENABLED_BROWSERS=array('chrome','firefox','safari');
	self::$BUILD_NUMBER='0.0.1';
    }
}

INIT::obtain(); // initializes static variables in any case

?>
