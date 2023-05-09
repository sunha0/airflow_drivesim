from __future__ import annotations

import datetime
import time
import pendulum

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator

from airflow.models import  Variable


siltestDir = Variable.get("siltest_dir") 

dockerHost = Variable.get("docker_host")

ndasImage = Variable.get("ndas_image")

drivesimImage = Variable.get("drivesim_image")

omniverseIp = Variable.get("omniverse_ip")

testCasePath = Variable.get("single_case_path")


rrLogPath=f"{siltestDir}/rrLog"
ncdPath=f"{siltestDir}/cache/dockerovcache-dev/.nvidia-omniverse/logs/Kit/omni.drivesim.e2e/23.1"

run_ndas_container="cd {{params.siltest_dir}}/script && ./ndas_startup_hyp8_r5_1.sh  {{params.siltest_dir}} {{params.ndas_image}} "
run_drivesim_container="cd  {{params.siltest_dir}}/script && ./ds_launch_hyp8_r5_1_airflow.sh  {{params.siltest_dir}} {{params.drivesim_image}} {{params.omniverse_ip}} {{params.testcase_path}} "


backup_nano_osi_roadcast_file="sudo sh {{params.siltest_dir}}/script/backup_nano_osi_roadcast.sh {{params.siltest_dir}}  {{params.testcase_path}}  {{params.ncdPath}} {{params.rrLogPath}} "
evaluations_report="sudo sh {{params.siltest_dir}}/script/evaluations.sh {{params.siltest_dir}} {{params.testcase_path}} "
kill_nads_drivesim_container="sudo sh {{params.siltest_dir}}/script/stop_ndas_drsivesim_container.sh "
clean_data="sudo sh {{params.siltest_dir}}/script/clean_data.sh {{params.siltest_dir}}"

watch_control_info="""
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

"""


watch_scenario_completed="""
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

"""





with DAG(
    dag_id="single_testcase_ndas_drivesim_bash",
    schedule=None,
    start_date=pendulum.datetime(2021, 1, 1, tz="Asia/Shanghai"),
    catchup=False,
    dagrun_timeout=datetime.timedelta(minutes=60),
    tags=["siltest"]
) as dag:

    start = EmptyOperator(task_id='Start', dag=dag) 
    run_ndas_container_task=BashOperator(task_id='run_ndas_container_task',bash_command=run_ndas_container,params={"siltest_dir":siltestDir.strip(),"ndas_image":ndasImage.strip()},dag=dag)
    run_drivesim_container_task=BashOperator(task_id='run_drivesim_container_task',bash_command=run_drivesim_container,params={"siltest_dir":siltestDir.strip(),"drivesim_image":drivesimImage.strip(),"omniverse_ip":omniverseIp.strip(),"testcase_path":testCasePath.strip()},dag=dag)
    watch_control_info_task=BashOperator(task_id='watch_control_info_task',bash_command=watch_control_info,dag=dag)
    run_ndas_script_task=BashOperator(task_id='run_ndas_script_task',bash_command='docker exec -d ndas bash -c "sh /home/run_ndas.sh"',dag=dag)
    watch_scenario_completed_task=BashOperator(task_id='watch_scenario_completed_task',bash_command=watch_scenario_completed,dag=dag)
    backup_nano_osi_roadcast_task = BashOperator(task_id="backup_nano_osi_roadcast_task",bash_command=backup_nano_osi_roadcast_file,params={"siltest_dir":siltestDir.strip(),"testcase_path":testCasePath.strip().split("/")[-1].split(".")[0],"ncdPath":ncdPath,"rrLogPath":rrLogPath},dag=dag)
    generate_evaluation_report_task = BashOperator(task_id="generate_evaluation_report_task",bash_command=evaluations_report,params={"siltest_dir":siltestDir.strip(),"testcase_path":testCasePath.strip()},dag=dag)
    kill_nads_drivesim_container_task=BashOperator(task_id="kill_nads_drivesim_container_task",bash_command=kill_nads_drivesim_container,params={"siltest_dir":siltestDir.strip()},dag=dag)
    clean_data_task=BashOperator(task_id="clean_data_task",bash_command=clean_data,params={"siltest_dir":siltestDir.strip()},dag=dag)
    end = EmptyOperator(task_id='End', dag=dag)

 
start >> [clean_data_task,kill_nads_drivesim_container_task]   >> run_ndas_container_task >> run_drivesim_container_task >> watch_control_info_task >> run_ndas_script_task >> watch_scenario_completed_task >> backup_nano_osi_roadcast_task >> generate_evaluation_report_task >> end


if __name__ == "__main__":
    dag.cli()

