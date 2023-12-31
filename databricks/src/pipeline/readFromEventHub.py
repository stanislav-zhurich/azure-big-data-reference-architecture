# Databricks notebook source
# MAGIC %md
# MAGIC 1. Import required libraries.

# COMMAND ----------

from pyspark.sql.functions import to_timestamp, concat, col, from_json, explode, to_date, transform, udf, current_timestamp
from delta.tables import *

# COMMAND ----------

spark.conf.set("spark.databricks.delta.constraints.allowUnenforcedNotNull.enabled", True)

# COMMAND ----------

# MAGIC %md
# MAGIC 2. Import *observation* schema using magic command.

# COMMAND ----------

# MAGIC %run "../pipeline/schema/observation.py"

# COMMAND ----------

# MAGIC %run "../pipeline/properties.py"

# COMMAND ----------

# MAGIC %md
# MAGIC 3. Read event hub connection string value from secrets. It has been already added during installation process. Use *dbutils.secrets.get()* method.
# MAGIC  - key = *source-eventhub-connection-string*
# MAGIC  - secrets name = *keyvault-managed*

# COMMAND ----------

eventhub_connection_string = dbutils.secrets.get(scope = "keyvault-managed", key = "source-eventhub-connection-string")

# COMMAND ----------

# MAGIC %md
# MAGIC 4. Read stream of events from event hub.
# MAGIC - Use *eventhubs* format option.
# MAGIC - Add checkpoint location option.
# MAGIC - To retrieve payload from the binary data use following statement:
# MAGIC > df.select(from_json(col("body").cast("STRING"), schema=schema).alias("data")).select("data.*")

# COMMAND ----------

# MAGIC %md
# MAGIC 5. Apply following transformation logic:
# MAGIC - identifier[0].value => id => retrieve uid only, get rid of prefix
# MAGIC - status => status
# MAGIC - category[0].coding[0].code => category_code
# MAGIC - code.coding[0].code => code
# MAGIC - subject.reference => patient_id => get rid of Patient/ prefix
# MAGIC - resourceType => resource_type
# MAGIC - effectiveDateTime => to_date => effective_date
# MAGIC - performer[0].reference => practitioner
# MAGIC - component[0].valueQuantity.value => systolic_pressure_value
# MAGIC - component[0].valueQuantity.unit => systolic_pressure_unit
# MAGIC - component[0].interpretation[0].coding[0].display => systolic_interpretation
# MAGIC - component[1].valueQuantity.value => diastolic_pressure_value
# MAGIC - component[1].valueQuantity.unit => diastolic_pressure_unit
# MAGIC - component[1].interpretation[0].coding[0].display => diastolic_interpretation

# COMMAND ----------

def retrieve_observation_id(str_id):
    id_parts = str_id.split(":")
    return id_parts[2]

retrieve_observation_id_udf = udf(lambda x:retrieve_observation_id(x),StringType()) 

# COMMAND ----------

def retrieve_patient_id(str_id):
    id_parts = str_id.split("/")
    return id_parts[1]

retrieve_patient_id_udf = udf(lambda x:retrieve_patient_id(x),StringType()) 

# COMMAND ----------

ehConf = {}
ehConf['eventhubs.connectionString'] = sc._jvm.org.apache.spark.eventhubs.EventHubsUtils.encrypt(eventhub_connection_string)
ehConf['mergeSchema'] = True

df = spark.readStream.format("eventhubs").options(**ehConf).load()
checkpoint_path = "/mnt/datalake_mount/silver/temp/observations/_checkpoints/"

select_df = df.select(from_json(col("body").cast("STRING"), schema=schema).alias("data")).select("data.*")\
    .select(retrieve_observation_id_udf(col("identifier")[0].value).alias("id"), 
            col("status"), 
            col("category")[0].coding[0].code.alias("category_code"),
            col("code").coding[0].code.alias("code"),
            retrieve_patient_id_udf(col("subject").reference).alias("patient_id"),
            col("resourceType").alias("resource_type"),
            to_date(col("effectiveDateTime")).alias("effective_date"),
            col("performer")[0].reference.alias("practitioner"),
            col("component")[0].valueQuantity.value.alias("systolic_pressure_value"),
            col("component")[0].valueQuantity.unit.alias("systolic_pressure_unit"),
            col("component")[0].interpretation[0].coding[0].display.alias("systolic_interpretation"),
            col("component")[1].valueQuantity.value.alias("diastolic_pressure_value"),
            col("component")[1].valueQuantity.unit.alias("diastolic_pressure_unit"),
            col("component")[1].interpretation[0].coding[0].display.alias("diastolic_interpretation"))\
                .withColumn("ingestion_date", current_timestamp())

# COMMAND ----------

# MAGIC %md
# MAGIC 5. Create external Delta table *silver_observations*.
# MAGIC  - partition data by *patient_id*
# MAGIC  - enable *change data feed* support for the table

# COMMAND ----------

DeltaTable.createIfNotExists(spark).location(silver_observations_table_location)\
  .tableName(silver_observations_table_name).partitionedBy("patient_id")\
  .addColumns(select_df.schema).execute()

# COMMAND ----------

# MAGIC %sql
# MAGIC ALTER TABLE silver_observations SET TBLPROPERTIES (delta.enableChangeDataFeed = true)

# COMMAND ----------

# MAGIC %md
# MAGIC 6. Write data to just created table.
# MAGIC - Use *delta* as a storage format
# MAGIC - Partition data by *patient_id*
# MAGIC - Use *append* as output mode
# MAGIC - Specify *checkpointLocation*

# COMMAND ----------

select_df.writeStream.format("delta").partitionBy("patient_id").outputMode("append").option("inferSchema", "true").option("mergeSchema", "true").option("checkpointLocation", checkpoint_path).option("schemaTrackingLocation", checkpoint_path)\
   .toTable(silver_observations_table_name)

# COMMAND ----------

#%sql
#DROP TABLE IF EXISTS gold_patient_observations
