-- Patient Analytics Queries
-- Complex queries for patient population analysis

USE healthcare_analytics;

-- 1. Patient Demographics Summary
SELECT 
    COUNT(DISTINCT patient_id) as total_patients,
    ROUND(AVG(TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE())), 1) as avg_age,
    SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) as male_count,
    SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) as female_count,
    COUNT(DISTINCT insurance_provider) as insurance_providers,
    COUNT(DISTINCT CONCAT(city, ', ', state)) as unique_locations
FROM patients;

-- 2. Patient Risk Stratification Based on Conditions and Age
WITH patient_conditions AS (
    SELECT 
        p.patient_id,
        p.first_name,
        p.last_name,
        TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) as age,
        COUNT(DISTINCT d.icd10_code) as condition_count,
        MAX(CASE WHEN d.icd10_code LIKE 'E11%' THEN 1 ELSE 0 END) as has_diabetes,
        MAX(CASE WHEN d.icd10_code LIKE 'I10%' THEN 1 ELSE 0 END) as has_hypertension,
        MAX(CASE WHEN d.icd10_code IN ('I21%', 'I25%') THEN 1 ELSE 0 END) as has_heart_disease
    FROM patients p
    LEFT JOIN encounters e ON p.patient_id = e.patient_id
    LEFT JOIN diagnoses d ON e.encounter_id = d.encounter_id
    GROUP BY p.patient_id
)
SELECT 
    patient_id,
    first_name,
    last_name,
    age,
    condition_count,
    CASE 
        WHEN age >= 65 AND (has_diabetes + has_hypertension + has_heart_disease) >= 2 THEN 'High Risk'
        WHEN age >= 50 AND (has_diabetes + has_hypertension + has_heart_disease) >= 1 THEN 'Medium Risk'
        WHEN condition_count >= 3 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END as risk_category
FROM patient_conditions
ORDER BY 
    CASE 
        WHEN age >= 65 AND (has_diabetes + has_hypertension + has_heart_disease) >= 2 THEN 1
        WHEN age >= 50 AND (has_diabetes + has_hypertension + has_heart_disease) >= 1 THEN 2
        WHEN condition_count >= 3 THEN 2
        ELSE 3
    END,
    age DESC;

-- 3. Patient Utilization Analysis
SELECT 
    p.patient_id,
    p.first_name,
    p.last_name,
    COUNT(DISTINCT e.encounter_id) as total_encounters,
    COUNT(DISTINCT CASE WHEN e.encounter_type = 'Emergency' THEN e.encounter_id END) as ed_visits,
    COUNT(DISTINCT CASE WHEN e.encounter_type = 'Inpatient' THEN e.encounter_id END) as admissions,
    COUNT(DISTINCT CASE WHEN e.encounter_type = 'Outpatient' THEN e.encounter_id END) as outpatient_visits,
    COALESCE(SUM(e.length_of_stay), 0) as total_los_days,
    ROUND(COALESCE(AVG(e.length_of_stay), 0), 1) as avg_los_days,
    MAX(e.encounter_date) as last_visit_date,
    DATEDIFF(CURDATE(), MAX(e.encounter_date)) as days_since_last_visit
FROM patients p
LEFT JOIN encounters e ON p.patient_id = e.patient_id
GROUP BY p.patient_id
HAVING COUNT(DISTINCT e.encounter_id) > 0
ORDER BY total_encounters DESC;

