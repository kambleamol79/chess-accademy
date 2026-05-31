-- MySQL dump 10.13  Distrib 9.6.0, for macos26.2 (arm64)
--
-- Host: 127.0.0.1    Database: chess_academy
-- ------------------------------------------------------
-- Server version	9.6.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '30f3f316-e941-11f0-be01-4ba661f09412:1-1717,
b943fcee-4ee4-11f1-b912-e9bdf595096f:1-923';

--
-- Table structure for table `chess_live_matches`
--

DROP TABLE IF EXISTS `chess_live_matches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chess_live_matches` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `tournament_id` int unsigned DEFAULT NULL,
  `white_student_id` int unsigned NOT NULL,
  `black_student_id` int unsigned NOT NULL,
  `status` enum('waiting','active','completed','abandoned') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'waiting',
  `result` enum('pending','white_win','black_win','draw') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `time_control_minutes` tinyint unsigned NOT NULL DEFAULT '10',
  `white_ms_remaining` int unsigned NOT NULL DEFAULT '600000',
  `black_ms_remaining` int unsigned NOT NULL DEFAULT '600000',
  `clock_side` enum('w','b') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `clock_since` datetime DEFAULT NULL,
  `start_fen` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  `current_fen` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `started_at` datetime DEFAULT NULL,
  `ended_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `event_seq` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_live_matches_tournament` (`tournament_id`),
  KEY `idx_live_matches_status` (`status`),
  KEY `fk_live_matches_white` (`white_student_id`),
  KEY `fk_live_matches_black` (`black_student_id`),
  CONSTRAINT `fk_live_matches_black` FOREIGN KEY (`black_student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_live_matches_tournament` FOREIGN KEY (`tournament_id`) REFERENCES `chess_tournaments` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_live_matches_white` FOREIGN KEY (`white_student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `chess_live_matches`
--

LOCK TABLES `chess_live_matches` WRITE;
/*!40000 ALTER TABLE `chess_live_matches` DISABLE KEYS */;
INSERT INTO `chess_live_matches` VALUES (1,NULL,4,5,'completed','white_win',10,600000,600000,NULL,NULL,'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1','rnbqkbnr/1p3pp1/8/p1ppp2p/1PP1P2P/3B4/P2P1PP1/RNBQK1NR w KQkq d6 0 6','2026-05-28 17:58:57','2026-05-28 22:38:54','2026-05-28 12:28:57','2026-05-28 17:08:54',12),(2,NULL,4,5,'active','pending',10,600000,600000,'b','2026-05-28 22:50:30','rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1','rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq d3 0 1','2026-05-28 22:39:06',NULL,'2026-05-28 17:09:06','2026-05-28 17:20:30',2);
/*!40000 ALTER TABLE `chess_live_matches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `chess_live_moves`
--

DROP TABLE IF EXISTS `chess_live_moves`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chess_live_moves` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `match_id` int unsigned NOT NULL,
  `ply` smallint unsigned NOT NULL,
  `uci` varchar(12) COLLATE utf8mb4_unicode_ci NOT NULL,
  `san` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `color` enum('w','b') COLLATE utf8mb4_unicode_ci NOT NULL,
  `student_id` int unsigned NOT NULL,
  `fen_after` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_live_moves_match_ply` (`match_id`,`ply`),
  KEY `idx_live_moves_match` (`match_id`),
  KEY `fk_live_moves_student` (`student_id`),
  CONSTRAINT `fk_live_moves_match` FOREIGN KEY (`match_id`) REFERENCES `chess_live_matches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_live_moves_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `chess_live_moves`
--

LOCK TABLES `chess_live_moves` WRITE;
/*!40000 ALTER TABLE `chess_live_moves` DISABLE KEYS */;
INSERT INTO `chess_live_moves` VALUES (1,1,1,'e2e4','e4','w',4,'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1','2026-05-28 12:31:20'),(2,1,2,'c7c5','c5','b',5,'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2','2026-05-28 12:31:31'),(3,1,3,'b2b4','b4','w',4,'rnbqkbnr/pp1ppppp/8/2p5/1P2P3/8/P1PP1PPP/RNBQKBNR b KQkq b3 0 2','2026-05-28 12:41:18'),(4,1,4,'h7h5','h5','b',5,'rnbqkbnr/pp1pppp1/8/2p4p/1P2P3/8/P1PP1PPP/RNBQKBNR w KQkq h6 0 3','2026-05-28 12:42:20'),(5,1,5,'h2h4','h4','w',4,'rnbqkbnr/pp1pppp1/8/2p4p/1P2P2P/8/P1PP1PP1/RNBQKBNR b KQkq h3 0 3','2026-05-28 12:46:51'),(6,1,6,'a7a5','a5','b',5,'rnbqkbnr/1p1pppp1/8/p1p4p/1P2P2P/8/P1PP1PP1/RNBQKBNR w KQkq a6 0 4','2026-05-28 12:48:52'),(7,1,7,'f1d3','Bd3','w',4,'rnbqkbnr/1p1pppp1/8/p1p4p/1P2P2P/3B4/P1PP1PP1/RNBQK1NR b KQkq - 1 4','2026-05-28 12:51:23'),(8,1,8,'e7e5','e5','b',5,'rnbqkbnr/1p1p1pp1/8/p1p1p2p/1P2P2P/3B4/P1PP1PP1/RNBQK1NR w KQkq e6 0 5','2026-05-28 16:54:23'),(9,1,9,'c2c4','c4','w',4,'rnbqkbnr/1p1p1pp1/8/p1p1p2p/1PP1P2P/3B4/P2P1PP1/RNBQK1NR b KQkq c3 0 5','2026-05-28 16:57:15'),(10,1,10,'d7d5','d5','b',5,'rnbqkbnr/1p3pp1/8/p1ppp2p/1PP1P2P/3B4/P2P1PP1/RNBQK1NR w KQkq d6 0 6','2026-05-28 16:57:49'),(11,2,1,'d2d4','d4','w',4,'rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq d3 0 1','2026-05-28 17:09:28');
/*!40000 ALTER TABLE `chess_live_moves` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `chess_matchmaking_queue`
--

DROP TABLE IF EXISTS `chess_matchmaking_queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chess_matchmaking_queue` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `student_id` int unsigned NOT NULL,
  `tournament_id` int unsigned DEFAULT NULL,
  `joined_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_queue_student` (`student_id`),
  KEY `idx_queue_tournament` (`tournament_id`),
  CONSTRAINT `fk_queue_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_queue_tournament` FOREIGN KEY (`tournament_id`) REFERENCES `chess_tournaments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `chess_matchmaking_queue`
--

LOCK TABLES `chess_matchmaking_queue` WRITE;
/*!40000 ALTER TABLE `chess_matchmaking_queue` DISABLE KEYS */;
/*!40000 ALTER TABLE `chess_matchmaking_queue` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `chess_tournament_entries`
--

DROP TABLE IF EXISTS `chess_tournament_entries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chess_tournament_entries` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `tournament_id` int unsigned NOT NULL,
  `student_id` int unsigned NOT NULL,
  `score` decimal(5,1) NOT NULL DEFAULT '0.0',
  `joined_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_tournament_student` (`tournament_id`,`student_id`),
  KEY `fk_tournament_entries_student` (`student_id`),
  CONSTRAINT `fk_tournament_entries_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_tournament_entries_tournament` FOREIGN KEY (`tournament_id`) REFERENCES `chess_tournaments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `chess_tournament_entries`
--

LOCK TABLES `chess_tournament_entries` WRITE;
/*!40000 ALTER TABLE `chess_tournament_entries` DISABLE KEYS */;
/*!40000 ALTER TABLE `chess_tournament_entries` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `chess_tournaments`
--

DROP TABLE IF EXISTS `chess_tournaments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chess_tournaments` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `starts_at` datetime NOT NULL,
  `time_control_minutes` tinyint unsigned NOT NULL DEFAULT '10',
  `status` enum('scheduled','registration','active','finished','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'scheduled',
  `created_by` int unsigned DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_chess_tournaments_starts` (`starts_at`),
  KEY `idx_chess_tournaments_status` (`status`),
  KEY `fk_chess_tournaments_creator` (`created_by`),
  CONSTRAINT `fk_chess_tournaments_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `chess_tournaments`
--

LOCK TABLES `chess_tournaments` WRITE;
/*!40000 ALTER TABLE `chess_tournaments` DISABLE KEYS */;
/*!40000 ALTER TABLE `chess_tournaments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `class_materials`
--

DROP TABLE IF EXISTS `class_materials`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `class_materials` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `form_id` int unsigned NOT NULL,
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` enum('pdf','video','link') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'link',
  `url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `uploaded_by` int unsigned DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_materials_form` (`form_id`),
  KEY `fk_materials_user` (`uploaded_by`),
  CONSTRAINT `fk_materials_form` FOREIGN KEY (`form_id`) REFERENCES `forms` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_materials_user` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `class_materials`
--

LOCK TABLES `class_materials` WRITE;
/*!40000 ALTER TABLE `class_materials` DISABLE KEYS */;
/*!40000 ALTER TABLE `class_materials` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `coaches`
--

DROP TABLE IF EXISTS `coaches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `coaches` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL,
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bio` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `rating` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_coaches_user` (`user_id`),
  CONSTRAINT `fk_coaches_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `coaches`
--

LOCK TABLES `coaches` WRITE;
/*!40000 ALTER TABLE `coaches` DISABLE KEYS */;
INSERT INTO `coaches` VALUES (1,2,'M@ COACH',NULL,1,'2026-05-25 13:45:42','2026-05-25 13:45:42');
/*!40000 ALTER TABLE `coaches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `form_enrollments`
--

DROP TABLE IF EXISTS `form_enrollments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `form_enrollments` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `form_id` int unsigned NOT NULL,
  `student_id` int unsigned NOT NULL,
  `enrolled_at` date NOT NULL,
  `status` enum('active','completed','dropped') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_form_student` (`form_id`,`student_id`),
  KEY `fk_enrollment_student` (`student_id`),
  CONSTRAINT `fk_enrollment_form` FOREIGN KEY (`form_id`) REFERENCES `forms` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_enrollment_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `form_enrollments`
--

LOCK TABLES `form_enrollments` WRITE;
/*!40000 ALTER TABLE `form_enrollments` DISABLE KEYS */;
INSERT INTO `form_enrollments` VALUES (3,25,4,'2026-05-27','active','2026-05-27 10:56:34');
/*!40000 ALTER TABLE `form_enrollments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `forms`
--

DROP TABLE IF EXISTS `forms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `forms` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `highlight` enum('blue','beige') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'beige',
  `batch` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `module` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `time` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `days_summary` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `day_1` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `coach_1` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `day_2` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `coach_2` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `zoom_meeting_id` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `zoom_join_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `zoom_start_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `zoom_password` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_forms_batch` (`batch`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `forms`
--

LOCK TABLES `forms` WRITE;
/*!40000 ALTER TABLE `forms` DISABLE KEYS */;
INSERT INTO `forms` VALUES (25,'beige','IB - 1','Intermediate','07.00-08.00','MON/TUE','MON',NULL,'TUE','Chaintanya A',NULL,'74175890267','https://us04web.zoom.us/j/74175890267?pwd=R52vRe5no0J0HfUb67u313F2jP1sfc.1','https://us04web.zoom.us/s/74175890267?zak=eyJ0eXAiOiJKV1QiLCJzdiI6IjAwMDAwMiIsInptX3NrbSI6InptX28ybSIsImFsZyI6IkhTMjU2In0.eyJpc3MiOiJ3ZWIiLCJjbHQiOjAsIm1udW0iOiI3NDE3NTg5MDI2NyIsImF1ZCI6ImNsaWVudHNtIiwidWlkIjoibWVGRG0ya1RSYldtc3l3Ty1IMXhCdyIsInppZCI6ImJlZjA2Y2NiZThjMzRlMWY4NGY3Y2MzN2RlY2MzMDlmIiwic2siOiIwIiwic3R5IjoxLCJ3Y2QiOiJ1czA0IiwiZXhwIjoxNzc5ODgyNDQ1LCJpYXQiOjE3Nzk4NzUyNDUsImFpZCI6IkIxU2d5UHZvUnplQkZuYnRFcUZfX2ciLCJjaWQiOiIifQ.eEcW0L7Gce5jgsFA1PF-bEL_lpbJjKDF51EQpYG4loE','5utPt0','2026-05-27 09:47:24','2026-05-27 11:52:35'),(26,'beige','IB - 2','Intermediate','15.00-16.04','WED/THU','WED',NULL,'THU','Chaintanya A',NULL,'74647356153','https://us04web.zoom.us/j/74647356153?pwd=SGB8XY9P6G3JnB86hd4XPHhkQ8qoGr.1','https://us04web.zoom.us/s/74647356153?zak=eyJ0eXAiOiJKV1QiLCJzdiI6IjAwMDAwMiIsInptX3NrbSI6InptX28ybSIsImFsZyI6IkhTMjU2In0.eyJpc3MiOiJ3ZWIiLCJjbHQiOjAsIm1udW0iOiI3NDY0NzM1NjE1MyIsImF1ZCI6ImNsaWVudHNtIiwidWlkIjoibWVGRG0ya1RSYldtc3l3Ty1IMXhCdyIsInppZCI6IjRjMzY4NGRlN2IwOTRlMGU5YTQ4YzY4NTk1ODRlOTIyIiwic2siOiIwIiwic3R5IjoxLCJ3Y2QiOiJ1czA0IiwiZXhwIjoxNzc5ODgzNDE5LCJpYXQiOjE3Nzk4NzYyMTksImFpZCI6IkIxU2d5UHZvUnplQkZuYnRFcUZfX2ciLCJjaWQiOiIifQ.v3WDTrJcMtsSdcndNKJyotRlrMzoZ21iKH9vEa8ZJTs','b5qyL2','2026-05-27 10:03:38','2026-05-27 11:52:38'),(27,'beige','IB - 3',NULL,'20.08-22.04','SAT/SUN','SAT',NULL,'SUN','Chaintanya A',NULL,'79405640766','https://us04web.zoom.us/j/79405640766?pwd=0gD0U3VVicFNyXMzseMIgRbAUobSYP.1','https://us04web.zoom.us/s/79405640766?zak=eyJ0eXAiOiJKV1QiLCJzdiI6IjAwMDAwMiIsInptX3NrbSI6InptX28ybSIsImFsZyI6IkhTMjU2In0.eyJpc3MiOiJ3ZWIiLCJjbHQiOjAsIm1udW0iOiI3OTQwNTY0MDc2NiIsImF1ZCI6ImNsaWVudHNtIiwidWlkIjoibWVGRG0ya1RSYldtc3l3Ty1IMXhCdyIsInppZCI6ImZmM2UxOWI4OTdmZTQ2NGVhNTc3NjE3OTE4Mzk1NWIzIiwic2siOiIwIiwic3R5IjoxLCJ3Y2QiOiJ1czA0IiwiZXhwIjoxNzc5ODgzNTk4LCJpYXQiOjE3Nzk4NzYzOTgsImFpZCI6IkIxU2d5UHZvUnplQkZuYnRFcUZfX2ciLCJjaWQiOiIifQ.tkR7AMZBMIYaVQ21ut5BlpUKNd046QUMLqxY8PmaW18','7CpUY3','2026-05-27 10:06:37','2026-05-27 11:52:42');
/*!40000 ALTER TABLE `forms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `games`
--

DROP TABLE IF EXISTS `games`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `games` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `student_id` int unsigned NOT NULL,
  `coach_id` int unsigned DEFAULT NULL,
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pgn` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `reviewed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_games_student` (`student_id`),
  KEY `fk_games_coach` (`coach_id`),
  CONSTRAINT `fk_games_coach` FOREIGN KEY (`coach_id`) REFERENCES `coaches` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_games_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `games`
--

LOCK TABLES `games` WRITE;
/*!40000 ALTER TABLE `games` DISABLE KEYS */;
/*!40000 ALTER TABLE `games` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `invoices`
--

DROP TABLE IF EXISTS `invoices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoices` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `student_id` int unsigned NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `due_date` date DEFAULT NULL,
  `status` enum('pending','paid','overdue','cancelled') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `paid_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_invoices_student` (`student_id`),
  CONSTRAINT `fk_invoices_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `invoices`
--

LOCK TABLES `invoices` WRITE;
/*!40000 ALTER TABLE `invoices` DISABLE KEYS */;
/*!40000 ALTER TABLE `invoices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `leads`
--

DROP TABLE IF EXISTS `leads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `leads` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `captured_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `child_name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `parents_name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `age` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `std` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `q1` enum('Yes','No') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `q2` enum('Yes','No') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `q3` enum('Yes','No') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `time_slot` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `attd_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `module` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status_int` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'INT when interested',
  `not_interested` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `paid` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'PAID when paid',
  `dnp` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `additional` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `review` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `updated_by` int unsigned DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_leads_captured` (`captured_at`),
  KEY `idx_leads_child` (`child_name`),
  KEY `fk_leads_updated_by` (`updated_by`),
  CONSTRAINT `fk_leads_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `leads`
--

LOCK TABLES `leads` WRITE;
/*!40000 ALTER TABLE `leads` DISABLE KEYS */;
INSERT INTO `leads` VALUES (5,'2025-06-05 13:00:00','Vedansh','Avantika sari','9876543210','parent@example.com','12','6th','Kanpur','Yes','No','Yes','07:00 PM - 0',NULL,'IB - 1','INT',NULL,NULL,NULL,NULL,NULL,1,'2026-05-26 16:56:37','2026-05-26 16:56:37');
/*!40000 ALTER TABLE `leads` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `practice_moves`
--

DROP TABLE IF EXISTS `practice_moves`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `practice_moves` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `session_id` int unsigned NOT NULL,
  `ply` smallint unsigned NOT NULL,
  `san` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `uci` varchar(12) COLLATE utf8mb4_unicode_ci NOT NULL,
  `color` enum('w','b') COLLATE utf8mb4_unicode_ci NOT NULL,
  `player` enum('human','opponent') COLLATE utf8mb4_unicode_ci NOT NULL,
  `fen_after` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_practice_moves_session_ply` (`session_id`,`ply`),
  KEY `idx_practice_moves_session` (`session_id`),
  CONSTRAINT `fk_practice_moves_session` FOREIGN KEY (`session_id`) REFERENCES `practice_sessions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `practice_moves`
--

LOCK TABLES `practice_moves` WRITE;
/*!40000 ALTER TABLE `practice_moves` DISABLE KEYS */;
INSERT INTO `practice_moves` VALUES (1,1,1,'d4','d2d4','w','human','rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq - 0 1','2026-05-28 11:24:14'),(2,1,2,'c6','c7c6','b','opponent','rnbqkbnr/pp1ppppp/2p5/8/3P4/8/PPP1PPPP/RNBQKBNR w KQkq - 0 2','2026-05-28 11:24:14'),(3,1,3,'f4','f2f4','w','human','rnbqkbnr/pp1ppppp/2p5/8/3P1P2/8/PPP1P1PP/RNBQKBNR b KQkq - 0 2','2026-05-28 11:24:17'),(4,1,4,'Qb6','d8b6','b','opponent','rnb1kbnr/pp1ppppp/1qp5/8/3P1P2/8/PPP1P1PP/RNBQKBNR w KQkq - 1 3','2026-05-28 11:24:17'),(5,4,1,'e4','e2e4','w','human','rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1','2026-05-28 17:10:17'),(6,4,2,'f5','f7f5','b','opponent','rnbqkbnr/ppppp1pp/8/5p2/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2','2026-05-28 17:10:18'),(7,5,1,'e4','e2e4','w','human','rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1','2026-05-28 17:13:06'),(8,5,2,'b6','b7b6','b','opponent','rnbqkbnr/p1pppppp/1p6/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2','2026-05-28 17:13:06'),(9,5,3,'f4','f2f4','w','human','rnbqkbnr/p1pppppp/1p6/8/4PP2/8/PPPP2PP/RNBQKBNR b KQkq - 0 2','2026-05-28 17:13:08'),(10,5,4,'c6','c7c6','b','opponent','rnbqkbnr/p2ppppp/1pp5/8/4PP2/8/PPPP2PP/RNBQKBNR w KQkq - 0 3','2026-05-28 17:13:09'),(11,5,5,'f5','f4f5','w','human','rnbqkbnr/p2ppppp/1pp5/5P2/4P3/8/PPPP2PP/RNBQKBNR b KQkq - 0 3','2026-05-28 17:13:11'),(12,5,6,'c5','c6c5','b','opponent','rnbqkbnr/p2ppppp/1p6/2p2P2/4P3/8/PPPP2PP/RNBQKBNR w KQkq - 0 4','2026-05-28 17:13:11'),(13,6,1,'e4','e2e4','w','human','rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1','2026-05-28 17:14:20'),(14,6,2,'g6','g7g6','b','opponent','rnbqkbnr/pppppp1p/6p1/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2','2026-05-28 17:14:21');
/*!40000 ALTER TABLE `practice_moves` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `practice_sessions`
--

DROP TABLE IF EXISTS `practice_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `practice_sessions` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL,
  `mode` enum('vs_computer','free_play') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'vs_computer',
  `level` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `player_color` enum('white','black') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'white',
  `time_control_minutes` tinyint unsigned NOT NULL DEFAULT '10',
  `start_fen` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `result` enum('ongoing','win','loss','draw','ended','timeout_win','timeout_loss') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ongoing',
  `ended_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_practice_sessions_user_created` (`user_id`,`created_at` DESC),
  CONSTRAINT `fk_practice_sessions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `practice_sessions`
--

LOCK TABLES `practice_sessions` WRITE;
/*!40000 ALTER TABLE `practice_sessions` DISABLE KEYS */;
INSERT INTO `practice_sessions` VALUES (1,6,'vs_computer','beginner','white',10,'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1','ended','2026-05-28 16:54:21','2026-05-28 11:24:11','2026-05-28 11:24:21'),(2,6,'free_play',NULL,'white',10,'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1','ended','2026-05-28 17:42:03','2026-05-28 12:11:58','2026-05-28 12:12:03'),(3,6,'free_play',NULL,'white',10,'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1','ongoing',NULL,'2026-05-28 12:13:08','2026-05-28 12:13:08'),(4,7,'vs_computer','beginner','white',10,'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1','ended','2026-05-28 22:40:22','2026-05-28 17:10:15','2026-05-28 17:10:22'),(5,6,'vs_computer','beginner','white',10,'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1','ongoing',NULL,'2026-05-28 17:13:04','2026-05-28 17:13:11'),(6,6,'vs_computer','beginner','white',10,'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1','ended','2026-05-28 22:44:44','2026-05-28 17:14:16','2026-05-28 17:14:44'),(7,6,'vs_computer','intermediate','white',10,'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1','ended','2026-05-28 22:45:07','2026-05-28 17:14:44','2026-05-28 17:15:07'),(8,6,'vs_computer','intermediate','white',10,'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1','ended','2026-05-28 22:45:22','2026-05-28 17:15:07','2026-05-28 17:15:22'),(9,6,'vs_computer','intermediate','white',10,'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1','ended','2026-05-28 22:45:30','2026-05-28 17:15:22','2026-05-28 17:15:30'),(10,6,'vs_computer','intermediate','white',10,'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1','ended','2026-05-28 22:50:30','2026-05-28 17:15:30','2026-05-28 17:20:30');
/*!40000 ALTER TABLE `practice_sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `puzzle_attempts`
--

DROP TABLE IF EXISTS `puzzle_attempts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `puzzle_attempts` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `puzzle_id` int unsigned NOT NULL,
  `student_id` int unsigned NOT NULL,
  `is_correct` tinyint(1) NOT NULL DEFAULT '0',
  `attempted_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_attempt_puzzle` (`puzzle_id`),
  KEY `idx_attempt_student` (`student_id`),
  CONSTRAINT `fk_attempt_puzzle` FOREIGN KEY (`puzzle_id`) REFERENCES `puzzles` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_attempt_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `puzzle_attempts`
--

LOCK TABLES `puzzle_attempts` WRITE;
/*!40000 ALTER TABLE `puzzle_attempts` DISABLE KEYS */;
/*!40000 ALTER TABLE `puzzle_attempts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `puzzles`
--

DROP TABLE IF EXISTS `puzzles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `puzzles` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fen` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `solution_moves` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `difficulty` enum('easy','medium','hard') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'medium',
  `created_by` int unsigned DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_puzzles_user` (`created_by`),
  CONSTRAINT `fk_puzzles_user` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=588 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `puzzles`
--

LOCK TABLES `puzzles` WRITE;
/*!40000 ALTER TABLE `puzzles` DISABLE KEYS */;
INSERT INTO `puzzles` VALUES (288,'Back rank mate A1-B8','1k6/ppp5/8/8/8/8/PPPPPPPP/R3K3 w - - 0 1','a1b8','easy',NULL,'2026-05-27 12:05:32'),(289,'Back rank mate H1G8','6k1/5ppp/8/8/8/8/PPPPPPPP/3K3R w - - 0 1','h1g8','easy',NULL,'2026-05-27 12:05:32'),(290,'Back rank mate A1-C8','2k5/1ppp4/8/8/8/8/PPPPPPPP/R3K3 w - - 0 1','a1c8','easy',NULL,'2026-05-27 12:05:32'),(291,'Back rank mate H1F8','5k2/4ppp1/8/8/8/8/PPPPPPPP/3K3R w - - 0 1','h1f8','easy',NULL,'2026-05-27 12:05:32'),(292,'Back rank mate A1-D8','3k4/2ppp3/8/8/8/8/PPPPPPPP/R3K3 w - - 0 1','a1d8','easy',NULL,'2026-05-27 12:05:32'),(293,'Back rank mate H1E8','4k3/3ppp2/8/8/8/8/PPPPPPPP/3K3R w - - 0 1','h1e8','easy',NULL,'2026-05-27 12:05:32'),(294,'Back rank mate A1-E8','4k3/3ppp2/8/8/8/8/PPPPPPPP/R3K3 w - - 0 1','a1e8','easy',NULL,'2026-05-27 12:05:32'),(295,'Back rank mate H1D8','3k4/2ppp3/8/8/8/8/PPPPPPPP/3K3R w - - 0 1','h1d8','easy',NULL,'2026-05-27 12:05:32'),(296,'Back rank mate A1-F8','5k2/4ppp1/8/8/8/8/PPPPPPPP/R3K3 w - - 0 1','a1f8','easy',NULL,'2026-05-27 12:05:32'),(297,'Back rank mate H1C8','2k5/1ppp4/8/8/8/8/PPPPPPPP/3K3R w - - 0 1','h1c8','easy',NULL,'2026-05-27 12:05:32'),(298,'Back rank mate A1-G8','6k1/5ppp/8/8/8/8/PPPPPPPP/R3K3 w - - 0 1','a1g8','easy',NULL,'2026-05-27 12:05:32'),(299,'Back rank mate H1B8','1k6/ppp5/8/8/8/8/PPPPPPPP/3K3R w - - 0 1','h1b8','easy',NULL,'2026-05-27 12:05:32'),(300,'Back rank mate A1-H8','7k/6pp/8/8/8/8/PPPPPPPP/R3K3 w - - 0 1','a1h8','easy',NULL,'2026-05-27 12:05:32'),(301,'Back rank mate H1A8','k7/pp6/8/8/8/8/PPPPPPPP/3K3R w - - 0 1','h1a8','easy',NULL,'2026-05-27 12:05:32'),(302,'Back rank mate B1-A8','k7/pp6/8/8/8/8/PPPPPPPP/1R2K3 w - - 0 1','b1a8','easy',NULL,'2026-05-27 12:05:32'),(303,'Back rank mate G1H8','7k/6pp/8/8/8/8/PPPPPPPP/3K2R1 w - - 0 1','g1h8','easy',NULL,'2026-05-27 12:05:32'),(304,'Back rank mate B1-C8','2k5/1ppp4/8/8/8/8/PPPPPPPP/1R2K3 w - - 0 1','b1c8','easy',NULL,'2026-05-27 12:05:32'),(305,'Back rank mate G1F8','5k2/4ppp1/8/8/8/8/PPPPPPPP/3K2R1 w - - 0 1','g1f8','easy',NULL,'2026-05-27 12:05:32'),(306,'Back rank mate B1-D8','3k4/2ppp3/8/8/8/8/PPPPPPPP/1R2K3 w - - 0 1','b1d8','easy',NULL,'2026-05-27 12:05:32'),(307,'Back rank mate G1E8','4k3/3ppp2/8/8/8/8/PPPPPPPP/3K2R1 w - - 0 1','g1e8','easy',NULL,'2026-05-27 12:05:32'),(308,'Back rank mate B1-E8','4k3/3ppp2/8/8/8/8/PPPPPPPP/1R2K3 w - - 0 1','b1e8','easy',NULL,'2026-05-27 12:05:32'),(309,'Back rank mate G1D8','3k4/2ppp3/8/8/8/8/PPPPPPPP/3K2R1 w - - 0 1','g1d8','easy',NULL,'2026-05-27 12:05:32'),(310,'Back rank mate B1-F8','5k2/4ppp1/8/8/8/8/PPPPPPPP/1R2K3 w - - 0 1','b1f8','easy',NULL,'2026-05-27 12:05:32'),(311,'Back rank mate G1C8','2k5/1ppp4/8/8/8/8/PPPPPPPP/3K2R1 w - - 0 1','g1c8','easy',NULL,'2026-05-27 12:05:32'),(312,'Back rank mate B1-G8','6k1/5ppp/8/8/8/8/PPPPPPPP/1R2K3 w - - 0 1','b1g8','easy',NULL,'2026-05-27 12:05:32'),(313,'Back rank mate G1B8','1k6/ppp5/8/8/8/8/PPPPPPPP/3K2R1 w - - 0 1','g1b8','easy',NULL,'2026-05-27 12:05:32'),(314,'Back rank mate B1-H8','7k/6pp/8/8/8/8/PPPPPPPP/1R2K3 w - - 0 1','b1h8','easy',NULL,'2026-05-27 12:05:32'),(315,'Back rank mate G1A8','k7/pp6/8/8/8/8/PPPPPPPP/3K2R1 w - - 0 1','g1a8','easy',NULL,'2026-05-27 12:05:32'),(316,'Back rank mate C1-A8','k7/pp6/8/8/8/8/PPPPPPPP/2R1K3 w - - 0 1','c1a8','easy',NULL,'2026-05-27 12:05:32'),(317,'Back rank mate F1H8','7k/6pp/8/8/8/8/PPPPPPPP/3K1R2 w - - 0 1','f1h8','easy',NULL,'2026-05-27 12:05:32'),(318,'Back rank mate C1-B8','1k6/ppp5/8/8/8/8/PPPPPPPP/2R1K3 w - - 0 1','c1b8','easy',NULL,'2026-05-27 12:05:32'),(319,'Back rank mate F1G8','6k1/5ppp/8/8/8/8/PPPPPPPP/3K1R2 w - - 0 1','f1g8','easy',NULL,'2026-05-27 12:05:32'),(320,'Back rank mate C1-D8','3k4/2ppp3/8/8/8/8/PPPPPPPP/2R1K3 w - - 0 1','c1d8','easy',NULL,'2026-05-27 12:05:32'),(321,'Back rank mate F1E8','4k3/3ppp2/8/8/8/8/PPPPPPPP/3K1R2 w - - 0 1','f1e8','easy',NULL,'2026-05-27 12:05:32'),(322,'Back rank mate C1-E8','4k3/3ppp2/8/8/8/8/PPPPPPPP/2R1K3 w - - 0 1','c1e8','easy',NULL,'2026-05-27 12:05:32'),(323,'Back rank mate F1D8','3k4/2ppp3/8/8/8/8/PPPPPPPP/3K1R2 w - - 0 1','f1d8','easy',NULL,'2026-05-27 12:05:32'),(324,'Back rank mate C1-F8','5k2/4ppp1/8/8/8/8/PPPPPPPP/2R1K3 w - - 0 1','c1f8','easy',NULL,'2026-05-27 12:05:32'),(325,'Back rank mate F1C8','2k5/1ppp4/8/8/8/8/PPPPPPPP/3K1R2 w - - 0 1','f1c8','easy',NULL,'2026-05-27 12:05:32'),(326,'Back rank mate C1-G8','6k1/5ppp/8/8/8/8/PPPPPPPP/2R1K3 w - - 0 1','c1g8','easy',NULL,'2026-05-27 12:05:32'),(327,'Back rank mate F1B8','1k6/ppp5/8/8/8/8/PPPPPPPP/3K1R2 w - - 0 1','f1b8','easy',NULL,'2026-05-27 12:05:32'),(328,'Back rank mate C1-H8','7k/6pp/8/8/8/8/PPPPPPPP/2R1K3 w - - 0 1','c1h8','easy',NULL,'2026-05-27 12:05:32'),(329,'Back rank mate F1A8','k7/pp6/8/8/8/8/PPPPPPPP/3K1R2 w - - 0 1','f1a8','easy',NULL,'2026-05-27 12:05:32'),(330,'Back rank mate D1-A8','k7/pp6/8/8/8/8/PPPPPPPP/3RK3 w - - 0 1','d1a8','easy',NULL,'2026-05-27 12:05:32'),(331,'Back rank mate E1H8','7k/6pp/8/8/8/8/PPPPPPPP/3KR3 w - - 0 1','e1h8','easy',NULL,'2026-05-27 12:05:32'),(332,'Back rank mate D1-B8','1k6/ppp5/8/8/8/8/PPPPPPPP/3RK3 w - - 0 1','d1b8','easy',NULL,'2026-05-27 12:05:32'),(333,'Back rank mate E1G8','6k1/5ppp/8/8/8/8/PPPPPPPP/3KR3 w - - 0 1','e1g8','easy',NULL,'2026-05-27 12:05:32'),(334,'Back rank mate D1-C8','2k5/1ppp4/8/8/8/8/PPPPPPPP/3RK3 w - - 0 1','d1c8','easy',NULL,'2026-05-27 12:05:32'),(335,'Back rank mate E1F8','5k2/4ppp1/8/8/8/8/PPPPPPPP/3KR3 w - - 0 1','e1f8','easy',NULL,'2026-05-27 12:05:32'),(336,'Back rank mate D1-E8','4k3/3ppp2/8/8/8/8/PPPPPPPP/3RK3 w - - 0 1','d1e8','easy',NULL,'2026-05-27 12:05:32'),(337,'Back rank mate E1D8','3k4/2ppp3/8/8/8/8/PPPPPPPP/3KR3 w - - 0 1','e1d8','easy',NULL,'2026-05-27 12:05:32'),(338,'Back rank mate D1-F8','5k2/4ppp1/8/8/8/8/PPPPPPPP/3RK3 w - - 0 1','d1f8','easy',NULL,'2026-05-27 12:05:32'),(339,'Back rank mate E1C8','2k5/1ppp4/8/8/8/8/PPPPPPPP/3KR3 w - - 0 1','e1c8','easy',NULL,'2026-05-27 12:05:32'),(340,'Back rank mate D1-G8','6k1/5ppp/8/8/8/8/PPPPPPPP/3RK3 w - - 0 1','d1g8','easy',NULL,'2026-05-27 12:05:32'),(341,'Back rank mate E1B8','1k6/ppp5/8/8/8/8/PPPPPPPP/3KR3 w - - 0 1','e1b8','easy',NULL,'2026-05-27 12:05:32'),(342,'Back rank mate D1-H8','7k/6pp/8/8/8/8/PPPPPPPP/3RK3 w - - 0 1','d1h8','easy',NULL,'2026-05-27 12:05:32'),(343,'Back rank mate E1A8','k7/pp6/8/8/8/8/PPPPPPPP/3KR3 w - - 0 1','e1a8','easy',NULL,'2026-05-27 12:05:32'),(344,'Back rank mate E1-A8','k7/pp6/8/8/8/8/PPPPPPPP/4R3 w - - 0 1','e1a8','easy',NULL,'2026-05-27 12:05:32'),(345,'Back rank mate D1H8','7k/6pp/8/8/8/8/PPPPPPPP/3R4 w - - 0 1','d1h8','easy',NULL,'2026-05-27 12:05:32'),(346,'Back rank mate E1-B8','1k6/ppp5/8/8/8/8/PPPPPPPP/4R3 w - - 0 1','e1b8','easy',NULL,'2026-05-27 12:05:32'),(347,'Back rank mate D1G8','6k1/5ppp/8/8/8/8/PPPPPPPP/3R4 w - - 0 1','d1g8','easy',NULL,'2026-05-27 12:05:32'),(348,'Back rank mate E1-C8','2k5/1ppp4/8/8/8/8/PPPPPPPP/4R3 w - - 0 1','e1c8','easy',NULL,'2026-05-27 12:05:32'),(349,'Back rank mate D1F8','5k2/4ppp1/8/8/8/8/PPPPPPPP/3R4 w - - 0 1','d1f8','easy',NULL,'2026-05-27 12:05:32'),(350,'Back rank mate E1-D8','3k4/2ppp3/8/8/8/8/PPPPPPPP/4R3 w - - 0 1','e1d8','easy',NULL,'2026-05-27 12:05:32'),(351,'Back rank mate D1E8','4k3/3ppp2/8/8/8/8/PPPPPPPP/3R4 w - - 0 1','d1e8','easy',NULL,'2026-05-27 12:05:32'),(352,'Back rank mate E1-F8','5k2/4ppp1/8/8/8/8/PPPPPPPP/4R3 w - - 0 1','e1f8','easy',NULL,'2026-05-27 12:05:32'),(353,'Back rank mate D1C8','2k5/1ppp4/8/8/8/8/PPPPPPPP/3R4 w - - 0 1','d1c8','easy',NULL,'2026-05-27 12:05:32'),(354,'Back rank mate E1-G8','6k1/5ppp/8/8/8/8/PPPPPPPP/4R3 w - - 0 1','e1g8','easy',NULL,'2026-05-27 12:05:32'),(355,'Back rank mate D1B8','1k6/ppp5/8/8/8/8/PPPPPPPP/3R4 w - - 0 1','d1b8','easy',NULL,'2026-05-27 12:05:32'),(356,'Back rank mate E1-H8','7k/6pp/8/8/8/8/PPPPPPPP/4R3 w - - 0 1','e1h8','easy',NULL,'2026-05-27 12:05:32'),(357,'Back rank mate D1A8','k7/pp6/8/8/8/8/PPPPPPPP/3R4 w - - 0 1','d1a8','easy',NULL,'2026-05-27 12:05:32'),(358,'Back rank mate F1-A8','k7/pp6/8/8/8/8/PPPPPPPP/4KR2 w - - 0 1','f1a8','easy',NULL,'2026-05-27 12:05:32'),(359,'Back rank mate C1H8','7k/6pp/8/8/8/8/PPPPPPPP/2RK4 w - - 0 1','c1h8','easy',NULL,'2026-05-27 12:05:32'),(360,'Back rank mate F1-B8','1k6/ppp5/8/8/8/8/PPPPPPPP/4KR2 w - - 0 1','f1b8','easy',NULL,'2026-05-27 12:05:32'),(361,'Back rank mate C1G8','6k1/5ppp/8/8/8/8/PPPPPPPP/2RK4 w - - 0 1','c1g8','easy',NULL,'2026-05-27 12:05:32'),(362,'Back rank mate F1-C8','2k5/1ppp4/8/8/8/8/PPPPPPPP/4KR2 w - - 0 1','f1c8','easy',NULL,'2026-05-27 12:05:32'),(363,'Back rank mate C1F8','5k2/4ppp1/8/8/8/8/PPPPPPPP/2RK4 w - - 0 1','c1f8','easy',NULL,'2026-05-27 12:05:32'),(364,'Back rank mate F1-D8','3k4/2ppp3/8/8/8/8/PPPPPPPP/4KR2 w - - 0 1','f1d8','easy',NULL,'2026-05-27 12:05:32'),(365,'Back rank mate C1E8','4k3/3ppp2/8/8/8/8/PPPPPPPP/2RK4 w - - 0 1','c1e8','easy',NULL,'2026-05-27 12:05:32'),(366,'Back rank mate F1-E8','4k3/3ppp2/8/8/8/8/PPPPPPPP/4KR2 w - - 0 1','f1e8','easy',NULL,'2026-05-27 12:05:32'),(367,'Back rank mate C1D8','3k4/2ppp3/8/8/8/8/PPPPPPPP/2RK4 w - - 0 1','c1d8','easy',NULL,'2026-05-27 12:05:32'),(368,'Back rank mate F1-G8','6k1/5ppp/8/8/8/8/PPPPPPPP/4KR2 w - - 0 1','f1g8','easy',NULL,'2026-05-27 12:05:32'),(369,'Back rank mate C1B8','1k6/ppp5/8/8/8/8/PPPPPPPP/2RK4 w - - 0 1','c1b8','easy',NULL,'2026-05-27 12:05:32'),(370,'Back rank mate F1-H8','7k/6pp/8/8/8/8/PPPPPPPP/4KR2 w - - 0 1','f1h8','easy',NULL,'2026-05-27 12:05:32'),(371,'Back rank mate C1A8','k7/pp6/8/8/8/8/PPPPPPPP/2RK4 w - - 0 1','c1a8','easy',NULL,'2026-05-27 12:05:32'),(372,'Back rank mate G1-A8','k7/pp6/8/8/8/8/PPPPPPPP/4K1R1 w - - 0 1','g1a8','easy',NULL,'2026-05-27 12:05:32'),(373,'Back rank mate B1H8','7k/6pp/8/8/8/8/PPPPPPPP/1R1K4 w - - 0 1','b1h8','easy',NULL,'2026-05-27 12:05:32'),(374,'Back rank mate G1-B8','1k6/ppp5/8/8/8/8/PPPPPPPP/4K1R1 w - - 0 1','g1b8','easy',NULL,'2026-05-27 12:05:32'),(375,'Back rank mate B1G8','6k1/5ppp/8/8/8/8/PPPPPPPP/1R1K4 w - - 0 1','b1g8','easy',NULL,'2026-05-27 12:05:32'),(376,'Back rank mate G1-C8','2k5/1ppp4/8/8/8/8/PPPPPPPP/4K1R1 w - - 0 1','g1c8','easy',NULL,'2026-05-27 12:05:32'),(377,'Back rank mate B1F8','5k2/4ppp1/8/8/8/8/PPPPPPPP/1R1K4 w - - 0 1','b1f8','easy',NULL,'2026-05-27 12:05:32'),(378,'Back rank mate G1-D8','3k4/2ppp3/8/8/8/8/PPPPPPPP/4K1R1 w - - 0 1','g1d8','easy',NULL,'2026-05-27 12:05:32'),(379,'Back rank mate B1E8','4k3/3ppp2/8/8/8/8/PPPPPPPP/1R1K4 w - - 0 1','b1e8','easy',NULL,'2026-05-27 12:05:32'),(380,'Back rank mate G1-E8','4k3/3ppp2/8/8/8/8/PPPPPPPP/4K1R1 w - - 0 1','g1e8','easy',NULL,'2026-05-27 12:05:32'),(381,'Back rank mate B1D8','3k4/2ppp3/8/8/8/8/PPPPPPPP/1R1K4 w - - 0 1','b1d8','easy',NULL,'2026-05-27 12:05:32'),(382,'Back rank mate G1-F8','5k2/4ppp1/8/8/8/8/PPPPPPPP/4K1R1 w - - 0 1','g1f8','easy',NULL,'2026-05-27 12:05:32'),(383,'Back rank mate B1C8','2k5/1ppp4/8/8/8/8/PPPPPPPP/1R1K4 w - - 0 1','b1c8','easy',NULL,'2026-05-27 12:05:32'),(384,'Back rank mate G1-H8','7k/6pp/8/8/8/8/PPPPPPPP/4K1R1 w - - 0 1','g1h8','easy',NULL,'2026-05-27 12:05:32'),(385,'Back rank mate B1A8','k7/pp6/8/8/8/8/PPPPPPPP/1R1K4 w - - 0 1','b1a8','easy',NULL,'2026-05-27 12:05:32'),(386,'Back rank mate H1-A8','k7/pp6/8/8/8/8/PPPPPPPP/4K2R w - - 0 1','h1a8','easy',NULL,'2026-05-27 12:05:32'),(387,'Back rank mate A1H8','7k/6pp/8/8/8/8/PPPPPPPP/R2K4 w - - 0 1','a1h8','easy',NULL,'2026-05-27 12:05:32'),(388,'Win the queen','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','f3g5 e8g8 g5f7','medium',NULL,'2026-05-27 12:05:32'),(389,'Win the queen (mirror)','r2kqbnr/ppp1pppp/2n5/3p1b2/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','c3b5 d8b8 b5c7','medium',NULL,'2026-05-27 12:05:32'),(390,'Win the queen #1','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 1','f3g5 e8g8 g5f7','medium',NULL,'2026-05-27 12:05:32'),(391,'Knight fork combo','r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4','h5f7 e8f7 c4d5','medium',NULL,'2026-05-27 12:05:32'),(392,'Knight fork combo (mirror)','r1bkqb1r/ppp1pppp/2n2n2/Q2p4/3P1B2/8/PPP1PPPP/RN1K1BNR w KQkq - 4 4','a5c7 d8c7 f4e5','medium',NULL,'2026-05-27 12:05:32'),(393,'Knight fork combo #2','r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 2','h5f7 e8f7 c4d5','medium',NULL,'2026-05-27 12:05:32'),(394,'Double attack','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4','c4f7 e8f7 f3g5','medium',NULL,'2026-05-27 12:05:32'),(395,'Double attack (mirror)','r2kqb1r/ppp1pppp/2n2n2/3p1b2/3P1B2/2N1P3/PPP2PPP/R2KQBNR w KQkq - 0 4','f4c7 d8c7 c3b5','medium',NULL,'2026-05-27 12:05:32'),(396,'Double attack #3','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 3','c4f7 e8f7 f3g5','medium',NULL,'2026-05-27 12:05:32'),(397,'Pin and win','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4','c4f7 e8f7 f3g5 f7g8 g5e6','medium',NULL,'2026-05-27 12:05:32'),(398,'Pin and win (mirror)','r2kqb1r/ppp1pppp/2n2n2/3p1b2/3P1B2/2N1P3/PPP2PPP/R2KQBNR w KQkq - 0 4','f4c7 d8c7 c3b5 c7b8 b5d6','medium',NULL,'2026-05-27 12:05:32'),(399,'Smothered setup','rnb1kbnr/pppp1ppp/8/4q3/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 4 3','c4f7 e8e7 f7d5','medium',NULL,'2026-05-27 12:05:32'),(400,'Smothered setup (mirror)','rnbk1bnr/ppp1pppp/8/3q4/3P1B2/8/PPP1PPPP/RN1KQBNR w KQkq - 4 3','f4c7 d8d7 c7e5','medium',NULL,'2026-05-27 12:05:32'),(401,'Smothered setup #5','rnb1kbnr/pppp1ppp/8/4q3/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 4 5','c4f7 e8e7 f7d5','medium',NULL,'2026-05-27 12:05:32'),(402,'Discovered attack','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3','f3e5 c6e5 c4f7','medium',NULL,'2026-05-27 12:05:32'),(403,'Discovered attack (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 2 3','c3d5 f6d5 f4c7','medium',NULL,'2026-05-27 12:05:32'),(404,'Discovered attack #6','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 6','f3e5 c6e5 c4f7','medium',NULL,'2026-05-27 12:05:32'),(405,'Remove defender','r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/3P1N2/PPP1BPPP/RNBQK2R w KQkq - 2 4','f3e5 c6e5 e2h5','medium',NULL,'2026-05-27 12:05:32'),(406,'Remove defender (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P4/2N1P3/PPPB1PPP/R2KQBNR w KQkq - 2 4','c3d5 f6d5 d2a5','medium',NULL,'2026-05-27 12:05:32'),(407,'Remove defender #7','r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/3P1N2/PPP1BPPP/RNBQK2R w KQkq - 2 7','f3e5 c6e5 e2h5','medium',NULL,'2026-05-27 12:05:32'),(408,'Fork and win','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','c4f7 e8f7 f3g5','medium',NULL,'2026-05-27 12:05:32'),(409,'Fork and win (mirror)','r1bkqbnr/ppp1pppp/2n5/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','f4c7 d8c7 c3b5','medium',NULL,'2026-05-27 12:05:32'),(410,'Fork and win #8','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 8','c4f7 e8f7 f3g5','medium',NULL,'2026-05-27 12:05:32'),(411,'Two-move tactic','r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4','h5f7 e8f7 d1h5','medium',NULL,'2026-05-27 12:05:32'),(412,'Two-move tactic (mirror)','r1bkqb1r/ppp1pppp/2n2n2/Q2p4/3P1B2/8/PPP1PPPP/RN1K1BNR w KQkq - 4 4','a5c7 d8c7 e1a5','medium',NULL,'2026-05-27 12:05:32'),(413,'Two-move tactic #9','r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 1','h5f7 e8f7 d1h5','medium',NULL,'2026-05-27 12:05:32'),(414,'Win material','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','c4f7 e8f7 f3g5','medium',NULL,'2026-05-27 12:05:32'),(415,'Win material (mirror)','r2kqbnr/ppp1pppp/2n5/3p1b2/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','f4c7 d8c7 c3b5','medium',NULL,'2026-05-27 12:05:32'),(416,'Win material #10','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 2','c4f7 e8f7 f3g5','medium',NULL,'2026-05-27 12:05:32'),(417,'Trap the queen','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','c4f7 e8f7 f3e5','medium',NULL,'2026-05-27 12:05:32'),(418,'Trap the queen (mirror)','r1bkqbnr/ppp1pppp/2n5/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','f4c7 d8c7 c3d5','medium',NULL,'2026-05-27 12:05:32'),(419,'Trap the queen #11','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 3','c4f7 e8f7 f3e5','medium',NULL,'2026-05-27 12:05:32'),(420,'Knight outpost','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3','f3e5 d8e7 e5f7','medium',NULL,'2026-05-27 12:05:32'),(421,'Knight outpost (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 2 3','c3d5 e8d7 d5c7','medium',NULL,'2026-05-27 12:05:32'),(422,'Knight outpost #12','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 4','f3e5 d8e7 e5f7','medium',NULL,'2026-05-27 12:05:32'),(423,'Bishop pair attack','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3','c4f7 e8f7 f3g5','medium',NULL,'2026-05-27 12:05:32'),(424,'Bishop pair attack (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 2 3','f4c7 d8c7 c3b5','medium',NULL,'2026-05-27 12:05:32'),(425,'Bishop pair attack #13','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 5','c4f7 e8f7 f3g5','medium',NULL,'2026-05-27 12:05:32'),(426,'Central fork','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','f3e5 c6e5 c4f7','medium',NULL,'2026-05-27 12:05:32'),(427,'Central fork (mirror)','r1bkqbnr/ppp1pppp/2n5/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','c3d5 f6d5 f4c7','medium',NULL,'2026-05-27 12:05:32'),(428,'Central fork #14','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 6','f3e5 c6e5 c4f7','medium',NULL,'2026-05-27 12:05:32'),(429,'Open file tactic','r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3','f1e1 e8e7 e1e7','medium',NULL,'2026-05-27 12:05:32'),(430,'Open file tactic (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P4/2N5/PPP1PPPP/R1BKQBNR w KQkq - 2 3','c1d1 d8d7 d1d7','medium',NULL,'2026-05-27 12:05:32'),(431,'Open file tactic #15','r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 7','f1e1 e8e7 e1e7','medium',NULL,'2026-05-27 12:05:32'),(432,'Skewer opportunity','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3','c4f7 e8f7 d1h5','medium',NULL,'2026-05-27 12:05:32'),(433,'Skewer opportunity (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 2 3','f4c7 d8c7 e1a5','medium',NULL,'2026-05-27 12:05:32'),(434,'Skewer opportunity #16','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 8','c4f7 e8f7 d1h5','medium',NULL,'2026-05-27 12:05:32'),(435,'Clearance #17','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 1','f3e5 c6e5 c4f7','medium',NULL,'2026-05-27 12:05:32'),(436,'Deflection','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','c4f7 e8f7 f3g5 f7g8 g5h7','medium',NULL,'2026-05-27 12:05:32'),(437,'Deflection (mirror)','r1bkqbnr/ppp1pppp/2n5/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','f4c7 d8c7 c3b5 c7b8 b5a7','medium',NULL,'2026-05-27 12:05:32'),(438,'Deflection #18','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 2','c4f7 e8f7 f3g5 f7g8 g5h7','medium',NULL,'2026-05-27 12:05:32'),(439,'Overload','r1bqkb1r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4','c4f7 e8f7 f3g5','medium',NULL,'2026-05-27 12:05:32'),(440,'Overload (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p1b2/3P1B2/2N1P3/PPP2PPP/R2KQBNR w KQkq - 0 4','f4c7 d8c7 c3b5','medium',NULL,'2026-05-27 12:05:32'),(441,'Overload #19','r1bqkb1r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 3','c4f7 e8f7 f3g5','medium',NULL,'2026-05-27 12:05:32'),(442,'Intermediate move','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','f3g5 e8g8 g5f7 f8e7 f7d8','medium',NULL,'2026-05-27 12:05:32'),(443,'Intermediate move (mirror)','r2kqbnr/ppp1pppp/2n5/3p1b2/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','c3b5 d8b8 b5c7 c8d7 c7e8','medium',NULL,'2026-05-27 12:05:32'),(444,'Mate threat #21','r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 5','h5f7 e8f7 c4d5','medium',NULL,'2026-05-27 12:05:32'),(445,'Capture sequence #22','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 6','c4f7 e8f7 f3e5','medium',NULL,'2026-05-27 12:05:32'),(446,'King hunt #23','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 7','c4f7 e8f7 f3g5','medium',NULL,'2026-05-27 12:05:32'),(447,'Piece coordination','r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/3P1N2/PPP1BPPP/RNBQK2R w KQkq - 2 4','e2h5 g8f6 h5f7','medium',NULL,'2026-05-27 12:05:32'),(448,'Piece coordination (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P4/2N1P3/PPPB1PPP/R2KQBNR w KQkq - 2 4','d2a5 b8c6 a5c7','medium',NULL,'2026-05-27 12:05:32'),(449,'Piece coordination #24','r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/3P1N2/PPP1BPPP/RNBQK2R w KQkq - 2 8','e2h5 g8f6 h5f7','medium',NULL,'2026-05-27 12:05:32'),(450,'Tactical shot','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','c4f7 e8f7 d1h5','medium',NULL,'2026-05-27 12:05:32'),(451,'Tactical shot (mirror)','r2kqbnr/ppp1pppp/2n5/3p1b2/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','f4c7 d8c7 e1a5','medium',NULL,'2026-05-27 12:05:32'),(452,'Tactical shot #25','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 1','c4f7 e8f7 d1h5','medium',NULL,'2026-05-27 12:05:32'),(453,'Combo 26','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3','f3e5 c6e5 c4f7 e8f7 d1h5','medium',NULL,'2026-05-27 12:05:32'),(454,'Combo 26 (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 2 3','c3d5 f6d5 f4c7 d8c7 e1a5','medium',NULL,'2026-05-27 12:05:32'),(455,'Combo 26 #26','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 2','f3e5 c6e5 c4f7 e8f7 d1h5','medium',NULL,'2026-05-27 12:05:32'),(456,'Combo 27','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','f3g5 e8g8 g5f7 f8e7 f7d8','medium',NULL,'2026-05-27 12:05:32'),(457,'Combo 27 (mirror)','r1bkqbnr/ppp1pppp/2n5/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','c3b5 d8b8 b5c7 c8d7 c7e8','medium',NULL,'2026-05-27 12:05:32'),(458,'Combo 27 #27','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 3','f3g5 e8g8 g5f7 f8e7 f7d8','medium',NULL,'2026-05-27 12:05:32'),(459,'Combo 28','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4','c4f7 e8f7 f3g5 f7g8 g5e6 d8e7','medium',NULL,'2026-05-27 12:05:32'),(460,'Combo 28 (mirror)','r2kqb1r/ppp1pppp/2n2n2/3p1b2/3P1B2/2N1P3/PPP2PPP/R2KQBNR w KQkq - 0 4','f4c7 d8c7 c3b5 c7b8 b5d6 e8d7','medium',NULL,'2026-05-27 12:05:32'),(461,'Combo 29','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','d1e2 e8g8 c4f7 f8e7 f7g8','medium',NULL,'2026-05-27 12:05:32'),(462,'Combo 29 (mirror)','r2kqbnr/ppp1pppp/2n5/3p1b2/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','e1d2 d8b8 f4c7 c8d7 c7b8','medium',NULL,'2026-05-27 12:05:32'),(463,'Combo 29 #29','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 5','d1e2 e8g8 c4f7 f8e7 f7g8','medium',NULL,'2026-05-27 12:05:32'),(464,'Combo 30','r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4','h5f7 e8f7 c4d5 f7g8 d5c6 b8c6','medium',NULL,'2026-05-27 12:05:32'),(465,'Combo 30 (mirror)','r1bkqb1r/ppp1pppp/2n2n2/Q2p4/3P1B2/8/PPP1PPPP/RN1K1BNR w KQkq - 4 4','a5c7 d8c7 f4e5 c7b8 e5f6 g8f6','medium',NULL,'2026-05-27 12:05:32'),(466,'Combo 30 #30','r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 6','h5f7 e8f7 c4d5 f7g8 d5c6 b8c6','medium',NULL,'2026-05-27 12:05:32'),(467,'Combo 31','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3','c4f7 e8f7 f3g5 f7g8 g5h7','medium',NULL,'2026-05-27 12:05:32'),(468,'Combo 31 (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 2 3','f4c7 d8c7 c3b5 c7b8 b5a7','medium',NULL,'2026-05-27 12:05:32'),(469,'Combo 31 #31','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 7','c4f7 e8f7 f3g5 f7g8 g5h7','medium',NULL,'2026-05-27 12:05:32'),(470,'Combo 32','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','c4f7 e8f7 d1h5 g7g6 h5f7','medium',NULL,'2026-05-27 12:05:32'),(471,'Combo 32 (mirror)','r1bkqbnr/ppp1pppp/2n5/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','f4c7 d8c7 e1a5 b7b6 a5c7','medium',NULL,'2026-05-27 12:05:32'),(472,'Combo 32 #32','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 8','c4f7 e8f7 d1h5 g7g6 h5f7','medium',NULL,'2026-05-27 12:05:32'),(473,'Combo 33','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4','c4f7 e8f7 f3g5 f7g8 g5e6 d8f6','medium',NULL,'2026-05-27 12:05:32'),(474,'Combo 33 (mirror)','r2kqb1r/ppp1pppp/2n2n2/3p1b2/3P1B2/2N1P3/PPP2PPP/R2KQBNR w KQkq - 0 4','f4c7 d8c7 c3b5 c7b8 b5d6 e8c6','medium',NULL,'2026-05-27 12:05:32'),(475,'Combo 33 #33','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 1','c4f7 e8f7 f3g5 f7g8 g5e6 d8f6','medium',NULL,'2026-05-27 12:05:32'),(476,'Combo 34','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','f3g5 h7h6 g5f7 e8f7 c4f7','medium',NULL,'2026-05-27 12:05:32'),(477,'Combo 34 (mirror)','r2kqbnr/ppp1pppp/2n5/3p1b2/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','c3b5 a7a6 b5c7 d8c7 f4c7','medium',NULL,'2026-05-27 12:05:32'),(478,'Combo 34 #34','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 2','f3g5 h7h6 g5f7 e8f7 c4f7','medium',NULL,'2026-05-27 12:05:32'),(479,'Combo 35','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3','c4f7 e8f7 f3g5 f7g8 g5e6','medium',NULL,'2026-05-27 12:05:32'),(480,'Combo 35 (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 2 3','f4c7 d8c7 c3b5 c7b8 b5d6','medium',NULL,'2026-05-27 12:05:32'),(481,'Combo 36','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','f3e5 d8e7 e5f7 e8f7 c4f7','medium',NULL,'2026-05-27 12:05:32'),(482,'Combo 36 (mirror)','r1bkqbnr/ppp1pppp/2n5/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','c3d5 e8d7 d5c7 d8c7 f4c7','medium',NULL,'2026-05-27 12:05:32'),(483,'Combo 37','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4','c4f7 e8f7 f3g5 f7g8 g5h7 f8h6','medium',NULL,'2026-05-27 12:05:32'),(484,'Combo 37 (mirror)','r2kqb1r/ppp1pppp/2n2n2/3p1b2/3P1B2/2N1P3/PPP2PPP/R2KQBNR w KQkq - 0 4','f4c7 d8c7 c3b5 c7b8 b5a7 c8a6','medium',NULL,'2026-05-27 12:05:32'),(485,'Combo 37 #37','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 5','c4f7 e8f7 f3g5 f7g8 g5h7 f8h6','medium',NULL,'2026-05-27 12:05:32'),(486,'Combo 38','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','c4f7 e8f7 f3g5 f7g8 g5e6','medium',NULL,'2026-05-27 12:05:32'),(487,'Combo 38 (mirror)','r2kqbnr/ppp1pppp/2n5/3p1b2/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','f4c7 d8c7 c3b5 c7b8 b5d6','medium',NULL,'2026-05-27 12:05:32'),(488,'Smothered mate pattern','rnb1kbnr/pppp1ppp/8/4q3/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 4 3','c4f7 e8e7 f7d5 e7f8 d5e6','hard',NULL,'2026-05-27 12:05:32'),(489,'Smothered mate pattern (mirror)','rnbk1bnr/ppp1pppp/8/3q4/3P1B2/8/PPP1PPPP/RN1KQBNR w KQkq - 4 3','f4c7 d8d7 c7e5 d7c8 e5d6','hard',NULL,'2026-05-27 12:05:32'),(490,'Smothered mate pattern #1','rnb1kbnr/pppp1ppp/8/4q3/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 4 1','c4f7 e8e7 f7d5 e7f8 d5e6','hard',NULL,'2026-05-27 12:05:32'),(491,'Long combination','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4','c4f7 e8f7 f3g5 f7g8 g5e6 d8e7 e6c7','hard',NULL,'2026-05-27 12:05:32'),(492,'Long combination (mirror)','r2kqb1r/ppp1pppp/2n2n2/3p1b2/3P1B2/2N1P3/PPP2PPP/R2KQBNR w KQkq - 0 4','f4c7 d8c7 c3b5 c7b8 b5d6 e8d7 d6f7','hard',NULL,'2026-05-27 12:05:32'),(493,'Long combination #2','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 2','c4f7 e8f7 f3g5 f7g8 g5e6 d8e7 e6c7','hard',NULL,'2026-05-27 12:05:32'),(494,'Deep calculation','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','f3g5 e8g8 g5f7 f8e7 f7d8 e7d8 c4f7','hard',NULL,'2026-05-27 12:05:32'),(495,'Deep calculation (mirror)','r2kqbnr/ppp1pppp/2n5/3p1b2/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','c3b5 d8b8 b5c7 c8d7 c7e8 d7e8 f4c7','hard',NULL,'2026-05-27 12:05:32'),(496,'Deep calculation #3','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 3','f3g5 e8g8 g5f7 f8e7 f7d8 e7d8 c4f7','hard',NULL,'2026-05-27 12:05:32'),(497,'Multi-move attack','r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4','h5f7 e8f7 c4d5 f7g8 d5c6','hard',NULL,'2026-05-27 12:05:32'),(498,'Multi-move attack (mirror)','r1bkqb1r/ppp1pppp/2n2n2/Q2p4/3P1B2/8/PPP1PPPP/RN1K1BNR w KQkq - 4 4','a5c7 d8c7 f4e5 c7b8 e5f6','hard',NULL,'2026-05-27 12:05:32'),(499,'Sacrifice idea','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3','c4f7 e8f7 f3g5 f7g8 g5h7 f8h6 h7f8','hard',NULL,'2026-05-27 12:05:32'),(500,'Sacrifice idea (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 2 3','f4c7 d8c7 c3b5 c7b8 b5a7 c8a6 a7c8','hard',NULL,'2026-05-27 12:05:32'),(501,'Sacrifice idea #5','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 5','c4f7 e8f7 f3g5 f7g8 g5h7 f8h6 h7f8','hard',NULL,'2026-05-27 12:05:32'),(502,'Complex middlegame','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','c4f7 e8f7 f3g5 f7g8 g5e6 d8e7 e6c7 e7d8','hard',NULL,'2026-05-27 12:05:32'),(503,'Complex middlegame (mirror)','r1bkqbnr/ppp1pppp/2n5/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','f4c7 d8c7 c3b5 c7b8 b5d6 e8d7 d6f7 d7e8','hard',NULL,'2026-05-27 12:05:32'),(504,'Complex middlegame #6','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 6','c4f7 e8f7 f3g5 f7g8 g5e6 d8e7 e6c7 e7d8','hard',NULL,'2026-05-27 12:05:32'),(505,'Endgame conversion','6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1','e1e8 f8e8 g1f2 e8f8 f2f3','hard',NULL,'2026-05-27 12:05:32'),(506,'Endgame conversion (mirror)','1k6/ppp5/8/8/8/8/PPP5/1K1R4 w - - 0 1','d1d8 c8d8 b1c2 d8c8 c2c3','hard',NULL,'2026-05-27 12:05:32'),(507,'Endgame conversion #7','6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 7','e1e8 f8e8 g1f2 e8f8 f2f3','hard',NULL,'2026-05-27 12:05:32'),(508,'Advanced tactic','r1bqkb1r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4','c4f7 e8f7 f3g5 f7g8 g5e6 d8f6 e6f8','hard',NULL,'2026-05-27 12:05:32'),(509,'Advanced tactic (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p1b2/3P1B2/2N1P3/PPP2PPP/R2KQBNR w KQkq - 0 4','f4c7 d8c7 c3b5 c7b8 b5d6 e8c6 d6c8','hard',NULL,'2026-05-27 12:05:32'),(510,'Advanced tactic #8','r1bqkb1r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 8','c4f7 e8f7 f3g5 f7g8 g5e6 d8f6 e6f8','hard',NULL,'2026-05-27 12:05:32'),(511,'Quiet killer','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','d1e2 e8g8 c4f7 f8e7 f7g8','hard',NULL,'2026-05-27 12:05:32'),(512,'Quiet killer (mirror)','r2kqbnr/ppp1pppp/2n5/3p1b2/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','e1d2 d8b8 f4c7 c8d7 c7b8','hard',NULL,'2026-05-27 12:05:32'),(513,'Quiet killer #9','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 1','d1e2 e8g8 c4f7 f8e7 f7g8','hard',NULL,'2026-05-27 12:05:32'),(514,'Calculation drill','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3','f3e5 c6e5 c4f7 e8f7 d1h5 g7g6 h5e5','hard',NULL,'2026-05-27 12:05:32'),(515,'Calculation drill (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 2 3','c3d5 f6d5 f4c7 d8c7 e1a5 b7b6 a5d5','hard',NULL,'2026-05-27 12:05:32'),(516,'Calculation drill #10','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 2','f3e5 c6e5 c4f7 e8f7 d1h5 g7g6 h5e5','hard',NULL,'2026-05-27 12:05:32'),(517,'Master level','rnb1kbnr/pppp1ppp/8/4q3/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 4 3','c4f7 e8e7 f7d5 e7f8 d5e6 f8g8 e6c8','hard',NULL,'2026-05-27 12:05:32'),(518,'Master level (mirror)','rnbk1bnr/ppp1pppp/8/3q4/3P1B2/8/PPP1PPPP/RN1KQBNR w KQkq - 4 3','f4c7 d8d7 c7e5 d7c8 e5d6 c8b8 d6f8','hard',NULL,'2026-05-27 12:05:32'),(519,'Grandmaster punch','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4','c4f7 e8f7 f3g5 f7g8 g5e6 d8e7 e6c7 e7c7 d1h5','hard',NULL,'2026-05-27 12:05:32'),(520,'Grandmaster punch (mirror)','r2kqb1r/ppp1pppp/2n2n2/3p1b2/3P1B2/2N1P3/PPP2PPP/R2KQBNR w KQkq - 0 4','f4c7 d8c7 c3b5 c7b8 b5d6 e8d7 d6f7 d7f7 e1a5','hard',NULL,'2026-05-27 12:05:32'),(521,'Deep fork line','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','c4f7 e8f7 f3g5 f7g8 g5h7 f8h6 h7f8 h6f8','hard',NULL,'2026-05-27 12:05:32'),(522,'Deep fork line (mirror)','r1bkqbnr/ppp1pppp/2n5/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','f4c7 d8c7 c3b5 c7b8 b5a7 c8a6 a7c8 a6c8','hard',NULL,'2026-05-27 12:05:32'),(523,'Deep fork line #13','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 5','c4f7 e8f7 f3g5 f7g8 g5h7 f8h6 h7f8 h6f8','hard',NULL,'2026-05-27 12:05:32'),(524,'Zugzwang theme','7k/8/8/8/8/8/6PP/6K1 w - - 0 1','g2g3 h8g8 g1f2 g8f8 f2e3','hard',NULL,'2026-05-27 12:05:32'),(525,'Zugzwang theme (mirror)','k7/8/8/8/8/8/PP6/1K6 w - - 0 1','b2b3 a8b8 b1c2 b8c8 c2d3','hard',NULL,'2026-05-27 12:05:32'),(526,'Zugzwang theme #14','7k/8/8/8/8/8/6PP/6K1 w - - 0 6','g2g3 h8g8 g1f2 g8f8 f2e3','hard',NULL,'2026-05-27 12:05:32'),(527,'Opposite side castling','r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4','h5f7 e8f7 c4d5 f7g8 d5c6 b8c6','hard',NULL,'2026-05-27 12:05:32'),(528,'Opposite side castling (mirror)','r1bkqb1r/ppp1pppp/2n2n2/Q2p4/3P1B2/8/PPP1PPPP/RN1K1BNR w KQkq - 4 4','a5c7 d8c7 f4e5 c7b8 e5f6 g8f6','hard',NULL,'2026-05-27 12:05:32'),(529,'Opposite side castling #15','r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 7','h5f7 e8f7 c4d5 f7g8 d5c6 b8c6','hard',NULL,'2026-05-27 12:05:32'),(530,'Piece sacrifice #16','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 8','c4f7 e8f7 f3g5 f7g8 g5h7 f8h6 h7f8','hard',NULL,'2026-05-27 12:05:32'),(531,'King safety breach','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','f3g5 h7h6 g5f7 e8f7 c4f7','hard',NULL,'2026-05-27 12:05:32'),(532,'King safety breach (mirror)','r2kqbnr/ppp1pppp/2n5/3p1b2/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','c3b5 a7a6 b5c7 d8c7 f4c7','hard',NULL,'2026-05-27 12:05:32'),(533,'King safety breach #17','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 1','f3g5 h7h6 g5f7 e8f7 c4f7','hard',NULL,'2026-05-27 12:05:32'),(534,'Prophylaxis then strike','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3','h2h3 h7h6 c4f7 e8f7 f3g5','hard',NULL,'2026-05-27 12:05:32'),(535,'Prophylaxis then strike (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 2 3','a2a3 a7a6 f4c7 d8c7 c3b5','hard',NULL,'2026-05-27 12:05:32'),(536,'Prophylaxis then strike #18','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 2','h2h3 h7h6 c4f7 e8f7 f3g5','hard',NULL,'2026-05-27 12:05:32'),(537,'Exchange sacrifice line #19','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 3','c4f7 e8f7 f3g5 f7g8 g5e6 d8e7 e6c7','hard',NULL,'2026-05-27 12:05:32'),(538,'Double rook lift','r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3','f1e1 e8e7 e1e5 d8e8 e5e7','hard',NULL,'2026-05-27 12:05:32'),(539,'Double rook lift (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P4/2N5/PPP1PPPP/R1BKQBNR w KQkq - 2 3','c1d1 d8d7 d1d5 e8d8 d5d7','hard',NULL,'2026-05-27 12:05:32'),(540,'Double rook lift #20','r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 4','f1e1 e8e7 e1e5 d8e8 e5e7','hard',NULL,'2026-05-27 12:05:32'),(541,'Battery attack','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3','c4f7 e8f7 d1h5 g7g6 h5f7','hard',NULL,'2026-05-27 12:05:32'),(542,'Battery attack (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 2 3','f4c7 d8c7 e1a5 b7b6 a5c7','hard',NULL,'2026-05-27 12:05:32'),(543,'Battery attack #21','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 5','c4f7 e8f7 d1h5 g7g6 h5f7','hard',NULL,'2026-05-27 12:05:32'),(544,'Mating net','rnb1kbnr/pppp1ppp/8/4q3/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 4 3','c4f7 e8e7 f7d5 e7f8 d5c6','hard',NULL,'2026-05-27 12:05:32'),(545,'Mating net (mirror)','rnbk1bnr/ppp1pppp/8/3q4/3P1B2/8/PPP1PPPP/RN1KQBNR w KQkq - 4 3','f4c7 d8d7 c7e5 d7c8 e5f6','hard',NULL,'2026-05-27 12:05:32'),(546,'Mating net #22','rnb1kbnr/pppp1ppp/8/4q3/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 4 6','c4f7 e8e7 f7d5 e7f8 d5c6','hard',NULL,'2026-05-27 12:05:32'),(547,'Counterattack parry','r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4','h5f7 e8f7 c4d5 f7g8 d5c6 b8c6 d1h5','hard',NULL,'2026-05-27 12:05:32'),(548,'Counterattack parry (mirror)','r1bkqb1r/ppp1pppp/2n2n2/Q2p4/3P1B2/8/PPP1PPPP/RN1K1BNR w KQkq - 4 4','a5c7 d8c7 f4e5 c7b8 e5f6 g8f6 e1a5','hard',NULL,'2026-05-27 12:05:32'),(549,'Counterattack parry #23','r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 7','h5f7 e8f7 c4d5 f7g8 d5c6 b8c6 d1h5','hard',NULL,'2026-05-27 12:05:32'),(550,'Quiet move wins','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','d1e2 e8g8 c4f7 f8e7 f7g8 a8d8','hard',NULL,'2026-05-27 12:05:32'),(551,'Quiet move wins (mirror)','r2kqbnr/ppp1pppp/2n5/3p1b2/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','e1d2 d8b8 f4c7 c8d7 c7b8 h8e8','hard',NULL,'2026-05-27 12:05:32'),(552,'Quiet move wins #24','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 8','d1e2 e8g8 c4f7 f8e7 f7g8 a8d8','hard',NULL,'2026-05-27 12:05:32'),(553,'Final blow','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4','c4f7 e8f7 f3g5 f7g8 g5e6 d8f6 e6f8 g8f8','hard',NULL,'2026-05-27 12:05:32'),(554,'Final blow (mirror)','r2kqb1r/ppp1pppp/2n2n2/3p1b2/3P1B2/2N1P3/PPP2PPP/R2KQBNR w KQkq - 0 4','f4c7 d8c7 c3b5 c7b8 b5d6 e8c6 d6c8 b8c8','hard',NULL,'2026-05-27 12:05:32'),(555,'Final blow #25','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 1','c4f7 e8f7 f3g5 f7g8 g5e6 d8f6 e6f8 g8f8','hard',NULL,'2026-05-27 12:05:32'),(556,'Tactical theme 26','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','c4f7 e8f7 f3g5 f7g8 g5h7','hard',NULL,'2026-05-27 12:05:32'),(557,'Tactical theme 26 (mirror)','r1bkqbnr/ppp1pppp/2n5/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','f4c7 d8c7 c3b5 c7b8 b5a7','hard',NULL,'2026-05-27 12:05:32'),(558,'Tactical theme 26 #26','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 2','c4f7 e8f7 f3g5 f7g8 g5h7','hard',NULL,'2026-05-27 12:05:32'),(559,'Tactical theme 27','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3','f3e5 c6e5 c4f7 e8f7 d1h5','hard',NULL,'2026-05-27 12:05:32'),(560,'Tactical theme 27 (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 2 3','c3d5 f6d5 f4c7 d8c7 e1a5','hard',NULL,'2026-05-27 12:05:32'),(561,'Tactical theme 28','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','f3g5 e8g8 g5f7 f8e7 f7d8','hard',NULL,'2026-05-27 12:05:32'),(562,'Tactical theme 28 (mirror)','r2kqbnr/ppp1pppp/2n5/3p1b2/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','c3b5 d8b8 b5c7 c8d7 c7e8','hard',NULL,'2026-05-27 12:05:32'),(563,'Tactical theme 29 #29','r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 5','h5f7 e8f7 c4d5 f7g8 d5c6','hard',NULL,'2026-05-27 12:05:32'),(564,'Tactical theme 30','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4','c4f7 e8f7 f3g5 f7g8 g5e6','hard',NULL,'2026-05-27 12:05:32'),(565,'Tactical theme 30 (mirror)','r2kqb1r/ppp1pppp/2n2n2/3p1b2/3P1B2/2N1P3/PPP2PPP/R2KQBNR w KQkq - 0 4','f4c7 d8c7 c3b5 c7b8 b5d6','hard',NULL,'2026-05-27 12:05:32'),(566,'Tactical theme 30 #30','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 6','c4f7 e8f7 f3g5 f7g8 g5e6','hard',NULL,'2026-05-27 12:05:32'),(567,'Tactical theme 31','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','f3e5 c6e5 c4f7 e8f7 d1h5','hard',NULL,'2026-05-27 12:05:32'),(568,'Tactical theme 31 (mirror)','r1bkqbnr/ppp1pppp/2n5/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','c3d5 f6d5 f4c7 d8c7 e1a5','hard',NULL,'2026-05-27 12:05:32'),(569,'Tactical theme 31 #31','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 7','f3e5 c6e5 c4f7 e8f7 d1h5','hard',NULL,'2026-05-27 12:05:32'),(570,'Tactical theme 32','r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3','f1e1 e8e7 e1e7 e7e8','hard',NULL,'2026-05-27 12:05:32'),(571,'Tactical theme 32 (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P4/2N5/PPP1PPPP/R1BKQBNR w KQkq - 2 3','c1d1 d8d7 d1d7 d7d8','hard',NULL,'2026-05-27 12:05:32'),(572,'Tactical theme 32 #32','r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 8','f1e1 e8e7 e1e7 e7e8','hard',NULL,'2026-05-27 12:05:32'),(573,'Tactical theme 33','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','c4f7 e8f7 f3g5 f7g8 g5e6','hard',NULL,'2026-05-27 12:05:32'),(574,'Tactical theme 33 (mirror)','r2kqbnr/ppp1pppp/2n5/3p1b2/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','f4c7 d8c7 c3b5 c7b8 b5d6','hard',NULL,'2026-05-27 12:05:32'),(575,'Tactical theme 33 #33','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 1','c4f7 e8f7 f3g5 f7g8 g5e6','hard',NULL,'2026-05-27 12:05:32'),(576,'Tactical theme 34','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3','c4f7 e8f7 d1f3 f7g8 f3f7','hard',NULL,'2026-05-27 12:05:32'),(577,'Tactical theme 34 (mirror)','r1bkqb1r/ppp1pppp/2n2n2/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 2 3','f4c7 d8c7 e1c3 c7b8 c3c7','hard',NULL,'2026-05-27 12:05:32'),(578,'Tactical theme 34 #34','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 2','c4f7 e8f7 d1f3 f7g8 f3f7','hard',NULL,'2026-05-27 12:05:32'),(579,'Tactical theme 35','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','f3g5 f8e7 g5f7 e8f7 c4f7','hard',NULL,'2026-05-27 12:05:32'),(580,'Tactical theme 35 (mirror)','r1bkqbnr/ppp1pppp/2n5/3p4/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','c3b5 c8d7 b5c7 d8c7 f4c7','hard',NULL,'2026-05-27 12:05:32'),(581,'Tactical theme 35 #35','rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 3','f3g5 f8e7 g5f7 e8f7 c4f7','hard',NULL,'2026-05-27 12:05:32'),(582,'Tactical theme 36','r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4','c4f7 e8f7 f3g5 f7g8 g5h7','hard',NULL,'2026-05-27 12:05:32'),(583,'Tactical theme 36 (mirror)','r2kqb1r/ppp1pppp/2n2n2/3p1b2/3P1B2/2N1P3/PPP2PPP/R2KQBNR w KQkq - 0 4','f4c7 d8c7 c3b5 c7b8 b5a7','hard',NULL,'2026-05-27 12:05:32'),(584,'Tactical theme 37','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4','c4f7 e8f7 d1h5 g7g6 h5f7','hard',NULL,'2026-05-27 12:05:32'),(585,'Tactical theme 37 (mirror)','r2kqbnr/ppp1pppp/2n5/3p1b2/3P1B2/2N5/PPP1PPPP/R2KQBNR w KQkq - 4 4','f4c7 d8c7 e1a5 b7b6 a5c7','hard',NULL,'2026-05-27 12:05:32'),(586,'Tactical theme 37 #37','rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 5','c4f7 e8f7 d1h5 g7g6 h5f7','hard',NULL,'2026-05-27 12:05:32'),(587,'Tactical theme 38','r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3','f3e5 c6e5 c4f7 e8f7 d1h5 g7g6','hard',NULL,'2026-05-27 12:05:32');
/*!40000 ALTER TABLE `puzzles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `refresh_tokens`
--

DROP TABLE IF EXISTS `refresh_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `refresh_tokens` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL,
  `token_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_refresh_user` (`user_id`),
  CONSTRAINT `fk_refresh_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=71 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `refresh_tokens`
--

LOCK TABLES `refresh_tokens` WRITE;
/*!40000 ALTER TABLE `refresh_tokens` DISABLE KEYS */;
INSERT INTO `refresh_tokens` VALUES (1,1,'e500413a6d8553e96b2e11488545c0afb93b089e3eaa66d8c7e313abbb693488','2026-06-24 12:54:33','2026-05-25 12:54:33'),(3,2,'25dcb9dffc95323c36d9ebbd4f720f35a0ae66c6353569c5404191e73d787ba0','2026-06-24 13:45:42','2026-05-25 13:45:42'),(5,1,'09e49b1d030250a9231189edadd59bf47ef7311189328da16dc6b2aa7f7b0b15','2026-06-24 16:01:12','2026-05-25 16:01:12'),(20,1,'ebe01ed0904b61e6fc7b0ff6a15c38361575be4016de84360e5c00feb860093e','2026-06-25 17:04:05','2026-05-26 17:04:05'),(21,1,'927f8d9975bf465a99ac4d7a3413daaad1a7b7eb5a04ecdd3bea2150c80b8fe0','2026-06-26 08:38:50','2026-05-27 08:38:50'),(22,1,'8d54914b7598309cbb025fdf1440c057562daebc6a2f73ca7e6b180e2f1ca962','2026-06-26 08:40:17','2026-05-27 08:40:17'),(23,1,'ca04e7b72bac4dfdc222c508465b1866034d1983c65c2e3f916d16802c9872d6','2026-06-26 08:41:21','2026-05-27 08:41:21'),(25,1,'6720512c72d2e12b4c348af04e976ddb86225365605e9b132560ec188c8b5f22','2026-06-26 08:45:34','2026-05-27 08:45:34'),(26,1,'925fa2fc282cbc1fe0b6d5771b2620cbad6aa62f0f74be07f538cc51b0270809','2026-06-26 08:55:06','2026-05-27 08:55:06'),(27,1,'1af48586f1be59b87ff96ba64da569d193547d73e8060e8b8a22d299bd5a2087','2026-06-26 08:55:48','2026-05-27 08:55:48'),(28,1,'b16f985b1d5fe7a6321ffcec1f75b3402ed467240db2cad291755ba2d91de437','2026-06-26 09:01:52','2026-05-27 09:01:52'),(29,1,'debab41f7cf4398dbc3aefa8617c778f84a709893a5bd874ee4b1c334e7e1748','2026-06-26 09:01:55','2026-05-27 09:01:55'),(30,1,'0a3e6a21f088bf021e79303a74e0fc94432b643fc13dea8db171431d4a95d4fb','2026-06-26 09:02:22','2026-05-27 09:02:22'),(31,1,'7074b3633da9885232173a5bb46abb90879e331e0c60c3d9ec2ea89bfb4ae276','2026-06-26 09:06:17','2026-05-27 09:06:17'),(32,1,'9a1e705296e95b939d80250c25ddfddd10b517d993a616dfb46b4c54635873a1','2026-06-26 09:07:22','2026-05-27 09:07:22'),(33,1,'9f38fcc2fb32f042de685bc27376ab1070532db2fcf6e68ac88bb49ceb4aa6fb','2026-06-26 09:17:14','2026-05-27 09:17:14'),(35,6,'4790e951a939415c838ac7cf9ff06b2629cb3de961fd9a1c69d8d23875bafe56','2026-06-26 10:50:25','2026-05-27 10:50:25'),(36,6,'dbab93ccc870458cbf73a3d06c39c144fc3e2181ea017ef212e8fa8b3fcb3797','2026-06-26 10:50:41','2026-05-27 10:50:41'),(38,1,'2c2f788cafaf02b612e365b5c81368d3008c68eb79f46d0778d30f7d18819a96','2026-06-26 10:52:18','2026-05-27 10:52:18'),(39,6,'e0523422bd20f49858ac5bf99ebac3eca2e578857607443267f85647afba8791','2026-06-26 11:51:55','2026-05-27 11:51:55'),(42,6,'6e56529e1290e9dcb7141d43b4ed56f60985972a834c53c1e1e52c5d50b08f51','2026-06-26 13:11:17','2026-05-27 13:11:17'),(45,6,'d9944338b4409e9e34916e39b71dc13c0f483b6b17312445498a29e3a5c3a14e','2026-06-26 17:18:05','2026-05-27 17:18:05'),(46,6,'ffbbf3a2c3a8c169f58b3dd0930016b50c40bad9fa50be1adfde5fe13cbfc1dd','2026-06-27 06:16:59','2026-05-28 06:16:59'),(48,1,'f3bbc954f83a48186df4d3ddb2c3ed3ce93c3e0c2de8c472f62f653f9066dd92','2026-06-27 07:24:07','2026-05-28 07:24:07'),(51,1,'371164c686dd5e5f8a3ac846f97a263e6d53c52f0a2c2fa9cd44ec65c43edf7c','2026-06-27 09:34:05','2026-05-28 09:34:05'),(52,6,'579ec5e92d7d248175df53bd4e29cb0aba234bf3fdf5d33d0f140c15a12753aa','2026-06-27 09:35:01','2026-05-28 09:35:01'),(53,1,'cf08f7ec5a10f5dae760dee50c18cb0597b3c21202ed3eba9a36a3425ccfd22d','2026-06-27 09:41:25','2026-05-28 09:41:25'),(55,6,'5c1b628e3561bf4aa38b4e9c248459a8b69ed6d1025d789195ad016674589663','2026-06-27 09:58:44','2026-05-28 09:58:44'),(59,6,'2d8eb6c396985d9b816170c96f8a1371068db94bd2311c819489b0b6da7de42c','2026-06-27 11:38:03','2026-05-28 11:38:03'),(63,7,'4b2dd4969a07b1a1d2fba6dfaee1a020d8686369a5af24b2a0ad353fa7dc2045','2026-06-27 12:24:24','2026-05-28 12:24:24'),(67,1,'134052d639f298945718e4814a1ac979e87e0f4e2a465ce50479fb69eb3958e1','2026-06-27 17:33:46','2026-05-28 17:33:46'),(68,6,'a411cb74c04efcb969db9d4b047903181998f0a85c49714d019802b770154d73','2026-06-27 17:39:43','2026-05-28 17:39:43'),(69,6,'49bddf96e67eb98a5802dd1f06634097c7c546c4336ab9c5e79b586ffe5221f8','2026-06-28 03:30:09','2026-05-29 03:30:09'),(70,1,'ce062383153ebdd50c6fe8abb456e4c417d8b1a109090582e709196904ab28e6','2026-06-28 03:39:38','2026-05-29 03:39:38');
/*!40000 ALTER TABLE `refresh_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `settings`
--

DROP TABLE IF EXISTS `settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `settings` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` json NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_settings_key` (`key`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `settings`
--

LOCK TABLES `settings` WRITE;
/*!40000 ALTER TABLE `settings` DISABLE KEYS */;
INSERT INTO `settings` VALUES (1,'academy_name','\"Chess Academy\"','2026-05-25 12:36:29'),(2,'timezone','\"Asia/Kolkata\"','2026-05-25 12:36:29'),(3,'default_batch_fee','1500','2026-05-25 12:36:29');
/*!40000 ALTER TABLE `settings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `students`
--

DROP TABLE IF EXISTS `students`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `students` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL,
  `parent_name` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `parent_phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `chess_rating` int NOT NULL DEFAULT '0',
  `city` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `level` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `payment_date` date DEFAULT NULL,
  `w_app` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `total_pay` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `payment_received` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `month_jan` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `month_feb` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `month_mar` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `month_apr` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `month_may` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `month_jun` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `month_jul` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `month_aug` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `month_sep` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `payment_receipt_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_lead_id` int unsigned DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_students_user` (`user_id`),
  KEY `idx_students_source_lead` (`source_lead_id`),
  CONSTRAINT `fk_students_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `students`
--

LOCK TABLES `students` WRITE;
/*!40000 ALTER TABLE `students` DISABLE KEYS */;
INSERT INTO `students` VALUES (4,6,'Puja Gope','9123456789',NULL,0,'Navi Mumbai','IB - 2','2026-05-26','9123456789',NULL,'PAID',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'bce65925b57dbdaab8f18ef7c11d558c.jpeg',6,'2026-05-26 16:58:54','2026-05-26 16:58:54'),(5,7,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-05-28 12:24:24','2026-05-28 12:24:24');
/*!40000 ALTER TABLE `students` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('admin','coach','student','accountant') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'student',
  `first_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_users_email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'admin@chessacademy.local','$2y$12$SKuVv2tv2g/JxFzGWx7RT.6Iz6BiiaGIt6g3i/VeFhsIghfWr1Age','admin','System','Admin',NULL,1,'2026-05-25 12:36:29','2026-05-25 12:36:29'),(2,'chaitanya@gmail.com','$2y$12$DqKJao55cGmGlbGhcNZ5teP3feBD1IBeNa42dSVMIIOm1J4KIAlGS','coach','Chaintanya','A','9665068639',1,'2026-05-25 13:45:42','2026-05-26 16:22:33'),(6,'puja25.gope@gmail.com','$2y$12$55y30C0M4VM0gQR90xEVlOmAdNpFHZvlrqq77btcEuXffNR5UvW0C','student','Sahiba','kaur','9123456789',1,'2026-05-26 16:58:54','2026-05-27 10:50:25'),(7,'satishdhere007@gmail.com','$2y$12$4/2p6Uk8rA8Y3Pcq1dQtme4s50dbsDm5mc2D4CfNhajlRo0sPnD3q','student','Amol','Dhere','9405487216',1,'2026-05-28 12:24:24','2026-05-28 12:24:24');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'chess_academy'
--
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-05-31 14:10:22
