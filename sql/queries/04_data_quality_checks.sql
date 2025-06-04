-- Data Quality Checks for Healthcare Analytics
-- Comprehensive validation queries to ensure data integrity

USE healthcare_analytics;

-- 1. Patient Data Quality Checks
SELECT 'PATIENT DATA QUALITY' as check_category;

-- Check for duplicate medical record numbers
SELECT 
    'Duplicate MRNs' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM (
    SELECT medical_record_number, COUNT(*) as cnt
    FROM patients
    GROUP BY medical_record_number
    HAVING COUNT(*) > 1
) duplicates;

-- Check for invalid dates of birth
SELECT 
    'Invalid DOB' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM patients
WHERE date_of_birth > CURDATE() 
   OR date_of_birth < '1900-01-01'
   OR TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) > 120;

-- Check for missing critical patient information
SELECT 
    'Missing Patient Info' as check_name,
    SUM(CASE WHEN first_name IS NULL OR first_name = '' THEN 1 ELSE 0 END) as missing_first_name,
    SUM(CASE WHEN last_name IS NULL OR last_name = '' THEN 1 ELSE 0 END) as missing_last_name,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) as missing_gender,
    SUM(CASE WHEN date_of_birth IS NULL THEN 1 ELSE 0 END) as missing_dob
FROM patients;

-- 2. Encounter Data Quality Checks
SELECT 'ENCOUNTER DATA QUALITY' as check_category;

-- Check for encounters with invalid dates
SELECT 
    'Invalid Encounter Dates' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM encounters
WHERE encounter_date > CURDATE()
   OR (discharge_date IS NOT NULL AND discharge_date < admission_date)
   OR (admission_date IS NOT NULL AND admission_date > encounter_date);

-- Check for orphaned encounters (no valid patient)
SELECT 
    'Orphaned Encounters' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM encounters e
LEFT JOIN patients p ON e.patient_id = p.patient_id
WHERE p.patient_id IS NULL;

-- Check for encounters with impossible length of stay
SELECT 
    'Invalid Length of Stay' as check_name,
    COUNT(*) as issue_count,
    GROUP_CONCAT(encounter_id) as affected_encounters
FROM encounters
WHERE length_of_stay < 0 
   OR length_of_stay > 365;

-- 3. Diagnosis Data Quality Checks
SELECT 'DIAGNOSIS DATA QUALITY' as check_category;

-- Check for invalid ICD-10 codes format
SELECT 
    'Invalid ICD-10 Format' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM diagnoses
WHERE icd10_code NOT REGEXP '^[A-Z][0-9]{2}(\.[0-9]{1,4})?$';

-- Check for missing diagnosis descriptions
SELECT 
    'Missing Diagnosis Descriptions' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM diagnoses
WHERE diagnosis_description IS NULL 
   OR diagnosis_description = '';

-- Check for diagnoses without valid encounters
SELECT 
    'Orphaned Diagnoses' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM diagnoses d
LEFT JOIN encounters e ON d.encounter_id = e.encounter_id
WHERE e.encounter_id IS NULL;

-- 4. Laboratory Data Quality Checks
SELECT 'LABORATORY DATA QUALITY' as check_category;

-- Check for lab results with future dates
SELECT 
    'Future Lab Dates' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM lab_results
WHERE collection_datetime > NOW()
   OR result_datetime > NOW();

-- Check for results before collection
SELECT 
    'Results Before Collection' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM lab_results
WHERE result_datetime < collection_datetime;

-- Check for invalid lab values
SELECT 
    'Invalid Lab Values' as check_name,
    test_code,
    COUNT(*) as issue_count,
    MIN(CAST(result_value AS DECIMAL(10,2))) as min_value,
    MAX(CAST(result_value AS DECIMAL(10,2))) as max_value
FROM lab_results
WHERE result_value REGEXP '^[0-9]+\.?[0-9]*$'
GROUP BY test_code
HAVING MIN(CAST(result_value AS DECIMAL(10,2))) < 0;

-- 5. Medication Data Quality Checks
SELECT 'MEDICATION DATA QUALITY' as check_category;

-- Check for medications with end date before start date
SELECT 
    'Invalid Medication Dates' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM medications
WHERE end_date < start_date;

-- Check for active medications with past end dates
SELECT 
    'Expired Active Medications' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM medications
WHERE is_active = TRUE 
  AND end_date < CURDATE();

-- 6. Vital Signs Data Quality Checks
SELECT 'VITAL SIGNS DATA QUALITY' as check_category;

