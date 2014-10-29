<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class api extends MY_Controller {

	function  __construct()  {
		parent::__construct();
	}

	public function index_get()
	{
		echo "API";
		// $this->post('fred')
	}

	public function device_get($id=null)
	{
		if (is_null($id))
		{
			$device = $this->device_model
			->get_all();
		}
		else
		{
			$device = $this->device_model
			->where('device_id',$id)
			->get();
		}

		$this->response($device, 200);
	}

	public function device_group_get($id=null)
	{
		if (is_null($id))
		{
			$device = $this->device_group
			->get_all();
		}
		else
		{
			$device = $this->device_group
			->where('device_group_id',$id)
			->get();
		}

		$this->response($device, 200);
	}
	public function devices_in_group_get($groupid=null)
	{
		if (is_null($groupid))
		{
			$this->response(array("status"=>"failure", "message"=>"Group ID required"), 400);
		}
		else
		{
			$devicesingrp = $this->device_model
				->join("devices_device_group AS map", "map.device_id = devices.device_id")
				->where('map.device_group_id',$groupid)
				->get_all();
			$this->response($devicesingrp, 200);
		}
	}

	public function samples_post()
	{
		if (!$this->_post_input_exists(array(
				's_id',
				't',
				'vrms',
				'irms',
				'app',
				'core_id'
			))) {
			$this->response(array("status"=>"error", "message"=>"malformed input"), 400);
			return;
		}
		$fields = array(
			's_id'=>'socket_id',
			'irms'=>'current',
			'vrms'=>'voltage',
			''=>'powerfactor',
			''=>'frequency',
			't'=>'temperature',
			''=>'wifi_strength',
			'app'=>'apparent_power',
			''=>'real_power'
		);

		$device_id = $this->device_model->coreid2deviceid($this->post('core_id'));
		$out = array();

		$numsamp = count($this->post('t'));
		for ($i=$numsamp-1; $i>=0  ; $i--) {
			$arr = array(
				'socket'=>$this->post('s_id'),
				'timestamp'=>date("Y-m-d H:i:s", $this->post('t')[$i]),
				'device_id'=>$device_id,
				'current'=>$this->post('irms')[$i],
				'voltage'=>$this->post('vrms')[$i],
				'powerfactor'=>0,
				'frequency'=>0,
				'temperature'=>0,
				'wifi_strength'=>0,
				'apparent_power'=>$this->post('app')[$i],
				'real_power'=>0
			);

			$ret = $this->samples->insert($arr);
			array_push($out, $ret);
		}

		if (count($out) == $numsamp) {
			$this->response(array("status"=>"success", "id"=>$out), 201);
		} else if (in_array(0, $out)) {
			$this->response(array("status"=>"partial success", "id"=>$out), 201);
		} else {
			$this->response(array("status"=>"error"), 400);
		}
	}

	public function samples2_post()
	{
		if (!$this->_post_input_exists(array(
				'socket_id',
				'current',
				'voltage',
				'powerfactor',
				'frequency',
				'temperature',
				'wifi_strength',
				'apparent_power',
				'useruuid',
				'real_power'
			))) {
			$this->response(array("status"=>"error", "message"=>"malformed input"), 400);
			return;
		}
		// print_r($this->post());
		// $this->response(array("status"=>"error", "message"=>"malformed input"), 400);
		if ($id = $this->samples->insert($this->post()))
		{
			$this->response(array("status"=>"success", "id"=>$id), 200);
		} else {
			$this->response(array("status"=>"error"), 400);
		}
	}

	public function core_data_post()
	{
		error_log("Core Data:".print_r($this->post()));
	}
}