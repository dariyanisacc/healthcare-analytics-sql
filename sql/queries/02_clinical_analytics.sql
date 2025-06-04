-- Clinical Analytics Queries
-- Advanced queries for clinical outcomes and quality metrics

USE healthcare_analytics;

-- 1. Hospital Readmission Analysis (30-day readmissions)
WITH readmissions AS (
    SELECT 
        e1.patient_id,
        e1.encounter_id as initial_encounter,
        e1.discharge_date as initial_discharge,
        e2.encounter_id as readmit_encounter,
        e2.admission_date as readmit_date,
        DATEDIFF(e2.admission_date, e1.discharge_date) as days_to_readmit,
        d1.icd10_code as initial_diagnosis,
        d1.diagnosis_description as initial_diagnosis_desc
    FROM encounters e1
    JOIN encounters e2 ON e1.patient_id = e2.patient_id
        AND e2.admission_date > e1.discharge_date
        AND e2.admission_date <= DATE_ADD(e1.discharge_date, INTERVAL 30 DAY)
        AND e2.encounter_type = 'Inpatient'
    JOIN diagnoses d1 ON e1.encounter_id = d1.encounter_id AND d1.diagnosis_type = 'Primary'
    WHERE e1.encounter_type = 'Inpatient'
        AND e1.discharge_date IS NOT NULL
)
SELECT 
    COUNT(DISTINCT r.initial_encounter) as total_discharges,
    COUNT(DISTINCT r.readmit_encounter) as total_readmissions,
    ROUND(COUNT(DISTINCT r.readmit_encounter) * 100.0 / COUNT(DISTINCT e.encounter_id), 2) as readmission_rate,
    AVG(r.days_to_readmit) as avg_days_to_readmit,
    r.initial_diagnosis,
    r.initial_diagnosis_desc,
    COUNT(DISTINCT r.readmit_encounter) as readmissions_by_diagnosis
FROM encounters e
LEFT JOIN readmissions r ON e.encounter_id = r.initial_encounter
WHERE e.encounter_type = 'Inpatient' AND e.discharge_date IS NOT NULL
GROUP BY r.initial_diagnosis, r.initial_diagnosis_desc
ORDER BY readmissions_by_diagnosis DESC;

