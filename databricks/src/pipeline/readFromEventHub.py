# Databricks notebook source
# MAGIC %md
# MAGIC 1. Import required libraries.

# COMMAND ----------

# MAGIC %md 2. 
# MAGIC Import *observation* schema using magic (run) command.

# COMMAND ----------

# MAGIC %md 
# MAGIC 3. Read event hub connection string value from secrets. It has been already added during installation process. Use *dbutils.secrets.get()* method.
# MAGIC - key = source-eventhub-connection-string
# MAGIC - secrets name = keyvault-managed

# COMMAND ----------

# MAGIC %md 
# MAGIC 4. Read stream of events from event hub.
# MAGIC - Use eventhubs format option.
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

# MAGIC %md 
# MAGIC 6. Create external Delta table *silver_observations*.
# MAGIC - partition data by patient_id
# MAGIC - enable change data feed support for the table

# COMMAND ----------

# MAGIC %md 
# MAGIC 7. Write data to just created table.
# MAGIC - Use *delta* as a storage format
# MAGIC - Partition data by *patient_id*
# MAGIC - Use *append* as output mode
# MAGIC - Specify *checkpointLocation*
