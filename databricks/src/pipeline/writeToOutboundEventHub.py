# Databricks notebook source
# MAGIC %md
# MAGIC 1. Import required libraries

# MAGIC %md
# MAGIC 2. Make sure that *change data feed* support is enabled for the *silver_observations* table


# MAGIC %md
# MAGIC 3. Read data stream from *silver_observations* delta table. 


# MAGIC %md
# MAGIC 4. Configure eventhub connection string for outbound event hub topic. Use following setting to read the string:
# MAGIC - scope: *keyvault-managed*
# MAGIC - key: *target-eventhub-connection-string*


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


# MAGIC %md
# MAGIC 6. Outbound event hub expects data to be in json format in *body* column. Transform your dataframe accordingly.
# MAGIC > Tip: use following expression df.select(to_json(struct(*[c for c in df.columns])).alias("body"))


# MAGIC %md
# MAGIC 7. Stream data to event hub



