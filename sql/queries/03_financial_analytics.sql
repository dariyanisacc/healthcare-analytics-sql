-- Financial Analytics Queries
-- Revenue cycle and cost analysis queries

USE healthcare_analytics;

-- 1. Revenue Cycle Dashboard
SELECT 
    COUNT(DISTINCT b.billing_id) as total_claims,
    COUNT(DISTINCT b.encounter_id) as unique_encounters,
    COUNT(DISTINCT b.patient_id) as unique_patients,
    SUM(b.charge_amount) as total_charges,
    SUM(b.allowed_amount) as total_allowed,
    SUM(b.paid_amount) as total_paid,
    SUM(b.patient_responsibility) as total_patient_responsibility,
    ROUND(SUM(b.paid_amount) * 100.0 / NULLIF(SUM(b.charge_amount), 0), 2) as collection_rate,
    ROUND(AVG(DATEDIFF(b.updated_at, b.service_date)), 1) as avg_days_to_payment,
    SUM(CASE WHEN b.billing_status = 'Denied' THEN b.charge_amount ELSE 0 END) as denied_charges,
    ROUND(SUM(CASE WHEN b.billing_status = 'Denied' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as denial_rate
FROM billing b
WHERE b.service_date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY);

-- 2. Payer Mix Analysis
WITH payer_summary AS (
    SELECT 
        p.insurance_provider,
        COUNT(DISTINCT b.patient_id) as patient_count,
        COUNT(DISTINCT b.encounter_id) as encounter_count,
        SUM(b.charge_amount) as total_charges,
        SUM(b.allowed_amount) as total_allowed,
        SUM(b.paid_amount) as total_paid,
        AVG(b.allowed_amount / NULLIF(b.charge_amount, 0)) as avg_allowed_ratio,
        AVG(b.paid_amount / NULLIF(b.allowed_amount, 0)) as avg_payment_ratio
    FROM billing b
    JOIN patients p ON b.patient_id = p.patient_id
    GROUP BY p.insurance_provider
)
SELECT 
    insurance_provider,
    patient_count,
    encounter_count,
    ROUND(total_charges, 2) as total_charges,
    ROUND(total_allowed, 2) as total_allowed,
    ROUND(total_paid, 2) as total_paid,
    ROUND(avg_allowed_ratio * 100, 2) as allowed_percentage,
    ROUND(avg_payment_ratio * 100, 2) as payment_percentage,
    ROUND(patient_count * 100.0 / SUM(patient_count) OVER(), 2) as payer_mix_percentage
FROM payer_summary
ORDER BY total_charges DESC;

-- 3. Service Line Profitability Analysis
WITH service_line_metrics AS (
    SELECT 
        d.department_name,
        COUNT(DISTINCT e.encounter_id) as encounter_volume,
        COUNT(DISTINCT e.patient_id) as unique_patients,
        AVG(e.length_of_stay) as avg_los,
        SUM(b.charge_amount) as total_charges,
        SUM(b.paid_amount) as total_revenue,
        SUM(b.charge_amount - b.paid_amount) as total_adjustments,
        COUNT(DISTINCT proc.procedure_id) as procedures_performed
    FROM departments d
    JOIN encounters e ON d.department_id = e.department_id
    LEFT JOIN billing b ON e.encounter_id = b.encounter_id
    LEFT JOIN procedures proc ON e.encounter_id = proc.encounter_id
    GROUP BY d.department_id, d.department_name
)
SELECT 
    department_name,
    encounter_volume,
    unique_patients,
    ROUND(avg_los, 2) as avg_length_of_stay,
    ROUND(total_charges, 2) as total_charges,
    ROUND(total_revenue, 2) as total_revenue,
    ROUND(total_revenue / NULLIF(encounter_volume, 0), 2) as revenue_per_encounter,
    ROUND(total_revenue * 100.0 / NULLIF(total_charges, 0), 2) as net_collection_rate,
    procedures_performed,
    ROUND(procedures_performed * 1.0 / NULLIF(encounter_volume, 0), 2) as procedures_per_encounter,
    CASE 
        WHEN total_revenue / NULLIF(encounter_volume, 0) > 5000 THEN 'High Revenue'
        WHEN total_revenue / NULLIF(encounter_volume, 0) > 2000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END as revenue_category
FROM service_line_metrics
ORDER BY total_revenue DESC;

-- 4. DRG-Based Cost Analysis (Simulated)
WITH drg_analysis AS (
    SELECT 
        d.icd10_code,
        d.diagnosis_description,
        COUNT(DISTINCT e.encounter_id) as case_count,
        AVG(e.length_of_stay) as avg_los,
        SUM(b.charge_amount) as total_charges,
        SUM(b.paid_amount) as total_payments,
        AVG(b.charge_amount) as avg_charge_per_case,
        AVG(b.paid_amount) as avg_payment_per_case,
        STDDEV(b.charge_amount) as charge_std_dev
    FROM encounters e
    JOIN diagnoses d ON e.encounter_id = d.encounter_id
    JOIN billing b ON e.encounter_id = b.encounter_id
    WHERE d.diagnosis_type = 'Primary'
        AND e.encounter_type = 'Inpatient'
    GROUP BY d.icd10_code, d.diagnosis_description
    HAVING COUNT(DISTINCT e.encounter_id) >= 2
)
SELECT 
    icd10_code,
    diagnosis_description,
    case_count,
    ROUND(avg_los, 2) as avg_length_of_stay,
    ROUND(avg_charge_per_case, 2) as avg_charge,
    ROUND(avg_payment_per_case, 2) as avg_payment,
    ROUND((avg_payment_per_case / NULLIF(avg_charge_per_case, 0)) * 100, 2) as payment_to_charge_ratio,
    ROUND(charge_std_dev, 2) as charge_variation,
    CASE 
        WHEN avg_los > 5 AND avg_payment_per_case < avg_charge_per_case * 0.6 THEN 'Loss Leader'
        WHEN avg_payment_per_case > avg_charge_per_case * 0.8 THEN 'Profitable'
        ELSE 'Break Even'
    END as financial_category
FROM drg_analysis
ORDER BY total_payments DESC
LIMIT 20;

-- 5. Accounts Receivable Aging Analysis
WITH ar_aging AS (
    SELECT 
        b.billing_id,
        b.patient_id,
        p.insurance_provider,
        b.service_date,
        b.charge_amount,
        b.paid_amount,
        (b.charge_amount - b.paid_amount) as outstanding_amount,
        DATEDIFF(CURDATE(), b.service_date) as days_outstanding,
        b.billing_status,
        CASE 
            WHEN DATEDIFF(CURDATE(), b.service_date) <= 30 THEN '0-30 days'
            WHEN DATEDIFF(CURDATE(), b.service_date) <= 60 THEN '31-60 days'
            WHEN DATEDIFF(CURDATE(), b.service_date) <= 90 THEN '61-90 days'
            WHEN DATEDIFF(CURDATE(), b.service_date) <= 120 THEN '91-120 days'
            ELSE '120+ days'
        END as aging_bucket
    FROM billing b
    JOIN patients p ON b.patient_id = p.patient_id
    WHERE b.billing_status IN ('Pending', 'Submitted', 'Denied')
        AND b.charge_amount > b.paid_amount
)
SELECT 
    aging_bucket,
    COUNT(*) as claim_count,
    COUNT(DISTINCT patient_id) as unique_patients,
    SUM(outstanding_amount) as total_outstanding,
    AVG(outstanding_amount) as avg_outstanding,
    MIN(days_outstanding) as min_days,
    MAX(days_outstanding) as max_days,
    GROUP_CONCAT(DISTINCT insurance_provider) as payers_affected,
    ROUND(SUM(outstanding_amount) * 100.0 / SUM(SUM(outstanding_amount)) OVER(), 2) as pct_of_total_ar
FROM ar_aging
GROUP BY aging_bucket
ORDER BY 
    CASE aging_bucket
        WHEN '0-30 days' THEN 1
        WHEN '31-60 days' THEN 2
        WHEN '61-90 days' THEN 3
        WHEN '91-120 days' THEN 4
        ELSE 5
    END;

-- 6. Cost per Patient by Chronic Condition
WITH chronic_costs AS (
    SELECT 
        p.patient_id,
        CONCAT(p.first_name, ' ', p.last_name) as patient_name,
        MAX(CASE WHEN d.icd10_code LIKE 'E11%' THEN 1 ELSE 0 END) as has_diabetes,
        MAX(CASE WHEN d.icd10_code LIKE 'I10%' THEN 1 ELSE 0 END) as has_hypertension,
        MAX(CASE WHEN d.icd10_code IN ('I21%', 'I25%') THEN 1 ELSE 0 END) as has_heart_disease,
        MAX(CASE WHEN d.icd10_code LIKE 'J44%' THEN 1 ELSE 0 END) as has_copd,
        COUNT(DISTINCT e.encounter_id) as total_encounters,
        SUM(b.charge_amount) as total_charges,
        SUM(b.paid_amount) as total_paid
    FROM patients p
    JOIN encounters e ON p.patient_id = e.patient_id
    JOIN diagnoses d ON e.encounter_id = d.encounter_id
    LEFT JOIN billing b ON e.encounter_id = b.encounter_id
    GROUP BY p.patient_id
)
SELECT 
    CASE 
        WHEN has_diabetes + has_hypertension + has_heart_disease + has_copd = 0 THEN 'No Chronic Conditions'
        WHEN has_diabetes + has_hypertension + has_heart_disease + has_copd = 1 THEN '1 Chronic Condition'
        WHEN has_diabetes + has_hypertension + has_heart_disease + has_copd = 2 THEN '2 Chronic Conditions'
        ELSE '3+ Chronic Conditions'
    END as condition_category,
    COUNT(DISTINCT patient_id) as patient_count,
    SUM(total_encounters) as total_encounters,
    ROUND(AVG(total_encounters), 2) as avg_encounters_per_patient,
    ROUND(SUM(total_charges), 2) as total_charges,
    ROUND(SUM(total_paid), 2) as total_revenue,
    ROUND(AVG(total_charges), 2) as avg_charge_per_patient,
    ROUND(AVG(total_paid), 2) as avg_revenue_per_patient,
    ROUND(SUM(total_charges) / NULLIF(SUM(total_encounters), 0), 2) as avg_charge_per_encounter
FROM chronic_costs
GROUP BY 
    CASE 
        WHEN has_diabetes + has_hypertension + has_heart_disease + has_copd = 0 THEN 'No Chronic Conditions'
        WHEN has_diabetes + has_hypertension + has_heart_disease + has_copd = 1 THEN '1 Chronic Condition'
        WHEN has_diabetes + has_hypertension + has_heart_disease + has_copd = 2 THEN '2 Chronic Conditions'
        ELSE '3+ Chronic Conditions'
    END
ORDER BY patient_count DESC;