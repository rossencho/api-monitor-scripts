#!/bin/bash
CT="Content-Type:application/json"
log_file=$1_monitor_launch.log


logger() {
    output="ps -p $PID -o %cpu,%mem"
    echo "Resources during $2" >> ${log_file}
    echo "Launch time $1" >> ${log_file}
    echo "$(${output})" >> ${log_file}
}

start_server() {
    if [ $1 = php ];then
        `nohup php -S localhost:8001 -t ../php-symfony-test/public >/dev/null &`
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

pinger() {
    status=0
    START=$(date +%s.%N)
    while [ $status -ne 200 ] ; do
        status=`curl -s -w"%{http_code}" -H $CT $1/1 -k -s -f -o /dev/null`
        logger 0 LAUNCHING
    done
    END=$(date +%s.%N)
    DIFF=$(echo $END $START | awk '{print $1 - $2}')
    echo $DIFF
    logger $DIFF IDLE
    sleep 30
    output="ps -p $PID -o %cpu,%mem"
    echo "Idle resources $(${output})" >> ${log_file}
}


start_server $1
pinger $2
end_server