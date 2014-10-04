<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Sockets extends MY_Model {

	protected $table = "samples";
	protected $primary_key = "sample_id";
	protected $fields = array(
		'socket_id',
		'device_id',
		'state',
	);

	function __construct()
	{
		// Call the Model constructor
		parent::__construct();
	}
}