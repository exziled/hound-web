-- phpMyAdmin SQL Dump
-- version 4.0.6deb1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Oct 29, 2014 at 12:42 AM
-- Server version: 5.5.37-0ubuntu0.13.10.1
-- PHP Version: 5.5.3-1ubuntu2.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

--
-- Database: `srproj`
--

-- --------------------------------------------------------

--
-- Table structure for table `devices`
--

CREATE TABLE IF NOT EXISTS `devices` (
  `device_id` int(11) NOT NULL AUTO_INCREMENT,
  `core_id` varchar(36) NOT NULL,
  `name` varchar(64) NOT NULL,
  `access_token` varchar(64) NOT NULL,
  `form_factor` int(11) NOT NULL,
  `date_activated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `user_id` int(11) DEFAULT NULL,
  `last_checkin` datetime NOT NULL,
  PRIMARY KEY (`device_id`),
  KEY `fk_devices_users1_idx` (`user_id`),
  KEY `fk_devices_form_factor1_idx` (`form_factor`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=10 ;

-- --------------------------------------------------------

--
-- Table structure for table `devices_device_group`
--

CREATE TABLE IF NOT EXISTS `devices_device_group` (
  `devices_device_group_id` int(11) NOT NULL AUTO_INCREMENT,
  `device_id` int(11) DEFAULT NULL,
  `device_group_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`devices_device_group_id`),
  KEY `fk_devices_device_group_devices1_idx` (`device_id`),
  KEY `fk_devices_device_group_device_group1_idx` (`device_group_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=2 ;

-- --------------------------------------------------------

--
-- Table structure for table `device_group`
--

CREATE TABLE IF NOT EXISTS `device_group` (
  `device_group_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT NULL,
  `locaton` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`device_group_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=3 ;

-- --------------------------------------------------------

--
-- Table structure for table `form_factor`
--

CREATE TABLE IF NOT EXISTS `form_factor` (
  `form_factor_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `image_url` varchar(128) NOT NULL,
  `socket_count` int(11) NOT NULL,
  `release_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `description` varchar(256) NOT NULL,
  PRIMARY KEY (`form_factor_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=3 ;

-- --------------------------------------------------------

--
-- Table structure for table `permissions`
--

CREATE TABLE IF NOT EXISTS `permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(12) NOT NULL,
  `description` text NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `samples`
--

CREATE TABLE IF NOT EXISTS `samples` (
  `sample_id` int(11) NOT NULL AUTO_INCREMENT,
  `socket` int(11) NOT NULL,
  `timestamp` datetime NOT NULL,
  `device_id` int(11) NOT NULL,
  `current` double NOT NULL,
  `voltage` double NOT NULL,
  `powerfactor` float NOT NULL,
  `frequency` double NOT NULL,
  `temperature` float NOT NULL,
  `wifi_strength` int(11) NOT NULL,
  `apparent_power` double NOT NULL,
  `real_power` double NOT NULL,
  PRIMARY KEY (`sample_id`),
  KEY `fk_samples_sockets1_idx` (`device_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  `email` varchar(30) DEFAULT NULL,
  `login` varchar(18) NOT NULL,
  `password` varchar(60) NOT NULL,
  `last_login` date DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=7 ;

-- --------------------------------------------------------

--
-- Table structure for table `users_meta`
--

CREATE TABLE IF NOT EXISTS `users_meta` (
  `user_id` int(11) NOT NULL,
  `name` varchar(40) NOT NULL,
  `value` varchar(255) NOT NULL,
  KEY `user_id` (`user_id`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `users_permissions`
--

CREATE TABLE IF NOT EXISTS `users_permissions` (
  `user_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL,
  KEY `user_id` (`user_id`),
  KEY `permission_id` (`permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `devices`
--
ALTER TABLE `devices`
  ADD CONSTRAINT `devices_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `devices_ibfk_2` FOREIGN KEY (`form_factor`) REFERENCES `form_factor` (`form_factor_id`);

--
-- Constraints for table `devices_device_group`
--
ALTER TABLE `devices_device_group`
  ADD CONSTRAINT `devices_device_group_ibfk_1` FOREIGN KEY (`device_group_id`) REFERENCES `device_group` (`device_group_id`),
  ADD CONSTRAINT `devices_device_group_ibfk_2` FOREIGN KEY (`device_id`) REFERENCES `devices` (`device_id`);

--
-- Constraints for table `permissions`
--
ALTER TABLE `permissions`
  ADD CONSTRAINT `permissions_ibfk_1` FOREIGN KEY (`id`) REFERENCES `users_permissions` (`permission_id`);

--
-- Constraints for table `samples`
--
ALTER TABLE `samples`
  ADD CONSTRAINT `samples_ibfk_1` FOREIGN KEY (`device_id`) REFERENCES `devices` (`device_id`);

--
-- Constraints for table `users_meta`
--
ALTER TABLE `users_meta`
  ADD CONSTRAINT `users_meta_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `users_permissions`
--
ALTER TABLE `users_permissions`
  ADD CONSTRAINT `users_permissions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
