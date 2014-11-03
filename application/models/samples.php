<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Samples extends MY_Model {

	protected $table = "samples";
	protected $primary_key = "sample_id";
	protected $fields = array(
		'sample_id',
		'socket',
		'timestamp',
		'device_id',
		'current',
		'voltage',
		'powerfactor',
		'frequency',
		'temperature',
		'wifi_strength',
		'apparent_power',
		'real_power'
	);

	function __construct()
	{
		// Call the Model constructor
		parent::__construct();
	}

	public function getKWH24hrs($device_id)
	{
		$sql = "SELECT round((sum(apparent_power)*24)/1000,2) as kwh,round((sum(apparent_power)/count(*))*24/1000,3) as VAh FROM `samples` WHERE device_id = $device_id AND TIMESTAMP > DATE_SUB( NOW( ) , INTERVAL 24 HOUR )";
		// print $sql;
		$query = $this->db->query($sql);
		$data = $query->result_array();
		// print_r($data);
		return $data[0]['VAh'];
	}

	public function getKVA1hr($device_id)
	{
		$sql = "SELECT round((sum(apparent_power)*24)/1000,2) as kwh,round((sum(apparent_power)/count(*))*24/1000,3) as VAh FROM `samples` WHERE device_id = $device_id AND TIMESTAMP > DATE_SUB( NOW( ) , INTERVAL 1 HOUR )";
		// print $sql;
		$query = $this->db->query($sql);
		$data = $query->result_array();
		// print_r($data);
		return $data[0]['VAh'];
	}

	public function getKVA30min($device_id)
	{
		$sql = "SELECT round((sum(apparent_power)*24)/1000,2) as kwh,round((sum(apparent_power)/count(*))*24/1000,3) as VAh FROM `samples` WHERE device_id = $device_id AND TIMESTAMP > DATE_SUB( NOW( ) , INTERVAL 30 MINUTE )";
		// print $sql;
		$query = $this->db->query($sql);
		$data = $query->result_array();
		// print_r($data);
		return $data[0]['VAh'];
	}

	public function getMaxIVA24hr($device_id)
	{
		$sql = "SELECT round(max(current),2) as i, round(max(voltage),2) as v, round(max(apparent_power),2) as a FROM `samples` WHERE device_id = $device_id AND TIMESTAMP > DATE_SUB( NOW( ) , INTERVAL 24 HOUR )";
		// print $sql;
		$query = $this->db->query($sql);
		$data = $query->result_array();
		// print_r($data);
		return $data[0];
	}

	public function getMinIVA24hr($device_id)
	{
		$sql = "SELECT round(min(current),2) as i, round(min(voltage),2) as v, round(min(apparent_power),2) as a FROM `samples` WHERE device_id = $device_id AND TIMESTAMP > DATE_SUB( NOW( ) , INTERVAL 24 HOUR )";
		// print $sql;
		$query = $this->db->query($sql);
		$data = $query->result_array();
		// print_r($data);
		return $data[0];
	}

	public function getAvgIVA24hr($device_id)
	{
		$sql = "SELECT round(avg(current),2) as i, round(avg(voltage),2) as v, round(avg(apparent_power),2) as a FROM `samples` WHERE device_id = $device_id AND TIMESTAMP > DATE_SUB( NOW( ) , INTERVAL 24 HOUR )";
		// print $sql;
		$query = $this->db->query($sql);
		$data = $query->result_array();
		// print_r($data);
		return $data[0];
	}

	public function LastHourOfSamples($device_id)
	{
		// $device_id = $this->device_model->coreid2deviceid($coreid);
		// return $device_id;
		$sql = "SELECT voltage,current,apparent_power,timestamp FROM samples WHERE device_id = $device_id AND TIMESTAMP > DATE_SUB( NOW( ) , INTERVAL 30 MINUTE )";
		// echo $sql;
		$query = $this->db->query($sql);
		$data = $query->result_array();

		$data_fixed = array(
			'voltage'=>array_map(function($el) {
			    return $el["voltage"];
			}, $data),
			'current'=>array_map(function($el) {
			    return $el["current"];
			}, $data),
			'apparent_power'=>array_map(function($el) {
			    return $el["apparent_power"];
			}, $data),
			'timestamp'=>array_map(function($el) {
			    return $el["timestamp"];
			}, $data),
		);
		return $data_fixed;
	}
}