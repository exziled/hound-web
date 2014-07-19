<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Devices_model extends MY_Model {

	protected $table = "devices";
	protected $primary_key = "device_id";
	protected $fields = array(
		'device_id',
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

	public function getDevicesForUser($user_id)
	{
		$devices = $this->devices_model
			->select("device_id as ID")
			// ->select("Core_id as UUID")
			->select("devices.name as Name")
			->select("CONCAT(`form_factor`.`name`, ' (', `form_factor`.`socket_count`,')') as `Form Factor`",false)
			// ->select("CONCAT('a','b')")
			->select("date_activated as `Date Added`")
			->where('user_id',$this->user->user_data->id)
			->join('form_factor','devices.form_factor=form_factor.form_factor_id')
			->get_all();
		return $devices;
	}
}