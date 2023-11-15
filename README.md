# Kafka Playground

## Overview
Welcome to `kafka-playground`! This repository is a sandbox for exploring and understanding the integration of Apache Kafka with Elixir, Rust, and Python. It's part of an initiative to leverage Kafka as a company-wide integration events bus, focusing on creating examples, guidelines, and best practices. Our aim is to address potential integration challenges and to refine our event design approach.

### Context
We've set up a hypothetical scenario involving a car repair shop to simulate real-world applications and data flows.

## Scenario: Car Repair Shop

### Components
- **Ticketing System (Elixir)**: Manages repair tickets.
- **Secretary (Python)**: Handles appointment scheduling.
- **Cash Desk (Rust)**: Processes payments.

### Kafka Topics
- `tickets`: For the ticketing system.
- `appointments`: For the secretary's scheduling tasks.
- `payments`: For payment processing at the cash desk.

### Events Flow
1. **Ticketing System**
   - `ticket_opened`
2. **Secretary**
   - `appointment_booked`
3. **Cash Desk**
   - `payment_registered`
4. **Ticketing System**
   - `ticket_closed`

## Event Structure

### Ticketing System
- `ticket_opened`
  - `occurred_on`: timestamp with time zone
  - `ticket_id`: uuid
  - `requester`:
    - `email`: email
    - `name`: string
    - `middlename`: optional[string]
    - `surname`: string
    - `age`: integer
  - `repair_type`: enum[windshield, bumper, body]

### Secretary
- `appointment_booked`
  - `occurred_on`: timestamp with time zone
  - `ticket_id`: uuid
  - `appointment_id`: uuid
  - `scheduled_at`: timestamp with time zone

### Cash Desk
- `payment_registered`
  - `ticket_id`: uuid
  - `appointment_id`: uuid
  - `payment_id`: uuid
  - `occurred_on`: timestamp with time zone
  - `amount`: decimal

### Ticketing System
- `ticket_closed`
  - `occurred_on`: timestamp with time zone
  - `ticket_id`: uuid

## Getting Started

[Instructions on how to clone, set up, and run the applications in this repository.]

To produce a (text) message on a topic use this:

```shell
TOPIC=test_topic
MESSAGE=test_message
curl -s \
  -X POST \
  "http://localhost:8082/topics/$TOPIC" \
  -H "Content-Type: application/vnd.kafka.binary.v2+json" \
  -d '{
  "records":[
      {
          "value":"'`printf $MESSAGE | base64`'"
      }
  ]
}'
```

## TODO
- [ ] finish readme
- [x] elixir consumer and producer
- [x] rust consumer and producer
- [x] python consumer and producer
- [ ] events examples
- [ ] avro (or protobuf?)
- [ ] schema registry naming strategies
- [ ] code generation
- [ ] auth (more than one set of credentials)
- [ ] kafka containers
- [ ] debug performance issues when running 3 containers?
- [ ] spark?
- [ ] distributed tracing? datadog compatibility with follow_from?
- [ ] encryption?
- [ ] transactions? (consumers must use read_committed isolation level)
- [ ] CI?
- [ ] transactional outboxes? (before or after serialization?)
- [ ] parallelism (multiple consumers and multiple consumers groups)
- [ ] idempotent consumers
