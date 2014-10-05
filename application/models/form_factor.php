<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Form_factor extends MY_Model {

	protected $table = "form_factor";
	protected $primary_key = "form_factor_id";
	protected $fields = array(
		'form_factor_id',
		'name',
		'image_url',
		'socket_count',
		'release_date',
		'description'
	);

	function __construct()
	{
		// Call the Model constructor
		parent::__construct();
	}
}