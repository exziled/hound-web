<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Devices extends MY_Controller {

	function __construct(){
		parent::__construct();

	}

	public function index_get()
	{
		$devices = $this->device_model->getDevicesForUser($this->user->user_data->id);
		// print_r($devices);
		// exit();
		foreach ($devices as $device => $prop) {
			// echo $devices[$device]['ID'];
			$id = $devices[$device]['ID'];
			unset($devices[$device]['ID']);
			$devices[$device]['Name'] = "<a href=\"".site_url("/devices/edit")."\" title=\"Click to edit\">".$devices[$device]['Name']."</a>";

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

		$ret = $this->device_model
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
	// 	$url = "https://api.spark.io/v1/devices/48ff6c065067555026311387/tempc?access_token=b122a221bf419da7491e4fca108f1835a2794451";
	// 	print_r(parse_url($url));
	// 	exit();

		$devices = $this->device_model
			->where('device_id', $id)
			->get();
		// print_r($devices);
		// exit();

		$function = 'tempc';//'activate';
		$url = $this->config->item('core_url');

		$url = str_replace('$(FUNCTION)', $function, $url);
		$url = str_replace('$(COREID)', $devices['core_id'], $url);
		$url = str_replace('$(ACCESS_TOKEN)', $devices['access_token'], $url);
		// echo $url;

		$request = new HTTPRequest($url, 'POST');
		// $request->setRawPostData(http_build_query($data));
		$request->send();
		$response = $request->getResponseBody();
		echo $response;
		// $arrresponse = json_decode($response);
		// if (!is_null($arrresponse))
		// $response = $arrresponse;
	}
}