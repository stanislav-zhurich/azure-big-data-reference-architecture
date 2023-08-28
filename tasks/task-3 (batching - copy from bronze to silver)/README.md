
# Task 3 - Batching: copy from Bronze to Silver (refined) layer.
> **Time to complete**: 3 hour
## Objective 
As soon as data is saved in bronze (landing) zone, the next step is to perform basic data clean up and transformation. Data transformation will be done using Databricks notebook. As part of Data Factory pipeline we will invoke Databricks notebook passing the file name being stored in bronze layer. Notebook will be responsible for loading json data to dataframe, transforming it and storing in Delta table.
![objective](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/task3-objective.png)
## Steps
1. Go to databricks cluster and open *copyFromBronzeToSilver.py* notebook under *Workspace/pipeline* folder.
> Databricks cluster endpoint might be found either in console after terraform scripts being installed or you might navigate via Azure Portal (your resource group -> datbricks-workspace-bigdata<id> -> overview -> launch workspace).
3. Complete all steps defined in this notebook.
4. Go to Data Factory Workspace.
5. Create new Databricks Notebook Activity.
- Name: *CopyFromBronzeToSilver*
- Select */pipeline/CopyFromBronzeToSilver.py* as a notebook to be run.
- Add *destination* parameter with value set to *@pipeline().parameters.destination*
5. Connect the very first *copy from source to bronze* activity and newly added using Data Factory UI.
5. Save and publish pipeline.
## Validation
1.  Upload one of the patient sample files to  _sourcebigdata/patient-data-source/_  folder.
   > Warning: for the sake of simplicity the solution is not optimized for processing of multiple files being placed simulteniosly to the souce folder. Although, it will work, moslt likely you'll come accross with *ConcurrentAppendException* within Notebook during merge operation. The reason we are not partitioning data in Bronze layer. Here is more [infomation](https://learn.microsoft.com/en-us/azure/databricks/optimizations/isolation-level) how to resolve such kind of issues.
3.  Go to  _Data Factory/Monitor/Pipeline Runs_  and make sure that pipeline is completed successfuly.
4.  Go to  _datalake/silver/patient_table_  folder and make that the structure resembles following one:
![enter image description here](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/task6-adls%20strcuture.png)
 
