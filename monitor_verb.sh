#!/bin/bash

log_file=$1_monitor_verb.log

ONE_MINUTE_COUNTER=60
# POST_PAYLOAD=`cat post_data.json | jq '.'`
CT="Content-Type:application/json"
RAND_NUMBER=$(awk -v min=1 -v max=100 'BEGIN{srand(); printf("%.2d", int(min+rand()*(max-min+1)))}')
API_LINK="http://localhost:8001/api/products"
CURL_BULK_GET="curl http://localhost:8001/products -H $CT "
CURL_GET="curl http://localhost:8001/products/$RAND_NUMBER -H $CT -s -o /dev/null -w %{time_starttransfer}"
CURL_DELETE="curl -X DELETE http://localhost:8001/products/$RAND_NUMBER -H $CT -s -o /dev/null -w %{time_starttransfer}"
POST_PAYLOAD="
{
    \"name\":\"Rossens API test\",
    \"description\":\"Rossens API test from bash\",
	\"price\":1.232,
	\"quantity\":23,
	\"is_on_stock\":false,
	\"pickup_method\":\"personal\"
}"
POST_PAYLOAD_4_JAVA="
{
    \"name\":\"Rossens API Java test\",
    \"description\":\"Rossens API test from bash\",
	\"price\":1.232,
	\"quantity\":23,
	\"is_on_stock\":false,
	\"pickupMethod\":\"personal\",
    \"createdAt\":\"2020-05-12 10:23:12\",
    \"updatedAt\":\"2020-05-12 10:23:12\"
}"
UPDATE_PAYLOAD="
{
    \"name\":\"Rossens API test update\",
    \"description\":\"Rossens API test from bash update\",
	\"price\":1.232,
	\"quantity\":23,
	\"is_on_stock\":false,
	\"pickup_method\":\"personal\"
}"

CURL_POST="curl http://localhost:8001/products -H $CT -d $POST_PAYLOAD"
GET_VERB="GET"
GET_BULK_VERB="GET_BULK"
POST_VERB="POST"
DELETE_VERB="DELETE"
PATCH_VERB="PATCH"
PUT_VERB="PUT"
PID=0
RANDOM_VERBS1M=()
RANDOM_VERBS4H=()


start_server() {
    if [ $1 = php ];then
        `nohup php -S localhost:8001 -t ../php-lumen-test/public >/dev/null &`
    elif [ $1 = node ];then
        `nohup node ../nodejs-test/server.js >/dev/null &`
    else
        # `nohup /usr/local/jdk1.8.0/bin/java -jar ../java-springboot-test/v1/cruddemo-0.0.1-SNAPSHOT.jar --server.address=127.0.0.1 --server.port=8001 --spring.jpa.open-in-view=false --spring.datasource.testOnBorrow=true --spring.datasource.validationQuery=SELECT 1 >/dev/null &` 
        `nohup /usr/local/jdk1.8.0/bin/java -jar cruddemo-data-jpa-0.0.1-SNAPSHOT.jar --server.address=127.0.0.1 --server.port=8001 --spring.jpa.open-in-view=false --spring.datasource.testOnBorrow=true --spring.datasource.validationQuery=SELECT 1 >/dev/null &` 
    fi
    PID=$(pidof "$1")
    echo "Process ID=$PID"
    
}

end_server() {
    `kill $PID`
}

logger() {
    output="ps -p $PID -o %cpu,%mem"

    echo "API=$1, verb=$2, response time=$3s, interval=$4 $(date)">>${log_file}
    echo "$(${output})" >> ${log_file}
}




average_per_verb() {
    get_time=0
    get_number=0
    result=0
    counter=$ONE_MINUTE_COUNTER
    while ((counter > 0))
    do
        VERB=$2
        RAND_NUMBER=$(awk -v min=1 -v max=1000 'BEGIN{srand(); printf("%.2d", int(min+rand()*(max-min+1)))}')
        if [ "$VERB" = "$POST_VERB" ]; then
            if [ $1 = php ];then
                get_time=$(echo `curl -X $VERB -H $CT $API_LINK -d "$POST_PAYLOAD" -s -o /dev/null -w %{time_starttransfer}` $get_time|awk '{print $1 + $2}')
            else
                get_time=$(echo `curl -X $VERB -H $CT $API_LINK -d "$POST_PAYLOAD_4_JAVA" -s -o /dev/null -w %{time_starttransfer}` $get_time|awk '{print $1 + $2}')
            fi
        elif [ "$VERB" = "$PATCH_VERB" ] || [ "$VERB" = "$PUT_VERB" ]; then
            if [ $1 = php ];then
                get_time=$(echo `curl -X $VERB -H $CT $API_LINK/$RAND_NUMBER -d "$UPDATE_PAYLOAD" -s -o /dev/null -w %{time_starttransfer}` $get_time|awk '{print $1 + $2}')
            else
                get_time=$(echo `curl -X $VERB -H $CT $API_LINK -d '{"id":"'"$RAND_NUMBER"'","name":"Rossens API Java test update","description":"Rossens API test from bash update",
        "price":1.232,"quantity":23,"is_on_stock":false,"pickupMethod":"personal","createdAt":"2020-05-12 10:23:12","updatedAt":"2020-05-12 10:23:12"}' -s -o /dev/null -w %{time_starttransfer}` $get_time|awk '{print $1 + $2}')
            fi
        elif [ "$VERB" = "$GET_BULK_VERB" ]; then
            get_time=$(echo `curl -H $CT $API_LINK -s -o /dev/null -w %{time_starttransfer}` $get_time|awk '{print $1 + $2}')
        elif [ "$VERB" = "$GET_VERB" ] ; then
            get_time=$(echo `curl -H $CT $API_LINK/$RAND_NUMBER -s -o /dev/null -w %{time_starttransfer}` $get_time|awk '{print $1 + $2}')
        else [ "$VERB" = "$DELETE_VERB" ] 
            get_time=$(echo `curl -X $VERB -H $CT $API_LINK/$RAND_NUMBER -s -o /dev/null -w %{time_starttransfer}` $get_time|awk '{print $1 + $2}')
        fi
        (( get_number++ ))
        (( counter-- ))
        sleep 1
    done
    result=$(echo $get_time $get_number|awk '{print $1/$2}')
    logger $1 $VERB "$result" "1 minute"
  
}

pinger() {
    status=0
    API_LINK=$1
    START=$(date +%s.%N)
    while [ $status -ne 200 ] ; do
        status=`curl -s -w"%{http_code}" -H $CT $1/1 -k -s -f -o /dev/null`
        logger 0 LAUNCHING
    done
    average_per_verb "$2" "$POST_VERB"
    if [ $2 = php ];then
        average_per_verb "$2" "$PATCH_VERB"
    else 
        average_per_verb "$2" "$PUT_VERB"
    fi
    average_per_verb "$2" "$GET_BULK_VERB" 
    average_per_verb "$2" "$GET_VERB"
    average_per_verb "$2" "$DELETE_VERB"   
}
    

start_server $1
pinger $2 $1
end_server

