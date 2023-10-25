import argparse
import asyncio

from aiokafka import AIOKafkaConsumer, AIOKafkaProducer, TopicPartition

CONSUMER_GROUP_ID = "python-consumer"

def run():
    parser = argparse.ArgumentParser(description='python kafka consumer and producer implementation with aiokafka')
    parser.add_argument('source_topic', type=str, help='the name of the topic to consume from')
    parser.add_argument('destination_topic', type=str, help='the name of the topic to produce to')
    args = parser.parse_args()
    asyncio.run(consume(args.source_topic, args.destination_topic))


async def consume(source_topic, destination_topic):
    consumer = AIOKafkaConsumer(
        source_topic,
        bootstrap_servers="kafka:9092",
        client_id="aiokafka-consumer",
        enable_auto_commit=False,
        group_id=f"python-aiokafka-consumer-{source_topic}",
        auto_offset_reset="latest"
    )
    producer = AIOKafkaProducer(
        bootstrap_servers="kafka:9092",
        client_id="aiokafka-producer",
        transactional_id=f"python-{destination_topic}",
    )
    await consumer.start()
    await producer.start()
    try:
        async for msg in consumer:
            print("consumed: ", msg)
            async with producer.transaction():
                sent = await producer.send(destination_topic, value=msg.value)
                print("produced: ", await(sent))
                await producer.send_offsets_to_transaction(offsets={
                        TopicPartition(
                            topic=msg.topic,
                            partition=msg.partition,
                        ): msg.offset
                        + 1,
                    },
                    group_id=CONSUMER_GROUP_ID,)
    finally:
        await consumer.stop()
        await producer.stop()
