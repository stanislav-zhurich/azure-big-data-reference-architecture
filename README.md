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
As for architecture foundation we rely on  [Lakehouse architecture](https://dbricks.co/38dVKYc) concept that addresses many of the challenges applicable for traditional data architectures. With this approach there is no longer a strong separation between data lake and data warehouse, instead the outputs from the lake are served using the [Delta Lake format](https://docs.databricks.com/delta/index.html). When it comes to technical implementation the solution will leverage [Microsoft Azure Synapse Analytics](https://learn.microsoft.com/en-us/azure/synapse-analytics/overview-what-is) that is a powerfull platform that brings together support of multiple data related services available in Azure.
![Component View](https://raw.githubusercontent.com/stanislav-zhurich/azure-big-data-reference-architecture/main/images/component-view-v1.drawio.png)

 1. Patient data periodically is ingested by **Synapse Pipeline Copy Activity** to landing zone (**Bronze**). Observation data (avro format) is being streamed via **Event Hub**. 
 2. Events are consumed by **Synapse Spark Job** and stored into landing zone (**Bronze**).
 3. **Synapse Spark Data Preparation Job** validate and transform raw data to canonical form and stores it in **Delta** format to **Silver zone**. 
 4. **Synapse Spark Data Aggregation Job** aggregates data and makes it readt to be consumed by Serving Layer by storing on **Golder zone**.
 5. **Synapse Serverless SQL Pool** leverages external storage as a data source and expose data for consumption via SQL queries.
 6. Aggregated and processed data is also ingested into **Event Hub** to be consumed on runtime.
 7. **Azure Stream Analytics** tool is used to read data from Event Hub and identify any anomalies. All detected anomalies are sent to different Event Hub topic.
### Cost Consideration
|Service| Free tier |Pricing Options |Cost|
|--|--|--|--|
|Blob Storage|5 GB locally redundant storage (LRS) hot block with 20,000 read and 10,000 write operations||
|Data Factory|5 low-frequency activities||
|Key Vault|10,000 transactions RSA 2048-bit keys or secret operations, Standard tier||
|Virtual Network|50 virtual networks|||
|Event Hub||$0.015/hour per Throughput Unit (MB/s ingress and 2 MB/s egress)|
|Stream Analytics||$0.405 per hours||
|Synapse Spark Pool|120 free vCore-hours per month until November 30, 2023| $0.155 per vCore-hour|

