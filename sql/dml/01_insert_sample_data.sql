-- Sample Healthcare Data
-- Realistic healthcare data for demonstration purposes

USE healthcare_analytics;

-- Insert Departments
INSERT INTO departments (department_name, department_code, location, phone, manager_name) VALUES
('Emergency Department', 'ED', 'Main Hospital - Level 1', '555-0101', 'Dr. Sarah Johnson'),
('Cardiology', 'CARD', 'Heart Center - Level 3', '555-0102', 'Dr. Michael Chen'),
('Internal Medicine', 'IM', 'Main Hospital - Level 2', '555-0103', 'Dr. Emily Williams'),
('Surgery', 'SURG', 'Surgical Tower - Level 2', '555-0104', 'Dr. Robert Martinez'),
('Pediatrics', 'PEDS', 'Children\'s Wing - Level 1', '555-0105', 'Dr. Lisa Anderson'),
('Radiology', 'RAD', 'Imaging Center - Level B1', '555-0106', 'Dr. James Thompson'),
('Laboratory', 'LAB', 'Main Hospital - Level B1', '555-0107', 'Dr. Jennifer Davis'),
('Intensive Care Unit', 'ICU', 'Main Hospital - Level 4', '555-0108', 'Dr. David Wilson'),
('Orthopedics', 'ORTH', 'Surgical Tower - Level 3', '555-0109', 'Dr. Patricia Brown'),
('Obstetrics/Gynecology', 'OBGYN', 'Women\'s Center - Level 2', '555-0110', 'Dr. Maria Garcia');

-- Insert Providers
INSERT INTO providers (npi, first_name, last_name, specialty, department, license_number, license_state, phone, email) VALUES
('1234567890', 'Sarah', 'Johnson', 'Emergency Medicine', 'Emergency Department', 'MD12345', 'CA', '555-1001', 'sjohnson@hospital.com'),
('2345678901', 'Michael', 'Chen', 'Cardiology', 'Cardiology', 'MD23456', 'CA', '555-1002', 'mchen@hospital.com'),
('3456789012', 'Emily', 'Williams', 'Internal Medicine', 'Internal Medicine', 'MD34567', 'CA', '555-1003', 'ewilliams@hospital.com'),
('4567890123', 'Robert', 'Martinez', 'General Surgery', 'Surgery', 'MD45678', 'CA', '555-1004', 'rmartinez@hospital.com'),
('5678901234', 'Lisa', 'Anderson', 'Pediatrics', 'Pediatrics', 'MD56789', 'CA', '555-1005', 'landerson@hospital.com'),
('6789012345', 'James', 'Thompson', 'Radiology', 'Radiology', 'MD67890', 'CA', '555-1006', 'jthompson@hospital.com'),
('7890123456', 'Jennifer', 'Davis', 'Pathology', 'Laboratory', 'MD78901', 'CA', '555-1007', 'jdavis@hospital.com'),
('8901234567', 'David', 'Wilson', 'Critical Care', 'Intensive Care Unit', 'MD89012', 'CA', '555-1008', 'dwilson@hospital.com'),
('9012345678', 'Patricia', 'Brown', 'Orthopedic Surgery', 'Orthopedics', 'MD90123', 'CA', '555-1009', 'pbrown@hospital.com'),
('0123456789', 'Maria', 'Garcia', 'Obstetrics and Gynecology', 'Obstetrics/Gynecology', 'MD01234', 'CA', '555-1010', 'mgarcia@hospital.com');

-- Insert Patients
INSERT INTO patients (medical_record_number, first_name, last_name, date_of_birth, gender, ssn_last_four, email, phone, 
                     address_line1, city, state, zip_code, insurance_provider, insurance_policy_number, 
                     emergency_contact_name, emergency_contact_phone) VALUES
('MRN001', 'John', 'Smith', '1970-05-15', 'M', '1234', 'john.smith@email.com', '555-2001', 
 '123 Main St', 'San Francisco', 'CA', '94101', 'Blue Cross', 'BC123456', 'Jane Smith', '555-2002'),
('MRN002', 'Mary', 'Johnson', '1985-08-22', 'F', '2345', 'mary.johnson@email.com', '555-2003', 
 '456 Oak Ave', 'San Francisco', 'CA', '94102', 'Aetna', 'AE234567', 'Bob Johnson', '555-2004'),
