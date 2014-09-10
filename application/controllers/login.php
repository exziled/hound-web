<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');

class Login extends MY_Controller {

	function __construct(){
		parent::__construct();

		// Load the Library
		$this->load->library(array('user', 'user_manager'));
		$this->load->helper('url');
	}

	public function index_get()
	{
		// If user is already logged in, send them to dashboard
		$this->user->on_valid_session('/dashboard');

		// Let's just have login from the homepage
		redirect("/");
	}
	public function user_get()
	{
		$this->user->on_invalid_session('/');

		// $key = $this->user->user_data->uuid;
		// if (empty($key)) {
		// 	$numtex = 0; //@todo really should be an error
		// 	die("Fatal error: Key not set.");
		// }
		// else
		// {
		// 	$numtex = $this->texture
		// 		->where("server",$key)
		// 		//->limit($rows, $offset)
		// 		->order_by('timestamp')
		// 		->count_all_results();
		// }
		$this->twiggy->set('numNodes', $this->device_model->getDevicesForUser($this->user->user_data->id, true)); //@todo get this from database
		$this->twiggy->title()->prepend('Dashboard');
		$this->twiggy->display('dashboard');
	}

	// public function private_page(){
	// 	// if user tries to direct access it will be sent to index
	// 	//$this->user->on_invalid_session('login');

	// 	// ... else he will view home
	// 	$this->load->view('home');
	// }

	public function validate_post()
	{
		// Receives the login data
		$login = $this->input->post('login');
		$password = $this->input->post('password');

		/*
		 * Validates the user input
		 * The user->login returns true on success or false on fail.
		 * It also creates the user session.
		*/
		if($this->user->login($login, $password)){
			$this->session->set_message("Success","Logged in as ".$this->user->user_data->login);
			// Success
			redirect('dashboard');
		} else {
			// Oh, holdon sir.
			$this->session->set_message("Danger","Invalid username or password.");
			redirect('/');
		}
	}

	// Simple logout function
	public function logout_get()
	{
		// Remove user session.
		$this->user->destroy_user();

		// Bye, thanks! :)
		$this->session->set_message("Success",'You are now logged out.');
		redirect('/'); //redirect to homepage
	}
	public function register_get()
	{
		$this->user->on_valid_session("/dashboard");
		$this->twiggy->set('hidelogin', TRUE);
		$this->twiggy->set('username', $this->session->flashdata('REG-username'));
		$this->twiggy->display('register');

	}
	public function register_post()
	{
		$minpwlen = $this->config->item('min_pw_len');
		$minuserlen = $this->config->item('min_username_len');

		$error = FALSE;

		if ($this->user_manager->login_exists($this->input->post('username'))) //does not exist
		{
			$this->session->set_message("Danger",'That username is already registered. Did you forget your password?'.site_url('/login/forgot'));
			$error = TRUE;
		}
		if ($this->input->post('username')) {
			$this->session->set_message("Danger",'Username required');
			$error = TRUE;
		}
		if (strlen($this->input->post('username')) < $minuserlen) {
			$this->session->set_message("Danger",'Username must be at least '.$minuserlen.' characters');
			$error = TRUE;
		}

		if ($this->input->post('password')) {
			$this->session->set_message("Danger",'Password required');
			$error = TRUE;
		}
		if ($this->input->post('password') != $this->input->post('passwordverify')) {
			$this->session->set_message("Danger",'Passwords do not match.');
			$error = TRUE;
		}
		if (strlen($this->input->post('password')) < $minpwlen) {
			$this->session->set_message("Danger",'Password must be at least '.$minpwlen.' characters');
			$error = TRUE;
		}

		


		if ($error) {
			$this->session->set_flashdata('REG-username', $this->input->post('username'));
			redirect("/register");
		}
		else
		{
			$newuserid = $this->user_manager->save_user("", $this->input->post('username'), $this->input->post('password'), "");
			if ($newuserid) {
				//Log the user in
				$this->user->login($this->input->post('username'), $this->input->post('password'));
				$this->session->set_message("Success", "Account Created! Welcome ".$this->input->post('username'));
				redirect("/dashboard");
			}
			else
			{
				echo "There was an error creating your account. An Administrator has been notified.";
				//@todo tell an admin
			}
		}
	}

}
?>
