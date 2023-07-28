# Azure Big Data Reference Project
## Description
The project is a foundation of data pipelines implementation and aims to provide practical experience for those who are keen on data engineering and especially those based on Azure managed services.
### Use Case
The case is taken from real project related to healthcare industry and represents nessesaty to ingest patient data into platform. 
![Context View](https://github.com/stanislav-zhurich/azure-big-data-reference-architecture/blob/e01273c765d560e18369fddae56a33fe8cffe1d3/images/context-view-v1.png?raw=true)
Data might be ingested in two ways:
 - Initial patient data via files that periodically arrives from insurance companies.
 - Stream of changes originated from consumtion layer. Usually these changes are made by patients themselfs, e.g. adding new address.
 ### Requirements
 #### Batching Ingestion
 
 - Initial data files represents patient information in standard  form of electronic health records. The format is called [FHIR](https://www.hl7.org/fhir/).
 - Inital data files are in **json** format and represents a set of electronic records.
 - Files are taken from data source system on a daily basis, stored, processed and ingested to consumption layer.
#### Streaming Ingestion
- Being initially ingested to the system, patient data is mutable and can be modified by patients themselfs.
- Being adjusted data feed is sent back to the pipeline as a stream event.
- The event is stored in platform, merged to patient profile and becomes available for consumtion.

## Architecture

