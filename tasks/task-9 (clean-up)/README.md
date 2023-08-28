# Task 9 - Clean up resources.
## Objective 
After all task are completed we need to purge all resources created in scope of these exercises.

## Steps
1. Go to Azure Portal and navigate to Azure Synapse Analytics.
2. From within workspace go to Synapse Studio.
3. Go to *Data -> Linked*.
4. Select *datalake->gold->patient_observation_table* folder.
5. Select *New SQL Script -> Select TOP 100 rows*.
6. Select *Delta* format as *file type*.
7. Run the query
## Validation
