# Databricks notebook source
# DBTITLE 1,Topic configuration
topic = "customer-management.shared.renewals.v1"

# COMMAND ----------

# DBTITLE 1,Kafka configuration
kafka_username = dbutils.secrets.get("uk_databricks_consumer.staging", "kafka_user")
kafka_password = dbutils.secrets.get("uk_databricks_consumer.staging", "kafka_password")

kafka_config = {
    "kafka.bootstrap.servers": "pkc-e8mp5.eu-west-1.aws.confluent.cloud:9092",
    "kafka.security.protocol": "SASL_SSL",
    "kafka.sasl.mechanism": "PLAIN",
    "kafka.sasl.jaas.config": f"kafkashaded.org.apache.kafka.common.security.scram.ScramLoginModule required username='{kafka_username}' password='{kafka_password}';",
}

# COMMAND ----------

# DBTITLE 1,Schema registry configuration
schema_registry_username = dbutils.secrets.get(
    "uk_databricks_consumer.staging", "schema_registry_username"
)
schema_registry_password = dbutils.secrets.get(
    "uk_databricks_consumer.staging", "schema_registry_password"
)

schema_registry_config = {
    "schema.registry.url": "https://psrc-95km5.eu-central-1.aws.confluent.cloud",
    "schema.registry.basic.auth.credentials.source": "USER_INFO",
    "schema.registry.basic.auth.user.info": f"{schema_registry_username}:{schema_registry_password}",
}

# COMMAND ----------

# DBTITLE 1,Ingest from Kafka
dataframe = (
    spark.readStream.format("kafka")
    .option("subscribe", topic)
    .option("startingOffsets", "earliest")
    .options(**kafka_config)
    .load()
)

# COMMAND ----------

# DBTITLE 1,ABRiS Python Interface
from pyspark.sql.column import Column, _to_java_column
from pyspark.sql.utils import get_active_spark_context
from py4j.java_gateway import JVMView
from typing import Dict


def create_schema_manager(config: Dict[str, str]):
    spark_context = get_active_spark_context()
    jvm_gateway = cast(JVMView, spark_context._jvm)
    scala_config = jvm_gateway.PythonUtils.toScalaMap(config)

    return jvm_gateway.za.co.absa.abris.avro.read.confluent.SchemaManagerFactory.create(
        scala_config
    )


def from_avro(col, schema: str) -> Column:
    spark_context = get_active_spark_context()
    jvm_gateway = cast(JVMView, spark_context._jvm)

    return Column(
        jvm_gateway.za.co.absa.abris.avro.functions.from_avro(
            _to_java_column(col), schema
        )
    )

# COMMAND ----------

# DBTITLE 1,Helper functions
import pandas as pd
from pyspark.sql.functions import *
from pyspark.sql.types import IntegerType


@pandas_udf(IntegerType())
def binary_to_int(input: pd.Series) -> pd.Series:
    return input.map(lambda it: int.from_bytes(it, byteorder="big"))


spark.udf.register("binary_to_int", binary_to_int)

schema_manager = create_schema_manager(schema_registry_config)


def upsertBatch(batchDF, batchId):
    schemaid_and_data = batchDF.select(
        expr("binary_to_int(substring(value, 2, 4))").alias("schema_id"),
        expr("substring(value, 6, length(value)-5)").alias("data"),
        struct(col("topic"), col("partition"), col("offset"), col("timestamp")).alias(
            "kafka"
        ),
    )

    for row in schemaid_and_data.select(col("schema_id")).distinct().collect():
        schema_id = row.schema_id
        schema = schema_manager.getSchemaById(schema_id)
        batch_for_id = schemaid_and_data.filter(col("schema_id") == lit(schema_id))
        batch_only_data = batch_for_id.select(
            from_avro(col("data"), schema.toString()).alias("data"), col("kafka")
        ).select(col("data.*"), col("kafka"))
        batch_only_data.write.format("delta").mode("append").option(
            "mergeSchema", "true"
        ).saveAsTable(f"kafka_playground.renewals.{schema.getName()}")

# COMMAND ----------

dataframe.writeStream.foreachBatch(upsertBatch).start().awaitTermination()
