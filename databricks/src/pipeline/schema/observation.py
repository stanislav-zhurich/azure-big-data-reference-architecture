# Databricks notebook source
from pyspark.sql.types import StructType, StructField, StringType, ArrayType

identifier_schema =  ArrayType(
        StructType(fields=[
            StructField("system", StringType(), False), 
            StructField("value", StringType(), False)
            ]
        ))
coding_schema = StructType(fields = [
    StructField("coding", ArrayType(
        StructType(fields=[
            StructField("system", StringType(), False), 
            StructField("code", StringType(), False),
            StructField("display", StringType(), False)
            ]
        )
    ), False),
    StructField("text", StringType(), False)
])

value_quantity_schema = StructType(fields=[
            StructField("value", StringType(), False), 
            StructField("unit", StringType(), False),
            StructField("system", StringType(), False),
            StructField("code", StringType(), False)
            ]
        )


component_schema = ArrayType(
        StructType(fields=[
           StructField("code", coding_schema), 
           StructField("valueQuantity", value_quantity_schema),
           StructField("interpretation", ArrayType(coding_schema)),
        ]
        ))

reference_schema = StructType(fields=[
            StructField("reference", StringType(), False)
            ]
        )

schema = StructType(fields=[
    StructField("status", StringType(), False),
    StructField("identifier", identifier_schema, False),
    StructField("category", ArrayType(coding_schema), False),
    StructField("code", coding_schema, False),
    StructField("subject", reference_schema, False),
    StructField("resourceType", StringType(), False),
    StructField("effectiveDateTime", StringType(), False),
    StructField("performer", ArrayType(reference_schema), False),
    StructField("component", component_schema)])
