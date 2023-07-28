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
Reference project is built on top of  [lakehouse architecture](https://dbricks.co/38dVKYc) architecture pattern that addresses many of the challenges of traditional data architectures (data warehouse or data lake).
Lakehouse combines the low cost and flexibility of data lakes with the reliability and performance of data warehouses, it provides ETL and stream processing allong with ACID transactions. 

