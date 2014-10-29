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
}