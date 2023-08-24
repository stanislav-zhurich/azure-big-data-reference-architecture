
# Azure Big Data Reference Project
## Description
The project serves as a reference architecture for lakehouse big data platform and aims to provide practical experience for those who are keen on data engineering and especially those based on Azure managed services.
### Use Case
The case is taken from real project, relates to healthcare industry and represents nessesaty to ingest patient data into platform along with their health observations (blood pressure, blood glucose, etc.). Platform should be capable of storing, aggregating and providing holistic view on patient health conditions. Apart from that, it should react fast on any anomalies detected in patient's observations.
![Context View](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/context-view-v2.png)

The following case assume that data is ingested in following pathes:
 - Initial patient data is to be sent via JSON files from external sources file storage.
 - Stream of observation metrics that comes from external providers, presumable wearable devices.
 ### Requirements
 #### Patient Data Ingestion
 
 - Initial data files represents patient information in standard  form of electronic health records. The format is called [FHIR](https://www.hl7.org/fhir/).
 - Data files are in *json* format and represents a set of electronic records. Example of such file is [FHIRE Patient](https://build.fhir.org/patient-example.json.html).
 - Sample files to be used for the tasks are already added to [samples directory](https://github.com/stanislav-zhurich/azure-big-data-reference-architecture/tree/main/samples)
 - Files are to be received via **Batch Ingestion Layer**, validated, processed and aggregated within **Data Storage Layer**. Clean and valuable information is exposed to customer from within **Serving Layer**.
#### Observation Data Ingestion
- Observation data is central element in healthcare, used to support diagnosis, monitor progress and capture results of tests. Observation resources include laboratory data, clinical findings and assesments, quality tests and etc. For the sake of simplicity we will focus only on blood pressure vital sign that's represents by following schema [FHIR Blood Pressure](https://www.hl7.org/fhir/observation-example-bloodpressure.html).
- Observations are streamed into platform and consumed by **Streaming Ingestion Layer**.
- After that observation data is processed, optimized, aggregated and stored within **Data Storage Layer**.
- Observation data should be exposed via Serving Layer for reporting and lookup operations.
- Observation data should be streamed and constantly monitored to understand if there are any anomalies in measurements.

## Architecture
As for architecture foundation we rely on  [Lakehouse architecture](https://dbricks.co/38dVKYc) concept that addresses many of the challenges applicable for traditional data architectures. With this approach there is no longer a strong separation between data lake and data warehouse, instead the outputs from the lake are served using the [Delta Lake format](https://docs.databricks.com/delta/index.html). When it comes to technical implementation the solution might leverage either [Microsoft Azure Synapse Analytics](https://learn.microsoft.com/en-us/azure/synapse-analytics/overview-what-is) (that is a powerfull platform that brings together support of multiple data related services available in Azure) or combination of [Azure Data Factory](https://learn.microsoft.com/en-us/azure/data-factory/introduction) and [Azure Databricks](https://learn.microsoft.com/en-us/azure/databricks/getting-started/). The last combination has been chosen over Synapse due to:

 - Synapse Sparl Pool currently doesn't support Spark Structured Streams on Deltalake that is required in our streaming scenario.
 - Less charges due to more flexibility in compute resources .
 Down below you can find high level component architecture that depicts the main part of the platform along with mapping to the tasks to be acomplished.

![Component View](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/component-view-v3.drawio.png)

 1. The very [first task](https://github.com/stanislav-zhurich/azure-big-data-reference-architecture/tree/main/tasks/task-1%20%28setup%20environment%29) is to prepare environment to build the solution on top. Provided terraform scrips along with materials will deploy the core part of the platform.
 2. [The second task](https://github.com/stanislav-zhurich/azure-big-data-reference-architecture/tree/main/tasks/task-2%20%28batching%20-%20copy%20from%20source%20to%20bronze%29) implies creation of Azure Data Factory activity to copy data from external Blob Storage to platform Bronze storage layer (landing zone).
 3. After data is being stored in our landing zone it must be refined and transformed to delta table. That is the scope of [the third task](https://github.com/stanislav-zhurich/azure-big-data-reference-architecture/tree/main/tasks/task-3%20%28batching%20-%20copy%20from%20bronze%20to%20silver%29).
 4.  [The fourth task](https://github.com/stanislav-zhurich/azure-big-data-reference-architecture/tree/main/tasks/task-4%20%28streaming%20-%20read%20streaming%20data%20from%20source%29) relates to ingestion of streaming observation event to the platform. Events are to be generated by provisioned Azure Function and sent to Event Hub. The goal is to store observation in delta table.
 5. [The fifth task](https://github.com/stanislav-zhurich/azure-big-data-reference-architecture/tree/main/tasks/task-5%20%28batching%20-%20copy%20from%20silver%20to%20gold%29) requires you to prepare data to be read by business consumer from Gold layer. 
 6. In the following [sixth task](https://github.com/stanislav-zhurich/azure-big-data-reference-architecture/tree/main/tasks/task-6%20%28streaming%20-%20write%20to%20event%20hub%29) you'll be asked to implement streaming observation data from from delta table to outbound Event Hub.
 7. The goal of [the seventh task](https://github.com/stanislav-zhurich/azure-big-data-reference-architecture/tree/main/tasks/task-7%20%28consumption%20-%20read%20observation%20data%29) is to implement solution to be able to analyze patient's observation data on runtime.
 8. And finally, within [the eighth task](https://github.com/stanislav-zhurich/azure-big-data-reference-architecture/tree/main/tasks/task-8%20%28consumtion%20-%20read%20patient%20data%29) you need to integrate Synapse Serverless SQL Pool with delta tables from Gold layer.
### Cost Consideration
#### Assumptions:
- It is recommended to use [Azure Free Trial account](https://azure.microsoft.com/en-us/free) that has $200 credit. 
- Average time spent on home task completion is around **20 hours**.
- Region of runnting environment is West Europe. All required services are availble there.

|Service| Free tier |Pricing Options |Cost|
|--|--|--|--|
|Blob Storage|5 GB locally redundant storage (LRS) hot block with 20,000 read and 10,000 write operations||$0.01|
|Data Factory|5 low-frequency activities|$0.001/per run, $0.25/diu per hour|~$2-$3
|Key Vault|10,000 transactions RSA 2048-bit keys or secret operations, Standard tier|$0.03 per 10k operations|$0.01|
|Event Hub||$0.015/hour per Throughput Unit (MB/s ingress and 2 MB/s egress)|$1|
|Stream Analytics||$0.110 per hour/unit| ~$2|
|Databricks|15 day of trial period| All-Purpose Compute Cluster, F4_Standard  Instance (4 vCPU, 8 GiB)| ~$9

Oveall costs are expected to be around **$15**. They can be cut applying Free Trail subscription. 
## Materials
### Reference Architecture
 - [Azure Synapse Analitics. End-to-And](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/dataplate2e/data-platform-end-to-end?tabs=portal)
 - [Stream Processing with Databricks](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/data/stream-processing-databricks)
 - [Stream Processing with Azure Stream Analytics](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/data/stream-processing-stream-analytics)
 - [Building ETL and Data Pipeline](https://videoportal.epam.com/video/kaEOA2Je)
### Azure Data Fundamental
-  [Azure Data Architecture Guide](https://learn.microsoft.com/en-us/azure/architecture/data-guide/)
-  [Microsoft Azure Data Fundamentals: Explore data analytics in Azure](https://learn.microsoft.com/en-us/training/paths/azure-data-fundamentals-explore-core-data-concepts/)
-   [Microsoft Azure Data Fundamentals: Explore relational data in Azure](https://learn.microsoft.com/en-us/training/paths/azure-data-fundamentals-explore-relational-data/)
-   [Microsoft Azure Data Fundamentals: Explore non-relational data in Azure](https://learn.microsoft.com/en-us/training/paths/azure-data-fundamentals-explore-non-relational-data/)
### Azure Data Factory
- [Azure Data Factory](https://learn.microsoft.com/en-us/azure/data-factory/introduction)
- [Data Integration with Azure Data Factory](https://learn.epam.com/detailsPage?id=40e290c3-6739-4945-b92e-258025451fe5)
### Azure Databricks
- [Azure Databricks](https://learn.microsoft.com/en-us/azure/databricks/)
- [Azure Databricks Essentials](https://www.linkedin.com/learning/azure-spark-databricks-essential-training/optimize-data-pipelines?dApp=53239054&leis=LAA&u=2113185)
### Azure Stream Analytics
- [Azure Stream Analytics](https://learn.microsoft.com/en-us/azure/stream-analytics/)
### Other Programs
- [Azure Data Integration Mentoring Program](https://learn.epam.com/detailsPage?id=9ada9581-85ef-41a4-be42-340452be3e93)
