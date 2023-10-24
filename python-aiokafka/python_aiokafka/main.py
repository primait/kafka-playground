import asyncio
import ssl

from aiokafka import AIOKafkaProducer

SOURCE_TOPIC = "python-aiokafka"
DESTINATION_TOPIC = "python-aiokafka"


def run():
    asyncio.run(produce())


async def produce():
    kafka_producer = AIOKafkaProducer(
        bootstrap_servers="kafka:9092",
        client_id="aiokafka-producer",
    )
    await kafka_producer.start()
    await kafka_producer.send(DESTINATION_TOPIC, value=bytes("ping", "utf-8"))
    await kafka_producer.stop()
