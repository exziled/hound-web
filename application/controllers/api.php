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
	public function devices_get($id=null)
	{
		$this->device_get($id);
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
			$this->response(array("status"=>"error", "message"=>"malformed input", "debug"=>$this->input->post()), 400);
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
		if ($device_id == null) {
			$this->response(array("status"=>"error", "message"=>"Core is currently unregistered", "core_id"=>$this->post('core_id')), 400);
			return;
		}
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

	public function getKWH24hrs_get ($device_id=null)
	{
		if (is_null($device_id)){
			$this->response(array('status'=>'error', 'msg'=>'ID required'), 400);
		}
		$data = $this->samples->getKWH24hrs($device_id);
		$this->response($data, 200);
	}
	public function getKVA1hr_get ($device_id=null)
	{
		if (is_null($device_id)){
			$this->response(array('status'=>'error', 'msg'=>'ID required'), 400);
		}
		$data = $this->samples->getKVA1hr($device_id);
		$this->response($data, 200);
	}
	public function getKVA30min_get ($device_id=null)
	{
		if (is_null($device_id)){
			$this->response(array('status'=>'error', 'msg'=>'ID required'), 400);
		}
		$data = $this->samples->getKVA30min($device_id);
		$this->response($data, 200);
	}
	public function getMaxIVA24hr_get ($device_id=null)
	{
		if (is_null($device_id)){
			$this->response(array('status'=>'error', 'msg'=>'ID required'), 400);
		}
		$data = $this->samples->getMaxIVA24hr($device_id);
		$this->response($data, 200);
	}
	public function getMinIVA24hr_get ($device_id=null)
	{
		if (is_null($device_id)){
			$this->response(array('status'=>'error', 'msg'=>'ID required'), 400);
		}
		$data = $this->samples->getMinIVA24hr($device_id);
		$this->response($data, 200);
	}
	public function getAvgIVA24hr_get ($device_id=null)
	{
		if (is_null($device_id)){
			$this->response(array('status'=>'error', 'msg'=>'ID required'), 400);
		}
		$data = $this->samples->getAvgIVA24hr($device_id);
		$this->response($data, 200);
	}
	public function LastHourOfSamples_get ($device_id=null)
	{
		if (is_null($device_id)){
			$this->response(array('status'=>'error', 'msg'=>'ID required'), 400);
		}
		$data = $this->samples->LastHourOfSamples($device_id);
		$this->response($data, 200);
	}

	public function control_post()
	{
		if ($this->_post_input_exists(array(
				'socket',
				'status',
			))) {
			if ($this->_post_input_exists(array('device_id')) || $this->_post_input_exists(array('core_id'))) {
				// we have device_id or core_id and {socket, status}
				$core_id = $this->post('core_id');
				if ($this->_post_input_exists(array('device_id'))) {
					$core_id = $this->device_model->deviceid2coreid($this->post('device_id'));
				}
				$action = array(
					'core_id'=>$core_id,
					'socket'=>$this->post('socket'),
					'status'=>$this->post('status'),
				);
				curl_post(); //@todo
				$this->response(array('status'=>'success'), 200);
			}
		}
		$this->response(array("status"=>"error", "message"=>"malformed input"), 400);
	}

	/**
	 * Get the program for a device, or get a list of devices with programs
	 * @param  id of the device of which to get program. When no supplied a list
	 * of all of the devices with programs will be returned.
	 * @return a devices program, or a list of devices with programs.
	 */
	public function program_get($id=null)
	{
		if ($id == null || !is_numeric($id)) {
			// List of devices with programs
			$data = $this->program
				->select('device_id')
				->where('xml <> ""')
				->get_all();
			$this->response($data, 200);
		} else {
			// Singular program
			$data = $this->program
				->select('program.*, devices.core_id')
				->join('devices', 'devices.device_id = program.device_id')
				->where('xml <> ""')
				->where('devices.device_id',$id)
				->get();
			$this->response($data, 200);
		}
	}
}