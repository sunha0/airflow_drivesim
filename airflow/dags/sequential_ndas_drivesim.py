from __future__ import annotations

import datetime
import pendulum
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from airflow.models import Variable
import pathlib

currentdir = str(pathlib.Path(__file__).parent.resolve())

print("currentdir:" + currentdir)

dockerHost = Variable.get("docker_host")

ndasImage = Variable.get("ndas_image")

drivesimImage = Variable.get("drivesim_image")

# define basic directory and cache directory
siltestDir = Variable.get("siltest_dir")
cacheDir = siltestDir + "/cache/dockerovcache-dev"
testCasePath = Variable.get("test_case_path")
sequential_dir = Variable.get("sequential_dir")
print("sequential_dir:" + sequential_dir)
rrLogPath = f"{siltestDir}/rrLog"
ncdPath = f"{siltestDir}/cache/dockerovcache-dev/.nvidia-omniverse/logs/Kit/omni.drivesim.e2e/23.1"

airflowDagPath = "/data/airflow/dags/scripts"

with DAG(
        dag_id="sequential_ndas_drivesim",
        schedule=None,
        start_date=pendulum.datetime(2021, 1, 1, tz="Asia/Shanghai"),
        catchup=False,
        dagrun_timeout=datetime.timedelta(minutes=60),
        tags=["siltest"]
) as dag:
    start = EmptyOperator(task_id='start', dag=dag)
    run_case = BashOperator(task_id="run_case",
                            bash_command="bash " + sequential_dir + "/sequential_ndas_drivesim.sh " + siltestDir + " "
                                         + dockerHost + " " + ndasImage + " " + drivesimImage + " " + testCasePath + " " + sequential_dir + " ")

    start >> run_case

if __name__ == "__main__":
    dag.cli()
