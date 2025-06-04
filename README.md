# Healthcare Analytics SQL Project

A comprehensive SQL-based healthcare analytics system demonstrating advanced database design, complex queries, and data analysis techniques for healthcare informatics professionals.

## Project Overview

This project showcases a complete healthcare data warehouse implementation with realistic healthcare scenarios including:
- Patient management and demographics
- Clinical encounters and diagnoses
- Laboratory results and medications
- Billing and revenue cycle management
- Quality measures and performance metrics

## Key Features

### 1. **Comprehensive Database Schema**
- 12 interconnected tables modeling a complete healthcare system
- HIPAA-compliant design patterns
- Proper indexing for optimal query performance
- Referential integrity with foreign key constraints

### 2. **Advanced Analytics Queries**
- Patient risk stratification and population health analytics
- Clinical quality metrics and outcome analysis
- Financial performance and revenue cycle analytics
- Readmission prediction and prevention
- Care gap identification

### 3. **Stored Procedures & Functions**
- Automated patient risk scoring
- Department performance reporting
- Medication adherence tracking
- Care gap detection
- Readmission risk assessment

### 4. **Data Quality Framework**
- Comprehensive data validation checks
- Data completeness monitoring
- Anomaly detection for clinical values
- Referential integrity validation

## Database Schema

### Core Tables

1. **patients** - Patient demographics and contact information
2. **providers** - Healthcare provider information
3. **departments** - Hospital departments and units
4. **encounters** - Patient visits and admissions
5. **diagnoses** - ICD-10 diagnosis codes
6. **procedures** - CPT procedure codes
7. **lab_results** - Laboratory test results
8. **medications** - Medication orders and prescriptions
9. **vital_signs** - Patient vital sign measurements
10. **billing** - Charges and payment information
11. **quality_measures** - Clinical quality metrics
12. **insurance** - Insurance provider information

## Technical Highlights

### Complex Query Examples

1. **30-Day Readmission Analysis**
   - Identifies patients readmitted within 30 days
   - Calculates readmission rates by diagnosis
   - Supports targeted intervention programs

2. **Chronic Disease Management Dashboard**
   - Tracks patients with multiple chronic conditions
   - Monitors care compliance and gaps
   - Identifies high-risk patients for case management

3. **Financial Performance Analytics**
   - Revenue cycle metrics and KPIs
   - Payer mix analysis
   - Service line profitability
   - Accounts receivable aging

### Stored Procedures

- `CalculatePatientRiskScore` - Comprehensive risk assessment
- `GenerateDepartmentReport` - Automated performance reporting
- `IdentifyCareGaps` - Proactive care management
- `PredictReadmissionRisk` - ML-ready risk prediction

## Getting Started

### Prerequisites
- MySQL 8.0+ or compatible database system
- SQL client (MySQL Workbench, DBeaver, etc.)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/dariyanisacc/healthcare-analytics-sql.git
cd healthcare-analytics-sql
```

2. Run the automated setup script:
```bash
./setup_database.sh
```

Or manually run each step:
```bash
mysql -u root -p < sql/ddl/01_create_database.sql
mysql -u root -p healthcare_analytics < sql/ddl/02_create_tables.sql
mysql -u root -p healthcare_analytics < sql/dml/01_insert_sample_data.sql
mysql -u root -p healthcare_analytics < sql/procedures/01_stored_procedures.sql
mysql -u root -p healthcare_analytics < sql/functions/01_utility_functions.sql
```

### Quick Demo

Run the demo script to see the analytics in action:
```bash
./run_demo.sh
```

For detailed examples with actual output, see [EXAMPLE_OUTPUT.md](EXAMPLE_OUTPUT.md)

## Usage Examples

### Patient Risk Assessment
```sql
CALL CalculatePatientRiskScore(1, @risk_score, @risk_category);
SELECT @risk_score, @risk_category;
```

### Department Performance Report
```sql
CALL GenerateDepartmentReport(1, '2024-01-01', '2024-12-31');
```

### Quality Metrics Dashboard
```sql
-- Run chronic disease management query
SOURCE sql/queries/01_patient_analytics.sql;
```

## Project Structure
```
healthcare-analytics-sql/
├── README.md
├── documentation/
│   ├── schema_diagram.png
│   ├── data_dictionary.md
│   └── query_guide.md
├── sql/
│   ├── ddl/
│   │   ├── 01_create_database.sql
│   │   └── 02_create_tables.sql
│   ├── dml/
│   │   └── 01_insert_sample_data.sql
│   ├── queries/
│   │   ├── 01_patient_analytics.sql
│   │   ├── 02_clinical_analytics.sql
│   │   ├── 03_financial_analytics.sql
│   │   └── 04_data_quality_checks.sql
│   ├── procedures/
│   │   └── 01_stored_procedures.sql
│   └── functions/
│       └── 01_utility_functions.sql
├── data/
│   └── sample_data_generator.py
└── scripts/
    └── setup.sh
```

## Healthcare Informatics Applications

This project demonstrates key competencies for healthcare informatics roles:

1. **Clinical Decision Support**
   - Risk stratification algorithms
   - Care gap identification
   - Clinical pathway adherence monitoring

2. **Population Health Management**
   - Chronic disease tracking
   - Preventive care metrics
   - Health outcome analysis

3. **Revenue Cycle Optimization**
   - Denial management analytics
   - Payer performance tracking
   - Cost analysis by service line

4. **Quality Reporting**
   - CMS quality measure tracking
   - HEDIS metric calculation
   - Clinical performance benchmarking

5. **Operational Analytics**
   - ED throughput analysis
   - Length of stay optimization
   - Resource utilization metrics

## Best Practices Demonstrated

- **Data Privacy**: No real patient data; HIPAA-compliant design
- **Performance**: Optimized indexes and query structures
- **Scalability**: Modular design supporting millions of records
- **Maintainability**: Clear naming conventions and documentation
- **Reusability**: Stored procedures and functions for common tasks

## Future Enhancements

- Integration with HL7 FHIR standards
- Machine learning model integration
- Real-time dashboard capabilities
- Predictive analytics for patient outcomes
- Natural language processing for clinical notes

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions or opportunities, please connect on:
- LinkedIn: www.linkedin.com/in/dariyan-jones-919185239
- Email: dariyanisacc@gmail.com

---

*This project is for educational and demonstration purposes only. All data is synthetic and does not represent real patient information.*
