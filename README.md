TODO:
- [x] elixir consumer and producer
- [x] rust consumer and producer
- [x] python consumer and producer
- [ ] Avro (or protobuf?)
- [ ] schema registry naming strategies
- [ ] code generation
- [ ] auth (more than one set of credentials)
- [ ] kafka containers
- [ ] debug performance issues when running 3 containers?
- [ ] spark?
- [ ] events examples?
- [ ] distributed tracing? datadog compatibility with follow_from?
- [ ] encryption?
- [ ] transactions? (consumers must use read_committed isolation level)
- [ ] CI?
- [ ] transactional outboxes? (before or after serialization?)


To implement a 'ring' we'll use a fake domain: a business car repair shop:

ticketing system: elixir application - topic: tickets

secretary: python application - topic: appointments

cash desk: rust application - topic: payments


Events flow:

1. ticketing system
```yaml
ticket_opened:
    occurred_on: timestamp with time zone
    ticket_id: uuid
    requester:
        email: email
        name: string
        middlename: optional[string]
        surname: string
        age: integer
    repair_type: enum[windshield, bumper, body]
```

2. secretary
```yaml
appointment_booked:
    occured_on: timestamp with time zone
    ticket_id: uuid
    appointment_id: uuid
    scheduled_at: timestamp with time zone
```

3. cash desk
```yaml
payment_registered:
   ticket_id: uuid
   appointment_id: uuid
   payment_id: uuid
   occurred_on: timestamp with time zone
   amount: decimal
```

4. ticketing system
```yaml
ticket_closed:
    occurred_on: timestamp with time zone
    ticket_id: uuid
```


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