('MRN003', 'Robert', 'Williams', '1955-03-10', 'M', '3456', 'robert.williams@email.com', '555-2005', 
 '789 Pine St', 'Oakland', 'CA', '94601', 'Kaiser', 'KP345678', 'Susan Williams', '555-2006'),
('MRN004', 'Jennifer', 'Brown', '1992-12-01', 'F', '4567', 'jennifer.brown@email.com', '555-2007', 
 '321 Elm Dr', 'Berkeley', 'CA', '94701', 'United Healthcare', 'UH456789', 'Michael Brown', '555-2008'),
('MRN005', 'Michael', 'Davis', '1978-07-18', 'M', '5678', 'michael.davis@email.com', '555-2009', 
 '654 Maple Way', 'San Jose', 'CA', '95101', 'Cigna', 'CI567890', 'Linda Davis', '555-2010'),
('MRN006', 'Linda', 'Miller', '1960-11-25', 'F', '6789', 'linda.miller@email.com', '555-2011', 
 '987 Cedar Ln', 'Palo Alto', 'CA', '94301', 'Blue Cross', 'BC678901', 'James Miller', '555-2012'),
('MRN007', 'William', 'Wilson', '1945-02-14', 'M', '7890', 'william.wilson@email.com', '555-2013', 
 '147 Birch St', 'Mountain View', 'CA', '94041', 'Medicare', 'MC789012', 'Betty Wilson', '555-2014'),
('MRN008', 'Elizabeth', 'Moore', '1988-09-30', 'F', '8901', 'elizabeth.moore@email.com', '555-2015', 
 '258 Spruce Ave', 'Redwood City', 'CA', '94061', 'Aetna', 'AE890123', 'Thomas Moore', '555-2016'),
('MRN009', 'James', 'Taylor', '1973-06-05', 'M', '9012', 'james.taylor@email.com', '555-2017', 
 '369 Willow Dr', 'San Mateo', 'CA', '94401', 'Kaiser', 'KP901234', 'Patricia Taylor', '555-2018'),
('MRN010', 'Patricia', 'Anderson', '1990-04-12', 'F', '0123', 'patricia.anderson@email.com', '555-2019', 
 '741 Ash Way', 'Fremont', 'CA', '94536', 'United Healthcare', 'UH012345', 'Richard Anderson', '555-2020');

-- Insert Encounters (with various types)
INSERT INTO encounters (patient_id, provider_id, department_id, encounter_date, encounter_type, 
                       admission_date, discharge_date, chief_complaint, discharge_disposition) VALUES
-- Emergency visits
(1, 1, 1, '2024-01-15 14:30:00', 'Emergency', '2024-01-15 14:30:00', '2024-01-15 22:45:00', 
 'Chest pain, shortness of breath', 'Admitted'),
(2, 1, 1, '2024-01-20 09:15:00', 'Emergency', '2024-01-20 09:15:00', '2024-01-20 15:30:00', 
 'Severe headache, nausea', 'Discharged home'),
 
-- Inpatient admissions
(1, 2, 2, '2024-01-15 23:00:00', 'Inpatient', '2024-01-15 23:00:00', '2024-01-18 10:00:00', 
 'Acute myocardial infarction', 'Discharged home'),
(3, 4, 4, '2024-02-01 07:00:00', 'Inpatient', '2024-02-01 07:00:00', '2024-02-03 16:00:00', 
 'Scheduled knee replacement', 'Discharged to rehabilitation'),
(7, 8, 8, '2024-02-10 18:00:00', 'Inpatient', '2024-02-10 18:00:00', '2024-02-15 14:00:00', 
 'Pneumonia with sepsis', 'Discharged home'),

-- Outpatient visits
(4, 3, 3, '2024-01-25 10:00:00', 'Outpatient', NULL, NULL, 'Annual physical exam', 'Completed'),
(5, 2, 2, '2024-02-05 14:30:00', 'Outpatient', NULL, NULL, 'Follow-up cardiology visit', 'Completed'),
(6, 9, 9, '2024-02-08 11:00:00', 'Outpatient', NULL, NULL, 'Hip pain evaluation', 'Completed'),
(8, 10, 10, '2024-02-12 09:00:00', 'Outpatient', NULL, NULL, 'Prenatal visit', 'Completed'),
(9, 5, 5, '2024-02-14 15:30:00', 'Outpatient', NULL, NULL, 'Child wellness check', 'Completed'),
(10, 3, 3, '2024-02-18 10:30:00', 'Outpatient', NULL, NULL, 'Diabetes management', 'Completed');

