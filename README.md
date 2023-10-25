TODO:
- [x] elixir consumer and producer
- [ ] rust consumer and producer
- [x] python consumer and producer
- [ ] schema registry naming strategies
- [ ] code generation
- [ ] Avro (or protobuf?)
- [ ] auth
- [ ] kafka containers
- [ ] spark?
- [ ] events examples?
- [ ] distributed tracing?
- [ ] encryption?
- [ ] transactions?

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
