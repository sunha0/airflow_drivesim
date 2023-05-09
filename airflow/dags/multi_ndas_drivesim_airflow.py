from __future__ import annotations

import datetime
import time
import pendulum

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.python  import PythonOperator
from airflow.models import  Variable


siltestDir = Variable.get("siltest_dir") 

dockerHost = Variable.get("docker_host")

ndasImage = Variable.get("ndas_image")

drivesimImage = Variable.get("drivesim_image")

omniverseIp = Variable.get("omniverse_ip")

multiTestCasePath = Variable.get("multi_test_case_path")



rrLogPath=f"{siltestDir}/rrLog"
ncdPath=f"{siltestDir}/cache/dockerovcache-dev/.nvidia-omniverse/logs/Kit/omni.drivesim.e2e/23.1"


multi_testcase="sudo bash {{params.siltest_dir}}/script/multi_run_testcase.sh '{{params.multi_testcasePath}}' {{params.siltest_dir}} {{params.ndas_image}} {{params.drivesim_image}} {{params.omniverse_ip}} "





with DAG(
    dag_id="multi_testcase_ndas_drivesim_bash",
    schedule=None,
    start_date=pendulum.datetime(2021, 1, 1, tz="Asia/Shanghai"),
    catchup=False,
    dagrun_timeout=datetime.timedelta(minutes=60),
    tags=["siltest"]
) as dag:

    start = EmptyOperator(task_id='Start', dag=dag) 

    run_multi_testcase_task=BashOperator(task_id='run_multi_testcase_task',bash_command=multi_testcase,params={"siltest_dir":siltestDir,"multi_testcasePath":multiTestCasePath.strip(),"ndas_image":ndasImage,"drivesim_image":drivesimImage,"omniverse_ip":omniverseIp,},dag=dag)
    end = EmptyOperator(task_id='End', dag=dag)
start   >> run_multi_testcase_task >>end 

if __name__ == "__main__":
    dag.cli()

