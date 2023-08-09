# Task 2 - Batching: copy from source to Bronze (landing) zone.
## Objective 
This is the first step in the batching process. The goal of the task is to copy data from external storage to our landing zone. The file is copied as is without any modifications. We will be using Azure Data Factory Copy Activity to copy the file.
## Steps
1. Navigate to Data Factory workspace, login to your git repo as soon as your are promted.
2. You need to import Linked Services to git repo. To acomplish it:
- Switch to *Live Mode*.
- Navigate to *Manage/Git Configuration*.
- Hit on *Import Resources* button.
- Switch back to Git mode and verify that you have Linked Services successfully imported.
3. Go to Author/Pipeline and create new pipeline in a way:
- Name: *PatientDataIngestion*
- Variables: *TriggerFileName (string)* and *Destination (string)*
- Parameters: 
	- *triggerFileName (string) = @trigger().outputs.body.fileName*
	- *destination (string) = @variables('Destination')*
4. Create new trigger. The trigger is required to initiate pipeline upon new file creation in patient source folder.
- Type: *storage event*
- Storage Account Name: *your storage account*
- Container Name:  *patient-data-source*
- One the parameters screen make sure that *triggerFileName* is set to *@trigger().outputs.body.fileName* 
5. Next we need to specify new destination for files being copied from source folder. The destination will comprise from dynamic part and original file name, e.g. */2023/08/08/patient-1.json*. Destination will be stored as Variable to be used across entire pipeline.
- From within *Activities* panel find *Set Variable* activity, drag and drop it to pipeline.
- Specify following settings:
  - Name: *SetDestinationVariable*
  - Within Settings create new pipeline variable with the name *Destination* and value 

> @concat('bronze/patient', '/', formatDateTime(utcnow(), 'yyyy'),
> '/',formatDateTime(utcnow(),'MM'),'/',formatDateTime(utcnow(),'dd'),
> '/', pipeline().parameters.triggerFileName)
6. To access source data we need to create pipeline dataset and connect it to the linked service.
- Go to Datasets and start creating new one.
- From available data stores select *Azure Blob Storage*.
- As a format select *json*.
- Select *blobSourceBlobStorageLinkedService* as a linked service.
- Configure file path in a such way:
> /patient-data-source/  /@dataset().file
- Set *Non* as import schema option.
- Go to Dataset parameters and create new one:
> file (String) = @variables('TriggerFileName')
7. Create another dataset to be able to access data lake bronze (landing) layer.
- Select *Azure Data Lake Storage Gen2* as a source.
- Select *json* as a format.
- Select *datalakeLinkedService* from available options for linked service.
- Configure file path in a such way:
> /datalake/  /@dataset().destination
- Set *Non* as import schema option.
- Go to Dataset parameters and create new one:
> destination(String) = @variables('Destination')
8. Add *Copy Activity* to pipeline.
9. Set it as a next step after Set Variable activity, that should be triggered on successful completion.
- As a *source* select DataSource created on step 6.
- As file path in dataset set 
> @pipeline().parameters.triggerFileName
- As a *sink* select DataSource created on step 7. 
10. Validate, save and publish pipeline.

## Validation
1. Upload one of the patient sample files to *sourcebigdata<id>/patient-data-source/* folder.
2. Go to *Data Factory/Monitor/Pipeline Runs* and make sure that pipeline is completed successfuly.
3. Go to *datalake/bronze/patient/yeat/month/day* folder and make sure that file is copied successfuly.
 
