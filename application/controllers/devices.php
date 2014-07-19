<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Devices extends MY_Controller {

	function __construct(){
		parent::__construct();

	}

	public function index_get()
	{
		$devices = $this->devices_model->getDevicesForUser($this->user->user_data->id);

		$this->twiggy->set('action', site_url("/devices/add"));
		$this->twiggy->set('devices', $devices);
		$this->twiggy->title()->prepend('Devices');
		$this->twiggy->display('devices');
	}

	public function add_get()
	{
		$this->twiggy->title()->prepend('Add Devices');
		$this->twiggy->display('devices_add');
	}
	public function add_post()
	{
		//@todo input validation

		$data = $this->input->post();
		$data['user_id'] = $this->user->user_data->id;

		$ret = $this->devices_model
			->insert($data);
		if ($ret)
		{
			$this->session->set_message("Success",'New device successfully added.');
		}
		else
		{
			//@todo add better error message
			$this->session->set_message("Danger",'Unable to add device.');
		}
		redirect("/devices");

	}
}