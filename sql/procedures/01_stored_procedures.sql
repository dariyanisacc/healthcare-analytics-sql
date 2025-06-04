-- Healthcare Analytics Stored Procedures
-- Reusable procedures for common analytics tasks

USE healthcare_analytics;

DELIMITER //

-- 1. Procedure to Calculate Patient Risk Score
CREATE PROCEDURE CalculatePatientRiskScore(
    IN p_patient_id INT,
    OUT risk_score INT,
    OUT risk_category VARCHAR(20)
)
BEGIN
    DECLARE patient_age INT;
    DECLARE chronic_conditions INT;
    DECLARE recent_admissions INT;
    DECLARE ed_visits_90days INT;
    
    -- Get patient age
    SELECT TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) INTO patient_age
    FROM patients WHERE patient_id = p_patient_id;
    
    -- Count chronic conditions
    SELECT COUNT(DISTINCT 
        CASE 
            WHEN d.icd10_code LIKE 'E11%' THEN 'Diabetes'
            WHEN d.icd10_code LIKE 'I10%' THEN 'Hypertension'
            WHEN d.icd10_code IN ('I21%', 'I25%') THEN 'Heart Disease'
            WHEN d.icd10_code LIKE 'J44%' THEN 'COPD'
            WHEN d.icd10_code LIKE 'N18%' THEN 'CKD'
        END
    ) INTO chronic_conditions
    FROM encounters e
    JOIN diagnoses d ON e.encounter_id = d.encounter_id
    WHERE e.patient_id = p_patient_id
        AND d.icd10_code REGEXP 'E11|I10|I21|I25|J44|N18';
    
    -- Count recent admissions (last 6 months)
    SELECT COUNT(*) INTO recent_admissions
    FROM encounters
    WHERE patient_id = p_patient_id
        AND encounter_type = 'Inpatient'
        AND encounter_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH);
    
    -- Count ED visits in last 90 days
    SELECT COUNT(*) INTO ed_visits_90days
    FROM encounters
    WHERE patient_id = p_patient_id
        AND encounter_type = 'Emergency'
        AND encounter_date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY);
    
    -- Calculate risk score
    SET risk_score = 0;
    
    -- Age scoring
    IF patient_age >= 75 THEN
        SET risk_score = risk_score + 3;
    ELSEIF patient_age >= 65 THEN
        SET risk_score = risk_score + 2;
    ELSEIF patient_age >= 50 THEN
        SET risk_score = risk_score + 1;
    END IF;
    
    -- Chronic conditions scoring
    SET risk_score = risk_score + (chronic_conditions * 2);
    
    -- Recent admissions scoring
    SET risk_score = risk_score + (recent_admissions * 3);
    
    -- ED visits scoring
    SET risk_score = risk_score + (ed_visits_90days * 2);
    
    -- Determine risk category
    IF risk_score >= 10 THEN
        SET risk_category = 'High Risk';
    ELSEIF risk_score >= 5 THEN
        SET risk_category = 'Medium Risk';
    ELSE
        SET risk_category = 'Low Risk';
    END IF;
END//

