use std::time::Duration;

use clap::Parser;
use log::info;
use rdkafka::config::ClientConfig;
use rdkafka::message::{Header, OwnedHeaders, ToBytes};
use rdkafka::producer::future_producer::OwnedDeliveryResult;
use rdkafka::producer::{FutureProducer, FutureRecord};
use text_io::read;
use rust_rdkafka::setup_logger;
use rust_rdkafka::TheMessage;

const BROKERS: &str = "kafka";
const TOPIC: &str = "topic-test";

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(short, long, default_value = "true")]
    verbose: bool,

    #[arg(short, long, default_value = BROKERS)]
    brokers: String,

    #[arg(short, long, default_value = TOPIC)]
    topic: String,

    #[arg(short, long, default_value = "5")]
    number: usize,

    #[arg(short, long, default_value = "false")]
    interactive: bool,
}

#[tokio::main]
async fn main() {
    setup_logger(true, None);
    let args: Args = Args::parse();
    info!("Args: {:?}", args);

    if args.interactive {
        produce_interactive(&args.brokers, &args.topic).await;
    } else {
        produce_number(args.verbose, &args.brokers, &args.topic, args.number).await;
    }
}

pub async fn produce_number(verbose: bool, brokers: &str, topic: &str, number: usize) {
    if verbose {
        info!(
            "Creating producer {{ brokers: {}, topic: {}, num. of messages: {} }}",
            brokers, topic, number
        );
    }

    let producer: &FutureProducer = &create_producer(brokers);

    let futures = (0..number)
        .map(|i| async move {
            // The send operation on the topic returns a future, which will be
            // completed once the result or failure from Kafka is received.
            let delivery_status = deliver(
                &producer,
                topic,
                i.to_string(),
                &TheMessage::new(&format!("Message {}", i)),
            )
            .await;

            if verbose {
                info!("Delivery status for message {} received", i);
            }

            delivery_status
        })
        .collect::<Vec<_>>();

    // This loop will wait until all delivery statuses have been received.
    for future in futures {
        info!("Future completed. Result: {:?}", future.await);
    }
}

pub async fn produce_interactive(brokers: &str, topic: &str) {
    info!(
        "Creating interactive producer {{ brokers: {}, topic: {} }}",
        brokers, topic,
    );
    let producer: &FutureProducer = &create_producer(brokers);
    let mut key = 1;

    loop {
        print!("Please enter the message key: ");
        let custom_key_content: String = read!("{}\n");
        let custom_key: Option<String> = if custom_key_content == "" {
            None
        } else {
            Some(custom_key_content)
        };
        print!("Please enter the message content: ");
        let message_content: String = read!("{}\n");
        let delivery_status = deliver(
            &producer,
            topic,
            custom_key
                .as_deref()
                .map(ToString::to_string)
                .unwrap_or_else(|| format!("Generated Key {}", key.to_string())),
            &TheMessage::new(&message_content),
        )
        .await;
        if custom_key.is_none() {
            key += 1;
        }

        info!("message sent, delivery status: {:?}", delivery_status);
    }
}

pub async fn deliver(
    producer: &FutureProducer,
    topic_name: &str,
    key: String,
    message: impl ToBytes,
) -> OwnedDeliveryResult {
    producer
        .send(
            FutureRecord::to(topic_name)
                .payload(&message)
                .key(&key)
                .headers(OwnedHeaders::new().insert(Header {
                    key: "header_key",
                    value: Some("header_value"),
                })),
            Duration::from_secs(0),
        )
        .await
}

fn create_producer(brokers: &str) -> FutureProducer {
    ClientConfig::new()
        .set("bootstrap.servers", brokers)
        .set("message.timeout.ms", "5000")
        .create()
        .expect("Producer creation error")
}
