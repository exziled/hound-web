<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class api extends MY_Controller {

	function  __construct()  {
		parent::__construct();
	}

	/**
	 * List all of the api endpoints
	 */
	public function index_get()
	{
		$me = get_class_methods($this);
		$parent = get_class_methods('MY_Controller');
		$this->response(array_diff($me, $parent), 200);
	}

	/**
	 * Get the properties of a device
	 * @param  num $id optional id of device to read information
	 */
	public function device_get($id=null)
	{
		if (is_null($id)) {
			$device = $this->device_model
			->get_all();
		} else {
			$device = $this->device_model
			->where('device_id',$id)
			->get();
		}

		$this->response($device, 200);
	}

	/**
	 * Handle the plural case
	 * @param  see above
	 */
	public function devices_get($id=null)
	{
		$this->device_get($id);
	}

	/**
	 * Receive data from the NodeJS EventManager
	 * @return json 201 code on success, 400 on error
	 */
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
				->select('program.device_id, devices.core_id')
				->join('devices', 'devices.device_id = program.device_id')
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

	/**
	 * Get the most recent sample for each socket of $device_id
	 * @param  num $device_id device of which to get sample for
	 */
	public function sample_get($device_id=null)
	{
		if ($device_id == null) {
			$this->response(array("status"=>"error", "message"=>"malformed input. Missing device_id parameter"), 400);
			return;
		}
		$data = $this->samples
			->select('socket, current, voltage, powerfactor, temperature, apparent_power, real_power')
			->where('device_id',$device_id)
			->order_by('sample_id desc')
			->limit(2)
			->get_all();
		$this->response($data, 200);
	}
}