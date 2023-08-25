# Databricks notebook source
# MAGIC %md
# MAGIC 1. Import required libraries


# MAGIC %md
# MAGIC 2. List all available mounts, make sure that */mnt/datalake_mount* is availble and points to your datalake storage.


# MAGIC %md
# MAGIC 3. Import *properties.py* file using magic command. The file contains usefull constants you might find handy for your code.
# MAGIC > Hint: use *%run* magic command 


# MAGIC %md
# MAGIC 4. Read *file_destination*  parameter passed from within Data Factory pipeline. 
# MAGIC > Hint: use *dbutils.widgets.get* method.


# MAGIC %md
# MAGIC 5. Import patient schema '../pipeline/schema/patient.py'.

# MAGIC %md
# MAGIC 6. Read json data from bronze layer. As a path use parameter read from Data Factory prefixed with moint endpoint.


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

# MAGIC %md
# MAGIC 8. Create new delta tabl (if not exists):
# MAGIC  - use patient schema defined above.
# MAGIC  - location - *silver_table_location* from *properties* file. 
# MAGIC  - table name - *silver_table_name* from *properties* file.
# MAGIC  - add new *update_date* column.

# MAGIC %md
# MAGIC 9. Merge existing patient data with received updates. Use 'id' to match records. If record is updated change the value of 'update_date' to current timestamp, otherwise leave it blank.


# MAGIC %md
# MAGIC 10. Execute *select ** command using SQL syntax. Check if data is added.


# MAGIC %md
# MAGIC 11. We need to pass id of the patient back to Data Factory pipeline. Return arrays of patient's ids that were modified. Use *dbutils.notebook.exit* method. The returned parameter should be array of ids converted to string.
# MAGIC > Hint: use json.dumps method

