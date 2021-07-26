
#!/bin/bash
 
#export KAFKA_BROKERS=\"127.0.0.1\"
#export KAFKA_TOPIC=hello
export ES_ENTRIES='"127.0.0.1:9200"'
export LOG_TAG=BILC_LOG
export CLUSTER_NAME=bilc
INPUT_TPL='
filebeat.config.inputs:
  enabled: true
  path: inputs.d/*.yml
  reload.enabled: true
  reload.period: 10s
'
OUTPUT_KAFKA_TPL="
output.kafka:
  hosts: [${KAFKA_BROKERS}]
  topic: ${KAFKA_TOPIC}
"
OUTPUT_CONSOLE_TPL="
output.console:
  pretty: true
"
OUTPUT_ES_TPL="
output.elasticsearch:
  hosts: [${ES_ENTRIES}] 
"
if [[ ! -e inputs.d ]]
then
mkdir inputs.d
fi
echo "$INPUT_TPL" > config.yml
if [[ $KAFKA_BROKERS != "" && $KAFKA_TOPIC != "" ]]
then
echo "$OUTPUT_KAFKA_TPL" >> config.yml
elif [[ $ES_ENTRIES != "" ]]
then
echo "$OUTPUT_ES_TPL" >> config.yml
else 
echo "$OUTPUT_CONSOLE_TPL" >> config.yml
fi 
if [[ $LOG_TAG == "" ]]; then
echo "err set LOG_TAG"
exit
fi
 
nohup ./cri_input.sh > output.log & 
echo "ok"
