<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Devices_device_group extends MY_Model {

	protected $table = "devices_device_group";
	protected $primary_key = "devices_device_group_id";
	protected $fields = array(
		'name',
		'location',
	);

	function __construct()
	{
		// Call the Model constructor
		parent::__construct();
	}
}