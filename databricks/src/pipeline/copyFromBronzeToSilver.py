# Databricks notebook source
# MAGIC %md
# MAGIC 1. Import required libraries

# COMMAND ----------

from pyspark.sql.functions import to_timestamp, concat, col, lit, to_date, current_timestamp, array_join
from delta.tables import *
import json

# COMMAND ----------

# MAGIC %md
# MAGIC 2. Import *properties.py* file.
# MAGIC > Hint: use *%run* magic command 

# COMMAND ----------

# MAGIC %run "../pipeline/properties.py"

# COMMAND ----------

# MAGIC %md
# MAGIC 2. Read *file_destination*  parameter passed from within Data Factory pipeline. 
# MAGIC > Hint: use *dbutils.widgets.get* method.

# COMMAND ----------

dbutils.widgets.text("file_destination", "")
file_destination = dbutils.widgets.get("file_destination")
absolute_path = "/mnt/datalake_mount/" + file_destination;

# COMMAND ----------

# MAGIC %md
# MAGIC 3. Import patient schema '../pipeline/schema/patient.py' using magic command

# COMMAND ----------

# MAGIC %run "../pipeline/schema/patient.py"

# COMMAND ----------

# MAGIC %md
# MAGIC 4. Read json data from bronze layer. As a path use 'absolute_path' variable defined above.

# COMMAND ----------

df = spark.read.schema(schema).option("recursiveFileLookup","true").json(absolute_path, multiLine=True)
df = df.dropDuplicates(subset = ['id'])

# COMMAND ----------

# MAGIC %md
# MAGIC 5. Select following columns and apply transformations for dataframe:
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
# MAGIC 6. Create new table delta "silver_patients" table (if not exists) using patient schema defined below and following location '/mnt/datalake_mount/silver/patient_table'. Also add new 'update_date' column.

# COMMAND ----------



# COMMAND ----------

silver_table_location = 

patient_delta_table = DeltaTable.createIfNotExists(spark).location("/mnt/datalake_mount/silver/patient_table")\
  .tableName("silver_patients") \
  .addColumns(df_converted_data.schema)\
  .addColumn("update_date", "TIMESTAMP")\
  .execute()

# COMMAND ----------

# MAGIC %md
# MAGIC 7. Merge existing patient data with received updates. Use 'id' to match records. If record is updated change the value of 'update_date' to current timestamp, otherwise leave it blank.

# COMMAND ----------

# MAGIC %md
# MAGIC df_converted_date.write.mode("overwrite").format("delta").option("path", "/path/to/external/table").saveAsTable("silver_patients")

# COMMAND ----------

df_converted_data.first()["id"]

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
# MAGIC 8. Execute 'select all' command using SQL syntax.

# COMMAND ----------

# MAGIC %sql
# MAGIC select * from silver_patients

# COMMAND ----------

# MAGIC %md
# MAGIC 9. Return arrays of patient's ids that were modified. Use *dbutils.notebook.exit* method.

# COMMAND ----------

ids_df = df_converted_data.select(col("id")).collect()
ids_array = [i[0] for i in ids_df]

# COMMAND ----------

dbutils.notebook.exit(json.dumps(ids_array))
