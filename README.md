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
- [ ] distributed tracing?
- [ ] encryption?
- [ ] transactions?
- [ ] CI?

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
