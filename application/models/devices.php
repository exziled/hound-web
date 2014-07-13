<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Devices extends MY_Model {

	protected $table = "devices";
	protected $primary_key = "device_id";
	protected $fields = array(
		'user_id',
		'core_id',
		'name',
		'access_token',
		'form_factor',
		'date_activated'
	);

	function __construct()
	{
		// Call the Model constructor
		parent::__construct();
	}
}