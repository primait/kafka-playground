use clap::{Parser, ValueEnum};
use opentelemetry::propagation::Extractor;
use opentelemetry::trace::{Link, Span, SpanKind, TraceContextExt, Tracer};
use opentelemetry::{global, Key, KeyValue, StringValue};
use rdkafka::config::RDKafkaLogLevel;
use rdkafka::consumer::{CommitMode, Consumer, StreamConsumer};
use rdkafka::message::{BorrowedHeaders, BorrowedMessage, Headers};
use rdkafka::{ClientConfig, Message};
use rust_rdkafka::setup_opentelemetry;
use std::string::ToString;
use tracing::{info, warn};
use uuid::Uuid;

const BROKERS: &str = "kafka";

#[tokio::main]
async fn main() {
    let _guard = setup_opentelemetry();

    let args: Args = Args::parse();
    info!("Args: {:?}", args);
    let group_id = args.group_id.unwrap_or_else(|| Uuid::new_v4().to_string());
    consume_and_print(
        args.verbose,
        &args.brokers,
        &args.topics.iter().map(|s| &**s).collect(),
        &group_id,
        args.offset_reset,
    )
    .await
}

async fn consume_and_print(
    verbose: bool,
    brokers: &str,
    topic: &Vec<&str>,
    group_id: &str,
    offset_reset: OffsetReset,
) {
    info!(
        "Creating consumer {{ brokers: {}, group_id: {}, topics: {}, offset.reset: {}, verbose: {} }}",
        brokers,
        group_id,
        topic.join(", "),
        offset_reset.to_string(),
        verbose
    );
    let consumer: StreamConsumer = ClientConfig::new()
        .set("group.id", group_id)
        .set("bootstrap.servers", brokers)
        .set("session.timeout.ms", "6000")
        .set("enable.auto.commit", "true")
        .set("auto.offset.reset", offset_reset.to_string())
        .set_log_level(RDKafkaLogLevel::Debug)
        .create()
        .expect("Consumer creation failed");

    consumer
        .subscribe(&topic.as_slice())
        .expect("Can't subscribe to specified topics");

    info!("Start consuming...");
    loop {
        match consumer.recv().await {
            Err(e) => warn!("Kafka error: {}", e),
            Ok(m) => consume_message(&consumer, m, verbose),
        };
    }
}

fn consume_message(consumer: &StreamConsumer, m: BorrowedMessage, verbose: bool) {
    let key = m
        .key()
        .and_then(|key| std::str::from_utf8(key).ok())
        .unwrap_or("no key");
    let payload = m
        .payload_view::<str>()
        .unwrap_or(Ok("--"))
        .unwrap_or_else(|e| {
            warn!("Error while deserializing message payload: {:?}", e);
            ""
        });

    if let Some(headers) = m.headers() {
        let context = global::get_text_map_propagator(|propagator| {
            propagator.extract(&HeaderExtractor(&headers))
        });
        let tracer = global::tracer("consumer");
        let mut span = tracer
            .span_builder("consume message")
            .with_kind(SpanKind::Consumer)
            .with_links(vec![Link::new(
                context.span().span_context().clone(),
                vec![],
            )])
            .start(&tracer);

        span.set_attribute(KeyValue {
            key: Key::new("payload"),
            value: opentelemetry::Value::String(StringValue::from(payload.to_string())),
        });
        for header in headers.iter() {
            if let Some(val) = header.value {
                println!(
                    "  Header {:#?}: {:?}",
                    header.key,
                    String::from_utf8(val.to_vec())
                );
            }
        }
        if verbose {
            for header in headers.iter() {
                info!("  Header {:#?}: {:?}", header.key, header.value);
            }
        }
    }

    if verbose {
        info!(
            "key: '{}', payload: '{}', topic: {}, partition: {}, offset: {}, timestamp: {:?}",
            key,
            payload,
            m.topic(),
            m.partition(),
            m.offset(),
            m.timestamp()
        );
    } else {
        info!("key: '{}', payload: '{}'", key, payload);
    }

    consumer.commit_message(&m, CommitMode::Async).unwrap();
}

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(short, long)]
    verbose: bool,

    #[arg(short, long, default_value = BROKERS)]
    brokers: String,

    #[arg(short, long, default_value = "topic-test")]
    topics: Vec<String>,

    #[arg(short, long)]
    group_id: Option<String>,

    #[arg(short, long, default_value = "latest")]
    offset_reset: OffsetReset,
}

#[derive(Debug, ValueEnum, Clone)]
enum OffsetReset {
    Latest,
    Earliest,
}

impl ToString for OffsetReset {
    fn to_string(&self) -> String {
        match self {
            OffsetReset::Latest => "latest".to_string(),
            OffsetReset::Earliest => "earliest".to_string(),
        }
    }
}

pub struct HeaderExtractor<'a>(pub &'a BorrowedHeaders);

impl<'a> Extractor for HeaderExtractor<'a> {
    fn get(&self, key: &str) -> Option<&str> {
        for i in 0..self.0.count() {
            if let Ok(val) = self.0.get_as::<str>(i) {
                if val.key == key {
                    return val.value;
                }
            }
        }
        None
    }

    fn keys(&self) -> Vec<&str> {
        self.0.iter().map(|kv| kv.key).collect::<Vec<_>>()
    }
}
