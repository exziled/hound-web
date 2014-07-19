<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

require_once(APPPATH.'/core/REST_Controller.php');

abstract class MY_Controller extends REST_Controller  {

	public function __construct ()  {
		parent::__construct();

		$name = "H.O.U.N.D.";
		$abbr = '<abbr title="Home Online Utility iNformaton Dashboard">'.$name.'</abbr>';
		$this->twiggy->title($name.' (Home Online Utility iNformaton Dashboard)');
		$this->twiggy->set('static', base_url()."application/static", TRUE);
		$this->twiggy->set('proj_name', $name, TRUE);
		$this->twiggy->set('proj_name_abbr', $abbr, TRUE);
		$this->twiggy->set('proj_tagline', "Home Online Utility iNformaton Dashboard", TRUE);
		$this->twiggy->set('proj_company', "Techplex Labs", TRUE);
		$this->twiggy->set('page_login', site_url("login/validate"), TRUE);
		$this->twiggy->set('messages', $this->session->render_messages(), TRUE);


		//user stuff
		$temp = (array)$this->user->user_data;
		if (isset($temp) && !empty($temp))
		{
			unset($temp["password"]);
			//print_r($temp);
			$this->twiggy->set('user_data', $temp, TRUE);
			$this->twiggy->set('user_permission', $this->user->user_permission, TRUE);
		}

		$this->twiggy->register_function('site_url');

		//from: print_r($temp); above
		// Array
		// (
		// 	[id] => 1
		// 	[name] => Administrator
		// 	[email] => admin@localhost
		// 	[login] => admin
		// 	[last_login] => 2014-07-13
		// 	[active] => 1
		// )
	}
}