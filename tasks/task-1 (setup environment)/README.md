# Task 1 - Infrastructure Setup
## Objective 
The goal of this task is to prepare Azure infrastrcructure to be able to complete following lessons.
## Prerequisites
 1. Azure personal account or [free trial](https://azure.microsoft.com/en-us/free) if available.
 2. [Terraform](https://www.terraform.io/) installed locally on your machine.
 3. [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed locally on your machine.
## Steps
 4. Navigate to */terraform/azure* folder and execute following command: `terraform install`. 
 5. In the same directory execute command: `terraform apply`. Print `yes` once requested.
 6. Installation might take some time, after completion you will have  core components being installed within your subscription. The picture below depicts main services to be installed.
![enter image description here](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/initial-infra-v1.png)
## Validation
 1. Go to your Azure Subscription and validate that following components were successfully deployed:
- Storage Account with *patient-data-source* folder inside
- Datalake storage with *bronze*, *silver* and *gold* folders inside.
- Azure Function that generates observation event. To check that events are being generated you might go to Event Hub and validate the *metrics/incoming messages*.
- Data Factory workspace with all required LinkedServices (storage account, datalake, key vault, databricks).
- Databricks workspace with default cluster being installed.  The cluster is of following shape:

> Single Node
> Standard_F4 shape
> 8 GB memory, 4 vCores
> 12.2.x-scala2.12 Runtime
> Automatic shutdown after 15 min inactivity
- Check if Databricks contains empty notebooks: CopyFromBronzeToSilver.py, CopyFromSilverToGold.py, StreamToSilver.py, StreamToGold.py, StreamToAnalytics.py.
