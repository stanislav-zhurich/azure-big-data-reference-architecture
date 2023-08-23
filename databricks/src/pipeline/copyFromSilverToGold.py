# Databricks notebook source
# MAGIC %md
# MAGIC 1. Import required libraries

# COMMAND ----------

from pyspark.sql.functions import to_timestamp, concat, col, lit, to_date, current_timestamp, array_join, avg
from delta.tables import *
from pyspark.sql.window import Window
import json

# COMMAND ----------

# MAGIC %md
# MAGIC 2. Read *patient_id* parameter passed from within Data Factory pipeline.

# COMMAND ----------

dbutils.widgets.text("patient_id", "")
str_patient_id = dbutils.widgets.get("patient_id")
patient_id = json.loads(str_patient_id)[0]
print(patient_id)

# COMMAND ----------

# MAGIC %md
# MAGIC 3. Read and join data from *silver_patients* and *silver_observations* tables.
# MAGIC - select following columns: *silver_patients.id, amily_name, given_name, work_phone, mobile_phone, gender,birth_date,active, city, district,line, postal_code, state*.
# MAGIC - find average *systolic_pressure_value* and *diastolic_pressure_value*. Add it to select statement, not forgetting to add right grouping.

# COMMAND ----------

patients_observations = spark.sql(
    "select avg(systolic_pressure_value) as avg_systolic_pressure, avg(diastolic_pressure_value) as avg_diastolic_pressure, p.id, family_name, given_name, work_phone, mobile_phone, gender,birth_date,active, city,district,line,postal_code,state from silver_patients p join silver_observations o on p.id = o.patient_id where p.id = {patient_id} group by p.id, family_name, given_name, work_phone, mobile_phone, gender,birth_date,active, city,district,line,postal_code,state", 
    patient_id = patient_id)
display(patients_observations)

# COMMAND ----------

#%sql
#DROP TABLE IF EXISTS gold_patient_observations

# COMMAND ----------

# MAGIC %md
# MAGIC 4. Create (if not already exists) external Delta table *gold_patient_observations*.
# MAGIC - Use a schema of select statement defined above.
# MAGIC - Add *update_date* column with value indicating the last timestamp of record update.
# MAGIC - Add *ingestion_date* column with value indicating the timestamp when record was created.

# COMMAND ----------

patient_observation_table = DeltaTable.createIfNotExists(spark).location("/mnt/datalake_mount/gold/patient_observation_table")\
  .tableName("gold_patient_observations") \
  .addColumns(patients_observations.schema)\
  .addColumn("update_date", "TIMESTAMP")\
  .addColumn("ingestion_date", "TIMESTAMP")\
  .execute()

# COMMAND ----------

# MAGIC %md
# MAGIC 5. Execute *merge* operation. 

# COMMAND ----------

patient_observation_table.alias('patient_observation') \
  .merge(
    patients_observations.alias('updates'),
    'patient_observation.id = updates.id'
  ) \
  .whenMatchedUpdate(set =
    {
      "id": "updates.id",
      "avg_systolic_pressure": "updates.avg_systolic_pressure",
      "avg_diastolic_pressure": "updates.avg_diastolic_pressure",
      "active": "updates.active",
      "gender": "updates.gender",
      "city": "updates.city",
      "district": "updates.district",
      "state": "updates.state",
      "line": "updates.line",
      "postal_code": "updates.postal_code",
      "family_name": "updates.family_name",
      "given_name": "updates.given_name",
      "work_phone": "updates.work_phone",
      "mobile_phone": "updates.mobile_phone",
      "birth_date": "updates.birth_date",
      "update_date": current_timestamp()
    }

  ) \
  .whenNotMatchedInsert(values =
     {
      "id": "updates.id",
      "avg_systolic_pressure": "updates.avg_systolic_pressure",
      "avg_diastolic_pressure": "updates.avg_diastolic_pressure",
      "active": "updates.active",
      "gender": "updates.gender",
      "city": "updates.city",
      "district": "updates.district",
      "state": "updates.state",
      "line": "updates.line",
      "postal_code": "updates.postal_code",
      "family_name": "updates.family_name",
      "given_name": "updates.given_name",
      "work_phone": "updates.work_phone",
      "mobile_phone": "updates.mobile_phone",
      "birth_date": "updates.birth_date",
      "ingestion_date": current_timestamp()
    }
  ) \
  .execute()

# COMMAND ----------

#%sql
#select * from gold_patient_observations
