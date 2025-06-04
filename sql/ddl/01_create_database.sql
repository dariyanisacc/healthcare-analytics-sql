-- Healthcare Analytics Database
-- Purpose: Comprehensive healthcare data warehouse for analytics and reporting
-- Author: Healthcare Analytics Project
-- Date: 2025-01-06

-- Create database
CREATE DATABASE IF NOT EXISTS healthcare_analytics;
USE healthcare_analytics;

-- Set appropriate settings for healthcare data
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';