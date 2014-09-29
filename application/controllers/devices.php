<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Devices extends MY_Controller {

	function __construct(){
		parent::__construct();
		$this->user->on_invalid_session('/');
	}

	/**
	 * Display a list of the users devices
	 */
	public function index_get()
	{
		$devices = $this->device_model->getDevicesForUser($this->user->user_data->id);
		// print_r($devices);
		// exit();
		foreach ($devices as $device => $prop) {
			// echo $devices[$device]['ID'];
			$id = $devices[$device]['ID'];
			unset($devices[$device]['ID']);
			// $devices[$device]['Name'] = "<a href=\"".site_url("/devices/edit/".$id)."\" title=\"Click to edit\">".$devices[$device]['Name']."</a>";
			$devices[$device]['Operations'] = "<a href=\"".site_url("/devices/edit/".$id)."\" title=\"Click to edit\">Edit</a>";
			$devices[$device]['Operations'] .= " | <a href=\"".site_url("/devices/details/".$id)."\" title=\"View details\">Details</a>";
			$devices[$device]['Operations'] .= " | <a href=\"".site_url("/devices/refresh/".$id)."\" title=\"Request Status Update\">Refresh</a>";
			$devices[$device]['Operations'] .= " | <a href=\"".site_url("/devices/remove/".$id)."\" title=\"Remove a device\">Delete</a>";

			if ($devices[$device]['Last Checkin'] == "0000-00-00 00:00:00") {
				$devices[$device]['Last Checkin'] = "Checkin pending";
			} else {
				$devices[$device]['Last Checkin'] = $newDate = date("g:ia M jS, Y", strtotime($devices[$device]['Last Checkin']));
			}

			$date = $devices[$device]['Date Added'];
			$devices[$device]['Date Added'] = $newDate = date("g:ia M jS, Y", strtotime($date));

		}
		// print_r($devices);
		// exit();

		$this->twiggy->set('action', site_url("/devices/add"));
		$this->twiggy->set('devices', $devices);
		$this->twiggy->title()->prepend('Devices');
		$this->twiggy->display('devices');
	}

	/**
	 * Display the add device page
	 */
	public function add_get()
	{
		$this->twiggy->title()->prepend('Add Devices');
		$this->twiggy->display('devices_add');
	}

	/**
	 * Handle submissions from the add device page
	 */
	public function add_post()
	{
		//@todo input validation

		$data = $this->input->post();
		$data['user_id'] = $this->user->user_data->id;

		$ret = $this->device_model
			->insert($data);
		if ($ret)
		{
			$this->session->set_message("Success",'New device successfully added.');
			//@todo send post to spark core


		}
		else
		{
			//@todo add better error message
			$this->session->set_message("Danger",'Unable to add device.');
		}
		redirect("/devices");

	}
	/**
	 * Display the device edit page
	 */
	public function edit_get($id)
	{
		echo "here";
	}

	/**
	 * Handle submissions from the edit device page
	 */
	public function edit_post()
	{
		echo "so you want to change that device do you?";
	}

	/**
	 * display details about a spesificc hound device
	 * @return [type]
	 */
	public function details_get($id)
	{
		echo $id;
	}

	public function refresh_get($id)
	{
		//lookup the core ID in the DB
		$devices = $this->device_model
			->where('device_id', $id)
			->get();

		$function = 'activate';
		$url = $this->config->item('core_url');

		$url = str_replace('$(FUNCTION)', $function, $url);
		$url = str_replace('$(COREID)', $devices['core_id'], $url);
		$url = str_replace('$(ACCESS_TOKEN)', $devices['access_token'], $url);
		$url = trim($url);
		die($url);
		$response = curl_post($url);

		$response = json_decode($response, true);
		if (!is_null($response))
		{
			print_r($response);
			if ($response['id'] == $devices['core_id']) {
				if ($response['return_value'] == 0) {
					//core subscription created
				} else {
					//set the core in an error state
				}
			}
		}

	}
}