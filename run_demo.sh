#!/bin/bash

# Healthcare Analytics SQL Demo Script
# This script runs key analytics queries to demonstrate the system's capabilities

echo "======================================"
echo "Healthcare Analytics SQL Demo"
echo "======================================"
echo ""

# Check if database exists
if ! mysql -u root -e "USE healthcare_analytics" 2>/dev/null; then
    echo "Database not found. Please run ./setup_database.sh first."
    exit 1
fi

echo "1. Patient Demographics Summary"
echo "-------------------------------"
mysql -u root healthcare_analytics -e "
SELECT 
    COUNT(DISTINCT patient_id) as total_patients,
    ROUND(AVG(TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE())), 1) as avg_age,
    SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) as male_count,
    SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) as female_count,
    COUNT(DISTINCT insurance_provider) as insurance_providers
FROM patients;"

echo ""
echo "2. Department Performance"
echo "-------------------------"
mysql -u root healthcare_analytics -e "
SELECT 
    d.department_name,
    COUNT(DISTINCT e.encounter_id) as total_encounters,
    ROUND(AVG(e.length_of_stay), 1) as avg_los_days
FROM departments d
LEFT JOIN encounters e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name
HAVING total_encounters > 0
ORDER BY total_encounters DESC
LIMIT 5;"

echo ""
echo "3. Patient Risk Assessment (Sample Patient)"
echo "------------------------------------------"
mysql -u root healthcare_analytics -e "
CALL CalculatePatientRiskScore(1, @risk_score, @risk_category);
SELECT 
    'John Smith' as patient_name,
    @risk_score as risk_score, 
    @risk_category as risk_category;"

echo ""
echo "4. Chronic Disease Patients with Care Gaps"
echo "------------------------------------------"
mysql -u root healthcare_analytics -e "
WITH chronic_patients AS (
    SELECT DISTINCT
        p.patient_id,
        CONCAT(p.first_name, ' ', p.last_name) as patient_name,
        MAX(CASE WHEN d.icd10_code LIKE 'E11%' THEN 1 ELSE 0 END) as has_diabetes,
        MAX(CASE WHEN d.icd10_code LIKE 'I10%' THEN 1 ELSE 0 END) as has_hypertension
    FROM patients p
    JOIN encounters e ON p.patient_id = e.patient_id
    JOIN diagnoses d ON e.encounter_id = d.encounter_id
    WHERE d.icd10_code IN ('E11.9', 'I10')
    GROUP BY p.patient_id
)
SELECT 
    patient_name,
    CASE WHEN has_diabetes = 1 THEN 'Yes' ELSE 'No' END as diabetes,
    CASE WHEN has_hypertension = 1 THEN 'Yes' ELSE 'No' END as hypertension,
    'Needs Follow-up' as action_required
FROM chronic_patients
WHERE has_diabetes = 1 OR has_hypertension = 1;"

echo ""
echo "5. Financial Performance Summary"
echo "--------------------------------"
mysql -u root healthcare_analytics -e "
SELECT 
    COUNT(DISTINCT billing_id) as total_claims,
    CONCAT('$', FORMAT(SUM(charge_amount), 2)) as total_charges,
    CONCAT('$', FORMAT(SUM(paid_amount), 2)) as total_revenue,
    CONCAT(ROUND(SUM(paid_amount) * 100.0 / NULLIF(SUM(charge_amount), 0), 2), '%') as collection_rate
FROM billing;"

echo ""
echo "======================================"
echo "Demo Complete!"
echo ""
echo "For more analytics, try:"
echo "  mysql -u root healthcare_analytics < sql/queries/01_patient_analytics.sql"
echo "  mysql -u root healthcare_analytics < sql/queries/02_clinical_analytics.sql"
echo "  mysql -u root healthcare_analytics < sql/queries/03_financial_analytics.sql"
echo ""