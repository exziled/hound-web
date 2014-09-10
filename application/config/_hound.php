<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');


$config['core_url'] = ' https://api.spark.io/v1/devices/$(COREID)/$(FUNCTION)?access_token=$(ACCESS_TOKEN)'; //include trailing slash

$config['min_pw_len'] = 5;
$config['min_username_len'] = 3;

$CI =& get_instance();
$CI->load->helper('url');
$config['forgot_msg'] = '<a href="'.site_url('/forgot').'">Did you forget your password?</a>';


