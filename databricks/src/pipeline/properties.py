# Databricks notebook source
mount_prefix = "/mnt/datalake_mount/"
silver_patients_table_location = mount_prefix + "silver/patient_table"
gold_patient_observations_table_location = mount_prefix + "gold/patient_observation_table"
silver_patients_table_name = "silver_patients"
gold_patient_observations_table_name = "gold_patient_observations"
silver_observations_table_name = "silver_observations"
silver_observations_table_location = mount_prefix + "silver/observation_table"
