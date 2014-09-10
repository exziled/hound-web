<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Device_model extends MY_Model {

	protected $table = "devices";
	protected $primary_key = "device_id";
	protected $fields = array(
		'device_id',
		'user_id',
		'core_id',
		'name',
		'access_token',
		'form_factor',
		'date_activated',
		'last_checkin'
	);

	function __construct()
	{
		// Call the Model constructor
		parent::__construct();
	}

	public function getDevicesForUser($user_id, $count=false)
	{
		if ($count) {
			$devices = $this
				->where('user_id',$user_id)
				->count_all_results();
			return $devices;
		} else {
			$devices = $this
				->select("device_id as ID")
				// ->select("Core_id as 'Core ID'")
				->select("devices.name as Name")
				//->select("CONCAT(`form_factor`.`name`, ' (', `form_factor`.`socket_count`,')') as `Form Factor`",false)
				->select("`form_factor`.`name` as `Form Factor`")
				->select("`form_factor`.`socket_count` as `Sockets`")
				->select("date_activated as `Date Added`")
				->select("last_checkin as `Last Checkin`")
				->where('user_id',$user_id)
				->join('form_factor','devices.form_factor=form_factor.form_factor_id')
				->get_all();

			echo $this->db->last_query();
			return $devices;
		}
	}
}