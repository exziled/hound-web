<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Devices extends MY_Controller {

	function __construct(){
		parent::__construct();

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
			$devices[$device]['Operations'] .= " | <a href=\"".site_url("/devices/details/".$id)."\" title=\"Click to view details\">Details</a>";
			$devices[$device]['Operations'] .= " | <a href=\"".site_url("/devices/refresh/".$id)."\" title=\"Click to request refresh\">Refresh</a>";

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
		// $url = " https://api.spark.io/v1/devices/48ff6c065067555026311387/tempc?access_token=b122a221bf419da7491e4fca108f1835a2794451";
		// echo $url;
		// print_r(parse_url($url));
		// exit();

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
		$url = trim($url);
		// echo $url;
		// exit();
		// 
		// $ch = curl_init();
		// curl_setopt($ch, CURLOPT_URL,"https://api.spark.io/v1/devices/" . $devices['core_id'] . "/$function");
		// curl_setopt($ch, CURLOPT_POST, 1);
		// curl_setopt($ch, CURLOPT_POSTFIELDS,"access_token=" . $devices['access_token']);
		// echo curl_exec ($ch);
		// curl_close ($ch);
		// 
		$response = curl_post($url);

		// $request = new HTTPRequest($url, 'POST');
		// // $request->setRawPostData(http_build_query($data));
		// $request->send();
		// $response = $request->getResponseBody();
		// echo $response;
		$response = json_decode($response, true);
		if (!is_null($response))
			print_r($response);
		// $response = $arrresponse;
	}
}