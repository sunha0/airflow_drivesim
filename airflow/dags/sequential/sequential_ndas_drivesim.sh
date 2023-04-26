#!/bin/bash

#siltestDir = Variable.get("siltest_dir")
#
#dockerHost = Variable.get("docker_host")
#
#ndasImage = Variable.get("ndas_image")
#
#drivesimImage = Variable.get("drivesim_image")
#
#testCasePath = Variable.get("test_case_path")

siltestDir=$1

dockerHost=$2

ndasImage=$3

drivesimImage=$4

testCasePath=$5

cacheDir=$siltestDir + "/cache/dockerovcache-dev"

rrLogPath=$siltestDir/rrLog

ncdPath=$siltestDir/cache/dockerovcache-dev/.nvidia-omniverse/logs/Kit/omni.drivesim.e2e/23.1

airflowDagPath="/data/airflow/dags/scripts"

python3 create_ndas_container.py $dockerHost

python3 create_drivesim_container.py $dockerHost $testCasePath

./scenario_waiting_on_Control.sh

python3 run_ndas_script.py $dockerHost

./watch_scenario_completed.sh

./evaluation_report.sh $airflowDagPath $siltestDir $testCasePath

./backup_nano_osi_roadcast.sh $airflowDagPath $siltestDir $testCasePath $ncdPath $rrLogPath

python3 stop_ndas_drivesim_container.py $dockerHost

python3 cleanup_nano_osi_roadcast_file.py $dockerHost $ncdPath $rrLogPath