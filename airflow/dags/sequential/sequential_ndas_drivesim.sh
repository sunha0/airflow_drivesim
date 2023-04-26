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
echo "siltestDir:"$siltestDir
dockerHost=$2
echo "dockerHost:"$dockerHost
ndasImage=$3
echo "ndasImage:"$ndasImage
drivesimImage=$4
echo "drivesimImage:"$drivesimImage
testCasePath=$5
echo "testCasePath:"$testCasePath

currentdir=$(cd `dirname $0`; pwd)
#currentdir=$6
echo "currentdir:"$currentdir
cacheDir=$siltestDir/cache/dockerovcache-dev

rrLogPath=$siltestDir/rrLog

ncdPath=$siltestDir/cache/dockerovcache-dev/.nvidia-omniverse/logs/Kit/omni.drivesim.e2e/23.1

airflowDagPath="/data/airflow/dags/scripts"

echo "currentdir:"$currentdir

python3 $currentdir/create_ndas_container.py $dockerHost

python3 $currentdir/create_drivesim_container.py $dockerHost $testCasePath

bash $currentdir/scenario_waiting_on_Control.sh

python3 $currentdir/run_ndas_script.py $dockerHost

bash $currentdir/watch_scenario_completed.sh

bash $currentdir/evaluation_report.sh $airflowDagPath $siltestDir $testCasePath

bash $currentdir/backup_nano_osi_roadcast.sh $airflowDagPath $siltestDir $testCasePath $ncdPath $rrLogPath

python3 $currentdir/stop_ndas_drivesim_container.py $dockerHost

python3 $currentdir/cleanup_nano_osi_roadcast_file.py $dockerHost $ncdPath $rrLogPath