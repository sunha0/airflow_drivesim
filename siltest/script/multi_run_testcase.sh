#!/bin/bash
multi_test_case_path="$1"
siltestDir="$2"
ndasImage="$3"
drivesimImage="$4"
omniverseIp="$5"

echo $siltestDir 
echo $ndasImage
echo $drivesimImage
echo $omniverseIp

rrLogPath="${siltestDir}/rrLog"
ncdPath="${siltestDir}/cache/dockerovcache-dev/.nvidia-omniverse/logs/Kit/omni.drivesim.e2e/23.1"

IFS=';' read -ra testcase_array <<< "$multi_test_case_path"

for testcase in "${testcase_array[@]}"
do
  echo $testcase
    
   # kill all ndas drivesim container
   sudo sh $siltestDir/script/stop_ndas_drsivesim_container.sh
   # clean up all cache files 
   sudo sh $siltestDir/script/clean_data.sh $siltestDir


   # start running ndas container 
   cd $siltestDir/script && ./ndas_startup_hyp8_r5_1.sh  $siltestDir $ndasImage
   # start running drivesim container and execute testcase
   cd $siltestDir/script && ./ds_launch_hyp8_r5_1_airflow.sh  $siltestDir  $drivesimImage  $omniverseIp  $testcase
   
   # watch drivesim control info 
   while true
       do
        log_info=`docker exec -i drivesim-ov bash -c "tail -n 100 ds2_run.log"`
        echo ${log_info}
        if echo  ${log_info}  | grep -q "Scenario Start/Resume is waiting on Control, client must indicate progression"; then

            echo "Scenario Start/Resume is waiting on Control. Starting run ndas script."

            break
        fi
        sleep 5
     done
   # start to execute ndas script
    docker exec -d ndas bash -c "sh /home/run_ndas.sh"
   # watch scenario completed 
    while true
     do
        if  [ ! -z $(docker ps -q -f "name=drivesim-ov") ];then

           log_info=`docker exec -i drivesim-ov bash -c "tail -n 100 ds2_run.log"`
           echo ${log_info}
           if echo  ${log_info}  | grep -q "ScenarioStateChange to eLoading broadcast completed"; then

              echo "ScenarioStateChange to eStopping broadcast completed"
              break
           fi
           sleep 10
        else
          break
        fi
    done

    # backup osi/roadcast log 
    testcase_name=`echo ${testcase##*/} |cut -d '.' -f 1`
    sudo sh $siltestDir/script/backup_nano_osi_roadcast.sh  $siltestDir  $testcase_name   $ncdPath  $rrLogPath
   
    # generate evaluation report
    sudo sh  $siltestDir/script/evaluations.sh $siltestDir $testcase

   echo "first completed"
done


