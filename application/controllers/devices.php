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
			$name = $devices[$device]['Name'];
			$devices[$device]['Name'] = "<abbr title=\"".$devices[$device]['core_id']."\">".$devices[$device]['Name']."</abbr>";
			unset($devices[$device]['core_id']);
			$devices[$device]['Operations'] = "<a href=\"".site_url("/devices/edit/".$id)."\" title=\"Click to edit\">Edit</a>";
			$devices[$device]['Operations'] .= " | <a href=\"".site_url("/devices/details/".$id)."\" title=\"View details\">Details</a>";
			$devices[$device]['Operations'] .= " | <a href=\"".site_url("/devices/program/".$id)."\" title=\"Create/Update program\">Program</a>";
			$devices[$device]['Operations'] .= " | <a href=\"".site_url("/devices/remove/".$id)."\" title=\"Remove a device\" class=\"delbtn\" data-devname=\"$name\">Delete</a>"; //

			if ($devices[$device]['Last Checkin'] == "0000-00-00 00:00:00") {
				$devices[$device]['Last Checkin'] = "Checkin pending";
			} else {
				$devices[$device]['Last Checkin'] = $newDate = date("g:ia M jS, Y", strtotime($devices[$device]['Last Checkin']));
			}

			$date = $devices[$device]['Date Added'];
			$devices[$device]['Date Added'] = $newDate = date("g:ia M jS, Y", strtotime($date));

			$devices[$device]['kVAh Last 24hrs'] = $this->samples->getKWH24hrs($id);

			// unset($devices[$device]['Form Factor']);
			unset($devices[$device]['Sockets']);
			unset($devices[$device]['Last Checkin']);

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
		$this->twiggy->set('action_name', 'Add');
		$this->twiggy->set('slogan', 'What are we monitoring today?');
		$this->twiggy->display('devices_add_edit');
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
		$device = $this->device_model->where('device_id', $id)->get();
		// print_r($device);
		// return;


		$this->twiggy->title()->prepend('Edit a Device');
		$this->twiggy->set('action_name', 'Edit');
		$this->twiggy->set('slogan', 'What needs changing?');
		$this->twiggy->set('device', $device);
		$this->twiggy->display('devices_add_edit');
	}

	/**
	 * Handle submissions from the edit device page
	 */
	public function edit_post()
	{
		// echo "so you want to change that device do you?";
		$data = $this->input->post();
		// print_r($data);
		// return;
		$data['user_id'] = $this->user->user_data->id;

		$ret = $this->device_model

		->update($data['device_id'], $data);

		// echo $ret;
		if ($ret)
		{
			$this->session->set_message("Success",'Device changes saved.');
		}
		else
		{
			//@todo add better error message
			$this->session->set_message("Danger",'Unable to change device.');
		}
		redirect("/devices");
	}

	/**
	 * display details about a spesificc hound device
	 * @return [type]
	 */
	public function details_get($id)
	{
		$device = $this->device_model
			->where('device_id', $id)
			->get();

		$data = $this->samples->LastHourOfSamples($id);
		$stats = array();
		// $stats['kVA in past 24 hrs']= $this->samples->getKWH24hrs($id);
		// $stats['kVA in past 1 hr']= $this->samples->getKVA1hr($id);
		// $stats['kVA in past 30 min']= $this->samples->getKVA30min($id);
		$stats['Max in past 24hrs']= $this->samples->getMaxIVA24hr($id);
		$stats['Min in past 24hrs']= $this->samples->getMinIVA24hr($id);
		$stats['Avg in past 24hrs']= $this->samples->getAvgIVA24hr($id);
		// print_r($stats);
		// exit();
		$this->twiggy->set('stats', $stats);

		$this->twiggy->set('data_vrms', substr(json_encode($data['voltage']), 1, -1));
		$this->twiggy->set('data_irms', substr(json_encode($data['current']), 1, -1));
		$this->twiggy->set('data_app', substr(json_encode($data['apparent_power']), 1, -1));
		$this->twiggy->set('data_time', substr(json_encode($data['timestamp']), 1, -1));

		$this->twiggy->set('vrms', "...");
		$this->twiggy->set('irms', "...");
		$this->twiggy->set('real', "...");
		$this->twiggy->set('powerfactor', "...");
		$this->twiggy->set('apparent', "...");
		$this->twiggy->set('kWhToday', "...");

		$this->twiggy->set('device', $device);
		$this->twiggy->title()->prepend('Device Details');
		$this->twiggy->display('devices/details');
	}

	public function refresh_get($id)
	{
		// //lookup the core ID in the DB
		// $devices = $this->device_model
		// 	->where('device_id', $id)
		// 	->get();

		// $function = 'activate';
		// $url = $this->config->item('core_url');

		// $url = str_replace('$(FUNCTION)', $function, $url);
		// $url = str_replace('$(COREID)', $devices['core_id'], $url);
		// $url = str_replace('$(ACCESS_TOKEN)', $devices['access_token'], $url);
		// $url = trim($url);
		// die($url);
		// $response = curl_post($url);

		// $response = json_decode($response, true);
		// if (!is_null($response))
		// {
		// 	print_r($response);
		// 	if ($response['id'] == $devices['core_id']) {
		// 		if ($response['return_value'] == 0) {
		// 			//core subscription created
		// 		} else {
		// 			//set the core in an error state
		// 		}
		// 	}
		// }
	}
	public function remove_get($id)
	{
		$this->samples->delete(array('device_id' => $id));
		//@todo handle foreign key constraints
		//@todo Confirm the deletion with the user.
		if (!$this->device_model->delete(array('device_id' => $id)))
		{
			$this->session->set_message("Danger",'Unable to delete device.');
		}
		redirect('/devices');
	}

	public function program_get($id)
	{
		$device = $this->device_model->where('device_id', $id)->get();
		$code = $this->program->where('device_id', $id)->get();

		$this->twiggy->set('code', $code);
		$this->twiggy->set('device', $device);
		$this->twiggy->set('program_form_attrs', array('class' => 'dataform'));
		$this->twiggy->title()->prepend('Device Programming');
		$this->twiggy->display('devices/program');
	}

	public function program_post()
	{
		print_r($this->post());

		$success = $this->program->insertOrUpdate($this->post());

		if ($success){
			$this->session->set_message("Success",'Program Updated!');
			redirect('/devices');
		}else{
			$this->session->set_message("Danger",'Unable to update program.');
			redirect('/devices');
		}
	}
}