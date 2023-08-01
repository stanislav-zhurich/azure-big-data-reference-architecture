
# Azure Big Data Reference Project
## Description
The project is a foundation of data pipelines platform and aims to provide practical experience for those who are keen on data engineering and especially those based on Azure managed services.
### Use Case
The case is taken from real project related to healthcare industry and represents nessesaty to ingest patient data into platform along with their health observations (blood pressure, blood glucose, etc.). Platform should be capable of storing, aggregating and providing holistic view on patient health conditions. Apart from that, it should react fast on any anomalies detected in patient's observations.
![Context View](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/c43101f25d78ad5529473d51bafed27528e564c6/images/context-view-v2.drawio.svg)

The following case assume data ingestion in following ways:
 - Initial patient data via files that periodically arrives from external sources.
 - Stream of observation data comes from external providers, presumable wearable devices.
 ### Requirements
 #### Patient Data Ingestion
 
 - Initial data files represents patient information in standard  form of electronic health records. The format is called [FHIR](https://www.hl7.org/fhir/).
 - Data files are in **json** format and represents a set of electronic records. Example of such file is [FHIRE Patient](https://build.fhir.org/patient-example.json.html).
 - Files are taken from data source system on a daily basis via **Batch Ingestion Layer**, stored, processed, aggregated within **Data Storage Layer** and exposed  to **Serving Layer**.
#### Observation Data Ingestion
- Observation data is central element in healthcare, used to support diagnosis, monitor progress and capture results of tests. Observation resources include laboratory data, clinical findings and assesments, quality tests and etc. For the sake of simplicity we will focus only on blood pressure vital sign that's represents by following schema [FHIR Blood Pressure](https://www.hl7.org/fhir/observation-example-bloodpressure.html).
- Observations are streamed into platform and consumed by **Streaming Ingestion Layer**.
- After that observation data is processed, optimized, aggregated and stored within **Data Storage Layer**.
- Observation data should be exposed via Serving Layer for reporting and lookup operations
- Observation data should be streamed and constantly monitored to understand if there are any anomalies in measurements.

## Architecture
As for architecture foundation we rely on  [Lakehouse architecture](https://dbricks.co/38dVKYc) concept that addresses many of the challenges applicable for traditional data architectures. With this approach there is no longer a strong separation between data lake and data warehouse, instead the outputs from the lake are served using the [Delta Lake format](https://docs.databricks.com/delta/index.html). When it comes to technical implementation the solution might leverage either [Microsoft Azure Synapse Analytics](https://learn.microsoft.com/en-us/azure/synapse-analytics/overview-what-is) (that is a powerfull platform that brings together support of multiple data related services available in Azure) or combination of [Azure Data Factory](https://learn.microsoft.com/en-us/azure/data-factory/introduction) and [Azure Databricks](https://learn.microsoft.com/en-us/azure/databricks/getting-started/). The last combination has been chosen over Synapse due to:

 - Synapse Sparl Pool currently doesn't support Spark Structured Streams on Deltalake that is required in our streaming scenario.
 - It's possible to use Free Trial Subscription with Databricks.

![Component View](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/component-view-v3.drawio.png)

 1. Patient data is ingested by **Data Factory Copy Activity** to landing zone (**Bronze**) once new file dropped in source folder. Observation data (avro format) is being streamed via **Event Hub** topic. 
 2. Observation events are consumed by **Databricks Stream Processing job** and stored into landing zone (**Bronze**) in raw format.
 3. **Databricks Spark Data Preparation Job** validate and transform raw data to canonical form and stores it in **Parquet** format to **Silver zone**. 
 4. **Databricks Spark Data Aggregation Job** aggregates data, makes it ready to be consumed by Serving Layer by storing on **Golder zone**. The format is transformed into **Delta**.
 5. **Databricks Spark Job** listens to changes in Delta table. 
 6. It processes structural stream and publish event to **Event hub**.
 7. . **Azure Stream Analytics** tool is used to read data from Event Hub and identify anomalies. All detected anomalies are sent to different Event Hub topic.
 8.  **Synapse Serverless SQL Pool** leverages external storage as a data source and expose data for consumption via SQL queries.
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

### Azure Data Fundamental
-   [Microsoft Azure Data Fundamentals: Explore data analytics in Azure](https://learn.microsoft.com/en-us/training/paths/azure-data-fundamentals-explore-core-data-concepts/)
-   [Microsoft Azure Data Fundamentals: Explore relational data in Azure](https://learn.microsoft.com/en-us/training/paths/azure-data-fundamentals-explore-relational-data/)
-   [Microsoft Azure Data Fundamentals: Explore non-relational data in Azure](https://learn.microsoft.com/en-us/training/paths/azure-data-fundamentals-explore-non-relational-data/)
### Azure Data Factory
- [Azure Data Factory](https://learn.microsoft.com/en-us/azure/data-factory/introduction)
- [Data Integration with Azure Data Factory](https://learn.epam.com/detailsPage?id=40e290c3-6739-4945-b92e-258025451fe5)
### Azure Databricks
- [Azure Databricks](https://learn.microsoft.com/en-us/azure/databricks/)
- [Azure Databricks Essentials](https://www.linkedin.com/learning/azure-spark-databricks-essential-training/optimize-data-pipelines?dApp=53239054&leis=LAA&u=2113185)
