# Healthcare Analytics SQL - Live Examples

This document demonstrates the actual output from running the healthcare analytics queries on a populated database with sample data.

## Database Setup Confirmation

```sql
mysql> SHOW TABLES;
```
```
+----------------------------------+
| Tables_in_healthcare_analytics   |
+----------------------------------+
| billing                          |
| departments                      |
| diagnoses                        |
| encounters                       |
| lab_results                      |
| medications                      |
| patients                         |
| procedures                       |
| providers                        |
| quality_measures                 |
| vital_signs                      |
+----------------------------------+
11 rows in set
```

## 1. Patient Demographics Analysis

### Query: Population Summary
```sql
SELECT 
    COUNT(DISTINCT patient_id) as total_patients,
    ROUND(AVG(TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE())), 1) as avg_age,
    SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) as male_count,
    SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) as female_count,
    COUNT(DISTINCT insurance_provider) as insurance_providers
FROM patients;
```

### Output:
```
+----------------+---------+------------+--------------+---------------------+
| total_patients | avg_age | male_count | female_count | insurance_providers |
+----------------+---------+------------+--------------+---------------------+
|             10 |    50.8 |          5 |            5 |                   6 |
+----------------+---------+------------+--------------+---------------------+
```

**Insights**: 
- Balanced gender distribution (50/50)
- Average patient age is 50.8 years
- 6 different insurance providers represented

## 2. Clinical Analytics

### Query: Top Diagnoses by Frequency
```sql
SELECT 
    d.icd10_code,
    d.diagnosis_description,
    COUNT(*) as diagnosis_count,
    COUNT(DISTINCT e.patient_id) as affected_patients
FROM diagnoses d
JOIN encounters e ON d.encounter_id = e.encounter_id
GROUP BY d.icd10_code, d.diagnosis_description
ORDER BY diagnosis_count DESC
LIMIT 5;
```

### Output:
```
+------------+------------------------------------------------+-----------------+-------------------+
| icd10_code | diagnosis_description                          | diagnosis_count | affected_patients |
+------------+------------------------------------------------+-----------------+-------------------+
| A41.9      | Sepsis, unspecified organism                   |               1 |                 1 |
| E11.9      | Type 2 diabetes mellitus without complications |               1 |                 1 |
| E78.5      | Hyperlipidemia, unspecified                    |               1 |                 1 |
| I10        | Essential hypertension                         |               1 |                 1 |
| I21.9      | Acute myocardial infarction, unspecified      |               1 |                 1 |
+------------+------------------------------------------------+-----------------+-------------------+
```

## 3. Department Performance Metrics

### Query: Department Utilization Summary
```sql
SELECT 
    d.department_name,
    COUNT(DISTINCT e.encounter_id) as total_encounters,
    COUNT(DISTINCT e.patient_id) as unique_patients,
    ROUND(AVG(e.length_of_stay), 1) as avg_los_days,
    COUNT(DISTINCT CASE WHEN e.encounter_type = 'Inpatient' THEN e.encounter_id END) as inpatient_count
FROM departments d
LEFT JOIN encounters e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name
HAVING total_encounters > 0
ORDER BY total_encounters DESC;
```

### Output:
```
+---------------------------+------------------+-----------------+--------------+-----------------+
| department_name           | total_encounters | unique_patients | avg_los_days | inpatient_count |
+---------------------------+------------------+-----------------+--------------+-----------------+
| Emergency Department      |                2 |               2 |          0.0 |               0 |
| Cardiology                |                2 |               2 |          3.0 |               1 |
| Internal Medicine         |                2 |               2 |         NULL |               0 |
| Surgery                   |                1 |               1 |          2.0 |               1 |
| Pediatrics                |                1 |               1 |         NULL |               0 |
| Intensive Care Unit       |                1 |               1 |          5.0 |               1 |
| Orthopedics               |                1 |               1 |         NULL |               0 |
| Obstetrics/Gynecology     |                1 |               1 |         NULL |               0 |
+---------------------------+------------------+-----------------+--------------+-----------------+
```

**Insights**:
- Emergency Department and Cardiology see the most encounters
- ICU has the longest average length of stay (5 days)
- Mix of inpatient and outpatient services across departments

## 4. Patient Risk Stratification

### Stored Procedure: Calculate Patient Risk Score
```sql
CALL CalculatePatientRiskScore(1, @risk_score, @risk_category);
SELECT 
    1 as patient_id,
    (SELECT CONCAT(first_name, ' ', last_name) FROM patients WHERE patient_id = 1) as patient_name,
    @risk_score as risk_score, 
    @risk_category as risk_category;
```

### Output:
```
+------------+--------------+------------+---------------+
| patient_id | patient_name | risk_score | risk_category |
+------------+--------------+------------+---------------+
|          1 | John Smith   |          3 | Low Risk      |
+------------+--------------+------------+---------------+
```

**Risk Scoring Algorithm considers**:
- Patient age
- Number of chronic conditions
- Recent hospital admissions
- Emergency department visits

## 5. Chronic Disease Management with Care Gaps