-- Check for physiologically impossible vital signs
SELECT 
    'Impossible Vital Signs' as check_name,
    SUM(CASE WHEN temperature < 90 OR temperature > 115 THEN 1 ELSE 0 END) as invalid_temp,
    SUM(CASE WHEN pulse < 20 OR pulse > 300 THEN 1 ELSE 0 END) as invalid_pulse,
    SUM(CASE WHEN respiratory_rate < 0 OR respiratory_rate > 100 THEN 1 ELSE 0 END) as invalid_rr,
    SUM(CASE WHEN blood_pressure_systolic < 50 OR blood_pressure_systolic > 300 THEN 1 ELSE 0 END) as invalid_sbp,
    SUM(CASE WHEN blood_pressure_diastolic < 20 OR blood_pressure_diastolic > 200 THEN 1 ELSE 0 END) as invalid_dbp,
    SUM(CASE WHEN oxygen_saturation < 0 OR oxygen_saturation > 100 THEN 1 ELSE 0 END) as invalid_o2sat
FROM vital_signs;

-- Check for vital signs with future timestamps
SELECT 
    'Future Vital Signs' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM vital_signs
WHERE measurement_datetime > NOW();

-- 7. Billing Data Quality Checks
SELECT 'BILLING DATA QUALITY' as check_category;

-- Check for negative amounts
SELECT 
    'Negative Billing Amounts' as check_name,
    SUM(CASE WHEN charge_amount < 0 THEN 1 ELSE 0 END) as negative_charges,
    SUM(CASE WHEN paid_amount < 0 THEN 1 ELSE 0 END) as negative_payments,
    SUM(CASE WHEN patient_responsibility < 0 THEN 1 ELSE 0 END) as negative_patient_resp
FROM billing;

-- Check for payments exceeding charges
SELECT 
    'Overpayments' as check_name,
    COUNT(*) as issue_count,
    SUM(paid_amount - charge_amount) as total_overpayment
FROM billing
WHERE paid_amount > charge_amount;

-- Check for orphaned billing records
SELECT 
    'Orphaned Billing Records' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM billing b
LEFT JOIN encounters e ON b.encounter_id = e.encounter_id
WHERE e.encounter_id IS NULL;

-- 8. Provider Data Quality Checks
SELECT 'PROVIDER DATA QUALITY' as check_category;

-- Check for duplicate NPIs
SELECT 
    'Duplicate NPIs' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM (
    SELECT npi, COUNT(*) as cnt
    FROM providers
    GROUP BY npi
    HAVING COUNT(*) > 1
) duplicates;

-- Check for invalid NPI format (should be 10 digits)
SELECT 
    'Invalid NPI Format' as check_name,
    COUNT(*) as issue_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM providers
WHERE LENGTH(npi) != 10 
   OR npi NOT REGEXP '^[0-9]+$';

-- 9. Summary Data Quality Report
SELECT 'DATA QUALITY SUMMARY' as report_type;

WITH quality_metrics AS (
    SELECT 
        'Total Records' as metric,
        'Patients' as entity,
        COUNT(*) as count
    FROM patients
    UNION ALL
    SELECT 'Total Records', 'Encounters', COUNT(*) FROM encounters
    UNION ALL
    SELECT 'Total Records', 'Diagnoses', COUNT(*) FROM diagnoses
    UNION ALL
    SELECT 'Total Records', 'Procedures', COUNT(*) FROM procedures
    UNION ALL
    SELECT 'Total Records', 'Lab Results', COUNT(*) FROM lab_results
    UNION ALL
    SELECT 'Total Records', 'Medications', COUNT(*) FROM medications
    UNION ALL
    SELECT 'Total Records', 'Vital Signs', COUNT(*) FROM vital_signs
    UNION ALL
    SELECT 'Total Records', 'Billing', COUNT(*) FROM billing
)
SELECT * FROM quality_metrics
ORDER BY entity;

-- 10. Data Completeness Report
SELECT 
    'Patients' as table_name,
    COUNT(*) as total_records,
    ROUND(100.0 * SUM(CASE WHEN email IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as email_completeness,
    ROUND(100.0 * SUM(CASE WHEN phone IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as phone_completeness,
    ROUND(100.0 * SUM(CASE WHEN insurance_provider IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as insurance_completeness
FROM patients
UNION ALL
SELECT 
    'Encounters' as table_name,
    COUNT(*) as total_records,
    ROUND(100.0 * SUM(CASE WHEN chief_complaint IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as chief_complaint_completeness,
    ROUND(100.0 * SUM(CASE WHEN discharge_disposition IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as disposition_completeness,
    NULL as insurance_completeness
FROM encounters;