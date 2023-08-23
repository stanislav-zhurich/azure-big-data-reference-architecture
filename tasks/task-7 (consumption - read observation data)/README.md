

  
# Task 7 - Consumtion Observation Data from Stream Analytics.
## Objective 
Azure Stream Analytics is a serverless scalable event processing engine that helps to analyze real time observation data published to Event Hub. It can easely be integrated with multiple source and sink services. For the sake of simplicity and cost decreasing we will be writing data directly to Stream Analytics console. 
![context](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/task6-objective.png)

## Steps
1. Go to Azure Stream Analytics Jobs via portal and navigate to one created for the course.
2. Go to *Inputs* and add new Event Hub input. Use following settings while creating the input:
- alias: *input-event-hub*
- event hub name: *target-even-hub*
- authentication mode: *system assigned managed identity*
3. Go to *Query* and compose following SQL query:
- use just created event hub input for data source
- select events for recent 5 minutes
- filter events and leave only those with *critical* and *abnormal* interpretation
## Validation
1. Make sure you are successfully connected to target-event-hub and able to see data samples.
2. Query is successfully executed and returns *critical* and *abnormal* data for recent 5 minutes.

