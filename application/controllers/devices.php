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

		foreach ($devices as $device => $prop) {

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

			unset($devices[$device]['Sockets']);
			unset($devices[$device]['Last Checkin']);
		}

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
		$data = $this->input->post();
		$data['user_id'] = $this->user->user_data->id;

		$success = $this->device_model->insert($data);
		if ($success) {
			$this->session->set_message("Success",'New device successfully added.');
		} else {
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
		$data = $this->input->post();

		$data['user_id'] = $this->user->user_data->id;

		$success = $this->device_model->update($data['device_id'], $data);

		if ($success)
		{
			$this->session->set_message("Success",'Device changes saved.');
		} else {
			$this->session->set_message("Danger",'Unable to change device.');
		}
		redirect("/devices");
	}

	/**
	 * display details about a spesificc hound device
	 * @return [type]
	 */
	public function details_get($id=null)
	{
		if ($id == null)
			redirect('/devices');
		$device = $this->device_model
			->where('device_id', $id)
			->get();

		$data = $this->samples->LastHourOfSamples($id);
		$vrms1 = array();
		$vrms2 = array();
		$irms1 = array();
		$irms2 = array();
		$app1 = array();
		$app2 = array();
		$time = array();

		foreach ($data as $idx => $el) {

			if ($el['socket'] == 0) {
				array_push($vrms1, $el['voltage']);
				array_push($irms1, $el['current']);
				array_push($app1, $el['apparent_power']);
			} else {
				array_push($vrms2, $el['voltage']);
				array_push($irms2, $el['current']);
				array_push($app2, $el['apparent_power']);
			}
			array_push($time, $el['timestamp']);
		}


		// the substring removes the [] so that the json can be embedded in a js array
		$this->twiggy->set('data_vrms1', substr(json_encode($vrms1), 1, -1));
		$this->twiggy->set('data_vrms2', substr(json_encode($vrms2), 1, -1));
		$this->twiggy->set('data_irms1', substr(json_encode($irms1), 1, -1));
		$this->twiggy->set('data_irms2', substr(json_encode($irms2), 1, -1));
		$this->twiggy->set('data_app1', substr(json_encode($app1), 1, -1));
		$this->twiggy->set('data_app2', substr(json_encode($app2), 1, -1));
		$this->twiggy->set('data_time', substr(json_encode($time), 1, -1));
		// $this->twiggy->set('data_time2', substr(json_encode($time2), 1. -1)));

		$stats = array();
		// $stats['kVA in past 24 hrs']= $this->samples->getKWH24hrs($id);
		// $stats['kVA in past 1 hr']= $this->samples->getKVA1hr($id);
		// $stats['kVA in past 30 min']= $this->samples->getKVA30min($id);
		$stats['Max in past 24hrs']= $this->samples->getMaxIVA24hr($id);
		$stats['Min in past 24hrs']= $this->samples->getMinIVA24hr($id);
		$stats['Avg in past 24hrs']= $this->samples->getAvgIVA24hr($id);

		$this->twiggy->set('stats', $stats);

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

	/**
	 * [remove_get description]
	 * @param  [type]
	 * @return [type]
	 */
	public function remove_get($id=null)
	{
		if ($id == null)
			redirect("/devices");

		//@todo handle foreign key constraints
		$this->samples->delete(array('device_id' => $id));
		$this->program->delete(array('device_id' => $id));

		if (!$this->device_model->delete(array('device_id' => $id)))
		{
			$this->session->set_message("Danger",'Unable to delete device.');
		}
		redirect('/devices');
	}

	/**
	 * Render the blockly programming interface. Load the user's previous program
	 * if one exists.
	 */
	public function program_get($id = null)
	{
		if ($id == null)
			redirect("/devices");
		$device = $this->device_model->where('device_id', $id)->get();
		$code = $this->program->where('device_id', $id)->get();

		$this->twiggy->set('code', $code);
		$this->twiggy->set('device', $device);
		$this->twiggy->set('program_form_attrs', array('class' => 'dataform'));
		$this->twiggy->title()->prepend('Device Programming');
		$this->twiggy->display('devices/program');
	}

	/**
	 * Store the users program in the database. Or update the current program.
	 */
	public function program_post()
	{
		$exists = $this->program
						->select("count(*) AS e")
						->where('device_id',$this->post('device_id'))
						->get();
		$exists = $exists['e'];

		$success = FALSE;
		if ($exists) {
			$success = $this->program->update($this->post('device_id'), $this->post());
		} else {
			$success = $this->program->insert($this->post());
		}

		if ($success){
			$this->session->set_message("Success",'Program Updated.');
			redirect('/devices');
		}else{
			$this->session->set_message("Danger",'Unable to update program.');
			redirect('/devices');
		}
	}
}