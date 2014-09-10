-- phpMyAdmin SQL Dump
-- version 4.0.6deb1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Sep 10, 2014 at 08:43 PM
-- Server version: 5.5.37-0ubuntu0.13.10.1
-- PHP Version: 5.5.3-1ubuntu2.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

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
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=8 ;

--
-- Dumping data for table `devices`
--

INSERT INTO `devices` (`device_id`, `core_id`, `name`, `access_token`, `form_factor`, `date_activated`, `user_id`, `last_checkin`) VALUES
(2, '', 'Fred', '', 1, '2014-07-13 18:05:01', 1, '0000-00-00 00:00:00'),
(3, '', 'Nope', '', 2, '2014-07-13 18:23:27', 4, '0000-00-00 00:00:00'),
(4, 'dd', 'dd', 'dd', 0, '2014-07-13 21:16:19', 4, '0000-00-00 00:00:00'),
(5, '', 'test', '', 0, '2014-07-19 15:17:33', 4, '0000-00-00 00:00:00'),
(6, '', 'ted', '', 0, '2014-07-20 15:44:02', 4, '0000-00-00 00:00:00'),
(7, '48ff6c065067555026311387', 'CorePlex', 'b122a221bf419da7491e4fca108f1835a2794451', 0, '2014-09-09 19:23:55', 4, '0000-00-00 00:00:00');

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

--
-- Dumping data for table `devices_device_group`
--

INSERT INTO `devices_device_group` (`devices_device_group_id`, `device_id`, `device_group_id`) VALUES
(1, 2, 1);

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

--
-- Dumping data for table `device_group`
--

INSERT INTO `device_group` (`device_group_id`, `name`, `locaton`) VALUES
(1, 'your mom''s room', 'fu'),
(2, 'Your mom''s room', 'joe');

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

--
-- Dumping data for table `form_factor`
--

INSERT INTO `form_factor` (`form_factor_id`, `name`, `image_url`, `socket_count`, `release_date`, `description`) VALUES
(0, 'Unknown', '', 0, '2014-07-20 15:53:53', ''),
(1, 'Outlet', '', 2, '2014-07-13 20:35:55', ''),
(2, 'Power Strip', '', 10, '2014-07-13 20:36:01', '');

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
  `socket_id` int(11) NOT NULL,
  `current` double NOT NULL,
  `voltage` double NOT NULL,
  `powerfactor` float NOT NULL,
  `frequency` double NOT NULL,
  PRIMARY KEY (`sample_id`),
  KEY `fk_samples_sockets1_idx` (`socket_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `sockets`
--

CREATE TABLE IF NOT EXISTS `sockets` (
  `socket_id` int(11) NOT NULL AUTO_INCREMENT,
  `device_id` int(11) NOT NULL,
  `state` int(11) NOT NULL,
  PRIMARY KEY (`socket_id`),
  KEY `fk_sockets_devices1_idx` (`device_id`)
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
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=5 ;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `login`, `password`, `last_login`, `active`) VALUES
(1, 'Administrator', 'admin@localhost', 'admin', '$2a$12$SR04o2/JNV5ZoVGZNgPiiezqM2f5D0eVDXsSDoWcfQqg/mST6O6Ye', '2014-07-20', 1),
(4, '', '', 'techplex', '$2a$12$x0swrPtQ3g1BRwyu8VuK9.4nQC95tHj6BsDFLKcKjYwT79AJrHOOa', '2014-09-09', 1);

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
  ADD CONSTRAINT `samples_ibfk_1` FOREIGN KEY (`socket_id`) REFERENCES `sockets` (`socket_id`);

--
-- Constraints for table `sockets`
--
ALTER TABLE `sockets`
  ADD CONSTRAINT `sockets_ibfk_1` FOREIGN KEY (`device_id`) REFERENCES `devices` (`device_id`);

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

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
