# Databricks notebook source
# MAGIC %md
# MAGIC 1. Import required libraries

# COMMAND ----------

# MAGIC %md 
# MAGIC 2. Make sure that change data feed support is enabled for the *silver_observations* table. It had to be enabled during table creation, otherwise alter table.

# COMMAND ----------

# MAGIC %md 
# MAGIC 3. Read data stream from silver_observations delta table.

# COMMAND ----------

# MAGIC %md 4. 
# MAGIC Configure eventhub connection string for outbound event hub topic. Use following setting to read the string:
# MAGIC - scope: keyvault-managed
# MAGIC - key: target-eventhub-connection-string

# COMMAND ----------

# MAGIC %md 
# MAGIC 5. Select following observation fields from inbound stream:
# MAGIC - systolic_pressure_value
# MAGIC - systolic_interpretation
# MAGIC - diastolic_pressure_value
# MAGIC - diastolic_interpretation
# MAGIC - ingestion_date
# MAGIC Join following data from patient table:
# MAGIC - patient_id
# MAGIC - family_name
# MAGIC - given_name

# COMMAND ----------

# MAGIC %md 
# MAGIC 6. Outbound event hub expects data to be in json format as *body* property. Transform your dataframe accordingly.
# MAGIC >Hint: use following expression df.select(to_json(struct(*[c for c in df.columns])).alias("body"))

# COMMAND ----------

# MAGIC %md 7. 
# MAGIC Write data stream to outbound event hub.
