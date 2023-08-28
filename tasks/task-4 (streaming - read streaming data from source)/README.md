
# Task 4 - Streaming: from Source to Silver.
## Objective 
The goal of the task is to continuosly read data from Azure Even Hub, transform it and store to Silver (refined) layer.
![objective](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/task4-objective.png)
## Steps
1. Go to database cluster and open *readFromEvenHub.py* notebook.
2. Complete all steps defined in this notebook.
## Validation
1. Check if data is successfully streamed from EventHub and stored in data lake.
![ADLS structure](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/task4-adls%20strcuture.png)
2. From within databricks notebook execute following command:
> select id, patient_id, systolic_pressure_value, diastolic_pressure_value from silver_observations
3. Verify if result resembles something like this
![result](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/task4-result.png)
 
## Cleanup
1. Do not forget to **stop the job manually**, as long as it's streaming one it will keep running without not being killed explicitly.
