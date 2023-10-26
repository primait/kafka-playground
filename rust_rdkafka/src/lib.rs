use prima_tracing::{configure_subscriber, init_subscriber, Country, Environment, Uninstall};
use rdkafka::message::ToBytes;
use rdkafka::producer::FutureProducer;
use rdkafka::ClientConfig;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Serialize, Deserialize, Debug)]
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

pub fn setup_opentelemetry() -> Uninstall {
    let subscriber = configure_subscriber(
        prima_tracing::builder("rust_rdkafka")
            .with_env(Environment::Dev)
            .with_version("0.0.1".to_string())
            .with_telemetry(
                "http://jaeger:55681/v1/traces".to_string(),
                "rust_rdkafka".to_string(),
            )
            .with_country(Country::Common)
            .build(),
    );
    let guard = init_subscriber(subscriber);

    guard
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
