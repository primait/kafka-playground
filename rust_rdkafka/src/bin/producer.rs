use std::fmt::Debug;
use std::time::Duration;

use clap::Parser;
use opentelemetry::propagation::Injector;
use opentelemetry::trace::{Span, TraceContextExt, Tracer};
use opentelemetry::{global, Context, KeyValue};
use rdkafka::message::{Header, Headers, OwnedHeaders, ToBytes};
use rdkafka::producer::future_producer::OwnedDeliveryResult;
use rdkafka::producer::{FutureProducer, FutureRecord};
use rust_rdkafka::TheMessage;
use rust_rdkafka::{create_producer, setup_opentelemetry};
use text_io::read;
use tracing::info;

const TOPIC: &str = "topic-test";
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(short, long, default_value = "true")]
    verbose: bool,

    #[arg(short, long, default_value = TOPIC)]
    topic: String,

    #[arg(short, long, default_value = "5")]
    number: usize,

    #[arg(short, long, default_value = "false")]
    interactive: bool,
}

#[tokio::main]
async fn main() {
    let _guard = setup_opentelemetry();
    let args: Args = Args::parse();
    info!("Args:");

    if args.interactive {
        produce_interactive(&args.topic).await;
    } else {
        produce_number(args.verbose, &args.topic, args.number).await;
    }
}

pub async fn produce_number(verbose: bool, topic: &str, number: usize) {
    println!("span");

    if verbose {
        info!(
            "Creating producer {{ topic: {}, num. of messages: {} }}",
            topic, number
        );
    }

    let producer: &FutureProducer = &create_producer(false);

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
        future.await.expect("future error");
    }
}

pub async fn produce_interactive(topic: &str) {
    info!("Creating interactive producer {{ topic: {} }}", topic,);
    let producer: &FutureProducer = &create_producer(false);
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

        tracing::info!("message sent, delivery status: {:?}", delivery_status);
    }
}

pub async fn deliver(
    producer: &FutureProducer,
    topic_name: &str,
    key: String,
    message: impl ToBytes + Debug,
) -> OwnedDeliveryResult {
    let mut span = global::tracer("producer").start("message delivery to kafka");
    span.set_attribute(KeyValue::new("topic", topic_name.to_owned()));
    span.set_attribute(KeyValue::new("message", format!("{:?}", message)));
    let context = Context::current_with_span(span);
    let mut headers = OwnedHeaders::new();
    global::get_text_map_propagator(|propagator| {
        propagator.inject_context(&context, &mut HeaderInjector(&mut headers))
    });

    producer
        .send(
            FutureRecord::to(topic_name)
                .payload(&message)
                .key(&key)
                .headers(headers),
            Duration::from_secs(0),
        )
        .await
}
pub struct HeaderInjector<'a>(pub &'a mut OwnedHeaders);

impl<'a> Injector for HeaderInjector<'a> {
    fn set(&mut self, key: &str, value: String) {
        let mut new = OwnedHeaders::new().insert(rdkafka::message::Header {
            key,
            value: Some(&value),
        });

        for header in self.0.iter() {
            let s = String::from_utf8(header.value.unwrap().to_vec()).unwrap();
            new = new.insert(rdkafka::message::Header {
                key: header.key,
                value: Some(&s),
            });
        }

        self.0.clone_from(&new);
    }
}
