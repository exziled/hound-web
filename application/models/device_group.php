<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Device_group extends MY_Model {

	protected $table = "device_group";
	protected $primary_key = "device_group_id";
	protected $fields = array(
		'device_id',
		'device_group_id',
	);

	function __construct()
	{
		// Call the Model constructor
		parent::__construct();
	}
}