-- 2. Emergency Department Efficiency Metrics
WITH ed_metrics AS (
    SELECT 
        e.encounter_id,
        e.patient_id,
        e.admission_date as arrival_time,
        e.discharge_date as departure_time,
        TIMESTAMPDIFF(MINUTE, e.admission_date, e.discharge_date) as los_minutes,
        e.discharge_disposition,
        COUNT(DISTINCT p.procedure_id) as procedures_performed,
        COUNT(DISTINCT l.lab_id) as labs_ordered,
        MIN(v.measurement_datetime) as first_vitals_time,
        TIMESTAMPDIFF(MINUTE, e.admission_date, MIN(v.measurement_datetime)) as time_to_vitals
    FROM encounters e
    LEFT JOIN procedures p ON e.encounter_id = p.encounter_id
    LEFT JOIN lab_results l ON e.encounter_id = l.encounter_id
    LEFT JOIN vital_signs v ON e.encounter_id = v.encounter_id
    WHERE e.encounter_type = 'Emergency'
    GROUP BY e.encounter_id
)
SELECT 
    COUNT(DISTINCT encounter_id) as total_ed_visits,
    ROUND(AVG(los_minutes) / 60.0, 2) as avg_los_hours,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY los_minutes) / 60.0, 2) as median_los_hours,
    ROUND(AVG(time_to_vitals), 2) as avg_time_to_vitals_min,
    SUM(CASE WHEN discharge_disposition = 'Admitted' THEN 1 ELSE 0 END) as admissions_from_ed,
    ROUND(SUM(CASE WHEN discharge_disposition = 'Admitted' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as admission_rate,
    SUM(CASE WHEN los_minutes < 120 THEN 1 ELSE 0 END) as visits_under_2hrs,
    SUM(CASE WHEN los_minutes >= 240 THEN 1 ELSE 0 END) as visits_over_4hrs,
    AVG(procedures_performed) as avg_procedures_per_visit,
    AVG(labs_ordered) as avg_labs_per_visit
FROM ed_metrics;

-- 3. Sepsis Bundle Compliance Analysis
WITH sepsis_patients AS (
    SELECT DISTINCT
        e.encounter_id,
        e.patient_id,
        e.admission_date,
        d.diagnosis_date as sepsis_diagnosis_time,
        -- Check for blood cultures
        MAX(CASE WHEN l.test_code = 'BLDCX' THEN 1 ELSE 0 END) as blood_culture_drawn,
        MIN(CASE WHEN l.test_code = 'BLDCX' THEN l.collection_datetime END) as blood_culture_time,
        -- Check for lactate
        MAX(CASE WHEN l.test_code = 'LACT' THEN 1 ELSE 0 END) as lactate_measured,
        MIN(CASE WHEN l.test_code = 'LACT' THEN l.collection_datetime END) as lactate_time,
        -- Check for antibiotics
        MAX(CASE WHEN m.medication_name LIKE '%cillin%' OR m.medication_name LIKE '%cycline%' 
                 OR m.medication_name LIKE '%mycin%' THEN 1 ELSE 0 END) as antibiotics_given,
        MIN(CASE WHEN m.medication_name LIKE '%cillin%' OR m.medication_name LIKE '%cycline%' 
                 OR m.medication_name LIKE '%mycin%' THEN m.start_date END) as antibiotic_time
    FROM encounters e
    JOIN diagnoses d ON e.encounter_id = d.encounter_id
    LEFT JOIN lab_results l ON e.encounter_id = l.encounter_id
    LEFT JOIN medications m ON e.encounter_id = m.encounter_id
    WHERE d.icd10_code LIKE 'A41%' -- Sepsis codes
    GROUP BY e.encounter_id
)
SELECT 
    COUNT(*) as total_sepsis_cases,
    SUM(blood_culture_drawn) as blood_cultures_drawn,
    SUM(lactate_measured) as lactate_measured,
    SUM(antibiotics_given) as antibiotics_administered,
    SUM(CASE WHEN blood_culture_drawn = 1 AND lactate_measured = 1 AND antibiotics_given = 1 THEN 1 ELSE 0 END) as full_bundle_compliance,
    ROUND(SUM(CASE WHEN blood_culture_drawn = 1 AND lactate_measured = 1 AND antibiotics_given = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as bundle_compliance_rate,
    AVG(TIMESTAMPDIFF(MINUTE, sepsis_diagnosis_time, antibiotic_time)) as avg_time_to_antibiotics_min
FROM sepsis_patients;

-- 4. Provider Performance Metrics
WITH provider_metrics AS (
    SELECT 
        p.provider_id,
        p.first_name,
        p.last_name,
        p.specialty,
        COUNT(DISTINCT e.encounter_id) as total_encounters,
        COUNT(DISTINCT e.patient_id) as unique_patients,
        AVG(e.length_of_stay) as avg_los,
        COUNT(DISTINCT CASE WHEN e.encounter_type = 'Inpatient' THEN e.encounter_id END) as inpatient_cases,
        COUNT(DISTINCT proc.procedure_id) as procedures_performed
    FROM providers p
    JOIN encounters e ON p.provider_id = e.provider_id
    LEFT JOIN procedures proc ON p.provider_id = proc.provider_id
    WHERE p.is_active = TRUE
    GROUP BY p.provider_id
),
quality_scores AS (
    SELECT 
        e.provider_id,
        AVG(CASE WHEN qm.performance_met = TRUE THEN 100 ELSE 0 END) as quality_score
    FROM encounters e
    JOIN quality_measures qm ON e.patient_id = qm.patient_id
        AND qm.measurement_date BETWEEN e.encounter_date AND COALESCE(e.discharge_date, e.encounter_date)
    GROUP BY e.provider_id
)
SELECT 
    pm.provider_id,
    CONCAT(pm.first_name, ' ', pm.last_name) as provider_name,
    pm.specialty,
    pm.total_encounters,
    pm.unique_patients,
    ROUND(pm.avg_los, 2) as avg_length_of_stay,
    pm.procedures_performed,
    ROUND(pm.total_encounters * 1.0 / 30, 2) as encounters_per_day,
    COALESCE(ROUND(qs.quality_score, 2), 0) as quality_score_pct,
    CASE 
        WHEN pm.total_encounters >= 50 AND COALESCE(qs.quality_score, 0) >= 80 THEN 'High Performer'
        WHEN pm.total_encounters >= 25 AND COALESCE(qs.quality_score, 0) >= 70 THEN 'Good Performer'
        ELSE 'Needs Improvement'
    END as performance_category
FROM provider_metrics pm
LEFT JOIN quality_scores qs ON pm.provider_id = qs.provider_id
ORDER BY pm.total_encounters DESC;

-- 5. Clinical Pathway Adherence for Heart Failure
WITH hf_patients AS (
    SELECT 
        e.encounter_id,
        e.patient_id,
        e.admission_date,
        e.discharge_date,
        -- Check for required medications
        MAX(CASE WHEN m.medication_name LIKE '%pril' OR m.medication_name LIKE '%sartan' THEN 1 ELSE 0 END) as ace_arb_prescribed,
        MAX(CASE WHEN m.medication_name LIKE '%olol' OR m.medication_name LIKE '%vedilol' THEN 1 ELSE 0 END) as beta_blocker_prescribed,
        MAX(CASE WHEN m.medication_name LIKE '%semide' OR m.medication_name LIKE 'Spironolactone' THEN 1 ELSE 0 END) as diuretic_prescribed,
        -- Check for diagnostic tests
        MAX(CASE WHEN p.cpt_code IN ('93306', '93307', '93308') THEN 1 ELSE 0 END) as echo_performed,
        MAX(CASE WHEN l.test_code = 'BNP' OR l.test_code = 'NTBNP' THEN 1 ELSE 0 END) as bnp_measured,
        -- Check for patient education
        MAX(CASE WHEN p.cpt_code IN ('99214', '99215') THEN 1 ELSE 0 END) as education_documented
    FROM encounters e
    JOIN diagnoses d ON e.encounter_id = d.encounter_id
    LEFT JOIN medications m ON e.encounter_id = m.encounter_id
    LEFT JOIN procedures p ON e.encounter_id = p.encounter_id
    LEFT JOIN lab_results l ON e.encounter_id = l.encounter_id
    WHERE d.icd10_code LIKE 'I50%' -- Heart failure
        AND e.encounter_type = 'Inpatient'
    GROUP BY e.encounter_id
)
SELECT 
    COUNT(*) as total_hf_admissions,
    SUM(ace_arb_prescribed) as on_ace_or_arb,
    SUM(beta_blocker_prescribed) as on_beta_blocker,
    SUM(diuretic_prescribed) as on_diuretic,
    SUM(echo_performed) as echo_completed,
    SUM(bnp_measured) as bnp_measured,
    ROUND(SUM(ace_arb_prescribed) * 100.0 / COUNT(*), 2) as ace_arb_rate,
    ROUND(SUM(beta_blocker_prescribed) * 100.0 / COUNT(*), 2) as beta_blocker_rate,
    ROUND(SUM(echo_performed) * 100.0 / COUNT(*), 2) as echo_rate,
    SUM(CASE WHEN ace_arb_prescribed = 1 AND beta_blocker_prescribed = 1 
             AND echo_performed = 1 AND bnp_measured = 1 THEN 1 ELSE 0 END) as full_pathway_adherence,
    ROUND(SUM(CASE WHEN ace_arb_prescribed = 1 AND beta_blocker_prescribed = 1 
                   AND echo_performed = 1 AND bnp_measured = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as pathway_adherence_rate
FROM hf_patients;