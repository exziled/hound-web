<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Start extends MY_Controller {

	public function __construct()
	{
		parent::__construct();
	}

	/**
	 * The page new users are sent to
	 */
	public function index_get()
	{
		// $this->load->view('welcome_message');
		$this->twiggy->title()->prepend('Start');
		$this->twiggy->set('hidelogin', true);
		$this->twiggy->display('start');
	}
}