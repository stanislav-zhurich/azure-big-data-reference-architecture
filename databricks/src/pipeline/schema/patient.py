# Databricks notebook source
from pyspark.sql.types import StructType, StructField, IntegerType, StringType, DateType, BooleanType, ArrayType

address_schema = ArrayType(StructType(fields=[StructField("city", StringType(), True), StructField("district", StringType(), False),
            StructField("postalCode", StringType(), False), StructField("state", StringType(), False), StructField("type", StringType(), False),
            StructField("use", StringType(), False), StructField("line", ArrayType(StringType()), True)]))

name_schema = ArrayType(
        StructType(fields=[
            StructField("use", StringType(), True), 
            StructField("family", StringType(), False),
            StructField("given", ArrayType(StringType()), True), 
            StructField("period", StructType(fields=[
                StructField ("start", StringType(), False),
                StructField("end", StringType(), False)]))
            ]
        ))
telecom_schema = ArrayType(
        StructType(fields=[
            StructField("use", StringType(), True), 
            StructField("value", StringType(), False),
            StructField("system", StringType(), False), 
            StructField("rank", IntegerType(), False), 
            StructField("period", StructType(fields=[
                StructField ("start", StringType(), False),
                StructField("end", StringType(), False)]))
            ]
        ))

schema = StructType(fields=[
    StructField("active", BooleanType(), False),
    StructField("gender", StringType(), False),
    StructField("id", StringType(), True),
    StructField("birthDate", StringType(), True),
    StructField("resourceType", StringType(), True),
    StructField("address", address_schema),
    StructField("name", name_schema),
    StructField("telecom", telecom_schema)])