### Query: Identify Patients with Care Gaps
```sql
WITH chronic_patients AS (
    SELECT DISTINCT
        p.patient_id,
        p.first_name,
        p.last_name,
        TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) as age,
        MAX(CASE WHEN d.icd10_code LIKE 'E11%' THEN 1 ELSE 0 END) as has_diabetes,
        MAX(CASE WHEN d.icd10_code LIKE 'I10%' THEN 1 ELSE 0 END) as has_hypertension
    FROM patients p
    JOIN encounters e ON p.patient_id = e.patient_id
    JOIN diagnoses d ON e.encounter_id = d.encounter_id
    WHERE d.icd10_code IN ('E11.9', 'I10')
    GROUP BY p.patient_id
)
SELECT 
    patient_id,
    CONCAT(first_name, ' ', last_name) as patient_name,
    age,
    CASE WHEN has_diabetes = 1 THEN 'Yes' ELSE 'No' END as diabetes,
    CASE WHEN has_hypertension = 1 THEN 'Yes' ELSE 'No' END as hypertension,
    'Needs HbA1c Test' as care_gap_identified
FROM chronic_patients
WHERE has_diabetes = 1 OR has_hypertension = 1;
```

### Output:
```
+------------+--------------------+------+----------+--------------+---------------------+
| patient_id | patient_name       | age  | diabetes | hypertension | care_gap_identified |
+------------+--------------------+------+----------+--------------+---------------------+
|         10 | Patricia Anderson  |   35 | Yes      | No           | Needs HbA1c Test    |
|          1 | John Smith         |   55 | No       | Yes          | Needs HbA1c Test    |
+------------+--------------------+------+----------+--------------+---------------------+
```

**Care Management Insights**:
- 2 patients identified with chronic conditions requiring follow-up
- Automated care gap detection for diabetes and hypertension management
- Supports proactive patient outreach programs

## 6. Financial Performance Analytics

### Query: Revenue Cycle Summary
```sql
SELECT 
    COUNT(DISTINCT billing_id) as total_claims,
    FORMAT(SUM(charge_amount), 2) as total_charges,
    FORMAT(SUM(paid_amount), 2) as total_revenue,
    FORMAT(SUM(patient_responsibility), 2) as patient_responsibility,
    ROUND(SUM(paid_amount) * 100.0 / NULLIF(SUM(charge_amount), 0), 2) as collection_rate_pct,
    COUNT(CASE WHEN billing_status = 'Denied' THEN 1 END) as denied_claims
FROM billing;
```

### Output:
```
+--------------+---------------+---------------+------------------------+---------------------+---------------+
| total_claims | total_charges | total_revenue | patient_responsibility | collection_rate_pct | denied_claims |
+--------------+---------------+---------------+------------------------+---------------------+---------------+
|            8 | 67,000.00     | 46,316.00     | 4,579.00               |               69.13 |             0 |
+--------------+---------------+---------------+------------------------+---------------------+---------------+
```

**Financial Insights**:
- Total charges: $67,000
- Revenue collected: $46,316 (69.13% collection rate)
- Patient responsibility: $4,579
- No denied claims in current dataset

## 7. Real-World Use Cases

### Use Case 1: 30-Day Readmission Prevention
```sql
-- Identify patients at risk of readmission
SELECT 
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) as patient_name,
    e.discharge_date,
    e.length_of_stay,
    COUNT(d.diagnosis_id) as diagnosis_count,
    GROUP_CONCAT(DISTINCT d.icd10_code) as conditions
FROM patients p
JOIN encounters e ON p.patient_id = e.patient_id
JOIN diagnoses d ON e.encounter_id = d.encounter_id
WHERE e.encounter_type = 'Inpatient'
    AND e.discharge_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY p.patient_id, e.encounter_id
HAVING diagnosis_count >= 3
ORDER BY e.discharge_date DESC;
```

### Use Case 2: Quality Measure Performance
```sql
-- Department-wise quality metrics
CALL GenerateDepartmentReport(1, '2024-01-01', '2024-12-31');
```

This generates comprehensive reports including:
- Patient volume metrics
- Top diagnoses by department
- Financial performance
- Provider productivity

### Use Case 3: Population Health Management
The system supports:
- Chronic disease registries
- Preventive care reminders
- Risk-adjusted patient panels
- Care coordination tracking

## Setup Instructions

To reproduce these results:

1. Install MySQL 8.0+
2. Clone the repository
3. Run the setup script:
   ```bash
   ./setup_database.sh
   ```
4. Execute queries using:
   ```bash
   mysql -u root healthcare_analytics < sql/queries/01_patient_analytics.sql
   ```

## Technical Architecture

- **Database**: MySQL 8.0+
- **Tables**: 11 interconnected tables
- **Stored Procedures**: 5 advanced procedures
- **Indexes**: Optimized for query performance
- **Data Model**: HIPAA-compliant design

## Business Value

This healthcare analytics system enables:

1. **Clinical Decision Support**: Real-time risk scoring and care gap identification
2. **Financial Optimization**: Revenue cycle analytics and denial management
3. **Quality Improvement**: Performance metrics and outcome tracking
4. **Population Health**: Chronic disease management and preventive care
5. **Operational Efficiency**: Department utilization and resource planning

---

*Note: All data shown is synthetic and for demonstration purposes only. No real patient information is used.*