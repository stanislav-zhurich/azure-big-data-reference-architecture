# Databricks notebook source
# MAGIC %md
# MAGIC 1. Import required libraries


# MAGIC %md
# MAGIC 2. Read *patient_id* parameter passed from within Data Factory pipeline.

# MAGIC %md
# MAGIC 3. Read and join data from *silver_patients* and *silver_observations* tables.
# MAGIC - select following columns: *silver_patients.id, family_name, given_name, work_phone, mobile_phone, gender,birth_date,active, city, district,line, postal_code, state*.
# MAGIC - find average *systolic_pressure_value* and *diastolic_pressure_value*. Add it to select statement, not forgetting to add right grouping.

# MAGIC %md
# MAGIC 4. Create (if not already exists) external Delta table *gold_patient_observations*.
# MAGIC - Use a schema of select statement defined above.
# MAGIC - Add *update_date* column with value indicating the last timestamp of record update.
# MAGIC - Add *ingestion_date* column with value indicating the timestamp when record was created.

# MAGIC %md
# MAGIC 5. Execute *merge* operation. 
