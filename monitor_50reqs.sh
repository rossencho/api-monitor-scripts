#!/bin/bash

log_file=$1_monitor_50reqs.log
CT="Content-Type:application/json"
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

GET_VERB="GET"
GET_BULK_VERB="GET_BULK"
POST_VERB="POST"
DELETE_VERB="DELETE"
PATCH_VERB="PATCH"
PUT_VERB="PUT"
VERBS=()

start_server() {
    if [ $1 = php ];then
        `nohup php -S localhost:8001 -t ../php-lumen-test/public >/dev/null &`
    elif [ $1 = node ];then
        `nohup node ../nodejs-test/server.js >/dev/null &`
    else
        `nohup /usr/local/jdk1.8.0/bin/java -jar cruddemo-data-jpa-0.0.1-SNAPSHOT.jar --server.address=127.0.0.1 --server.port=8001 --spring.jpa.open-in-view=false --spring.datasource.testOnBorrow=true --spring.datasource.validationQuery=SELECT 1 >/dev/null &` 
        echo "java"
    fi
    PID=$(pidof "$1")
    echo "Process ID=$PID"
}

end_server() {
    `kill $PID`
}

set_api_link() {
    API_LINK=$1
}

make50_verbs() {

    for c in {1..50} ;do
        if [ "$c" -le 10 ];then
            VERBS[$c]=GET
        elif [ "$c" -gt 10 ] && [ "$c" -le 20 ];then
            VERBS[$c]=GET_BULK
        elif [ "$c" -gt 20 ] && [ "$c" -le 30 ];then
            VERBS[$c]=POST
        elif [ "$c" -gt 30 ] && [ "$c" -le 40 ];then
            VERBS[$c]=PUT
        elif [ "$c" -gt 40 ];then
            VERBS[$c]=DELETE
        fi
    done
}

make50_random_verbs() {

    for c in {1..50} ;do
        if [ "$c" -le 5 ];then
            VERBS[$c]=GET
        elif [ "$c" -gt 5 ] && [ "$c" -le 10 ];then
            VERBS[$c]=POST
        elif [ "$c" -gt 10 ] && [ "$c" -le 15 ];then
            VERBS[$c]=PATCH
        elif [ "$c" -gt 15 ] && [ "$c" -le 25 ];then
            VERBS[$c]=GET_BULK
        elif [ "$c" -gt 25 ] && [ "$c" -le 30 ];then
            VERBS[$c]=DELETE
        elif [ "$c" -gt 30 ] && [ "$c" -le 40 ];then
            VERBS[$c]=GET
        elif [ "$c" -gt 40 ];then
            VERBS[$c]=PATCH
        fi
    done
}

init() {
    set_api_link $1
    if [ $2 -le 60 ];then
        make50_verbs
    else
        make50_random_verbs
    fi
}

logger() {
    output="ps -p $PID -o %cpu,%mem"
    echo "API=$1, GET time=$2s, GET_BULK time=$3, POST time=$4, UPDATE time=$5, DELETE time=$6, interval=$7 $(date)">>${log_file}
    echo "$(${output})" >> ${log_file}
}

make50_requests() {
    get_time=0
    get_number=0
    get_bulk_time=0
    get_bulk_number=0
    update_time=0
    update_number=0
    post_time=0
    post_number=0
    delete_time=0
    delete_number=0
    counter=$2
    while [ $counter -gt 0 ]
    do
        for VERB in ${VERBS[@]} ; do
            RAND_ID=$(awk -v min=1 -v max=1000 'BEGIN{srand(); printf("%.2d", int(min+rand()*(max-min+1)))}')
            if [ "$VERB" = "$POST_VERB" ]; then
                if [ $1 = php ];then
                    post_time=$(echo `curl -X $VERB -H $CT $API_LINK -d "$POST_PAYLOAD" -s -o /dev/null -w %{time_starttransfer}` $post_time|awk '{print $1 + $2}')
                else
                    post_time=$(echo `curl -X $VERB -H $CT $API_LINK -d "$POST_PAYLOAD_4_JAVA" -s -o /dev/null -w %{time_starttransfer}` $post_time|awk '{print $1 + $2}')
                fi
                (( post_number++ ))
            elif [ "$VERB" = "$PATCH_VERB" ] || [ "$VERB" = "$PUT_VERB" ]; then
                if [ $1 = php ];then
                    update_time=$(echo `curl -X $VERB -H $CT $API_LINK/$RAND_ID -d "$UPDATE_PAYLOAD" -s -o /dev/null -w %{time_starttransfer}` $update_time|awk '{print $1 + $2}')
                else    
                    update_time=$(echo `curl -X $VERB -H $CT $API_LINK -d '{"id":"'"$RAND_ID"'","name":"Rossens API Java test update","description":"Rossens API test from bash update",
	"price":1.232,"quantity":23,"is_on_stock":false,"pickupMethod":"personal","createdAt":"2020-05-12 10:23:12","updatedAt":"2020-05-12 10:23:12"}' -s -o /dev/null -w %{time_starttransfer}`  $update_time|awk '{print $1 + $2}')
                fi
                (( update_number++ ))
            elif [ "$VERB" = "$GET_BULK_VERB" ]; then
                get_bulk_time=$(echo `curl -H $CT $API_LINK -s -o /dev/null -w %{time_starttransfer}` $get_bulk_time|awk '{print $1 + $2}')
                (( get_bulk_number++ ))
            elif [ "$VERB" = "$GET_VERB" ] ; then
                get_time=$(echo `curl -H $CT $API_LINK/$RAND_ID -s -o /dev/null -w %{time_starttransfer}` $get_time|awk '{print $1 + $2}')
                (( get_number++ ))
            else [ "$VERB" = "$DELETE_VERB" ] 
                delete_time=$(echo `curl -X $VERB -H $CT $API_LINK/$RAND_ID -s -o /dev/null -w %{time_starttransfer}` $delete_time|awk '{print $1 + $2}')
                (( delete_number++ ))
            fi
        done
        counter=$[$counter-1]
        sleep 1
    done
    get_average=$(echo $get_time $get_number|awk '{print $1/$2}')
    get_bulk_average=$(echo $get_bulk_time $get_bulk_number|awk '{print $1/$2}')
    post_average=$(echo $post_time $post_number|awk '{print $1/$2}')
    update_average=$(echo $update_time $update_number|awk '{print $1/$2}')
    delete_average=$(echo $delete_time $delete_number|awk '{print $1/$2}')

    logger $1 "$get_average" "$get_bulk_average" "$post_average" "$update_average" "$delete_average" $2
}

pinger() {
    status=0
    START=$(date +%s.%N)
    while [ $status -ne 200 ] ; do
        status=`curl -s -w"%{http_code}" -H $CT $1/1 -k -s -f -o /dev/null`
        logger 0 LAUNCHING
    done
    make50_requests $2 $3
}

init $2 $3
start_server $1
pinger $2 $1 $3
end_server

# $1 - technology; $2 - API_URL; $3 - measured interval
