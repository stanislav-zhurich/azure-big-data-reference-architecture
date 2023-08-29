# Task 5 - Batching: copy from Silver to Gold (consumption) layer.
> **Time to complete**: 2 hour
## Objective 
Tables in Gold layer represent data that has been transformed into knowledge, rather than just information. In our case we need to aggregate Patient and Observation data to provide valuable insights on patient conditions. For this task it's required to join both tables from Silver layer, find average blood pressure for the patient and store as new table in Gold layer.
![objective](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/task5-objective.png)
## Steps
1. Go to Azure Data Factory Studio.
2. Create new *CopyFromSilverToGold* Databricks Notebook activity.
- Select *copyFromSilverToGold.py* notebook as a source.
- Go to Settings->Base parameters and add following one:
> patient_id = @string(activity(**'name of the copy from bronze to silver activity'**).output.runOutput)
4. Connect with arrow previous activity with newly created using Data Factory UI.
5. Save and publish changes.
6. Go to Databricks cluster and open  _copyFromSilverToBronze.py_  notebook.
7.  Complete all steps defined in this notebook.
## Validation
> To validate the entire flow we need to have *readFromEventHub.py* notebook being run. It keeps listening to new event in Event Hub and need to be **manually stopped** after validatation, otherwise it will prevent cluster from autoscaling and might incur additional charges.

1. Make sure that Data Factory pipeline is published without errors.
2. Upload one of the patient sample files to  _sourcebigdata/patient-data-source/_  folder.
> Warning: for the sake of simplicity the solution is not optimized for processing of multiple files being placed simulteniosly to the souce folder. Although, it will work, most likely you'll come accross with *ConcurrentAppendException* within Notebook during merge operation. The reason we are not partitioning data in Bronze layer. Here is more [infomation](https://learn.microsoft.com/en-us/azure/databricks/optimizations/isolation-level) how to resolve such kind of issues.
3. Go to  _Data Factory/Monitor/Pipeline Runs_  and make sure that pipeline is completed successfuly.
4. Execute *select * from gold_patient_observation* statement from within Databricks notebook. Make sure new aggregative columns present in result.
![result](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/task5-result.png)
