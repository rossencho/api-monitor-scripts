#!/bin/bash


log_file=$1_monitor_random.log

ONE_MINUTE_COUNTER=60
# POST_PAYLOAD=`cat post_data.json | jq '.'`
CT="Content-Type:application/json"
RAND_ID=$(awk -v min=1 -v max=100 'BEGIN{srand(); printf("%.2d", int(min+rand()*(max-min+1)))}')
API_LINK="http://localhost:8001/products"
CURL_BULK_GET="curl http://localhost:8001/products -H $CT "
CURL_GET="curl http://localhost:8001/products/$RAND_ID -H $CT -s -o /dev/null -w %{time_starttransfer}"
CURL_DELETE="curl -X DELETE http://localhost:8001/products/$RAND_ID -H $CT -s -o /dev/null -w %{time_starttransfer}"
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
RANDOM_VERBS=(GET GET_BULK DELETE PUT POST)

set_api_link() {
    API_LINK=$1
}

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

make_random_verbs_for_aminute() {

    for  (( c=1; c<=60; c++ ));do
        if [ "$c" -le 30 ];then
            RANDOM_VERBS1M[$c]=GET
        elif [ "$c" -gt 30 ] && [ "$c" -le 40 ];then
            RANDOM_VERBS1M[$c]=GET_BULK
        elif [ "$c" -gt 40 ] && [ "$c" -le 50 ];then
            RANDOM_VERBS1M[$c]=POST
        elif [ "$c" -gt 50 ] && [ "$c" -le 55 ];then
            RANDOM_VERBS1M[$c]=PATCH
        elif [ "$c" -gt 55 ];then
            RANDOM_VERBS1M[$c]=DELETE
        fi
    done
}

make_random_verbs_for_4hours() {

    for  (( c=1; c<=14400; c++ ));do
        if [ "$c" -le 5000 ];then
            RANDOM_VERBS4H[$c]=GET
        elif [ "$c" -gt 5000 ] && [ "$c" -le 10000 ];then
            RANDOM_VERBS4H[$c]=GET_BULK
        elif [ "$c" -gt 10000 ] && [ "$c" -le 12000 ];then
            RANDOM_VERBS4H[$c]=POST
        elif [ "$c" -gt 12000 ] && [ "$c" -le 14000 ];then
            RANDOM_VERBS4H[$c]=PATCH
        elif [ "$c" -gt 14000 ];then
            RANDOM_VERBS4H[$c]=DELETE
        fi
    done
}

init_script() {
    set_api_link $1
    # make_random_verbs_for_aminute
    # make_random_verbs_for_4hours
}

logger() {
    output="ps -p $PID -o %cpu,%mem"
    echo "API=$1, GET time=$2s, GET_BULK time=$3, POST time=$4, UPDATE time=$5, DELETE time=$6, interval=$7 $(date)">>${log_file}
    echo "$(${output})" >> ${log_file}
}

average_per_random_verb() {
   
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
    

    # if [ $2 -eq 60 ] ; then
    #     VERBS=${RANDOM_VERBS1M[@]}
    # else 
    #     VERBS=${RANDOM_VERBS4H[@]}
    # fi 

    counter=$2
    while ((counter > 0))
    do
        rand_verb=$(awk -v min=0 -v max=4 'BEGIN{srand(); printf("%.1d", int(min+rand()*(max-min+1)))}')
        VERB=${RANDOM_VERBS[$rand_verb]}
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
	"price":1.232,"quantity":23,"is_on_stock":false,"pickupMethod":"personal","createdAt":"2020-05-12 10:23:12","updatedAt":"2020-05-12 10:23:12"}' -s -o /dev/null -w %{time_starttransfer}` $update_time|awk '{print $1 + $2}')
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
        (( counter-- ))
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
    average_per_random_verb $2 $3
}

start_server $1
init_script $2
# $1 - technology; $2 - API_URL; $3 - measured interval
pinger $2 $1 $3
end_server

