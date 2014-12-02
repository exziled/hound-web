<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Program extends MY_Model {

	protected $table = "program";
	protected $primary_key = "device_id";
	protected $fields = array(
		'device_id',
		'xml',
		'javascript',
	);

	function __construct()
	{
		// Call the Model constructor
		parent::__construct();
	}
}