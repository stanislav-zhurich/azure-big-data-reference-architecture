# Databricks notebook source
# MAGIC %md
# MAGIC 1. Import required libraries

# COMMAND ----------

from pyspark.sql.functions import to_timestamp, concat, col, lit, to_date, current_timestamp, array_join
from delta.tables import *
import json

# COMMAND ----------

# MAGIC %md
# MAGIC 2. List all available mounts, make sure that */mnt/datalake_mount* is availble and points to your datalake storage.

# COMMAND ----------

display(dbutils.fs.mounts())

# COMMAND ----------

# MAGIC %md
# MAGIC 3. Import *properties.py* file using magic command. The file contains usefull constants you might find handy for your code.
# MAGIC > Hint: use *%run* magic command 

# COMMAND ----------

# MAGIC %run "../pipeline/properties.py"

# COMMAND ----------

# MAGIC %md
# MAGIC 4. Read *file_destination*  parameter passed from within Data Factory pipeline. 
# MAGIC > Hint: use *dbutils.widgets.get* method.

# COMMAND ----------

dbutils.widgets.text("file_destination", "")
file_destination = dbutils.widgets.get("file_destination")
absolute_path = mount_prefix + file_destination;

# COMMAND ----------

# MAGIC %md
# MAGIC 5. Import patient schema '../pipeline/schema/patient.py'.

# COMMAND ----------

# MAGIC %run "../pipeline/schema/patient.py"

# COMMAND ----------

# MAGIC %md
# MAGIC 6. Read json data from bronze layer. As a path use parameter read from Data Factory prefixed with moint endpoint.

# COMMAND ----------

df = spark.read.schema(schema).option("recursiveFileLookup","true").json(absolute_path, multiLine=True)
df = df.dropDuplicates(subset = ['id'])

# COMMAND ----------

display(df)

# COMMAND ----------

# MAGIC %md
# MAGIC 7. Select following columns and apply transformations for dataframe:
# MAGIC - id => id
# MAGIC - gender => gender
# MAGIC - active => active
# MAGIC - resourceType => resource_type
# MAGIC - birthDate => to_date => birth_date
# MAGIC - name[0].family => family_name
# MAGIC - name[0].given => given_name
# MAGIC - telecom[1].value => work_phone
# MAGIC - telecom[2].value => mobile_phone
# MAGIC - address[0].city => city
# MAGIC - address[0].district => district
# MAGIC - address[0].state => state
# MAGIC - address[0].line[0] => line
# MAGIC - address[0].postalCode => postal_code
# MAGIC - add new column 'ingestion_date' with the value equal current timestamp.
# MAGIC

# COMMAND ----------

df_converted_data = df.select(col("resourceType").alias("resource_type"),\
    col("name")[0].family.alias("family_name"),\
    array_join(col("name")[0].given, " ").alias("given_name"),\
    col("telecom")[1].value.alias("work_phone"),\
    col("telecom")[2].value.alias("mobile_phone"),\
    col("gender"),\
    col("active"),\
    col("id"),\
    col("birthDate"),\
    col("address")[0].city.alias("city"),\
    col("address")[0].district.alias("district"),\
    col("address")[0].state.alias("state"),\
    col("address")[0].line[0].alias("line"),\
    col("address")[0].postalCode.alias("postal_code"),\
    ).withColumn("birth_date", to_date(col("birthDate"), 'yyyy-MM-dd'))\
    .withColumn("ingestion_date", current_timestamp())\
    .drop(col("birthDate"))


# COMMAND ----------

# MAGIC %md
# MAGIC 8. Create new delta tabl (if not exists):
# MAGIC  - use patient schema defined above.
# MAGIC  - location - *silver_table_location* from *properties* file. 
# MAGIC  - table name - *silver_table_name* from *properties* file.
# MAGIC  - add new *update_date* column.

# COMMAND ----------



# COMMAND ----------

patient_delta_table = DeltaTable.createIfNotExists(spark).location(silver_patients_table_location)\
  .tableName(silver_patients_table_name) \
  .addColumns(df_converted_data.schema)\
  .addColumn("update_date", "TIMESTAMP")\
  .execute()

# COMMAND ----------

# MAGIC %md
# MAGIC 9. Merge existing patient data with received updates. Use 'id' to match records. If record is updated change the value of 'update_date' to current timestamp, otherwise leave it blank.

# COMMAND ----------

patient_delta_table.alias('patients') \
  .merge(
    df_converted_data.alias('updates'),
    "patients.id = updates.id AND patients.id='" + df_converted_data.first()["id"] + "'"
  ) \
  .whenMatchedUpdate(set =
    {
      "id": "updates.id",
      "active": "updates.active",
      "gender": "updates.gender",
      "resource_type": "updates.resource_type",
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
      "active": "updates.active",
      "gender": "updates.gender",
      "resource_type": "updates.resource_type",
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

# MAGIC %md
# MAGIC 10. Execute *select ** command using SQL syntax. Check if data is added.

# COMMAND ----------

# MAGIC %sql
# MAGIC select * from silver_patients

# COMMAND ----------

# MAGIC %md
# MAGIC 11. We need to pass id of the patient back to Data Factory pipeline. Return arrays of patient's ids that were modified. Use *dbutils.notebook.exit* method. The returned parameter should be array of ids converted to string.
# MAGIC > Hint: use json.dumps method

# COMMAND ----------

ids_df = df_converted_data.select(col("id")).collect()
ids_array = [i[0] for i in ids_df]

# COMMAND ----------

dbutils.notebook.exit(json.dumps(ids_array))
