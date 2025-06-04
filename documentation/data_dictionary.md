# Healthcare Analytics Database - Data Dictionary

## Table: patients
Patient demographic and contact information

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| patient_id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique patient identifier |
| medical_record_number | VARCHAR(20) | UNIQUE, NOT NULL | Medical record number |
| first_name | VARCHAR(50) | NOT NULL | Patient's first name |
| last_name | VARCHAR(50) | NOT NULL | Patient's last name |
| date_of_birth | DATE | NOT NULL | Date of birth |
| gender | ENUM('M', 'F', 'Other') | NOT NULL | Gender |
| ssn_last_four | VARCHAR(4) | | Last 4 digits of SSN |
| email | VARCHAR(100) | | Email address |
| phone | VARCHAR(20) | | Phone number |
| address_line1 | VARCHAR(100) | | Street address line 1 |
| address_line2 | VARCHAR(100) | | Street address line 2 |
| city | VARCHAR(50) | | City |
| state | VARCHAR(2) | | State code |
| zip_code | VARCHAR(10) | | ZIP code |
| insurance_provider | VARCHAR(100) | | Primary insurance provider |
| insurance_policy_number | VARCHAR(50) | | Insurance policy number |
| emergency_contact_name | VARCHAR(100) | | Emergency contact name |
| emergency_contact_phone | VARCHAR(20) | | Emergency contact phone |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |

## Table: providers
Healthcare provider information

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| provider_id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique provider identifier |
| npi | VARCHAR(10) | UNIQUE, NOT NULL | National Provider Identifier |
| first_name | VARCHAR(50) | NOT NULL | Provider's first name |
| last_name | VARCHAR(50) | NOT NULL | Provider's last name |
| specialty | VARCHAR(100) | NOT NULL | Medical specialty |
| department | VARCHAR(100) | | Department affiliation |
| license_number | VARCHAR(50) | | Medical license number |
| license_state | VARCHAR(2) | | License state |
| phone | VARCHAR(20) | | Contact phone |
| email | VARCHAR(100) | | Email address |
| is_active | BOOLEAN | DEFAULT TRUE | Active status |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Record creation timestamp |

## Table: encounters
Patient visits and admissions

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| encounter_id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique encounter identifier |
| patient_id | INT | FOREIGN KEY, NOT NULL | Reference to patient |
| provider_id | INT | FOREIGN KEY, NOT NULL | Primary provider |
| department_id | INT | FOREIGN KEY | Department |
| encounter_date | DATETIME | NOT NULL | Start of encounter |
| encounter_type | ENUM | NOT NULL | Type: Outpatient, Inpatient, Emergency, Observation |
| admission_date | DATETIME | | Admission timestamp (if applicable) |
| discharge_date | DATETIME | | Discharge timestamp (if applicable) |
| chief_complaint | TEXT | | Reason for visit |
| discharge_disposition | VARCHAR(50) | | Discharge status |
| length_of_stay | INT | GENERATED | Calculated days (discharge - admission) |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Record creation timestamp |

## Table: diagnoses
ICD-10 diagnosis codes and descriptions

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| diagnosis_id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique diagnosis identifier |
| encounter_id | INT | FOREIGN KEY, NOT NULL | Reference to encounter |
| icd10_code | VARCHAR(10) | NOT NULL | ICD-10 diagnosis code |
| diagnosis_description | TEXT | NOT NULL | Diagnosis description |
| diagnosis_type | ENUM | NOT NULL | Type: Primary, Secondary, Admission, Discharge |
| diagnosis_date | DATE | NOT NULL | Date of diagnosis |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Record creation timestamp |

## Table: procedures
CPT procedure codes and details

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| procedure_id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique procedure identifier |
| encounter_id | INT | FOREIGN KEY, NOT NULL | Reference to encounter |
| cpt_code | VARCHAR(10) | NOT NULL | CPT procedure code |
| procedure_description | TEXT | NOT NULL | Procedure description |
| procedure_date | DATETIME | NOT NULL | Date/time of procedure |
| provider_id | INT | FOREIGN KEY, NOT NULL | Performing provider |
| modifier | VARCHAR(10) | | CPT modifier |
| quantity | INT | DEFAULT 1 | Number of procedures |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Record creation timestamp |

## Table: lab_results
Laboratory test results

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| lab_id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique lab result identifier |
| encounter_id | INT | FOREIGN KEY, NOT NULL | Reference to encounter |
| patient_id | INT | FOREIGN KEY, NOT NULL | Reference to patient |
| test_code | VARCHAR(20) | NOT NULL | Lab test code |
| test_name | VARCHAR(200) | NOT NULL | Test name |
| result_value | VARCHAR(100) | | Result value |
| result_unit | VARCHAR(50) | | Unit of measurement |
| reference_range | VARCHAR(100) | | Normal range |
| abnormal_flag | ENUM | DEFAULT 'N' | Flag: N, L, H, LL, HH |
| collection_datetime | DATETIME | NOT NULL | Sample collection time |
| result_datetime | DATETIME | | Result available time |
| ordering_provider_id | INT | FOREIGN KEY | Ordering provider |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Record creation timestamp |

