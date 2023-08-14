# Databricks notebook source
from pyspark.sql.types import StructType, StructField, IntegerType, StringType, DateType, BooleanType, ArrayType

identifier_schema =  ArrayType(
        StructType(fields=[
            StructField("system", StringType(), True), 
            StructField("value", StringType(), True)
            ]
        ))
coding_schema = StructType(fields = [
    StructField("coding", ArrayType(
        StructType(fields=[
            StructField("system", StringType(), True), 
            StructField("code", StringType(), True),
            StructField("display", StringType(), True)
            ]
        )
    ), True),
    StructField("text", StringType(), False)
])

value_quantity_schema = StructType(fields=[
            StructField("value", StringType(), True), 
            StructField("unit", StringType(), True),
            StructField("system", StringType(), True),
            StructField("code", StringType(), True)
            ]
        )


component_schema = ArrayType(
        StructType(fields=[
           StructField("code", coding_schema), 
           StructField("valueQuantity", value_quantity_schema),
           StructField("interpretation", coding_schema),
        ]
        ))

reference_schema = StructType(fields=[
            StructField("reference", StringType(), True)
            ]
        )

schema = StructType(fields=[
    StructField("status", StringType(), True),
    StructField("identifier", identifier_schema),
    StructField("category", coding_schema),
    StructField("code", coding_schema),
    StructField("subject", reference_schema),
    StructField("resourceType", StringType(), True),
    StructField("effectiveDateTime", StringType(), True),
    StructField("performer", reference_schema),
    StructField("component", component_schema)])