-- Insert Diagnoses
INSERT INTO diagnoses (encounter_id, icd10_code, diagnosis_description, diagnosis_type, diagnosis_date) VALUES
-- Emergency visit diagnoses
(1, 'R07.9', 'Chest pain, unspecified', 'Primary', '2024-01-15'),
(1, 'R06.02', 'Shortness of breath', 'Secondary', '2024-01-15'),
(2, 'R51', 'Headache', 'Primary', '2024-01-20'),
(2, 'R11.0', 'Nausea', 'Secondary', '2024-01-20'),

-- Inpatient diagnoses
(3, 'I21.9', 'Acute myocardial infarction, unspecified', 'Primary', '2024-01-15'),
(3, 'I10', 'Essential hypertension', 'Secondary', '2024-01-15'),
(3, 'E78.5', 'Hyperlipidemia, unspecified', 'Secondary', '2024-01-15'),
(4, 'M17.11', 'Unilateral primary osteoarthritis, right knee', 'Primary', '2024-02-01'),
(5, 'J18.9', 'Pneumonia, unspecified organism', 'Primary', '2024-02-10'),
(5, 'A41.9', 'Sepsis, unspecified organism', 'Secondary', '2024-02-10'),

-- Outpatient diagnoses
(6, 'Z00.00', 'Encounter for general adult medical examination', 'Primary', '2024-01-25'),
(7, 'I25.10', 'Atherosclerotic heart disease', 'Primary', '2024-02-05'),
(8, 'M25.551', 'Pain in right hip', 'Primary', '2024-02-08'),
(9, 'Z34.90', 'Encounter for supervision of normal pregnancy', 'Primary', '2024-02-12'),
(10, 'Z00.121', 'Encounter for routine child health examination', 'Primary', '2024-02-14'),
(11, 'E11.9', 'Type 2 diabetes mellitus without complications', 'Primary', '2024-02-18');

-- Insert Procedures
INSERT INTO procedures (encounter_id, cpt_code, procedure_description, procedure_date, provider_id, modifier, quantity) VALUES
-- Emergency procedures
(1, '93010', 'Electrocardiogram, routine ECG', '2024-01-15 14:45:00', 1, NULL, 1),
(1, '71020', 'Chest X-ray, 2 views', '2024-01-15 15:00:00', 6, NULL, 1),
(2, '70450', 'CT scan head without contrast', '2024-01-20 10:00:00', 6, NULL, 1),

-- Inpatient procedures
(3, '92928', 'Percutaneous coronary angioplasty', '2024-01-16 08:00:00', 2, NULL, 1),
(3, '93458', 'Cardiac catheterization', '2024-01-16 07:00:00', 2, NULL, 1),
(4, '27447', 'Total knee arthroplasty', '2024-02-01 09:00:00', 9, NULL, 1),
(5, '31500', 'Endotracheal intubation', '2024-02-10 18:30:00', 8, NULL, 1),

-- Outpatient procedures
(6, '99395', 'Preventive medicine service, 18-39 years', '2024-01-25 10:00:00', 3, NULL, 1),
(7, '93000', 'Electrocardiogram with interpretation', '2024-02-05 14:30:00', 2, NULL, 1),
(8, '73721', 'MRI hip without contrast', '2024-02-08 12:00:00', 6, NULL, 1),
(9, '76815', 'Ultrasound, pregnant uterus', '2024-02-12 09:30:00', 10, NULL, 1),
(10, '99392', 'Preventive medicine service, 1-4 years', '2024-02-14 15:30:00', 5, NULL, 1);

-- Insert Laboratory Results
INSERT INTO lab_results (encounter_id, patient_id, test_code, test_name, result_value, result_unit, 
                        reference_range, abnormal_flag, collection_datetime, result_datetime, ordering_provider_id) VALUES
