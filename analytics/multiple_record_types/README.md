# Analytics: Topic with multiple record types

## Overview
In this folder we have an example of how to consume a topic - with many record types - from Databricks. Messages are encoded using AVRO and the Schema Registry. The Spark application - written in Scala - will use the library [AbsaOSS ABRiS](https://github.com/AbsaOSS/ABRiS) that provides a more complete integration with the Schema Registry than the library provided by Databricks. The consumer will read all the messages from a topic, parse them, and store them in different tables - one per record type.

## Topic used in this example
The example application will consume from the `customer-management.shared.renewals.v1`. This topic contains four different types of records:

- EsPolicyExpired
- EsPolicyGracePeriodExpired
- EsPolicyRenewalPeriodStarted
- EsRenewalOfferReadyToBePurchased

Each of these record types will be stored in its own dedicated table under the schema `kafka_playground.renewals`.

## How does it work
The application is a Spark streaming application that exploits the microbatch nature of Spark streams. For each microbatch:
1. Finds out how many different Schema ID are in the batch by parsing the Schema ID of each message; each unique Schema ID represents a different record type - or a different version of the same records type.
2. Groups messages by Schema ID.
3. For each group:
    1. Downloads the schema from the Schema Registry - using the Schema ID.
    2. Parses the payload using the schema.
    3. Appends all decoded messages to the output table.

## How to run it
In order to run this application you need a Databricks cluster that uses the 12.2 LTS or 13.2 LTS runtimes, and with the following Maven libraries installed:
- org.apache.kafka:kafka-clients:6.2.1-ccs
- za.co.absa:abris_2.12:6.3.0
You will need to add https://packages.confluent.io/maven/ as an additional Maven repo when adding these dependencies.

Once you have configured the cluster:
1. Import the notebook `consumer.scala` or `consumer.py` into your personal workspace.
2. Edit notebook to update secret scopes; change it to one that you can read and contain Kafka and Schema Registry credentials that can consume from the topic `customer-management.shared.renewals.v1`
3. (Optional) Change target catalogue and schema.
4. Press `Run all`.

## TODO
- [ ] Output table names in snake case
- [ ] Test if the example application handles schema evolution transparently
- [ ] Test performance
- [ ] Adapt this example to the car repair shop scenario described in the main [README.md](/README.md)
