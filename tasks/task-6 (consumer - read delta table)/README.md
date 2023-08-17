
  
# Task 6 - Consumption. Read Gold Data.
## Objective 
As soons as data ends up in Gold layer it's ready to power analytics, machine learning and production application. It contains not just information but also knowledge. Lakehouse architecture allows to query data directly from Delta lake, however sometimes it might not provide desired performance. In this case data is ingested to warehouse platform and fetched from that layer. For our reference architecture we will rely on Azure Synapse Serverless SQL Pool.
> Serverless SQL Pool is used as the cheapest and simple option for our case. However for better and predictable performance it's recommended to go with Dedicated SQL Pool.
 
![objective](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/task6-objective.png)

## Steps
1. Go to Azure Portal and navigate to Azure Synapse Analytics.
2. From within workspace go to Synapse Studio.
3. Go to *Data -> Linked*.
4. Select *datalake->gold->patient_observation_table* folder.
5. Select *New SQL Script -> Select TOP 100 rows*.
6. Select *Delta* format as *file type*.
7. Run the query
## Validation

1. Make sure you've got result similar to this:
![result](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/task6-result.png)

