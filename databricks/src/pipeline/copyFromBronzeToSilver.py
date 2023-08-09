# Databricks notebook source
# MAGIC %md
# MAGIC 1. Import required libraries

# COMMAND ----------

from pyspark.sql.functions import to_timestamp, concat, col, lit, to_date, current_timestamp, explode
from delta.tables import *

# COMMAND ----------

dbutils.widgets.text("destination", "")
file_destination = dbutils.widgets.get("destination")
absolute_path = "/mnt/datalake_mount/" + file_destination;

# COMMAND ----------

# MAGIC %md
# MAGIC 2. Import schema from patient notebook using magic command

# COMMAND ----------

# MAGIC %md
# MAGIC 3. Include schema from '../pipeline/schema/patient' file

# COMMAND ----------

# MAGIC %run "../pipeline/schema/patient"

# COMMAND ----------

# MAGIC %md
# MAGIC 4. Read data from bronze layer

# COMMAND ----------

display(dbutils.fs.mounts())

# COMMAND ----------

df = spark.read.schema(schema).option("recursiveFileLookup","true").json(absolute_path, multiLine=True)
df = df.dropDuplicates(subset = ['id'])

# COMMAND ----------

df.show()

# COMMAND ----------

df_converted_date = df.withColumn("birth_date", to_date(col("birthDate"), 'yyyy-MM-dd'))\
    .withColumn("ingestion_date", current_timestamp())\
    .withColumnRenamed("resourceType", "resource_type")\
    .drop(col("birthDate"))

#df_address_explode = df_converted_date.select(explode(df.address))


# COMMAND ----------

df_converted_date.head()

# COMMAND ----------

#%sql
#DROP TABLE IF EXISTS patients

# COMMAND ----------

#spark.sql("show tables").show()

# COMMAND ----------

patient_delta_table = DeltaTable.createIfNotExists(spark).location("/mnt/datalake_mount/silver/patient-table")\
  .tableName("patients") \
  .addColumns(df_converted_date.schema)\
  .addColumn("update_date", "TIMESTAMP")\
  .execute()

# COMMAND ----------

#patient_delta_table = DeltaTable.forPath(spark, "/mnt/datalake_mount/silver/patient-table")

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

# MAGIC %sql
# MAGIC select * from patients
