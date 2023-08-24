# Databricks notebook source
# MAGIC %md
# MAGIC 1. Import required libraries

# COMMAND ----------

from pyspark.sql.functions import to_timestamp, concat, col, from_json, explode, to_date, transform, udf, current_timestamp, lit, struct, to_json
from pyspark.sql.types import StringType
import json

# COMMAND ----------

# MAGIC %run "../pipeline/properties.py"

# COMMAND ----------

# MAGIC %md
# MAGIC 2. Make sure that *change data feed* support is enabled for the *silver_observations* table

# COMMAND ----------

# MAGIC %md
# MAGIC 3. Read data stream from *silver_observations* delta table. 

# COMMAND ----------

spark.readStream.format("delta") \
  .option("readChangeFeed", "true") \
  .table(silver_observations_table_name) \
  .createOrReplaceTempView("temp_observations")

# COMMAND ----------

# MAGIC %md
# MAGIC 4. Configure eventhub connection string for outbound event hub topic. Use following setting to read the string:
# MAGIC - scope: *keyvault-managed*
# MAGIC - key: *target-eventhub-connection-string*

# COMMAND ----------

eventhub_connection_string = dbutils.secrets.get(scope = "keyvault-managed", key = "target-eventhub-connection-string")
ehConf = {}
ehConf['eventhubs.connectionString'] = sc._jvm.org.apache.spark.eventhubs.EventHubsUtils.encrypt(eventhub_connection_string)
checkpoint_path = "/mnt/datalake_mount/gold/temp/observations/_checkpoints/"

# COMMAND ----------

# MAGIC %md
# MAGIC 5. Select following *observation* fields from inbound stream:
# MAGIC - systolic_pressure_value
# MAGIC - systolic_interpretation
# MAGIC - diastolic_pressure_value
# MAGIC - diastolic_interpretation
# MAGIC - ingestion_date
# MAGIC
# MAGIC Join following data from *patient* table:
# MAGIC - patient_id
# MAGIC - family_name
# MAGIC - given_name

# COMMAND ----------

df = spark.sql(f"select patient_id, family_name, given_name, systolic_pressure_value, systolic_interpretation, diastolic_pressure_value, diastolic_interpretation, o.ingestion_date from temp_observations o join {silver_patients_table_name} p on o.patient_id = p.id")

# COMMAND ----------

# MAGIC %md
# MAGIC 6. Outbound event hub expects data to be in json format in *body* column. Transform your dataframe accordingly.
# MAGIC > Tip: use following expression df.select(to_json(struct(*[c for c in df.columns])).alias("body"))

# COMMAND ----------

json_df = df.select(to_json(struct(*[c for c in df.columns])).alias("body"))

# COMMAND ----------

# MAGIC %md
# MAGIC 7. Stream data to event hub

# COMMAND ----------

df = json_df.writeStream \
  .format("eventhubs") \
  .options(**ehConf) \
  .option("checkpointLocation", checkpoint_path)\
  .start()


