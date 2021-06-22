#export LOG_TAG=BAIDU_LOG
#export CLUSTER_NAME=baidu
function generate() {
containerLen=`crictl ps  -o json | jq '.containers|length' `
#delete the disappear container config
allids=""
for  (( i=0; i<$containerLen; i++ ))
do
    allids=$allids" "`crictl ps  -o json | jq -r ".containers[$i].id" `.yml
done
for file in `ls inputs.d`
do
    if ! echo $allids | grep -q "$file"
    then
    echo "rm input.d/$file"
    rm inputs.d/$file
    fi
done
#generate 
for  (( i=0; i<$containerLen; i++ ))
do
containerID=`crictl ps  -o json | jq -r ".containers[$i].id" `
podID=`crictl ps  -o json | jq -r ".containers[$i].podSandboxId" `
containerDetail=`crictl inspect ${containerID} `
log_env=`echo $containerDetail | jq .info.runtimeSpec.process.env | grep -o "${LOG_TAG}[^\"]*"`
mountsLen=`echo $containerDetail | jq '.status.mounts|length'`
log_env=${log_env/${LOG_TAG}=/}
log_env=${log_env//:/ }
for log_dir in ${log_env}
do
    for (( j=0; j<${mountsLen}; j++ )) 
    do
    containerPath=`echo $containerDetail | jq -r ".status.mounts[$j].containerPath"`
    hostPath=`echo $containerDetail | jq -r ".status.mounts[$j].hostPath"`
    if echo $log_dir | grep -q "${containerPath}"; then
        log_real_dir=${log_dir/${containerPath}/${hostPath}} 
        if [[ $LOG_DIR == "" ]]; then
            LOG_DIR=$log_real_dir
        else
            LOG_DIR=$LOG_DIR,$log_real_dir
        fi
#        echo $LOG_DIR
        ok="ok"
    fi
    done
    
    if [[ $ok != "ok" ]]; then
       echo "error find "$log_dir
    fi  
done
if [[ $LOG_DIR != "" ]]; then
NAMESPACE=`echo $containerDetail | jq -r '.status.labels."io.kubernetes.pod.namespace"' `
POD=`echo $containerDetail | jq -r '.status.labels."io.kubernetes.pod.name"' `
CONTAINER=`echo $containerDetail | jq -r '.status.labels."io.kubernetes.container.name"' `
INPUT_LOG_TPL="
- type: log
  paths: [${LOG_DIR}]
  scan_frequency: 10s
  fields:
    cluster: ${CLUSTER}
    namespace: ${NAMESPACE}
    pod_name: ${POD}
    container_name: ${CONTAINER}
  fields_under_root: true
"
echo "$INPUT_LOG_TPL" >  inputs.d/${containerID}.yml
LOG_DIR=""
POD=""
CONTAINER=""
fi
done
} # end generate
if [[ $LOG_TAG == "" ]]; then
echo "err set LOG_TAG"
exit
fi
if [[ $SLEEP_TIME == "" ]]; then
SLEEP_TIME=2
fi 
while :
do
generate
sleep $SLEEP_TIME
done
