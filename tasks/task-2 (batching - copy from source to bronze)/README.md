
# Task 2 - Batching: copy from source to Bronze (landing) zone.
## Objective 
This is the first step in the batching process. The goal of the task is to copy data from external storage to our landing zone. The file is copied as is without any modifications. We will be using Azure Data Factory Copy Activity to copy the file.
![objective](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/task2-objective.png)
## Steps
1. Navigate to Data Factory workspace, login to your git repo as soon as your are promted.
2. You need to import Linked Services to git repo. To acomplish it:
- Switch to *Live Mode*.
- Navigate to *Manage/Git Configuration*.
- Hit on *Import Resources* button.
- Switch back to Git mode and verify that you have Linked Services successfully imported.
3. Go to Author/Pipeline and create new pipeline in a way:
- Name: *PatientDataIngestion*
- Parameters with empty default values: 
	- *trigger_file_name (string)*
	- *file_destination (string)*
4. Create new trigger. The trigger is required to initiate pipeline upon new file creation in patient source folder.
- Type: *storage event*
- Storage Account Name: *your storage account*
- Container Name:  *patient-data-source*
- Parameter *trigger_file_name* is set to *@trigger().outputs.body.fileName*
- Parameter *file_destination* is set to *@concat('bronze/patient', '/', formatDateTime(utcnow(), 'yyyy'), '/',formatDateTime(utcnow(),'MM'),'/',formatDateTime(utcnow(),'dd'), '/', trigger().outputs.body.fileName)*
5. To access source data we need to create pipeline dataset and connect it to the linked service.
- Go to Datasets and start creating new one.
- From available data stores select *Azure Blob Storage*.
- As a format select *json*.
- Select *blobSourceBlobStorageLinkedService* as a linked service.
- Configure file path in a such way:
> /patient-data-source/  /@dataset().file
- Set *Non* as import schema option.
- Go to Dataset parameters and create new one with empty default value:
> file (String)
6. Create another dataset to be able to access data lake bronze (landing) layer.
- Select *Azure Data Lake Storage Gen2* as a source.
- Select *json* as a format.
- Select *datalakeLinkedService* from available options for linked service.
- Configure file path in a such way:
> /datalake/  /@dataset().destination
- Set *Non* as import schema option.
- Go to Dataset parameters and create new one with empty value:
> file_destination(String) 
7. Add *Copy Activity* to pipeline.
- As a *source* select DataSource created on step 6.
- As a *file* data set property set following value:
> @pipeline().parameters.trigger_file_name
- As a *sink* select DataSource created on step 7. 
- As a *destination* data set property set following value:
> @pipeline().parameters.file_destination
8. Click on validate, save and publish pipeline.

## Validation
1. Upload one of the patient sample files to *sourcebigdata<id>/patient-data-source/* folder.
2. Go to *Data Factory/Monitor/Pipeline Runs* and make sure that pipeline is completed successfuly.
3. Go to *datalake/bronze/patient/yeat/month/day* folder and make sure that file is copied successfuly.
