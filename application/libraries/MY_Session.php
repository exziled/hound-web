<?php    if ( ! defined('BASEPATH')) exit('No direct script access allowed');
class MY_Session extends CI_Session {

	function __construct()
	{
		parent::__construct();
	}
	var $message_types = array(
		'Success'=>'Success!',
		'Info'=>'Heads up!',
		'Warning'=>'Warning!',
		'Danger'=>'Oh snap!'
	);
	function set_message($type, $content)
	{
		if (array_key_exists($type, $this->message_types)) {
			$ci =& get_instance();
			$ci->session->set_flashdata('UI-'.strtoupper($type), $content); //@todo it would be nice if this could handle more than one message
		}
		else
		{
			die("Invalid type: ".$type); //this seems a bit extreme
		}

	}
	function render_messages()
	{
		//$type = "UI-ALL"
		$ci =& get_instance();
		$retval = "";
		foreach ($this->message_types as $type => $value) {
			$msgs = $ci->session->flashdata('UI-'.strtoupper($type));
			if (empty($msgs)) continue;
			$retval .= '<div class="flash alert alert-'.$type.'">';
			$retval .= '<strong>'.$value.'</strong>';
			//foreach
				$retval .= '<p>'.$msgs.'</p>';// style="margin:0"
			$retval .= '</div>';
		}
		return $retval;
	}
}