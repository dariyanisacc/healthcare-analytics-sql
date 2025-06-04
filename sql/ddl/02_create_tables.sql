-- Healthcare Analytics Tables
-- Core tables for healthcare data management

USE healthcare_analytics;

-- Patients table
CREATE TABLE patients (
    patient_id INT PRIMARY KEY AUTO_INCREMENT,
    medical_record_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('M', 'F', 'Other') NOT NULL,
    ssn_last_four VARCHAR(4),
    email VARCHAR(100),
    phone VARCHAR(20),
    address_line1 VARCHAR(100),
    address_line2 VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(2),
    zip_code VARCHAR(10),
    insurance_provider VARCHAR(100),
    insurance_policy_number VARCHAR(50),
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_patient_name (last_name, first_name),
    INDEX idx_patient_dob (date_of_birth)
);

-- Providers table
CREATE TABLE providers (
    provider_id INT PRIMARY KEY AUTO_INCREMENT,
    npi VARCHAR(10) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    specialty VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    license_number VARCHAR(50),
    license_state VARCHAR(2),
    phone VARCHAR(20),
    email VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_provider_specialty (specialty),
    INDEX idx_provider_name (last_name, first_name)
);

-- Departments table
CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(100) NOT NULL,
    department_code VARCHAR(20) UNIQUE NOT NULL,
    location VARCHAR(100),
    phone VARCHAR(20),
    manager_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Encounters table
CREATE TABLE encounters (
    encounter_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    provider_id INT NOT NULL,
    department_id INT,
    encounter_date DATETIME NOT NULL,
    encounter_type ENUM('Outpatient', 'Inpatient', 'Emergency', 'Observation') NOT NULL,
    admission_date DATETIME,
    discharge_date DATETIME,
    chief_complaint TEXT,
    discharge_disposition VARCHAR(50),
    length_of_stay INT GENERATED ALWAYS AS (DATEDIFF(discharge_date, admission_date)) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (provider_id) REFERENCES providers(provider_id),
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    INDEX idx_encounter_date (encounter_date),
    INDEX idx_patient_encounters (patient_id, encounter_date)
);

-- Diagnoses table
CREATE TABLE diagnoses (
    diagnosis_id INT PRIMARY KEY AUTO_INCREMENT,
    encounter_id INT NOT NULL,
    icd10_code VARCHAR(10) NOT NULL,
    diagnosis_description TEXT NOT NULL,
    diagnosis_type ENUM('Primary', 'Secondary', 'Admission', 'Discharge') NOT NULL,
    diagnosis_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounter_id),
    INDEX idx_diagnosis_code (icd10_code),
    INDEX idx_encounter_diagnoses (encounter_id)
);

-- Procedures table
CREATE TABLE procedures (
    procedure_id INT PRIMARY KEY AUTO_INCREMENT,
    encounter_id INT NOT NULL,
    cpt_code VARCHAR(10) NOT NULL,
    procedure_description TEXT NOT NULL,
    procedure_date DATETIME NOT NULL,
    provider_id INT NOT NULL,
    modifier VARCHAR(10),
    quantity INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounter_id),
    FOREIGN KEY (provider_id) REFERENCES providers(provider_id),
    INDEX idx_procedure_code (cpt_code),
    INDEX idx_procedure_date (procedure_date)
);

-- Laboratory results table
CREATE TABLE lab_results (
    lab_id INT PRIMARY KEY AUTO_INCREMENT,
    encounter_id INT NOT NULL,
    patient_id INT NOT NULL,
    test_code VARCHAR(20) NOT NULL,
    test_name VARCHAR(200) NOT NULL,
    result_value VARCHAR(100),
    result_unit VARCHAR(50),
    reference_range VARCHAR(100),
    abnormal_flag ENUM('N', 'L', 'H', 'LL', 'HH') DEFAULT 'N',
    collection_datetime DATETIME NOT NULL,
    result_datetime DATETIME,
    ordering_provider_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounter_id),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (ordering_provider_id) REFERENCES providers(provider_id),
    INDEX idx_lab_test (test_code),
    INDEX idx_lab_collection (collection_datetime),
    INDEX idx_patient_labs (patient_id, collection_datetime)
);

-- Medications table
CREATE TABLE medications (
    medication_id INT PRIMARY KEY AUTO_INCREMENT,
    encounter_id INT NOT NULL,
    patient_id INT NOT NULL,
    medication_name VARCHAR(200) NOT NULL,
    generic_name VARCHAR(200),
    dosage VARCHAR(100),
    route VARCHAR(50),
    frequency VARCHAR(100),
    start_date DATE NOT NULL,
    end_date DATE,
    prescribing_provider_id INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounter_id),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (prescribing_provider_id) REFERENCES providers(provider_id),
    INDEX idx_medication_active (patient_id, is_active),
    INDEX idx_medication_dates (start_date, end_date)
);

-- Vital signs table
CREATE TABLE vital_signs (
    vital_id INT PRIMARY KEY AUTO_INCREMENT,
    encounter_id INT NOT NULL,
    patient_id INT NOT NULL,
    measurement_datetime DATETIME NOT NULL,
    temperature DECIMAL(4,1),
    pulse INT,
    respiratory_rate INT,
    blood_pressure_systolic INT,
    blood_pressure_diastolic INT,
    oxygen_saturation DECIMAL(4,1),
    height_cm DECIMAL(5,1),
    weight_kg DECIMAL(5,2),
    bmi DECIMAL(4,1) GENERATED ALWAYS AS (weight_kg / POWER(height_cm/100, 2)) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounter_id),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    INDEX idx_vital_datetime (measurement_datetime),
    INDEX idx_patient_vitals (patient_id, measurement_datetime)
);

-- Billing table
CREATE TABLE billing (
    billing_id INT PRIMARY KEY AUTO_INCREMENT,
    encounter_id INT NOT NULL,
    patient_id INT NOT NULL,
    service_date DATE NOT NULL,
    billing_code VARCHAR(20) NOT NULL,
    description VARCHAR(500),
    quantity INT DEFAULT 1,
    charge_amount DECIMAL(10,2) NOT NULL,
    allowed_amount DECIMAL(10,2),
    paid_amount DECIMAL(10,2) DEFAULT 0,
    patient_responsibility DECIMAL(10,2),
    billing_status ENUM('Pending', 'Submitted', 'Paid', 'Denied', 'Appealed') DEFAULT 'Pending',
    insurance_claim_number VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (encounter_id) REFERENCES encounters(encounter_id),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    INDEX idx_billing_status (billing_status),
    INDEX idx_billing_date (service_date)
);

-- Quality measures table
CREATE TABLE quality_measures (
    measure_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    measure_code VARCHAR(50) NOT NULL,
    measure_name VARCHAR(200) NOT NULL,
    measure_type VARCHAR(100),
    measurement_date DATE NOT NULL,
    numerator BOOLEAN DEFAULT FALSE,
    denominator BOOLEAN DEFAULT FALSE,
    exclusion BOOLEAN DEFAULT FALSE,
    performance_met BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    INDEX idx_measure_code (measure_code),
    INDEX idx_measure_date (measurement_date)
);