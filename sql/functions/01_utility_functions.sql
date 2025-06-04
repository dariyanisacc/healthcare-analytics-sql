-- Healthcare Analytics Utility Functions
-- Reusable functions for data processing and calculations

USE healthcare_analytics;

DELIMITER //

-- 1. Function to calculate patient age
CREATE FUNCTION GetPatientAge(p_patient_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE patient_age INT;
    
    SELECT TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) INTO patient_age
    FROM patients
    WHERE patient_id = p_patient_id;
    
    RETURN patient_age;
END//

-- 2. Function to format ICD-10 codes
CREATE FUNCTION FormatICD10Code(icd_code VARCHAR(10))
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
    DECLARE formatted_code VARCHAR(10);
    
    -- Remove any dots and spaces
    SET formatted_code = REPLACE(REPLACE(icd_code, '.', ''), ' ', '');
    
    -- Add dot after 3rd character if code is longer than 3 characters
    IF LENGTH(formatted_code) > 3 THEN
        SET formatted_code = CONCAT(
            SUBSTRING(formatted_code, 1, 3),
            '.',
            SUBSTRING(formatted_code, 4)
        );
    END IF;
    
    RETURN formatted_code;
END//

-- 3. Function to calculate BMI
CREATE FUNCTION CalculateBMI(height_cm DECIMAL(5,1), weight_kg DECIMAL(5,2))
RETURNS DECIMAL(4,1)
DETERMINISTIC
BEGIN
    DECLARE bmi DECIMAL(4,1);
    
    IF height_cm > 0 AND weight_kg > 0 THEN
        SET bmi = weight_kg / POWER(height_cm/100, 2);
    ELSE
        SET bmi = NULL;
    END IF;
    
    RETURN ROUND(bmi, 1);
END//

-- 4. Function to categorize BMI
CREATE FUNCTION GetBMICategory(bmi DECIMAL(4,1))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE category VARCHAR(20);
    
    IF bmi IS NULL THEN
        SET category = 'Unknown';
    ELSEIF bmi < 18.5 THEN
        SET category = 'Underweight';
    ELSEIF bmi < 25 THEN
        SET category = 'Normal';
    ELSEIF bmi < 30 THEN
        SET category = 'Overweight';
    ELSEIF bmi < 35 THEN
        SET category = 'Obese Class I';
    ELSEIF bmi < 40 THEN
        SET category = 'Obese Class II';
    ELSE
        SET category = 'Obese Class III';
    END IF;
    
    RETURN category;
END//

-- 5. Function to calculate days between dates
CREATE FUNCTION GetDaysBetween(start_date DATE, end_date DATE)
RETURNS INT
DETERMINISTIC
BEGIN
    IF start_date IS NULL OR end_date IS NULL THEN
        RETURN NULL;
    END IF;
    
    RETURN DATEDIFF(end_date, start_date);
END//

-- 6. Function to get fiscal quarter
CREATE FUNCTION GetFiscalQuarter(date_value DATE)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
    DECLARE fiscal_quarter VARCHAR(10);
    DECLARE month_num INT;
    
    SET month_num = MONTH(date_value);
    
    -- Assuming fiscal year starts in January
    IF month_num IN (1, 2, 3) THEN
        SET fiscal_quarter = CONCAT('FY', YEAR(date_value), '-Q1');
    ELSEIF month_num IN (4, 5, 6) THEN
        SET fiscal_quarter = CONCAT('FY', YEAR(date_value), '-Q2');
    ELSEIF month_num IN (7, 8, 9) THEN
        SET fiscal_quarter = CONCAT('FY', YEAR(date_value), '-Q3');
    ELSE
        SET fiscal_quarter = CONCAT('FY', YEAR(date_value), '-Q4');
    END IF;
    
    RETURN fiscal_quarter;
END//

