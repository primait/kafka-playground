// Databricks notebook source
// DBTITLE 1,Topic configuration
val topic = "customer-management.shared.renewals.v1"

// COMMAND ----------

// DBTITLE 1,Kafka configuration
val kafkaUsername = dbutils.secrets.get("uk_databricks_consumer.staging", "kafka_user")
val kafkaPassword = dbutils.secrets.get("uk_databricks_consumer.staging", "kafka_password")

val kafkaConfig = Map(
    "kafka.bootstrap.servers" -> "pkc-e8mp5.eu-west-1.aws.confluent.cloud:9092",
    "kafka.security.protocol" -> "SASL_SSL",
    "kafka.sasl.mechanism" -> "PLAIN",
    "kafka.sasl.jaas.config" -> s"kafkashaded.org.apache.kafka.common.security.scram.ScramLoginModule required username='$kafkaUsername' password='$kafkaPassword';"
)

// COMMAND ----------

// DBTITLE 1,Schema registry configuration
val schemaRegistryUsername= dbutils.secrets.get("uk_databricks_consumer.staging", "schema_registry_username")
val schemaRegistryPassword = dbutils.secrets.get("uk_databricks_consumer.staging", "schema_registry_password")

val schemaRegistryConfig = Map(
  "schema.registry.url" -> "https://psrc-95km5.eu-central-1.aws.confluent.cloud",
  "schema.registry.basic.auth.credentials.source" -> "USER_INFO",
  "schema.registry.basic.auth.user.info" -> s"$schemaRegistryUsername:$schemaRegistryPassword",
)

// COMMAND ----------

// DBTITLE 1,Ingest from Kafka
val dataframe = spark
  .readStream
  .format("kafka")
  .option("subscribe", topic)
  .option("startingOffsets", "earliest")
  .options(kafkaConfig)
  .load()

// COMMAND ----------

// DBTITLE 1,Helper functions
import java.nio.ByteBuffer
import io.delta.tables.DeltaTable
import org.apache.spark.sql._
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types.DataTypes
import za.co.absa.abris.avro.functions.from_avro
import za.co.absa.abris.avro.read.confluent.SchemaManagerFactory

spark.udf.register("binary_to_int", (input: Array[Byte]) => ByteBuffer.wrap(input).getInt)

val schemaManager = SchemaManagerFactory.create(schemaRegistryConfig)

def processBatch(batchDF: DataFrame, batchId: Long): Unit = {
  val schemaIDAndData = batchDF
    .select(
      expr("binary_to_int(substring(value, 2, 4))") as 'schema_id,
      expr("substring(value, 6, length(value)-5)") as 'data,
      struct(col("topic"), col("partition"), col("offset"), col("timestamp")) as 'kafka
    )

  schemaIDAndData.select(col("schema_id")).distinct().collect().foreach { row =>
    val schemaID = row.getInt(0)
    val schema = schemaManager.getSchemaById(schemaID)
    val batchForID = schemaIDAndData.filter(col("schema_id") === lit(schemaID))
    val batchOnlyData = batchForID
      .select(from_avro(col("data"), schema.toString) as 'data, col("kafka"))
      .select(col("data.*"), col("kafka"))

    batchOnlyData
      .write
      .format("delta")
      .mode("append")
      .option("mergeSchema", "true")
      .saveAsTable(f"kafka_playground.renewals.${schema.getName}")
  }
}

// COMMAND ----------

dataframe
  .writeStream
  .foreachBatch(processBatch _)
  .start()
  .awaitTermination()
