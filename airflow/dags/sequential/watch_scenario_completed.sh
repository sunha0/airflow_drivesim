#!/bin/bash

while true
    do
        log_info=`docker exec -i 'drivesim-ov'  bash  -c "tail -n 50 ds2_run.log"`
        echo ${log_info}
        if echo  ${log_info}  | grep -q "ScenarioStateChange to eStopping broadcast completed"; then

            echo "ScenarioStateChange to eStopping broadcast completed"
            sleep 5
            break
        fi
done