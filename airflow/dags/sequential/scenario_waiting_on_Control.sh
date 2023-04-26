while true
    do
        log_info=`docker exec -i 'drivesim-ov'  bash  -c "tail -n 50 ds2_run.log"`
        echo ${log_info}
        if echo  ${log_info}  | grep -q "Scenario Start/Resume is waiting on Control, client must indicate progression"; then

            echo "Scenario Start/Resume is waiting on Control. Starting run ndas script."
            sleep 5
            break
        fi
done