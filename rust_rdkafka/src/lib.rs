use chrono::prelude::*;
use env_logger::fmt::Formatter;
use env_logger::Builder;
use log::{LevelFilter, Record};
use rdkafka::message::ToBytes;
use rdkafka::producer::FutureProducer;
use rdkafka::ClientConfig;
use serde::{Deserialize, Serialize};
use std::io::Write;
use std::thread;
use uuid::Uuid;

#[derive(Serialize, Deserialize)]
pub struct TheMessage {
    content: String,
}

impl TheMessage {
    pub fn new(content: &str) -> Self {
        Self {
            content: content.to_owned(),
        }
    }
}

impl ToBytes for TheMessage {
    fn to_bytes(&self) -> &[u8] {
        self.content.to_bytes()
    }
}

pub fn setup_logger(log_thread: bool, rust_log: Option<&str>) {
    let output_format = move |formatter: &mut Formatter, record: &Record| {
        let thread_name = if log_thread {
            format!("(t: {}) ", thread::current().name().unwrap_or("unknown"))
        } else {
            "".to_string()
        };

        let local_time: DateTime<Local> = Local::now();
        let time_str = local_time.format("%H:%M:%S%.3f").to_string();
        write!(
            formatter,
            "{} {}{} - {} - {}\n",
            time_str,
            thread_name,
            record.level(),
            record.target(),
            record.args()
        )
    };

    let mut builder = Builder::new();
    builder
        .format(output_format)
        .filter(None, LevelFilter::Info);

    rust_log.map(|conf| builder.parse_filters(conf));

    builder.init();
}

pub fn create_producer(transactional: bool) -> FutureProducer {
    let mut config = ClientConfig::new();

    config
        .set("bootstrap.servers", "kafka")
        .set("message.timeout.ms", "5000");
    if transactional {
        config.set("transactional.id", &Uuid::new_v4().to_string());
    }
    let producer = config.create().expect("Producer creation error");
    producer
}
