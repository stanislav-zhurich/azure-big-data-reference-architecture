

  
# Task 6 - Streaming. Write Observations to Event Hub.
## Objective 
In order to react fast on any abnormal patient's health metrics and conditions batching analytics is not enought. It's required to have an access to such event in real time. To achieve that, we wil be listening Delta table change data feeds and publish these changes to outbound event hub.
![context](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/task6-objective.png)
The goal of the task is to stream patient observation events stored in Delta table to Event Hub. Stream Analytics Job is capable of reading this data using SQL syntax, filter it and send to consumer. For the sake of simplicity and costs, we will send result right to the Stream Analytics console.

## Steps
1. Go to Databricks cluster and open *writeToOutboundEventHub.py* notebook.
2. Execute all steps listed within notebook.
3. Make sure that *readFromEventHub.py* notebook is running. This one is responsible for storing data in Delta table, change data feeds event from this table are to be consumed by new notebook.
4. Run *writeToOutboundEventHub.py* notebook.
## Validation

1. Make sure that notebook writes events to outbound event hub. Check the dashboard:
![dashboard](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/task6%20-%20outbbound%20eventhub.png)