-- Emergency labs
(1, 1, 'TROP', 'Troponin I', '2.5', 'ng/mL', '<0.04', 'HH', '2024-01-15 14:45:00', '2024-01-15 15:30:00', 1),
(1, 1, 'CBC', 'Complete Blood Count - WBC', '12.5', 'K/uL', '4.5-11.0', 'H', '2024-01-15 14:45:00', '2024-01-15 15:00:00', 1),
(2, 2, 'CBC', 'Complete Blood Count - WBC', '8.2', 'K/uL', '4.5-11.0', 'N', '2024-01-20 09:30:00', '2024-01-20 10:00:00', 1),

-- Inpatient labs
(3, 1, 'LIPID', 'Total Cholesterol', '285', 'mg/dL', '<200', 'H', '2024-01-16 06:00:00', '2024-01-16 08:00:00', 2),
(3, 1, 'HBA1C', 'Hemoglobin A1C', '7.8', '%', '<5.7', 'H', '2024-01-16 06:00:00', '2024-01-16 10:00:00', 2),
(5, 7, 'LACT', 'Lactic Acid', '4.2', 'mmol/L', '0.5-2.2', 'H', '2024-02-10 18:30:00', '2024-02-10 19:00:00', 8),
(5, 7, 'PCT', 'Procalcitonin', '2.8', 'ng/mL', '<0.5', 'H', '2024-02-10 18:30:00', '2024-02-10 20:00:00', 8),

-- Outpatient labs
(6, 4, 'GLUC', 'Glucose, Fasting', '95', 'mg/dL', '70-100', 'N', '2024-01-25 08:00:00', '2024-01-25 12:00:00', 3),
(11, 10, 'HBA1C', 'Hemoglobin A1C', '8.5', '%', '<5.7', 'H', '2024-02-18 10:00:00', '2024-02-18 14:00:00', 3),
(11, 10, 'GLUC', 'Glucose, Random', '185', 'mg/dL', '70-140', 'H', '2024-02-18 10:30:00', '2024-02-18 14:00:00', 3);

-- Insert Medications
INSERT INTO medications (encounter_id, patient_id, medication_name, generic_name, dosage, route, 
                        frequency, start_date, end_date, prescribing_provider_id) VALUES
-- Emergency medications
(1, 1, 'Aspirin', 'Aspirin', '325mg', 'PO', 'Once', '2024-01-15', '2024-01-15', 1),
(1, 1, 'Nitroglycerin', 'Nitroglycerin', '0.4mg', 'SL', 'Every 5 minutes PRN', '2024-01-15', '2024-01-15', 1),

-- Inpatient medications
(3, 1, 'Metoprolol', 'Metoprolol tartrate', '50mg', 'PO', 'Twice daily', '2024-01-16', NULL, 2),
(3, 1, 'Lisinopril', 'Lisinopril', '10mg', 'PO', 'Once daily', '2024-01-16', NULL, 2),
(3, 1, 'Atorvastatin', 'Atorvastatin', '80mg', 'PO', 'Once daily at bedtime', '2024-01-16', NULL, 2),
(3, 1, 'Clopidogrel', 'Clopidogrel', '75mg', 'PO', 'Once daily', '2024-01-16', NULL, 2),
(5, 7, 'Vancomycin', 'Vancomycin', '1g', 'IV', 'Every 12 hours', '2024-02-10', '2024-02-15', 8),
(5, 7, 'Piperacillin-Tazobactam', 'Piperacillin-Tazobactam', '4.5g', 'IV', 'Every 6 hours', '2024-02-10', '2024-02-15', 8),

-- Outpatient medications
(7, 5, 'Carvedilol', 'Carvedilol', '12.5mg', 'PO', 'Twice daily', '2024-02-05', NULL, 2),
(11, 10, 'Metformin', 'Metformin', '1000mg', 'PO', 'Twice daily with meals', '2024-02-18', NULL, 3);

-- Insert Vital Signs
INSERT INTO vital_signs (encounter_id, patient_id, measurement_datetime, temperature, pulse, respiratory_rate, 
                        blood_pressure_systolic, blood_pressure_diastolic, oxygen_saturation, height_cm, weight_kg) VALUES