-- 4. Chronic Disease Management Dashboard
WITH chronic_patients AS (
    SELECT DISTINCT
        p.patient_id,
        p.first_name,
        p.last_name,
        p.date_of_birth,
        MAX(CASE WHEN d.icd10_code LIKE 'E11%' THEN 1 ELSE 0 END) as has_diabetes,
        MAX(CASE WHEN d.icd10_code LIKE 'I10%' THEN 1 ELSE 0 END) as has_hypertension,
        MAX(CASE WHEN d.icd10_code LIKE 'J44%' THEN 1 ELSE 0 END) as has_copd,
        MAX(CASE WHEN d.icd10_code IN ('I21%', 'I25%') THEN 1 ELSE 0 END) as has_cad
    FROM patients p
    JOIN encounters e ON p.patient_id = e.patient_id
    JOIN diagnoses d ON e.encounter_id = d.encounter_id
    WHERE d.icd10_code IN ('E11%', 'I10%', 'J44%', 'I21%', 'I25%')
    GROUP BY p.patient_id
),
latest_labs AS (
    SELECT 
        l.patient_id,
        MAX(CASE WHEN l.test_code = 'HBA1C' THEN l.result_value END) as latest_hba1c,
        MAX(CASE WHEN l.test_code = 'HBA1C' THEN l.collection_datetime END) as hba1c_date,
        MAX(CASE WHEN l.test_code = 'LIPID' THEN l.result_value END) as latest_cholesterol,
        MAX(CASE WHEN l.test_code = 'LIPID' THEN l.collection_datetime END) as cholesterol_date
    FROM lab_results l
    WHERE l.test_code IN ('HBA1C', 'LIPID')
    GROUP BY l.patient_id
)
SELECT 
    cp.patient_id,
    cp.first_name,
    cp.last_name,
    TIMESTAMPDIFF(YEAR, cp.date_of_birth, CURDATE()) as age,
    CASE 
        WHEN cp.has_diabetes = 1 THEN 'Yes' ELSE 'No' 
    END as diabetes,
    CASE 
        WHEN cp.has_hypertension = 1 THEN 'Yes' ELSE 'No' 
    END as hypertension,
    CASE 
        WHEN cp.has_copd = 1 THEN 'Yes' ELSE 'No' 
    END as copd,
    CASE 
        WHEN cp.has_cad = 1 THEN 'Yes' ELSE 'No' 
    END as heart_disease,
    ll.latest_hba1c,
    DATEDIFF(CURDATE(), ll.hba1c_date) as days_since_hba1c,
    ll.latest_cholesterol,
    DATEDIFF(CURDATE(), ll.cholesterol_date) as days_since_cholesterol,
    CASE 
        WHEN cp.has_diabetes = 1 AND (ll.hba1c_date IS NULL OR DATEDIFF(CURDATE(), ll.hba1c_date) > 180) THEN 'Overdue HbA1c'
        WHEN cp.has_cad = 1 AND (ll.cholesterol_date IS NULL OR DATEDIFF(CURDATE(), ll.cholesterol_date) > 365) THEN 'Overdue Lipid Panel'
        ELSE 'Up to date'
    END as care_gap
FROM chronic_patients cp
LEFT JOIN latest_labs ll ON cp.patient_id = ll.patient_id
ORDER BY 
    CASE 
        WHEN cp.has_diabetes = 1 AND (ll.hba1c_date IS NULL OR DATEDIFF(CURDATE(), ll.hba1c_date) > 180) THEN 1
        WHEN cp.has_cad = 1 AND (ll.cholesterol_date IS NULL OR DATEDIFF(CURDATE(), ll.cholesterol_date) > 365) THEN 2
        ELSE 3
    END;

-- 5. Patient Medication Adherence Analysis
WITH medication_adherence AS (
    SELECT 
        p.patient_id,
        p.first_name,
        p.last_name,
        m.medication_name,
        m.start_date,
        m.end_date,
        m.is_active,
        DATEDIFF(COALESCE(m.end_date, CURDATE()), m.start_date) as therapy_duration_days,
        COUNT(DISTINCT e.encounter_id) as follow_up_visits
    FROM patients p
    JOIN medications m ON p.patient_id = m.patient_id
    LEFT JOIN encounters e ON p.patient_id = e.patient_id 
        AND e.encounter_date >= m.start_date 
        AND (m.end_date IS NULL OR e.encounter_date <= m.end_date)
        AND e.encounter_type = 'Outpatient'
    WHERE m.medication_name IN ('Metformin', 'Lisinopril', 'Atorvastatin', 'Metoprolol')
    GROUP BY p.patient_id, m.medication_id
)
SELECT 
    patient_id,
    first_name,
    last_name,
    medication_name,
    therapy_duration_days,
    follow_up_visits,
    CASE 
        WHEN therapy_duration_days >= 180 AND follow_up_visits >= 2 THEN 'Good Adherence'
        WHEN therapy_duration_days >= 90 AND follow_up_visits >= 1 THEN 'Fair Adherence'
        ELSE 'Poor Adherence'
    END as adherence_category
FROM medication_adherence
ORDER BY patient_id, medication_name;