-- 2. Procedure to Generate Department Performance Report
CREATE PROCEDURE GenerateDepartmentReport(
    IN p_department_id INT,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    -- Department summary
    SELECT 
        d.department_name,
        COUNT(DISTINCT e.encounter_id) as total_encounters,
        COUNT(DISTINCT e.patient_id) as unique_patients,
        COUNT(DISTINCT CASE WHEN e.encounter_type = 'Inpatient' THEN e.encounter_id END) as inpatient_count,
        COUNT(DISTINCT CASE WHEN e.encounter_type = 'Outpatient' THEN e.encounter_id END) as outpatient_count,
        ROUND(AVG(e.length_of_stay), 2) as avg_los,
        COUNT(DISTINCT p.provider_id) as active_providers
    FROM departments d
    LEFT JOIN encounters e ON d.department_id = e.department_id
        AND e.encounter_date BETWEEN p_start_date AND p_end_date
    LEFT JOIN providers p ON e.provider_id = p.provider_id
    WHERE d.department_id = p_department_id
    GROUP BY d.department_id;
    
    -- Top diagnoses for department
    SELECT 
        di.icd10_code,
        di.diagnosis_description,
        COUNT(*) as diagnosis_count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
    FROM encounters e
    JOIN diagnoses di ON e.encounter_id = di.encounter_id
    WHERE e.department_id = p_department_id
        AND e.encounter_date BETWEEN p_start_date AND p_end_date
    GROUP BY di.icd10_code, di.diagnosis_description
    ORDER BY diagnosis_count DESC
    LIMIT 10;
    
    -- Financial summary
    SELECT 
        COUNT(DISTINCT b.billing_id) as total_claims,
        SUM(b.charge_amount) as total_charges,
        SUM(b.paid_amount) as total_revenue,
        ROUND(SUM(b.paid_amount) * 100.0 / NULLIF(SUM(b.charge_amount), 0), 2) as collection_rate,
        ROUND(AVG(b.charge_amount), 2) as avg_charge_per_claim
    FROM encounters e
    JOIN billing b ON e.encounter_id = b.encounter_id
    WHERE e.department_id = p_department_id
        AND e.encounter_date BETWEEN p_start_date AND p_end_date;
END//

-- 3. Procedure to Track Medication Adherence
CREATE PROCEDURE TrackMedicationAdherence(
    IN p_patient_id INT,
    IN p_medication_name VARCHAR(200)
)
BEGIN
    DECLARE adherence_score DECIMAL(5,2);
    DECLARE expected_refills INT;
    DECLARE actual_refills INT;
    DECLARE days_on_therapy INT;
    
    -- Get medication history
    SELECT 
        DATEDIFF(COALESCE(MAX(end_date), CURDATE()), MIN(start_date)) as therapy_days,
        COUNT(DISTINCT medication_id) as refill_count
    INTO days_on_therapy, actual_refills
    FROM medications
    WHERE patient_id = p_patient_id
        AND medication_name LIKE CONCAT('%', p_medication_name, '%')
        AND is_active = TRUE;
    
    -- Calculate expected refills (assuming 30-day supply)
    SET expected_refills = CEILING(days_on_therapy / 30.0);
    
    -- Calculate adherence score
    IF expected_refills > 0 THEN
        SET adherence_score = (actual_refills * 100.0) / expected_refills;
    ELSE
        SET adherence_score = 0;
    END IF;
    
    -- Return adherence report
    SELECT 
        p.patient_id,
        CONCAT(p.first_name, ' ', p.last_name) as patient_name,
        p_medication_name as medication,
        days_on_therapy,
        actual_refills,
        expected_refills,
        ROUND(adherence_score, 2) as adherence_percentage,
        CASE 
            WHEN adherence_score >= 80 THEN 'Good Adherence'
            WHEN adherence_score >= 60 THEN 'Fair Adherence'
            ELSE 'Poor Adherence'
        END as adherence_category,
        COUNT(DISTINCT e.encounter_id) as related_visits
    FROM patients p
    LEFT JOIN encounters e ON p.patient_id = e.patient_id
        AND e.encounter_date >= DATE_SUB(CURDATE(), INTERVAL days_on_therapy DAY)
    WHERE p.patient_id = p_patient_id
    GROUP BY p.patient_id;
END//

-- 4. Procedure to Identify Care Gaps
CREATE PROCEDURE IdentifyCareGaps(
    IN p_patient_id INT
)
BEGIN
    DECLARE has_diabetes BOOLEAN DEFAULT FALSE;
    DECLARE has_hypertension BOOLEAN DEFAULT FALSE;
    DECLARE has_heart_disease BOOLEAN DEFAULT FALSE;
    DECLARE last_hba1c_date DATE;
    DECLARE last_bp_check DATE;
    DECLARE last_lipid_date DATE;
    
    -- Check chronic conditions
    SELECT 
        MAX(CASE WHEN d.icd10_code LIKE 'E11%' THEN TRUE ELSE FALSE END),
        MAX(CASE WHEN d.icd10_code LIKE 'I10%' THEN TRUE ELSE FALSE END),
        MAX(CASE WHEN d.icd10_code IN ('I21%', 'I25%') THEN TRUE ELSE FALSE END)
    INTO has_diabetes, has_hypertension, has_heart_disease
    FROM encounters e
    JOIN diagnoses d ON e.encounter_id = d.encounter_id
    WHERE e.patient_id = p_patient_id;
    
    -- Get last test dates
    SELECT 
        MAX(CASE WHEN test_code = 'HBA1C' THEN DATE(collection_datetime) END),
        MAX(CASE WHEN test_code = 'LIPID' THEN DATE(collection_datetime) END)
    INTO last_hba1c_date, last_lipid_date
    FROM lab_results
    WHERE patient_id = p_patient_id;
    
    SELECT MAX(DATE(measurement_datetime)) INTO last_bp_check
    FROM vital_signs
    WHERE patient_id = p_patient_id
        AND blood_pressure_systolic IS NOT NULL;
    
    -- Create care gaps report
    SELECT 'Care Gap Analysis' as report_type, p_patient_id as patient_id;
    
    -- Check diabetes care gaps
    IF has_diabetes THEN
        IF last_hba1c_date IS NULL OR DATEDIFF(CURDATE(), last_hba1c_date) > 90 THEN
            SELECT 'Diabetes Care' as care_type, 
                   'HbA1c Test Overdue' as gap_description,
                   COALESCE(CONCAT(DATEDIFF(CURDATE(), last_hba1c_date), ' days overdue'), 'Never performed') as status;
        END IF;
    END IF;
    
    -- Check hypertension care gaps
    IF has_hypertension THEN
        IF last_bp_check IS NULL OR DATEDIFF(CURDATE(), last_bp_check) > 30 THEN
            SELECT 'Hypertension Care' as care_type,
                   'Blood Pressure Check Overdue' as gap_description,
                   COALESCE(CONCAT(DATEDIFF(CURDATE(), last_bp_check), ' days since last check'), 'Never performed') as status;
        END IF;
    END IF;
    
    -- Check cardiovascular care gaps
    IF has_heart_disease THEN
        IF last_lipid_date IS NULL OR DATEDIFF(CURDATE(), last_lipid_date) > 365 THEN
            SELECT 'Cardiovascular Care' as care_type,
                   'Lipid Panel Overdue' as gap_description,
                   COALESCE(CONCAT(DATEDIFF(CURDATE(), last_lipid_date), ' days overdue'), 'Never performed') as status;
        END IF;
    END IF;
END//

-- 5. Procedure for Readmission Risk Prediction
CREATE PROCEDURE PredictReadmissionRisk(
    IN p_encounter_id INT
)
BEGIN
    DECLARE risk_points INT DEFAULT 0;
    DECLARE patient_id INT;
    DECLARE los INT;
    DECLARE diagnosis_count INT;
    DECLARE prior_admissions INT;
    DECLARE chronic_meds INT;
    
    -- Get patient and encounter info
    SELECT e.patient_id, e.length_of_stay 
    INTO patient_id, los
    FROM encounters e
    WHERE e.encounter_id = p_encounter_id;
    
    -- Count diagnoses
    SELECT COUNT(*) INTO diagnosis_count
    FROM diagnoses
    WHERE encounter_id = p_encounter_id;
    
    -- Count prior admissions in last 6 months
    SELECT COUNT(*) INTO prior_admissions
    FROM encounters
    WHERE patient_id = patient_id
        AND encounter_type = 'Inpatient'
        AND encounter_id != p_encounter_id
        AND encounter_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH);
    
    -- Count chronic medications
    SELECT COUNT(DISTINCT medication_name) INTO chronic_meds
    FROM medications
    WHERE patient_id = patient_id
        AND is_active = TRUE;
    
    -- Calculate risk points
    -- Length of stay scoring
    IF los >= 7 THEN
        SET risk_points = risk_points + 3;
    ELSEIF los >= 4 THEN
        SET risk_points = risk_points + 2;
    ELSEIF los >= 2 THEN
        SET risk_points = risk_points + 1;
    END IF;
    
    -- Diagnosis complexity
    IF diagnosis_count >= 5 THEN
        SET risk_points = risk_points + 3;
    ELSEIF diagnosis_count >= 3 THEN
        SET risk_points = risk_points + 2;
    END IF;
    
    -- Prior admissions
    SET risk_points = risk_points + (prior_admissions * 2);
    
    -- Medication complexity
    IF chronic_meds >= 10 THEN
        SET risk_points = risk_points + 3;
    ELSEIF chronic_meds >= 5 THEN
        SET risk_points = risk_points + 2;
    END IF;
    
    -- Return risk assessment
    SELECT 
        p_encounter_id as encounter_id,
        risk_points as total_risk_score,
        CASE 
            WHEN risk_points >= 10 THEN 'High'
            WHEN risk_points >= 5 THEN 'Medium'
            ELSE 'Low'
        END as readmission_risk,
        los as length_of_stay,
        diagnosis_count as diagnoses,
        prior_admissions as recent_admissions,
        chronic_meds as active_medications,
        CASE 
            WHEN risk_points >= 10 THEN 'Recommend intensive discharge planning and follow-up within 48 hours'
            WHEN risk_points >= 5 THEN 'Recommend standard discharge planning and follow-up within 7 days'
            ELSE 'Standard discharge process'
        END as recommendation;
END//

DELIMITER ;