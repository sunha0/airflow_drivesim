#!/bin/bash
while true
do
if [  ! -z  $(docker ps -q -f  "name=drivesim-ov")  ];then
        log_info=`docker exec -i drivesim-ov  bash  -c "tail -n 100 ds2_run.log"`
        echo ${log_info}
        if echo  ${log_info}  | grep -q "ScenarioStateChange to eStopping broadcast completed"; then

            echo "ScenarioStateChange to eStopping broadcast completed"

            break
        fi
        sleep 10
else
break 


fi

 done
