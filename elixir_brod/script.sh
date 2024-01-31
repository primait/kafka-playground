TOPIC=two
MESSAGE=porcodio
curl -s -v \
  -X POST \
  "http://127.0.0.1:8082/topics/$TOPIC" \
  -H "Content-Type: application/vnd.kafka.binary.v2+json" \
  -d '{
  "records":[
      {
          "value":"'`printf $MESSAGE | base64`'"
      }
  ]
}'