## Table: medications
Medication orders and prescriptions

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| medication_id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique medication identifier |
| encounter_id | INT | FOREIGN KEY, NOT NULL | Reference to encounter |
| patient_id | INT | FOREIGN KEY, NOT NULL | Reference to patient |
| medication_name | VARCHAR(200) | NOT NULL | Medication name |
| generic_name | VARCHAR(200) | | Generic name |
| dosage | VARCHAR(100) | | Dosage strength |
| route | VARCHAR(50) | | Administration route |
| frequency | VARCHAR(100) | | Dosing frequency |
| start_date | DATE | NOT NULL | Start date |
| end_date | DATE | | End date (if applicable) |
| prescribing_provider_id | INT | FOREIGN KEY, NOT NULL | Prescribing provider |
| is_active | BOOLEAN | DEFAULT TRUE | Active status |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Record creation timestamp |

## Table: vital_signs
Patient vital sign measurements

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| vital_id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique vital sign identifier |
| encounter_id | INT | FOREIGN KEY, NOT NULL | Reference to encounter |
| patient_id | INT | FOREIGN KEY, NOT NULL | Reference to patient |
| measurement_datetime | DATETIME | NOT NULL | Measurement timestamp |
| temperature | DECIMAL(4,1) | | Temperature (°F) |
| pulse | INT | | Heart rate (bpm) |
| respiratory_rate | INT | | Respiratory rate |
| blood_pressure_systolic | INT | | Systolic BP (mmHg) |
| blood_pressure_diastolic | INT | | Diastolic BP (mmHg) |
| oxygen_saturation | DECIMAL(4,1) | | O2 saturation (%) |
| height_cm | DECIMAL(5,1) | | Height (cm) |
| weight_kg | DECIMAL(5,2) | | Weight (kg) |
| bmi | DECIMAL(4,1) | GENERATED | Calculated BMI |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Record creation timestamp |

## Table: billing
Financial charges and payments

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| billing_id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique billing identifier |
| encounter_id | INT | FOREIGN KEY, NOT NULL | Reference to encounter |
| patient_id | INT | FOREIGN KEY, NOT NULL | Reference to patient |
| service_date | DATE | NOT NULL | Date of service |
| billing_code | VARCHAR(20) | NOT NULL | Billing/CPT code |
| description | VARCHAR(500) | | Service description |
| quantity | INT | DEFAULT 1 | Quantity |
| charge_amount | DECIMAL(10,2) | NOT NULL | Charge amount |
| allowed_amount | DECIMAL(10,2) | | Insurance allowed amount |
| paid_amount | DECIMAL(10,2) | DEFAULT 0 | Amount paid |
| patient_responsibility | DECIMAL(10,2) | | Patient responsibility |
| billing_status | ENUM | DEFAULT 'Pending' | Status: Pending, Submitted, Paid, Denied, Appealed |
| insurance_claim_number | VARCHAR(50) | | Claim number |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | Last update timestamp |

## Table: quality_measures
Clinical quality metrics tracking

| Column | Data Type | Constraints | Description |
|--------|-----------|-------------|-------------|
| measure_id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique measure identifier |
| patient_id | INT | FOREIGN KEY, NOT NULL | Reference to patient |
| measure_code | VARCHAR(50) | NOT NULL | Quality measure code |
| measure_name | VARCHAR(200) | NOT NULL | Measure name |
| measure_type | VARCHAR(100) | | Type of measure |
| measurement_date | DATE | NOT NULL | Measurement date |
| numerator | BOOLEAN | DEFAULT FALSE | In numerator |
| denominator | BOOLEAN | DEFAULT FALSE | In denominator |
| exclusion | BOOLEAN | DEFAULT FALSE | Excluded |
| performance_met | BOOLEAN | DEFAULT FALSE | Performance met |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Record creation timestamp |

## Common Abbreviations

- **ICD-10**: International Classification of Diseases, 10th Revision
- **CPT**: Current Procedural Terminology
- **NPI**: National Provider Identifier
- **BMI**: Body Mass Index
- **BP**: Blood Pressure
- **ED**: Emergency Department
- **LOS**: Length of Stay

## Data Types Reference

- **INT**: Integer values
- **VARCHAR(n)**: Variable-length string up to n characters
- **TEXT**: Large text fields
- **DATE**: Date in YYYY-MM-DD format
- **DATETIME**: Date and time in YYYY-MM-DD HH:MM:SS format
- **TIMESTAMP**: Automatic timestamp
- **DECIMAL(p,s)**: Decimal with p total digits and s decimal places
- **BOOLEAN**: True/False values
- **ENUM**: Predefined list of values