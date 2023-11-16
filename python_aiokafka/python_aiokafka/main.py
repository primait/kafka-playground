import argparse
import asyncio
import logging
import os
import uuid

import avro.schema
import primapy_tracing
from aiokafka import AIOKafkaConsumer, AIOKafkaProducer, TopicPartition
from opentelemetry import context, propagate


def run():
    logging.basicConfig(
        format="%(asctime)s %(levelname)s %(message)s", level=logging.INFO
    )

    primapy_tracing.instrument(
        primapy_tracing.TracingSettings(
            endpoint=os.environ.get(
                "OPENTELEMETRY_ENDPOINT", default="http://localhost:55681/v1/traces"
            ),
            enabled=True,
            service_name="python_aiokafka",
            service_version="0.0.0-dev",
            deployment_environment="dev",
        )
    )

    parser = argparse.ArgumentParser(
        description="python kafka consumer and producer implementation with aiokafka"
    )
    parser.add_argument("-s", "--source", default=os.environ.get("SOURCE"))
    parser.add_argument("-d", "--destination", default=os.environ.get("DESTINATION"))
    args = parser.parse_args()

    asyncio.run(consume(args.source, args.destination))


class Setter:
    def set(self, headers, key, value):
        headers.append((key, value.encode("utf-8")))


class Getter:
    def get(self, headers, key):
        for k, value in headers:
            if k == key:
                return [value.decode("utf-8")]
        return None

    def keys(self, headers):
        return [k for k, v in headers]


async def consume(source: str, destination: str):
    schema = avro.schema.parse(open("../schemas/appointment_booked.avsc", "rb").read())

    logger = logging.getLogger(__name__)

    consumer_group_id = f"python-aiokafka-consumer-{source}"

    consumer = AIOKafkaConsumer(
        source,
        bootstrap_servers="kafka:9092",
        client_id="aiokafka-consumer",
        enable_auto_commit=False,
        group_id=consumer_group_id,
        auto_offset_reset="latest",
    )
    producer = AIOKafkaProducer(
        bootstrap_servers="kafka:9092",
        client_id="aiokafka-producer",
        transactional_id=f"python-{str(uuid.uuid4())}",
    )

    await consumer.start()
    await producer.start()

    tracer = primapy_tracing.trace.get_tracer("test")
    propagator = propagate.get_global_textmap()

    try:
        async for msg in consumer:
            trace_context = propagator.extract(msg.headers, getter=Getter())

            # to set the producer span as parent
            # context.attach(trace_context)


            links = []
            # to add a the producer span as a link
            if spans := list(trace_context):
                links = [
                    primapy_tracing.trace.Link(
                        context.get_value(
                            spans[0], context=trace_context
                        ).get_span_context()
                    )
                ]

            with tracer.start_as_current_span(
                "consume",
                kind=primapy_tracing.trace.SpanKind.CONSUMER,
                attributes={"message": str(msg)},
                links=links,
            ):
                with tracer.start_as_current_span(
                    "internal", kind=primapy_tracing.trace.SpanKind.INTERNAL
                ):
                    async with producer.transaction():
                        headers = []
                        propagator.inject(
                            headers, setter=Setter(), context=context.get_current()
                        )

                        with tracer.start_as_current_span(
                            "producer", kind=primapy_tracing.trace.SpanKind.PRODUCER
                        ):
                            await producer.send(
                                destination, value=msg.value, headers=headers
                            )
                        await producer.send_offsets_to_transaction(
                            offsets={
                                TopicPartition(
                                    topic=msg.topic,
                                    partition=msg.partition,
                                ): msg.offset
                                + 1,
                            },
                            group_id=consumer_group_id,
                        )
            logger.info("message consumed: %s", msg)
    finally:
        await consumer.stop()
        await producer.stop()
