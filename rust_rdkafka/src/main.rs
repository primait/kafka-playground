use clap::Parser;
use log::{info, warn};

use rdkafka::config::RDKafkaLogLevel;
use rdkafka::consumer::{Consumer, StreamConsumer};
use rdkafka::producer::{FutureRecord, Producer};
use rdkafka::Offset::Offset;
use rdkafka::{ClientConfig, Message, TopicPartitionList};
use rust_rdkafka::{create_producer, setup_opentelemetry};
use std::collections::HashMap;
use std::env;
use std::time::Duration;
use tracing::info_span;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(short, long)]
    source: Option<String>,

    #[arg(short, long)]
    destination: Option<String>,
}

#[tokio::main]
async fn main() {
    let _guard = setup_opentelemetry();
    let _span = info_span!("MySpan");
    let args: Args = Args::parse();

    let source = args.source.unwrap_or_else(|| env::var("SOURCE").unwrap());
    let destination = args
        .destination
        .unwrap_or_else(|| env::var("DESTINATION").unwrap());

    info!("Source {:?}, Destination {:?}", source, destination);

    let consumer: StreamConsumer = ClientConfig::new()
        .set("group.id", "rust_rdkafka")
        .set("bootstrap.servers", "kafka")
        .set("session.timeout.ms", "6000")
        .set("enable.auto.commit", "false")
        .set_log_level(RDKafkaLogLevel::Debug)
        .set("auto.offset.reset", "earliest")
        .create()
        .expect("Consumer creation failed");

    let producer = &create_producer(true);
    producer
        .init_transactions(Duration::from_secs(1))
        .expect("init transaction error");

    consumer
        .subscribe(&[&source])
        .expect("Can't subscribe to specified topics");

    loop {
        match consumer.recv().await {
            Ok(m) => {
                let payload: &str =
                    m.payload_view::<str>()
                        .unwrap_or(Ok("--"))
                        .unwrap_or_else(|e| {
                            warn!("Error while deserializing message payload: {:?}", e);
                            ""
                        });

                info!("Message received {}", payload);

                producer
                    .begin_transaction()
                    .expect("unable to start transaction");

                let _ = producer
                    .send(
                        FutureRecord::to(&destination).key("").payload(payload),
                        Duration::from_secs(0),
                    )
                    .await;

                producer
                    .send_offsets_to_transaction(
                        &TopicPartitionList::from_topic_map(&HashMap::from([(
                            (source.to_string(), m.partition()),
                            Offset(m.offset() + 1),
                        )]))
                        .expect("topic partition list error"),
                        &consumer.group_metadata().expect("group_metadata is None"),
                        Duration::from_secs(1),
                    )
                    .expect("send_offsets_to_transaction error");

                producer
                    .commit_transaction(Duration::from_secs(1))
                    .expect("commit_transaction error");
            }
            Err(e) => warn!("Kafka error: {}", e),
        }
        //tokio::time::sleep(Duration::from_millis(100)).await;
    }
}
