# Databricks notebook source
# MAGIC %md
# MAGIC 1. Import required libraries

# COMMAND ----------

from pyspark.sql.functions import to_timestamp, concat, col, lit, to_date, current_timestamp, explode
from delta.tables import *

# COMMAND ----------

# MAGIC %md
# MAGIC 2. Read file_destination from a parameter (destination) passed by Data Factory. Use dbutils.

# COMMAND ----------

dbutils.widgets.text("destination", "")
file_destination = dbutils.widgets.get("destination")
absolute_path = "/mnt/datalake_mount/" + file_destination;

# COMMAND ----------

# MAGIC %md
# MAGIC 3. Import patient schema '../pipeline/schema/patient' using magic command

# COMMAND ----------

# MAGIC %run "../pipeline/schema/patient"

# COMMAND ----------

# MAGIC %md
# MAGIC 4. Read json data from bronze layer. As a path use 'absolute_path' variable defined above.

# COMMAND ----------

df = spark.read.schema(schema).option("recursiveFileLookup","true").json(absolute_path, multiLine=True)
df = df.dropDuplicates(subset = ['id'])

# COMMAND ----------

# MAGIC %md
# MAGIC 5. Do the following transformations with data set:
# MAGIC - add new column 'ingestion_date' with the value equal current timestamp.
# MAGIC - change type of 'birthDate' column from string to date.
# MAGIC - rename 'resourceType' column to 'resource_type'
# MAGIC - rename 'birthdatDate' to 'birth_date'

# COMMAND ----------

df_converted_date = df.withColumn("birth_date", to_date(col("birthDate"), 'yyyy-MM-dd'))\
    .withColumn("ingestion_date", current_timestamp())\
    .withColumnRenamed("resourceType", "resource_type")\
    .drop(col("birthDate"))


# COMMAND ----------

#%sql
#DROP TABLE IF EXISTS patients

# COMMAND ----------

#spark.sql("show tables").show()

# COMMAND ----------

# MAGIC %md
# MAGIC 6. Create new table delta table (if not exists) using patient schema defined below and following location '/mnt/datalake_mount/silver/patient-table'. Also add new 'update_date' column.

# COMMAND ----------

patient_delta_table = DeltaTable.createIfNotExists(spark).location("/mnt/datalake_mount/silver/patient-table")\
  .tableName("patients") \
  .addColumns(df_converted_date.schema)\
  .addColumn("update_date", "TIMESTAMP")\
  .execute()

# COMMAND ----------

# MAGIC %md
# MAGIC 7. Merge existing patient data with received updates. Use 'id' to match records. If record is updated change the value of 'update_date' to current timestamp, otherwise leave it blank.

# COMMAND ----------

patient_delta_table.alias('patients') \
  .merge(
    df_converted_date.alias('updates'),
    'patients.id = updates.id'
  ) \
  .whenMatchedUpdate(set =
    {
      "id": "updates.id",
      "active": "updates.active",
      "gender": "updates.gender",
      "resource_type": "updates.resource_type",
      "address": "updates.address",
      "name": "updates.name",
      "telecom": "updates.telecom",
      "birth_date": "updates.birth_date",
      "update_date": current_timestamp()
    }
  ) \
  .whenNotMatchedInsert(values =
     {
      "id": "updates.id",
      "active": "updates.active",
      "gender": "updates.gender",
      "resource_type": "updates.resource_type",
      "address": "updates.address",
      "name": "updates.name",
      "telecom": "updates.telecom",
      "birth_date": "updates.birth_date",
      "ingestion_date": current_timestamp()
    }
  ) \
  .execute()

# COMMAND ----------

# MAGIC %md
# MAGIC 8. Execute 'select all' command using SQL syntax.

# COMMAND ----------

# MAGIC %sql
# MAGIC select * from patients
