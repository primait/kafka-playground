TODO:
- elixir consumer and producer
- rust consumer and producer
- python consumer and producer
- schema registry naming strategies
- code generation
- Avro (or protobuf?)
- auth
- kafka containers
- spark?
- events examples?
- distributed tracing?
- encryption?
- transactions?



UTILS:

curl -s \
  -X POST \
  "http://localhost:8082/topics/source" \
  -H "Content-Type: application/vnd.kafka.binary.v2+json" \
  -d '{
  "records":[
      {
          "value":"'`printf testmessage | base64`'"
      }
  ]
}'
