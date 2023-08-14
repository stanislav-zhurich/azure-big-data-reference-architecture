
# Task 3 - Batching: copy from Bronze to Silver (refined) layer.
## Objective 
As soon as data is saved in landing zone, the next step is to perform basic data clean up and transformation. Data transformation will be done using Databricks notebook. As part of Data Factory pipeline we will invoke Databricks notebook passing the file name being stored in bronze layer. Notebook will be responsible for loading json data to dataframe, transformation and storing in Delta table.
![objective](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/task3-objective.png)
## Steps
1. Go to database cluster and open *copyFromBronzeToSilver.py* notebook.
2. Complete all steps defined in this notebook.
3. Go to Data Factory Workspace.
4. Create new Databricks Notebook Activity.
- Name: *CopyFromBronzeToSilver*
- Select */pipeline/CopyFromBronzeToSilver.py* as a notebook to be run.
5. Save and publish pipeline.
## Validation
1.  Upload one of the patient sample files to  _sourcebigdata/patient-data-source/_  folder.
2.  Go to  _Data Factory/Monitor/Pipeline Runs_  and make sure that pipeline is completed successfuly.
3.  Go to  _datalake/silver/patient_table_  folder and make that the structure resembles following one:
![enter image description here](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/task6-adls%20strcuture.png)
 