-- Emergency vitals
(1, 1, '2024-01-15 14:35:00', 98.2, 95, 20, 165, 95, 94.0, 175.0, 82.0),
(1, 1, '2024-01-15 18:00:00', 98.4, 78, 16, 138, 82, 98.0, 175.0, 82.0),
(2, 2, '2024-01-20 09:20:00', 99.1, 88, 18, 142, 88, 99.0, 165.0, 68.0),

-- Inpatient vitals
(3, 1, '2024-01-16 06:00:00', 98.6, 72, 16, 128, 78, 98.0, 175.0, 82.0),
(3, 1, '2024-01-17 06:00:00', 98.4, 68, 14, 122, 74, 99.0, 175.0, 81.5),
(5, 7, '2024-02-10 18:15:00', 102.5, 115, 28, 92, 58, 88.0, 180.0, 90.0),
(5, 7, '2024-02-11 06:00:00', 100.8, 98, 22, 108, 65, 94.0, 180.0, 90.0),

-- Outpatient vitals
(6, 4, '2024-01-25 10:05:00', 98.6, 70, 16, 118, 76, 99.0, 168.0, 65.0),
(8, 6, '2024-02-08 11:05:00', 98.4, 76, 16, 132, 84, 98.0, 162.0, 72.0),
(11, 10, '2024-02-18 10:35:00', 98.7, 82, 18, 138, 88, 98.0, 170.0, 78.0);

-- Insert Billing Records
INSERT INTO billing (encounter_id, patient_id, service_date, billing_code, description, quantity, 
                    charge_amount, allowed_amount, paid_amount, patient_responsibility, billing_status, insurance_claim_number) VALUES
-- Emergency billing
(1, 1, '2024-01-15', '99285', 'Emergency department visit, high complexity', 1, 1200.00, 800.00, 640.00, 160.00, 'Paid', 'BC2024-001'),
(1, 1, '2024-01-15', '93010', 'Electrocardiogram', 1, 150.00, 100.00, 80.00, 20.00, 'Paid', 'BC2024-001'),
(1, 1, '2024-01-15', '71020', 'Chest X-ray', 1, 250.00, 175.00, 140.00, 35.00, 'Paid', 'BC2024-001'),

-- Inpatient billing
(3, 1, '2024-01-16', '92928', 'Percutaneous coronary angioplasty', 1, 25000.00, 18000.00, 14400.00, 3600.00, 'Paid', 'BC2024-002'),
(3, 1, '2024-01-16', '93458', 'Cardiac catheterization', 1, 5000.00, 3500.00, 2800.00, 700.00, 'Paid', 'BC2024-002'),
(4, 3, '2024-02-01', '27447', 'Total knee arthroplasty', 1, 35000.00, 28000.00, 28000.00, 0.00, 'Paid', 'KP2024-003'),

-- Outpatient billing
(6, 4, '2024-01-25', '99395', 'Preventive medicine service', 1, 250.00, 200.00, 160.00, 40.00, 'Paid', 'UH2024-004'),
(11, 10, '2024-02-18', '99213', 'Office visit, established patient', 1, 150.00, 120.00, 96.00, 24.00, 'Submitted', 'UH2024-005');

-- Insert Quality Measures
INSERT INTO quality_measures (patient_id, measure_code, measure_name, measure_type, measurement_date, 
                             numerator, denominator, exclusion, performance_met) VALUES
-- Diabetes care measures
(10, 'DM-HBA1C', 'Diabetes: HbA1c Control', 'Process', '2024-02-18', FALSE, TRUE, FALSE, FALSE),
(10, 'DM-EYE', 'Diabetes: Eye Exam', 'Process', '2024-02-18', FALSE, TRUE, FALSE, FALSE),

-- Cardiovascular measures
(1, 'CAD-LDL', 'CAD: LDL Control', 'Outcome', '2024-01-16', FALSE, TRUE, FALSE, FALSE),
(1, 'CAD-ASA', 'CAD: Aspirin Therapy', 'Process', '2024-01-16', TRUE, TRUE, FALSE, TRUE),

-- Preventive care measures
(4, 'PREV-BMI', 'Preventive Care: BMI Screening', 'Process', '2024-01-25', TRUE, TRUE, FALSE, TRUE),
(6, 'PREV-BP', 'Preventive Care: Blood Pressure Screening', 'Process', '2024-02-08', TRUE, TRUE, FALSE, TRUE);