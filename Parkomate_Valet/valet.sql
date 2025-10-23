CREATE DATABASE  IF NOT EXISTS `valet` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `valet`;
-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: localhost    Database: valet
-- ------------------------------------------------------
-- Server version	8.0.43

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `car_details`
--

DROP TABLE IF EXISTS `car_details`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `car_details` (
  `car_no` varchar(50) NOT NULL,
  `valet_id` varchar(50) NOT NULL,
  `site_no` int NOT NULL DEFAULT '1',
  `parking_spot` varchar(50) DEFAULT NULL,
  `driver_assigned_for_parking` varchar(50) DEFAULT NULL,
  `driver_assigned_for_bringing` varchar(50) DEFAULT NULL,
  `status` enum('none','in_request','assigned_parking','parked','out_request','assigned_bringing','brought_to_client','handed_over') DEFAULT 'none',
  `timestamp_car_in_request` datetime DEFAULT NULL,
  `timestamp_car_out_request` datetime DEFAULT NULL,
  `timestamp_parked` datetime DEFAULT NULL,
  `timestamp_driver_assigned` datetime DEFAULT NULL,
  `timestamp_car_brought` datetime DEFAULT NULL,
  `timestamp_car_handed_over` datetime DEFAULT NULL,
  PRIMARY KEY (`car_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `car_details`
--

LOCK TABLES `car_details` WRITE;
/*!40000 ALTER TABLE `car_details` DISABLE KEYS */;
INSERT INTO `car_details` VALUES ('BL03bh321','456',1,'BX123','dr1','dr1','handed_over','2025-09-13 04:33:49','2025-09-13 04:35:01','2025-09-13 04:34:23','2025-09-13 04:35:13','2025-09-13 04:35:23','2025-09-13 04:35:36'),('BR01hn2314','VAL004',1,'BZ345','dr1','dr1','handed_over','2025-09-13 04:26:06','2025-09-13 04:27:07','2025-09-13 04:26:49','2025-09-13 04:32:14','2025-09-13 04:32:22','2025-09-13 04:32:31'),('FE09GH7070','VALL',1,'axbv','dr1','dr1','handed_over','2025-09-13 05:27:13','2025-09-13 05:29:25','2025-09-13 05:28:44','2025-09-13 05:29:39','2025-09-13 05:29:54','2025-09-13 05:30:06'),('gh50hk3201','66677',1,'bhha','dr1','dr1','handed_over','2025-09-14 03:02:36','2025-09-14 03:07:16','2025-09-14 03:04:28','2025-09-14 03:07:27','2025-09-14 03:07:50','2025-09-14 03:08:14'),('gj09dgh','489',1,'asd','dr1','dr1','handed_over','2025-09-17 14:33:45','2025-09-17 14:36:58','2025-09-17 14:34:55','2025-09-17 14:37:19','2025-09-17 14:38:28','2025-09-17 14:38:47'),('hhhhh3333','333',1,'wwww','dr1','dr1','handed_over','2025-09-14 03:55:41','2025-09-14 04:00:12','2025-09-14 03:56:47','2025-09-14 04:00:20','2025-09-14 04:01:58','2025-09-14 04:02:21'),('hm23fg5090','09990',1,'klllk','dr1',NULL,'parked','2025-09-14 02:51:28',NULL,'2025-09-14 02:53:41','2025-09-14 02:52:29',NULL,NULL),('jk02fe555','666',1,'ghhg','dr1','dr1','handed_over','2025-09-13 14:16:02','2025-09-13 14:22:57','2025-09-13 14:21:03','2025-09-13 14:23:11','2025-09-13 14:23:58','2025-09-13 14:25:57'),('lu09hn1234','5050',1,NULL,NULL,NULL,'in_request','2025-09-13 06:26:02',NULL,NULL,NULL,NULL,NULL),('m01ac6092','999',1,'bbc','dr1','dr1','handed_over','2025-09-15 23:48:37','2025-09-15 23:51:28','2025-09-15 23:50:23','2025-09-15 23:51:49','2025-09-15 23:52:27','2025-09-15 23:53:05'),('mh01010101','0101',1,NULL,'dr1','dr1','handed_over','2025-09-13 03:06:01','2025-09-13 04:24:52','2025-09-13 03:33:37','2025-09-13 04:25:08','2025-09-13 04:30:18','2025-09-13 04:30:35'),('MH01GJ0987','vd2',1,'HOME','dr1','dr1','handed_over','2025-09-17 13:16:13','2025-09-17 13:24:39','2025-09-17 13:23:55','2025-09-17 13:24:51','2025-09-17 13:25:15','2025-09-17 13:25:42'),('mh04hm0321','214',1,'BZXyui','dr1','dr1','handed_over','2025-09-13 03:02:18','2025-09-18 05:03:45','2025-09-13 04:31:34','2025-09-18 05:04:05','2025-09-18 05:04:09','2025-09-18 05:04:15'),('mh04hm03212','6666',1,NULL,NULL,NULL,'in_request','2025-09-18 05:14:11',NULL,NULL,NULL,NULL,NULL),('mh04hm0322','2142',1,'asd','dr1','dr1','handed_over','2025-09-18 04:59:53','2025-09-18 05:05:07','2025-09-18 05:01:31','2025-09-18 05:05:17','2025-09-18 05:05:36','2025-09-18 05:05:44'),('mh04kj4563','Val456',1,'abcd','dr1','dr1','handed_over','2025-09-13 16:04:07','2025-09-13 16:08:18','2025-09-13 16:07:46','2025-09-13 16:09:07','2025-09-13 16:09:38','2025-09-13 16:09:49'),('MH12AB1234','VAL001',1,'1234','dr1','dr1','handed_over',NULL,'2025-09-13 04:36:46','2025-09-13 04:36:11','2025-09-13 04:36:55','2025-09-13 04:37:07','2025-09-13 04:37:16'),('MH12CD5678','VAL002',1,NULL,'dr1','dr1','handed_over',NULL,'2025-09-13 04:18:05','2025-09-13 03:39:31','2025-09-13 04:18:48','2025-09-13 04:19:05',NULL),('MH21HM4567','VAL1000',1,'BXY210','dr1','dr1','handed_over','2025-09-13 04:39:36','2025-09-13 04:40:59','2025-09-13 04:40:31','2025-09-13 04:41:15','2025-09-13 04:41:26','2025-09-13 04:41:38'),('RJ04kl2554','VAL424',1,NULL,NULL,NULL,'in_request','2025-09-13 14:42:10',NULL,NULL,NULL,NULL,NULL),('uk201','val777',1,'bx210','dr1',NULL,'parked','2025-09-13 04:09:21',NULL,'2025-09-13 04:11:58','2025-09-13 04:10:49',NULL,NULL),('uk20134','val777',1,'BX212','dr1',NULL,'parked','2025-09-13 04:09:29',NULL,'2025-09-13 04:24:13','2025-09-13 04:10:56',NULL,NULL),('up65fe0123','val456',1,NULL,NULL,NULL,'in_request','2025-09-13 04:09:09',NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `car_details` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `car_details_1`
--

DROP TABLE IF EXISTS `car_details_1`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `car_details_1` (
  `car_no` varchar(50) NOT NULL,
  `valet_id` varchar(50) NOT NULL,
  `site_no` int DEFAULT '1',
  `parking_spot` varchar(50) DEFAULT NULL,
  `driver_assigned_for_parking` varchar(50) DEFAULT NULL,
  `driver_assigned_for_bringing` varchar(50) DEFAULT NULL,
  `status` enum('none','in_request','assigned_parking','parked','out_request','assigned_bringing','brought_to_client','handed_over') DEFAULT 'none',
  `timestamp_car_in_request` datetime DEFAULT NULL,
  `timestamp_car_out_request` datetime DEFAULT NULL,
  `timestamp_parked` datetime DEFAULT NULL,
  `timestamp_driver_assigned` datetime DEFAULT NULL,
  `timestamp_car_brought` datetime DEFAULT NULL,
  `timestamp_car_handed_over` datetime DEFAULT NULL,
  `seen_parking` tinyint(1) DEFAULT '0',
  `timestamp_seen_parking` datetime DEFAULT NULL,
  `seen_bringing` tinyint(1) DEFAULT '0',
  `timestamp_seen_bringing` datetime DEFAULT NULL,
  `phone_number` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`car_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `car_details_1`
--

LOCK TABLES `car_details_1` WRITE;
/*!40000 ALTER TABLE `car_details_1` DISABLE KEYS */;
INSERT INTO `car_details_1` VALUES ('BL03bh321','val456',1,NULL,NULL,NULL,'in_request','2025-09-18 07:23:36',NULL,NULL,NULL,NULL,NULL,0,NULL,0,NULL,NULL),('BN56DF6675','765',1,'tyyg','dr2',NULL,'parked','2025-09-21 18:49:29',NULL,'2025-09-21 18:51:00','2025-09-21 18:50:03',NULL,NULL,0,NULL,0,NULL,NULL),('BR01hn2314','214',1,'BZ345','dr1',NULL,'parked','2025-09-18 07:24:16',NULL,'2025-09-19 09:42:33','2025-09-19 09:39:10',NULL,NULL,1,'2025-09-19 09:42:19',0,NULL,NULL),('Hr09kl8907','345',1,'gfhhj','dr1',NULL,'parked','2025-09-21 08:40:20',NULL,'2025-09-21 18:48:12','2025-09-21 18:46:45',NULL,NULL,0,NULL,0,NULL,NULL),('HR56Gh3442','609',1,'ghhvvg','dr1',NULL,'parked','2025-09-21 19:41:27',NULL,'2025-09-23 09:29:36','2025-09-21 19:41:57',NULL,NULL,1,'2025-09-23 09:29:28',0,NULL,NULL),('jk02fe555','667',1,NULL,NULL,NULL,'in_request','2025-09-18 07:17:57',NULL,NULL,NULL,NULL,NULL,0,NULL,0,NULL,NULL),('jk02fe5554','568',1,'454dfsdf5','dr1',NULL,'parked','2025-09-18 07:24:58',NULL,'2025-10-06 06:33:10','2025-09-18 08:29:09',NULL,NULL,1,'2025-10-06 06:33:04',0,NULL,NULL),('jk02fe5556','454',1,'ggyhb','dr2',NULL,'parked','2025-09-19 09:33:40',NULL,'2025-09-23 09:45:54','2025-09-19 09:38:52',NULL,NULL,1,'2025-09-23 09:45:51',0,NULL,NULL),('jk02fe666','2323',1,NULL,NULL,NULL,'in_request','2025-09-23 16:32:07',NULL,NULL,NULL,NULL,NULL,0,NULL,0,NULL,NULL),('MH 11 DB 5176','ENteL',1,'fsfd','dr2',NULL,'parked','2025-09-22 13:13:16',NULL,'2025-10-06 06:33:37','2025-09-22 13:13:52',NULL,NULL,1,'2025-10-06 06:33:31',0,NULL,NULL),('MH 12Hj 6785','23',1,'asfffb','dr2',NULL,'parked','2025-09-22 13:26:54',NULL,'2025-10-06 06:33:30','2025-09-23 09:45:31',NULL,NULL,1,'2025-10-06 06:33:22',0,NULL,NULL),('mh01010101','576',1,NULL,NULL,NULL,'in_request','2025-09-18 07:19:19',NULL,NULL,NULL,NULL,NULL,0,NULL,0,NULL,NULL),('mh04hm0321','666',1,NULL,NULL,NULL,'in_request','2025-09-18 07:17:20',NULL,NULL,NULL,NULL,NULL,0,NULL,0,NULL,NULL),('mh04hm03211','456',1,NULL,NULL,NULL,'in_request','2025-09-18 07:21:42',NULL,NULL,NULL,NULL,NULL,0,NULL,0,NULL,NULL),('Th67Gh6762','62',1,NULL,NULL,NULL,'in_request','2025-09-23 17:49:01',NULL,NULL,NULL,NULL,NULL,0,NULL,0,NULL,NULL),('TM09Hk5678','987',1,'yuij','dr2',NULL,'parked','2025-09-21 19:05:07',NULL,'2025-09-21 19:06:31','2025-09-21 19:05:32',NULL,NULL,0,NULL,0,NULL,NULL),('ty67gg7789','467',1,'5hghs','dr1',NULL,'parked','2025-09-23 07:20:07',NULL,'2025-09-23 09:38:32','2025-09-23 09:38:07',NULL,NULL,1,'2025-09-23 09:38:27',0,NULL,NULL),('up65fe0123','0101',1,NULL,NULL,NULL,'in_request','2025-09-18 07:21:01',NULL,NULL,NULL,NULL,NULL,0,NULL,0,NULL,NULL),('up65fe01235','6662',1,NULL,NULL,NULL,'in_request','2025-10-06 06:37:03',NULL,NULL,NULL,NULL,NULL,0,NULL,0,NULL,'1234567890');
/*!40000 ALTER TABLE `car_details_1` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `car_details_2`
--

DROP TABLE IF EXISTS `car_details_2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `car_details_2` (
  `car_no` varchar(50) NOT NULL,
  `valet_id` varchar(50) NOT NULL,
  `site_no` int NOT NULL DEFAULT '2',
  `phone_number` varchar(20) DEFAULT NULL,
  `status` enum('in_request','assigned_parking','parked','out_request','assigned_bringing','brought_to_client','handed_over') NOT NULL DEFAULT 'in_request',
  `parking_spot` varchar(50) DEFAULT NULL,
  `driver_assigned_for_parking` varchar(50) DEFAULT NULL,
  `driver_assigned_for_bringing` varchar(50) DEFAULT NULL,
  `seen_parking` tinyint(1) DEFAULT '0',
  `timestamp_seen_parking` datetime DEFAULT NULL,
  `seen_bringing` tinyint(1) DEFAULT '0',
  `timestamp_seen_bringing` datetime DEFAULT NULL,
  `timestamp_car_in_request` datetime DEFAULT CURRENT_TIMESTAMP,
  `timestamp_driver_assigned` datetime DEFAULT NULL,
  `timestamp_parked` datetime DEFAULT NULL,
  `timestamp_car_out_request` datetime DEFAULT NULL,
  `timestamp_car_brought` datetime DEFAULT NULL,
  `timestamp_car_handed_over` datetime DEFAULT NULL,
  PRIMARY KEY (`car_no`,`site_no`),
  UNIQUE KEY `unique_valet` (`valet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `car_details_2`
--

LOCK TABLES `car_details_2` WRITE;
/*!40000 ALTER TABLE `car_details_2` DISABLE KEYS */;
INSERT INTO `car_details_2` VALUES ('22Bh6783aa','090',2,'9087654321','in_request',NULL,NULL,NULL,0,NULL,0,NULL,'2025-09-23 10:08:12',NULL,NULL,NULL,NULL,NULL),('AS56GH9766','66',2,'8765432190','in_request',NULL,NULL,NULL,0,NULL,0,NULL,'2025-09-23 16:25:36',NULL,NULL,NULL,NULL,NULL),('Bh66Gh7786','827',2,'1234567890','in_request',NULL,NULL,NULL,0,NULL,0,NULL,'2025-09-23 09:58:20',NULL,NULL,NULL,NULL,NULL),('BL03bh321','0101',2,'1234567890','parked','fgh','dr1',NULL,1,'2025-09-23 17:30:47',0,NULL,'2025-09-19 06:10:13','2025-09-19 09:17:21','2025-09-23 17:30:51',NULL,NULL,NULL),('BR01hn2314','456',2,'1234567890','parked','BZ#$%','dr2',NULL,1,'2025-09-19 09:16:21',0,NULL,'2025-09-19 06:10:43','2025-09-19 09:15:55','2025-09-19 09:16:28',NULL,NULL,NULL),('DL67TY5456','55',2,'9876543210','in_request',NULL,NULL,NULL,0,NULL,0,NULL,'2025-09-23 16:25:12',NULL,NULL,NULL,NULL,NULL),('GJ03Jh6709','999',2,'8765432190','in_request',NULL,NULL,NULL,0,NULL,0,NULL,'2025-09-19 12:29:22',NULL,NULL,NULL,NULL,NULL),('Hj78Bh7827','928',2,'0123456789','assigned_parking',NULL,'dr2',NULL,1,'2025-09-23 09:59:57',0,NULL,'2025-09-23 09:59:10','2025-09-23 09:59:28',NULL,NULL,NULL,NULL),('Hr08hh7887','345',2,'856974321','parked','yghhu','dr1',NULL,1,'2025-09-23 10:02:41',0,NULL,'2025-09-21 08:55:49','2025-09-23 09:59:39','2025-09-23 10:02:46',NULL,NULL,NULL),('HR66FG4554','54',2,'555555555','in_request',NULL,NULL,NULL,0,NULL,0,NULL,'2025-09-23 17:09:42',NULL,NULL,NULL,NULL,NULL),('jk02fe555','215',2,NULL,'in_request',NULL,NULL,NULL,0,NULL,0,NULL,'2025-09-19 05:38:05',NULL,NULL,NULL,NULL,NULL),('jk02fg4444','0102',2,NULL,'parked','sdf56','dr1',NULL,1,'2025-09-19 09:05:55',0,NULL,'2025-09-19 06:13:32','2025-09-19 09:05:48','2025-09-19 09:06:05',NULL,NULL,NULL),('mh04hm000','200',2,NULL,'in_request',NULL,NULL,NULL,0,NULL,0,NULL,'2025-09-19 05:45:02',NULL,NULL,NULL,NULL,NULL),('mh04hm0321','214',2,'1234567890','in_request',NULL,NULL,NULL,0,NULL,0,NULL,'2025-09-19 05:36:09',NULL,NULL,NULL,NULL,NULL),('mh04hm0322','2142',2,'1234567890','in_request',NULL,NULL,NULL,0,NULL,0,NULL,'2025-09-19 05:36:29',NULL,NULL,NULL,NULL,NULL),('mh04kl4579','211',2,'1234567890','in_request',NULL,NULL,NULL,0,NULL,0,NULL,'2025-09-19 05:42:33',NULL,NULL,NULL,NULL,NULL),('Sw54fh7886','743',2,NULL,'assigned_parking',NULL,'dr1',NULL,0,NULL,0,NULL,'2025-09-23 17:04:34','2025-09-23 17:31:35',NULL,NULL,NULL,NULL),('TM09SD1234','243',2,'000000000','assigned_parking',NULL,'dr2',NULL,0,NULL,0,NULL,'2025-09-23 16:30:58','2025-09-23 17:31:40',NULL,NULL,NULL,NULL),('ty78bh7878','297',2,'31515484846','in_request',NULL,NULL,NULL,0,NULL,0,NULL,'2025-09-23 07:22:06',NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `car_details_2` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `driver_sessions`
--

DROP TABLE IF EXISTS `driver_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `driver_sessions` (
  `session_id` int NOT NULL AUTO_INCREMENT,
  `driver_id` varchar(50) DEFAULT NULL,
  `site_no` int DEFAULT NULL,
  `driver_name` varchar(100) DEFAULT NULL,
  `driver_photo` text,
  `login_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `logout_time` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `driver_sessions`
--

LOCK TABLES `driver_sessions` WRITE;
/*!40000 ALTER TABLE `driver_sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `driver_sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dumpcardetails_1`
--

DROP TABLE IF EXISTS `dumpcardetails_1`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dumpcardetails_1` (
  `car_no` varchar(50) NOT NULL,
  `valet_id` varchar(50) NOT NULL,
  `site_no` int DEFAULT '1',
  `parking_spot` varchar(50) DEFAULT NULL,
  `driver_assigned_for_parking` varchar(50) DEFAULT NULL,
  `driver_assigned_for_bringing` varchar(50) DEFAULT NULL,
  `status` enum('none','in_request','assigned_parking','parked','out_request','assigned_bringing','brought_to_client','handed_over') DEFAULT 'none',
  `timestamp_car_in_request` datetime DEFAULT NULL,
  `timestamp_car_out_request` datetime DEFAULT NULL,
  `timestamp_parked` datetime DEFAULT NULL,
  `timestamp_driver_assigned` datetime DEFAULT NULL,
  `timestamp_car_brought` datetime DEFAULT NULL,
  `timestamp_car_handed_over` datetime DEFAULT NULL,
  `seen_parking` tinyint DEFAULT '0',
  `timestamp_seen_parking` datetime DEFAULT NULL,
  `seen_bringing` tinyint DEFAULT '0',
  `timestamp_seen_bringing` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dumpcardetails_1`
--

LOCK TABLES `dumpcardetails_1` WRITE;
/*!40000 ALTER TABLE `dumpcardetails_1` DISABLE KEYS */;
INSERT INTO `dumpcardetails_1` VALUES ('mh04hm03212','666',1,'asdff','dr1','dr1','handed_over','2025-09-18 05:21:21','2025-09-18 05:23:39','2025-09-18 05:23:26','2025-09-18 05:24:43','2025-09-18 05:25:00','2025-09-18 06:07:22',0,NULL,0,NULL),('mh04hm0321','6666',1,'123','dr2','dr2','handed_over','2025-09-18 05:18:21','2025-09-18 06:08:16','2025-09-18 05:27:37','2025-09-18 06:09:01','2025-09-18 06:09:30','2025-09-18 06:09:38',0,NULL,0,NULL),('mh04hm03212','666',1,'asdff','dr1','dr2','handed_over','2025-09-18 06:09:42','2025-09-18 06:10:20','2025-09-18 06:10:10','2025-09-18 06:10:37','2025-09-18 06:10:41','2025-09-18 06:10:55',0,NULL,0,NULL),('mh04hm03212','666',1,'asdff','dr1','dr2','handed_over','2025-09-18 06:26:22','2025-09-18 06:27:07','2025-09-18 06:26:49','2025-09-18 06:27:16','2025-09-18 06:28:01','2025-09-18 06:28:10',0,NULL,0,NULL),('mh04hm03212','666',1,'asdff','dr2','dr2','handed_over','2025-09-18 06:31:45','2025-09-18 06:37:40','2025-09-18 06:37:30','2025-09-18 06:38:01','2025-09-18 06:38:16','2025-09-18 06:38:26',1,'2025-09-18 06:37:18',1,'2025-09-18 06:38:11'),('mh04hm03212','666',1,'asdff','dr2','dr2','handed_over','2025-09-18 06:51:25','2025-09-18 06:54:28','2025-09-18 06:54:18','2025-09-18 06:54:50','2025-09-18 06:55:07','2025-09-18 06:55:17',1,'2025-09-18 06:54:01',1,'2025-09-18 06:54:57'),('mh04hm03212','666',1,'asdff','dr2','dr2','handed_over','2025-09-18 06:55:43','2025-09-18 07:03:06','2025-09-18 06:56:11','2025-09-18 07:03:28','2025-09-18 07:03:34','2025-09-18 07:03:47',0,'2025-09-18 06:56:01',1,'2025-09-18 07:03:32'),('mh04hm03212','666',1,'asdff','dr1','dr1','handed_over','2025-09-18 07:13:11','2025-09-18 07:16:25','2025-09-18 07:16:18','2025-09-18 07:16:36','2025-09-18 07:16:48','2025-09-18 07:16:56',1,'2025-09-18 07:16:12',1,'2025-09-18 07:16:47'),('gh45re6542','213',1,'aasd','dr1','dr2','handed_over','2025-09-18 07:29:29','2025-09-18 07:36:27','2025-09-18 07:36:12','2025-09-18 07:36:40','2025-09-18 07:36:45','2025-09-18 07:36:57',1,'2025-09-18 07:36:05',1,'2025-09-18 07:36:43'),('BH09RE4352','200',1,'asdaw','dr2','dr2','handed_over','2025-09-19 05:54:11','2025-09-19 06:05:04','2025-09-19 06:03:55','2025-09-19 06:05:38','2025-09-19 06:05:50','2025-09-19 06:06:00',1,'2025-09-19 06:03:46',1,'2025-09-19 06:05:49'),('mh04hm021','012',1,'asd','dr1','dr1','handed_over','2025-09-18 07:27:38','2025-09-19 09:44:55','2025-09-18 07:42:38','2025-09-19 09:45:13','2025-09-19 09:45:27','2025-09-19 09:45:34',1,'2025-09-18 07:42:33',1,'2025-09-19 09:45:22');
/*!40000 ALTER TABLE `dumpcardetails_1` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dumpcardetails_2`
--

DROP TABLE IF EXISTS `dumpcardetails_2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dumpcardetails_2` (
  `id` int NOT NULL AUTO_INCREMENT,
  `car_no` varchar(50) NOT NULL,
  `valet_id` varchar(50) NOT NULL,
  `site_no` int NOT NULL DEFAULT '2',
  `phone_number` varchar(20) DEFAULT NULL,
  `parking_spot` varchar(50) DEFAULT NULL,
  `driver_assigned_for_parking` varchar(50) DEFAULT NULL,
  `driver_assigned_for_bringing` varchar(50) DEFAULT NULL,
  `status` enum('in_request','assigned_parking','parked','out_request','assigned_bringing','brought_to_client','handed_over') NOT NULL,
  `timestamp_car_in_request` datetime DEFAULT NULL,
  `timestamp_car_out_request` datetime DEFAULT NULL,
  `timestamp_driver_assigned` datetime DEFAULT NULL,
  `timestamp_parked` datetime DEFAULT NULL,
  `timestamp_car_brought` datetime DEFAULT NULL,
  `timestamp_car_handed_over` datetime DEFAULT NULL,
  `seen_parking` tinyint(1) DEFAULT NULL,
  `timestamp_seen_parking` datetime DEFAULT NULL,
  `seen_bringing` tinyint(1) DEFAULT NULL,
  `timestamp_seen_bringing` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dumpcardetails_2`
--

LOCK TABLES `dumpcardetails_2` WRITE;
/*!40000 ALTER TABLE `dumpcardetails_2` DISABLE KEYS */;
INSERT INTO `dumpcardetails_2` VALUES (1,'mh04hm0321','214',2,'1234567890','BZXyui','dr1','dr1','handed_over','2025-09-19 05:09:16','2025-09-19 05:31:34','2025-09-19 05:32:18','2025-09-19 05:23:09','2025-09-19 05:32:30','2025-09-19 05:34:39',1,'2025-09-19 05:23:00',1,'2025-09-19 05:32:29','2025-09-19 00:04:39'),(2,'mh04hm0214','111',2,NULL,'sd45','dr1','dr2','handed_over','2025-09-19 08:19:51','2025-09-19 09:23:12','2025-09-19 09:23:28','2025-09-19 08:53:37','2025-09-19 09:23:43','2025-09-19 09:23:52',1,'2025-09-19 08:53:30',1,'2025-09-19 09:23:37','2025-09-19 03:53:51'),(3,'KA09Hj4555','900',2,'9876543210','Ghhj','dr2','dr1','handed_over','2025-09-19 12:20:55','2025-09-19 12:29:43','2025-09-19 12:29:51','2025-09-19 12:28:07','2025-09-19 12:30:28','2025-09-19 12:30:40',1,'2025-09-19 12:27:56',1,'2025-09-19 12:30:22','2025-09-19 07:00:39'),(4,'Mh04hm33','967',2,'058','Yuuu','dr2','dr2','handed_over','2025-09-19 12:35:09','2025-09-19 12:41:27','2025-09-19 12:41:44','2025-09-19 12:41:01','2025-09-19 12:42:08','2025-09-19 12:42:37',1,'2025-09-19 12:40:38',1,'2025-09-19 12:42:01','2025-09-19 07:12:36'),(5,'DB45DG4568','68',2,NULL,'yoto','dr2','dr1','handed_over','2025-09-23 17:15:28','2025-09-23 17:17:14','2025-09-23 17:18:14','2025-09-23 17:16:47','2025-09-23 17:18:47','2025-09-23 17:19:08',1,'2025-09-23 17:16:42',1,'2025-09-23 17:18:45','2025-09-23 11:49:07'),(6,'MH04HM321','321',2,'9769796120','yolo','dr2','dr1','handed_over','2025-09-23 17:54:43','2025-09-23 17:57:04','2025-09-23 17:57:12','2025-09-23 17:56:47','2025-09-23 17:57:36','2025-09-23 17:57:54',1,'2025-09-23 17:56:43',1,'2025-09-23 17:57:32','2025-09-23 12:27:53'),(7,'MH04HM1234','37',2,'9930128525','Yoyo','dr2','dr1','handed_over','2025-09-23 18:55:03','2025-09-23 18:57:48','2025-09-23 18:57:55','2025-09-23 18:57:20','2025-09-23 18:58:20','2025-09-23 18:58:42',1,'2025-09-23 18:57:14',1,'2025-09-23 18:58:11','2025-09-23 13:28:41'),(8,'Gj78sd6786','396',2,'9876541230','tolo','dr2','dr2','handed_over','2025-09-23 22:15:26','2025-09-23 22:17:25','2025-09-23 22:17:37','2025-09-23 22:17:02','2025-09-23 22:17:58','2025-09-23 22:18:17',1,'2025-09-23 22:16:57',1,'2025-09-23 22:17:55','2025-09-23 16:48:16'),(9,'MH04FM9179','179',2,'8082379741','b1 x123','dr1','dr1','handed_over','2025-09-24 13:23:13','2025-09-24 13:32:48','2025-09-24 13:32:55','2025-09-24 13:32:13','2025-09-24 13:33:24','2025-09-24 13:33:47',1,'2025-09-24 13:31:58',1,'2025-09-24 13:33:14','2025-09-24 08:03:47');
/*!40000 ALTER TABLE `dumpcardetails_2` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `login`
--

DROP TABLE IF EXISTS `login`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `login` (
  `id` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `site_no` int DEFAULT NULL,
  `role` enum('operator','driver','manager','client','admin') NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `site_no` (`site_no`),
  CONSTRAINT `login_ibfk_1` FOREIGN KEY (`site_no`) REFERENCES `sites` (`site_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `login`
--

LOCK TABLES `login` WRITE;
/*!40000 ALTER TABLE `login` DISABLE KEYS */;
INSERT INTO `login` VALUES ('admin1','adminpass',1,'admin','2025-09-13 01:07:46'),('cl1','pass4',1,'client','2025-09-13 01:07:46'),('dr1','pass2',1,'driver','2025-09-13 01:07:46'),('mg1','pass3',1,'manager','2025-09-13 01:07:46'),('op1','pass1',1,'operator','2025-09-13 21:58:17');
/*!40000 ALTER TABLE `login` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `login_1`
--

DROP TABLE IF EXISTS `login_1`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `login_1` (
  `id` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `site_no` int DEFAULT '1',
  `role` enum('operator','driver','manager','client','admin') NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `driver_name` varchar(100) DEFAULT NULL,
  `driver_photo` text,
  `on_duty` tinyint(1) DEFAULT '0',
  `last_login` timestamp NULL DEFAULT NULL,
  `last_logout` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `site_no` (`site_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `login_1`
--

LOCK TABLES `login_1` WRITE;
/*!40000 ALTER TABLE `login_1` DISABLE KEYS */;
INSERT INTO `login_1` VALUES ('admin1','adminpass',1,'admin','2025-09-13 01:07:46',NULL,NULL,0,NULL,NULL),('cl1','pass4',1,'client','2025-09-13 01:07:46',NULL,NULL,0,NULL,NULL),('dr1','pass2',1,'driver','2025-09-13 01:07:46',NULL,NULL,0,NULL,NULL),('dr2','pass5',1,'driver','2025-09-17 23:50:56',NULL,NULL,0,NULL,NULL),('mg1','pass3',1,'manager','2025-09-13 01:07:46',NULL,NULL,0,NULL,NULL),('op1','pass1',1,'operator','2025-09-13 21:58:17',NULL,NULL,0,NULL,NULL);
/*!40000 ALTER TABLE `login_1` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `login_2`
--

DROP TABLE IF EXISTS `login_2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `login_2` (
  `id` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `site_no` int NOT NULL DEFAULT '2',
  `role` enum('operator','manager','driver','admin') NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `driver_name` varchar(100) DEFAULT NULL,
  `driver_photo` text,
  `on_duty` tinyint(1) DEFAULT '0',
  `last_login` timestamp NULL DEFAULT NULL,
  `last_logout` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `login_2`
--

LOCK TABLES `login_2` WRITE;
/*!40000 ALTER TABLE `login_2` DISABLE KEYS */;
INSERT INTO `login_2` VALUES ('admin1','adminpass',2,'admin','2025-09-18 22:13:15',NULL,NULL,0,NULL,NULL),('dr1','pass2',2,'driver','2025-09-18 22:13:15',NULL,NULL,0,NULL,NULL),('dr2','pass5',2,'driver','2025-09-18 22:13:15',NULL,NULL,0,NULL,NULL),('mg1','pass3',2,'manager','2025-09-18 22:13:15',NULL,NULL,0,NULL,NULL),('op1','pass1',2,'operator','2025-09-18 22:13:15',NULL,NULL,0,NULL,NULL);
/*!40000 ALTER TABLE `login_2` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sites`
--

DROP TABLE IF EXISTS `sites`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sites` (
  `site_no` int NOT NULL AUTO_INCREMENT,
  `login_table` varchar(255) DEFAULT NULL,
  `car_table` varchar(255) DEFAULT NULL,
  `dump_table` varchar(64) NOT NULL,
  `max_users` int DEFAULT NULL,
  PRIMARY KEY (`site_no`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sites`
--

LOCK TABLES `sites` WRITE;
/*!40000 ALTER TABLE `sites` DISABLE KEYS */;
INSERT INTO `sites` VALUES (1,'login_1','car_details_1','dumpcardetails_1',9),(2,'login_2','car_details_2','dumpcardetails_2',10);
/*!40000 ALTER TABLE `sites` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `superadmin_login`
--

DROP TABLE IF EXISTS `superadmin_login`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `superadmin_login` (
  `id` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `site_no` int DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `superadmin_login`
--

LOCK TABLES `superadmin_login` WRITE;
/*!40000 ALTER TABLE `superadmin_login` DISABLE KEYS */;
INSERT INTO `superadmin_login` VALUES ('super1','superpass',0);
/*!40000 ALTER TABLE `superadmin_login` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'valet'
--

--
-- Dumping routines for database 'valet'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-10-07  0:52:43
