#!/bin/bash

# Healthcare Analytics Database Setup Script (No Password Version)

echo "Healthcare Analytics SQL Database Setup"
echo "======================================"
echo ""
echo "This script will:"
echo "1. Create the healthcare_analytics database"
echo "2. Create all tables"
echo "3. Load sample data"
echo "4. Create stored procedures and functions"
echo ""

# Navigate to project directory
cd "$(dirname "$0")"

# Step 1: Create Database
echo "Step 1: Creating database..."
mysql -u root < sql/ddl/01_create_database.sql
if [ $? -eq 0 ]; then
    echo "✓ Database created successfully"
else
    echo "✗ Failed to create database"
    exit 1
fi

# Step 2: Create Tables
echo ""
echo "Step 2: Creating tables..."
mysql -u root healthcare_analytics < sql/ddl/02_create_tables.sql
if [ $? -eq 0 ]; then
    echo "✓ Tables created successfully"
else
    echo "✗ Failed to create tables"
    exit 1
fi

# Step 3: Load Sample Data
echo ""
echo "Step 3: Loading sample data..."
mysql -u root healthcare_analytics < sql/dml/01_insert_sample_data.sql
if [ $? -eq 0 ]; then
    echo "✓ Sample data loaded successfully"
else
    echo "✗ Failed to load sample data"
    exit 1
fi

# Step 4: Create Stored Procedures
echo ""
echo "Step 4: Creating stored procedures..."
mysql -u root healthcare_analytics < sql/procedures/01_stored_procedures.sql
if [ $? -eq 0 ]; then
    echo "✓ Stored procedures created successfully"
else
    echo "✗ Failed to create stored procedures"
    exit 1
fi

# Step 5: Create Functions
echo ""
echo "Step 5: Creating utility functions..."
mysql -u root healthcare_analytics < sql/functions/01_utility_functions.sql
if [ $? -eq 0 ]; then
    echo "✓ Functions created successfully"
else
    echo "✗ Failed to create functions"
    exit 1
fi

echo ""
echo "======================================"
echo "✅ Database setup complete!"
echo ""
echo "You can now connect to the database using:"
echo "  mysql -u root healthcare_analytics"
echo ""
echo "Try running some analytics queries:"
echo "  mysql -u root healthcare_analytics < sql/queries/01_patient_analytics.sql"
echo ""
echo "To explore the database interactively:"
echo "  mysql -u root healthcare_analytics"
echo "  Then try: SHOW TABLES;"
echo "           SELECT * FROM patients LIMIT 5;"
echo "           CALL CalculatePatientRiskScore(1, @risk_score, @risk_category);"
echo "           SELECT @risk_score, @risk_category;"