-- 7. Function to check if lab result is critical
CREATE FUNCTION IsLabCritical(test_code VARCHAR(20), result_value VARCHAR(100))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE is_critical BOOLEAN DEFAULT FALSE;
    DECLARE numeric_value DECIMAL(10,2);
    
    -- Try to convert result to numeric
    SET numeric_value = CAST(result_value AS DECIMAL(10,2));
    
    -- Check critical values based on test code
    CASE test_code
        WHEN 'GLUC' THEN
            IF numeric_value < 40 OR numeric_value > 500 THEN
                SET is_critical = TRUE;
            END IF;
        WHEN 'K' THEN
            IF numeric_value < 2.5 OR numeric_value > 6.5 THEN
                SET is_critical = TRUE;
            END IF;
        WHEN 'NA' THEN
            IF numeric_value < 120 OR numeric_value > 160 THEN
                SET is_critical = TRUE;
            END IF;
        WHEN 'HGB' THEN
            IF numeric_value < 7.0 OR numeric_value > 20.0 THEN
                SET is_critical = TRUE;
            END IF;
        WHEN 'PLT' THEN
            IF numeric_value < 20 OR numeric_value > 1000 THEN
                SET is_critical = TRUE;
            END IF;
        WHEN 'TROP' THEN
            IF numeric_value > 0.04 THEN
                SET is_critical = TRUE;
            END IF;
    END CASE;
    
    RETURN is_critical;
END//

-- 8. Function to calculate comorbidity index
CREATE FUNCTION CalculateComorbidityIndex(p_patient_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE cci_score INT DEFAULT 0;
    
    -- Simplified Charlson Comorbidity Index calculation
    -- Check for various conditions and add points
    
    -- Myocardial infarction
    SELECT cci_score + 
        CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END INTO cci_score
    FROM diagnoses d
    JOIN encounters e ON d.encounter_id = e.encounter_id
    WHERE e.patient_id = p_patient_id AND d.icd10_code LIKE 'I21%';
    
    -- Congestive heart failure
    SELECT cci_score + 
        CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END INTO cci_score
    FROM diagnoses d
    JOIN encounters e ON d.encounter_id = e.encounter_id
    WHERE e.patient_id = p_patient_id AND d.icd10_code LIKE 'I50%';
    
    -- Diabetes
    SELECT cci_score + 
        CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END INTO cci_score
    FROM diagnoses d
    JOIN encounters e ON d.encounter_id = e.encounter_id
    WHERE e.patient_id = p_patient_id AND d.icd10_code LIKE 'E11%';
    
    -- COPD
    SELECT cci_score + 
        CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END INTO cci_score
    FROM diagnoses d
    JOIN encounters e ON d.encounter_id = e.encounter_id
    WHERE e.patient_id = p_patient_id AND d.icd10_code LIKE 'J44%';
    
    -- Renal disease
    SELECT cci_score + 
        CASE WHEN COUNT(*) > 0 THEN 2 ELSE 0 END INTO cci_score
    FROM diagnoses d
    JOIN encounters e ON d.encounter_id = e.encounter_id
    WHERE e.patient_id = p_patient_id AND d.icd10_code LIKE 'N18%';
    
    RETURN cci_score;
END//

-- 9. Function to get insurance coverage percentage
CREATE FUNCTION GetInsuranceCoveragePercent(charge_amount DECIMAL(10,2), paid_amount DECIMAL(10,2))
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    IF charge_amount IS NULL OR charge_amount = 0 THEN
        RETURN 0;
    END IF;
    
    RETURN ROUND((COALESCE(paid_amount, 0) / charge_amount) * 100, 2);
END//

-- 10. Function to determine encounter shift
CREATE FUNCTION GetEncounterShift(encounter_datetime DATETIME)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
    DECLARE hour_of_day INT;
    DECLARE shift VARCHAR(10);
    
    SET hour_of_day = HOUR(encounter_datetime);
    
    IF hour_of_day >= 7 AND hour_of_day < 15 THEN
        SET shift = 'Day';
    ELSEIF hour_of_day >= 15 AND hour_of_day < 23 THEN
        SET shift = 'Evening';
    ELSE
        SET shift = 'Night';
    END IF;
    
    RETURN shift;
END//

DELIMITER ;